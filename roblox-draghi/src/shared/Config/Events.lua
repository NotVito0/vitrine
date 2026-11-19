-- Eventi automatici. Tutti gli orari sono in UTC (ora italiana = UTC+1 d'inverno, UTC+2 d'estate).
local Events = {}

-- Mescola un numero in un seme ben distribuito (finestre di tempo vicine danno risultati molto diversi).
local function seed(n: number): number
	n = math.floor(n) % 4294967296
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = (n * 73244475) % 4294967296
	n = bit32.bxor(n, bit32.rshift(n, 16))
	n = (n * 73244475) % 4294967296
	return bit32.bxor(n, bit32.rshift(n, 16))
end

-- Eventi delle feste. From/To = { mese, giorno }. Mult = moltiplicatori attivi per tutto l'evento.
-- Dragon = drago esclusivo che i mostri possono lasciare durante l'evento (DropChance per mostro).
Events.Seasonal = {
	{ Id = "Valentine", Name = "Valentine's Event", Icon = "💘", From = { 2, 10 }, To = { 2, 16 }, Mult = { Coins = 1.5 }, Dragon = "CupidDrake", DropChance = 1 / 400, Tint = Color3.fromRGB(255, 120, 170) },
	{ Id = "Easter", Name = "Easter Egg Hunt", Icon = "🐣", Easter = 7, Mult = { Luck = 1.5 }, Dragon = "BunnyDrake", DropChance = 1 / 400, Tint = Color3.fromRGB(255, 230, 140) },
	{ Id = "Summer", Name = "Summer Splash", Icon = "🏖️", From = { 7, 1 }, To = { 8, 31 }, Mult = { Coins = 1.5 }, Dragon = "SurfDrake", DropChance = 1 / 600, Tint = Color3.fromRGB(90, 200, 255) },
	{ Id = "School", Name = "Back to School", Icon = "🏫", From = { 9, 1 }, To = { 9, 14 }, Mult = { Training = 2 } },
	{ Id = "Halloween", Name = "Halloween Night", Icon = "🎃", From = { 10, 20 }, To = { 11, 3 }, Mult = { Damage = 1.5, Coins = 1.5 }, Dragon = "PumpkinDrake", DropChance = 1 / 400, Tint = Color3.fromRGB(255, 140, 40) },
	{ Id = "BlackFriday", Name = "Black Friday", Icon = "🛍️", From = { 11, 24 }, To = { 11, 30 }, Mult = { Luck = 2 } },
	{ Id = "Christmas", Name = "Winter Holidays", Icon = "🎄", From = { 12, 15 }, To = { 1, 6 }, Mult = { Coins = 2 }, Dragon = "JollyDrake", DropChance = 1 / 400, Tint = Color3.fromRGB(120, 220, 160) },
}

-- Ora d'oro ogni giorno.
Events.GoldenHour = { HourUTC = 18, Minutes = 30, Mult = { Coins = 2 }, Name = "Golden Hour", Icon = "🌅" }

-- Weekend (sabato e domenica UTC).
Events.Weekend = { Mult = { Coins = 2 }, Name = "Weekend x2 Coins", Icon = "🎉" }

-- Pioggia di meteore: ogni ora al minuto indicato, per Duration secondi. Fa cadere mostri di cristallo.
Events.Meteors = { Minute = 30, Duration = 180, PerIsland = 4, Name = "Meteor Shower", Icon = "☄️" }

-- Admin abuse automatico: ogni sabato all'ora indicata (UTC). 17 UTC = 18 italiane d'inverno, 19 d'estate.
Events.AdminAbuse = {
	Weekday = 7, -- os.date: 1 = domenica, 7 = sabato
	HourUTC = 17,
	Count = 7, -- eventi per sessione, più il finale
	EventSeconds = 300,
	WarnMinutes = { 60, 30, 10, 5, 1 },
}

-- Chi può usare i comandi admin in chat oltre al proprietario del gioco (UserId).
Events.Admins = {}

-- Tutti gli eventi possibili dell'admin abuse. Ogni sabato se ne pescano 7 a caso,
-- senza ripetere quelli della settimana prima. Mult = moltiplicatori, Kind = azione speciale.
Events.AdminPool = {
	{ Id = "Luck10", Name = "LUCK x10", Icon = "🍀", Mult = { Luck = 10 } },
	{ Id = "Coins5", Name = "COINS x5", Icon = "💰", Mult = { Coins = 5 } },
	{ Id = "Damage5", Name = "DAMAGE x5", Icon = "⚔️", Mult = { Damage = 5 } },
	{ Id = "Training10", Name = "TRAINING x10", Icon = "🏋️", Mult = { Training = 10 } },
	{ Id = "ShinyParty", Name = "SHINY PARTY x10", Icon = "✨", Mult = { Shiny = 10 } },
	{ Id = "EggRain", Name = "EGG RAIN", Icon = "🥚", Kind = "EggRain" },
	{ Id = "Boss", Name = "GIANT BOSS", Icon = "👹", Kind = "Boss" },
	{ Id = "GemStorm", Name = "GEM STORM", Icon = "💎", Kind = "GemStorm" },
	{ Id = "Golden", Name = "GOLDEN MONSTERS x10", Icon = "🌟", Kind = "Golden" },
	{ Id = "LowGravity", Name = "LOW GRAVITY", Icon = "🪐", Kind = "Gravity" },
	{ Id = "Giants", Name = "GIANT DRAGONS", Icon = "🐲", Kind = "Giants", Mult = { Damage = 2 } },
	{ Id = "SpeedRush", Name = "SPEED RUSH", Icon = "⚡", Kind = "Speed" },
	{ Id = "Eclipse", Name = "FORCED ECLIPSE", Icon = "🌑", Kind = "Eclipse" },
	{ Id = "FreePotion", Name = "FREE SUPER LUCK", Icon = "🌈", Kind = "FreePotion" },
	{ Id = "Chaos", Name = "CHAOS: ALL x3", Icon = "🌀", Mult = { Coins = 3, Damage = 3, Luck = 3, Training = 3 } },
}

