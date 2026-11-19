-- Tutta l'interfaccia, costruita dal codice: monete, stato (combattimento/allenamento),
-- pannello draghi, negozio, rinascita, schiusa delle uova, offerte e notifiche.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Dragons = require(Shared.Config.Dragons)
local Elements = require(Shared.Config.Elements)
local Passes = require(Shared.Config.Passes)
local Products = require(Shared.Config.Products)
local Balance = require(Shared.Config.Balance)
local DragonModel = require(Shared.DragonModel)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)

local UI = {}

local player = Players.LocalPlayer

local C = {
	Panel = Color3.fromRGB(22, 35, 58),
	Panel2 = Color3.fromRGB(32, 49, 78),
	Ink = Color3.fromRGB(244, 247, 255),
	Muted = Color3.fromRGB(157, 176, 207),
	Gold = Color3.fromRGB(255, 200, 61),
	Gem = Color3.fromRGB(192, 140, 255),
	Robux = Color3.fromRGB(47, 191, 113),
	Orange = Color3.fromRGB(255, 122, 61),
	Red = Color3.fromRGB(255, 90, 90),
	Blue = Color3.fromRGB(70, 160, 255),
}
local DISPLAY = Enum.Font.FredokaOne
local BODY = Enum.Font.GothamBold

local function new(class, props, children)
	local inst = Instance.new(class)
	for k, v in props or {} do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	inst.Parent = props and props.Parent
	return inst
end

local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 12) })
end

local function stroke(color, thickness)
	return new("UIStroke", { Color = color, Thickness = thickness or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function pad(px)
	return new("UIPadding", { PaddingTop = UDim.new(0, px), PaddingBottom = UDim.new(0, px), PaddingLeft = UDim.new(0, px), PaddingRight = UDim.new(0, px) })
end

local function label(props)
	local defaults = { BackgroundTransparency = 1, Font = BODY, TextColor3 = C.Ink, TextScaled = false, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left }
	for k, v in props do
		defaults[k] = v
	end
	return new("TextLabel", defaults)
end

local function button(props, color, onClick)
	local b = new("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = color,
		Font = DISPLAY,
		TextColor3 = C.Ink,
		TextSize = 18,
		Text = "",
	})
	for k, v in props do
		b[k] = v
	end
	corner(10).Parent = b
	new("UIStroke", { Color = color:Lerp(Color3.new(0, 0, 0), 0.45), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

local gui, hud, coinsLabel, gemsLabel, chips, statusLabel, toastHolder
local panels = {}
local openPanel = nil

-- Drago dentro una piccola finestra 3D (per inventario, schiusa, negozio).
local function viewport(parent, dragonId, shiny, size)
	local vp = new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = size or UDim2.fromScale(1, 1),
		Ambient = Color3.fromRGB(200, 200, 210),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1),
		Parent = parent,
	})
	local rig = DragonModel.Build(dragonId, shiny, 1)
	local parts, cframes = {}, {}
	DragonModel.Pose(rig, CFrame.Angles(0, math.rad(-30), 0), 0.25, parts, cframes)
	for i, p in parts do
		p.CFrame = cframes[i]
	end
	rig.Model.Parent = vp
	local cam = new("Camera", { FieldOfView = 40, Parent = vp })
	cam.CFrame = CFrame.lookAt(Vector3.new(-3.5, 2.6, -8.5), Vector3.new(0, 0.4, 0))
	vp.CurrentCamera = cam
	return vp
end

local function rarityColor(rarity)
	return (Dragons.Rarities[rarity] or Dragons.Rarities.Common).Color
end

