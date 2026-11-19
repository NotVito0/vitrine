-- Converte gli ID delle Decal caricate (Config/Art.lua) negli ID delle immagini vere,
-- che è quello che serve alle ImageLabel, e li passa ai client con l'attributo "ArtImages".
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Art = require(Shared.Config.Art)

local ArtService = {}

function ArtService.Start()
	task.spawn(function()
		local images = {}
		for name, id in Art.Decals do
			local url = "rbxassetid://" .. tostring(id)
			local ok, model = pcall(InsertService.LoadAsset, InsertService, id)
			if ok and model then
				local decal = model:FindFirstChildWhichIsA("Decal", true)
				if decal and decal.Texture ~= "" then
					url = decal.Texture
				end
				model:Destroy()
			end
			images[name] = url
		end
		workspace:SetAttribute("ArtImages", HttpService:JSONEncode(images))
	end)
end

return ArtService