-- Temi a rotazione: cambiano nome e colore dell'admin abuse di ogni settimana.
Events.AdminThemes = {
	{ Name = "Fire Abuse", Color = Color3.fromRGB(255, 110, 50) },
	{ Name = "Chaos Abuse", Color = Color3.fromRGB(190, 90, 255) },
	{ Name = "Boss Abuse", Color = Color3.fromRGB(255, 70, 90) },
	{ Name = "Space Abuse", Color = Color3.fromRGB(90, 120, 255) },
	{ Name = "Ocean Abuse", Color = Color3.fromRGB(60, 190, 255) },
	{ Name = "Gold Abuse", Color = Color3.fromRGB(255, 200, 60) },
	{ Name = "Thunder Abuse", Color = Color3.fromRGB(255, 230, 80) },
	{ Name = "Shadow Abuse", Color = Color3.fromRGB(120, 80, 180) },
}

-- Il finale regala a tutti il drago esclusivo della settimana (a rotazione).
Events.AdminDragons = { "AdminFireDrake", "AdminWaterDrake", "AdminStormDrake", "AdminShadowDrake", "AdminLightDrake", "AdminNatureDrake" }

-- Data di Pasqua (calcolo gregoriano). Ritorna mese, giorno.
function Events.Easter(year: number): (number, number)
	local a = year % 19
	local b = year // 100
	local c = year % 100
	local d = b // 4
	local e = b % 4
	local f = (b + 8) // 25
	local g = (b - f + 1) // 3
	local h = (19 * a + b - d - g + 15) % 30
	local i = c // 4
	local k = c % 4
	local l = (32 + 2 * e + 2 * i - h - k) % 7
	local m = (a + 11 * h + 22 * l) // 451
	local month = (h + l - 7 * m + 114) // 31
	local day = ((h + l - 7 * m + 114) % 31) + 1
	return month, day
end

-- È attivo questo evento stagionale alla data (UTC) indicata?
function Events.SeasonActive(event, t)
	local date = os.date("!*t", t)
	if event.Easter then
		local m, d = Events.Easter(date.year)
		local easter = os.time({ year = date.year, month = m, day = d, hour = 12 })
		return math.abs(t - easter) <= event.Easter * 86400
	end
	local now = date.month * 100 + date.day
	local from = event.From[1] * 100 + event.From[2]
	local to = event.To[1] * 100 + event.To[2]
	if from <= to then
		return now >= from and now <= to
	end
	return now >= from or now <= to -- a cavallo di capodanno
end

-- Inizio (UTC) dell'admin abuse della settimana che contiene `t`, e numero della settimana.
function Events.AdminStart(t: number): (number, number)
	local date = os.date("!*t", t)
	local daysToSaturday = (Events.AdminAbuse.Weekday - date.wday) % 7
	local dayStart = t - (date.hour * 3600 + date.min * 60 + date.sec)
	local start = dayStart + daysToSaturday * 86400 + Events.AdminAbuse.HourUTC * 3600
	local length = (Events.AdminAbuse.Count + 1) * Events.AdminAbuse.EventSeconds
	if start + length < t then
		start += 7 * 86400 -- quello di oggi è già finito: il prossimo è sabato prossimo
	end
	return start, start // (7 * 86400)
end

-- I 7 eventi della settimana, mai gli stessi della settimana prima.
local function basePick(week: number, exclude)
	local rng = Random.new(seed(week * 101 + 3))
	local pool = {}
	for _, e in Events.AdminPool do
		if not (exclude and exclude[e.Id]) then
			table.insert(pool, e)
		end
	end
	local picks = {}
	for _ = 1, math.min(Events.AdminAbuse.Count, #pool) do
		local i = rng:NextInteger(1, #pool)
		table.insert(picks, table.remove(pool, i))
	end
	return picks
end

-- Le scelte di ogni settimana partono da una settimana fissa e vanno avanti una alla volta,
-- escludendo sempre quelle della settimana prima. Così tutti i server ottengono lo stesso risultato.
local EPOCH_WEEK = 2960
local chain = { [EPOCH_WEEK] = nil }
local chainTop = EPOCH_WEEK - 1

local function picksFor(week: number)
	if week < EPOCH_WEEK or week > chainTop + 520 then
		return basePick(week) -- fuori dalla catena (es. admin abuse lanciato a mano)
	end
	while chainTop < week do
		local nextWeek = chainTop + 1
		local exclude = {}
		for _, e in chain[chainTop] or {} do
			exclude[e.Id] = true
		end
		chain[nextWeek] = basePick(nextWeek, exclude)
		chainTop = nextWeek
	end
	return chain[week]
end

function Events.AdminPlan(week: number)
	local picks = table.clone(picksFor(week))
	local theme = Events.AdminThemes[(week % #Events.AdminThemes) + 1]
	local dragon = Events.AdminDragons[(week % #Events.AdminDragons) + 1]
	table.insert(picks, { Id = "Finale", Name = "FINALE: FREE " .. dragon:gsub("Admin", ""):gsub("Drake", " DRAKE"):upper(), Icon = "🐉", Kind = "AdminDragon", Dragon = dragon })
	return picks, theme
end

return Events
