-- Abilità dei draghi: il giocatore preme un pulsante, il server controlla ricarica e posizione
-- e fa danni ai mostri vicini (o attiva Frenzy / Coin Magnet).
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Abilities = require(Shared.Config.Abilities)
local Islands = require(Shared.Config.Islands)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local DragonService = require(script.Parent.DragonService)
local MonsterService = require(script.Parent.MonsterService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local QuestService = require(script.Parent.QuestService)
local Boosts = require(script.Parent.Boosts)

local AbilityService = {}

local cooldowns = {} -- player -> { [id] = pronto da (os.clock) }

local function teamPower(player)
	local total = 0
	for _, entry in DragonService.GetTeam(player) do
		total += DragonService.Power(entry.Dragon)
	end
	return total
end

function AbilityService.Start()
	Players.PlayerRemoving:Connect(function(p)
		cooldowns[p] = nil
	end)

	Remotes.Func("UnlockAbility").OnServerInvoke = function(player, id)
		local data = DataService.Get(player)
		local ability = type(id) == "string" and Abilities.Get(id)
		if not data or not ability then
			return false, "Unknown ability"
		end
		if data.Abilities[id] then
			return true
		end
		if data.Gems < ability.Unlock then
			return false, "You need " .. (ability.Unlock - data.Gems) .. " more gems"
		end
		data.Gems -= ability.Unlock
		data.Abilities[id] = true
		DataService.MarkDirty(player, false)
		return true
	end

	Remotes.Func("UseAbility").OnServerInvoke = function(player, id)
		local data = DataService.Get(player)
		local ability = type(id) == "string" and Abilities.Get(id)
		if not data or not ability or not data.Abilities[id] then
			return false, "Locked"
		end
		local now = os.clock()
		local mine = cooldowns[player] or {}
		cooldowns[player] = mine
		if now < (mine[id] or 0) then
			return false, "Cooldown"
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local index = root and WorldBuilder.IslandAt(root.Position)
		if not index or not data.Unlocked[Islands.Get(index).Id] then
			return false, "Use abilities on an island"
		end
		mine[id] = now + ability.Cooldown

		local targets = {}
		if ability.Damage then
			local damage = teamPower(player) * ability.Damage * Boosts.Damage(player, data)
			local near = MonsterService.Near(index, root.Position, ability.Radius)
			for i, entry in near do
				if ability.MaxTargets and i > ability.MaxTargets then
					break
				end
				table.insert(targets, MonsterService.Position(entry.Monster))
				MonsterService.Damage(entry.Monster, player, damage)
			end
		elseif id == "Frenzy" then
			player:SetAttribute("FrenzyUntil", workspace:GetServerTimeNow() + ability.Duration)
		elseif id == "CoinMagnet" then
			Boosts.Add(data, "Magnet", ability.Duration, 2)
			DataService.MarkDirty(player, false)
		end
		QuestService.Add(player, "Abilities", 1)

		-- Effetto visivo a chi è vicino.
		for _, viewer in Players:GetPlayers() do
			local viewerRoot = viewer.Character and viewer.Character:FindFirstChild("HumanoidRootPart")
			if viewerRoot and (viewerRoot.Position - root.Position).Magnitude < 250 then
				Remotes.Event("AbilityFx"):FireClient(viewer, id, root.Position, targets)
			end
		end
		return true, ability.Cooldown
	end
end

return AbilityService
