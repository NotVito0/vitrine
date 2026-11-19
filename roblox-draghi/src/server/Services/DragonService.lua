-- Inventario dei draghi: aggiungere, equipaggiare, livelli e forza.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Balance = require(Shared.Config.Balance)
local Dragons = require(Shared.Config.Dragons)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PassService = require(script.Parent.PassService)

local DragonService = {}

function DragonService.Power(dragon): number
	local def = Dragons.Get(dragon.Id)
	if not def then
		return 0
	end
	local shiny = if dragon.Shiny then Balance.ShinyMult else 1
	-- Gli ibridi del nido hanno una forza base propria (dai genitori), salvata in Base.
	local variant = Dragons.Variants[dragon.Variant or 1] or Dragons.Variants[1]
	return (dragon.Base or def.Power) * shiny * variant.Mult * Balance.LevelMult(dragon.Level or 1)
end

function DragonService.TeamSize(player): number
	local data = DataService.Get(player)
	local bonus = if data then data.BonusTeamSlots + (data.RebirthUpgrades.Slots or 0) else 0
	return Balance.BaseTeamSize + bonus + PassService.Value(player, "TeamSlots", 0)
end

function DragonService.InventoryMax(player): number
	return Balance.MaxInventory + PassService.Value(player, "Storage", 0)
end

function DragonService.Count(data): number
	local n = 0
	for _ in data.Dragons do
		n += 1
	end
	return n
end

-- La squadra attuale: lista di { Uid, Dragon }, al massimo TeamSize.
function DragonService.GetTeam(player)
	local data = DataService.Get(player)
	local team = {}
	if not data then
		return team
	end
	local size = DragonService.TeamSize(player)
	for _, uid in data.Equipped do
		local d = data.Dragons[uid]
		if d then
			table.insert(team, { Uid = uid, Dragon = d })
			if #team >= size then
				break
			end
		end
	end
	return team
end

