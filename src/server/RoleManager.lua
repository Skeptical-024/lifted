local RoleManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage:WaitForChild("Types"))

function RoleManager.AssignRoles(players, lastGuardianUserId)
	local shuffled = table.clone(players)
	for i = #shuffled, 2, -1 do
		local j = math.random(1, i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	local rolesByPlayer = {}
	local guardian = shuffled[1]
	if #shuffled > 1 and lastGuardianUserId then
		for _, candidate in ipairs(shuffled) do
			if candidate.UserId ~= lastGuardianUserId then
				guardian = candidate
				break
			end
		end
	end
	rolesByPlayer[guardian] = Types.PlayerRole.Guardian

	for i = 2, #shuffled do
		rolesByPlayer[shuffled[i]] = Types.PlayerRole.Thief
	end

	return rolesByPlayer, guardian
end

return RoleManager
