-- CoreHudController: timer, role badge, phase/directive/hint labels, proximity dot.
-- Owns THE single persistent RunService.Heartbeat for the entire HUD.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local CoreHudController = {}

local sharedHud = nil
local killFeed = nil
local guardianHud = nil
local thiefHud = nil
local objectiveHud = nil

-- Private UI
local timerPanel, timerShadow, timerText, timerTitle, timerStroke
local roleBadge, roleShadow, roleDot, roleText
local phaseLabel, objectiveDirectiveLabel, interactionHintLabel
local proximity

-- Private state
local lastPromptScanAt = 0
local cachedInteractionHint = nil

local function formatTime(secs)
	local m = math.floor(math.max(secs, 0) / 60)
	local s = math.floor(math.max(secs, 0) % 60)
	return string.format("%d:%02d", m, s)
end

function CoreHudController.Init(sh, kf, gh, th, oh)
	sharedHud = sh
	killFeed = kf
	guardianHud = gh
	thiefHud = th
	objectiveHud = oh

	local COLORS = sh.COLORS
	local gui = sh.gui
	local makePanel = sh.makePanel
	local makeShadow = sh.makeShadow
	local makeLabel = sh.makeLabel
	local tweenIn = sh.tweenIn
	local localPlayer = sh.localPlayer

	timerPanel = makePanel(UDim2.fromOffset(160, 56), UDim2.new(0.5, -80, 0, -20), gui, 0.2)
	timerShadow = makeShadow(timerPanel)
	timerPanel.Visible = false
	timerShadow.Visible = false

	timerStroke = timerPanel:FindFirstChildOfClass("UIStroke")
	if timerStroke then
		timerStroke.Color = COLORS.teal
		timerStroke.Transparency = 0.4
	end

	timerTitle = makeLabel("TIME REMAINING", Enum.Font.GothamBold, COLORS.grey, timerPanel)
	timerTitle.Size = UDim2.new(1, 0, 0, 14)
	timerTitle.TextSize = 11
	timerTitle.Position = UDim2.fromOffset(0, 2)

	timerText = makeLabel("8:00", Enum.Font.GothamBlack, COLORS.white, timerPanel)
	timerText.Size = UDim2.new(1, 0, 1, -8)
	timerText.Position = UDim2.fromOffset(0, 8)
	timerText.TextSize = 30

	roleBadge = makePanel(UDim2.fromOffset(140, 36), UDim2.new(0, -180, 0, 16), gui, 0.2)
	roleShadow = makeShadow(roleBadge)
	roleBadge.Visible = false
	roleShadow.Visible = false
	roleDot = Instance.new("Frame")
	roleDot.Size = UDim2.fromOffset(10, 10)
	roleDot.Position = UDim2.fromOffset(12, 13)
	roleDot.BorderSizePixel = 0
	roleDot.Parent = roleBadge
	local roleDotCorner = Instance.new("UICorner")
	roleDotCorner.CornerRadius = UDim.new(1, 0)
	roleDotCorner.Parent = roleDot
	roleText = makeLabel("ROLE", Enum.Font.GothamBold, COLORS.white, roleBadge)
	roleText.Size = UDim2.new(1, -28, 1, 0)
	roleText.Position = UDim2.fromOffset(24, 0)
	roleText.TextSize = 18
	roleText.TextXAlignment = Enum.TextXAlignment.Left

	objectiveDirectiveLabel = Instance.new("TextLabel")
	objectiveDirectiveLabel.Parent = gui
	objectiveDirectiveLabel.Size = UDim2.fromOffset(280, 20)
	objectiveDirectiveLabel.Position = UDim2.new(0.5, -140, 0, 80)
	objectiveDirectiveLabel.BackgroundTransparency = 1
	objectiveDirectiveLabel.Font = Enum.Font.GothamBold
	objectiveDirectiveLabel.TextSize = 13
	objectiveDirectiveLabel.TextColor3 = COLORS.grey
	objectiveDirectiveLabel.TextXAlignment = Enum.TextXAlignment.Center
	objectiveDirectiveLabel.Text = ""
	objectiveDirectiveLabel.Visible = false
	objectiveDirectiveLabel.ZIndex = 5

	phaseLabel = Instance.new("TextLabel")
	phaseLabel.Parent = gui
	phaseLabel.Size = UDim2.fromOffset(280, 18)
	phaseLabel.Position = UDim2.new(0.5, -140, 0, 98)
	phaseLabel.BackgroundTransparency = 1
	phaseLabel.Font = Enum.Font.GothamBold
	phaseLabel.TextSize = 12
	phaseLabel.TextColor3 = COLORS.teal
	phaseLabel.TextXAlignment = Enum.TextXAlignment.Center
	phaseLabel.Text = ""
	phaseLabel.Visible = false
	phaseLabel.ZIndex = 5

	interactionHintLabel = Instance.new("TextLabel")
	interactionHintLabel.Parent = gui
	interactionHintLabel.Size = UDim2.fromOffset(320, 22)
	interactionHintLabel.Position = UDim2.new(0.5, -160, 1, -84)
	interactionHintLabel.BackgroundTransparency = 1
	interactionHintLabel.Font = Enum.Font.GothamBold
	interactionHintLabel.TextSize = 14
	interactionHintLabel.TextColor3 = COLORS.teal
	interactionHintLabel.TextXAlignment = Enum.TextXAlignment.Center
	interactionHintLabel.Text = ""
	interactionHintLabel.Visible = false
	interactionHintLabel.ZIndex = 6

	proximity = Instance.new("Frame")
	proximity.Size = UDim2.fromOffset(60, 60)
	proximity.AnchorPoint = Vector2.new(0.5, 0.5)
	proximity.BackgroundColor3 = COLORS.red
	proximity.BackgroundTransparency = 0.4
	proximity.Visible = false
	proximity.Parent = gui
	local proxCorner = Instance.new("UICorner")
	proxCorner.CornerRadius = UDim.new(1, 0)
	proxCorner.Parent = proximity

	-- THE single persistent Heartbeat
	RunService.Heartbeat:Connect(function()
		if not sharedHud.getIsRoundActive() then return end

		local role  = localPlayer:GetAttribute("Role")
		local state = localPlayer:GetAttribute("RoundState")
		local remain = math.max(0, sharedHud.getRoundEndTime() - os.clock())
		timerText.Text = formatTime(remain)

		if remain <= 30 then
			if math.floor(os.clock() * 2) % 2 == 0 then
				timerText.TextColor3 = COLORS.red
			else
				timerText.TextColor3 = COLORS.white
			end
			if timerStroke then timerStroke.Color = COLORS.red end
		elseif remain <= 60 then
			timerText.TextColor3 = COLORS.red
			if timerStroke then
				timerStroke.Color = COLORS.red
				timerStroke.Transparency = 0.2 + ((math.sin(os.clock() * 6) + 1) * 0.15)
			end
		else
			timerText.TextColor3 = COLORS.white
			if timerStroke then
				timerStroke.Color = COLORS.teal
				timerStroke.Transparency = 0.4
			end
		end

		-- Thief→Guardian proximity arrow
		if role == "Thief" then
			local myChar = localPlayer.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local guardian
			for _, p in ipairs(sharedHud.Players:GetPlayers()) do
				if p:GetAttribute("Role") == "Guardian" then
					guardian = p
					break
				end
			end
			local gRoot = guardian and guardian.Character and guardian.Character:FindFirstChild("HumanoidRootPart")
			if myRoot and gRoot then
				local vec  = gRoot.Position - myRoot.Position
				local dist = vec.Magnitude
				if dist <= Constants.THIEF_GUARDIAN_PROXIMITY_RADIUS then
					local cam = workspace.CurrentCamera
					if cam then
						local look  = cam.CFrame.LookVector
						local right = cam.CFrame.RightVector
						local f  = look:Dot(vec.Unit)
						local r  = right:Dot(vec.Unit)
						local sx = math.clamp(0.5 + r * 0.45, 0.08, 0.92)
						local sy = math.clamp(0.5 - f * 0.45, 0.08, 0.92)
						proximity.Position = UDim2.new(sx, 0, sy, 0)
						proximity.Visible = true
						local pulse = 0.9 + ((math.sin(os.clock() * math.pi * 2) + 1) * 0.05)
						proximity.Size = UDim2.fromOffset(60 * pulse, 60 * pulse)
					end
				else
					proximity.Visible = false
				end
			else
				proximity.Visible = false
			end
		else
			proximity.Visible = false
		end

		-- Guardian ability line update
		if role == "Guardian" then
			guardianHud.UpdateAbilityLine()
		end

		-- Interaction hint (throttled)
		if state == "OutOfRound" or state == "Escaped" or state == "Eliminated" then
			interactionHintLabel.Visible = false
			cachedInteractionHint = nil
		else
			if os.clock() - lastPromptScanAt >= Constants.HUD_PROMPT_SCAN_INTERVAL then
				lastPromptScanAt = os.clock()
				local root = sharedHud.getRootPart(localPlayer)
				local hint = nil
				if role == "Thief" then
					local hasIdol = localPlayer:GetAttribute("HasIdol") == true
					if hasIdol and sharedHud.isNearExtract(root) then
						hint = "Hold E: Extract idol"
					elseif not hasIdol and sharedHud.isNearCagedTeammate(root) then
						hint = "Hold E: Rescue teammate"
					elseif sharedHud.isNearIncompleteObjective(root) then
						hint = "Hold E: Break seal"
					elseif not hasIdol and sharedHud.isIdolAvailableNear(root) then
						hint = "Press E: Pick up idol"
					end
				elseif role == "Guardian" then
					local catchHint = guardianHud.GetCatchPromptText()
					if type(catchHint) == "string" and #catchHint > 0 then
						hint = catchHint
					elseif sharedHud.isNearCagedTeammate(root) then
						hint = "Guard the cage"
					elseif sharedHud.isNearIncompleteObjective(root) then
						hint = "Pressure the seals"
					else
						hint = "Shift Rush | Q Reveal | R Roar"
					end
				end
				cachedInteractionHint = hint
			end
			if cachedInteractionHint and #cachedInteractionHint > 0 then
				interactionHintLabel.Text = cachedInteractionHint
				interactionHintLabel.Visible = true
			else
				interactionHintLabel.Visible = false
			end
		end
	end)

	-- Misc optional remotes that CoreHud handles
	local co = sh.connectOptional
	local Remotes = sh.Remotes

	co(Remotes.Names.PingFailed, function(reason)
		sh.showFailure(reason == "on_cooldown" and "cooldown" or reason)
	end)

	co(Remotes.Names.AFKWarning, function(message)
		killFeed.Add(type(message) == "string" and message or "Move or act to stay in the round.")
	end)

	co(Remotes.Names.PlayerEliminated, function(userId, playerName)
		local name = type(playerName) == "string" and playerName or "A thief"
		killFeed.Add(name .. " was eliminated")
		if tonumber(userId) == localPlayer.UserId then
			roleText.Text = "ELIMINATED"
			objectiveDirectiveLabel.Text = "ELIMINATED — spectating until next round"
			objectiveDirectiveLabel.Visible = true
			interactionHintLabel.Visible = false
		end
	end)
