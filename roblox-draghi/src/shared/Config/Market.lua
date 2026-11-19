-- Il mercato: ogni RestockSeconds cambia la merce e si riempiono le scorte.
-- È uguale per tutti i giocatori e tutti i server (dipende solo dall'orario),
-- così la gente se ne parla: "ora c'è la Super Luck al mercato!".
local Market = {}

-- Mescola un numero in un seme ben distribuito (finestre di tempo vicine danno risultati molto diversi).
local function seed(n: number): number
	n = math.floor(n) % 4294967296
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = (n * 73244475) % 4294967296
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = (n * 73244475) % 4294967296
	return bit32.bxor(n, bit32.rshift(n, 16))
end

Market.RestockSeconds = 300
Market.Slots = 4

-- Merce possibile, con il peso (più alto = esce più spesso).
-- EggPrice: prezzo in monete pari a N uova della tua isola migliore. Gems: prezzo in cristalli.
Market.Pool = {
	{ Potion = "Luck", Weight = 30, Stock = 3, EggPrice = 2 },
	{ Potion = "Coins", Weight = 30, Stock = 3, EggPrice = 2 },
	{ Potion = "Damage", Weight = 26, Stock = 3, EggPrice = 2 },
	{ Potion = "Training", Weight = 22, Stock = 3, EggPrice = 3 },
	{ Potion = "Shiny", Weight = 9, Stock = 2, Gems = 15 },
	{ Potion = "SuperLuck", Weight = 4, Stock = 1, Gems = 40 },
}

function Market.Window(serverTime: number): number
	return math.floor(serverTime / Market.RestockSeconds)
end

-- La merce di una finestra di tempo. Stesso risultato su server e client.
function Market.Items(window: number)
	local rng = Random.new(seed(window * 7919 + 17))
	local pool = table.clone(Market.Pool)
	local items = {}
	for _ = 1, math.min(Market.Slots, #pool) do
		local total = 0
		for _, item in pool do
			total += item.Weight
		end
		local roll = rng:NextNumber(0, total)
		for i, item in pool do
			roll -= item.Weight
			if roll <= 0 then
				table.insert(items, item)
				table.remove(pool, i)
				break
			end
		end
	end
	return items
end

return Market