function DragonService.EquipBest(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local uids = {}
	for uid in data.Dragons do
		table.insert(uids, uid)
	end
	table.sort(uids, function(a, b)
		return DragonService.Power(data.Dragons[a]) > DragonService.Power(data.Dragons[b])
	end)
	local size = DragonService.TeamSize(player)
	data.Equipped = {}
	for i = 1, math.min(size, #uids) do
		data.Equipped[i] = uids[i]
	end
	DataService.MarkDirty(player, true)
end

-- Aggiunge un drago. opts: { Shiny, Serial, Force (ignora inventario pieno) }
-- Ritorna uid, drago, isNew (prima volta che lo trovi) — oppure nil, motivo.
function DragonService.Add(player, dragonId: string, opts)
	opts = opts or {}
	local data = DataService.Get(player)
	if not data or not Dragons.Get(dragonId) then
		return nil, "invalid"
	end
	if not opts.Force and DragonService.Count(data) >= DragonService.InventoryMax(player) then
		return nil, "full"
	end
	local uid = tostring(data.NextUid)
	data.NextUid += 1
	local dragon = { Id = dragonId, Level = 1, Xp = 0, Shiny = opts.Shiny == true, Serial = opts.Serial, Base = opts.Base, Variant = opts.Variant }
	data.Dragons[uid] = dragon
	local isNew = not data.Discovered[dragonId]
	data.Discovered[dragonId] = true
	if opts.SkipEquip ~= true and data.Settings.AutoEquip then
		DragonService.EquipBest(player)
	end
	DataService.MarkDirty(player, true)
	return uid, dragon, isNew
end

-- Aggiunge esperienza. Ritorna true se il drago è salito di livello.
function DragonService.AddXp(dragon, amount: number): boolean
	if dragon.Level >= Balance.MaxLevel then
		return false
	end
	dragon.Xp += amount
	local leveled = false
	while dragon.Level < Balance.MaxLevel and dragon.Xp >= Balance.XpToNext(dragon.Level) do
		dragon.Xp -= Balance.XpToNext(dragon.Level)
		dragon.Level += 1
		leveled = true
	end
	if dragon.Level >= Balance.MaxLevel then
		dragon.Xp = 0
	end
	return leveled
end

function DragonService.Start()
	Remotes.Func("Equip").OnServerInvoke = function(player, uid, on)
		local data = DataService.Get(player)
		if not data or type(uid) ~= "string" or not data.Dragons[uid] then
			return false, "Unknown dragon"
		end
		local index = table.find(data.Equipped, uid)
		if on then
			if index then
				return true
			end
			if #data.Equipped >= DragonService.TeamSize(player) then
				return false, "Your team is full"
			end
			table.insert(data.Equipped, uid)
		elseif index then
			table.remove(data.Equipped, index)
		end
		data.Settings.AutoEquip = false
		DataService.MarkDirty(player, true)
		return true
	end

	-- Evoluzione: 5 draghi uguali (stessa specie, stesso grado, stessa brillantezza) diventano 1 del grado dopo.
	-- Si consumano prima quelli fuori squadra. Il nuovo drago tiene il livello più alto dei cinque.
	Remotes.Func("Evolve").OnServerInvoke = function(player, uid)
		local data = DataService.Get(player)
		local chosen = data and type(uid) == "string" and data.Dragons[uid]
		if not chosen then
			return false, "Unknown dragon"
		end
		local variant = chosen.Variant or 1
		if variant >= #Dragons.Variants then
			return false, "Already at the highest grade"
		end
		if chosen.Serial then
			return false, "Numbered limited dragons can't evolve"
		end
		local same = {}
		for otherUid, d in data.Dragons do
			if d.Id == chosen.Id and (d.Variant or 1) == variant and d.Shiny == chosen.Shiny and not d.Serial then
				table.insert(same, otherUid)
			end
		end
		if #same < Dragons.EvolveCost then
			return false, "You need " .. Dragons.EvolveCost .. " of them (you have " .. #same .. ")"
		end
		table.sort(same, function(a, b)
			local ea, eb = table.find(data.Equipped, a) ~= nil, table.find(data.Equipped, b) ~= nil
			if ea ~= eb then
				return not ea
			end
			return data.Dragons[a].Level < data.Dragons[b].Level
		end)
		local level, base = 1, nil
		for i = 1, Dragons.EvolveCost do
			local d = data.Dragons[same[i]]
			level = math.max(level, d.Level)
			if d.Base then
				base = math.max(base or 0, d.Base)
			end
			local index = table.find(data.Equipped, same[i])
			if index then
				table.remove(data.Equipped, index)
			end
			data.Dragons[same[i]] = nil
		end
		local newUid, dragon = DragonService.Add(player, chosen.Id, { Force = true, Shiny = chosen.Shiny, Base = base, Variant = variant + 1, SkipEquip = true })
		dragon.Level = level
		DragonService.EquipBest(player)
		DataService.MarkDirty(player, true)
		return true, { Id = chosen.Id, Shiny = chosen.Shiny, Variant = variant + 1, Uid = newUid }
	end

	Remotes.Func("EquipBest").OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then
			return false
		end
		data.Settings.AutoEquip = true
		DragonService.EquipBest(player)
		return true
	end

	Remotes.Func("DeleteDragon").OnServerInvoke = function(player, uid)
		local data = DataService.Get(player)
		if not data or type(uid) ~= "string" or not data.Dragons[uid] then
			return false, "Unknown dragon"
		end
		if DragonService.Count(data) <= 1 then
			return false, "You need at least one dragon"
		end
		local index = table.find(data.Equipped, uid)
		if index then
			table.remove(data.Equipped, index)
		end
		data.Dragons[uid] = nil
		if data.Settings.AutoEquip then
			DragonService.EquipBest(player)
		end
		DataService.MarkDirty(player, true)
		return true
	end

	-- Quando cambiano i pass (es. Team Slots) la squadra si aggiorna.
	PassService.Changed:Connect(function(player)
		local data = DataService.Get(player)
		if data and data.Settings.AutoEquip then
			DragonService.EquipBest(player)
		end
		DataService.MarkDirty(player, true)
	end)
end

return DragonService
