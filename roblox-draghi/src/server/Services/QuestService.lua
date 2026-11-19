-- Missioni giornaliere: contano le azioni del giocatore e danno premi.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)

local QuestService = {}

local function today()
	return Quests.Day(os.time())
end

-- Se è un giorno nuovo, le missioni ripartono da zero.
local function current(data)
	local q = data.Quests
	local day = today()
	if q.Day ~= day then
		q.Day = day
		q.Progress = {}
		q.Claimed = {}
		q.AllClaimed = false
	end
	return q
end

-- Aggiunge `amount` alla statistica `stat` (es. "Kills").
function QuestService.Add(player, stat: string, amount: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local q = current(data)
	q.Progress[stat] = (q.Progress[stat] or 0) + amount
end

local function view(data)
	local q = current(data)
	local list = {}
	local allDone = true
	for i, quest in Quests.ForDay(q.Day) do
		local progress = math.min(quest.Goal, q.Progress[quest.Stat] or 0)
		list[i] = { Id = quest.Id, Text = quest.Text, Goal = quest.Goal, Progress = progress, Reward = quest.Reward, Claimed = q.Claimed[tostring(i)] == true }
		if not list[i].Claimed then
			allDone = false
		end
	end
	return { Quests = list, AllDone = allDone, AllClaimed = q.AllClaimed, AllReward = Quests.AllDoneReward, ResetIn = (q.Day + 1) * 86400 - os.time() }
end

function QuestService.Start()
	Remotes.Func("GetQuests").OnServerInvoke = function(player)
		local data = DataService.Get(player)
		return data and view(data)
	end

	Remotes.Func("ClaimQuest").OnServerInvoke = function(player, index)
		local data = DataService.Get(player)
		if not data then
			return { Ok = false }
		end
		local RewardService = require(script.Parent.RewardService)
		local q = current(data)
		if index == "all" then
			local v = view(data)
			if not v.AllDone or q.AllClaimed then
				return { Ok = false, Error = "Finish all quests first" }
			end
			q.AllClaimed = true
			local text = RewardService.Give(player, data, Quests.AllDoneReward)
			return { Ok = true, Text = text, View = view(data) }
		end
		local quest = type(index) == "number" and Quests.ForDay(q.Day)[index]
		if not quest then
			return { Ok = false, Error = "Unknown quest" }
		end
		if q.Claimed[tostring(index)] then
			return { Ok = false, Error = "Already claimed" }
		end
		if (q.Progress[quest.Stat] or 0) < quest.Goal then
			return { Ok = false, Error = "Not finished yet" }
		end
		q.Claimed[tostring(index)] = true
		local text = RewardService.Give(player, data, quest.Reward)
		return { Ok = true, Text = text, View = view(data) }
	end
end

return QuestService
