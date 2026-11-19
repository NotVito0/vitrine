-- Le pozioni che si trovano nel mercato e nei regali. Si tengono nell'inventario e si usano quando si vuole.
local Potions = {}

Potions.List = {
	Luck = { Name = "Luck Potion", Icon = "🍀", Boost = "Luck", Mult = 2, Seconds = 300, Color = Color3.fromRGB(90, 220, 120), Rarity = "Common" },
	Coins = { Name = "Coin Potion", Icon = "💰", Boost = "Coins", Mult = 2, Seconds = 300, Color = Color3.fromRGB(255, 205, 70), Rarity = "Common" },
	Damage = { Name = "Rage Potion", Icon = "⚔️", Boost = "Damage", Mult = 2, Seconds = 300, Color = Color3.fromRGB(255, 90, 90), Rarity = "Common" },
	Training = { Name = "XP Potion", Icon = "🏋️", Boost = "Training", Mult = 3, Seconds = 300, Color = Color3.fromRGB(80, 170, 255), Rarity = "Uncommon" },
	Shiny = { Name = "Shiny Potion", Icon = "✨", Boost = "Shiny", Mult = 3, Seconds = 300, Color = Color3.fromRGB(255, 160, 230), Rarity = "Epic" },
	SuperLuck = { Name = "Super Luck Potion", Icon = "🌈", Boost = "Luck", Mult = 4, Seconds = 300, Color = Color3.fromRGB(190, 120, 255), Rarity = "Legendary" },
}

Potions.Order = { "Luck", "Coins", "Damage", "Training", "Shiny", "SuperLuck" }

return Potions
