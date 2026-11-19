-- Tutti i draghi del gioco.
-- Per aggiungere draghi a un aggiornamento basta aggiungere righe qui (e l'uovo che li contiene in Islands.lua).
local Dragons = {}

Dragons.Rarities = {
	Common = { Order = 1, Name = "Common", Color = Color3.fromRGB(185, 198, 218), Mult = 1 },
	Uncommon = { Order = 2, Name = "Uncommon", Color = Color3.fromRGB(95, 214, 120), Mult = 1.6 },
	Rare = { Order = 3, Name = "Rare", Color = Color3.fromRGB(79, 163, 255), Mult = 2.6 },
	Epic = { Order = 4, Name = "Epic", Color = Color3.fromRGB(181, 108, 255), Mult = 4.5 },
	Legendary = { Order = 5, Name = "Legendary", Color = Color3.fromRGB(255, 176, 46), Mult = 8 },
	Exclusive = { Order = 6, Name = "Exclusive", Color = Color3.fromRGB(63, 220, 143), Mult = 1 },
	Limited = { Order = 7, Name = "Limited", Color = Color3.fromRGB(255, 90, 90), Mult = 1 },
}

-- Le cinque rarità di ogni uovo, in ordine, con il loro peso (probabilità).
Dragons.EggRarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
Dragons.EggWeights = { Common = 50, Uncommon = 30, Rare = 14, Epic = 5, Legendary = 1 }

-- Forza base dell'isola: ogni isola i draghi sono 5 volte più forti.
function Dragons.IslandBasePower(islandIndex: number): number
	return 4 * 5 ^ (islandIndex - 1)
end

-- Draghi delle uova, isola per isola: { id, nome, elemento } nell'ordine delle rarità sopra.
local EGG_SETS = {
	{
		{ "SproutDrake", "Sprout Drake", "Nature" },
		{ "PebbleDrake", "Pebble Drake", "Earth" },
		{ "BreezePup", "Breeze Pup", "Air" },
		{ "EmberHatchling", "Ember Hatchling", "Fire" },
		{ "BloomWyrm", "Bloom Wyrm", "Nature" },
	},
	{
		{ "MossDrake", "Moss Drake", "Nature" },
		{ "AcornWyvern", "Acorn Wyvern", "Earth" },
		{ "OwlDrake", "Owl Drake", "Air" },
		{ "ThornDragon", "Thorn Dragon", "Nature" },
		{ "ElderOakDragon", "Elder Oak Dragon", "Earth" },
	},
	{
		{ "ShellDrake", "Shell Drake", "Water" },
		{ "CoralDrake", "Coral Drake", "Water" },
		{ "TideWyvern", "Tide Wyvern", "Water" },
		{ "PearlDragon", "Pearl Dragon", "Light" },
		{ "LeviathanPup", "Leviathan Pup", "Water" },
	},
	{
		{ "SandDrake", "Sand Drake", "Earth" },
		{ "CactusDrake", "Cactus Drake", "Nature" },
		{ "DuneWyvern", "Dune Wyvern", "Air" },
		{ "ScarabDragon", "Scarab Dragon", "Earth" },
		{ "PharaohDragon", "Pharaoh Dragon", "Light" },
	},
	{
		{ "CinderDrake", "Cinder Drake", "Fire" },
		{ "MagmaDrake", "Magma Drake", "Fire" },
		{ "AshWyvern", "Ash Wyvern", "Shadow" },
		{ "InfernoDragon", "Inferno Dragon", "Fire" },
		{ "PhoenixDragon", "Phoenix Dragon", "Fire" },
	},
	{
		{ "FrostDrake", "Frost Drake", "Ice" },
		{ "SnowballDrake", "Snowball Drake", "Ice" },
		{ "IcicleWyvern", "Icicle Wyvern", "Water" },
		{ "BlizzardDragon", "Blizzard Dragon", "Ice" },
		{ "GlacierKing", "Glacier King", "Ice" },
	},
	{
		{ "SparkDrake", "Spark Drake", "Lightning" },
		{ "StaticDrake", "Static Drake", "Lightning" },
		{ "VoltWyvern", "Volt Wyvern", "Air" },
		{ "StormDragon", "Storm Dragon", "Lightning" },
		{ "ThunderTitan", "Thunder Titan", "Lightning" },
	},
	{
		{ "CloudDrake", "Cloud Drake", "Air" },
		{ "HaloDrake", "Halo Drake", "Light" },
		{ "SkyWyvern", "Sky Wyvern", "Air" },
		{ "AuroraDragon", "Aurora Dragon", "Light" },
		{ "CelestialDragon", "Celestial Dragon", "Light" },
	},
}

Dragons.List = {}
Dragons.EggSets = {} -- isola -> lista di id, nell'ordine delle rarità

for islandIndex, set in EGG_SETS do
	Dragons.EggSets[islandIndex] = {}
	for slot, entry in set do
		local rarity = Dragons.EggRarities[slot]
		Dragons.List[entry[1]] = {
			Id = entry[1],
			Name = entry[2],
			Element = entry[3],
			Rarity = rarity,
			Island = islandIndex,
			Power = Dragons.IslandBasePower(islandIndex) * Dragons.Rarities[rarity].Mult,
		}
		table.insert(Dragons.EggSets[islandIndex], entry[1])
	end
end

-- Draghi che si ottengono solo dal negozio. Non escono mai dalle uova.
local function exclusive(id, name, element, rarity, power, crown)
	Dragons.List[id] = {
		Id = id,
		Name = name,
		Element = element,
		Rarity = rarity,
		Power = power,
		Exclusive = true,
		Crown = crown,
	}
end

exclusive("StarterDrake", "Starter Drake", "Light", "Exclusive", 28, true) -- Mini Pack: forte come un leggendario della prima isola
exclusive("CrownDrake", "Crown Drake", "Fire", "Exclusive", 160, true) -- Starter Pack
exclusive("PrismDrake", "Prism Drake", "Light", "Exclusive", 700, true) -- Pro Pack
exclusive("CrystalDrake", "Crystal Drake", "Ice", "Limited", 2600, true) -- Limitato numerato

function Dragons.Get(id: string)
	return Dragons.List[id]
end

return Dragons
