-- SkillCheckController: skill check panel, needle, SkillCheckStarted/Result/Expired remotes.

local SkillCheckController = {}

local sharedHud = nil
local killFeed = nil

-- Private UI
local skillCheckPanel, skillCheckShadow, skillCheckLabel
local skillCheckBack, skillCheckTargetZone, skillCheckNeedle

-- Private state
local skillCheckActive = false
local pendingSkillCheckId = nil

function SkillCheckController.Init(sh, kf)
	sharedHud = sh
	killFeed = kf

	local COLORS = sh.COLORS
	local gui = sh.gui
	local makePanel = sh.makePanel
	local makeShadow = sh.makeShadow
	local makeLabel = sh.makeLabel

	skillCheckPanel = makePanel(
		UDim2.fromOffset(280, 64),
		UDim2.new(0.5, -140, 0.5, 80),
		gui, 0.15
	)
	skillCheckShadow = makeShadow(skillCheckPanel)
	skillCheckPanel.Visible = false
	skillCheckShadow.Visible = false

	local scpStroke = skillCheckPanel:FindFirstChildOfClass("UIStroke")
	if scpStroke then
		scpStroke.Color = COLORS.teal
		scpStroke.Transparency = 0.3
	end

	skillCheckLabel = makeLabel("HIT SPACE!", Enum.Font.GothamBold, COLORS.teal, skillCheckPanel)
	skillCheckLabel.Size = UDim2.new(1, 0, 0, 13)
	skillCheckLabel.TextSize = 11

	skillCheckBack = Instance.new("Frame")
	skillCheckBack.Size = UDim2.new(1, -16, 0, 20)
	skillCheckBack.Position = UDim2.fromOffset(8, 20)
	skillCheckBack.BackgroundColor3 = COLORS.panelSoft
	skillCheckBack.BorderSizePixel = 0
	skillCheckBack.Parent = skillCheckPanel
	local scbCorner = Instance.new("UICorner")
	scbCorner.CornerRadius = UDim.new(0, 4)
	scbCorner.Parent = skillCheckBack

	skillCheckTargetZone = Instance.new("Frame")
	skillCheckTargetZone.Size = UDim2.fromScale(0.2, 1)
	skillCheckTargetZone.Position = UDim2.fromScale(0.4, 0)
	skillCheckTargetZone.BackgroundColor3 = COLORS.teal
	skillCheckTargetZone.BackgroundTransparency = 0.5
	skillCheckTargetZone.BorderSizePixel = 0
	skillCheckTargetZone.Parent = skillCheckBack
	local sctzCorner = Instance.new("UICorner")
	sctzCorner.CornerRadius = UDim.new(0, 3)
	sctzCorner.Parent = skillCheckTargetZone

	skillCheckNeedle = Instance.new("Frame")
	skillCheckNeedle.Size = UDim2.new(0, 3, 1, 0)
	skillCheckNeedle.Position = UDim2.fromScale(0, 0)
	skillCheckNeedle.BackgroundColor3 = COLORS.white
	skillCheckNeedle.BorderSizePixel = 0
	skillCheckNeedle.Parent = skillCheckBack
	skillCheckNeedle.Visible = false

	-- Remote connections
	local co = sh.connectOptional
	local Remotes = sh.Remotes

	co(Remotes.Names.SkillCheckStarted, function(_, checkId, _)
		if not sh.isThiefRole() then return end
		SkillCheckController.Show()
		pendingSkillCheckId = checkId
	end)

	co(Remotes.Names.SkillCheckResult, function(_, checkId, success, _)
		pendingSkillCheckId = nil
		if success then
			if skillCheckPanel and skillCheckPanel.Parent then
				skillCheckPanel.BackgroundColor3 = Color3.fromRGB(20, 80, 30)
				task.delay(0.3, function()
					if skillCheckPanel.Parent then
						skillCheckPanel.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
					end
				end)
			end
			killFeed.Add("Skill check!")
		else
			if skillCheckPanel and skillCheckPanel.Parent then
				skillCheckPanel.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
				task.delay(0.3, function()
					if skillCheckPanel.Parent then
						skillCheckPanel.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
					end
				end)
			end
		end
		task.delay(0.5, function()
			SkillCheckController.Hide()
		end)
	end)

	co(Remotes.Names.SkillCheckExpired, function(_, checkId)
		pendingSkillCheckId = nil
		SkillCheckController.Hide()
	end)
end

function SkillCheckController.Show()
	if not sharedHud.isThiefRole() then return end
	skillCheckActive = true
	skillCheckPanel.Visible = true
	skillCheckShadow.Visible = true
	skillCheckLabel.Text = "HIT SPACE / A"
	skillCheckTargetZone.Position = UDim2.fromScale(0, 0)
	skillCheckTargetZone.Size = UDim2.fromScale(1, 1)
end

function SkillCheckController.Hide()
	skillCheckActive = false
	skillCheckPanel.Visible = false
	skillCheckShadow.Visible = false
end

function SkillCheckController.GetPendingId()
	return pendingSkillCheckId
end

function SkillCheckController.ClearPendingId()
	pendingSkillCheckId = nil
end

function SkillCheckController.Reset()
	skillCheckActive = false
	pendingSkillCheckId = nil
	SkillCheckController.Hide()
end

return SkillCheckController
