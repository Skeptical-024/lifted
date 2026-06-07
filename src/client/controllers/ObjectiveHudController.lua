-- ObjectiveHudController: seal panel, objective interaction panel, objective remotes.

local ObjectiveHudController = {}

local sharedHud = nil
local killFeed = nil
local skillCheck = nil

-- Private UI
local sealPanel, sealShadow, sealTitle, vaultStatusLabel
local sealIcons = {}
local objectiveInteractionPanel, objectiveInteractionShadow
local objectiveNameLabel, objectivePromptLabel
local objectiveProgressBack, objectiveProgressFill, objectiveProgressLabel
local objectiveDangerLabel

-- Private state
local currentObjectiveId = nil
local currentObjectiveName = nil
local objectiveInteractionActive = false
local objectiveProgress = 0

local sealNames = {
	[1] = "FLAME",
	[2] = "MOON",
	[3] = "SIGIL",
}

local indexByObjectiveId = {
	FlameSeal = 1,
	MoonLock  = 2,
	StoneSigil = 3,
}

function ObjectiveHudController.Init(sh, kf, sc)
	sharedHud = sh
	killFeed = kf
	skillCheck = sc

	local COLORS = sh.COLORS
	local gui = sh.gui
	local makePanel = sh.makePanel
	local makeShadow = sh.makeShadow
	local makeLabel = sh.makeLabel
	local tweenIn = sh.tweenIn

	sealPanel = makePanel(UDim2.fromOffset(220, 88), UDim2.new(0, 16, 1, -96), gui, 0.2)
	sealShadow = makeShadow(sealPanel)
	sealShadow.Size = sealPanel.Size
	sealShadow.Position = sealPanel.Position + UDim2.fromOffset(2, 2)
	sealPanel.Visible = false
	sealShadow.Visible = false
	local bs = sealPanel:FindFirstChildOfClass("UIStroke")
	if bs then
		bs.Color = COLORS.teal
		bs.Transparency = 0.35
	end

	sealTitle = makeLabel("SEALS", Enum.Font.GothamBold, COLORS.grey, sealPanel)
	sealTitle.Size = UDim2.new(1, 0, 0, 14)
	sealTitle.Position = UDim2.fromOffset(0, 2)
	sealTitle.TextSize = 12

	for i = 1, 3 do
		local sq = Instance.new("Frame")
		sq.Size = UDim2.fromOffset(20, 20)
		sq.Position = UDim2.fromOffset(10 + (i - 1) * 28, 26)
		sq.BackgroundColor3 = COLORS.panelSoft
		sq.Parent = sealPanel
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 5)
		c.Parent = sq
		local s = Instance.new("UIStroke")
		s.Color = COLORS.white
		s.Transparency = 0.85
		s.Parent = sq
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.fromOffset(20, 10)
		nameLabel.Position = UDim2.fromOffset(10 + (i - 1) * 28, 49)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = sealNames[i] or ""
		nameLabel.TextSize = 8
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextColor3 = COLORS.teal
		nameLabel.TextTransparency = 0.5
		nameLabel.TextXAlignment = Enum.TextXAlignment.Center
		nameLabel.TextYAlignment = Enum.TextYAlignment.Center
		nameLabel.Parent = sealPanel
		sealIcons[i] = {frame = sq, stroke = s, label = nameLabel}
	end

	vaultStatusLabel = makeLabel("VAULT SEALED", Enum.Font.GothamBold, COLORS.grey, sealPanel)
	vaultStatusLabel.Name = "VaultStatusLabel"
	vaultStatusLabel.Position = UDim2.fromOffset(0, 66)
	vaultStatusLabel.Size = UDim2.new(1, 0, 0, 14)
	vaultStatusLabel.TextSize = 11
	vaultStatusLabel.BackgroundTransparency = 1

	objectiveInteractionPanel = makePanel(
		UDim2.fromOffset(220, 92),
		UDim2.new(0.5, -110, 1, -244),
		gui, 0.2
	)
	objectiveInteractionShadow = makeShadow(objectiveInteractionPanel)
	objectiveInteractionPanel.Visible = false
	objectiveInteractionShadow.Visible = false

	local oipStroke = objectiveInteractionPanel:FindFirstChildOfClass("UIStroke")
	if oipStroke then
		oipStroke.Color = COLORS.teal
		oipStroke.Transparency = 0.35
	end

	objectiveNameLabel = makeLabel("", Enum.Font.GothamBold, COLORS.grey, objectiveInteractionPanel)
	objectiveNameLabel.Size = UDim2.new(1, 0, 0, 13)
	objectiveNameLabel.TextSize = 11

	objectivePromptLabel = makeLabel("", Enum.Font.Gotham, COLORS.white, objectiveInteractionPanel)
	objectivePromptLabel.Size = UDim2.new(1, 0, 0, 16)
	objectivePromptLabel.Position = UDim2.fromOffset(0, 14)
	objectivePromptLabel.TextSize = 13

	objectiveProgressBack = Instance.new("Frame")
	objectiveProgressBack.Size = UDim2.new(1, -16, 0, 8)
	objectiveProgressBack.Position = UDim2.fromOffset(8, 34)
	objectiveProgressBack.BackgroundColor3 = COLORS.panelSoft
	objectiveProgressBack.BorderSizePixel = 0
	objectiveProgressBack.Parent = objectiveInteractionPanel
	local opbCorner = Instance.new("UICorner")
	opbCorner.CornerRadius = UDim.new(0, 4)
	opbCorner.Parent = objectiveProgressBack

	objectiveProgressFill = Instance.new("Frame")
	objectiveProgressFill.Size = UDim2.fromScale(0, 1)
	objectiveProgressFill.BackgroundColor3 = COLORS.teal
	objectiveProgressFill.BorderSizePixel = 0
	objectiveProgressFill.Parent = objectiveProgressBack
	local opfCorner = Instance.new("UICorner")
	opfCorner.CornerRadius = UDim.new(0, 4)
	opfCorner.Parent = objectiveProgressFill

	objectiveProgressLabel = makeLabel("", Enum.Font.GothamBold, COLORS.teal, objectiveInteractionPanel)
	objectiveProgressLabel.Size = UDim2.new(1, 0, 0, 12)
	objectiveProgressLabel.Position = UDim2.fromOffset(0, 46)
	objectiveProgressLabel.TextSize = 10

	objectiveDangerLabel = makeLabel("", Enum.Font.GothamBold, COLORS.red, objectiveInteractionPanel)
	objectiveDangerLabel.Size = UDim2.new(1, 0, 0, 14)
	objectiveDangerLabel.Position = UDim2.fromOffset(0, 62)
	objectiveDangerLabel.TextSize = 11

	-- Remote connections
	local co = sh.connectOptional
	local Remotes = sh.Remotes

	co(Remotes.Names.ObjectivePromptShown, function(objectiveId, objectiveName)
		ObjectiveHudController.ShowPrompt(objectiveId, objectiveName)
	end)

	co(Remotes.Names.ObjectivePromptHidden, function(objectiveId)
		if currentObjectiveId == nil or currentObjectiveId == objectiveId then
			ObjectiveHudController.HidePrompt()
		end
	end)

	co(Remotes.Names.ObjectiveInteractionStarted, function(objectiveId, objectiveName)
		ObjectiveHudController.StartInteraction(objectiveId, objectiveName)
	end)

	co(Remotes.Names.ObjectiveProgress, function(objectiveId, progress)
		if currentObjectiveId == nil or currentObjectiveId == objectiveId then
			ObjectiveHudController.UpdateProgress(progress)
		end
	end)

	co(Remotes.Names.ObjectiveCompleted, function(objectiveId)
		local idx = indexByObjectiveId[objectiveId]
		if idx and sealIcons[idx] then
			local icon = sealIcons[idx]
			icon.frame.BackgroundColor3 = COLORS.teal
			icon.stroke.Color = COLORS.teal
			icon.stroke.Transparency = 0.15
			icon.frame.Size = UDim2.fromOffset(20, 20)
			tweenIn(icon.frame, "Size", UDim2.fromOffset(24, 24), 0.1)
			task.delay(0.1, function()
				if icon.frame.Parent then
					tweenIn(icon.frame, "Size", UDim2.fromOffset(20, 20), 0.1)
				end
			end)
			local newCount = math.clamp(sh.getSealsBroken() + 1, 0, 3)
			sh.setSealsBroken(newCount)
			local status = sealPanel:FindFirstChild("VaultStatusLabel")
			if status and status:IsA("TextLabel") then
				status.Text = "VAULT SEALED"
				status.TextColor3 = COLORS.grey
			end
		end
		ObjectiveHudController.CompleteInteraction()
	end)

	co(Remotes.Names.ObjectiveFailed, function(objectiveId, reason)
		ObjectiveHudController.FailInteraction(reason)
	end)

	-- Dead remote: server does not fire ObjectiveStarted yet
	co("ObjectiveStarted", function(objectiveId, objectiveName)
		sharedHud.showFailure and nil  -- no-op placeholder; move as-is per spec
	end)
