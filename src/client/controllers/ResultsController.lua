-- ResultsController: round-results overlay, all result labels, show/hide logic.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local ResultsController = {}

local sharedHud = nil

-- Private UI
local roundResultsOverlay, resultPanel, resultPanelShadow
local resultTop, resultTitleLabel, accentLine, resultSubtitleLabel, resultRoleNote
local resultStatsFrame, statSealLabel, statCaughtLabel, statTimeLabel, statXPLabel
local resultRewardLabel, resultMvpLabel, resultBoardLabel, resultNextLabel, resultDivider
local resultStroke

-- Private state
local roundResultVisible = false

local function formatTime(secs)
	local m = math.floor(math.max(secs, 0) / 60)
	local s = math.floor(math.max(secs, 0) % 60)
	return string.format("%d:%02d", m, s)
end

local function normalizeRoundResult(...)
	local args = {...}
	if type(args[1]) == "table" then
		return args[1]
	end
	local resultStr = type(args[1]) == "string" and args[1] or ""
	local winnerStr = type(args[2]) == "string" and args[2] or ""
	local reason = "Unknown"
	if resultStr:lower():find("extract") then
		reason = "IdolExtracted"
	elseif resultStr:lower():find("caught") then
		reason = "AllThievesCaught"
	elseif resultStr:lower():find("time") then
		reason = "TimerExpired"
	end
	local localPlayer = sharedHud.localPlayer
	return {
		winningTeam = (winnerStr ~= "" and winnerStr or nil),
		reason = reason,
		role = localPlayer:GetAttribute("Role"),
		xpEarned = 0,
		sealsBroken = (sharedHud.getLastReportedSealCount() or 0),
		thievesCaught = (sharedHud.getThievesCaughtByGuardian() or 0),
		timeRemaining = 0,
	}
end

local function formatRoundReason(winningTeam, reason)
	if winningTeam == "Thieves" then
		if reason == "IdolExtracted" then return "The idol was lifted." end
		return "The thieves won."
	elseif winningTeam == "Guardian" then
		if reason == "AllThievesCaught" then return "All thieves were caught." end
		if reason == "TimerExpired" then return "The temple held." end
		return "The guardian stopped the heist."
	elseif winningTeam == "Draw" then
		return "No winner."
	end
	return "Returning to lobby."
end

local function getLocalResultNote(winningTeam)
	local localPlayer = sharedHud.localPlayer
	local role = localPlayer:GetAttribute("Role")
	if role == "Thief" then
		if winningTeam == "Thieves" then return "You escaped the temple." end
		return "The heist failed."
	elseif role == "Guardian" then
		if winningTeam == "Guardian" then return "You protected the idol." end
		return "The idol was stolen."
	end
	return "Round complete."
end

