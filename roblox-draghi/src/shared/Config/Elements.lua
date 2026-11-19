-- Gli elementi dei draghi e dei mostri, e chi batte chi.
-- Un drago forte contro il mostro fa danni x1.75, uno debole x0.6.
local Elements = {}

Elements.List = {
	Fire = { Name = "Fire", Icon = "🔥", Color = Color3.fromRGB(255, 107, 61), Color2 = Color3.fromRGB(255, 192, 97) },
	Water = { Name = "Water", Icon = "💧", Color = Color3.fromRGB(61, 155, 255), Color2 = Color3.fromRGB(166, 220, 255) },
	Nature = { Name = "Nature", Icon = "🌿", Color = Color3.fromRGB(96, 196, 72), Color2 = Color3.fromRGB(214, 245, 140) },
	Earth = { Name = "Earth", Icon = "🪨", Color = Color3.fromRGB(168, 119, 63), Color2 = Color3.fromRGB(226, 190, 128) },
	Air = { Name = "Air", Icon = "🌪️", Color = Color3.fromRGB(191, 230, 255), Color2 = Color3.fromRGB(255, 255, 255) },
	Ice = { Name = "Ice", Icon = "❄️", Color = Color3.fromRGB(127, 220, 245), Color2 = Color3.fromRGB(233, 251, 255) },
	Lightning = { Name = "Lightning", Icon = "⚡", Color = Color3.fromRGB(255, 210, 61), Color2 = Color3.fromRGB(255, 244, 173) },
	Light = { Name = "Light", Icon = "🌟", Color = Color3.fromRGB(255, 240, 179), Color2 = Color3.fromRGB(255, 198, 236) },
	Shadow = { Name = "Shadow", Icon = "🌑", Color = Color3.fromRGB(106, 78, 168), Color2 = Color3.fromRGB(44, 32, 80) },
}

-- attaccante -> elementi contro cui è forte
Elements.Strong = {
	Water = { "Fire", "Earth" },
	Fire = { "Nature", "Ice" },
	Nature = { "Water", "Earth" },
	Earth = { "Lightning", "Fire" },
	Ice = { "Air", "Nature" },
	Lightning = { "Water", "Air" },
	Air = { "Nature" },
	Light = { "Shadow" },
	Shadow = { "Light" },
}

Elements.StrongMult = 1.75
Elements.WeakMult = 0.6

local function beats(a: string, b: string): boolean
	local list = Elements.Strong[a]
	if not list then
		return false
	end
	return table.find(list, b) ~= nil
end

function Elements.Multiplier(attacker: string, defender: string): number
	if beats(attacker, defender) then
		return Elements.StrongMult
	end
	if beats(defender, attacker) then
		return Elements.WeakMult
	end
	return 1
end

return Elements
