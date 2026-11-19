-- Le isole, in ordine. Ogni aggiornamento con un'isola nuova aggiunge una voce in fondo.
-- Costi e vita dei mostri crescono più in fretta della forza dei draghi:
-- più si va avanti, più servono allenamento, draghi rari o pass.
local Dragons = require(script.Parent.Dragons)

local Islands = {}

local RAW = {
	{
		Id = "Meadow",
		Name = "Meadow",
		Element = "Nature",
		Ground = Color3.fromRGB(110, 196, 78),
		Cliff = Color3.fromRGB(120, 86, 52),
		Material = Enum.Material.Grass,
		EggColor = Color3.fromRGB(255, 236, 170),
		Decor = { { "tree", 14 }, { "flower", 26 }, { "rock", 6 } },
		Monsters = {
			{ Name = "Green Slime", Element = "Nature", Color = Color3.fromRGB(120, 220, 90), Size = 3.5, Shape = "blob", Hp = 1, Coins = 1, Weight = 60 },
			{ Name = "Buzz Bee", Element = "Air", Color = Color3.fromRGB(255, 214, 64), Size = 3, Shape = "blob", Hp = 0.8, Coins = 0.9, Weight = 25 },
			{ Name = "Pebble Golem", Element = "Earth", Color = Color3.fromRGB(150, 140, 130), Size = 4.5, Shape = "box", Hp = 1.8, Coins = 1.8, Weight = 15 },
		},
	},
	{
		Id = "Forest",
		Name = "Forest",
		Element = "Nature",
		Ground = Color3.fromRGB(62, 140, 64),
		Cliff = Color3.fromRGB(90, 64, 40),
		Material = Enum.Material.Grass,
		EggColor = Color3.fromRGB(150, 210, 120),
		Decor = { { "pine", 26 }, { "tree", 8 }, { "rock", 8 } },
		Monsters = {
			{ Name = "Moss Slime", Element = "Nature", Color = Color3.fromRGB(80, 160, 70), Size = 3.8, Shape = "blob", Hp = 1, Coins = 1, Weight = 55 },
			{ Name = "Timber Wolf", Element = "Earth", Color = Color3.fromRGB(140, 110, 80), Size = 4.2, Shape = "box", Hp = 1.4, Coins = 1.4, Weight = 30 },
			{ Name = "Night Bat", Element = "Shadow", Color = Color3.fromRGB(80, 60, 120), Size = 3, Shape = "blob", Hp = 0.9, Coins = 1.1, Weight = 15 },
		},
	},
	{
		Id = "Beach",
		Name = "Beach",
		Element = "Water",
		Ground = Color3.fromRGB(240, 218, 150),
		Cliff = Color3.fromRGB(200, 170, 110),
		Material = Enum.Material.Sand,
		EggColor = Color3.fromRGB(140, 210, 255),
		Decor = { { "palm", 14 }, { "rock", 10 }, { "shell", 18 } },
		Monsters = {
			{ Name = "Beach Crab", Element = "Water", Color = Color3.fromRGB(240, 100, 80), Size = 3.6, Shape = "box", Hp = 1, Coins = 1, Weight = 50 },
			{ Name = "Jelly Blob", Element = "Water", Color = Color3.fromRGB(150, 140, 255), Size = 3.4, Shape = "blob", Hp = 0.9, Coins = 1, Weight = 35 },
			{ Name = "Bone Pirate", Element = "Shadow", Color = Color3.fromRGB(230, 225, 210), Size = 4.6, Shape = "box", Hp = 1.8, Coins = 1.9, Weight = 15 },
		},
	},
	{
		Id = "Desert",
		Name = "Desert",
		Element = "Earth",
		Ground = Color3.fromRGB(230, 190, 110),
		Cliff = Color3.fromRGB(180, 130, 70),
		Material = Enum.Material.Sand,
		EggColor = Color3.fromRGB(240, 200, 120),
		Decor = { { "cactus", 18 }, { "rock", 14 } },
		Monsters = {
			{ Name = "Sand Worm", Element = "Earth", Color = Color3.fromRGB(200, 160, 100), Size = 3.8, Shape = "blob", Hp = 1, Coins = 1, Weight = 50 },
			{ Name = "Scorpion", Element = "Earth", Color = Color3.fromRGB(170, 90, 50), Size = 3.6, Shape = "box", Hp = 1.2, Coins = 1.2, Weight = 35 },
			{ Name = "Mummy", Element = "Shadow", Color = Color3.fromRGB(220, 210, 180), Size = 4.6, Shape = "box", Hp = 1.9, Coins = 2, Weight = 15 },
		},
	},
	{
		Id = "Volcano",
		Name = "Volcano",
		Element = "Fire",
		Ground = Color3.fromRGB(70, 50, 46),
		Cliff = Color3.fromRGB(40, 28, 26),
		Material = Enum.Material.Basalt,
		EggColor = Color3.fromRGB(255, 120, 70),
		Decor = { { "rock", 22 }, { "lava", 10 } },
		Monsters = {
			{ Name = "Lava Slime", Element = "Fire", Color = Color3.fromRGB(255, 110, 40), Size = 3.8, Shape = "blob", Hp = 1, Coins = 1, Weight = 55 },
			{ Name = "Fire Golem", Element = "Fire", Color = Color3.fromRGB(150, 60, 40), Size = 5, Shape = "box", Hp = 2, Coins = 2, Weight = 25 },
			{ Name = "Ash Bat", Element = "Shadow", Color = Color3.fromRGB(70, 60, 70), Size = 3, Shape = "blob", Hp = 0.9, Coins = 1.1, Weight = 20 },
		},
	},
	{
		Id = "Glacier",
		Name = "Glacier",
		Element = "Ice",
		Ground = Color3.fromRGB(232, 244, 255),
		Cliff = Color3.fromRGB(150, 196, 230),
		Material = Enum.Material.Snow,
		EggColor = Color3.fromRGB(200, 240, 255),
		Decor = { { "spike", 20 }, { "pine", 10 }, { "rock", 6 } },
		Monsters = {
			{ Name = "Ice Slime", Element = "Ice", Color = Color3.fromRGB(160, 230, 255), Size = 3.8, Shape = "blob", Hp = 1, Coins = 1, Weight = 50 },
			{ Name = "Yeti", Element = "Ice", Color = Color3.fromRGB(245, 248, 255), Size = 5.2, Shape = "box", Hp = 2.1, Coins = 2.2, Weight = 20 },
			{ Name = "Frost Wisp", Element = "Air", Color = Color3.fromRGB(200, 220, 255), Size = 3, Shape = "blob", Hp = 0.9, Coins = 1, Weight = 30 },
		},
	},
	{
		Id = "ThunderPeaks",
		Name = "Thunder Peaks",
		Element = "Lightning",
		Ground = Color3.fromRGB(90, 96, 120),
		Cliff = Color3.fromRGB(56, 60, 80),
		Material = Enum.Material.Slate,
		EggColor = Color3.fromRGB(255, 225, 90),
		Decor = { { "crystal", 16 }, { "rock", 16 } },
		Monsters = {
			{ Name = "Spark Slime", Element = "Lightning", Color = Color3.fromRGB(255, 225, 70), Size = 3.8, Shape = "blob", Hp = 1, Coins = 1, Weight = 50 },
			{ Name = "Rust Robot", Element = "Lightning", Color = Color3.fromRGB(170, 110, 70), Size = 5, Shape = "box", Hp = 2, Coins = 2, Weight = 25 },
			{ Name = "Storm Bird", Element = "Air", Color = Color3.fromRGB(110, 140, 200), Size = 3.2, Shape = "blob", Hp = 0.9, Coins = 1.1, Weight = 25 },
		},
	},
	{
		Id = "CloudIsle",
		Name = "Cloud Isle",
		Element = "Air",
		Ground = Color3.fromRGB(245, 248, 255),
		Cliff = Color3.fromRGB(205, 215, 245),
		Material = Enum.Material.SmoothPlastic,
		EggColor = Color3.fromRGB(255, 240, 200),
		Decor = { { "cloud", 18 }, { "pillar", 10 } },
		Monsters = {
			{ Name = "Cloud Puff", Element = "Air", Color = Color3.fromRGB(235, 240, 255), Size = 3.8, Shape = "blob", Hp = 1, Coins = 1, Weight = 50 },
			{ Name = "Wind Spirit", Element = "Air", Color = Color3.fromRGB(170, 230, 255), Size = 3.4, Shape = "blob", Hp = 1.1, Coins = 1.1, Weight = 30 },
			{ Name = "Fallen Angel", Element = "Shadow", Color = Color3.fromRGB(90, 70, 140), Size = 4.8, Shape = "box", Hp = 2, Coins = 2.1, Weight = 20 },
		},
	},
}

Islands.List = {}
Islands.ById = {}

for index, raw in RAW do
	local island = table.clone(raw)
	island.Index = index
	-- Costo per sbloccare l'isola (la prima è gratis).
	island.UnlockCost = if index == 1 then 0 else math.floor(400 * 13 ^ (index - 2))
	-- Uovo dell'isola: prezzo e probabilità.
	island.EggCost = math.floor(25 * 12 ^ (index - 1))
	island.EggDragons = Dragons.EggSets[index]
	-- Mostri: vita e monete base, moltiplicate per Hp/Coins di ogni mostro.
	island.MonsterHp = 12 * 9 ^ (index - 1)
	island.MonsterCoins = 3 * 10 ^ (index - 1)
	-- Allenamento: esperienza al secondo per ogni drago in squadra.
	island.TrainingXp = 2 * 1.6 ^ (index - 1)
	Islands.List[index] = island
	Islands.ById[island.Id] = island
end

function Islands.Get(index: number)
	return Islands.List[index]
end

return Islands
