-- Statistiche per il pannello creatore di Roblox (Analytics):
-- - funnel dei primi passi (dove smettono di giocare i nuovi giocatori);
-- - dove si spendono monete e cristalli;
-- - acquisti in Robux per prodotto.
-- Ogni chiamata è protetta: se il servizio non risponde, il gioco continua.
local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

Analytics.Funnel = { "Joined", "FirstKill", "FirstEgg", "SecondIsland", "FirstBreed", "FirstRebirth" }

-- Registra un passo del funnel una sola volta per account.
function Analytics.Step(player, data, name: string)
	if not data then
		return
	end
	data.Funnel = data.Funnel or {}
	if data.Funnel[name] then
		return
	end
	data.Funnel[name] = true
	local index = table.find(Analytics.Funnel, name)
	if index then
		pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, player, index, name)
	end
end

-- Spesa di valuta del gioco (currency = "Coins" o "Gems").
function Analytics.Spend(player, currency: string, amount: number, balance: number, sku: string)
	pcall(
		AnalyticsService.LogEconomyEvent,
		AnalyticsService,
		player,
		Enum.AnalyticsEconomyFlowType.Sink,
		currency,
		amount,
		balance,
		Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
		sku
	)
end

function Analytics.Custom(player, name: string, value: number?)
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, player, name, value or 1)
end

return Analytics
