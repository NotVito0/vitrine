-- Primi minuti di gioco: una scia luminosa e una scritta guidano il nuovo giocatore
-- 1) verso i mostri, 2) verso l'uovo, 3) verso il cancello della seconda isola. Poi sparisce per sempre.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Islands = require(Shared.Config.Islands)

local State = require(script.Parent.State)

local Tutorial = {}

local player = Players.LocalPlayer

local function dragonCount(data)
	local n = 0
	for _ in data.Dragons do
		n += 1
	end
	return n
end

-- Quale passo mostrare adesso (nil = tutorial finito).
local function currentStep(data)
	if data.Rebirths > 0 or data.Unlocked[Islands.List[2].Id] then
		return nil
	end
	if data.Coins < Islands.List[1].EggCost and dragonCount(data) < 2 then
		return "fight"
	end
	if dragonCount(data) < 2 then
		return "egg"
	end
	return "gate"
end

local TEXT = {
	fight = "⚔️ Walk to a monster: your dragons fight on their own!",
	egg = "🥚 You have enough coins! Go to the egg and press E",
	gate = "🗺️ Collect coins and unlock the Forest",
}

local function findTarget(step, root)
	local world = workspace:FindFirstChild("World")
	if step == "fight" then
		local monsters = workspace:FindFirstChild("Monsters")
		local best, bestDist = nil, math.huge
		if monsters then
			for _, m in monsters:GetChildren() do
				if m.PrimaryPart then
					local d = (m.PrimaryPart.Position - root.Position).Magnitude
					if d < bestDist and m.PrimaryPart.Position.X < 150 then
						best, bestDist = m.PrimaryPart, d
					end
				end
			end
		end
		return best
	elseif step == "egg" then
		local island = world and world:FindFirstChild(Islands.List[1].Id)
		return island and island:FindFirstChild("EggStand")
	elseif step == "gate" then
		local island = world and world:FindFirstChild(Islands.List[1].Id)
		return island and island:FindFirstChild("Gate")
	end
	return nil
end

function Tutorial.Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Tutorial"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -24)
	hint.Size = UDim2.fromOffset(460, 48)
	hint.BackgroundColor3 = Color3.fromRGB(22, 35, 58)
	hint.BackgroundTransparency = 0.1
	hint.Font = Enum.Font.FredokaOne
	hint.TextSize = 20
	hint.TextWrapped = true
	hint.TextColor3 = Color3.new(1, 1, 1)
	hint.Visible = false
	hint.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = hint
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 61)
	stroke.Thickness = 2
	stroke.Parent = hint

	local beam = Instance.new("Beam")
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90))
	beam.LightEmission = 1
	beam.FaceCamera = true
	beam.Width0 = 1.2
	beam.Width1 = 1.2
	beam.Segments = 20
	beam.CurveSize0 = 6
	beam.CurveSize1 = -6
	beam.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.TextureLength = 3
	beam.TextureSpeed = 2
	beam.Transparency = NumberSequence.new(0.15)
	local from = Instance.new("Attachment")
	local to = Instance.new("Attachment")
	beam.Attachment0 = from
	beam.Attachment1 = to
	beam.Parent = workspace.Terrain
	to.Parent = workspace.Terrain

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.25 then
			return
		end
		acc = 0
		local data = State.Data
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local step = data and data.Dragons and currentStep(data)
		local target = step and root and findTarget(step, root)
		if not target then
			hint.Visible = false
			beam.Enabled = false
			return
		end
		hint.Text = TEXT[step]
		hint.Visible = true
		if from.Parent ~= root then
			from.Parent = root
		end
		to.WorldPosition = target.Position + Vector3.new(0, 2, 0)
		-- Vicino all'obiettivo la scia sparisce, resta solo la scritta.
		beam.Enabled = (root.Position - target.Position).Magnitude > 14
	end)
end

return Tutorial
