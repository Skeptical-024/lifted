-- RoundUIClient v4 — thin bootstrap; all HUD logic lives in src/client/controllers/

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

-- Resolve the controllers folder (PlayerScripts at runtime)
local controllersFolder = script.Parent:WaitForChild("controllers")

-- ── Init order: SharedHud → KillFeed → Results → GuardianHud → ThiefHud
--               → SkillCheck → ObjectiveHud → IdolExtract → Cage
--               → CoreHud → SnapshotController ─────────────────────────
local SharedHud            = require(controllersFolder:WaitForChild("SharedHud"))
local KillFeedController   = require(controllersFolder:WaitForChild("KillFeedController"))
local ResultsController    = require(controllersFolder:WaitForChild("ResultsController"))
local GuardianHudController = require(controllersFolder:WaitForChild("GuardianHudController"))
local ThiefHudController   = require(controllersFolder:WaitForChild("ThiefHudController"))
local SkillCheckController  = require(controllersFolder:WaitForChild("SkillCheckController"))
local ObjectiveHudController = require(controllersFolder:WaitForChild("ObjectiveHudController"))
local IdolExtractController  = require(controllersFolder:WaitForChild("IdolExtractController"))
local CageController         = require(controllersFolder:WaitForChild("CageController"))
local CoreHudController      = require(controllersFolder:WaitForChild("CoreHudController"))
local SnapshotController     = require(controllersFolder:WaitForChild("SnapshotController"))

-- ── Wire up controllers ──────────────────────────────────────────────────

KillFeedController.Init(SharedHud)
SharedHud.injectKillFeed(KillFeedController.Add)  -- enables showFailure

ResultsController.Init(SharedHud)

GuardianHudController.Init(SharedHud, KillFeedController)

ThiefHudController.Init(SharedHud)

SkillCheckController.Init(SharedHud, KillFeedController)

ObjectiveHudController.Init(SharedHud, KillFeedController, SkillCheckController)

IdolExtractController.Init(SharedHud, KillFeedController, GuardianHudController)

CageController.Init(SharedHud, KillFeedController)

CoreHudController.Init(
	SharedHud,
	KillFeedController,
	GuardianHudController,
	ThiefHudController,
	ObjectiveHudController
)

-- Inject CoreHud into controllers that need it at handler time
IdolExtractController.SetCoreHud(CoreHudController)
CageController.SetCoreHud(CoreHudController)

-- SnapshotController inits last and triggers the first snapshot itself
SnapshotController.Init(
	SharedHud,
	CoreHudController,
	KillFeedController,
	GuardianHudController,
	ThiefHudController,
	SkillCheckController,
	ObjectiveHudController,
	IdolExtractController,
	CageController
)

-- ── Top-level remote connections ─────────────────────────────────────────

local roundStartedRemote = Remotes.Client(Remotes.Names.RoundStarted)
local roundEndedRemote   = Remotes.Client(Remotes.Names.RoundEnded)
local thiefCaughtRemote  = Remotes.Client(Remotes.Names.ThiefCaught)

roundStartedRemote.OnClientEvent:Connect(function(roundDuration, totalThieves)
	local duration = tonumber(roundDuration) or 0
	SharedHud.setDuration(duration)
	SharedHud.setRoundEndTime(os.clock() + duration)
	SharedHud.setIsRoundActive(true)
	SharedHud.setThievesCaughtByGuardian(0)

	CoreHudController.Show()
	KillFeedController.Add("Break 3 seals to open the vault.")
	local role = localPlayer:GetAttribute("Role")
	CoreHudController.SetRole(role)
	if role == "Guardian" then
		local count = tonumber(totalThieves) or ThiefHudController.InferThiefCount()
		ThiefHudController.UpdateIconCount(count)
	end

	SharedHud.setSealsBroken(0)
	SharedHud.setIdolTaken(false)

	CoreHudController.SetDirectiveVisible(true)
	if role == "Thief" then
		CoreHudController.SetDirective("Break 3 seals to open the vault.")
	elseif role == "Guardian" then
		CoreHudController.SetDirective("Stop the thieves. Shift Rush | Q Reveal | R Roar | E Catch")
	else
		CoreHudController.SetDirective("")
	end

	CoreHudController.SetPhase("Break the Seals")
	IdolExtractController.Reset()
	ObjectiveHudController.Reset()
	GuardianHudController.Reset()

	if SharedHud.isGuardianRole() then
		GuardianHudController.SetVisible(true)
	end

	ResultsController.Reset()
	CoreHudController.SetHintVisible(false)
	SkillCheckController.Reset()
	CageController.Reset()
end)

roundEndedRemote.OnClientEvent:Connect(function(result, winner)
	SharedHud.setIsRoundActive(false)
	CoreHudController.Hide()

	if type(result) ~= "string" then result = "Round ended" end
	if type(winner) ~= "string" then winner = "Time" end

	if winner == "Thieves" then
		KillFeedController.Add("Thieves extracted loot")
	end

	-- Hide panels owned by other controllers
	ObjectiveHudController.HideInteractionPanel()
	SkillCheckController.Hide()
	GuardianHudController.SetPanelsForRole(false)
	IdolExtractController.HidePanel()

	KillFeedController.Add("Round over")

	if winner == "Thieves" then
		CoreHudController.SetPhase("Heist Complete")
	elseif winner == "Guardian" then
		CoreHudController.SetPhase("Guardian Victory")
	else
		CoreHudController.SetPhase("Round Ended")
	end

	CoreHudController.SetDirectiveVisible(false)
	CoreHudController.SetDirective("")
	SharedHud.setSealsBroken(0)
	SharedHud.setIdolTaken(false)
	IdolExtractController.Reset()
	ObjectiveHudController.Reset()
	GuardianHudController.Reset()
	SkillCheckController.Reset()
end)

thiefCaughtRemote.OnClientEvent:Connect(function(_, caughtPlayer)
	if typeof(caughtPlayer) == "Instance" and caughtPlayer:IsA("Player") then
		KillFeedController.Add("Guardian caught " .. caughtPlayer.Name)
	end
	if localPlayer:GetAttribute("Role") == "Guardian" then
		SharedHud.setThievesCaughtByGuardian(SharedHud.getThievesCaughtByGuardian() + 1)
	end
end)
