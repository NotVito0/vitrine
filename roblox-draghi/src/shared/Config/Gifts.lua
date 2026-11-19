-- Regali a tempo: si sbloccano giocando e ripartono a ogni nuova sessione.
-- Più resti, più sono belli: l'ultimo dopo un'ora sono uova gratis.
-- Coins = monete pari a N uova della tua isola migliore. FreeEggs = uova gratis della tua isola migliore.
local Gifts = {}

Gifts.List = {
	{ Minutes = 1, Coins = 2 },
	{ Minutes = 3, Potion = "Luck" },
	{ Minutes = 5, Gems = 5 },
	{ Minutes = 8, Coins = 5 },
	{ Minutes = 12, Potion = "Coins" },
	{ Minutes = 16, Gems = 15 },
	{ Minutes = 20, Potion = "Training" },
	{ Minutes = 25, Coins = 15 },
	{ Minutes = 30, Potion = "Shiny" },
	{ Minutes = 40, Gems = 40 },
	{ Minutes = 50, Potion = "SuperLuck" },
	{ Minutes = 60, FreeEggs = 3 },
}

return Gifts
