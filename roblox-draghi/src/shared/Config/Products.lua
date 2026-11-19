-- Acquisti ripetibili e pacchetti (Developer Products).
-- Id = 0 vuol dire "non ancora creato": crealo nel Creator Dashboard
-- (Monetization > Developer Products) con lo stesso prezzo e incolla qui il numero.
-- In Roblox Studio un prodotto con Id 0 si "compra" per finta, così puoi provarlo.
--
-- OneTime = si può comprare una volta sola per account.
-- Section = dove compare nel negozio.
local Products = {}

Products.List = {
	-- Pacchetti di benvenuto: contengono sempre qualcosa che non si trova giocando.
	MiniPack = {
		Id = 0,
		Price = 9,
		Section = "Packs",
		OneTime = true,
		Title = "Mini Pack",
		Icon = "🎁",
		Was = 250,
		Description = "Starter Drake (exclusive, never in eggs) + coins",
	},
	StarterPack = {
		Id = 0,
		Price = 25,
		Section = "Packs",
		OneTime = true,
		Title = "Starter Pack",
		Icon = "🎁",
		Was = 400,
		Description = "Crown Drake (exclusive) + 1 extra team slot forever",
	},
	ProPack = {
		Id = 0,
		Price = 99,
		Section = "Packs",
		OneTime = true,
		Title = "Pro Pack",
		Icon = "💎",
		Was = 1200,
		Description = "Prism Drake (exclusive) + 150 gems + 15 min Luck x2",
	},

	-- Limitati: quantità fissa per tutto il gioco, numerati.
	CrystalDrake = {
		Id = 0,
		Price = 149,
		Section = "Limited",
		OneTime = true,
		Title = "Crystal Drake",
		Icon = "🔷",
		Stock = 500,
		Description = "Only 500 will ever exist. Each one is numbered.",
	},

	-- Piccoli aiuti
	LuckPotion = {
		Id = 0,
		Price = 5,
		Section = "Boosts",
		Title = "Luck Potion",
		Icon = "🍀",
		Boost = "Luck",
		Mult = 2,
		Seconds = 300,
		Description = "Luck x2 for 5 minutes",
	},
	CoinPotion = {
		Id = 0,
		Price = 19,
		Section = "Boosts",
		Title = "Coin Potion",
		Icon = "💰",
		Boost = "Coins",
		Mult = 2,
		Seconds = 900,
		Description = "Coins x2 for 15 minutes",
	},
	DamagePotion = {
		Id = 0,
		Price = 19,
		Section = "Boosts",
		Title = "Rage Potion",
		Icon = "⚔️",
		Boost = "Damage",
		Mult = 2,
		Seconds = 900,
		Description = "Damage x2 for 15 minutes",
	},
	TrainingPotion = {
		Id = 0,
		Price = 19,
		Section = "Boosts",
		Title = "XP Potion",
		Icon = "🏋️",
		Boost = "Training",
		Mult = 3,
		Seconds = 900,
		Description = "Training XP x3 for 15 minutes",
	},

	-- Cristalli
	Gems10 = { Id = 0, Price = 5, Section = "Gems", Title = "Handful of Gems", Icon = "💎", Gems = 10, Description = "+10 gems" },
	Gems120 = { Id = 0, Price = 49, Section = "Gems", Title = "Bag of Gems", Icon = "💎", Gems = 120, Description = "+120 gems" },
	Gems600 = { Id = 0, Price = 199, Section = "Gems", Title = "Chest of Gems", Icon = "💎", Gems = 600, Description = "+600 gems · best value", Best = true },

	-- Monete: il valore cresce con l'isola migliore che hai sbloccato.
	CoinsSmall = { Id = 0, Price = 9, Section = "Coins", Title = "Coin Pouch", Icon = "🪙", EggsWorth = 5, Description = "Coins worth 5 eggs of your best island" },
	CoinsMedium = { Id = 0, Price = 49, Section = "Coins", Title = "Coin Sack", Icon = "🪙", EggsWorth = 30, Description = "Coins worth 30 eggs of your best island" },
	CoinsLarge = { Id = 0, Price = 199, Section = "Coins", Title = "Coin Vault", Icon = "🪙", EggsWorth = 150, Description = "Coins worth 150 eggs · best value", Best = true },

	-- Venduti dentro il mercato e i regali, non nel negozio.
	MarketRestock = { Id = 0, Price = 15, Section = "Hidden", Title = "Instant Restock", Icon = "🔄", Description = "Refill the market stock right now" },
	UnlockAllGifts = { Id = 0, Price = 49, Section = "Hidden", Title = "Unlock All Gifts", Icon = "🎁", Description = "Open every gift of this session now" },
}

Products.Sections = {
	{ Key = "Packs", Title = "Welcome offers" },
	{ Key = "Limited", Title = "Limited" },
	{ Key = "Boosts", Title = "Potions" },
	{ Key = "Gems", Title = "Gems" },
	{ Key = "Coins", Title = "Coins" },
}

Products.Order = {
	"MiniPack",
	"StarterPack",
	"ProPack",
	"CrystalDrake",
	"LuckPotion",
	"CoinPotion",
	"DamagePotion",
	"TrainingPotion",
	"Gems10",
	"Gems120",
	"Gems600",
	"CoinsSmall",
	"CoinsMedium",
	"CoinsLarge",
}

return Products
