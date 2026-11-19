-- Avvio del client.
local Controllers = script.Parent:WaitForChild("Controllers")

local State = require(Controllers.State)
local UI = require(Controllers.UI)
local World = require(Controllers.World)
local DragonVisuals = require(Controllers.DragonVisuals)

UI.Start()
World.Start(UI)
DragonVisuals.Start()
State.Wait()