function ResultsController.Init(sh)
	sharedHud = sh
	local COLORS = sh.COLORS
	local gui = sh.gui
	local makePanel = sh.makePanel
	local makeShadow = sh.makeShadow
	local makeLabel = sh.makeLabel
	local tweenIn = sh.tweenIn

	-- Full-screen dimmer
	roundResultsOverlay = Instance.new("Frame")
	roundResultsOverlay.Name = "RoundResultsOverlay"
	roundResultsOverlay.Size = UDim2.fromScale(1, 1)
	roundResultsOverlay.BackgroundColor3 = COLORS.bg
	roundResultsOverlay.BackgroundTransparency = 1
	roundResultsOverlay.Visible = false
	roundResultsOverlay.ZIndex = 10
	roundResultsOverlay.Parent = gui

	-- Center modal
	resultPanel = makePanel(
		UDim2.fromOffset(560, 320),
		UDim2.new(0.5, -280, 0.5, -160),
		roundResultsOverlay, 0.1
	)
	resultPanelShadow = makeShadow(resultPanel)
	resultPanel.Visible = false
	resultPanelShadow.Visible = false
	resultPanel.ZIndex = 11

	resultStroke = resultPanel:FindFirstChildOfClass("UIStroke")

	resultTop = makeLabel("ROUND OVER", Enum.Font.GothamBold, COLORS.grey, resultPanel)
	resultTop.Size = UDim2.new(1, 0, 0, 16)
	resultTop.TextSize = 12
	resultTop.ZIndex = 12

	resultTitleLabel = makeLabel("", Enum.Font.GothamBlack, COLORS.white, resultPanel)
	resultTitleLabel.Size = UDim2.new(1, 0, 0, 72)
	resultTitleLabel.Position = UDim2.fromOffset(0, 20)
	resultTitleLabel.TextSize = 52
	resultTitleLabel.ZIndex = 12

	accentLine = Instance.new("Frame")
	accentLine.Size = UDim2.fromOffset(0, 2)
	accentLine.Position = UDim2.new(0.5, 0, 0, 96)
	accentLine.AnchorPoint = Vector2.new(0.5, 0)
	accentLine.BorderSizePixel = 0
	accentLine.BackgroundColor3 = COLORS.teal
	accentLine.ZIndex = 12
	accentLine.Parent = resultPanel

	resultSubtitleLabel = makeLabel("", Enum.Font.GothamBold, COLORS.white, resultPanel)
	resultSubtitleLabel.Size = UDim2.new(1, -20, 0, 24)
	resultSubtitleLabel.Position = UDim2.fromOffset(10, 106)
	resultSubtitleLabel.TextSize = 18
	resultSubtitleLabel.ZIndex = 12

	resultRoleNote = makeLabel("", Enum.Font.Gotham, COLORS.grey, resultPanel)
	resultRoleNote.Size = UDim2.new(1, -20, 0, 18)
	resultRoleNote.Position = UDim2.fromOffset(10, 130)
	resultRoleNote.TextSize = 14
	resultRoleNote.ZIndex = 12

	-- Stats row
	resultStatsFrame = Instance.new("Frame")
	resultStatsFrame.Size = UDim2.new(1, -20, 0, 56)
	resultStatsFrame.Position = UDim2.fromOffset(10, 158)
	resultStatsFrame.BackgroundTransparency = 1
	resultStatsFrame.ZIndex = 12
	resultStatsFrame.Parent = resultPanel

	local cols = {
		{name = "SEALS BROKEN",   x = 0},
		{name = "THIEVES CAUGHT", x = 130},
		{name = "TIME LEFT",      x = 270},
		{name = "SCORE",          x = 390},
	}
	local vals = {}
	for i, col in ipairs(cols) do
		local h = makeLabel(col.name, Enum.Font.GothamBold, COLORS.grey, resultStatsFrame)
		h.Size = UDim2.fromOffset(120, 14)
		h.Position = UDim2.fromOffset(col.x, 0)
		h.TextSize = 10
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.ZIndex = 12

		local v = makeLabel("0", Enum.Font.GothamBold, COLORS.white, resultStatsFrame)
		v.Size = UDim2.fromOffset(120, 26)
		v.Position = UDim2.fromOffset(col.x, 16)
		v.TextSize = 20
		v.TextXAlignment = Enum.TextXAlignment.Left
		v.ZIndex = 12
		vals[i] = v
	end
	statSealLabel   = vals[1]
	statCaughtLabel = vals[2]
	statTimeLabel   = vals[3]
	statXPLabel     = vals[4]

	resultRewardLabel = makeLabel("", Enum.Font.GothamBold, COLORS.teal, resultPanel)
	resultRewardLabel.Size = UDim2.new(1, -20, 0, 18)
	resultRewardLabel.Position = UDim2.fromOffset(10, 224)
	resultRewardLabel.TextSize = 14
	resultRewardLabel.ZIndex = 12

	resultMvpLabel = makeLabel("", Enum.Font.GothamBold, COLORS.gold, resultPanel)
	resultMvpLabel.Size = UDim2.new(1, -20, 0, 16)
	resultMvpLabel.Position = UDim2.fromOffset(10, 244)
	resultMvpLabel.TextSize = 12
	resultMvpLabel.ZIndex = 12

	resultBoardLabel = makeLabel("", Enum.Font.Gotham, COLORS.grey, resultPanel)
	resultBoardLabel.Size = UDim2.new(1, -20, 0, 42)
	resultBoardLabel.Position = UDim2.fromOffset(10, 262)
	resultBoardLabel.TextSize = 11
	resultBoardLabel.TextYAlignment = Enum.TextYAlignment.Top
	resultBoardLabel.TextXAlignment = Enum.TextXAlignment.Left
	resultBoardLabel.ZIndex = 12

	resultNextLabel = makeLabel("Next round starting soon", Enum.Font.Gotham, COLORS.grey, resultPanel)
	resultNextLabel.Size = UDim2.new(1, -20, 0, 18)
	resultNextLabel.Position = UDim2.fromOffset(10, 306)
	resultNextLabel.TextSize = 13
	resultNextLabel.ZIndex = 12

	resultDivider = Instance.new("Frame")
	resultDivider.Size = UDim2.new(1, -20, 0, 1)
	resultDivider.Position = UDim2.fromOffset(10, 300)
	resultDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	resultDivider.BackgroundTransparency = 0.88
	resultDivider.BorderSizePixel = 0
	resultDivider.ZIndex = 12
	resultDivider.Parent = resultPanel

	-- Connect RoundResults remote (optional)
	sharedHud.connectOptional(sharedHud.Remotes.Names.RoundResults, function(resultData)
		roundResultVisible = false
		ResultsController.Show(resultData)
	end)
