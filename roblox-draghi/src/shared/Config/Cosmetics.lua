-- Aure (particelle attorno al personaggio) e scie (dietro quando cammini).
-- Price = { Gems = n }, { Product = "NomeProdotto" } (Robux, vedi Products.lua), { VIP = true },
-- { Rebirths = n } o { Eggs = n } (traguardi).
local Cosmetics = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Rarity serve solo per il colore del bordo nel negozio.
-- Rebirths / Eggs = si sblocca gratis raggiungendo quel numero di rinascite o di uova aperte.
Cosmetics.Auras = {
	{ Id = "Leaf", Name = "Leaf Aura", Icon = "🍃", Rarity = "Common", Colors = { rgb(120, 220, 90), rgb(220, 255, 140) }, Price = { Gems = 25 } },
	{ Id = "Bubble", Name = "Bubble Aura", Icon = "🫧", Rarity = "Common", Colors = { rgb(140, 210, 255), rgb(230, 250, 255) }, Price = { Gems = 30 } },
	{ Id = "Ember", Name = "Ember Aura", Icon = "🔥", Rarity = "Uncommon", Colors = { rgb(255, 110, 40), rgb(255, 220, 90) }, Price = { Gems = 50 } },
	{ Id = "Frost", Name = "Frost Aura", Icon = "❄️", Rarity = "Uncommon", Colors = { rgb(150, 230, 255), rgb(255, 255, 255) }, Price = { Gems = 50 } },
	{ Id = "Sand", Name = "Sandstorm Aura", Icon = "🏜️", Rarity = "Uncommon", Colors = { rgb(230, 190, 110), rgb(255, 240, 200) }, Price = { Eggs = 100 } },
	{ Id = "Petal", Name = "Petal Aura", Icon = "🌸", Rarity = "Rare", Colors = { rgb(255, 150, 200), rgb(255, 230, 240) }, Price = { Gems = 90 } },
	{ Id = "Storm", Name = "Storm Aura", Icon = "⚡", Rarity = "Rare", Colors = { rgb(255, 230, 70), rgb(120, 160, 255) }, Price = { Gems = 120 } },
	{ Id = "Toxic", Name = "Toxic Aura", Icon = "☢️", Rarity = "Rare", Colors = { rgb(140, 255, 60), rgb(40, 120, 20) }, Price = { Eggs = 500 } },
	{ Id = "Ocean", Name = "Ocean Aura", Icon = "🌊", Rarity = "Epic", Colors = { rgb(30, 120, 255), rgb(100, 230, 255) }, Price = { Gems = 180 } },
	{ Id = "Shadow", Name = "Shadow Aura", Icon = "🌑", Rarity = "Epic", Colors = { rgb(90, 60, 150), rgb(20, 10, 40) }, Price = { Gems = 220 } },
	{ Id = "Inferno", Name = "Inferno Aura", Icon = "🌋", Rarity = "Epic", Colors = { rgb(255, 60, 20), rgb(80, 0, 0) }, Price = { Rebirths = 1 } },
	{ Id = "Angel", Name = "Angel Aura", Icon = "😇", Rarity = "Legendary", Colors = { rgb(255, 250, 220), rgb(255, 210, 120) }, Price = { Gems = 350 } },
	{ Id = "Blossom", Name = "Sakura Aura", Icon = "🌺", Rarity = "Legendary", Colors = { rgb(255, 120, 170), rgb(255, 255, 255) }, Price = { Eggs = 2000 } },
	{ Id = "Nebula", Name = "Nebula Aura", Icon = "🌌", Rarity = "Mythic", Colors = { rgb(160, 60, 255), rgb(60, 200, 255) }, Price = { Gems = 600 } },
	{ Id = "Dragonfire", Name = "Dragonfire Aura", Icon = "🐉", Rarity = "Mythic", Colors = { rgb(255, 90, 30), rgb(255, 230, 60) }, Price = { Rebirths = 5 } },
	{ Id = "Holy", Name = "Holy Aura", Icon = "✝️", Rarity = "Divine", Colors = { rgb(255, 255, 210), rgb(255, 230, 120) }, Price = { Gems = 1200 } },
	{ Id = "Starfall", Name = "Starfall Aura", Icon = "🌠", Rarity = "Celestial", Colors = { rgb(120, 230, 255), rgb(255, 255, 255) }, Price = { Rebirths = 15 } },
	{ Id = "Crown", Name = "Royal Aura", Icon = "👑", Rarity = "Legendary", Colors = { rgb(255, 200, 60), rgb(255, 255, 200) }, Price = { VIP = true } },
	{ Id = "Rainbow", Name = "Rainbow Aura", Icon = "🌈", Rarity = "Mythic", Rainbow = true, Colors = { rgb(255, 80, 80), rgb(80, 160, 255) }, Price = { Product = "AuraRainbow" } },
	{ Id = "Glitch", Name = "Glitch Aura", Icon = "👾", Rarity = "Secret", Colors = { rgb(255, 0, 140), rgb(0, 255, 200) }, Price = { Eggs = 10000 } },
}

