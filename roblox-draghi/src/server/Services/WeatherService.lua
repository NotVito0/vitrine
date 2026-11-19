-- Meteo uguale in tutti i server (dipende dall'orario). L'admin abuse può forzare l'eclissi.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Weather = require(Shared.Config.Weather)
local Remotes = require(Shared.Remotes)

local Boosts = require(script.Parent.Boosts)

local WeatherService = {}

WeatherService.Override = nil -- es. "Eclipse" durante l'admin abuse

function WeatherService.Current(): string
	return WeatherService.Override or Weather.At(Weather.Window(workspace:GetServerTimeNow()))
end

function WeatherService.Start()
	local last = nil
	task.spawn(function()
		while true do
			local now = workspace:GetServerTimeNow()
			local key = WeatherService.Current()
			local info = Weather.Types[key]
			Boosts.WeatherElement = info.Element
			workspace:SetAttribute("Weather", key)
			workspace:SetAttribute("WeatherEnds", if WeatherService.Override then 0 else (Weather.Window(now) + 1) * Weather.Cycle)
			if last and key ~= last then
				Remotes.Event("Notify"):FireAllClients(info.Icon .. " The weather changed: " .. info.Name .. "! " .. info.Element .. " dragons are stronger.", "info")
			end
			last = key
			task.wait(1)
		end
	end)
end

return WeatherService
