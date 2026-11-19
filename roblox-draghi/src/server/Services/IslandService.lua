-- Sblocco delle isole, rinascita e pass "Fast Walk".
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Balance = require(Shared.Config.Balance)
local Islands = require(Shared.Config.Islands)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PassService = require(script.Parent.PassService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local IslandService = {}

local function applySpeed(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local speed = if PassService.Has(player, "Speed") then 32 else 20
		if workspace:GetAttribute("SpeedBoost") then
			speed += 24 -- "Speed Rush" dell'admin abuse
		end
		humanoid.WalkSpeed = speed
	end
end

function IslandService.Start()
	Remotes.Func("UnlockIsland").OnServerInvoke = function(player, index)
		local data = DataService.Get(player)
		local island = type(index) == "number" and Islands.Get(index)
		if not data or not island then
			return false, "Unknown island"
		end
		if data.Unlocked[island.Id] then
			return true
		end
		local previous = Islands.Get(index - 1)
		if previous and not data.Unlocked[previous.Id] then
			return false, "Unlock " .. previous.Name .. " first"
		end
		if data.Coins < island.UnlockCost then
			return false, "You need " .. Format.Number(island.UnlockCost - data.Coins) .. " more coins"
		end
		data.Coins -= island.UnlockCost
		data.Unlocked[island.Id] = true
		DataService.MarkDirty(player, false)
		Remotes.Event("Notify"):FireAllClients(player.DisplayName .. " unlocked " .. island.Name .. "!", "info")
		return true
	end

	Remotes.Func("Rebirth").OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then
			return false, "Not ready"
		end
		local cost = Balance.RebirthCost(data.Rebirths)
		if data.Coins < cost then
			return false, "You need " .. Format.Number(cost - data.Coins) .. " more coins"
		end
		data.Coins = 0
		data.Unlocked = { [Islands.List[1].Id] = true }
		data.Rebirths += 1
		DataService.MarkDirty(player, true)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(WorldBuilder.Arrival(1))
		end
		Remotes.Event("Notify"):FireAllClients(player.DisplayName .. " reached Rebirth " .. data.Rebirths .. "!", "info")
		return true
	end

	local function hook(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			applySpeed(player)
		end)
		if player.Character then
			applySpeed(player)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	PassService.Changed:Connect(applySpeed)
	workspace:GetAttributeChangedSignal("SpeedBoost"):Connect(function()
		for _, p in Players:GetPlayers() do
			applySpeed(p)
		end
	end)
end

return IslandService