Cosmetics.Trails = {
	{ Id = "Spark", Name = "Spark Trail", Icon = "✨", Rarity = "Common", Colors = { rgb(255, 255, 200), rgb(255, 220, 120) }, Price = { Gems = 20 } },
	{ Id = "Bubble", Name = "Bubble Trail", Icon = "🫧", Rarity = "Common", Colors = { rgb(140, 210, 255), rgb(220, 245, 255) }, Price = { Gems = 30 } },
	{ Id = "Grass", Name = "Grass Trail", Icon = "🌿", Rarity = "Common", Colors = { rgb(90, 200, 80), rgb(200, 255, 140) }, Price = { Eggs = 25 } },
	{ Id = "Candy", Name = "Candy Trail", Icon = "🍬", Rarity = "Uncommon", Colors = { rgb(255, 120, 200), rgb(140, 220, 255) }, Price = { Gems = 50 } },
	{ Id = "Flame", Name = "Flame Trail", Icon = "🔥", Rarity = "Uncommon", Colors = { rgb(255, 80, 30), rgb(255, 200, 60) }, Price = { Gems = 70 } },
	{ Id = "Ice", Name = "Ice Trail", Icon = "🧊", Rarity = "Rare", Colors = { rgb(120, 220, 255), rgb(240, 255, 255) }, Price = { Gems = 90 } },
	{ Id = "Honey", Name = "Honey Trail", Icon = "🍯", Rarity = "Rare", Colors = { rgb(255, 190, 40), rgb(255, 240, 160) }, Price = { Eggs = 250 } },
	{ Id = "Bolt", Name = "Lightning Trail", Icon = "⚡", Rarity = "Epic", Colors = { rgb(255, 240, 80), rgb(255, 255, 255) }, Price = { Gems = 160 } },
	{ Id = "Lava", Name = "Lava Trail", Icon = "🌋", Rarity = "Epic", Colors = { rgb(255, 70, 0), rgb(60, 0, 0) }, Price = { Gems = 200 } },
	{ Id = "Ghost", Name = "Ghost Trail", Icon = "👻", Rarity = "Epic", Colors = { rgb(230, 240, 255), rgb(150, 160, 200) }, Price = { Rebirths = 2 } },
	{ Id = "Void", Name = "Void Trail", Icon = "🌌", Rarity = "Legendary", Colors = { rgb(120, 60, 200), rgb(10, 0, 30) }, Price = { Gems = 300 } },
	{ Id = "Aurora", Name = "Aurora Trail", Icon = "🌈", Rarity = "Legendary", Colors = { rgb(80, 255, 180), rgb(120, 80, 255) }, Price = { Eggs = 1500 } },
	{ Id = "Comet", Name = "Comet Trail", Icon = "☄️", Rarity = "Mythic", Colors = { rgb(255, 160, 60), rgb(160, 90, 255) }, Price = { Gems = 550 } },
	{ Id = "Dragon", Name = "Dragon Scale Trail", Icon = "🐲", Rarity = "Mythic", Colors = { rgb(60, 200, 120), rgb(255, 210, 60) }, Price = { Rebirths = 8 } },
	{ Id = "Heaven", Name = "Heaven Trail", Icon = "🕊️", Rarity = "Divine", Colors = { rgb(255, 255, 255), rgb(255, 230, 150) }, Price = { Gems = 1100 } },
	{ Id = "Galaxy", Name = "Galaxy Trail", Icon = "🪐", Rarity = "Celestial", Colors = { rgb(40, 20, 120), rgb(200, 120, 255) }, Price = { Rebirths = 20 } },
	{ Id = "Gold", Name = "Golden Trail", Icon = "👑", Rarity = "Legendary", Colors = { rgb(255, 200, 40), rgb(255, 250, 200) }, Price = { VIP = true } },
	{ Id = "Rainbow", Name = "Rainbow Trail", Icon = "🌈", Rarity = "Mythic", Rainbow = true, Colors = { rgb(255, 80, 80), rgb(80, 160, 255) }, Price = { Product = "TrailRainbow" } },
	{ Id = "Pixel", Name = "Pixel Trail", Icon = "🕹️", Rarity = "Secret", Colors = { rgb(0, 255, 120), rgb(255, 0, 200) }, Price = { Eggs = 7500 } },
	{ Id = "Infinity", Name = "Infinity Trail", Icon = "♾️", Rarity = "Secret", Colors = { rgb(255, 255, 255), rgb(0, 0, 0) }, Price = { Rebirths = 50 } },
}

-- È già del giocatore? (comprata, regalo del VIP o traguardo raggiunto)
function Cosmetics.Owns(item, kind: string, data, hasVip: boolean): boolean
	local price = item.Price
	if price.VIP then
		return hasVip
	end
	if price.Rebirths then
		return (data.Rebirths or 0) >= price.Rebirths
	end
	if price.Eggs then
		return ((data.Stats and data.Stats.EggsHatched) or data.EggsHatched or 0) >= price.Eggs
	end
	return data.Cosmetics ~= nil and data.Cosmetics.Owned[kind .. "_" .. item.Id] == true
end

function Cosmetics.Find(kind: string, id: string)
	local list = if kind == "Aura" then Cosmetics.Auras elseif kind == "Trail" then Cosmetics.Trails else nil
	if not list then
		return nil
	end
	for _, c in list do
		if c.Id == id then
			return c
		end
	end
	return nil
end

-- Colori arcobaleno per aure e scie "Rainbow".
Cosmetics.RainbowSequence = ColorSequence.new({
	ColorSequenceKeypoint.new(0, rgb(255, 70, 70)),
	ColorSequenceKeypoint.new(0.2, rgb(255, 170, 50)),
	ColorSequenceKeypoint.new(0.4, rgb(255, 240, 70)),
	ColorSequenceKeypoint.new(0.6, rgb(80, 220, 110)),
	ColorSequenceKeypoint.new(0.8, rgb(70, 150, 255)),
	ColorSequenceKeypoint.new(1, rgb(190, 90, 255)),
})

return Cosmetics
