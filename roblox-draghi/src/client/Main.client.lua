-- Avvio del client. Ogni parte parte protetta e gli errori vengono mandati al registro del server.
local ScriptContext = game:GetService("ScriptContext")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local device = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then "Phone" else "PC"
local clientError = Remotes.Event("ClientError")
ScriptContext.Error:Connect(function(message, trace)
	clientError:FireServer(message, trace, device)
end)

local Controllers = script.Parent:WaitForChild("Controllers")

local function safe(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	if not ok then
		clientError:FireServer("Start failed: " .. name .. ": " .. tostring(err), "", device)
	end
end

local modules = {}
for _, name in { "State", "UI", "World", "DragonVisuals", "WeatherFx", "Tutorial", "Skills" } do
	safe("require " .. name, function()
		modules[name] = require(Controllers[name])
	end)
end

local UI = modules.UI
safe("UI.Start", function()
	UI.Start()
end)
safe("World.Start", function()
	modules.World.Start(UI)
end)
safe("DragonVisuals.Start", function()
	modules.DragonVisuals.Start()
end)
safe("WeatherFx.Start", function()
	modules.WeatherFx.Start()
end)
safe("Tutorial.Start", function()
	modules.Tutorial.Start()
end)
safe("Skills.Start", function()
	modules.Skills.Start(UI)
end)
