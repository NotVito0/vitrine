-- I numeri che decidono quanto è facile salire. Si regolano qui dopo aver visto i dati dei giocatori.
local Balance = {}

Balance.StartingDragon = "SproutDrake"
Balance.BaseTeamSize = 3
Balance.MaxInventory = 150

-- Combattimento automatico
Balance.CombatRadius = 30 -- entro questa distanza da un mostro parte il combattimento
Balance.AttackInterval = 1 -- secondi tra un attacco e l'altro di ogni drago
Balance.MonstersPerIsland = 10
Balance.MonsterRespawn = 3
Balance.KillXp = 1 -- esperienza per mostro, moltiplicata per l'isola
Balance.GemChance = 0.04 -- probabilità che un mostro lasci cristalli

-- Uova
Balance.ShinyChance = 1 / 50
Balance.ShinyMult = 2.5
Balance.LuckyRarities = { Rare = true, Epic = true, Legendary = true } -- quelle che la fortuna moltiplica
Balance.HatchCooldown = 0.35

-- Livelli dei draghi
Balance.MaxLevel = 100

function Balance.LevelMult(level: number): number
	return 1 + 0.08 * (level - 1)
end

function Balance.XpToNext(level: number): number
	return math.floor(12 * level ^ 1.55)
end

-- Rinascita: ricominci le isole e tieni i draghi, con un bonus permanente alle monete.
Balance.RebirthBonus = 0.5 -- +50% monete per ogni rinascita

function Balance.RebirthCost(rebirths: number): number
	return math.floor(250000 * 9 ^ rebirths)
end

-- Bonus VIP
Balance.VIPCoinBonus = 0.2

return Balance
