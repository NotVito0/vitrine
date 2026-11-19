-- Avvio del server: costruisce il mondo e accende tutti i sistemi.
-- Ogni sistema parte protetto: se uno va in errore, gli altri continuano e l'errore finisce nel registro.
local Services = script.Parent:WaitForChild("Services")

local Diagnostics = require(Services.Diagnostics)
Diagnostics.Start()

local function safe(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	if not ok then
		Diagnostics.Add("Server", "Start failed: " .. name .. ": " .. tostring(err), "")
		print("[Avvio] " .. name .. " non è partito:", err)
	end
end

local loaded = {}
local function load(name)
	safe("require " .. name, function()
		loaded[name] = require(Services[name])
	end)
	return loaded[name]
end

local WorldBuilder = load("WorldBuilder")
safe("WorldBuilder.Build", function()
	WorldBuilder.Build()
end)

local DataService = load("DataService")
local Analytics = load("Analytics")
safe("Analytics hook", function()
	DataService.PlayerLoaded:Connect(function(player, data)
		Analytics.Step(player, data, "Joined")
	end)
end)

-- Prima i sistemi che rispondono al client, poi quelli che caricano i giocatori, poi i cicli di gioco.
local ORDER = {
	"ArtService",
	"DragonService",
	"EggService",
	"MarketService",
	"GiftService",
	"WeatherService",
	"NestService",
	"RewardService",
	"QuestService",
	"AbilityService",
	"CosmeticService",
	"IslandService",
	"ShopService",
	"SyncService",
	"PassService",
	"DataService",
	"MonsterService",
	"CombatService",
	"TrainingService",
	"EventService",
}

for _, name in ORDER do
	local service = loaded[name] or load(name)
	if service and service.Start then
		safe(name .. ".Start", function()
			service.Start()
		end)
	end
end

print("[Dragon Elements Sim] server pronto")
