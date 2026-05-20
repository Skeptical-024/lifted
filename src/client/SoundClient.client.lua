local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))

local localPlayer = Players.LocalPlayer

local roleAssignedRemote = ReplicatedStorage:WaitForChild("RoleAssigned")
local thiefCaughtRemote = ReplicatedStorage:WaitForChild("ThiefCaught")
local roundEndedRemote = ReplicatedStorage:WaitForChild("RoundEnded")
local lobbyUpdateRemote = ReplicatedStorage:WaitForChild("LobbyUpdate")
local objectiveCompletedRemote = ReplicatedStorage:WaitForChild("ObjectiveCompleted")
local vaultOpenedRemote = ReplicatedStorage:WaitForChild("VaultOpened")
local idolPickedUpRemote = ReplicatedStorage:WaitForChild("IdolPickedUp")
local idolDroppedRemote = ReplicatedStorage:WaitForChild("IdolDropped")
local extractCompletedRemote = ReplicatedStorage:WaitForChild("ExtractCompleted")
local guardianRoarActivatedRemote = ReplicatedStorage:WaitForChild("GuardianRoarActivated")

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
	SealCompleted = "rbxassetid://6042053626",
	ExtractSuccess = "rbxassetid://1837853335",
	CountdownBeep = "rbxassetid://6042053626",
	FinalCountdownBeep = "rbxassetid://4612263052",
	VaultOpened = "rbxassetid://6042053626",
	IdolPickedUp = "rbxassetid://6042053626",
	IdolDropped = "rbxassetid://4612263052",
}

local lastCountdown = nil

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

objectiveCompletedRemote.OnClientEvent:Connect(function()
	playOneShot(SOUND_IDS.SealCompleted, 0.8, SoundService, 80)
end)

vaultOpenedRemote.OnClientEvent:Connect(function()
	playOneShot(SOUND_IDS.VaultOpened, 0.8, SoundService, 80)
end)

idolPickedUpRemote.OnClientEvent:Connect(function()
	playOneShot(SOUND_IDS.IdolPickedUp, 0.75, SoundService, 80)
end)

idolDroppedRemote.OnClientEvent:Connect(function()
	playOneShot(SOUND_IDS.IdolDropped, 0.7, SoundService, 80)
end)

extractCompletedRemote.OnClientEvent:Connect(function()
	playOneShot(SOUND_IDS.ExtractSuccess, 0.9, SoundService, 80)
end)

guardianRoarActivatedRemote.OnClientEvent:Connect(function()
	playOneShot(SOUND_IDS.GuardianCatch, 0.8, SoundService, 80)
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

-- Footstep one-shot playback intentionally disabled to avoid asset mismatch spam.
