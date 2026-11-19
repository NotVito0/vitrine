-- I mostri delle isole: nascono, girano, perdono vita e rinascono dopo qualche secondo.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Islands = require(Shared.Config.Islands)
local Balance = require(Shared.Config.Balance)
local Format = require(Shared.Format)

local WorldBuilder = require(script.Parent.WorldBuilder)

local MonsterService = {}

local killed = Instance.new("BindableEvent")
MonsterService.Killed = killed.Event -- (monster, damagers: { [Player]: true })

local byIsland = {} -- index -> lista di mostri
local folder
local rng = Random.new()

local function pickDef(island)
	local total = 0
	for _, m in island.Monsters do
		total += m.Weight
	end
	local roll = rng:NextNumber(0, total)
	for _, m in island.Monsters do
		roll -= m.Weight
		if roll <= 0 then
			return m
		end
	end
	return island.Monsters[1]
end

local function newPart(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in props do
		if k ~= "Shape" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function buildModel(def, pos)
	local model = Instance.new("Model")
	model.Name = def.Name
	local s = def.Size
	local body
	if def.Shape == "box" then
		body = newPart(model, { Name = "Body", Size = Vector3.new(s, s * 0.9, s), Color = def.Color, Material = Enum.Material.SmoothPlastic })
	else
		body = newPart(model, { Name = "Body", Shape = Enum.PartType.Ball, Size = Vector3.one * s, Color = def.Color, Material = Enum.Material.SmoothPlastic })
	end
	body.CanQuery = true
	model.PrimaryPart = body
	for _, side in { -1, 1 } do
		newPart(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * s * 0.28, CFrame = CFrame.new(side * s * 0.2, s * 0.15, -s * 0.42), Color = Color3.new(1, 1, 1) })
		newPart(model, { Shape = Enum.PartType.Ball, Size = Vector3.one * s * 0.14, CFrame = CFrame.new(side * s * 0.2, s * 0.15, -s * 0.54), Color = Color3.fromRGB(20, 17, 28) })
	end
	-- Le parti sopra sono state messe attorno all'origine: spostiamo tutto nel punto giusto.
	model:PivotTo(CFrame.new(pos + Vector3.new(0, s / 2, 0)))

	local gui = Instance.new("BillboardGui")
	gui.Name = "Health"
	gui.Size = UDim2.fromOffset(120, 34)
	gui.StudsOffset = Vector3.new(0, s * 0.5 + 1.8, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0.5, 0)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.3
	name.Text = def.Name
	name.Parent = gui
	local back = Instance.new("Frame")
	back.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	back.BorderSizePixel = 0
	back.Position = UDim2.fromScale(0.05, 0.6)
	back.Size = UDim2.fromScale(0.9, 0.3)
	back.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = back
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Color3.fromRGB(94, 224, 143)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = back
	corner:Clone().Parent = fill
	local hp = Instance.new("TextLabel")
	hp.Name = "Hp"
	hp.BackgroundTransparency = 1
	hp.Size = UDim2.fromScale(1, 1)
	hp.Font = Enum.Font.GothamBold
	hp.TextScaled = true
	hp.TextColor3 = Color3.new(1, 1, 1)
	hp.Parent = back
	gui.Parent = body
	model.Parent = folder
	return model, fill, hp
end

local function updateBar(m)
	local frac = math.clamp(m.Health / m.MaxHealth, 0, 1)
	m.Fill.Size = UDim2.fromScale(frac, 1)
	m.HpLabel.Text = Format.Number(math.max(0, m.Health))
end

MonsterService.GoldMult = 1 -- "Golden Monsters" dell'admin abuse: monete x10 e mostri dorati
MonsterService.Tint = nil -- colore degli eventi stagionali (Halloween arancione...)

local GEM_DEF = { Name = "Crystal Golem", Element = "Light", Color = Color3.fromRGB(192, 140, 255), Size = 4.2, Shape = "box", Hp = 1.5, Coins = 0, Weight = 0 }

local function displayColor(def)
	if MonsterService.GoldMult > 1 then
		return Color3.fromRGB(255, 205, 60)
	end
	if MonsterService.Tint and def.Coins > 0 then
		return def.Color:Lerp(MonsterService.Tint, 0.45)
	end
	return def.Color
end

-- special: nil (normale), "gem" (mostro di cristallo che lascia cristalli) o "boss".
local function spawnMonster(index, special)
	local island = Islands.Get(index)
	local def = if special == "gem" then GEM_DEF else pickDef(island)
	if special == "boss" then
		def = table.clone(def)
		def.Name = "👹 GIANT " .. string.upper(def.Name)
		def.Size = 16
		def.Hp *= 400
		def.Coins *= 300
	end
	local shown = table.clone(def)
	shown.Color = displayColor(def)
	local pos = if special == "boss" then WorldBuilder.Islands[index].Center + Vector3.new(0, 0, -6) else WorldBuilder.RandomPoint(index, rng)
	local model, fill, hp = buildModel(shown, pos)
	local maxHealth = math.floor(island.MonsterHp * def.Hp)
	local m = {
		Model = model,
		Island = index,
		Def = def,
		Special = special,
		Gems = if special == "gem" then math.max(2, index * 2) elseif special == "boss" then 25 * index else 0,
		Health = maxHealth,
		MaxHealth = maxHealth,
		Coins = math.max(if special == "gem" then 0 else 1, math.floor(island.MonsterCoins * def.Coins)),
		Home = pos,
		Pos = pos,
		Target = pos,
		Facing = rng:NextNumber(0, math.pi * 2),
		Speed = if special == "boss" then 3 else 7,
		Phase = rng:NextNumber(0, 6),
		Wait = rng:NextNumber(0, 2),
		Damagers = {},
		Alive = true,
		Fill = fill,
		HpLabel = hp,
	}
	model:SetAttribute("Element", def.Element)
	updateBar(m)
	table.insert(byIsland[index], m)
	return m