end

function ObjectiveHudController.SetSealPanelVisible(visible)
	sealPanel.Visible = visible
	sealShadow.Visible = visible
end

function ObjectiveHudController.SetVaultStatus(text, color)
	vaultStatusLabel.Text = text or "VAULT SEALED"
	vaultStatusLabel.TextColor3 = color or sharedHud.COLORS.grey
end

function ObjectiveHudController.SetSealCompleted(objectiveId)
	local COLORS = sharedHud.COLORS
	local tweenIn = sharedHud.tweenIn
	local idx = indexByObjectiveId[objectiveId]
	if idx and sealIcons[idx] then
		local icon = sealIcons[idx]
		icon.frame.BackgroundColor3 = COLORS.teal
		icon.stroke.Color = COLORS.teal
		icon.stroke.Transparency = 0.15
	end
end

function ObjectiveHudController.Reset()
	currentObjectiveId = nil
	currentObjectiveName = nil
	objectiveInteractionActive = false
	objectiveProgress = 0
	objectiveInteractionPanel.Visible = false
	objectiveInteractionShadow.Visible = false
	objectiveNameLabel.Text = ""
	objectivePromptLabel.Text = ""
	objectiveDangerLabel.Text = ""
	objectiveProgressFill.Size = UDim2.fromScale(0, 1)
	objectiveProgressLabel.Text = ""
	skillCheck.Hide()
