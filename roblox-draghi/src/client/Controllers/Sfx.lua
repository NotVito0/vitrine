-- Suoni dell'interfaccia. Usano i suoni inclusi in Roblox; si possono sostituire
-- con suoni del Creator Store mettendo qui il loro "rbxassetid://...".
local SoundService = game:GetService("SoundService")

local Sfx = {}

local SOUNDS = {
	Click = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.25, Pitch = 1.4 },
	Coin = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.18, Pitch = 2 },
	Reveal = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.5, Pitch = 0.8 },
	Rare = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Pitch = 0.55 },
	Error = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.3, Pitch = 0.4 },
}

local cache = {}
local lastPlay = {}

function Sfx.Play(name: string)
	local info = SOUNDS[name]
	if not info then
		return
	end
	-- Evita di suonare lo stesso suono troppe volte di fila.
	local now = os.clock()
	if now - (lastPlay[name] or 0) < 0.05 then
		return
	end
	lastPlay[name] = now
	local sound = cache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.SoundId = info.Id
		sound.Volume = info.Volume
		sound.PlaybackSpeed = info.Pitch
		sound.Parent = SoundService
		cache[name] = sound
	end
	SoundService:PlayLocalSound(sound)
end

return Sfx
