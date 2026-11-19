-- Salvataggi dei giocatori su DataStore.
-- Un "lucchetto" di sessione impedisce che due server scrivano lo stesso giocatore
-- (succede quando si cambia server in fretta) e quindi che i progressi si perdano o si duplichino.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Balance = require(Shared.Config.Balance)

local DataService = {}

local STORE_NAME = "PlayerData_v1"
local LOCK_TIMEOUT = 150 -- secondi dopo cui un lucchetto di un server morto si considera scaduto
local AUTOSAVE = 90

local store
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local cache = {} -- player -> data
local noSave = {} -- player -> true se i dati non vanno salvati (Studio senza accesso alle API)
local loadedEvent = Instance.new("BindableEvent")
DataService.PlayerLoaded = loadedEvent.Event

local function template()
	return {
		Coins = 0,
		Gems = 0,
		Rebirths = 0,
		Dragons = {}, -- uid -> { Id, Level, Xp, Shiny, Serial }
		NextUid = 1,
		Equipped = {}, -- lista di uid
		Unlocked = { Meadow = true },
		Discovered = {},
		Purchases = {}, -- PurchaseId -> os.time(), per non dare due volte lo stesso acquisto
		OneTime = {}, -- pacchetti già comprati
		Boosts = {}, -- nome -> { Expires, Mult }
		Potions = {}, -- nome pozione -> quantità nell'inventario
		Market = { Window = 0, Bought = {} }, -- acquisti nel mercato nella finestra attuale
		Codes = {}, -- codici già usati
		Daily = { Day = 0, Last = -1 }, -- giorno della serie e ultimo giorno (UTC) ritirato
		-- Nest = { A, B, Ends } mentre un incrocio è in corso
		BonusTeamSlots = 0,
		Settings = { AutoEquip = true },
		Stats = { MonstersDefeated = 0, EggsHatched = 0, CoinsEarned = 0 },
		FirstJoin = os.time(),
	}
end

local function deepCopy(t)
	local c = {}
	for k, v in t do
		c[k] = if type(v) == "table" then deepCopy(v) else v
	end
	return c
end

-- Aggiunge ai dati vecchi i campi nuovi introdotti dagli aggiornamenti.
local function reconcile(data, tmpl)
	for k, v in tmpl do
		if data[k] == nil then
			data[k] = if type(v) == "table" then deepCopy(v) else v
		elseif type(v) == "table" and type(data[k]) == "table" and next(v) ~= nil and #v == 0 then
			reconcile(data[k], v)
		end
	end
end

local function key(player)
	return "u_" .. player.UserId
end

local function loadData(player)
	if not store then
		return nil
	end
	for attempt = 1, 6 do
		local result
		local locked = false
		local force = attempt == 6
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function(old)
				old = old or template()
				local lock = old.Lock
				if not force and lock and lock.JobId ~= game.JobId and os.time() - lock.Time < LOCK_TIMEOUT then
					locked = true
					return nil
				end
				old.Lock = { JobId = game.JobId, Time = os.time() }
				result = old
				return old
			end)
		end)
		if ok and result then
			return result
		end
		if not ok then
			warn("[Data] caricamento fallito per", player.Name, err)
		end
		if not player.Parent then
			return nil
		end
		task.wait(if locked then 4 else 2)
	end
	return nil
end

function DataService.Save(player, release: boolean?): boolean
	local data = cache[player]
	if not data or noSave[player] or not store then
		return true
	end
	data.Lock = if release then nil else { JobId = game.JobId, Time = os.time() }
	local ok, err = pcall(function()
		store:UpdateAsync(key(player), function(old)
			if old and old.Lock and old.Lock.JobId ~= game.JobId and os.time() - old.Lock.Time < LOCK_TIMEOUT then
				return nil -- un altro server ha preso il giocatore: non sovrascrivere
			end
			return data
		end)
	end)
	if not ok then
		warn("[Data] salvataggio fallito per", player.Name, err)
	end
	return ok
end

function DataService.Get(player)
	return cache[player]
end

-- Aspetta che i dati del giocatore siano pronti (o che esca).
function DataService.Wait(player, timeout: number?)
	local start = os.clock()
	while player.Parent and not cache[player] do
		if timeout and os.clock() - start > timeout then
			return nil
		end
		task.wait(0.1)
	end
	return cache[player]
end

function DataService.IsLoaded(player): boolean
	return cache[player] ~= nil
end

-- Segna che il client va aggiornato. `full` = anche l'inventario dei draghi (più pesante).
local dirty = {}
function DataService.MarkDirty(player, full: boolean?)
	local current = dirty[player]
	dirty[player] = (current == true) or (full == true)
end

-- Usato da SyncService: prende e svuota la lista dei giocatori da aggiornare.
function DataService.TakeDirty()
	local out = dirty
	dirty = {}
	return out
end

local function onJoin(player)
	local data = loadData(player)
	if not data then
		if RunService:IsStudio() then
			warn("[Data] Studio senza accesso alle API: uso dati nuovi che non verranno salvati. Attiva 'Enable Studio Access to API Services' per provare i salvataggi.")
			data = template()
			noSave[player] = true
		else
			player:Kick("Could not load your data. Please rejoin in a moment.")
			return
		end
	end
	if not player.Parent then
		return
	end
	reconcile(data, template())
	if next(data.Dragons) == nil then
		local uid = tostring(data.NextUid)
		data.NextUid += 1
		data.Dragons[uid] = { Id = Balance.StartingDragon, Level = 1, Xp = 0, Shiny = false }
		data.Equipped = { uid }
		data.Discovered[Balance.StartingDragon] = true
	end
	cache[player] = data
	loadedEvent:Fire(player, data)
end

local function onLeave(player)
	if cache[player] then
		DataService.Save(player, true)
	end
	cache[player] = nil
	noSave[player] = nil
end

function DataService.Start()
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in Players:GetPlayers() do
		task.spawn(onJoin, p)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE)
			for player in cache do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in cache do
			pending += 1
			task.spawn(function()
				DataService.Save(player, true)
				pending -= 1
			end)
		end
		local start = os.clock()
		while pending > 0 and os.clock() - start < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
