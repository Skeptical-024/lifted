-- Sends a coarse, rate-limited activity pulse after real local input or movement.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local localPlayer = Players.LocalPlayer
local activityRemote = Remotes.Client(Remotes.Names.ActivityPulse)

local dirty = true
local lastSentAt = 0
local lastPosition = nil
local interval = Constants.AFK_ACTIVITY_PULSE_SECONDS or 5

UserInputService.InputBegan:Connect(function(_, gameProcessed)
	if not gameProcessed then
		dirty = true
	end
end)

RunService.Heartbeat:Connect(function()
	local root = localPlayer.Character
		and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if root then
		if lastPosition and (root.Position - lastPosition).Magnitude >= 2 then
			dirty = true
		end
		lastPosition = root.Position
	end

	if dirty and os.clock() - lastSentAt >= interval then
		dirty = false
		lastSentAt = os.clock()
		activityRemote:FireServer()
	end
end)