---------------------------------------------------------------- Notifiche
function UI.Toast(text, kind)
	local color = if kind == "error" then C.Red elseif kind == "success" then C.Robux elseif kind == "level" then C.Blue else C.Panel2
	local t = new("TextLabel", {
		BackgroundColor3 = color,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = BODY,
		TextSize = 16,
		TextWrapped = true,
		TextColor3 = C.Ink,
		Text = text,
		Parent = toastHolder,
	}, { corner(10), pad(8) })
	task.delay(3.2, function()
		TweenService:Create(t, TweenInfo.new(0.3), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.3)
		t:Destroy()
	end)
	local list = toastHolder:GetChildren()
	local count = 0
	for _, c in list do
		if c:IsA("TextLabel") then
			count += 1
		end
	end
	if count > 4 then
		for _, c in list do
			if c:IsA("TextLabel") then
				c:Destroy()
				break
			end
		end
	end
end

function UI.Bump()
	local scale = coinsLabel:FindFirstChildOfClass("UIScale")
	scale.Scale = 1.18
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

---------------------------------------------------------------- Pannelli
local function makePanel(name, title)
	local frame = new("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.62, 0.72),
		BackgroundColor3 = C.Panel,
		Visible = false,
		Parent = gui,
	}, { corner(18), stroke(Color3.fromRGB(60, 80, 120), 2), new("UISizeConstraint", { MaxSize = Vector2.new(760, 560), MinSize = Vector2.new(320, 300) }) })
	label({ Text = title, Font = DISPLAY, TextSize = 28, Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -80, 0, 36), Parent = frame })
	button({ Text = "✕", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.fromOffset(38, 38) }, C.Red, function()
		UI.Close()
	end).Parent = frame
	local sub = label({ Name = "Sub", Text = "", TextColor3 = C.Muted, TextSize = 14, Position = UDim2.fromOffset(18, 46), Size = UDim2.new(1, -36, 0, 20), Parent = frame })
	local body = new("ScrollingFrame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 74),
		Size = UDim2.new(1, -24, 1, -86),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		BorderSizePixel = 0,
		Parent = frame,
	})
	panels[name] = { Frame = frame, Body = body, Sub = sub }
	return panels[name]
end

function UI.Close()
	if openPanel then
		panels[openPanel].Frame.Visible = false
	end
	openPanel = nil
end

local refreshers = {}
function UI.Open(name)
	if openPanel == name then
		UI.Close()
		return
	end
	UI.Close()
	openPanel = name
	panels[name].Frame.Visible = true
	if refreshers[name] then
		refreshers[name](true)
	end
end

---------------------------------------------------------------- Pannello draghi
local dragonCells = {}
local deleteArmed = nil

