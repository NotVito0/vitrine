-- Negozio della rinascita: ogni rinascita dà gettoni da spendere in potenziamenti permanenti.
-- Per = bonus per ogni livello (0.1 = +10%). Cost(livello) = gettoni per comprare quel livello.
local RebirthShop = {}

-- Gettoni ricevuti alla rinascita numero n (1, 2, 3...): uno in più ogni 5 rinascite.
function RebirthShop.TokensFor(n: number): number
	return 1 + n // 5
end

RebirthShop.List = {
	{ Id = "Coins", Name = "Coin Master", Icon = "💰", Max = 20, Per = 0.1, Description = "+10% coins per level" },
	{ Id = "Damage", Name = "Dragon Might", Icon = "⚔️", Max = 20, Per = 0.1, Description = "+10% damage per level" },
	{ Id = "Training", Name = "Fast Learner", Icon = "🏋️", Max = 20, Per = 0.1, Description = "+10% training XP per level" },
	{ Id = "Luck", Name = "Lucky Charm", Icon = "🍀", Max = 10, Per = 0.05, Description = "+5% egg luck per level" },
	{ Id = "Slots", Name = "Bigger Team", Icon = "🐉", Max = 2, Per = 1, Description = "+1 dragon in your team per level" },
}

function RebirthShop.Cost(item, level: number): number
	if item.Id == "Slots" then
		return 5 * level
	end
	return level
end

function RebirthShop.Get(id: string)
	for _, item in RebirthShop.List do
		if item.Id == id then
			return item
		end
	end
	return nil
end

return RebirthShop
