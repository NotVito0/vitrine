-- Costruisce le isole all'avvio del server, tutte con le forme di Roblox: terreno, decorazioni,
-- ponti, cancelli da sbloccare, uovo dell'isola e zona di allenamento.
-- Così una nuova isola in un aggiornamento è solo una voce in più in Config/Islands.lua.
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Islands = require(Shared.Config.Islands)
local Dragons = require(Shared.Config.Dragons)
local Format = require(Shared.Format)

local WorldBuilder = {}

WorldBuilder.Spacing = 300
WorldBuilder.Radius = 95
WorldBuilder.TrainingRadius = 18
WorldBuilder.Islands = {} -- index -> { Center, EggPos, TrainingPos, Folder }

local world

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	-- La forma va impostata prima della misura, e il genitore per ultimo.
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.Size then
		p.Size = props.Size
	end
	for k, v in props do
		if k ~= "Parent" and k ~= "Shape" and k ~= "Size" then
			p[k] = v
		end
	end
	p.Parent = props.Parent
	return p
end

local function billboard(adornee, text, size, offset, color, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffset = offset
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	gui.MaxDistance = maxDistance or 150
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = text
	label.Parent = gui
	gui.Parent = adornee
	return gui, label
end

local function prompt(parent, action, object, key, attrs)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = object
	p.KeyboardKeyCode = key or Enum.KeyCode.E
	p.HoldDuration = 0
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	for k, v in attrs do
		p:SetAttribute(k, v)
	end
	p.Parent = parent
	return p
end

-- Decorazioni semplici. `rng` rende ogni isola sempre uguale a ogni avvio.
local DECOR = {}

function DECOR.tree(folder, pos, rng, island)
	local s = rng:NextNumber(0.8, 1.4)
	part({ Parent = folder, Size = Vector3.new(1.6, 8, 1.6) * s, Position = pos + Vector3.new(0, 4 * s, 0), Color = Color3.fromRGB(122, 80, 46), Material = Enum.Material.Wood })
	local leaves = part({ Parent = folder, Shape = Enum.PartType.Ball, Size = Vector3.one * 8 * s, Position = pos + Vector3.new(0, 10 * s, 0), Color = island.Ground:Lerp(Color3.fromRGB(40, 120, 40), 0.5), Material = Enum.Material.Grass })
	leaves.CanCollide = false
end

function DECOR.pine(folder, pos, rng, island)
	local s = rng:NextNumber(0.9, 1.5)
	part({ Parent = folder, Size = Vector3.new(1.4, 6, 1.4) * s, Position = pos + Vector3.new(0, 3 * s, 0), Color = Color3.fromRGB(100, 66, 40), Material = Enum.Material.Wood })
	local green = if island.Id == "Glacier" then Color3.fromRGB(200, 230, 220) else Color3.fromRGB(40, 110, 60)
	for i = 0, 2 do
		local size = (6 - i * 1.6) * s
		local p = part({ Parent = folder, Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size), Position = pos + Vector3.new(0, (6 + i * 3) * s, 0), Color = green, Material = Enum.Material.Grass })
		p.CanCollide = false
	end
end

function DECOR.palm(folder, pos, rng)
	local s = rng:NextNumber(0.9, 1.3)
	part({ Parent = folder, Size = Vector3.new(1.2, 12, 1.2) * s, CFrame = CFrame.new(pos + Vector3.new(0, 6 * s, 0)) * CFrame.Angles(0, 0, 0.12), Color = Color3.fromRGB(160, 120, 70), Material = Enum.Material.Wood })
	for i = 0, 4 do
		local leaf = part({ Parent = folder, Size = Vector3.new(7, 0.3, 1.8) * s, Color = Color3.fromRGB(60, 160, 70), Material = Enum.Material.Grass })
		leaf.CFrame = CFrame.new(pos + Vector3.new(0.8, 12 * s, 0)) * CFrame.Angles(0, i * math.pi * 2 / 5, -0.35) * CFrame.new(3 * s, 0, 0)
		leaf.CanCollide = false
	end
end

