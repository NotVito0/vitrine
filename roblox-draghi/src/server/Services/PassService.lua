-- Quali game pass ha ogni giocatore, e acquisto dei pass (anche quelli a livelli: x2 -> x4 -> x8).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Passes = require(Shared.Config.Passes)
local Remotes = require(Shared.Remotes)

local PassService = {}

local owned = {} -- player -> { Tiers = { Coins = 2 }, Single = { VIP = true } }
local changed = Instance.new("BindableEvent")
PassService.Changed = changed.Event

local function ownsPass(player, id: number): boolean
	if id == 0 then
		return false
	end
	local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
	return ok and result == true
end

local function load(player)
	local entry = { Tiers = {}, Single = {} }
	owned[player] = entry
	for category, tiers in Passes.Tiers do
		for tier, info in ipairs(tiers) do
			if ownsPass(player, info.Id) then
				entry.Tiers[category] = math.max(entry.Tiers[category] or 0, tier)
			end
		end
	end
	for name, info in Passes.Single do
		if ownsPass(player, info.Id) then
			entry.Single[name] = true
		end
	end
	changed:Fire(player)
end

function PassService.Tier(player, category: string): number
	local entry = owned[player]
	return entry and entry.Tiers[category] or 0
end

-- Il valore del livello più alto posseduto (es. Mult = 4), o `default` se non ne ha.
function PassService.Value(player, category: string, default: number): number
	local tier = PassService.Tier(player, category)
	if tier == 0 then
		return default
	end
	local tiers = Passes.Tiers[category]
	return tiers[tier][tiers.Field]
end

function PassService.Has(player, name: string): boolean
	local entry = owned[player]
	return entry ~= nil and entry.Single[name] == true
end

function PassService.Snapshot(player)
	local entry = owned[player] or { Tiers = {}, Single = {} }
	return { Tiers = table.clone(entry.Tiers), Single = table.clone(entry.Single) }
end

local function grant(player, category, tier)
	local entry = owned[player]
	if not entry then
		return
	end
	if category == "Single" then
		entry.Single[tier] = true
	else
		entry.Tiers[category] = math.max(entry.Tiers[category] or 0, tier)
	end
	changed:Fire(player)
end

local function findPass(id)
	for category, tiers in Passes.Tiers do
		for tier, info in ipairs(tiers) do
			if info.Id == id then
				return category, tier
			end
		end
	end
	for name, info in Passes.Single do
		if info.Id == id then
			return "Single", name
		end
	end
	return nil
end

function PassService.Start()
	Players.PlayerAdded:Connect(load)
	for _, p in Players:GetPlayers() do
		task.spawn(load, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		owned[p] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local category, tier = findPass(passId)
		if category then
			grant(player, category, tier)
			Remotes.Event("Notify"):FireClient(player, "Thanks! Your pass is active.", "success")
		end
	end)

	-- Il client chiede di comprare un pass. Per quelli a livelli si può comprare solo il livello successivo.
	Remotes.Func("BuyPass").OnServerInvoke = function(player, category, tier)
		local info
		if category == "Single" then
			if type(tier) ~= "string" or PassService.Has(player, tier) then
				return false, "Already owned"
			end
			info = Passes.Single[tier]
		else
			local tiers = Passes.Tiers[category]
			if not tiers or type(tier) ~= "number" then
				return false, "Unknown pass"
			end
			if tier ~= PassService.Tier(player, category) + 1 then
				return false, "Buy the previous level first"
			end
			info = tiers[tier]
		end
		if not info then
			return false, "Unknown pass"
		end
		if info.Id == 0 then
			if RunService:IsStudio() then
				grant(player, category, tier)
				return true, "Studio test: pass granted (no Robux spent)"
			end
			return false, "This pass is not set up yet"
		end
		MarketplaceService:PromptGamePassPurchase(player, info.Id)
		return true
	end
end

return PassService