end

function ResultsController.Hide()
	roundResultVisible = false
	roundResultsOverlay.Visible = false
	resultPanel.Visible = false
	resultPanelShadow.Visible = false
end

function ResultsController.Reset()
	ResultsController.Hide()
	resultTitleLabel.Text    = ""
	resultSubtitleLabel.Text = ""
	resultRoleNote.Text      = ""
	resultRewardLabel.Text   = ""
	resultMvpLabel.Text      = ""
	resultBoardLabel.Text    = ""
	statSealLabel.Text       = "0"
	statCaughtLabel.Text     = "0"
	statTimeLabel.Text       = "0s"
	statXPLabel.Text         = "+0"
	accentLine.Size          = UDim2.fromOffset(0, 2)
end

function ResultsController.Show(...)
	if roundResultVisible then return end
	roundResultVisible = true

	local COLORS = sharedHud.COLORS
	local tweenIn = sharedHud.tweenIn
	local localPlayer = sharedHud.localPlayer

	local data = normalizeRoundResult(...)
	local winningTeam = data.winner or data.winningTeam or ""

	local accentColor = COLORS.white
	if winningTeam == "Thieves" then
		accentColor = COLORS.teal
		roundResultsOverlay.BackgroundColor3 = Color3.fromRGB(8, 32, 40)
	elseif winningTeam == "Guardian" then
		accentColor = COLORS.red
		roundResultsOverlay.BackgroundColor3 = Color3.fromRGB(40, 8, 8)
	else
		roundResultsOverlay.BackgroundColor3 = COLORS.bg
	end

	if winningTeam == "Thieves" then
		resultTitleLabel.Text       = "THIEVES ESCAPED"
		resultTitleLabel.TextColor3 = COLORS.teal
	elseif winningTeam == "Guardian" then
		resultTitleLabel.Text       = "GUARDIAN WON"
		resultTitleLabel.TextColor3 = COLORS.red
	elseif winningTeam == "Draw" then
		resultTitleLabel.Text       = "ROUND ENDED"
		resultTitleLabel.TextColor3 = COLORS.white
	else
		resultTitleLabel.Text       = "ROUND OVER"
		resultTitleLabel.TextColor3 = COLORS.white
	end

	resultSubtitleLabel.Text = formatRoundReason(winningTeam, data.reason)
	resultRoleNote.Text      = getLocalResultNote(winningTeam)

	local teamSummary = type(data.teamSummary) == "table" and data.teamSummary or {}
	statSealLabel.Text = tostring(math.clamp(
		tonumber(data.sealsBroken) or tonumber(teamSummary.sealsCompleted) or 0, 0, 3
	)) .. " / 3"
	local totalCatches = tonumber(data.thievesCaught) or 0
	if totalCatches == 0 and type(data.players) == "table" then
		for _, row in ipairs(data.players) do
			totalCatches += tonumber(row.stats and row.stats.catches) or 0
		end
	end
	statCaughtLabel.Text = tostring(totalCatches)
	statTimeLabel.Text = tostring(math.floor(math.max(tonumber(data.timeRemaining) or 0, 0))) .. "s"
	local localScore = 0
	if type(data.players) == "table" then
		for _, row in ipairs(data.players) do
			if tonumber(row.userId) == localPlayer.UserId then
				localScore = tonumber(row.totalScore) or 0
				break
			end
		end
	end
	statXPLabel.Text = tostring(localScore)

	resultRewardLabel.Text = ""
	resultNextLabel.Text = string.format(
		"Next round in about %ds",
		math.max(0, math.floor(tonumber(data.nextRoundSeconds) or 8))
	)
	if type(data.mvp) == "table" then
		local mvpName  = type(data.mvp.name) == "string" and data.mvp.name or "Unknown"
		local mvpRole  = type(data.mvp.role) == "string" and data.mvp.role or "None"
		local mvpScore = tonumber(data.mvp.totalScore) or 0
		resultMvpLabel.Text = string.format("MVP: %s (%s)  %d", mvpName, mvpRole, mvpScore)
	end
	if type(data.players) == "table" then
		local lines = {}
		for i = 1, math.min(3, #data.players) do
			local row = data.players[i]
			local name  = type(row.name) == "string" and row.name or "Player"
			local score = tonumber(row.totalScore) or 0
			table.insert(lines, string.format("%d. %s - %d", i, name, score))
		end
		local personal = nil
		for _, row in ipairs(data.players) do
			if tonumber(row.userId) == localPlayer.UserId then
				personal = row
				break
			end
		end
		if personal and type(personal.stats) == "table" then
			table.insert(lines, string.format(
				"You: %d pts | Seals %d | Rescues %d | Catches %d",
				tonumber(personal.totalScore) or 0,
				tonumber(personal.stats.sealsCompleted) or 0,
				tonumber(personal.stats.rescuesCompleted) or 0,
				tonumber(personal.stats.catches) or 0
			))
		end
		if type(data.heroMoments) == "table" and #data.heroMoments > 0 then
			local momentParts = {}
			for _, m in ipairs(data.heroMoments) do
				if type(m.playerName) == "string" then
					local val = m.value and (" x" .. tostring(m.value)) or ""
					table.insert(momentParts, m.title .. ": " .. m.playerName .. val)
				end
			end
			if #momentParts > 0 then
				table.insert(lines, table.concat(momentParts, " | "))
			end
		end
		resultBoardLabel.Text = table.concat(lines, "\n")
	end

	accentLine.BackgroundColor3 = accentColor
	if resultStroke then
		resultStroke.Color = accentColor
		resultStroke.Transparency = 0.35
	end

	roundResultsOverlay.Visible = true
	resultPanel.Visible = true
	resultPanelShadow.Visible = true
	roundResultsOverlay.BackgroundTransparency = 1
	resultPanel.BackgroundTransparency = 0.1
	resultPanelShadow.BackgroundTransparency = 1
	resultPanel.Position = UDim2.new(0.5, -280, 0.5, -200)
	accentLine.Size = UDim2.fromOffset(0, 2)

	tweenIn(roundResultsOverlay, "BackgroundTransparency", 0.45, 0.35)
	tweenIn(resultPanel, "Position", UDim2.new(0.5, -280, 0.5, -160), 0.4,
		Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	task.delay(0.4, function()
		if accentLine.Parent then
			tweenIn(accentLine, "Size", UDim2.fromOffset(400, 2), 0.5)
		end
	end)
	task.delay(Constants.RESULTS_DISPLAY_SECONDS or 8, function()
		if roundResultVisible then
			ResultsController.Hide()
		end
	end)
end

return ResultsController
