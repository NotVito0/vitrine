-- Tutti i canali tra server e client. Il server li crea, il client li aspetta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = { "DataSync", "AttackFx", "Reward", "Notify", "LevelUp", "Offer", "HatchFx", "Announce", "AbilityFx" }
local FUNCTIONS = {
	"Hatch",
	"UnlockIsland",
	"Equip",
	"EquipBest",
	"DeleteDragon",
	"BuyPass",
	"BuyProduct",
	"Rebirth",
	"GetShopState",
	"GetMarket",
	"BuyMarket",
	"UsePotion",
	"GetGifts",
	"ClaimGift",
	"StartNest",
	"SkipNest",
	"RedeemCode",
	"GetDaily",
	"ClaimDaily",
	"BuyCosmetic",
	"EquipCosmetic",
	"UnlockAbility",
	"UseAbility",
	"BuyRebirthUpgrade",
	"TeleportToEgg",
	"GetQuests",
	"ClaimQuest",
}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in EVENTS do
		if not folder:FindFirstChild(name) then
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
	end
	for _, name in FUNCTIONS do
		if not folder:FindFirstChild(name) then
			local r = Instance.new("RemoteFunction")
			r.Name = name
			r.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local Remotes = {}

function Remotes.Event(name: string): RemoteEvent
	return folder:WaitForChild(name)
end

-- Limite di richieste per giocatore: chi ne manda più di LIMIT al secondo alla stessa funzione
-- (solo chi usa trucchi) viene ignorato. Un giocatore normale non ci arriva mai.
local LIMIT = 15
local counts = {}

local function allowed(player, name)
	local now = os.clock()
	local key = name
	local perPlayer = counts[player]
	if not perPlayer then
		perPlayer = {}
		counts[player] = perPlayer
		player.AncestryChanged:Connect(function(_, parent)
			if not parent then
				counts[player] = nil
			end
		end)
	end
	local entry = perPlayer[key]
	if not entry or now - entry.Start >= 1 then
		perPlayer[key] = { Start = now, Count = 1 }
		return true
	end
	entry.Count += 1
	return entry.Count <= LIMIT
end

function Remotes.Func(name: string)
	local remote = folder:WaitForChild(name)
	if not RunService:IsServer() then
		return remote
	end
	-- Sul server: impostare OnServerInvoke aggiunge da solo il limite di richieste.
	return setmetatable({}, {
		__newindex = function(_, key, fn)
			if key == "OnServerInvoke" then
				remote.OnServerInvoke = function(player, ...)
					if not allowed(player, name) then
						return nil
					end
					return fn(player, ...)
				end
			else
				remote[key] = fn
			end
		end,
		__index = remote,
	})
end

return Remotes
