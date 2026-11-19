-- Schiusa delle uova. Tutto si decide sul server: prezzo, probabilità, fortuna e brillanti.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Balance = require(Shared.Config.Balance)
local Dragons = require(Shared.Config.Dragons)
local Islands = require(Shared.Config.Islands)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local DragonService = require(script.Parent.DragonService)
local PassService = require(script.Parent.PassService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Boosts = require(script.Parent.Boosts)

local EggService = {}

local rng = Random.new()
local lastHatch = {}

-- Probabilità dell'uovo con la fortuna attuale (la fortuna moltiplica Raro, Epico e Leggendario).
function EggService.Weights(island, luck: number)
	local out = {}
	for _, id in island.EggDragons do
		local def = Dragons.Get(id)
		local w = Dragons.EggWeights[def.Rarity]
		if Balance.LuckyRarities[def.Rarity] then
			w *= luck
		end
		table.insert(out, { Id = id, Weight = w })
	end
	return out
end

local function roll(weights)
	local total = 0
	for _, w in weights do
		total += w.Weight
	end
	local r = rng:NextNumber(0, total)
	for _, w in weights do
		r -= w.Weight
		if r <= 0 then
			return w.Id
		end
	end
	return weights[1].Id
end

function EggService.Start()
	Remotes.Func("Hatch").OnServerInvoke = function(player, islandIndex, amount)
		local data = DataService.Get(player)
		local island = type(islandIndex) == "number" and Islands.Get(islandIndex)
		if not data or not island then
			return { Ok = false, Error = "invalid" }
		end
		local now = os.clock()
		if now - (lastHatch[player] or 0) < Balance.HatchCooldown then
			return { Ok = false, Error = "slow" }
		end
		lastHatch[player] = now

		if not data.Unlocked[island.Id] then
			return { Ok = false, Error = "locked" }
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local eggPos = WorldBuilder.Islands[islandIndex].EggPos
		if not root or (root.Position - eggPos).Magnitude > 20 then
			return { Ok = false, Error = "far" }
		end

		local maxCount = PassService.Value(player, "HatchCount", 1)
		amount = math.clamp(math.floor(tonumber(amount) or 1), 1, maxCount)
		local affordable = math.floor(data.Coins / island.EggCost)
		if affordable < 1 then
			return { Ok = false, Error = "coins", Missing = island.EggCost - data.Coins }
		end
		amount = math.min(amount, affordable)
		local space = Balance.MaxInventory - DragonService.Count(data)
		if space < 1 then
			return { Ok = false, Error = "full" }
		end
		amount = math.min(amount, space)

		data.Coins -= island.EggCost * amount
		local luck = Boosts.Luck(player, data)
		local weights = EggService.Weights(island, luck)
		local shinyChance = Balance.ShinyChance * (if luck > 1 then 1.5 else 1)
		local results = {}
		for _ = 1, amount do
			local id = roll(weights)
			local shiny = rng:NextNumber() < shinyChance
			local uid, _, isNew = DragonService.Add(player, id, { Shiny = shiny, SkipEquip = true })
			if uid then
				data.Stats.EggsHatched += 1
				table.insert(results, { Id = id, Shiny = shiny, New = isNew, Rarity = Dragons.Get(id).Rarity })
			end
		end
		if data.Settings.AutoEquip then
			DragonService.EquipBest(player)
		end
		DataService.MarkDirty(player, true)
		return { Ok = true, Results = results }
	end
end

return EggService
