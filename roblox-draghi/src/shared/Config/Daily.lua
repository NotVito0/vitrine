-- Premio giornaliero: 7 giorni di fila, poi ricomincia. Se salti un giorno si riparte dal primo.
-- Coins = monete pari a N uova della tua isola migliore.
local Daily = {}

Daily.Rewards = {
	{ Coins = 3 },
	{ Potion = "Luck" },
	{ Gems = 15 },
	{ Coins = 10, Potion = "Coins" },
	{ Gems = 30, Potion = "Training" },
	{ Potion = "Shiny", Gems = 30 },
	{ Dragon = "LoyalDrake", Potion = "SuperLuck", Gems = 60 }, -- drago esclusivo solo per chi arriva al 7° giorno
}

return Daily
