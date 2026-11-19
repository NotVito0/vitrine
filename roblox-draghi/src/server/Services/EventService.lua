-- Eventi automatici: feste dell'anno, ora d'oro, weekend, pioggia di meteore e admin abuse del sabato.
-- Tutto dipende dall'orario, quindi è uguale in tutti i server e non serve nessuno al computer.
-- Il proprietario del gioco può anche lanciare eventi a mano scrivendo in chat:
--   /event abuse      -> admin abuse completo adesso, in tutti i server
--   /event luck10     -> un singolo evento (vedi gli Id in Config/Events.lua)
--   /event stop       -> ferma gli eventi lanciati a mano
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Events = require(Shared.Config.Events)
local Islands = require(Shared.Config.Islands)
local Dragons = require(Shared.Config.Dragons)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local DragonService = require(script.Parent.DragonService)
local MonsterService = require(script.Parent.MonsterService)
local EggService = require(script.Parent.EggService)
local MarketService = require(script.Parent.MarketService)
local WeatherService = require(script.Parent.WeatherService)
local Boosts = require(script.Parent.Boosts)

local EventService = {}

local DEFAULT_GRAVITY = workspace.Gravity
local length = (Events.AdminAbuse.Count + 1) * Events.AdminAbuse.EventSeconds

local manual = {} -- eventi singoli lanciati a mano: { Effect, Ends }
local manualAbuse = nil -- { Start, Week } admin abuse lanciato a mano
local seen = {} -- chiavi degli eventi già annunciati
local warned = {}
local lastEggRain = 0

local function notifyAll(text, kind)
	Remotes.Event("Notify"):FireAllClients(text, kind or "info")
end

local function bestIsland(data)
	local best = 1
	for i, island in Islands.List do
		if data.Unlocked[island.Id] then
			best = i
		end
	end
	return best
end

local function abuseEntries(start, week, now, prefix)
	local out = {}
	if now < start or now >= start + length then
		return out
	end
	local index = math.floor((now - start) / Events.AdminAbuse.EventSeconds) + 1
	local plan, theme = Events.AdminPlan(week)
	local effect = plan[index]
	if effect then
		table.insert(out, {
			Key = prefix .. week .. "_" .. index,
			Name = theme.Name .. ": " .. effect.Name,
			Icon = effect.Icon,
			Ends = start + index * Events.AdminAbuse.EventSeconds,
			Mult = effect.Mult,
			Kind = effect.Kind,
			Effect = effect,
			Week = week,
			Admin = true,
		})
	end
	return out
end

local function computeActive(now)
	local active = {}
	local date = os.date("!*t", now)
	local dayStart = now - (date.hour * 3600 + date.min * 60 + date.sec)

	for _, season in Events.Seasonal do
		if Events.SeasonActive(season, now) then
			table.insert(active, { Key = "season_" .. season.Id .. date.year, Name = season.Name, Icon = season.Icon, Mult = season.Mult, Season = season })
		end
	end

	local gh = Events.GoldenHour
	if date.hour == gh.HourUTC and date.min < gh.Minutes then
		table.insert(active, { Key = "golden" .. dayStart, Name = gh.Name, Icon = gh.Icon, Ends = dayStart + gh.HourUTC * 3600 + gh.Minutes * 60, Mult = gh.Mult })
	end

	if date.wday == 7 or date.wday == 1 then
		local daysLeft = if date.wday == 7 then 2 else 1
		table.insert(active, { Key = "weekend" .. (dayStart - (2 - daysLeft) * 86400), Name = Events.Weekend.Name, Icon = Events.Weekend.Icon, Ends = dayStart + daysLeft * 86400, Mult = Events.Weekend.Mult })
	end

	local met = Events.Meteors
	local hourStart = dayStart + date.hour * 3600
	local metStart = hourStart + met.Minute * 60
	if now >= metStart and now < metStart + met.Duration then
		table.insert(active, { Key = "meteor" .. metStart, Name = met.Name, Icon = met.Icon, Ends = metStart + met.Duration, Kind = "Meteors" })
	end

	local start, week = Events.AdminStart(now)
	for _, e in abuseEntries(start, week, now, "admin") do
		table.insert(active, e)
	end
	if manualAbuse then
		local entries = abuseEntries(manualAbuse.Start, manualAbuse.Week, now, "manual")
		if #entries == 0 and now >= manualAbuse.Start + length then
			manualAbuse = nil
		end
		for _, e in entries do
			table.insert(active, e)
		end
	end

	for i = #manual, 1, -1 do
		local m = manual[i]
		if now >= m.Ends then
			table.remove(manual, i)
		else
			table.insert(active, { Key = "single" .. m.Key, Name = "ADMIN: " .. m.Effect.Name, Icon = m.Effect.Icon, Ends = m.Ends, Mult = m.Effect.Mult, Kind = m.Effect.Kind, Effect = m.Effect, Admin = true })
		end
	end

	-- Avvisi prima dell'admin abuse del sabato.
	for _, minutes in Events.AdminAbuse.WarnMinutes do
		local at = start - minutes * 60
		if now >= at and now < at + 2 and not warned[at] then
			warned[at] = true
			notifyAll("⚠️ ADMIN ABUSE in " .. minutes .. " minute" .. (if minutes == 1 then "" else "s") .. "! Stay in the game!", "level")
		end
	end
	workspace:SetAttribute("NextAdminAbuse", start)
	return active
