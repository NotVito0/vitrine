-- Tutti i canali tra server e client. Il server li crea, il client li aspetta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = { "DataSync", "AttackFx", "Reward", "Notify", "LevelUp", "Offer" }
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

function Remotes.Func(name: string): RemoteFunction
	return folder:WaitForChild(name)
end

return Remotes
