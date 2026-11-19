-- Barra delle abilità in basso: un pulsante per abilità sbloccata, con il tempo di ricarica.
-- Da tastiera si usano i tasti 1–6. Disegna anche gli effetti delle abilità di tutti i giocatori.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Abilities = require(Shared.Config.Abilities)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local Sfx = require(script.Parent.Sfx)

local Skills = {}

local player = Players.LocalPlayer
local bar
local buttons = {} -- id -> { Button, Shade, Timer, ReadyAt }
local UI

local function fxPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in props do
		p[k] = v
	end
	p.Parent = workspace
	return p
end

-- Effetti: un'onda che si allarga, fulmini o meteore sui bersagli.
local function playFx(id, origin, targets)
	local ability = Abilities.Get(id)
	if not ability then
		return
	end
	local color = ability.Color
	if ability.Radius and id ~= "ThunderStrike" then
		local ring = fxPart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2, 2), Color = color, Transparency = 0.2, CFrame = CFrame.new(origin - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
		TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { Size = Vector3.new(0.6, ability.Radius * 2, ability.Radius * 2), Transparency = 1 }):Play()
		Debris:AddItem(ring, 0.5)
	end
	for _, pos in targets or {} do
		if id == "ThunderStrike" then
			local bolt = fxPart({ Size = Vector3.new(0.6, 40, 0.6), Color = color, CFrame = CFrame.new(pos + Vector3.new(0, 20, 0)) })
			TweenService:Create(bolt, TweenInfo.new(0.3), { Transparency = 1, Size = Vector3.new(0.1, 40, 0.1) }):Play()
			Debris:AddItem(bolt, 0.35)
		elseif id == "MeteorCall" then
			local rock = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4, Color = color, Position = pos + Vector3.new(-30, 60, 0) })
			local fall = TweenService:Create(rock, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = pos })
			fall.Completed:Connect(function()
				rock:Destroy()
				local boom = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Color = Color3.fromRGB(255, 180, 90), Position = pos })
				TweenService:Create(boom, TweenInfo.new(0.35), { Size = Vector3.one * 14, Transparency = 1 }):Play()
				Debris:AddItem(boom, 0.4)
			end)
			fall:Play()
		else
			local burst = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 2, Color = color, Position = pos })
			TweenService:Create(burst, TweenInfo.new(0.3), { Size = Vector3.one * 7, Transparency = 1 }):Play()
			Debris:AddItem(burst, 0.35)
		end
	end
	if id == "Frenzy" or id == "CoinMagnet" then
		local glow = fxPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4, Color = color, Transparency = 0.4, Position = origin })
		TweenService:Create(glow, TweenInfo.new(0.6), { Size = Vector3.one * 16, Transparency = 1 }):Play()
		Debris:AddItem(glow, 0.65)
	end
end

local function use(id)
	local b = buttons[id]
	if b and os.clock() < b.ReadyAt then
		return
	end
	local ok, result = Remotes.Func("UseAbility"):InvokeServer(id)
	if ok and b then
		b.ReadyAt = os.clock() + (result or 0)
		Sfx.Play("Reveal")
	elseif result and result ~= "Cooldown" and UI then
		UI.Toast(result, "error")
	end
end

local function rebuild()
	local data = State.Data
	if not data or not data.Abilities then
		return
	end
	local order = 0
	for _, ability in Abilities.List do
		local owned = data.Abilities[ability.Id]
		if owned and not buttons[ability.Id] then
			local b = Instance.new("TextButton")
			b.Text = ability.Icon
			b.TextSize = 30
			b.Font = Enum.Font.FredokaOne
			b.TextColor3 = Color3.new(1, 1, 1)
			b.BackgroundColor3 = ability.Color:Lerp(Color3.fromRGB(20, 30, 50), 0.45)
			b.Size = UDim2.fromOffset(64, 64)
			b.Parent = bar
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = b
			local stroke = Instance.new("UIStroke")
			stroke.Color = ability.Color
			stroke.Thickness = 3
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = b
			local shade = Instance.new("Frame")
			shade.BackgroundColor3 = Color3.new(0, 0, 0)
			shade.BackgroundTransparency = 0.45
			shade.AnchorPoint = Vector2.new(0, 1)
			shade.Position = UDim2.fromScale(0, 1)
			shade.Size = UDim2.fromScale(1, 0)
			shade.Parent = b
			local shadeCorner = corner:Clone()
			shadeCorner.Parent = shade
			local timer = Instance.new("TextLabel")
			timer.BackgroundTransparency = 1
			timer.Size = UDim2.fromScale(1, 1)
			timer.Font = Enum.Font.FredokaOne
			timer.TextSize = 22
			timer.TextColor3 = Color3.new(1, 1, 1)
			timer.TextStrokeTransparency = 0.3
			timer.Text = ""
			timer.Parent = b
			b.Activated:Connect(function()
				use(ability.Id)
			end)
			buttons[ability.Id] = { Button = b, Shade = shade, Timer = timer, ReadyAt = 0, Cooldown = ability.Cooldown }
			ContextActionService:BindAction("Ability_" .. ability.Id, function(_, state)
				if state == Enum.UserInputState.Begin then
					use(ability.Id)
				end
				return Enum.ContextActionResult.Pass
			end, false, ability.Key)
		end
		if buttons[ability.Id] then
			order += 1
			buttons[ability.Id].Button.LayoutOrder = order
		end
	end
end

function Skills.Start(ui)
	UI = ui
	local gui = Instance.new("ScreenGui")
	gui.Name = "AbilityBar"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	bar = Instance.new("Frame")
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -84)
	bar.Size = UDim2.fromOffset(440, 70)
	bar.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	State.Changed:Connect(rebuild)
	rebuild()
	Remotes.Event("AbilityFx").OnClientEvent:Connect(playFx)

	game:GetService("RunService").RenderStepped:Connect(function()
		local now = os.clock()
		for _, b in buttons do
			local left = b.ReadyAt - now
			if left > 0 then
				b.Shade.Size = UDim2.fromScale(1, math.clamp(left / b.Cooldown, 0, 1))
				b.Timer.Text = tostring(math.ceil(left))
			else
				b.Shade.Size = UDim2.fromScale(1, 0)
				b.Timer.Text = ""
			end
		end
	end)
end

return Skills
