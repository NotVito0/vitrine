-- Mercato delle pozioni (si rifornisce ogni 5 minuti) e uso delle pozioni dall'inventario.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Islands = require(Shared.Config.Islands)
local Market = require(Shared.Config.Market)
local Potions = require(Shared.Config.Potions)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Boosts = require(script.Parent.Boosts)

local MarketService = {}

local function now()
	return workspace:GetServerTimeNow()
end

local function bestEggCost(data)
	local cost = Islands.List[1].EggCost
	for _, island in Islands.List do
		if data.Unlocked[island.Id] then
			cost = island.EggCost
		end
	end
	return cost
end

-- Se è cambiata la finestra di tempo, le scorte del giocatore ripartono piene.
local function sync(data)
	local window = Market.Window(now())
	if data.Market.Window ~= window then
		data.Market.Window = window
		data.Market.Bought = {}
	end
	return window
end

local function view(data)
	local window = sync(data)
	local items = {}
	for slot, item in Market.Items(window) do
		local bought = data.Market.Bought[tostring(slot)] or 0
		table.insert(items, {
			Slot = slot,
			Potion = item.Potion,
			Left = math.max(0, item.Stock - bought),
			Stock = item.Stock,
			Coins = if item.EggPrice then bestEggCost(data) * item.EggPrice else nil,
			Gems = item.Gems,
		})
	end
	return { Items = items, NextRestock = (window + 1) * Market.RestockSeconds }
end

function MarketService.Restock(data)
	sync(data)
	data.Market.Bought = {}
end

function MarketService.AddPotion(data, name: string, count: number)
	data.Potions[name] = (data.Potions[name] or 0) + count
end

function MarketService.Start()
	Remotes.Func("GetMarket").OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then
			return nil
		end
		return view(data)
	end

	Remotes.Func("BuyMarket").OnServerInvoke = function(player, slot)
		local data = DataService.Get(player)
		if not data or type(slot) ~= "number" then
			return false, "Not ready"
		end
		local window = sync(data)
		local item = Market.Items(window)[slot]
		if not item then
			return false, "This item is gone"
		end
		local key = tostring(slot)
		local bought = data.Market.Bought[key] or 0
		if bought >= item.Stock then
			return false, "Sold out until the next restock"
		end
		if item.Gems then
			if data.Gems < item.Gems then
				return false, "You need " .. (item.Gems - data.Gems) .. " more gems"
			end
			data.Gems -= item.Gems
		else
			local price = bestEggCost(data) * item.EggPrice
			if data.Coins < price then
				return false, "You need " .. Format.Number(price - data.Coins) .. " more coins"
			end
			data.Coins -= price
		end
		data.Market.Bought[key] = bought + 1
		MarketService.AddPotion(data, item.Potion, 1)
		DataService.MarkDirty(player, false)
		return true, view(data)
	end

	Remotes.Func("UsePotion").OnServerInvoke = function(player, name)
		local data = DataService.Get(player)
		local potion = type(name) == "string" and Potions.List[name]
		if not data or not potion then
			return false, "Unknown potion"
		end
		if (data.Potions[name] or 0) < 1 then
			return false, "You don't have this potion"
		end
		data.Potions[name] -= 1
		if data.Potions[name] <= 0 then
			data.Potions[name] = nil
		end
		Boosts.Add(data, potion.Boost, potion.Seconds, potion.Mult)
		DataService.MarkDirty(player, false)
		return true
	end
end

return MarketService