local function refreshDragons(force)
	local p = panels.Dragons
	local data = State.Data
	if not data or not p.Frame.Visible and not force then
		return
	end
	local uids = {}
	for uid in data.Dragons do
		table.insert(uids, uid)
	end
	table.sort(uids, function(a, b)
		return data.Dragons[a].Power > data.Dragons[b].Power
	end)
	p.Sub.Text = string.format("Team %d/%d · Dragons %d/%d · tap a dragon to add or remove it from your team", #data.Equipped, data.TeamSize, #uids, data.InventoryMax or Balance.MaxInventory)

	local alive = {}
	for order, uid in uids do
		alive[uid] = true
		local d = data.Dragons[uid]
		local def = Dragons.Get(d.Id)
		local cell = dragonCells[uid]
		if not cell then
			local frame = new("TextButton", { Text = "", AutoButtonColor = true, BackgroundColor3 = C.Panel2, Parent = p.Body }, { corner(12) })
			local st = stroke(rarityColor(def.Rarity), 2)
			st.Parent = frame
			viewport(frame, d.Id, d.Shiny, UDim2.new(1, 0, 0, 78))
			local name = label({ Text = def.Name .. (if d.Serial then " #" .. d.Serial else ""), Font = DISPLAY, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(4, 76), Size = UDim2.new(1, -8, 0, 30), Parent = frame })
			local info = label({ Text = "", TextSize = 12, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(4, 106), Size = UDim2.new(1, -8, 0, 16), Parent = frame })
			local xpBack = new("Frame", { BackgroundColor3 = Color3.fromRGB(12, 20, 34), Position = UDim2.new(0, 8, 1, -12), Size = UDim2.new(1, -16, 0, 5), Parent = frame }, { corner(3) })
			local xpFill = new("Frame", { BackgroundColor3 = C.Blue, Size = UDim2.fromScale(0, 1), Parent = xpBack }, { corner(3) })
			local badge = label({ Text = "TEAM", Font = DISPLAY, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 0, BackgroundColor3 = C.Gold, TextColor3 = Color3.fromRGB(60, 40, 0), Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(44, 18), Parent = frame }, nil)
			corner(6).Parent = badge
			local shinyTag = label({ Text = "✨", TextSize = 16, Position = UDim2.new(1, -52, 0, 4), Size = UDim2.fromOffset(20, 20), Visible = d.Shiny, Parent = frame })
			local del = button({ Text = "🗑", TextSize = 14, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(26, 22) }, Color3.fromRGB(70, 50, 70))
			del.Parent = frame
			del.Activated:Connect(function()
				if deleteArmed ~= uid then
					deleteArmed = uid
					del.Text = "?"
					UI.Toast("Tap 🗑 again to delete " .. def.Name, "info")
					task.delay(2.5, function()
						if deleteArmed == uid then
							deleteArmed = nil
							del.Text = "🗑"
						end
					end)
					return
				end
				deleteArmed = nil
				local ok, msg = Remotes.Func("DeleteDragon"):InvokeServer(uid)
				if not ok then
					UI.Toast(msg or "Could not delete", "error")
				end
			end)
			frame.Activated:Connect(function()
				local equipped = table.find(State.Data.Equipped, uid) ~= nil
				local ok, msg = Remotes.Func("Equip"):InvokeServer(uid, not equipped)
				if not ok and msg then
					UI.Toast(msg, "error")
				end
			end)
			cell = { Frame = frame, Info = info, XpFill = xpFill, Badge = badge, Name = name, Shiny = shinyTag }
			dragonCells[uid] = cell
		end
		cell.Frame.LayoutOrder = order
		cell.Info.Text = string.format("Lv %d · ⚔ %s", d.Level, Format.Number(d.Power))
		cell.XpFill.Size = UDim2.fromScale(if d.Level >= Balance.MaxLevel then 1 else math.clamp(d.Xp / math.max(1, d.Next), 0, 1), 1)
		cell.Badge.Visible = table.find(data.Equipped, uid) ~= nil
	end
	for uid, cell in dragonCells do
		if not alive[uid] then
			cell.Frame:Destroy()
			dragonCells[uid] = nil
		end
	end
end

local function buildDragonsPanel()
	local p = makePanel("Dragons", "🐉 Your Dragons")
	new("UIGridLayout", { CellSize = UDim2.fromOffset(112, 140), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = p.Body })
	local best = button({ Text = "Equip Best", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 12), Size = UDim2.fromOffset(120, 36) }, C.Orange, function()
		Remotes.Func("EquipBest"):InvokeServer()
	end)
	best.Parent = p.Frame
	refreshers.Dragons = refreshDragons
end

---------------------------------------------------------------- Negozio
local shopRows = {}
local shopState = { Left = {} }

local function shopSection(parent, title, order)
	label({ Text = title, Font = DISPLAY, TextSize = 20, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = order, Parent = parent })
end

local function shopRow(parent, order, icon, title, desc, hot)
	local row = new("Frame", { BackgroundColor3 = if hot then Color3.fromRGB(58, 35, 80) else C.Panel2, Size = UDim2.new(1, -6, 0, 70), LayoutOrder = order, Parent = parent }, { corner(12) })
	label({ Text = icon, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(0, 48, 1, 0), Parent = row })
	local t = label({ Text = title, Font = DISPLAY, TextSize = 18, Position = UDim2.fromOffset(62, 8), Size = UDim2.new(1, -230, 0, 22), Parent = row })
	local d = label({ Text = desc, TextSize = 13, TextColor3 = C.Muted, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(62, 32), Size = UDim2.new(1, -230, 0, 34), Parent = row })
	local b = button({ Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(150, 40), TextSize = 16 }, C.Robux)
	b.Parent = row
	return { Row = row, Title = t, Desc = d, Button = b }