function DECOR.cactus(folder, pos, rng)
	local s = rng:NextNumber(0.8, 1.4)
	local green = Color3.fromRGB(70, 150, 80)
	part({ Parent = folder, Size = Vector3.new(2, 9, 2) * s, Position = pos + Vector3.new(0, 4.5 * s, 0), Color = green, Material = Enum.Material.Grass })
	part({ Parent = folder, Size = Vector3.new(3, 1.2, 1.2) * s, Position = pos + Vector3.new(1.8 * s, 4 * s, 0), Color = green, Material = Enum.Material.Grass })
	part({ Parent = folder, Size = Vector3.new(1.2, 3, 1.2) * s, Position = pos + Vector3.new(2.9 * s, 5.5 * s, 0), Color = green, Material = Enum.Material.Grass })
end

function DECOR.rock(folder, pos, rng, island)
	local s = rng:NextNumber(2, 5)
	part({ Parent = folder, Size = Vector3.new(s * 1.3, s, s), CFrame = CFrame.new(pos + Vector3.new(0, s * 0.35, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), Color = island.Cliff:Lerp(Color3.fromRGB(130, 130, 130), 0.5), Material = Enum.Material.Rock })
end

function DECOR.flower(folder, pos, rng)
	local colors = { Color3.fromRGB(255, 120, 160), Color3.fromRGB(255, 220, 80), Color3.fromRGB(180, 140, 255), Color3.new(1, 1, 1) }
	local p = part({ Parent = folder, Shape = Enum.PartType.Ball, Size = Vector3.one * 1.1, Position = pos + Vector3.new(0, 0.6, 0), Color = colors[rng:NextInteger(1, #colors)] })
	p.CanCollide = false
end

function DECOR.shell(folder, pos, rng)
	local p = part({ Parent = folder, Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(0.8, 1.4), Position = pos + Vector3.new(0, 0.3, 0), Color = Color3.fromRGB(255, 200, 190) })
	p.CanCollide = false
end

function DECOR.lava(folder, pos, rng)
	local r = rng:NextNumber(6, 12)
	local p = part({ Parent = folder, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, r, r), CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 110, 30), Material = Enum.Material.Neon })
	p.CanCollide = false
end

function DECOR.spike(folder, pos, rng)
	local h = rng:NextNumber(6, 14)
	part({ Parent = folder, Size = Vector3.new(2.2, h, 2.2), CFrame = CFrame.new(pos + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 6), rng:NextNumber(-0.25, 0.25)), Color = Color3.fromRGB(170, 225, 250), Material = Enum.Material.Ice, Transparency = 0.2 })
end

function DECOR.crystal(folder, pos, rng)
	local h = rng:NextNumber(5, 11)
	part({ Parent = folder, Size = Vector3.new(1.8, h, 1.8), CFrame = CFrame.new(pos + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6), rng:NextNumber(-0.3, 0.3)), Color = Color3.fromRGB(255, 220, 70), Material = Enum.Material.Neon, Transparency = 0.15 })
end

function DECOR.cloud(folder, pos, rng)
	for i = 1, 3 do
		local p = part({ Parent = folder, Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(4, 7), Position = pos + Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(1, 3), rng:NextNumber(-3, 3)), Color = Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic })
		p.CanCollide = i == 1
	end
end

function DECOR.pillar(folder, pos, rng)
	local h = rng:NextNumber(8, 16)
	part({ Parent = folder, Size = Vector3.new(2.5, h, 2.5), Position = pos + Vector3.new(0, h / 2, 0), Color = Color3.fromRGB(255, 225, 150), Material = Enum.Material.Marble })
end

local function randomPointOnIsland(rng, center, keepAway)
	for _ = 1, 30 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = math.sqrt(rng:NextNumber(0, 1)) * (WorldBuilder.Radius - 10)
		local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		local ok = true
		for _, k in keepAway do
			if (pos - k.Pos).Magnitude < k.R then
				ok = false
				break
			end
		end
		if ok then
			return pos
		end
	end
	return center + Vector3.new(0, 0, WorldBuilder.Radius * 0.6)
end

