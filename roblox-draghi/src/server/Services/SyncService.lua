-- Manda al client lo stato del giocatore (monete, draghi, pass...) quando cambia,
-- aggiorna la classifica in alto a destra e l'attributo "Team" che tutti i client usano per disegnare i draghi.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Balance = require(Shared.Config.Balance)
local Islands = require(Shared.Config.Islands)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PassService = require(script.Parent.PassService)
local DragonService = require(script.Parent.DragonService)
local Boosts = require(script.Parent.Boosts)

local SyncService = {}

local FULL_INTERVAL = 1.5 -- l'inventario completo al massimo ogni 1,5 secondi
local lastFull = {}
local pendingFull = {}

local function setupLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	stats.Parent = player
end

local function snapshot(player, data, full)
	local now = os.time()
	local boosts = {}
	for name, b in data.Boosts do
		if b.Expires > now then
			boosts[name] = { Left = b.Expires - now, Mult = b.Mult }
		end
	end
	local out = {
		Coins = data.Coins,
		Gems = data.Gems,
		Rebirths = data.Rebirths,
		RebirthCost = Balance.RebirthCost(data.Rebirths),
		Unlocked = data.Unlocked,
		Boosts = boosts,
		Passes = PassService.Snapshot(player),
		OneTime = data.OneTime,
		Potions = data.Potions,
		TeamSize = DragonService.TeamSize(player),
		HatchCount = PassService.Value(player, "HatchCount", 1),
		Mults = {
			Coins = Boosts.Coins(player, data),
			Damage = Boosts.Damage(player, data),
			Training = Boosts.Training(player, data),
			Luck = Boosts.Luck(player, data),
		},
	}
	if full then
		local dragons = {}
		for uid, d in data.Dragons do
			dragons[uid] = {
				Id = d.Id,
				Level = d.Level,
				Xp = d.Xp,
				Next = Balance.XpToNext(d.Level),
				Shiny = d.Shiny,
				Serial = d.Serial,
				Power = DragonService.Power(d),
			}
		end
		out.Dragons = dragons
		out.Equipped = data.Equipped
		out.Discovered = data.Discovered
		out.InventoryMax = Balance.MaxInventory
	end
	return out
end

local function updateWorldState(player, data)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Coins.Value = data.Coins
		stats.Rebirths.Value = data.Rebirths
	end
	local team = {}
	for _, entry in DragonService.GetTeam(player) do
		table.insert(team, { entry.Dragon.Id, entry.Dragon.Shiny and 1 or 0 })
	end
	local encoded = HttpService:JSONEncode(team)
	if player:GetAttribute("Team") ~= encoded then
		player:SetAttribute("Team", encoded)
	end
	-- Isola migliore sbloccata, per i pacchetti di monete e il client.
	local best = 1
	for i, island in Islands.List do
		if data.Unlocked[island.Id] then
			best = i
		end
	end
	player:SetAttribute("BestIsland", best)
end

function SyncService.Push(player, full: boolean?)
	local data = DataService.Get(player)
	if not data then
		return
	end
	Remotes.Event("DataSync"):FireClient(player, snapshot(player, data, full))
	updateWorldState(player, data)
	if full then
		lastFull[player] = os.clock()
		pendingFull[player] = nil
	end
end

function SyncService.Start()
	Players.PlayerAdded:Connect(setupLeaderstats)
	for _, p in Players:GetPlayers() do
		if not p:FindFirstChild("leaderstats") then
			setupLeaderstats(p)
		end
	end
	Players.PlayerRemoving:Connect(function(p)
		lastFull[p] = nil
		pendingFull[p] = nil
	end)

	DataService.PlayerLoaded:Connect(function(player)
		SyncService.Push(player, true)
	end)
	PassService.Changed:Connect(function(player)
		DataService.MarkDirty(player, true)
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 then
			return
		end
		acc = 0
		local now = os.clock()
		for player, full in DataService.TakeDirty() do
			if full then
				pendingFull[player] = true
			end
			if not (pendingFull[player] and now - (lastFull[player] or 0) >= FULL_INTERVAL) then
				SyncService.Push(player, false)
			end
		end
		for player in pendingFull do
			if now - (lastFull[player] or 0) >= FULL_INTERVAL then
				SyncService.Push(player, true)
			end
		end
	end)

	-- Ogni 5 secondi aggiorna i tempi rimasti delle pozioni.
	task.spawn(function()
		while true do
			task.wait(5)
			for _, p in Players:GetPlayers() do
				if DataService.IsLoaded(p) then
					DataService.MarkDirty(p, false)
				end
			end
		end
	end)
end

return SyncService