end

-- Azioni che partono una volta sola quando un evento inizia.
local function onStart(e)
	local kind = e.Kind
	if kind == "Boss" then
		for i in Islands.List do
			MonsterService.SpawnSpecial(i, "boss")
		end
	elseif kind == "GemStorm" or kind == "Meteors" then
		local count = if kind == "Meteors" then Events.Meteors.PerIsland else 6
		for i in Islands.List do
			for _ = 1, count do
				MonsterService.SpawnSpecial(i, "gem")
			end
		end
	elseif kind == "FreePotion" then
		for _, p in Players:GetPlayers() do
			local data = DataService.Get(p)
			if data then
				MarketService.AddPotion(data, "SuperLuck", 1)
				DataService.MarkDirty(p, false)
			end
		end
	end
end

-- Il finale dell'admin abuse: il drago della settimana a chi è online (anche a chi entra durante il finale).
local function giveAdminDragon(e)
	local id = e.Effect.Dragon
	for _, p in Players:GetPlayers() do
		local data = DataService.Get(p)
		if data then
			data.AdminGifts = data.AdminGifts or {}
			local key = tostring(e.Week) .. (if e.Key:sub(1, 6) == "manual" then "m" else "")
			if not data.AdminGifts[key] then
				data.AdminGifts[key] = true
				DragonService.Add(p, id, { Force = true })
				Remotes.Event("HatchFx"):FireClient(p, { { Id = id, Shiny = false, New = true } }, nil)
			end
		end
	end
end

local function apply(active, now)
	local global = { Coins = 1, Damage = 1, Training = 1, Luck = 1, Shiny = 1 }
	local kinds = {}
	local drop, tint = nil, nil
	for _, e in active do
		for k, v in e.Mult or {} do
			global[k] *= v
		end
		if e.Kind then
			kinds[e.Kind] = e
		end
		if e.Season then
			if e.Season.Dragon then
				drop = { Dragon = e.Season.Dragon, Chance = e.Season.DropChance }
			end
			tint = e.Season.Tint
		end
		if not seen[e.Key] then
			seen[e.Key] = true
			notifyAll(e.Icon .. " " .. e.Name .. (if e.Admin then "" else " has started!"), if e.Admin then "level" else "info")
			onStart(e)
		end
	end
	Boosts.Global = global
	Boosts.EventDrop = drop

	local gold = if kinds.Golden then 10 else 1
	if MonsterService.GoldMult ~= gold or MonsterService.Tint ~= tint then
		MonsterService.GoldMult = gold
		MonsterService.Tint = tint
		MonsterService.Recolor()
	end
	local gravity = if kinds.Gravity then 60 else DEFAULT_GRAVITY
	if workspace.Gravity ~= gravity then
		workspace.Gravity = gravity
	end
	workspace:SetAttribute("SpeedBoost", kinds.Speed ~= nil)
	workspace:SetAttribute("GiantDragons", kinds.Giants ~= nil)
	WeatherService.Override = if kinds.Eclipse then "Eclipse" else nil

	if kinds.EggRain and now - lastEggRain >= 60 then
		lastEggRain = now
		for _, p in Players:GetPlayers() do
			local data = DataService.Get(p)
			if data then
				local island = bestIsland(data)
				local results = EggService.Grant(p, island, 1)
				Remotes.Event("HatchFx"):FireClient(p, results, island)
			end
		end
	end
	if kinds.AdminDragon then
		giveAdminDragon(kinds.AdminDragon)
	end

	local list = {}
	for _, e in active do
		table.insert(list, { Name = e.Name, Icon = e.Icon, Ends = e.Ends, Admin = e.Admin })
	end
	local encoded = HttpService:JSONEncode(list)
	if workspace:GetAttribute("Events") ~= encoded then
		workspace:SetAttribute("Events", encoded)
	end
	local mults = HttpService:JSONEncode(global)
	if workspace:GetAttribute("GlobalMults") ~= mults then
		workspace:SetAttribute("GlobalMults", mults)
	end
