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

	-- Assign Thief to every player who is NOT the chosen guardian.
	-- Do NOT use index-based loop: if guardian is not shuffled[1], index-based
	-- would overwrite the guardian slot as Thief and leave shuffled[1] unassigned.
	for _, player in ipairs(shuffled) do
		if player ~= guardian then
			rolesByPlayer[player] = Types.PlayerRole.Thief
		end
	end

	return rolesByPlayer, guardian
end

return RoleManager
