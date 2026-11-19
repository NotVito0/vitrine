-- Abilità dei draghi: un pulsante ciascuna, con tempo di ricarica.
-- Damage = quante volte la forza totale della squadra. Radius = distanza dal giocatore.
-- Unlock = cristalli per sbloccarla (0 = gratis dall'inizio).
local Abilities = {}

Abilities.List = {
	{ Id = "FireBreath", Name = "Fire Breath", Icon = "🔥", Key = Enum.KeyCode.One, Cooldown = 8, Radius = 20, Damage = 6, Unlock = 0, Color = Color3.fromRGB(255, 110, 40), Description = "Burns every monster close to you" },
	{ Id = "TidalWave", Name = "Tidal Wave", Icon = "🌊", Key = Enum.KeyCode.Two, Cooldown = 12, Radius = 28, Damage = 10, Unlock = 50, Color = Color3.fromRGB(60, 160, 255), Description = "A big wave around you" },
	{ Id = "Frenzy", Name = "Frenzy", Icon = "💢", Key = Enum.KeyCode.Three, Cooldown = 30, Duration = 8, Unlock = 80, Color = Color3.fromRGB(255, 70, 90), Description = "Your dragons attack twice as fast for 8 s" },
	{ Id = "ThunderStrike", Name = "Thunder Strike", Icon = "⚡", Key = Enum.KeyCode.Four, Cooldown = 15, Radius = 40, Damage = 14, MaxTargets = 6, Unlock = 120, Color = Color3.fromRGB(255, 230, 70), Description = "Lightning hits up to 6 monsters" },
	{ Id = "CoinMagnet", Name = "Coin Magnet", Icon = "🧲", Key = Enum.KeyCode.Five, Cooldown = 45, Duration = 10, Unlock = 150, Color = Color3.fromRGB(255, 200, 60), Description = "Double coins for 10 s" },
	{ Id = "MeteorCall", Name = "Meteor Call", Icon = "☄️", Key = Enum.KeyCode.Six, Cooldown = 60, Radius = 35, Damage = 30, Unlock = 300, Color = Color3.fromRGB(200, 90, 255), Description = "A meteor crashes on all monsters around you" },
}

function Abilities.Get(id: string)
	for _, a in Abilities.List do
		if a.Id == id then
			return a
		end
	end
	return nil
end

return Abilities