end

local function buy(kind, a, b)
	local ok, msg
	if kind == "pass" then
		ok, msg = Remotes.Func("BuyPass"):InvokeServer(a, b)
	else
		ok, msg = Remotes.Func("BuyProduct"):InvokeServer(a)
	end
	if msg then
		UI.Toast(msg, if ok then "success" else "error")
	end
end

local function refreshShop()
	local data = State.Data
	if not data or not shopRows.built then
		return
	end
	for _, category in Passes.TierOrder do
		local tiers = Passes.Tiers[category]
		local row = shopRows["pass_" .. category]
		local tier = data.Passes.Tiers[category] or 0
		local field = tiers.Field
		local current = if tier > 0 then tiers[tier][field] else nil
		local nextTier = tiers[tier + 1]
		local currentText = if current then "Owned: " .. string.format(tiers.Describe, tostring(current)) else "Not owned yet"
		if nextTier then
			row.Desc.Text = currentText .. "  →  next: " .. string.format(tiers.Describe, tostring(nextTier[field]))
			row.Button.Text = "R$ " .. nextTier.Price
			row.Button.AutoButtonColor = true
			row.Button.BackgroundColor3 = C.Robux
		else
			row.Desc.Text = currentText .. " · maximum level"
			row.Button.Text = "MAX ✓"
			row.Button.AutoButtonColor = false
			row.Button.BackgroundColor3 = C.Panel
		end
		row.Title.Text = tiers.Title .. (if tier > 0 then "  Lv " .. tier .. "/" .. #tiers else "")
	end
	for _, name in Passes.SingleOrder do
		local row = shopRows["single_" .. name]
		local owned = data.Passes.Single[name]
		row.Button.Text = if owned then "Owned ✓" else "R$ " .. Passes.Single[name].Price
		row.Button.BackgroundColor3 = if owned then C.Panel else C.Robux
	end
	for _, key in Products.Order do
		local info = Products.List[key]
		local row = shopRows["product_" .. key]
		local owned = info.OneTime and data.OneTime[key]
		local left = shopState.Left[key]
		if owned then
			row.Button.Text = "Owned ✓"
			row.Button.BackgroundColor3 = C.Panel
		elseif left == 0 then
			row.Button.Text = "Sold out"
			row.Button.BackgroundColor3 = C.Panel
		else
			row.Button.Text = (if info.Was then "R$ " .. info.Price .. "  (" .. info.Was .. ")" else "R$ " .. info.Price)
			row.Button.BackgroundColor3 = C.Robux
		end
		if info.Stock then
			row.Desc.Text = info.Description .. (if left then "  ·  " .. left .. " left!" else "")
		end
	end
end

local function buildShopPanel()
	local p = makePanel("Shop", "🛒 Shop")
	p.Sub.Text = "Passes last forever. Each level unlocks the next one."
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = p.Body })
	local order = 0
	local function o()
		order += 1
		return order
	end
	-- Prima le offerte di benvenuto, perché sono quelle che si comprano di più.
	for _, section in Products.Sections do
		if section.Key == "Packs" or section.Key == "Limited" then
			shopSection(p.Body, section.Title, o())
			for _, key in Products.Order do
				local info = Products.List[key]
				if info.Section == section.Key then
					local row = shopRow(p.Body, o(), info.Icon, info.Title, info.Description, true)
					row.Button.Activated:Connect(function()
						buy("product", key)
					end)
					shopRows["product_" .. key] = row
				end
			end
		end
	end
	shopSection(p.Body, "Upgrades (forever)", o())
	for _, category in Passes.TierOrder do
		local tiers = Passes.Tiers[category]
		local row = shopRow(p.Body, o(), tiers.Icon, tiers.Title, "", false)
		row.Button.Activated:Connect(function()
			local tier = (State.Data.Passes.Tiers[category] or 0) + 1
			if tiers[tier] then
				buy("pass", category, tier)
			end
		end)
		shopRows["pass_" .. category] = row
	end
	for _, name in Passes.SingleOrder do
		local info = Passes.Single[name]
		local row = shopRow(p.Body, o(), info.Icon, info.Title, info.Description, false)
		row.Button.Activated:Connect(function()
			buy("pass", "Single", name)
		end)
		shopRows["single_" .. name] = row
	end
	for _, section in Products.Sections do
		if section.Key ~= "Packs" and section.Key ~= "Limited" then
			shopSection(p.Body, section.Title, o())
			for _, key in Products.Order do
				local info = Products.List[key]
				if info.Section == section.Key then
					local row = shopRow(p.Body, o(), info.Icon, info.Title, info.Description, info.Best)
					row.Button.Activated:Connect(function()
						buy("product", key)
					end)
					shopRows["product_" .. key] = row
				end
			end
		end
	end
	shopRows.built = true
	refreshers.Shop = function()
		task.spawn(function()
			local ok, result = pcall(function()
				return Remotes.Func("GetShopState"):InvokeServer()
			end)
			if ok and result then
				shopState = result
			end
			refreshShop()
		end)
		refreshShop()
	end
