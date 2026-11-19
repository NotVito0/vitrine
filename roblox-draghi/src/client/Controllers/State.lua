-- Lo stato del giocatore ricevuto dal server. Gli altri controller ascoltano State.Changed.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local State = {
	Data = nil,
	Ready = false,
}

local changed = Instance.new("BindableEvent")
State.Changed = changed.Event -- (data, fullUpdate)

Remotes.Event("DataSync").OnClientEvent:Connect(function(snapshot)
	local full = snapshot.Dragons ~= nil
	if not State.Data then
		State.Data = snapshot
	else
		for k, v in snapshot do
			State.Data[k] = v
		end
	end
	State.Ready = State.Data.Dragons ~= nil
	if State.Ready then
		changed:Fire(State.Data, full)
	end
end)

function State.Wait()
	while not State.Ready do
		task.wait(0.1)
	end
	return State.Data
end

return State
