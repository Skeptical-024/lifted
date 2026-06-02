-- RemoteGuardService
-- Small server-side request throttle for client RemoteEvent spam.

local RemoteGuardService = {}

local lastAllowedAt = {}
local blockedCounts = {}

function RemoteGuardService.Allow(player, actionName, cooldownSeconds)
	if not player or not player.Parent then
		return false
	end
	if type(actionName) ~= "string" or actionName == "" then
		return false
	end

	local uid = player.UserId
	local now = os.clock()
	local cooldown = math.max(tonumber(cooldownSeconds) or 0, 0)
	lastAllowedAt[uid] = lastAllowedAt[uid] or {}

	local previous = lastAllowedAt[uid][actionName] or 0
	if now - previous < cooldown then
		blockedCounts[actionName] = (blockedCounts[actionName] or 0) + 1
		return false
	end

	lastAllowedAt[uid][actionName] = now
	return true
end

function RemoteGuardService.ClearPlayer(player)
	if player then
		lastAllowedAt[player.UserId] = nil
	end
end

function RemoteGuardService.Reset()
	lastAllowedAt = {}
	blockedCounts = {}
end

function RemoteGuardService.GetBlockedCounts()
	return table.clone(blockedCounts)
end

return RemoteGuardService