local function buildEgg(folder, island, index, pos)
	local base = part({ Parent = folder, Name = "EggStand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 10, 10), CFrame = CFrame.new(pos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(70, 70, 90), Material = Enum.Material.Slate })
	local egg = part({ Parent = folder, Name = "Egg", Size = Vector3.new(6, 7.5, 6), Position = pos + Vector3.new(0, 6, 0), Color = island.EggColor, Material = Enum.Material.SmoothPlastic, CanCollide = false })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	egg:SetAttribute("Spin", true)

	-- Probabilità sempre visibili sopra l'uovo.
	local lines = { island.Name .. " Egg · " .. Format.Number(island.EggCost) .. " coins" }
	local total = 0
	for _, r in Dragons.EggRarities do
		total += Dragons.EggWeights[r]
	end
	for slot, id in island.EggDragons do
		local def = Dragons.Get(id)
		local pct = Dragons.EggWeights[def.Rarity] / total * 100
		table.insert(lines, string.format("%s  %s%%", def.Name, if pct < 0.1 then string.format("%.2f", pct) elseif pct < 10 then string.format("%.1f", pct) else string.format("%d", pct)))
	end
	local gui, label = billboard(egg, table.concat(lines, "\n"), UDim2.fromOffset(240, 230), Vector3.new(0, 9, 0), Color3.new(1, 1, 1), 60)
	label.TextScaled = false
	label.TextSize = 15
	label.TextYAlignment = Enum.TextYAlignment.Bottom

	prompt(base, "Open 1", island.Name .. " Egg", Enum.KeyCode.E, { EggIsland = index, Amount = 1 })
	local multi = prompt(base, "Open Multi", island.Name .. " Egg", Enum.KeyCode.R, { EggIsland = index, Amount = 99 })
	multi.UIOffset = Vector2.new(0, 80)
end

local function buildTraining(folder, island, index, pos)
	local r = WorldBuilder.TrainingRadius
	local pad = part({ Parent = folder, Name = "TrainingZone", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, r * 2, r * 2), CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(70, 160, 255), Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false })
	billboard(pad, "🏋️ TRAINING ZONE\nStand here: your dragons gain XP", UDim2.fromOffset(260, 60), Vector3.new(0, 9, 0), Color3.fromRGB(150, 210, 255), 120)
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		local p = pos + Vector3.new(math.cos(a) * (r - 4), 0, math.sin(a) * (r - 4))
		part({ Parent = folder, Size = Vector3.new(0.8, 4, 0.8), Position = p + Vector3.new(0, 2, 0), Color = Color3.fromRGB(140, 100, 60), Material = Enum.Material.Wood })
		part({ Parent = folder, Size = Vector3.new(2.4, 2.6, 1.6), Position = p + Vector3.new(0, 4.6, 0), Color = Color3.fromRGB(220, 190, 140), Material = Enum.Material.Fabric })
		local head = part({ Parent = folder, Shape = Enum.PartType.Ball, Size = Vector3.one * 1.8, Position = p + Vector3.new(0, 6.6, 0), Color = Color3.fromRGB(220, 190, 140), Material = Enum.Material.Fabric })
		local face = Instance.new("Decal")
		face.Face = Enum.NormalId.Front
		face.Texture = "rbxasset://textures/face.png"
		face.Parent = head
	end
end

-- Banco del mercato: tenda a strisce, bancone e boccette colorate.
local function buildMarket(folder, pos)
	local market = Instance.new("Model")
	market.Name = "Market"
	market.Parent = folder
	local wood = Color3.fromRGB(140, 96, 58)
	local counter = part({ Parent = market, Name = "Counter", Size = Vector3.new(14, 3.6, 4), Position = pos + Vector3.new(0, 1.8, 0), Color = wood, Material = Enum.Material.WoodPlanks })
	for _, x in { -6.5, 6.5 } do
		part({ Parent = market, Size = Vector3.new(0.8, 10, 0.8), Position = pos + Vector3.new(x, 5, -1.6), Color = wood, Material = Enum.Material.Wood })
		part({ Parent = market, Size = Vector3.new(0.8, 10, 0.8), Position = pos + Vector3.new(x, 5, 3), Color = wood, Material = Enum.Material.Wood })
	end
	for i = 0, 6 do
		local color = if i % 2 == 0 then Color3.fromRGB(255, 90, 110) else Color3.fromRGB(255, 245, 235)
		part({ Parent = market, Size = Vector3.new(2.1, 0.4, 6.4), CFrame = CFrame.new(pos + Vector3.new(-6.3 + i * 2.1, 10.4, 0.7)) * CFrame.Angles(math.rad(-12), 0, 0), Color = color, Material = Enum.Material.Fabric })
	end
	local colors = { Color3.fromRGB(90, 220, 120), Color3.fromRGB(255, 205, 70), Color3.fromRGB(255, 90, 90), Color3.fromRGB(80, 170, 255), Color3.fromRGB(255, 160, 230), Color3.fromRGB(190, 120, 255) }
	for i, c in colors do
		local x = -5.5 + (i - 1) * 2.2
		local bottle = part({ Parent = market, Shape = Enum.PartType.Ball, Size = Vector3.one * 1.3, Position = pos + Vector3.new(x, 4.25, 0), Color = c, Material = Enum.Material.Neon, CanCollide = false })
		bottle.Transparency = 0.1
		part({ Parent = market, Size = Vector3.new(0.4, 0.6, 0.4), Position = pos + Vector3.new(x, 5.1, 0), Color = Color3.fromRGB(230, 230, 240), Material = Enum.Material.Glass, CanCollide = false })
	end
	billboard(counter, "🧪 POTION MARKET\nRestocks every 5 minutes", UDim2.fromOffset(240, 60), Vector3.new(0, 11, 0), Color3.fromRGB(255, 220, 240), 120)
	prompt(counter, "Shop", "Potion Market", Enum.KeyCode.E, { OpenMarket = true })
end

-- Nido degli incroci: un grande nido di rami con un uovo luminoso.
local function buildNest(folder, pos)
	local nest = Instance.new("Model")
	nest.Name = "Nest"
	nest.Parent = folder
	local base = part({ Parent = nest, Name = "NestBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 12, 12), CFrame = CFrame.new(pos + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(110, 74, 44), Material = Enum.Material.Wood })
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		part({ Parent = nest, Size = Vector3.new(0.7, 0.7, 5), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 5.4, 1.6, math.sin(a) * 5.4)) * CFrame.Angles(0, -a, math.rad(18 * ((i % 2) * 2 - 1))), Color = Color3.fromRGB(140, 98, 58), Material = Enum.Material.Wood })
	end
	local egg = part({ Parent = nest, Size = Vector3.new(3.4, 4.2, 3.4), Position = pos + Vector3.new(0, 3.6, 0), Color = Color3.fromRGB(230, 200, 255), Material = Enum.Material.Neon, CanCollide = false })
	egg.Transparency = 0.15
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	billboard(base, "🪺 BREEDING NEST\nMix two elements, discover secret dragons", UDim2.fromOffset(280, 60), Vector3.new(0, 8, 0), Color3.fromRGB(230, 200, 255), 120)
	prompt(base, "Breed", "Breeding Nest", Enum.KeyCode.E, { OpenNest = true })
end

local function buildGate(folder, toIndex, x)
	local island = Islands.Get(toIndex)
	local gate = part({ Parent = folder, Name = "Gate", Size = Vector3.new(2, 18, 20), Position = Vector3.new(x, 9, 0), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.ForceField, Transparency = 0.1 })
	gate:SetAttribute("IslandIndex", toIndex)
	billboard(gate, "🔒 " .. island.Name .. "\n" .. Format.Number(island.UnlockCost) .. " coins", UDim2.fromOffset(220, 70), Vector3.new(0, 12, 0), Color3.fromRGB(255, 225, 120), 200)
	prompt(gate, "Unlock", island.Name, Enum.KeyCode.E, { GateIsland = toIndex })
end

function WorldBuilder.Build()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = workspace

	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmo = Instance.new("Atmosphere")
		atmo.Density = 0.28
		atmo.Color = Color3.fromRGB(200, 225, 255)
		atmo.Decay = Color3.fromRGB(120, 160, 220)
		atmo.Parent = Lighting
	end

	for index, island in Islands.List do
		local center = Vector3.new((index - 1) * WorldBuilder.Spacing, 0, 0)
		local folder = Instance.new("Folder")
		folder.Name = island.Id
		folder.Parent = world
		local R = WorldBuilder.Radius

		part({ Parent = folder, Name = "Ground", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, R * 2, R * 2), CFrame = CFrame.new(center - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = island.Ground, Material = island.Material })
		part({ Parent = folder, Name = "Cliff", Shape = Enum.PartType.Cylinder, Size = Vector3.new(40, R * 2 - 6, R * 2 - 6), CFrame = CFrame.new(center - Vector3.new(0, 24, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = island.Cliff, Material = Enum.Material.Rock })

		local sign = part({ Parent = folder, Name = "Sign", Size = Vector3.new(1, 1, 1), Position = center + Vector3.new(0, 40, 0), Transparency = 1, CanCollide = false })
		billboard(sign, island.Name, UDim2.fromOffset(400, 90), Vector3.new(), Color3.new(1, 1, 1), 400)

		local eggPos = center + Vector3.new(-30, 0, -32)
		local trainingPos = center + Vector3.new(32, 0, -34)
		buildEgg(folder, island, index, eggPos)
		buildTraining(folder, island, index, trainingPos)
		local marketPos = center + Vector3.new(-34, 0, 34)
		buildMarket(folder, marketPos)
		local nestPos = center + Vector3.new(34, 0, 32)
		buildNest(folder, nestPos)

		local keepAway = {
			{ Pos = marketPos, R = 14 },
			{ Pos = nestPos, R = 12 },
			{ Pos = eggPos, R = 14 },
			{ Pos = trainingPos, R = WorldBuilder.TrainingRadius + 6 },
			{ Pos = center + Vector3.new(0, 0, 20), R = 14 }, -- zona di arrivo
			{ Pos = center + Vector3.new(R, 0, 0), R = 16 }, -- ponti
			{ Pos = center - Vector3.new(R, 0, 0), R = 16 },
		}
		local rng = Random.new(index * 7919)
		local decorFolder = Instance.new("Folder")
		decorFolder.Name = "Decor"
		decorFolder.Parent = folder
		for _, entry in island.Decor do
			local builder = DECOR[entry[1]]
			for _ = 1, entry[2] do
				builder(decorFolder, randomPointOnIsland(rng, center, keepAway), rng, island)
			end
		end

		if index < #Islands.List then
			local nextCenter = center + Vector3.new(WorldBuilder.Spacing, 0, 0)
			local length = WorldBuilder.Spacing - 2 * R + 8
			part({ Parent = folder, Name = "Bridge", Size = Vector3.new(length, 2, 18), Position = Vector3.new(center.X + WorldBuilder.Spacing / 2, -1, 0), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks })
			for _, side in { -1, 1 } do
				part({ Parent = folder, Size = Vector3.new(length, 1, 1), Position = Vector3.new(center.X + WorldBuilder.Spacing / 2, 2.5, 9 * side), Color = Color3.fromRGB(110, 80, 50), Material = Enum.Material.Wood })
			end
			buildGate(folder, index + 1, nextCenter.X - R - 4)
		end

		WorldBuilder.Islands[index] = {
			Center = center,
			EggPos = eggPos,
			TrainingPos = trainingPos,
			Folder = folder,
			KeepAway = keepAway,
		}
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 20)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = world
	local existing = workspace:FindFirstChild("SpawnLocation")
	if existing and existing ~= spawn then
		existing:Destroy()
	end
	workspace.FallenPartsDestroyHeight = -200
end

-- Su quale isola si trova questa posizione (nil se sul ponte o nel vuoto).
function WorldBuilder.IslandAt(pos: Vector3): number?
	local index = math.floor(pos.X / WorldBuilder.Spacing + 0.5) + 1
	local info = WorldBuilder.Islands[index]
	if not info then
		return nil
	end
	local flat = Vector3.new(pos.X - info.Center.X, 0, pos.Z - info.Center.Z)
	if flat.Magnitude <= WorldBuilder.Radius + 2 then
		return index
	end
	return nil
end

function WorldBuilder.RandomPoint(index: number, rng)
	local info = WorldBuilder.Islands[index]
	return randomPointOnIsland(rng or Random.new(), info.Center, info.KeepAway)
end

function WorldBuilder.Arrival(index: number): Vector3
	return WorldBuilder.Islands[index].Center + Vector3.new(0, 4, 20)
end

return WorldBuilder