end

---------------------------------------------------------------- Comandi admin
local function isAdmin(player)
	if RunService:IsStudio() then
		return true
	end
	if table.find(Events.Admins, player.UserId) then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	local ok, rank = pcall(player.GetRankInGroup, player, game.CreatorId)
	return ok and rank == 255
end

local function runCommand(arg, now)
	arg = string.lower(arg or "")
	if arg == "stop" then
		manual = {}
		manualAbuse = nil
		return "Manual events stopped"
	elseif arg == "abuse" then
		manualAbuse = { Start = now, Week = now // 60 } -- ogni lancio a mano pesca eventi nuovi
		return "Admin abuse started!"
	end
	for _, effect in Events.AdminPool do
		if string.lower(effect.Id) == arg then
			table.insert(manual, { Effect = effect, Ends = now + Events.AdminAbuse.EventSeconds, Key = tostring(now) .. effect.Id })
			return effect.Name .. " started for " .. Events.AdminAbuse.EventSeconds // 60 .. " minutes"
		end
	end
	return nil
end

local function onCommand(player, text)
	if not isAdmin(player) then
		return
	end
	local arg = string.match(text, "^/event%s+(%S+)")
	if not arg then
		local ids = {}
		for _, e in Events.AdminPool do
			table.insert(ids, string.lower(e.Id))
		end
		Remotes.Event("Notify"):FireClient(player, "Use /event abuse, /event stop or /event <" .. table.concat(ids, ", ") .. ">", "info")
		return
	end
	local now = math.floor(workspace:GetServerTimeNow())
	local result = runCommand(arg, now)
	if not result then
		Remotes.Event("Notify"):FireClient(player, "Unknown event: " .. arg, "error")
		return
	end
	Remotes.Event("Notify"):FireClient(player, result, "success")
	-- Lo stesso evento parte in tutti gli altri server.
	pcall(function()
		MessagingService:PublishAsync("AdminCommand", { Arg = arg, Now = now })
	end)
end

local function setupCommands()
	pcall(function()
		MessagingService:SubscribeAsync("AdminCommand", function(message)
			local data = message.Data
			if type(data) == "table" and data.Arg then
				runCommand(data.Arg, math.floor(data.Now or workspace:GetServerTimeNow()))
			end
		end)
	end)
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local command = Instance.new("TextChatCommand")
		command.Name = "EventCommand"
		command.PrimaryAlias = "/event"
		command.Parent = TextChatService:FindFirstChild("TextChatCommands") or TextChatService
		command.Triggered:Connect(function(source, text)
			local player = Players:GetPlayerByUserId(source.UserId)
			if player then
				onCommand(player, text)
			end
		end)
	else
		local function hook(p)
			p.Chatted:Connect(function(text)
				if string.sub(text, 1, 6) == "/event" then
					onCommand(p, text)
				end
			end)
		end
		Players.PlayerAdded:Connect(hook)
		for _, p in Players:GetPlayers() do
			hook(p)
		end
	end
end

function EventService.Start()
	setupCommands()
	task.spawn(function()
		while true do
			local now = math.floor(workspace:GetServerTimeNow())
			local ok, err = pcall(function()
				apply(computeActive(now), now)
			end)
			if not ok then
				warn("[Events]", err)
			end
			task.wait(1)
		end
	end)
end

return EventService
