-- Aure (particelle attorno al personaggio) e scie (dietro quando cammini).
-- Price = { Gems = n } oppure { Product = "NomeProdotto" } (Robux, vedi Products.lua) oppure { VIP = true }.
local Cosmetics = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Cosmetics.Auras = {
	{ Id = "Leaf", Name = "Leaf Aura", Icon = "🍃", Colors = { rgb(120, 220, 90), rgb(220, 255, 140) }, Price = { Gems = 40 } },
	{ Id = "Ember", Name = "Ember Aura", Icon = "🔥", Colors = { rgb(255, 110, 40), rgb(255, 220, 90) }, Price = { Gems = 60 } },
	{ Id = "Frost", Name = "Frost Aura", Icon = "❄️", Colors = { rgb(150, 230, 255), rgb(255, 255, 255) }, Price = { Gems = 60 } },
	{ Id = "Storm", Name = "Storm Aura", Icon = "⚡", Colors = { rgb(255, 230, 70), rgb(120, 160, 255) }, Price = { Gems = 120 } },
	{ Id = "Shadow", Name = "Shadow Aura", Icon = "🌑", Colors = { rgb(90, 60, 150), rgb(20, 10, 40) }, Price = { Gems = 200 } },
	{ Id = "Angel", Name = "Angel Aura", Icon = "😇", Colors = { rgb(255, 250, 220), rgb(255, 210, 120) }, Price = { Gems = 300 } },
	{ Id = "Crown", Name = "Royal Aura", Icon = "👑", Colors = { rgb(255, 200, 60), rgb(255, 255, 200) }, Price = { VIP = true } },
	{ Id = "Rainbow", Name = "Rainbow Aura", Icon = "🌈", Rainbow = true, Colors = { rgb(255, 80, 80), rgb(80, 160, 255) }, Price = { Product = "AuraRainbow" } },
}

Cosmetics.Trails = {
	{ Id = "Spark", Name = "Spark Trail", Icon = "✨", Colors = { rgb(255, 255, 200), rgb(255, 220, 120) }, Price = { Gems = 30 } },
	{ Id = "Bubble", Name = "Bubble Trail", Icon = "🫧", Colors = { rgb(140, 210, 255), rgb(220, 245, 255) }, Price = { Gems = 40 } },
	{ Id = "Flame", Name = "Flame Trail", Icon = "🔥", Colors = { rgb(255, 80, 30), rgb(255, 200, 60) }, Price = { Gems = 80 } },
	{ Id = "Ice", Name = "Ice Trail", Icon = "🧊", Colors = { rgb(120, 220, 255), rgb(240, 255, 255) }, Price = { Gems = 80 } },
	{ Id = "Bolt", Name = "Lightning Trail", Icon = "⚡", Colors = { rgb(255, 240, 80), rgb(255, 255, 255) }, Price = { Gems = 150 } },
	{ Id = "Void", Name = "Void Trail", Icon = "🌌", Colors = { rgb(120, 60, 200), rgb(10, 0, 30) }, Price = { Gems = 200 } },
	{ Id = "Gold", Name = "Golden Trail", Icon = "👑", Colors = { rgb(255, 200, 40), rgb(255, 250, 200) }, Price = { VIP = true } },
	{ Id = "Rainbow", Name = "Rainbow Trail", Icon = "🌈", Rainbow = true, Colors = { rgb(255, 80, 80), rgb(80, 160, 255) }, Price = { Product = "TrailRainbow" } },
}

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
