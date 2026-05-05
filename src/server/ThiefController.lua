local ThiefController = {}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function isNearVault(player)
	local rootPart = getRootPart(player)
	if not rootPart then
		return false
	end

	for _, vault in CollectionService:GetTagged("Vault") do
		if vault:IsA("BasePart") and vault:IsDescendantOf(workspace) then
			local distance = (vault.Position - rootPart.Position).Magnitude
			if distance <= Constants.THIEF_EXTRACT_DISTANCE then
				return true
			end
		end
	end

	return false
end

function ThiefController.ValidateExtract(player, rolesByPlayer, roundActive)
	if not roundActive then
		return false, "round_inactive"
	end

	if rolesByPlayer[player] ~= "Thief" then
		return false, "not_thief"
	end

	if not Players:FindFirstChild(player.Name) then
		return false, "player_missing"
	end

	if not isNearVault(player) then
		return false, "not_near_vault"
	end

	return true
end

return ThiefController
