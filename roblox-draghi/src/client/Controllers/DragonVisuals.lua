-- Disegna i draghi di tutti i giocatori dietro di loro e gli effetti degli attacchi.
-- Tutto qui è solo grafica: i danni li calcola il server.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DragonModel = require(Shared.DragonModel)
local Elements = require(Shared.Config.Elements)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DragonVisuals = {}

local rigs = {} -- player -> { Key, Dragons = { { Rig, CFrame, Phase, Lunge } } }
local folder
local camera = workspace.CurrentCamera

local function clear(entry)
	for _, d in entry.Dragons do
		d.Rig.Model:Destroy()
	end
	entry.Dragons = {}
end

local function rebuild(player)
	local entry = rigs[player]
	if not entry then
		entry = { Key = "", Dragons = {} }
		rigs[player] = entry
	end
	local key = player:GetAttribute("Team") or "[]"
	if key == entry.Key then
		return
	end
	entry.Key = key
	clear(entry)
	local ok, team = pcall(HttpService.JSONDecode, HttpService, key)
	if not ok then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local start = if root then root.CFrame else CFrame.new()
	for i, item in team do
		local rig = DragonModel.Build(item[1], item[2] == 1, 0.9)
		rig.Model.Parent = folder
		table.insert(entry.Dragons, { Rig = rig, CFrame = start * CFrame.new(0, 4, 6), Phase = i * 1.7 })
	end
end

local function track(player)
	player:GetAttributeChangedSignal("Team"):Connect(function()
		rebuild(player)
	end)
	rebuild(player)
end

local function slotOffset(i, n, t, phase)
	local spread = (i - (n + 1) / 2) * 4.2
	local back = 5.5 + (i % 2) * 2
	return CFrame.new(spread, 4.5 + math.sin(t * 2 + phase) * 0.6, back)
end

local function render(dt)
	local t = os.clock()
	local parts, cframes = {}, {}
	local camPos = camera.CFrame.Position
	for player, entry in rigs do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and #entry.Dragons > 0 then
			local far = (root.Position - camPos).Magnitude > 350
			local base = CFrame.new(root.Position) * (root.CFrame - root.CFrame.Position)
			local n = #entry.Dragons
			for i, d in entry.Dragons do
				local target = base * slotOffset(i, n, t, d.Phase)
				if d.Lunge and t < d.Lunge.Until then
					local toward = d.Lunge.Target
					local from = target.Position
					local dir = toward - from
					local pos = from + dir * 0.55
					target = CFrame.lookAt(pos, toward)
				end
				local alpha = 1 - math.exp(-dt * 7)
				d.CFrame = d.CFrame:Lerp(target, alpha)
				if not far then
					DragonModel.Pose(d.Rig, d.CFrame, t + d.Phase, parts, cframes)
				end
			end
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function burst(position, color)
	local ball = Instance.new("Part")
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CastShadow = false
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.Neon
	ball.Color = color
	ball.Size = Vector3.one * 1.5
	ball.Position = position
	ball.Parent = folder
	TweenService:Create(ball, TweenInfo.new(0.3), { Size = Vector3.one * 5, Transparency = 1 }):Play()
	Debris:AddItem(ball, 0.35)
end

-- Il mostro colpito lampeggia di bianco.
local function hitFlash(monster)
	local old = monster:FindFirstChild("HitFlash")
	if old then
		old:Destroy()
	end
	local h = Instance.new("Highlight")
	h.Name = "HitFlash"
	h.FillColor = Color3.new(1, 1, 1)
	h.FillTransparency = 0.25
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = monster
	TweenService:Create(h, TweenInfo.new(0.18), { FillTransparency = 1 }):Play()
	Debris:AddItem(h, 0.2)
end

-- Numeri dei danni, solo per i propri attacchi. Più grandi e gialli se l'elemento è forte.
local function damageNumber(position, damage, mult)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position + Vector3.new(math.random(-15, 15) / 10, 1.5, math.random(-15, 15) / 10)
	anchor.Parent = folder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 36)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 80
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextStrokeTransparency = 0.15
	text.TextColor3 = if mult > 1 then Color3.fromRGB(255, 220, 70) elseif mult < 1 then Color3.fromRGB(170, 180, 200) else Color3.new(1, 1, 1)
	text.Text = Format.Number(damage) .. (if mult > 1 then "!" else "")
	text.Parent = gui
	gui.Parent = anchor
	local scale = Instance.new("UIScale")
	scale.Scale = if mult > 1 then 1.5 else 0.6
	scale.Parent = text
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = if mult > 1 then 1.15 else 0.85 }):Play()
	TweenService:Create(anchor, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { Position = anchor.Position + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(text, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 0.75)
end

local function onAttack(userId, slot, monster, element, mult, damage)
	local player = Players:GetPlayerByUserId(userId)
	local entry = player and rigs[player]
	local d = entry and entry.Dragons[slot]
	if not d or not monster or not monster.Parent or not monster.PrimaryPart then
		return
	end
	local from = d.CFrame.Position
	if (from - camera.CFrame.Position).Magnitude > 250 then
		return
	end
	local target = monster.PrimaryPart.Position
	d.Lunge = { Until = os.clock() + 0.25, Target = target }

	local el = Elements.List[element] or Elements.List.Fire
	local orb = Instance.new("Part")
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.CanTouch = false
	orb.CastShadow = false
	orb.Shape = Enum.PartType.Ball
	orb.Material = Enum.Material.Neon
	orb.Color = el.Color
	orb.Size = Vector3.one * (if mult > 1 then 1.6 else 1.1)
	orb.Position = from
	orb.Parent = folder
	local tween = TweenService:Create(orb, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = target })
	tween.Completed:Connect(function()
		orb:Destroy()
		burst(target, el.Color2)
		if monster.Parent then
			hitFlash(monster)
		end
		if player == Players.LocalPlayer and damage then
			damageNumber(target, damage, mult)
		end
	end)
	tween:Play()
end

function DragonVisuals.Start()
	folder = Instance.new("Folder")
	folder.Name = "DragonVisuals"
	folder.Parent = workspace

	for _, p in Players:GetPlayers() do
		track(p)
	end
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(p)
		local entry = rigs[p]
		if entry then
			clear(entry)
		end
		rigs[p] = nil
	end)

	RunService.RenderStepped:Connect(render)
	Remotes.Event("AttackFx").OnClientEvent:Connect(onAttack)
end

return DragonVisuals
