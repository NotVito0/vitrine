-- Effetti del meteo sul client: luce del cielo, nebbia, pioggia, neve, lampi ed eclissi.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local WeatherFx = {}

local LOOKS = {
	Sunny = { Clock = 14.5, Brightness = 2.6, Ambient = Color3.fromRGB(150, 150, 170), Density = 0.25, Haze = 0, Tint = Color3.fromRGB(255, 255, 255) },
	Windy = { Clock = 15.5, Brightness = 2.2, Ambient = Color3.fromRGB(150, 160, 175), Density = 0.32, Haze = 1.5, Tint = Color3.fromRGB(240, 248, 255) },
	Rain = { Clock = 16, Brightness = 1.2, Ambient = Color3.fromRGB(110, 120, 140), Density = 0.42, Haze = 2.5, Tint = Color3.fromRGB(200, 215, 235), Particles = "rain" },
	Storm = { Clock = 17.5, Brightness = 0.8, Ambient = Color3.fromRGB(80, 85, 110), Density = 0.5, Haze = 3, Tint = Color3.fromRGB(170, 175, 210), Particles = "rain", Lightning = true },
	Snow = { Clock = 13, Brightness = 2, Ambient = Color3.fromRGB(170, 180, 200), Density = 0.38, Haze = 2, Tint = Color3.fromRGB(230, 240, 255), Particles = "snow" },
	Eclipse = { Clock = 19.2, Brightness = 0.6, Ambient = Color3.fromRGB(90, 60, 130), Density = 0.4, Haze = 1, Tint = Color3.fromRGB(190, 150, 255) },
}

local emitterPart, rain, snow, colorFx, atmosphere

local function makeEmitters()
	emitterPart = Instance.new("Part")
	emitterPart.Name = "WeatherEmitter"
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	emitterPart.CanTouch = false
	emitterPart.Transparency = 1
	emitterPart.Size = Vector3.new(120, 1, 120)
	emitterPart.Parent = workspace

	rain = Instance.new("ParticleEmitter")
	rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	rain.Color = ColorSequence.new(Color3.fromRGB(190, 210, 255))
	rain.LightEmission = 0.3
	rain.Size = NumberSequence.new(0.15)
	rain.Transparency = NumberSequence.new(0.35)
	rain.Lifetime = NumberRange.new(1.2, 1.6)
	rain.Speed = NumberRange.new(70, 85)
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.SpreadAngle = Vector2.new(4, 4)
	rain.Rate = 0
	rain.Squash = NumberSequence.new(-3)
	rain.Parent = emitterPart

	snow = Instance.new("ParticleEmitter")
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.LightEmission = 0.5
	snow.Size = NumberSequence.new(0.35)
	snow.Lifetime = NumberRange.new(5, 7)
	snow.Speed = NumberRange.new(8, 12)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.SpreadAngle = Vector2.new(25, 25)
	snow.RotSpeed = NumberRange.new(-60, 60)
	snow.Rate = 0
	snow.Parent = emitterPart

	colorFx = Lighting:FindFirstChild("WeatherColor") or Instance.new("ColorCorrectionEffect")
	colorFx.Name = "WeatherColor"
	colorFx.Parent = Lighting
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
end

local current = nil
local function applyWeather(key)
	local look = LOOKS[key] or LOOKS.Sunny
	if key == current then
		return
	end
	current = key
	local info = TweenInfo.new(3, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, { ClockTime = look.Clock, Brightness = look.Brightness, OutdoorAmbient = look.Ambient }):Play()
	TweenService:Create(colorFx, info, { TintColor = look.Tint }):Play()
	atmosphere = atmosphere or Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		TweenService:Create(atmosphere, info, { Density = look.Density, Haze = look.Haze }):Play()
	end
	rain.Rate = if look.Particles == "rain" then (if look.Lightning then 900 else 600) else 0
	snow.Rate = if look.Particles == "snow" then 160 else 0
end

local function flash()
	local before = Lighting.Brightness
	Lighting.Brightness = before + 4
	colorFx.Brightness = 0.25
	task.wait(0.08)
	Lighting.Brightness = before
	colorFx.Brightness = 0
end

function WeatherFx.Start()
	makeEmitters()
	applyWeather(workspace:GetAttribute("Weather") or "Sunny")
	workspace:GetAttributeChangedSignal("Weather"):Connect(function()
		applyWeather(workspace:GetAttribute("Weather"))
	end)

	local camera = workspace.CurrentCamera
	RunService.RenderStepped:Connect(function()
		local pos = camera.CFrame.Position
		emitterPart.CFrame = CFrame.new(pos + Vector3.new(0, 40, 0))
	end)

	-- Lampi durante il temporale.
	task.spawn(function()
		while true do
			task.wait(math.random(6, 14))
			if current == "Storm" then
				flash()
				task.wait(0.12)
				if math.random() < 0.5 then
					flash()
				end
			end
		end
	end)
end

return WeatherFx
