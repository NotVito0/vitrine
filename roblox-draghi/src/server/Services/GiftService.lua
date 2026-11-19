-- Regali a tempo: si sbloccano con i minuti giocati in questa sessione.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Gifts = require(Shared.Config.Gifts)
local Islands = require(Shared.Config.Islands)
local Potions = require(Shared.Config.Potions)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local EggService = require(script.Parent.EggService)
local MarketService = require(script.Parent.MarketService)

local GiftService = {}

local sessions = {} -- player -> { Start, Claimed = { [i] = true }, AllUnlocked }

local function session(player)
	local s = sessions[player]
	if not s then
		s = { Start = os.time(), Claimed = {}, AllUnlocked = false }
		sessions[player] = s
	end
	return s
end

local function bestIsland(data)
	local best = 1
	for i, island in Islands.List do
		if data.Unlocked[island.Id] then
			best = i
		end
	end
	return best
end

local function view(player)
	local s = session(player)
	local played = os.time() - s.Start
	local list = {}
	for i, gift in Gifts.List do
		list[i] = {
			Claimed = s.Claimed[i] == true,
			Left = if s.AllUnlocked then 0 else math.max(0, gift.Minutes * 60 - played),
		}
	end
	return { Gifts = list, AllUnlocked = s.AllUnlocked }
end

function GiftService.UnlockAll(player)
	session(player).AllUnlocked = true
end

function GiftService.Start()
	Players.PlayerAdded:Connect(session)
	for _, p in Players:GetPlayers() do
		session(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		sessions[p] = nil
	end)

	Remotes.Func("GetGifts").OnServerInvoke = function(player)
		return view(player)
	end

	Remotes.Func("ClaimGift").OnServerInvoke = function(player, index)
		local data = DataService.Get(player)
		local gift = type(index) == "number" and Gifts.List[index]
		if not data or not gift then
			return { Ok = false, Error = "Unknown gift" }
		end
		local s = session(player)
		if s.Claimed[index] then
			return { Ok = false, Error = "Already claimed" }
		end
		if not s.AllUnlocked and os.time() - s.Start < gift.Minutes * 60 then
			return { Ok = false, Error = "Not ready yet" }
		end
		s.Claimed[index] = true
		local reward = {}
		local island = Islands.Get(bestIsland(data))
		if gift.Coins then
			local coins = island.EggCost * gift.Coins
			data.Coins += coins
			reward.Coins = coins
		end
		if gift.Gems then
			data.Gems += gift.Gems
			reward.Gems = gift.Gems
		end
		if gift.Potion then
			MarketService.AddPotion(data, gift.Potion, 1)
			reward.Potion = Potions.List[gift.Potion].Name
		end
		if gift.FreeEggs then
			reward.Hatch = EggService.Grant(player, island.Index, gift.FreeEggs)
			reward.Island = island.Index
		end
		DataService.MarkDirty(player, true)
		return { Ok = true, Reward = reward, State = view(player) }
	end
end

return GiftService