end

function CoreHudController.Show()
	local tweenIn = sharedHud.tweenIn
	roleBadge.Visible = true
	roleShadow.Visible = true
	roleBadge.Position = UDim2.new(0, -180, 0, 16)
	tweenIn(roleBadge, "Position", UDim2.new(0, 16, 0, 16), 0.25)
	timerPanel.Visible = true
	timerShadow.Visible = true
	timerPanel.Position = UDim2.new(0.5, -80, 0, -20)
	tweenIn(timerPanel, "Position", UDim2.new(0.5, -80, 0, 16), 0.25)
	phaseLabel.Visible = true
end

function CoreHudController.Hide()
	roleBadge.Visible = false
	roleShadow.Visible = false
	timerPanel.Visible = false
	timerShadow.Visible = false
	-- Hide panels owned by other controllers
	objectiveHud.SetSealPanelVisible(false)
	thiefHud.HideAll()
	guardianHud.SetPanelsForRole(false)
	proximity.Visible = false
	phaseLabel.Visible = false
end

function CoreHudController.SetRole(role)
	local COLORS = sharedHud.COLORS
	if role == "Guardian" then
		roleText.Text = "GUARDIAN"
		roleText.TextColor3 = COLORS.red
		roleDot.BackgroundColor3 = COLORS.red
		local st = roleBadge:FindFirstChildOfClass("UIStroke")
		if st then st.Color = COLORS.red st.Transparency = 0.35 end
		objectiveHud.SetSealPanelVisible(false)
		thiefHud.SetPanelsForRole("Guardian")
		guardianHud.SetPanelsForRole(true)
		guardianHud.SetDirective("Stop the thieves. Shift Rush | Q Reveal | R Roar | E Catch")
	elseif role == "Thief" then
		roleText.Text = "THIEF"
		roleText.TextColor3 = COLORS.teal
		roleDot.BackgroundColor3 = COLORS.teal
		local st = roleBadge:FindFirstChildOfClass("UIStroke")
		if st then st.Color = COLORS.teal st.Transparency = 0.35 end
		objectiveHud.SetSealPanelVisible(true)
		thiefHud.SetPanelsForRole("Thief")
		guardianHud.SetPanelsForRole(false)
	else
		objectiveHud.SetSealPanelVisible(false)
		thiefHud.SetPanelsForRole("none")
		guardianHud.SetPanelsForRole(false)
	end
end

function CoreHudController.SetPhase(text)
	if type(text) ~= "string" then text = "" end
	phaseLabel.Text = text
	phaseLabel.Visible = sharedHud.getIsRoundActive() and (#text > 0)
end

function CoreHudController.SetDirective(text)
	objectiveDirectiveLabel.Text = text or ""
end

function CoreHudController.SetDirectiveVisible(v)
	objectiveDirectiveLabel.Visible = v
end

function CoreHudController.SetHintVisible(v)
	interactionHintLabel.Visible = v
end

-- Override role text (for eliminated/caged/waiting display)
function CoreHudController.SetRoleOverride(text, color)
	roleText.Text = text
	if color then roleText.TextColor3 = color end
end

function CoreHudController.SetTimerText(text)
	timerText.Text = text
end

return CoreHudController