end

---------------------------------------------------------------- Rinascita
local function buildRebirthPanel()
	local p = makePanel("Rebirth", "♻️ Rebirth")
	p.Sub.Text = "Start the islands again, keep all your dragons, earn more coins forever."
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = p.Body })
	local info = label({ Text = "", TextSize = 18, TextWrapped = true, Size = UDim2.new(1, 0, 0, 110), LayoutOrder = 1, Parent = p.Body })
	local go = button({ Text = "Rebirth", Size = UDim2.new(1, 0, 0, 50), LayoutOrder = 2, TextSize = 22 }, C.Orange, function()
		local ok, msg = Remotes.Func("Rebirth"):InvokeServer()
		if ok then
			UI.Close()
			UI.Toast("♻️ Rebirth complete! Coins bonus increased.", "success")
		else
			UI.Toast(msg or "Not enough coins", "error")
		end
	end)
	go.Parent = p.Body
	refreshers.Rebirth = function()
		local data = State.Data
		if not data then
			return
		end
		local now = 1 + data.Rebirths * Balance.RebirthBonus
		local after = 1 + (data.Rebirths + 1) * Balance.RebirthBonus
		info.Text = string.format(
			"Rebirths: %d\nCoins bonus: x%.1f → x%.1f\nCost: %s coins (you have %s)\nYou keep every dragon, level and pass.",
			data.Rebirths,
			now,
			after,
			Format.Number(data.RebirthCost),
			Format.Number(data.Coins)
		)
	end
end

