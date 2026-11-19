-- Zona di allenamento: chi ci sta dentro fa guadagnare esperienza a tutti i draghi della squadra,
-- anche se resta fermo (AFK). Ogni isola allena più in fretta della precedente.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Islands = require(Shared.Config.Islands)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local DragonService = require(script.Parent.DragonService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Boosts = require(script.Parent.Boosts)
local QuestService = require(script.Parent.QuestService)

local TrainingService = {}

local function trainingIsland(pos: Vector3): number?
	for index, info in WorldBuilder.Islands do
		local d = Vector3.new(pos.X - info.TrainingPos.X, 0, pos.Z - info.TrainingPos.Z).Magnitude
		if d <= WorldBuilder.TrainingRadius and math.abs(pos.Y - info.TrainingPos.Y) < 12 then
			return index
		end
	end
	return nil
end

function TrainingService.Start()
	task.spawn(function()
		local tickCount = 0
		while true do
			task.wait(1)
			tickCount += 1
			-- L'inventario completo (con le barre dell'esperienza) si manda ogni 8 secondi
			-- o quando un drago sale di livello, non ogni secondo: risparmia rete sui telefoni.
			local sendFull = tickCount % 8 == 0
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local index = root and trainingIsland(root.Position)
				if index and data and not data.Unlocked[Islands.Get(index).Id] then
					index = nil
				end
				local was = player:GetAttribute("Training")
				if (index ~= nil) ~= (was == true) then
					player:SetAttribute("Training", index ~= nil)
				end
				if index and data then
					local xp = Islands.Get(index).TrainingXp * Boosts.Training(player, data)
					player:SetAttribute("TrainingXp", xp)
					QuestService.Add(player, "TrainSeconds", 1)
					local leveled = false
					for _, entry in DragonService.GetTeam(player) do
						if DragonService.AddXp(entry.Dragon, xp) then
							leveled = true
						end
					end
					DataService.MarkDirty(player, leveled or sendFull)
					if leveled then
						Remotes.Event("LevelUp"):FireClient(player)
						if data.Settings.AutoEquip then
							DragonService.EquipBest(player)
						end
					end
				end
			end
		end
	end)
end

return TrainingService
