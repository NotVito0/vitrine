-- Cose del mondo viste dal giocatore: cancelli già sbloccati che spariscono,
-- pulsanti per le uova e i cancelli, uova che girano, monete che volano dai mostri.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Islands = require(Shared.Config.Islands)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)

local World = {}

local player = Players.LocalPlayer
local UI -- impostato da Start per evitare dipendenze circolari

local function refreshGates(data)
	local world = workspace:FindFirstChild("World")
	if not world then
		return
	end
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Gate" then
			local island = Islands.Get(d:GetAttribute("IslandIndex"))
			local open = island and data.Unlocked[island.Id]
			d.CanCollide = not open
			d.Transparency = if open then 1 else 0.1
			for _, c in d:GetChildren() do
				if c:IsA("BillboardGui") or c:IsA("ProximityPrompt") then
					c.Enabled = not open
				end
			end
		elseif d:IsA("ProximityPrompt") and d:GetAttribute("EggIsland") and d:GetAttribute("Amount") ~= 1 then
			d.Enabled = (data.HatchCount or 1) > 1
			d.ActionText = "Open " .. tostring(data.HatchCount or 1)
		end
	end
end

local function floatText(position, text, color)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.Position = position + Vector3.new(0, 2, 0)
	anchor.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 40)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Text = text
	label.Parent = gui
	gui.Parent = anchor
	TweenService:Create(anchor, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Position = anchor.Position + Vector3.new(0, 6, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

local hatching = false
local function onPrompt(prompt)
	local eggIsland = prompt:GetAttribute("EggIsland")
	local gateIsland = prompt:GetAttribute("GateIsland")
	if eggIsland then
		if hatching then
			return
		end
		hatching = true
		local amount = prompt:GetAttribute("Amount")
		local result = Remotes.Func("Hatch"):InvokeServer(eggIsland, amount)
		hatching = false
		if result.Ok then
			UI.ShowHatch(result.Results)
		elseif result.Error == "coins" then
			UI.NeedCoins(result.Missing)
		elseif result.Error == "full" then
			UI.Toast("Your inventory is full. Delete some dragons first.", "error")
		elseif result.Error == "locked" then
			UI.Toast("Unlock this island first.", "error")
		end
	elseif gateIsland then
		local ok, message = Remotes.Func("UnlockIsland"):InvokeServer(gateIsland)
		if ok then
			UI.Toast("🗺️ " .. Islands.Get(gateIsland).Name .. " unlocked!", "success")
		else
			UI.Toast(message or "Not enough coins", "error")
		end
	end
end

function World.Start(ui)
	UI = ui
	State.Changed:Connect(function(data)
		refreshGates(data)
	end)
	if State.Data then
		refreshGates(State.Data)
	end

	ProximityPromptService.PromptTriggered:Connect(onPrompt)

	Remotes.Event("Reward").OnClientEvent:Connect(function(reward)
		if reward.Coins > 0 then
			floatText(reward.Position, "+" .. Format.Number(reward.Coins) .. " 🪙", Color3.fromRGB(255, 216, 94))
		end
		if reward.Gems > 0 then
			floatText(reward.Position + Vector3.new(0, 1.5, 0), "+" .. reward.Gems .. " 💎", Color3.fromRGB(214, 170, 255))
		end
		UI.Bump()
	end)

	-- Le uova girano piano sul piedistallo.
	local eggs = {}
	task.spawn(function()
		local world = workspace:WaitForChild("World")
		task.wait(1)
		for _, d in world:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("Spin") then
				table.insert(eggs, { Part = d, Base = d.CFrame })
			end
		end
	end)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, e in eggs do
			e.Part.CFrame = e.Base * CFrame.new(0, math.sin(t * 2) * 0.4, 0) * CFrame.Angles(0, t * 0.8, 0)
		end
	end)
end

return World