---------------------------------------------------------------- Schiusa
function UI.ShowHatch(results)
	local overlay = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = gui })
	local holder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.5), ZIndex = 21, Parent = overlay }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), Wraps = true }),
	})
	for _, r in results do
		local def = Dragons.Get(r.Id)
		local card = new("Frame", { BackgroundColor3 = C.Panel, Size = UDim2.fromOffset(170, 220), ZIndex = 22, Parent = holder }, { corner(16), stroke(rarityColor(def.Rarity), 3) })
		local scale = new("UIScale", { Scale = 0.2, Parent = card })
		TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		local vp = viewport(card, r.Id, r.Shiny, UDim2.new(1, 0, 0, 130))
		vp.ZIndex = 23
		label({ Text = def.Name, Font = DISPLAY, TextSize = 18, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(6, 128), Size = UDim2.new(1, -12, 0, 40), ZIndex = 23, Parent = card })
		label({ Text = def.Rarity:upper() .. (if r.Shiny then " · SHINY ✨" else ""), Font = DISPLAY, TextSize = 14, TextColor3 = rarityColor(def.Rarity), TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(6, 168), Size = UDim2.new(1, -12, 0, 20), ZIndex = 23, Parent = card })
		if r.New then
			local tag = label({ Text = "NEW!", Font = DISPLAY, TextSize = 14, TextColor3 = Color3.fromRGB(60, 40, 0), BackgroundTransparency = 0, BackgroundColor3 = C.Gold, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(52, 22), ZIndex = 24, Parent = card })
			corner(8).Parent = tag
		end
		local el = Elements.List[def.Element]
		label({ Text = el.Icon .. " " .. el.Name, TextSize = 13, TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(6, 190), Size = UDim2.new(1, -12, 0, 20), ZIndex = 23, Parent = card })
	end
	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		overlay:Destroy()
	end
	overlay.Activated:Connect(close)
	task.delay(3.5, close)
end

---------------------------------------------------------------- Offerte
function UI.NeedCoins(missing)
	local data = State.Data
	if data and not data.OneTime.MiniPack then
		UI.ShowOffer("MiniPack", "You need " .. Format.Number(missing or 0) .. " more coins. The Starter Drake is stronger than anything on the first islands, and you can't get it from eggs.")
	else
		UI.Toast("You need " .. Format.Number(missing or 0) .. " more coins", "error")
	end
end

function UI.ShowOffer(key, text)
	local info = Products.List[key]
	local overlay = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 30, Parent = gui })
	local card = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 380), BackgroundColor3 = C.Panel, ZIndex = 31, Parent = overlay }, { corner(20), stroke(C.Robux, 3) })
	local vp = viewport(card, "StarterDrake", false, UDim2.new(1, 0, 0, 160))
	vp.ZIndex = 32
	label({ Text = "OFFER JUST FOR YOU", Font = DISPLAY, TextSize = 14, TextColor3 = C.Robux, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 160), Size = UDim2.new(1, 0, 0, 20), ZIndex = 32, Parent = card })
	label({ Text = info.Title, Font = DISPLAY, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 180), Size = UDim2.new(1, 0, 0, 34), ZIndex = 32, Parent = card })
	label({ Text = text, TextSize = 14, TextColor3 = C.Muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(16, 216), Size = UDim2.new(1, -32, 0, 70), ZIndex = 32, Parent = card })
	local yes = button({ Text = "R$ " .. info.Price .. (if info.Was then "   (was " .. info.Was .. ")" else ""), Position = UDim2.new(0, 16, 1, -86), Size = UDim2.new(1, -32, 0, 42), ZIndex = 32, TextSize = 20 }, C.Robux, function()
		overlay:Destroy()
		buy("product", key)
	end)
	yes.Parent = card
	local no = button({ Text = "No thanks", Position = UDim2.new(0, 16, 1, -38), Size = UDim2.new(1, -32, 0, 30), ZIndex = 32, TextSize = 15 }, C.Panel2, function()
		overlay:Destroy()
	end)
	no.Parent = card
end

---------------------------------------------------------------- HUD
local function refreshHud(data)
	coinsLabel.Text = Format.Number(data.Coins)
	gemsLabel.Text = Format.Number(data.Gems)
	for _, c in chips:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local function chip(text)
		local l = label({ Text = text, TextSize = 13, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), BackgroundTransparency = 0.25, BackgroundColor3 = C.Panel, TextXAlignment = Enum.TextXAlignment.Center, Parent = chips })
		corner(12).Parent = l
		pad(4).Parent = l
	end
	for name, b in data.Boosts or {} do
		chip(string.format("%s x%s · %s", name, tostring(b.Mult), Format.Time(b.Left)))
	end
	if (data.Mults.Coins or 1) > 1 then
		chip("💰 Coins x" .. string.format("%.1f", data.Mults.Coins))
	end
