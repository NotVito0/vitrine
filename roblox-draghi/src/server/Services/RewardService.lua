-- Codici e premio giornaliero.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
-- I codici stanno sul server: se fossero in ReplicatedStorage chiunque potrebbe leggerli prima dell'annuncio.
local Codes = require(script.Parent.Parent.Config.Codes)
local Daily = require(Shared.Config.Daily)
local Islands = require(Shared.Config.Islands)
local Potions = require(Shared.Config.Potions)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local DragonService = require(script.Parent.DragonService)
local MarketService = require(script.Parent.MarketService)

local RewardService = {}

local function bestEggCost(data)
	local cost = Islands.List[1].EggCost
	for _, island in Islands.List do
		if data.Unlocked[island.Id] then
			cost = island.EggCost
		end
	end
	return cost
end

-- Dà una ricompensa { Coins, Gems, Potion, Dragon } e ritorna il testo da mostrare.
function RewardService.Give(player, data, reward)
	local parts = {}
	if reward.Coins then
		local coins = bestEggCost(data) * reward.Coins
		data.Coins += coins
		table.insert(parts, "+" .. Format.Number(coins) .. " coins")
	end
	if reward.Gems then
		data.Gems += reward.Gems
		table.insert(parts, "+" .. reward.Gems .. " gems")
	end
	if reward.Potion then
		MarketService.AddPotion(data, reward.Potion, 1)
		table.insert(parts, Potions.List[reward.Potion].Name)
	end
	local hatch
	if reward.Dragon then
		local _, _, isNew = DragonService.Add(player, reward.Dragon, { Force = true })
		hatch = { { Id = reward.Dragon, Shiny = false, New = isNew } }
	end
	DataService.MarkDirty(player, true)
	return table.concat(parts, " · "), hatch
end

local function today()
	return os.time() // 86400
end

local function dailyView(data)
	local day = today()
	local canClaim = data.Daily.Last < day
	local streak = if data.Daily.Last == day - 1 or data.Daily.Last == day then data.Daily.Day else 0
	local nextDay = if canClaim then (streak % #Daily.Rewards) + 1 else streak
	return { CanClaim = canClaim, Streak = streak, Next = nextDay, ResetIn = (day + 1) * 86400 - os.time() }
end

function RewardService.Start()
	Remotes.Func("RedeemCode").OnServerInvoke = function(player, code)
		local data = DataService.Get(player)
		if not data or type(code) ~= "string" or #code > 30 then
			return false, "Invalid code"
		end
		code = string.upper((string.gsub(code, "%s", "")))
		local reward = Codes.List[code]
		if not reward then
			return false, "This code doesn't exist"
		end
		if reward.Expires then
			local e = reward.Expires
			if os.time() > os.time({ year = e[1], month = e[2], day = e[3], hour = 23 }) then
				return false, "This code has expired"
			end
		end
		if data.Codes[code] then
			return false, "You already used this code"
		end
		data.Codes[code] = true
		local text = RewardService.Give(player, data, reward)
		return true, "Code redeemed: " .. text
	end

	Remotes.Func("GetDaily").OnServerInvoke = function(player)
		local data = DataService.Get(player)
		return data and dailyView(data)
	end

	Remotes.Func("ClaimDaily").OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then
			return { Ok = false }
		end
		local view = dailyView(data)
		if not view.CanClaim then
			return { Ok = false, Error = "Come back tomorrow!" }
		end
		local dayIndex = view.Next
		data.Daily.Day = dayIndex
		data.Daily.Last = today()
		local text, hatch = RewardService.Give(player, data, Daily.Rewards[dayIndex])
		return { Ok = true, Text = text, Hatch = hatch, View = dailyView(data), Day = dayIndex }
	end
end

return RewardService
