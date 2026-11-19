-- Pozioni a tempo e moltiplicatori finali (pass + pozioni + rinascite + VIP + eventi).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Balance = require(Shared.Config.Balance)
local RebirthShop = require(Shared.Config.RebirthShop)
local PassService = require(script.Parent.PassService)

local Boosts = {}

-- Moltiplicatori globali per gli eventi (weekend x2, admin abuse...). Li cambia il sistema eventi.
Boosts.Global = { Coins = 1, Damage = 1, Training = 1, Luck = 1, Shiny = 1 }

-- Impostati da WeatherService ed EventService.
Boosts.WeatherElement = nil -- elemento rafforzato dal meteo attuale
Boosts.WeatherBoost = 1.25
Boosts.EventDrop = nil -- { Dragon, Chance } durante un evento stagionale

function Boosts.Add(data, name: string, seconds: number, mult: number)
	local now = os.time()
	local current = data.Boosts[name]
	if current and current.Expires > now and current.Mult >= mult then
		current.Expires += seconds
	else
		data.Boosts[name] = { Expires = now + seconds, Mult = mult }
	end
end

function Boosts.Active(data, name: string): number
	local b = data.Boosts[name]
	if b and b.Expires > os.time() then
		return b.Mult
	end
	return 1
end

-- Bonus permanenti comprati con i gettoni della rinascita.
function Boosts.Rebirth(data, id: string): number
	local item = RebirthShop.Get(id)
	local level = data.RebirthUpgrades and data.RebirthUpgrades[id] or 0
	return 1 + level * item.Per
end

-- Bonus social: +10% per ogni amico nello stesso server (massimo 3), e +10% per Roblox Premium.
-- L'attributo FriendsHere lo aggiorna SyncService ogni 30 secondi.
function Boosts.Social(player): number
	local friends = math.min(3, player:GetAttribute("FriendsHere") or 0)
	local premium = if player.MembershipType == Enum.MembershipType.Premium then 0.1 else 0
	return 1 + friends * 0.1 + premium
end

function Boosts.Coins(player, data): number
	local vip = if PassService.Has(player, "VIP") then 1 + Balance.VIPCoinBonus else 1
	return PassService.Value(player, "Coins", 1)
		* Boosts.Active(data, "Coins")
		* (1 + data.Rebirths * Balance.RebirthBonus)
		* vip
		* Boosts.Social(player)
		* Boosts.Rebirth(data, "Coins")
		* Boosts.Active(data, "Magnet")
		* Boosts.Global.Coins
end

function Boosts.Damage(player, data): number
	return PassService.Value(player, "Damage", 1) * Boosts.Active(data, "Damage") * Boosts.Rebirth(data, "Damage") * Boosts.Global.Damage
end

function Boosts.Training(player, data): number
	return PassService.Value(player, "Training", 1) * Boosts.Active(data, "Training") * Boosts.Rebirth(data, "Training") * Boosts.Global.Training
end

function Boosts.Luck(player, data): number
	return PassService.Value(player, "Luck", 1) * Boosts.Active(data, "Luck") * Boosts.Rebirth(data, "Luck") * Boosts.Global.Luck
end

return Boosts