end

function ObjectiveHudController.ShowPrompt(objectiveId, objectiveName)
	if not sharedHud.isThiefRole() then return end
	currentObjectiveId = objectiveId
	currentObjectiveName = objectiveName
	objectiveInteractionPanel.Visible = true
	objectiveInteractionShadow.Visible = true
	objectiveNameLabel.Text = (type(objectiveName) == "string" and #objectiveName > 0)
		and objectiveName or "SEAL OBJECTIVE"
	objectivePromptLabel.Text = "Hold E to break seal"
	objectiveDangerLabel.Text = ""
end

function ObjectiveHudController.HidePrompt()
	if objectiveInteractionActive then return end
	objectiveInteractionPanel.Visible = false
	objectiveInteractionShadow.Visible = false
	objectivePromptLabel.Text = ""
end

function ObjectiveHudController.StartInteraction(objectiveId, objectiveName)
	if not sharedHud.isThiefRole() then return end
	objectiveInteractionActive = true
	currentObjectiveId = objectiveId
	currentObjectiveName = objectiveName
	objectiveInteractionPanel.Visible = true
	objectiveInteractionShadow.Visible = true
	objectiveNameLabel.Text = (type(objectiveName) == "string" and #objectiveName > 0)
		and objectiveName or "SEAL OBJECTIVE"
	objectivePromptLabel.Text = "Breaking seal..."
	objectiveDangerLabel.Text = ""
end

function ObjectiveHudController.UpdateProgress(progress)
	progress = math.clamp(tonumber(progress) or 0, 0, 1)
	objectiveProgress = progress
	objectiveProgressFill.Size = UDim2.fromScale(progress, 1)
	objectiveProgressLabel.Text = math.floor(progress * 100) .. "%"
	-- Server drives completion via ObjectiveCompleted; never self-complete.
end

function ObjectiveHudController.CompleteInteraction()
	objectiveInteractionActive = false
	objectivePromptLabel.Text = "Seal broken."
	objectiveDangerLabel.Text = ""
	skillCheck.Hide()
	if currentObjectiveId ~= nil then
		killFeed.Add("Seal broken.")
	end
	task.delay(1.5, function()
		if not objectiveInteractionActive then
			if objectiveInteractionPanel.Parent then
				objectiveInteractionPanel.Visible = false
			end
			if objectiveInteractionShadow.Parent then
				objectiveInteractionShadow.Visible = false
			end
		end
	end)
end

function ObjectiveHudController.FailInteraction(reason)
	local COLORS = sharedHud.COLORS
	local msg = sharedHud.readableFailure(reason)
	objectiveDangerLabel.Text = msg
	objectiveDangerLabel.TextColor3 = COLORS.red
	sharedHud.showFailure(reason)
	skillCheck.Hide()
	task.delay(2, function()
		if objectiveDangerLabel.Parent then
			objectiveDangerLabel.Text = ""
		end
	end)
end

function ObjectiveHudController.HideInteractionPanel()
	objectiveInteractionPanel.Visible = false
	objectiveInteractionShadow.Visible = false
end

return ObjectiveHudController
