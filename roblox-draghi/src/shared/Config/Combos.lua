-- Incroci del nido: due draghi di elementi diversi danno un drago ibrido.
-- Weather = l'incrocio riesce solo con quel meteo (altrimenti nasce una copia del genitore più debole).
-- Per aggiungere incroci in un aggiornamento basta aggiungere righe qui.
local Combos = {}

Combos.List = {
	{ "Fire", "Water", "SteamDrake", "Steam Drake", "Rare" },
	{ "Water", "Earth", "SwampDrake", "Swamp Drake", "Rare" },
	{ "Earth", "Air", "SandstormDrake", "Sandstorm Drake", "Rare" },
	{ "Nature", "Water", "LotusDrake", "Lotus Drake", "Rare" },
	{ "Nature", "Earth", "GroveDrake", "Grove Drake", "Rare" },
	{ "Fire", "Earth", "LavaDrake", "Lava Drake", "Epic" },
	{ "Water", "Air", "MistDrake", "Mist Drake", "Epic" },
	{ "Fire", "Lightning", "PlasmaDrake", "Plasma Drake", "Epic" },
	{ "Water", "Ice", "FrostwaveDrake", "Frostwave Drake", "Epic" },
	{ "Nature", "Light", "BloomlightDrake", "Bloomlight Drake", "Epic" },
	{ "Ice", "Air", "BlizzardWyrm", "Blizzard Wyrm", "Epic", "Snow" },
	{ "Fire", "Air", "PhoenixWyrm", "Phoenix Wyrm", "Legendary" },
	{ "Earth", "Shadow", "CryptDragon", "Crypt Dragon", "Legendary" },
	{ "Light", "Air", "SeraphDragon", "Seraph Dragon", "Legendary" },
	{ "Lightning", "Ice", "TempestDragon", "Tempest Dragon", "Legendary", "Storm" },
	{ "Lightning", "Water", "ThunderwaveDragon", "Thunderwave Dragon", "Legendary", "Rain" },
	{ "Fire", "Light", "SolarDragon", "Solar Dragon", "Legendary", "Sunny" },
	{ "Ice", "Shadow", "PolarNightDragon", "Polar Night Dragon", "Legendary", "Snow" },
	{ "Nature", "Shadow", "NightshadeDragon", "Nightshade Dragon", "Legendary", "Rain" },
	{ "Light", "Shadow", "EclipseDragon", "Eclipse Dragon", "Secret", "Eclipse" },
}

-- Forza dell'ibrido = (forza genitore A + forza genitore B) x questo valore.
Combos.PowerMult = { Rare = 1.3, Epic = 1.6, Legendary = 2, Secret = 2.8 }

-- Tempo nel nido, in secondi, e quanti cristalli costa finire subito.
Combos.NestSeconds = 90
Combos.SkipGems = 10

function Combos.Find(a: string, b: string)
	for _, c in Combos.List do
		if (c[1] == a and c[2] == b) or (c[1] == b and c[2] == a) then
			return { A = c[1], B = c[2], Id = c[3], Name = c[4], Rarity = c[5], Weather = c[6] }
		end
	end
	return nil
end

return Combos
