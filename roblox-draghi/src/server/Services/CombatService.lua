-- Combattimento automatico: quando un giocatore è vicino ai mostri, la modalità combattimento
-- si attiva da sola e i suoi draghi attaccano finché non ci sono più mostri intorno.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Balance = require(Shared.Config.Balance)
local Dragons = require(Shared.Config.Dragons)
local Elements = require(Shared.Config.Elements)
local Islands = require(Shared.Config.Islands)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Analytics)
local DragonService = require(script.Parent.DragonService)
local MonsterService = require(script.Parent.MonsterService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Boosts = require(script.Parent.Boosts)

local CombatService = {}

local state = {} -- player -> { Next = { [uid] = time }, Focus = monster }
local rng = Random.new()

local function bestUnlocked(data): number
	local best = 1
	for i, island in Islands.List do
		if data.Unlocked[island.Id] then
			best = i
		end
	end
	return best
end

local function onKilled(m, damagers)
	local island = Islands.Get(m.Island)
	if m.Special == "boss" then
		Remotes.Event("Notify"):FireAllClients("👹 The giant boss on " .. island.Name .. " was defeated!", "success")
	end
	for player in damagers do
		local data = DataService.Get(player)
		if data and player.Parent then
			local coins = math.floor(m.Coins * Boosts.Coins(player, data) * MonsterService.GoldMult)
			data.Coins += coins
			data.Stats.CoinsEarned += coins
			data.Stats.MonstersDefeated += 1
			Analytics.Step(player, data, "FirstKill")
			local gems = m.Gems or 0
			if rng:NextNumber() < Balance.GemChance then
				gems += rng:NextInteger(1, 2 + math.floor(m.Island / 2))
			end
			data.Gems += gems
			-- Durante gli eventi delle feste, raramente un mostro lascia il drago dell'evento.
			local drop = Boosts.EventDrop
			if drop and rng:NextNumber() < drop.Chance * (if m.Special == "boss" then 50 else 1) then
				local uid = DragonService.Add(player, drop.Dragon, { Force = true })
				if uid then
					Remotes.Event("HatchFx"):FireClient(player, { { Id = drop.Dragon, Shiny = false, New = true } }, m.Island)
					Remotes.Event("Notify"):FireAllClients("🎉 " .. player.DisplayName .. " found the " .. Dragons.Get(drop.Dragon).Name .. "!", "info")
				end
			end
			local leveled = false
			local xp = Balance.KillXp * island.TrainingXp
			for _, entry in DragonService.GetTeam(player) do
				if DragonService.AddXp(entry.Dragon, xp) then
					leveled = true
				end
			end
			Remotes.Event("Reward"):FireClient(player, { Coins = coins, Gems = gems, Position = MonsterService.Position(m) })
			DataService.MarkDirty(player, leveled)
			if leveled then
				Remotes.Event("LevelUp"):FireClient(player)
			end
		end
	end
end

local function tick(player, now)
	local data = DataService.Get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		player:SetAttribute("InCombat", false)
		return
	end
	local pos = root.Position
	local index = WorldBuilder.IslandAt(pos)
	player:SetAttribute("Island", index or 0)

	-- Protezione: se qualcuno arriva su un'isola non sbloccata (salti, exploit) torna indietro.
	if index and not data.Unlocked[Islands.Get(index).Id] then
		root.CFrame = CFrame.new(WorldBuilder.Arrival(bestUnlocked(data)))
		Remotes.Event("Notify"):FireClient(player, "Unlock this island first!", "error")
		return
	end

	if not index then
		player:SetAttribute("InCombat", false)
		return
	end

	local near = MonsterService.Near(index, pos, Balance.CombatRadius)
	local inCombat = #near > 0
	if player:GetAttribute("InCombat") ~= inCombat then
		player:SetAttribute("InCombat", inCombat)
	end
	if not inCombat then
		return
	end

	local st = state[player]
	if not st then
		st = { Next = {} }
		state[player] = st
	end
	if not st.Focus or not st.Focus.Alive then
		st.Focus = near[1].Monster
	end

	local damageMult = Boosts.Damage(player, data)
	for slot, entry in DragonService.GetTeam(player) do
		local target = st.Focus
		if not target or not target.Alive then
			local fresh = MonsterService.Near(index, pos, Balance.CombatRadius)
			if #fresh == 0 then
				break
			end
			target = fresh[1].Monster
			st.Focus = target
		end
		if now >= (st.Next[entry.Uid] or 0) then
			local def = Dragons.Get(entry.Dragon.Id)
			-- Gli ibridi usano il migliore dei loro due elementi.
			local mult = Elements.Multiplier(def.Element, target.Def.Element)
			if def.Element2 then
				mult = math.max(mult, Elements.Multiplier(def.Element2, target.Def.Element))
			end
			local weather = Boosts.WeatherElement
			local weatherMult = if weather and (def.Element == weather or def.Element2 == weather) then Boosts.WeatherBoost else 1
			local damage = DragonService.Power(entry.Dragon) * mult * damageMult * weatherMult
			st.Next[entry.Uid] = now + Balance.AttackInterval * rng:NextNumber(0.85, 1.15)
			-- L'effetto dell'attacco solo a chi è abbastanza vicino da vederlo.
			local attackFx = Remotes.Event("AttackFx")
			for _, viewer in Players:GetPlayers() do
				local viewerRoot = viewer.Character and viewer.Character:FindFirstChild("HumanoidRootPart")
				if viewerRoot and (viewerRoot.Position - pos).Magnitude < 220 then
					attackFx:FireClient(viewer, player.UserId, slot, target.Model, def.Element, mult, damage)
				end
			end
			MonsterService.Damage(target, player, damage)
		end
	end
end

function CombatService.Start()
	MonsterService.Killed:Connect(onKilled)
	Players.PlayerRemoving:Connect(function(p)
		state[p] = nil
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			tick(player, now)
		end
	end)
end

CombatService.BestUnlocked = bestUnlocked

return CombatService
