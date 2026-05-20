local GuardianController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local PlayerStateService = require(script.Parent:WaitForChild("PlayerStateService"))

local function getHumanoid(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

function GuardianController.ResetPlayer(player)
	local _ = player
end

function GuardianController.TryCatch(guardianPlayer, targetPlayer, rolesByPlayer, roundActive)
	if not roundActive then
		return false, "round_inactive"
	end
	if rolesByPlayer[guardianPlayer] ~= "Guardian" then
		return false, "not_guardian"
	end
	if not Players:FindFirstChild(guardianPlayer.Name) or not Players:FindFirstChild(targetPlayer.Name) then
		return false, "player_missing"
	end

	local guardianRoot = getRootPart(guardianPlayer)
	local thiefRoot = getRootPart(targetPlayer)
	if not guardianRoot or not thiefRoot then
		return false, "missing_root"
	end

	local distance = (guardianRoot.Position - thiefRoot.Position).Magnitude
	if distance > Constants.GUARDIAN_CATCH_DISTANCE then
		return false, "too_far"
	end
	-- Use PlayerStateService as source of truth, not just rolesByPlayer
	if not PlayerStateService.CanBeCaught(targetPlayer) then
		return false, "target_not_catchable"
	end
	-- Line-of-sight validation
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {
		guardianPlayer.Character,
		targetPlayer.Character,
	}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local direction = thiefRoot.Position - guardianRoot.Position
	local rayResult = workspace:Raycast(guardianRoot.Position, direction, raycastParams)
	if rayResult then
		-- Something blocked the ray before reaching the thief
		return false, "no_line_of_sight"
	end

	local thiefCaughtRemote = ReplicatedStorage:FindFirstChild("ThiefCaught")
	if thiefCaughtRemote and thiefCaughtRemote:IsA("RemoteEvent") then
		thiefCaughtRemote:FireAllClients(guardianPlayer, targetPlayer)
	end

	return true
end

return GuardianController
