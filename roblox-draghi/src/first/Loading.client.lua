-- Schermata di caricamento: compare subito, mostra l'immagine del gioco quando è pronta
-- e sparisce con una dissolvenza quando il mondo e il personaggio sono caricati.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "Loading"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local back = Instance.new("Frame")
back.Size = UDim2.fromScale(1, 1)
back.BackgroundColor3 = Color3.fromRGB(14, 20, 38)
back.Parent = gui
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new(Color3.fromRGB(60, 90, 170), Color3.fromRGB(14, 20, 38))
gradient.Parent = back

local banner = Instance.new("ImageLabel")
banner.BackgroundTransparency = 1
banner.Size = UDim2.fromScale(1, 1)
banner.ScaleType = Enum.ScaleType.Crop
banner.ImageTransparency = 1
banner.Parent = back

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 0.45
shade.Parent = back

local function text(props)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextScaled = true
	for k, v in props do
		t[k] = v
	end
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = Color3.fromRGB(15, 18, 30)
	s.Parent = t
	t.Parent = back
	return t
end

text({ Text = "DRAGON ELEMENTS", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(0.8, 0.14) })
text({ Text = "SIMULATOR", TextColor3 = Color3.fromRGB(255, 200, 61), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.5, 0.08) })
local status = text({ Text = "Loading the islands...", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.82), Size = UDim2.fromScale(0.6, 0.045) })

local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.88)
barBack.Size = UDim2.fromScale(0.4, 0.02)
barBack.BackgroundColor3 = Color3.fromRGB(20, 26, 44)
barBack.Parent = back
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(255, 200, 61)
fill.Parent = barBack
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local function showBanner()
	local raw = workspace:GetAttribute("ArtImages")
	if not raw then
		return
	end
	local ok, images = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and images.banner then
		banner.Image = images.banner
		TweenService:Create(banner, TweenInfo.new(0.8), { ImageTransparency = 0 }):Play()
	end
end
workspace:GetAttributeChangedSignal("ArtImages"):Connect(showBanner)
showBanner()

local start = os.clock()
TweenService:Create(fill, TweenInfo.new(2.5, Enum.EasingStyle.Quad), { Size = UDim2.fromScale(0.85, 1) }):Play()

if not game:IsLoaded() then
	game.Loaded:Wait()
end
status.Text = "Waking up your dragons..."
local character = player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart", 15)
workspace:WaitForChild("World", 15)
while os.clock() - start < 3 do
	task.wait(0.1)
end

TweenService:Create(fill, TweenInfo.new(0.3), { Size = UDim2.fromScale(1, 1) }):Play()
task.wait(0.35)
for _, d in back:GetDescendants() do
	if d:IsA("TextLabel") then
		TweenService:Create(d, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	elseif d:IsA("UIStroke") then
		TweenService:Create(d, TweenInfo.new(0.5), { Transparency = 1 }):Play()
	elseif d:IsA("ImageLabel") then
		TweenService:Create(d, TweenInfo.new(0.5), { ImageTransparency = 1 }):Play()
	elseif d:IsA("Frame") then
		TweenService:Create(d, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	end
end
TweenService:Create(back, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
task.wait(0.55)
gui:Destroy()
