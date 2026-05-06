local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))

local localPlayer = Players.LocalPlayer

local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")
local thiefCaughtRemote = ReplicatedStorage:WaitForChild("ThiefCaught")
local brazierStateChangedRemote = ReplicatedStorage:WaitForChild("BrazierStateChanged")
local roundEndedRemote = ReplicatedStorage:WaitForChild("RoundEnded")
local lobbyUpdateRemote = ReplicatedStorage:WaitForChild("LobbyUpdate")

local soundGroup = SoundService:FindFirstChild("GameSounds")
if not soundGroup then
	soundGroup = Instance.new("SoundGroup")
	soundGroup.Name = "GameSounds"
	soundGroup.Parent = SoundService
end

local SOUND_IDS = {
	RoundStart = "rbxassetid://1837853335",
	RoundEndWin = "rbxassetid://4612263052",
	RoundEndLose = "rbxassetid://4612263052",
	ThiefCaught = "rbxassetid://4612263052",
	GuardianCatch = "rbxassetid://6042053626",
	BrazierLit = "rbxassetid://6042053626",
	BrazierExtinguish = "rbxassetid://4612263052",
	ExtractSuccess = "rbxassetid://1837853335",
	CountdownBeep = "rbxassetid://6042053626",
	FinalCountdownBeep = "rbxassetid://4612263052",
	Footstep = "rbxassetid://1763718928",
}

local lastLitCount = 0
local lastCountdown = nil
local footstepTimer = 0

local function getRole()
	return localPlayer:GetAttribute("Role")
end

local function playOneShot(soundId, volume, parent, rolloff)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.RollOffMaxDistance = rolloff or 80
	sound.SoundGroup = soundGroup
	sound.Parent = parent or SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(5, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function isGrounded(root)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {localPlayer.Character}
	local result = workspace:Raycast(root.Position, Vector3.new(0, -4, 0), raycastParams)
	return result ~= nil
end

roleAssignedRemote.OnClientEvent:Connect(function()
	playOneShot(SOUND_IDS.RoundStart, 0.8, SoundService, 80)
end)

thiefCaughtRemote.OnClientEvent:Connect(function(guardianPlayer, caughtPlayer)
	if typeof(guardianPlayer) ~= "Instance" or typeof(caughtPlayer) ~= "Instance" then
		return
	end
	if localPlayer == caughtPlayer then
		playOneShot(SOUND_IDS.ThiefCaught, 1, SoundService, 80)
	elseif localPlayer == guardianPlayer then
		local root = getRootPart(localPlayer)
		playOneShot(SOUND_IDS.GuardianCatch, 1, root or SoundService, 80)
	end
end)

brazierStateChangedRemote.OnClientEvent:Connect(function(litNames)
	if type(litNames) ~= "table" then
		return
	end
	local count = #litNames
	if count > lastLitCount then
		local name = litNames[count]
		local part = workspace:FindFirstChild(name, true)
		playOneShot(SOUND_IDS.BrazierLit, 0.8, part or SoundService, 80)
	elseif count < lastLitCount then
		playOneShot(SOUND_IDS.BrazierExtinguish, 0.8, SoundService, 80)
	end
	lastLitCount = count
end)

roundEndedRemote.OnClientEvent:Connect(function(_, winner)
	local role = getRole()
	if winner == "Thieves" then
		playOneShot(SOUND_IDS.ExtractSuccess, 0.9, SoundService, 80)
	end
	if role == Types.PlayerRole.Guardian then
		if winner == "Guardian" or winner == "Time" then
			playOneShot(SOUND_IDS.RoundEndWin, 0.9, SoundService, 80)
		else
			playOneShot(SOUND_IDS.RoundEndLose, 0.9, SoundService, 80)
		end
	elseif role == Types.PlayerRole.Thief then
		if winner == "Thieves" then
			playOneShot(SOUND_IDS.RoundEndWin, 0.9, SoundService, 80)
		else
			playOneShot(SOUND_IDS.RoundEndLose, 0.9, SoundService, 80)
		end
	end
end)

lobbyUpdateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.status ~= "countdown" then
		lastCountdown = nil
		return
	end

	local countdown = payload.countdown
	if type(countdown) ~= "number" then
		return
	end
	if countdown == lastCountdown then
		return
	end
	lastCountdown = countdown

	if countdown <= 3 then
		playOneShot(SOUND_IDS.FinalCountdownBeep, 0.8, SoundService, 80)
	else
		playOneShot(SOUND_IDS.CountdownBeep, 0.6, SoundService, 80)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	footstepTimer += dt
	local root = getRootPart(localPlayer)
	if not root then
		return
	end
	if root.AssemblyLinearVelocity.Magnitude <= 2 then
		return
	end
	if not isGrounded(root) then
		return
	end

	local interval = 0.4
	if getRole() == Types.PlayerRole.Thief and root.Parent then
		local humanoid = root.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.WalkSpeed <= Constants.THIEF_CROUCH_SPEED + 0.1 then
			interval = 0.7
		end
	end

	if footstepTimer >= interval then
		footstepTimer = 0
		local volume = interval == 0.7 and 0.3 or 0.5
		playOneShot(SOUND_IDS.Footstep, volume, root, 40)
	end
end)
