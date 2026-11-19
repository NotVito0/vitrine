-- Tutti i draghi del gioco.
-- Per aggiungere draghi a un aggiornamento basta aggiungere righe qui (e l'uovo che li contiene in Islands.lua).
local Dragons = {}

Dragons.Rarities = {
	Common = { Order = 1, Name = "Common", Color = Color3.fromRGB(185, 198, 218), Mult = 1 },
	Uncommon = { Order = 2, Name = "Uncommon", Color = Color3.fromRGB(95, 214, 120), Mult = 1.6 },
	Rare = { Order = 3, Name = "Rare", Color = Color3.fromRGB(79, 163, 255), Mult = 2.6 },
	Epic = { Order = 4, Name = "Epic", Color = Color3.fromRGB(181, 108, 255), Mult = 4.5 },
	Legendary = { Order = 5, Name = "Legendary", Color = Color3.fromRGB(255, 176, 46), Mult = 8 },
	Mythic = { Order = 6, Name = "Mythic", Color = Color3.fromRGB(255, 70, 70), Mult = 14 },
	Divine = { Order = 7, Name = "Divine", Color = Color3.fromRGB(255, 240, 150), Mult = 25 },
	Celestial = { Order = 8, Name = "Celestial", Color = Color3.fromRGB(110, 230, 255), Mult = 45 },
	Secret = { Order = 9, Name = "Secret", Color = Color3.fromRGB(255, 79, 139), Mult = 80 },
	Exclusive = { Order = 10, Name = "Exclusive", Color = Color3.fromRGB(63, 220, 143), Mult = 1 },
	Event = { Order = 10, Name = "Event", Color = Color3.fromRGB(255, 150, 60), Mult = 1 },
	Limited = { Order = 11, Name = "Limited", Color = Color3.fromRGB(255, 90, 90), Mult = 1 },
}

-- Le nove rarità di ogni uovo, dalla più comune alla più rara, con il loro peso (su 100).
-- Secret = 1 su 10.000. Divine e superiori vengono annunciati a tutto il server.
Dragons.EggRarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Celestial", "Secret" }
Dragons.EggWeights = { Common = 44, Uncommon = 28, Rare = 16, Epic = 7.5, Legendary = 3, Mythic = 1.2, Divine = 0.25, Celestial = 0.04, Secret = 0.01 }

-- Evoluzioni: 5 draghi uguali dello stesso grado diventano 1 del grado dopo.
Dragons.Variants = {
	{ Name = "Normal", Mult = 1 },
	{ Name = "Golden", Mult = 3, Color = Color3.fromRGB(255, 200, 60) },
	{ Name = "Rainbow", Mult = 8, Color = Color3.fromRGB(255, 120, 220) },
	{ Name = "Void", Mult = 20, Color = Color3.fromRGB(140, 70, 255) },
}
Dragons.EvolveCost = 5

-- Forza base dell'isola: ogni isola i draghi sono 5 volte più forti.
function Dragons.IslandBasePower(islandIndex: number): number
	return 4 * 5 ^ (islandIndex - 1)
end

-- Draghi delle uova, isola per isola: { id, nome, elemento, secondo elemento } nell'ordine delle rarità sopra.
local EGG_SETS = {
	{
		{ "SproutDrake", "Sprout Drake", "Nature" },
		{ "PebbleDrake", "Pebble Drake", "Earth" },
		{ "BreezePup", "Breeze Pup", "Air" },
		{ "EmberHatchling", "Ember Hatchling", "Fire" },
		{ "BloomWyrm", "Bloom Wyrm", "Nature" },
		{ "MeadowGuardian", "Meadow Guardian", "Nature", "Earth" },
		{ "SunpetalDragon", "Sunpetal Dragon", "Light", "Nature" },
		{ "VerdantSeraph", "Verdant Seraph", "Nature", "Light" },
		{ "GlitchSprout", "Glitch Sprout", "Shadow", "Nature" },
	},
	{
		{ "MossDrake", "Moss Drake", "Nature" },
		{ "AcornWyvern", "Acorn Wyvern", "Earth" },
		{ "OwlDrake", "Owl Drake", "Air" },
		{ "ThornDragon", "Thorn Dragon", "Nature" },
		{ "ElderOakDragon", "Elder Oak Dragon", "Earth" },
		{ "AncientTreantDragon", "Ancient Treant Dragon", "Earth", "Nature" },
		{ "DruidDragon", "Druid Dragon", "Nature", "Light" },
		{ "ForestSpiritWyrm", "Forest Spirit Wyrm", "Light", "Nature" },
		{ "HollowShade", "Hollow Shade", "Shadow", "Earth" },
	},
	{
		{ "ShellDrake", "Shell Drake", "Water" },
		{ "CoralDrake", "Coral Drake", "Water" },
		{ "TideWyvern", "Tide Wyvern", "Water" },
		{ "PearlDragon", "Pearl Dragon", "Light" },
		{ "LeviathanPup", "Leviathan Pup", "Water" },
		{ "KrakenDragon", "Kraken Dragon", "Water", "Shadow" },
		{ "TsunamiLord", "Tsunami Lord", "Water", "Air" },
		{ "AbyssalSeraph", "Abyssal Seraph", "Water", "Light" },
		{ "SunkenRelic", "Sunken Relic", "Shadow", "Water" },
	},
	{
		{ "SandDrake", "Sand Drake", "Earth" },
		{ "CactusDrake", "Cactus Drake", "Nature" },
		{ "DuneWyvern", "Dune Wyvern", "Air" },
		{ "ScarabDragon", "Scarab Dragon", "Earth" },
		{ "PharaohDragon", "Pharaoh Dragon", "Light" },
		{ "SphinxDragon", "Sphinx Dragon", "Earth", "Light" },
		{ "MirageDragon", "Mirage Dragon", "Light", "Air" },
		{ "SunGodDragon", "Sun God Dragon", "Fire", "Light" },
		{ "SandglassWyrm", "Sandglass Wyrm", "Shadow", "Earth" },
	},
	{
		{ "CinderDrake", "Cinder Drake", "Fire" },
		{ "MagmaDrake", "Magma Drake", "Fire" },
		{ "AshWyvern", "Ash Wyvern", "Shadow" },
		{ "InfernoDragon", "Inferno Dragon", "Fire" },
		{ "PhoenixDragon", "Phoenix Dragon", "Fire" },
		{ "MagmaKing", "Magma King", "Fire", "Earth" },
		{ "HellfireDragon", "Hellfire Dragon", "Fire", "Shadow" },
		{ "SolarFlareWyrm", "Solar Flare Wyrm", "Light", "Fire" },
		{ "ObsidianHorror", "Obsidian Horror", "Shadow", "Fire" },
	},
	{
		{ "FrostDrake", "Frost Drake", "Ice" },
		{ "SnowballDrake", "Snowball Drake", "Ice" },
		{ "IcicleWyvern", "Icicle Wyvern", "Water" },
		{ "BlizzardDragon", "Blizzard Dragon", "Ice" },
		{ "GlacierKing", "Glacier King", "Ice" },
		{ "FrostTitan", "Frost Titan", "Ice", "Water" },
		{ "AuroraWyrm", "Aurora Wyrm", "Light", "Ice" },
		{ "EternalWinter", "Eternal Winter", "Ice", "Light" },
		{ "FrozenVoid", "Frozen Void", "Shadow", "Ice" },
	},
	{
		{ "SparkDrake", "Spark Drake", "Lightning" },
		{ "StaticDrake", "Static Drake", "Lightning" },
		{ "VoltWyvern", "Volt Wyvern", "Air" },
		{ "StormDragon", "Storm Dragon", "Lightning" },
		{ "ThunderTitan", "Thunder Titan", "Lightning" },
		{ "StormEmperor", "Storm Emperor", "Lightning", "Air" },
		{ "PlasmaGod", "Plasma God", "Lightning", "Fire" },
		{ "ZeusDragon", "Zeus Dragon", "Light", "Lightning" },
		{ "StaticGhost", "Static Ghost", "Shadow", "Lightning" },
	},
	{
		{ "CloudDrake", "Cloud Drake", "Air" },
		{ "HaloDrake", "Halo Drake", "Light" },
		{ "SkyWyvern", "Sky Wyvern", "Air" },
		{ "AuroraDragon", "Aurora Dragon", "Light" },
		{ "CelestialDragon", "Celestial Dragon", "Light" },
		{ "HeavensGateDragon", "Heaven's Gate Dragon", "Light", "Air" },
		{ "ArchangelDragon", "Archangel Dragon", "Light", "Fire" },
		{ "CosmicDragon", "Cosmic Dragon", "Air", "Shadow" },
		{ "TheVoidDragon", "The Void Dragon", "Shadow", "Light" },
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
			Element2 = entry[4],
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

-- Draghi degli eventi e dell'admin abuse: escono solo in quei momenti.
local function eventDragon(id, name, element, element2, power)
	Dragons.List[id] = { Id = id, Name = name, Element = element, Element2 = element2, Rarity = "Event", Power = power, Exclusive = true, Crown = true }
end

eventDragon("LoyalDrake", "Loyal Drake", "Light", "Nature", 900) -- 7° giorno del premio giornaliero
eventDragon("CupidDrake", "Cupid Drake", "Light", "Fire", 3000)
eventDragon("BunnyDrake", "Bunny Drake", "Nature", "Light", 3000)
eventDragon("SurfDrake", "Surf Drake", "Water", "Light", 3000)
eventDragon("PumpkinDrake", "Pumpkin Drake", "Fire", "Shadow", 3000)
eventDragon("JollyDrake", "Jolly Drake", "Ice", "Fire", 3000)
eventDragon("AdminFireDrake", "Admin Fire Drake", "Fire", "Light", 12000)
eventDragon("AdminWaterDrake", "Admin Water Drake", "Water", "Light", 12000)
eventDragon("AdminStormDrake", "Admin Storm Drake", "Lightning", "Shadow", 12000)
eventDragon("AdminShadowDrake", "Admin Shadow Drake", "Shadow", "Light", 12000)
eventDragon("AdminLightDrake", "Admin Light Drake", "Light", "Fire", 12000)
eventDragon("AdminNatureDrake", "Admin Nature Drake", "Nature", "Light", 12000)

-- Ibridi del nido: la forza vera dipende dai genitori ed è salvata nel drago (campo Base).
do
	local Combos = require(script.Parent.Combos)
	for _, c in Combos.List do
		Dragons.List[c[3]] = { Id = c[3], Name = c[4], Element = c[1], Element2 = c[2], Rarity = c[5], Power = 0, Hybrid = true, Weather = c[6] }
	end
end

function Dragons.Get(id: string)
	return Dragons.List[id]
end

return Dragons
