-- Registro degli errori: raccoglie gli errori del server e dei telefoni/computer dei giocatori
-- e li salva nel DataStore "Diagnostics_v1" (chiave "log"), da dove si leggono con tools/logs.py.
-- Così i bug si trovano anche senza Roblox Studio.
local DataStoreService = game:GetService("DataStoreService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ScriptContext = game:GetService("ScriptContext")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local Diagnostics = {}

local MAX_ENTRIES = 150
local pending = {}
local store
pcall(function()
	store = DataStoreService:GetDataStore("Diagnostics_v1")
end)

local function add(side: string, message, trace)
	message = string.sub(tostring(message or "?"), 1, 300)
	trace = string.sub(tostring(trace or ""), 1, 600)
	local key = side .. "|" .. message
	local entry = pending[key]
	local now = os.time()
	if entry then
		entry.Count += 1
		entry.Last = now
	else
		pending[key] = { Side = side, Msg = message, Trace = trace, Count = 1, First = now, Last = now, Version = game.PlaceVersion }
	end
end

Diagnostics.Add = add

local function flush()
	if not store or next(pending) == nil then
		return
	end
	local batch = pending
	pending = {}
	local ok, err = pcall(function()
		store:UpdateAsync("log", function(old)
			old = old or { Entries = {} }
			local index = {}
			for i, e in old.Entries do
				index[e.Side .. "|" .. e.Msg] = i
			end
			for key, e in batch do
				local i = index[key]
				if i then
					local existing = old.Entries[i]
					existing.Count += e.Count
					existing.Last = e.Last
					existing.Version = e.Version
				else
					table.insert(old.Entries, e)
				end
			end
			table.sort(old.Entries, function(a, b)
				return a.Last > b.Last
			end)
			while #old.Entries > MAX_ENTRIES do
				table.remove(old.Entries)
			end
			old.Updated = os.time()
			return old
		end)
	end)
	if not ok then
		-- Non usare warn qui: verrebbe registrato di nuovo.
		print("[Diagnostics] salvataggio non riuscito:", err)
	end
end

function Diagnostics.Start()
	ScriptContext.Error:Connect(function(message, trace, script)
		add("Server", message, trace .. (if script then " @" .. script:GetFullName() else ""))
	end)
	LogService.MessageOut:Connect(function(message, kind)
		if kind == Enum.MessageType.MessageWarning and not string.find(message, "Diagnostics", 1, true) then
			add("ServerWarn", message, "")
		end
	end)

	-- Errori dal dispositivo dei giocatori (massimo 20 al minuto per giocatore).
	local counts = {}
	Remotes.Event("ClientError").OnServerEvent:Connect(function(player, message, trace, device)
		local now = os.time() // 60
		local c = counts[player]
		if not c or c.Minute ~= now then
			c = { Minute = now, N = 0 }
			counts[player] = c
		end
		c.N += 1
		if c.N > 20 or type(message) ~= "string" then
			return
		end
		add("Client" .. (if type(device) == "string" then "-" .. string.sub(device, 1, 10) else ""), message, if type(trace) == "string" then trace else "")
	end)
	Players.PlayerRemoving:Connect(function(p)
		counts[p] = nil
	end)

	add("Info", "Server started (place version " .. tostring(game.PlaceVersion) .. ")", "")
	task.spawn(function()
		while true do
			task.wait(20)
			flush()
		end
	end)
	game:BindToClose(flush)
end

return Diagnostics