end

local function refreshStatus()
	if player:GetAttribute("InCombat") then
		statusLabel.Text = "⚔️ COMBAT"
		statusLabel.BackgroundColor3 = C.Red
		statusLabel.Visible = true
	elseif player:GetAttribute("Training") then
		local xp = player:GetAttribute("TrainingXp") or 0
		statusLabel.Text = "🏋️ TRAINING  +" .. Format.Number(xp) .. " XP/s"
		statusLabel.BackgroundColor3 = C.Blue
		statusLabel.Visible = true
	else
		statusLabel.Visible = false
	end
end

local function buildHud()
	hud = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui })

	local wallet = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(220, 96), Parent = hud }, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function pill(icon, color, order)
		local f = new("Frame", { BackgroundColor3 = C.Panel, BackgroundTransparency = 0.1, Size = UDim2.fromOffset(190, 40), LayoutOrder = order, Parent = wallet }, { corner(20), stroke(color, 2) })
		label({ Text = icon, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(40, 40), Parent = f })
		local l = label({ Text = "0", Font = DISPLAY, TextSize = 22, Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -50, 1, 0), Parent = f })
		new("UIScale", { Parent = l })
		return l
	end
	coinsLabel = pill("🪙", C.Gold, 1)
	gemsLabel = pill("💎", C.Gem, 2)

	chips = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 112), Size = UDim2.fromOffset(300, 60), Parent = hud }, {
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	statusLabel = label({ Text = "", Font = DISPLAY, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 0.05, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(300, 40), Visible = false, Parent = hud })
	corner(20).Parent = statusLabel
	for _, attr in { "InCombat", "Training", "TrainingXp" } do
		player:GetAttributeChangedSignal(attr):Connect(refreshStatus)
	end

	local side = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.55, 0), Size = UDim2.fromOffset(80, 260), Parent = hud }, {
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function sideButton(text, color, order, panel)
		local b = button({ Text = text, TextSize = 15, TextWrapped = true, Size = UDim2.fromOffset(78, 70), LayoutOrder = order }, color, function()
			UI.Open(panel)
		end)
		b.Parent = side
	end
	sideButton("🐉\nDragons", C.Orange, 1, "Dragons")
	sideButton("🛒\nShop", C.Robux, 2, "Shop")
	sideButton("♻️\nRebirth", C.Blue, 3, "Rebirth")

	toastHolder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(360, 200), Parent = gui }, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
end

function UI.Start()
	gui = new("ScreenGui", { Name = "DragonUI", ResetOnSpawn = false, IgnoreGuiInset = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
	local uiScale = new("UIScale", { Parent = gui })
	local function rescale()
		local size = Workspace.CurrentCamera.ViewportSize
		uiScale.Scale = math.clamp(math.min(size.X / 1100, size.Y / 650), 0.62, 1.15)
	end
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	buildHud()
	buildDragonsPanel()
	buildShopPanel()
	buildRebirthPanel()

	State.Changed:Connect(function(data, full)
		refreshHud(data)
		if openPanel == "Dragons" and full then
			refreshDragons()
		elseif openPanel == "Shop" then
			refreshShop()
		elseif openPanel == "Rebirth" then
			refreshers.Rebirth()
		end
	end)
	if State.Data then
		refreshHud(State.Data)
	end

	Remotes.Event("Notify").OnClientEvent:Connect(function(text, kind)
		UI.Toast(text, kind)
	end)
	local lastLevel = 0
	Remotes.Event("LevelUp").OnClientEvent:Connect(function()
		if os.clock() - lastLevel > 4 then
			lastLevel = os.clock()
			UI.Toast("⬆️ Your dragons leveled up!", "level")
		end
	end)

	task.delay(2, function()
		UI.Toast("Walk near monsters: your dragons fight on their own!", "info")
	end)
end

return UI
