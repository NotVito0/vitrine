-- Acquisti con Robux (Developer Products): pacchetti, pozioni, cristalli, monete e limitati.
-- ProcessReceipt è scritto per non dare mai due volte lo stesso acquisto e non perderne nessuno.
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Islands = require(Shared.Config.Islands)
local Products = require(Shared.Config.Products)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Analytics = require(script.Parent.Analytics)
local DragonService = require(script.Parent.DragonService)
local Boosts = require(script.Parent.Boosts)
local MarketService = require(script.Parent.MarketService)
local GiftService = require(script.Parent.GiftService)

local ShopService = {}

local globalStore
pcall(function()
	globalStore = DataStoreService:GetDataStore("Global_v1")
end)

local soldCache = {} -- chiave limitato -> venduti (aggiornato ogni 30 s)
local byId = {}
for key, info in Products.List do
	if info.Id ~= 0 then
		byId[info.Id] = key
	end
end

local function bestIsland(data)
	local best = Islands.List[1]
	for _, island in Islands.List do
		if data.Unlocked[island.Id] then
			best = island
		end
	end
	return best
end

-- Prende un numero di serie per un limitato. Ritorna il numero, o nil se finiti.
local function claimSerial(key, stock)
	if not globalStore then
		if RunService:IsStudio() then
			soldCache[key] = (soldCache[key] or 0) + 1
			return soldCache[key]
		end
		return nil, "store"
	end
	local serial
	local ok, err = pcall(function()
		globalStore:UpdateAsync("Limited_" .. key, function(sold)
			sold = sold or 0
			if sold >= stock then
				serial = nil
				return nil
			end
			serial = sold + 1
			return serial
		end)
	end)
	if not ok then
		warn("[Shop] limitato non disponibile:", err)
		return nil, "store"
	end
	if serial then
		soldCache[key] = serial
	end
	return serial, if serial then nil else "soldout"
end

-- Cosa fa ogni prodotto. Errore = l'acquisto verrà riprovato da Roblox più tardi.
local GRANT = {}

function GRANT.MiniPack(player, data)
	DragonService.Add(player, "StarterDrake", { Force = true })
	data.Coins += bestIsland(data).EggCost * 3
end

function GRANT.StarterPack(player, data)
	data.BonusTeamSlots += 1
	DragonService.Add(player, "CrownDrake", { Force = true })
end

function GRANT.ProPack(player, data)
	DragonService.Add(player, "PrismDrake", { Force = true })
	data.Gems += 150
	Boosts.Add(data, "Luck", 900, 2)
end

function GRANT.CrystalDrake(player, data, info)
	local serial, reason = claimSerial("CrystalDrake", info.Stock)
	if serial then
		DragonService.Add(player, "CrystalDrake", { Force = true, Serial = serial })
	elseif reason == "soldout" then
		-- Finiti mentre pagava: lo ripaghiamo in cristalli invece di lasciarlo senza niente.
		data.Gems += 400
		Remotes.Event("Notify"):FireClient(player, "Sold out! You received 400 gems instead.", "info")
	else
		error("limited store unavailable")
	end
end

function GRANT.MarketRestock(player, data)
	MarketService.Restock(data)
end

function GRANT.UnlockAllGifts(player)
	GiftService.UnlockAll(player)
end

local function grantGeneric(player, data, info)
	if info.Boost then
		Boosts.Add(data, info.Boost, info.Seconds, info.Mult)
	end
	if info.Gems then
		data.Gems += info.Gems
	end
	if info.EggsWorth then
		data.Coins += bestIsland(data).EggCost * info.EggsWorth
	end
end

local function grant(player, data, key)
	local info = Products.List[key]
	local fn = GRANT[key]
	if fn then
		fn(player, data, info)
	else
		grantGeneric(player, data, info)
	end
	if info.OneTime then
		data.OneTime[key] = true
	end
	Analytics.Custom(player, "Purchase_" .. key, info.Price)
	DataService.MarkDirty(player, true)
	Remotes.Event("Notify"):FireClient(player, "Thanks for your purchase: " .. info.Title .. "!", "success")
end

local function prunePurchases(data)
	local list = {}
	for id, t in data.Purchases do
		table.insert(list, { Id = id, T = t })
	end
	if #list <= 100 then
		return
	end
	table.sort(list, function(a, b)
		return a.T < b.T
	end)
	for i = 1, #list - 100 do
		data.Purchases[list[i].Id] = nil
	end
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService.Wait(player, 15)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if data.Purchases[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local key = byId[receipt.ProductId]
	if not key then
		warn("[Shop] prodotto sconosciuto", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(grant, player, data, key)
	if not ok then
		warn("[Shop] consegna fallita", key, err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.Purchases[receipt.PurchaseId] = os.time()
	prunePurchases(data)
	if not DataService.Save(player) then
		-- L'acquisto è registrato in memoria: se Roblox riprova, non verrà dato due volte.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function refreshStock()
	if not globalStore then
		return
	end
	for key, info in Products.List do
		if info.Stock then
			local ok, sold = pcall(globalStore.GetAsync, globalStore, "Limited_" .. key)
			if ok then
				soldCache[key] = sold or 0
			end
		end
	end
end

function ShopService.Start()
	MarketplaceService.ProcessReceipt = processReceipt

	task.spawn(function()
		while true do
			refreshStock()
			task.wait(30)
		end
	end)

	Remotes.Func("GetShopState").OnServerInvoke = function()
		local left = {}
		for key, info in Products.List do
			if info.Stock then
				left[key] = math.max(0, info.Stock - (soldCache[key] or 0))
			end
		end
		return { Left = left }
	end

	Remotes.Func("BuyProduct").OnServerInvoke = function(player, key)
		local data = DataService.Get(player)
		local info = type(key) == "string" and Products.List[key]
		if not data or not info then
			return false, "Unknown item"
		end
		if info.OneTime and data.OneTime[key] then
			return false, "Already bought"
		end
		if info.Stock and (soldCache[key] or 0) >= info.Stock then
			return false, "Sold out"
		end
		if info.Id == 0 then
			if RunService:IsStudio() then
				local ok, err = pcall(grant, player, data, key)
				return ok, if ok then "Studio test: no Robux spent" else tostring(err)
			end
			return false, "This item is not set up yet"
		end
		MarketplaceService:PromptProductPurchase(player, info.Id)
		return true
	end
end

return ShopService
