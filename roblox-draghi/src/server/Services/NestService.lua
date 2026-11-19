-- Nido degli incroci. Due draghi di elementi diversi: dopo il tempo del nido nasce un ibrido
-- (se la combinazione esiste e il meteo è quello giusto), altrimenti una copia del genitore più debole.
-- I genitori non si perdono. Il primo al mondo a scoprire un ibrido viene annunciato in tutti i server.
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Combos = require(Shared.Config.Combos)
local Dragons = require(Shared.Config.Dragons)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Analytics)
local QuestService = require(script.Parent.QuestService)
local DragonService = require(script.Parent.DragonService)
local WeatherService = require(script.Parent.WeatherService)

local NestService = {}

local globalStore
pcall(function()
	globalStore = DataStoreService:GetDataStore("Global_v1")
end)

local function announce(text)
	Remotes.Event("Announce"):FireAllClients(text)
	pcall(function()
		MessagingService:PublishAsync("Announce", { Text = text, From = game.JobId })
	end)
end

-- Registra la prima scoperta mondiale. Ritorna true se questo giocatore è il primo.
local function claimFirst(player, id)
	if not globalStore then
		return false
	end
	local first = false
	pcall(function()
		globalStore:UpdateAsync("First_" .. id, function(old)
			if old then
				return nil
			end
			first = true
			return { Name = player.DisplayName, UserId = player.UserId, Time = os.time() }
		end)
	end)
	return first
end

local function finish(player, data)
	local nest = data.Nest
	data.Nest = nil
	local a = data.Dragons[nest.A]
	local b = data.Dragons[nest.B]
	if not a or not b then
		DataService.MarkDirty(player, true)
		return
	end
	local defA, defB = Dragons.Get(a.Id), Dragons.Get(b.Id)
	local combo = Combos.Find(defA.Element, defB.Element)
	local resultId, base
	if combo and (not combo.Weather or combo.Weather == nest.Weather) then
		resultId = combo.Id
		local powA = (a.Base or defA.Power) * (if a.Shiny then 2.5 else 1)
		local powB = (b.Base or defB.Power) * (if b.Shiny then 2.5 else 1)
		base = math.floor((powA + powB) * Combos.PowerMult[combo.Rarity])
	else
		local weak = if DragonService.Power(a) <= DragonService.Power(b) then a else b
		resultId = weak.Id
		base = weak.Base
	end
	local uid, _, isNew = DragonService.Add(player, resultId, { Force = true, Base = base })
	if not uid then
		return
	end
	Remotes.Event("HatchFx"):FireClient(player, { { Id = resultId, Shiny = false, New = isNew, Nest = true } }, nil)
	if combo and resultId == combo.Id and isNew then
		task.spawn(function()
			if claimFirst(player, combo.Id) then
				announce("🏆 " .. player.DisplayName .. " is the FIRST in the world to discover the " .. combo.Name .. "!")
			end
		end)
	end
	DataService.MarkDirty(player, true)
end

function NestService.Start()
	pcall(function()
		MessagingService:SubscribeAsync("Announce", function(message)
			local data = message.Data
			if type(data) == "table" and type(data.Text) == "string" and data.From ~= game.JobId then
				Remotes.Event("Announce"):FireAllClients(data.Text)
			end
		end)
	end)

	Remotes.Func("StartNest").OnServerInvoke = function(player, uidA, uidB)
		local data = DataService.Get(player)
		if not data then
			return false, "Not ready"
		end
		if data.Nest then
			return false, "The nest is busy"
		end
		if type(uidA) ~= "string" or type(uidB) ~= "string" or uidA == uidB then
			return false, "Pick two different dragons"
		end
		local a, b = data.Dragons[uidA], data.Dragons[uidB]
		if not a or not b then
			return false, "Unknown dragon"
		end
		if Dragons.Get(a.Id).Element == Dragons.Get(b.Id).Element then
			return false, "Pick two dragons with different elements"
		end
		Analytics.Step(player, data, "FirstBreed")
		QuestService.Add(player, "Breeds", 1)
		data.Nest = { A = uidA, B = uidB, Ends = os.time() + Combos.NestSeconds, Weather = WeatherService.Current() }
		DataService.MarkDirty(player, true)
		return true
	end

	Remotes.Func("SkipNest").OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data or not data.Nest then
			return false, "The nest is empty"
		end
		if data.Gems < Combos.SkipGems then
			return false, "You need " .. Combos.SkipGems .. " gems"
		end
		data.Gems -= Combos.SkipGems
		data.Nest.Ends = 0
		return true
	end

	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.time()
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data and data.Nest and now >= data.Nest.Ends then
					finish(player, data)
				end
			end
		end
	end)
end

return NestService
