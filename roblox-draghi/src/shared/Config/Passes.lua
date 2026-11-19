-- Game pass: si pagano una volta e valgono per sempre.
-- Quelli a livelli si sbloccano in ordine: prima x2, poi x4, poi x8.
--
-- Id = 0 vuol dire "non ancora creato". Crea il pass nel Creator Dashboard di Roblox
-- (Monetization > Passes) con lo stesso prezzo e incolla qui il suo numero.
-- In Roblox Studio un pass con Id 0 si "compra" per finta, così puoi provarlo.
local Passes = {}

Passes.Tiers = {
	Coins = {
		Title = "Coins",
		Icon = "💰",
		Field = "Mult",
		Describe = "x%s coins from every monster",
		{ Id = 0, Price = 99, Mult = 2 },
		{ Id = 0, Price = 299, Mult = 4 },
		{ Id = 0, Price = 799, Mult = 8 },
	},
	Training = {
		Title = "Training",
		Icon = "🏋️",
		Field = "Mult",
		Describe = "x%s XP in the training zone",
		{ Id = 0, Price = 79, Mult = 2 },
		{ Id = 0, Price = 249, Mult = 4 },
		{ Id = 0, Price = 699, Mult = 8 },
	},
	Damage = {
		Title = "Damage",
		Icon = "⚔️",
		Field = "Mult",
		Describe = "x%s dragon damage",
		{ Id = 0, Price = 129, Mult = 2 },
		{ Id = 0, Price = 399, Mult = 4 },
		{ Id = 0, Price = 999, Mult = 8 },
	},
	Luck = {
		Title = "Luck",
		Icon = "🍀",
		Field = "Mult",
		Describe = "x%s chance of Rare, Epic and Legendary",
		{ Id = 0, Price = 149, Mult = 2 },
		{ Id = 0, Price = 449, Mult = 3 },
		{ Id = 0, Price = 999, Mult = 5 },
	},
	HatchCount = {
		Title = "Multi Hatch",
		Icon = "🥚",
		Field = "Count",
		Describe = "Open %s eggs at once",
		{ Id = 0, Price = 99, Count = 3 },
		{ Id = 0, Price = 399, Count = 8 },
	},
	TeamSlots = {
		Title = "Team Slots",
		Icon = "🐉",
		Field = "Extra",
		Describe = "+%s dragons in your team",
		{ Id = 0, Price = 99, Extra = 1 },
		{ Id = 0, Price = 249, Extra = 2 },
		{ Id = 0, Price = 599, Extra = 3 },
	},
}

Passes.Tiers.Storage = {
	Title = "Storage",
	Icon = "🎒",
	Field = "Extra",
	Describe = "+%s dragon slots",
	{ Id = 0, Price = 79, Extra = 100 },
	{ Id = 0, Price = 249, Extra = 250 },
}

-- L'ordine in cui compaiono nel negozio
Passes.TierOrder = { "Coins", "Damage", "Training", "Luck", "HatchCount", "TeamSlots", "Storage" }

Passes.Single = {
	VIP = { Id = 0, Price = 249, Title = "VIP", Icon = "👑", Description = "+20% coins forever, VIP tag and VIP area" },
	Speed = { Id = 0, Price = 49, Title = "Fast Walk", Icon = "🏃", Description = "Walk twice as fast" },
}

Passes.SingleOrder = { "VIP", "Speed" }

return Passes
