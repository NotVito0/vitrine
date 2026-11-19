-- Meteo: cambia ogni Cycle secondi, uguale in tutti i server.
-- Ogni meteo rafforza un elemento (+25% danni) e apre gli incroci che lo richiedono.
local Weather = {}

-- Mescola un numero in un seme ben distribuito (finestre di tempo vicine danno risultati molto diversi).
local function seed(n: number): number
	n = math.floor(n) % 4294967296
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = (n * 73244475) % 4294967296
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = (n * 73244475) % 4294967296
	return bit32.bxor(n, bit32.rshift(n, 16))
end

Weather.Cycle = 900 -- 15 minuti

Weather.Types = {
	Sunny = { Name = "Sunny", Icon = "☀️", Weight = 30, Element = "Fire", Luck = 1 },
	Windy = { Name = "Windy", Icon = "🌪️", Weight = 16, Element = "Air", Luck = 1 },
	Rain = { Name = "Rain", Icon = "🌧️", Weight = 22, Element = "Water", Luck = 1 },
	Storm = { Name = "Storm", Icon = "⛈️", Weight = 14, Element = "Lightning", Luck = 1 },
	Snow = { Name = "Snow", Icon = "❄️", Weight = 14, Element = "Ice", Luck = 1 },
	Eclipse = { Name = "Eclipse", Icon = "🌑", Weight = 4, Element = "Shadow", Luck = 1.5 },
}

Weather.Order = { "Sunny", "Windy", "Rain", "Storm", "Snow", "Eclipse" }
Weather.ElementBoost = 1.25

function Weather.Window(serverTime: number): number
	return math.floor(serverTime / Weather.Cycle)
end

function Weather.At(window: number): string
	local rng = Random.new(seed(window * 31 + 5))
	local total = 0
	for _, key in Weather.Order do
		total += Weather.Types[key].Weight
	end
	local roll = rng:NextNumber(0, total)
	for _, key in Weather.Order do
		roll -= Weather.Types[key].Weight
		if roll <= 0 then
			return key
		end
	end
	return "Sunny"
end

return Weather
