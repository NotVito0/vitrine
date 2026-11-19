-- Missioni giornaliere: ogni giorno (UTC) 3 missioni pescate da questa lista, uguali per tutti.
-- Stat = cosa conta. Goal = quanto serve. Reward = premio. Completarle tutte dà un premio extra.
local Quests = {}

local function seed(n: number): number
	n = math.floor(n) % 4294967296
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = (n * 73244475) % 4294967296
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = (n * 73244475) % 4294967296
	return bit32.bxor(n, bit32.rshift(n, 16))
end

Quests.Pool = {
	{ Id = "Kills100", Text = "Defeat 100 monsters", Stat = "Kills", Goal = 100, Reward = { Gems = 15 } },
	{ Id = "Kills300", Text = "Defeat 300 monsters", Stat = "Kills", Goal = 300, Reward = { Gems = 30, Potion = "Coins" } },
	{ Id = "Eggs10", Text = "Hatch 10 eggs", Stat = "Eggs", Goal = 10, Reward = { Gems = 15 } },
	{ Id = "Eggs30", Text = "Hatch 30 eggs", Stat = "Eggs", Goal = 30, Reward = { Gems = 25, Potion = "Luck" } },
	{ Id = "Train10", Text = "Train for 10 minutes", Stat = "TrainSeconds", Goal = 600, Reward = { Gems = 15, Potion = "Training" } },
	{ Id = "Breed2", Text = "Breed 2 dragons in the nest", Stat = "Breeds", Goal = 2, Reward = { Gems = 20 } },
	{ Id = "Market2", Text = "Buy 2 potions at the market", Stat = "MarketBuys", Goal = 2, Reward = { Gems = 15 } },
	{ Id = "Ability20", Text = "Use abilities 20 times", Stat = "Abilities", Goal = 20, Reward = { Gems = 15, Potion = "Damage" } },
	{ Id = "Gems10", Text = "Find 10 gems", Stat = "GemsFound", Goal = 10, Reward = { Potion = "Shiny" } },
}

Quests.PerDay = 3
Quests.AllDoneReward = { Gems = 40, Potion = "SuperLuck" }

function Quests.Day(t: number): number
	return math.floor(t / 86400)
end

function Quests.ForDay(day: number)
	local rng = Random.new(seed(day * 977 + 11))
	local pool = table.clone(Quests.Pool)
	local picks = {}
	for _ = 1, Quests.PerDay do
		table.insert(picks, table.remove(pool, rng:NextInteger(1, #pool)))
	end
	return picks
end

return Quests
