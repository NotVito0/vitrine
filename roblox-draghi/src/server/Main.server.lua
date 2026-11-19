-- Avvio del server: costruisce il mondo e accende tutti i sistemi.
local Services = script.Parent:WaitForChild("Services")

local WorldBuilder = require(Services.WorldBuilder)
local DataService = require(Services.DataService)
local PassService = require(Services.PassService)
local DragonService = require(Services.DragonService)
local SyncService = require(Services.SyncService)
local MonsterService = require(Services.MonsterService)
local CombatService = require(Services.CombatService)
local TrainingService = require(Services.TrainingService)
local EggService = require(Services.EggService)
local IslandService = require(Services.IslandService)
local ShopService = require(Services.ShopService)

WorldBuilder.Build()

-- Prima i sistemi che rispondono al client, poi quelli che caricano i giocatori.
DragonService.Start()
EggService.Start()
IslandService.Start()
ShopService.Start()
SyncService.Start()
PassService.Start()
DataService.Start()

MonsterService.Start()
CombatService.Start()
TrainingService.Start()

print("[Dragon Elements Sim] server pronto")