end

local function die(m)
	m.Alive = false
	local list = byIsland[m.Island]
	local i = table.find(list, m)
	if i then
		table.remove(list, i)
	end
	local body = m.Model.PrimaryPart
	if body then
		local gui = body:FindFirstChild("Health")
		if gui then
			gui:Destroy()
		end
	end
	for _, p in m.Model:GetDescendants() do
		if p:IsA("BasePart") then
			TweenService:Create(p, TweenInfo.new(0.35), { Size = p.Size * 0.1, Transparency = 1 }):Play()
		end
	end
	task.delay(0.4, function()
		m.Model:Destroy()
	end)
	if m.Special then
		return -- i mostri speciali degli eventi non rinascono
	end
	task.delay(Balance.MonsterRespawn, function()
		local regular = 0
		for _, other in byIsland[m.Island] do
			if not other.Special then
				regular += 1
			end
		end
		if regular < Balance.MonstersPerIsland then
			spawnMonster(m.Island)
		end
	end)
end

-- Fa comparire mostri speciali (eventi): "gem" o "boss".
function MonsterService.SpawnSpecial(index: number, special: string)
	return spawnMonster(index, special)
end

-- Ricolora i mostri normali (dopo che cambia GoldMult o Tint).
function MonsterService.Recolor()
	for _, list in byIsland do
		for _, m in list do
			if not m.Special and m.Model.PrimaryPart then
				m.Model.PrimaryPart.Color = displayColor(m.Def)
			end
		end
	end
end

-- Fa danni a un mostro. Ritorna true se l'ha sconfitto.
function MonsterService.Damage(m, player, amount: number): boolean
	if not m.Alive then
		return false
	end
	m.Health -= amount
	m.Damagers[player] = true
	if m.Health <= 0 then
		local damagers = m.Damagers
		die(m)
		killed:Fire(m, damagers)
		return true
	end
	updateBar(m)
	return false
end

-- Mostri vivi entro `radius` da `pos` sull'isola, dal più vicino.
function MonsterService.Near(index: number, pos: Vector3, radius: number)
	local out = {}
	local list = byIsland[index]
	if not list then
		return out
	end
	for _, m in list do
		local d = (Vector3.new(m.Pos.X, 0, m.Pos.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
		if d <= radius then
			table.insert(out, { Monster = m, Distance = d })
		end
	end
	table.sort(out, function(a, b)
		return a.Distance < b.Distance
	end)
	return out
end

function MonsterService.Position(m): Vector3
	return m.Pos + Vector3.new(0, m.Def.Size / 2, 0)
end

local acc = 0
local clock = 0
local occupied = {}
local occupiedAt = -1

-- Isole con almeno un giocatore sopra o vicino: solo lì i mostri si muovono (risparmia server).
local function refreshOccupied()
	occupied = {}
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local index = math.floor(root.Position.X / WorldBuilder.Spacing + 0.5) + 1
			occupied[index] = true
		end
	end
end

local function step(dt)
	acc += dt
	clock += dt
	if acc < 0.1 then
		return
	end
	local delta = acc
	acc = 0
	if clock - occupiedAt > 1 then
		occupiedAt = clock
		refreshOccupied()
	end
	for index, list in byIsland do
		if not occupied[index] then
			continue
		end
		for _, m in list do
			if m.Wait > 0 then
				m.Wait -= delta
			else
				local to = m.Target - m.Pos
				local flat = Vector3.new(to.X, 0, to.Z)
				if flat.Magnitude < 1 then
					m.Wait = rng:NextNumber(1, 3)
					local home = m.Home
					local a = rng:NextNumber(0, math.pi * 2)
					local candidate = home + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(4, 18)
					if WorldBuilder.IslandAt(candidate) == m.Island then
						m.Target = candidate
					end
				else
					local move = flat.Unit * math.min(flat.Magnitude, m.Speed * delta)
					m.Pos += move
					m.Facing = math.atan2(-flat.X, -flat.Z)
				end
			end
			local hop = math.abs(math.sin(clock * 4 + m.Phase)) * (if m.Wait > 0 then 0.3 else 1.4)
			m.Model:PivotTo(CFrame.new(m.Pos + Vector3.new(0, m.Def.Size / 2 + hop, 0)) * CFrame.Angles(0, m.Facing, 0))
		end
	end
end

function MonsterService.Start()
	folder = Instance.new("Folder")
	folder.Name = "Monsters"
	folder.Parent = workspace
	for index in Islands.List do
		byIsland[index] = {}
		for _ = 1, Balance.MonstersPerIsland do
			spawnMonster(index)
		end
	end
	RunService.Heartbeat:Connect(step)
end

return MonsterService
