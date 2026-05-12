local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIStateController = {}

local state = {
	roundState = "waiting",
	playerRole = nil,
	timeRemaining = 0,
	objectives = {},
	vaultState = "locked",
	idolState = "vault",
	idolCarrierUserId = nil,
	extractState = nil,
	cageState = nil,
	guardianAbilityState = nil,
	lastAlert = nil,
}

local keyCallbacks = {}
local anyCallbacks = {}

local function shallowCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

local function fireKeyCallbacks(key, newValue, oldValue)
	local list = keyCallbacks[key]
	if not list then
		return
	end
	for _, cb in ipairs(list) do
		local ok, err = pcall(cb, newValue, oldValue)
		if not ok then
			warn("[UIStateController] OnChanged callback error for key '" .. tostring(key) .. "': " .. tostring(err))
		end
	end
end

local function fireAnyCallbacks(key, newValue, oldValue)
	for _, cb in ipairs(anyCallbacks) do
		local ok, err = pcall(cb, key, newValue, oldValue)
		if not ok then
			warn("[UIStateController] OnAnyChanged callback error: " .. tostring(err))
		end
	end
end

function UIStateController.GetState()
	return shallowCopy(state)
end

function UIStateController.Get(key)
	return state[key]
end

function UIStateController.Set(key, value)
	local oldValue = state[key]
	state[key] = value
	fireKeyCallbacks(key, value, oldValue)
	fireAnyCallbacks(key, value, oldValue)
end

function UIStateController.OnChanged(key, callback)
	if type(callback) ~= "function" then
		return
	end
	if not keyCallbacks[key] then
		keyCallbacks[key] = {}
	end
	table.insert(keyCallbacks[key], callback)
end

function UIStateController.OnAnyChanged(callback)
	if type(callback) ~= "function" then
		return
	end
	table.insert(anyCallbacks, callback)
end

local function updateObjective(id, completed, progress)
	if id == nil then
		return
	end
	local objectiveId = tostring(id)
	local objectives = state.objectives
	local normalizedProgress = tonumber(progress)
	if normalizedProgress then
		normalizedProgress = math.clamp(normalizedProgress, 0, 1)
	end
	for i, objective in ipairs(objectives) do
		if objective.id == objectiveId then
			local newObjectives = shallowCopy(objectives)
			newObjectives[i] = {
				id = objectiveId,
				completed = completed == true,
				progress = normalizedProgress ~= nil and normalizedProgress or objective.progress or ((completed == true) and 1 or 0),
			}
			UIStateController.Set("objectives", newObjectives)
			return
		end
	end
	local newObjectives = shallowCopy(objectives)
	table.insert(newObjectives, {
		id = objectiveId,
		completed = completed == true,
		progress = normalizedProgress ~= nil and normalizedProgress or ((completed == true) and 1 or 0),
	})
	UIStateController.Set("objectives", newObjectives)
end

local function connectRemote(remoteName, handler)
	local remote = ReplicatedStorage:FindFirstChild(remoteName)
	if not remote then
		return
	end
	if remote:IsA("RemoteEvent") then
		remote.OnClientEvent:Connect(handler)
	elseif remote:IsA("BindableEvent") then
		remote.Event:Connect(handler)
	end
end

connectRemote("PlayClicked", function()
	UIStateController.Set("lastAlert", "play_clicked")
end)

connectRemote("RoleAssigned", function(role)
	local mapped = nil
	if type(role) == "string" then
		local lower = string.lower(role)
		if lower == "thief" or lower == "guardian" then
			mapped = lower
		end
	end
	UIStateController.Set("playerRole", mapped)
end)

connectRemote("BrazierLit", function(id)
	updateObjective(id or "brazier", true)
	UIStateController.Set("lastAlert", "brazier_lit")
end)

connectRemote("BrazierExtinguished", function(id)
	updateObjective(id or "brazier", false)
	UIStateController.Set("lastAlert", "brazier_extinguished")
end)

connectRemote("PlayerCaught", function(...)
	UIStateController.Set("cageState", "caged")
	UIStateController.Set("lastAlert", "player_caught")
end)

connectRemote("RoundStarted", function(...)
	UIStateController.Set("roundState", "active")
	UIStateController.Set("objectives", {})
	UIStateController.Set("vaultState", "locked")
	UIStateController.Set("idolState", "vault")
	UIStateController.Set("idolCarrierUserId", nil)
	UIStateController.Set("extractState", nil)
	UIStateController.Set("cageState", nil)
	UIStateController.Set("guardianAbilityState", nil)
	UIStateController.Set("lastAlert", nil)
end)

connectRemote("RoundEnded", function(...)
	UIStateController.Set("roundState", "ended")
end)

connectRemote("TimerUpdated", function(timeRemaining)
	UIStateController.Set("timeRemaining", tonumber(timeRemaining) or 0)
end)

connectRemote("ObjectiveProgress", function(id, progress)
	local p = tonumber(progress) or 0
	updateObjective(id, p >= 1, p)
end)

connectRemote("ObjectiveCompleted", function(id)
	updateObjective(id, true, 1)
end)

connectRemote("VaultOpened", function(...)
	UIStateController.Set("vaultState", "open")
end)

connectRemote("IdolPickedUp", function(userId)
	UIStateController.Set("idolState", "carried")
	UIStateController.Set("idolCarrierUserId", tonumber(userId))
end)

connectRemote("IdolDropped", function(...)
	UIStateController.Set("idolState", "dropped")
end)

connectRemote("IdolCarrierChanged", function(userId)
	UIStateController.Set("idolCarrierUserId", tonumber(userId))
end)

connectRemote("ExtractStarted", function(...)
	UIStateController.Set("extractState", "active")
end)

connectRemote("ExtractCanceled", function(...)
	UIStateController.Set("extractState", nil)
end)

connectRemote("ExtractCompleted", function(...)
	UIStateController.Set("extractState", "completed")
end)

connectRemote("ThiefCaught", function(...)
	UIStateController.Set("cageState", "caged")
end)

connectRemote("ThiefRescued", function(...)
	UIStateController.Set("cageState", "rescued")
end)

connectRemote("GuardianAbilityState", function(abilityState)
	UIStateController.Set("guardianAbilityState", abilityState)
end)

return UIStateController
