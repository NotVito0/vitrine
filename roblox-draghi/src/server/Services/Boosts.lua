-- Pozioni a tempo e moltiplicatori finali (pass + pozioni + rinascite + VIP + eventi).
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Balance = require(Shared.Config.Balance)
local PassService = require(script.Parent.PassService)

local Boosts = {}

-- Moltiplicatori globali per gli eventi (weekend x2, admin abuse...). Li cambia il sistema eventi.
Boosts.Global = { Coins = 1, Damage = 1, Training = 1, Luck = 1 }

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

function Boosts.Coins(player, data): number
	local vip = if PassService.Has(player, "VIP") then 1 + Balance.VIPCoinBonus else 1
	return PassService.Value(player, "Coins", 1)
		* Boosts.Active(data, "Coins")
		* (1 + data.Rebirths * Balance.RebirthBonus)
		* vip
		* Boosts.Global.Coins
end

function Boosts.Damage(player, data): number
	return PassService.Value(player, "Damage", 1) * Boosts.Active(data, "Damage") * Boosts.Global.Damage
end

function Boosts.Training(player, data): number
	return PassService.Value(player, "Training", 1) * Boosts.Active(data, "Training") * Boosts.Global.Training
end

function Boosts.Luck(player, data): number
	return PassService.Value(player, "Luck", 1) * Boosts.Active(data, "Luck") * Boosts.Global.Luck
end

return Boosts
