-- Aure e scie: acquisto, scelta e aspetto sul personaggio. Anche il tag VIP sopra la testa.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Cosmetics = require(Shared.Config.Cosmetics)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PassService = require(script.Parent.PassService)

local CosmeticService = {}

local function owns(player, data, kind, item)
	if item.Price.VIP then
		return PassService.Has(player, "VIP")
	end
	return data.Cosmetics.Owned[kind .. "_" .. item.Id] == true
end

local function sequence(item)
	if item.Rainbow then
		return Cosmetics.RainbowSequence
	end
	return ColorSequence.new(item.Colors[1], item.Colors[2])
end

-- Rimette aura, scia e tag VIP sul personaggio attuale.
function CosmeticService.Apply(player)
	local data = DataService.Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	for _, name in { "SGAura", "SGAuraLight", "SGTrail", "SGTrailTop", "SGTrailBottom" } do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end

	local aura = Cosmetics.Find("Aura", data.Cosmetics.Aura)
	if aura and owns(player, data, "Aura", aura) then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "SGAura"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = sequence(aura)
		emitter.LightEmission = 0.8
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new(0.2)
		emitter.Lifetime = NumberRange.new(0.8, 1.4)
		emitter.Rate = 30
		emitter.Speed = NumberRange.new(1, 3)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Acceleration = Vector3.new(0, 4, 0)
		emitter.Parent = root
		local light = Instance.new("PointLight")
		light.Name = "SGAuraLight"
		light.Color = aura.Colors[1]
		light.Range = 8
		light.Brightness = 1
		light.Parent = root
	end

	local trail = Cosmetics.Find("Trail", data.Cosmetics.Trail)
	if trail and owns(player, data, "Trail", trail) then
		local top = Instance.new("Attachment")
		top.Name = "SGTrailTop"
		top.Position = Vector3.new(0, 1, 0)
		top.Parent = root
		local bottom = Instance.new("Attachment")
		bottom.Name = "SGTrailBottom"
		bottom.Position = Vector3.new(0, -1.5, 0)
		bottom.Parent = root
		local t = Instance.new("Trail")
		t.Name = "SGTrail"
		t.Attachment0 = top
		t.Attachment1 = bottom
		t.Color = sequence(trail)
		t.LightEmission = 0.9
		t.Lifetime = 0.6
		t.MinLength = 0.1
		t.FaceCamera = true
		t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		t.Parent = root
	end

	-- Tag VIP sopra la testa
	local head = character:FindFirstChild("Head")
	local oldTag = head and head:FindFirstChild("SGVipTag")
	if oldTag then
		oldTag:Destroy()
	end
	local vip = PassService.Has(player, "VIP")
	player:SetAttribute("VIP", vip)
	if vip and head then
		local gui = Instance.new("BillboardGui")
		gui.Name = "SGVipTag"
		gui.Size = UDim2.fromOffset(90, 26)
		gui.StudsOffset = Vector3.new(0, 2.6, 0)
		gui.MaxDistance = 80
		gui.LightInfluence = 0
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 210, 60)
		label.TextStrokeTransparency = 0.2
		label.Text = "👑 VIP"
		label.Parent = gui
		gui.Parent = head
	end
end

function CosmeticService.Grant(data, kind: string, id: string)
	data.Cosmetics.Owned[kind .. "_" .. id] = true
end

function CosmeticService.Start()
	local function hook(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			character:WaitForChild("Head", 10)
			CosmeticService.Apply(player)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	DataService.PlayerLoaded:Connect(CosmeticService.Apply)
	PassService.Changed:Connect(CosmeticService.Apply)

	Remotes.Func("BuyCosmetic").OnServerInvoke = function(player, kind, id)
		local data = DataService.Get(player)
		local item = type(kind) == "string" and type(id) == "string" and Cosmetics.Find(kind, id)
		if not data or not item then
			return false, "Unknown item"
		end
		if owns(player, data, kind, item) then
			return true
		end
		if item.Price.VIP then
			return false, "Get the VIP pass to unlock this"
		end
		if item.Price.Product then
			return false, "product" -- il client apre l'acquisto in Robux
		end
		if data.Gems < item.Price.Gems then
			return false, "You need " .. (item.Price.Gems - data.Gems) .. " more gems"
		end
		data.Gems -= item.Price.Gems
		CosmeticService.Grant(data, kind, id)
		DataService.MarkDirty(player, false)
		return true
	end

	Remotes.Func("EquipCosmetic").OnServerInvoke = function(player, kind, id)
		local data = DataService.Get(player)
		if not data or (kind ~= "Aura" and kind ~= "Trail") or type(id) ~= "string" then
			return false
		end
		if id ~= "" then
			local item = Cosmetics.Find(kind, id)
			if not item or not owns(player, data, kind, item) then
				return false, "You don't own this yet"
			end
		end
		data.Cosmetics[kind] = id
		CosmeticService.Apply(player)
		DataService.MarkDirty(player, false)
		return true
	end
end

return CosmeticService
