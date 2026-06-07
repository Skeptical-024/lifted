-- GuardianHudController: guardian status panel, rush panel, ability tracking, catch prompt.

local GuardianHudController = {}

local sharedHud = nil
local killFeed = nil

-- Private UI
local guardianStatusPanel, guardianStatusShadow
local guardianTitleLabel, guardianDirectiveLabel, guardianCatchPromptLabel
local guardianRushLabel, guardianCarrierLabel, guardianAlertLabel
local rushPanel, rushShadow, rushLabel, barBg, barFill

-- Private state
local guardianRushReady = true
local guardianCanCatch = false
local guardianTargetName = nil
local guardianCurrentAlert = nil
local guardianCarrierName = nil
local guardianCarrierUserId = nil
local lastObjectiveAlertTime = 0
local guardianAbilityCooldownEnds = { Rush = 0, Reveal = 0, Roar = 0 }

function GuardianHudController.Init(sh, kf)
	sharedHud = sh
	killFeed = kf

	local COLORS = sh.COLORS
	local gui = sh.gui
	local makePanel = sh.makePanel
	local makeShadow = sh.makeShadow
	local makeLabel = sh.makeLabel

	guardianStatusPanel = makePanel(
		UDim2.fromOffset(240, 124),
		UDim2.new(0, 16, 1, -192),
		gui, 0.2
	)
	guardianStatusShadow = makeShadow(guardianStatusPanel)
	guardianStatusPanel.Visible = false
	guardianStatusShadow.Visible = false

	local gspStroke = guardianStatusPanel:FindFirstChildOfClass("UIStroke")
	if gspStroke then
		gspStroke.Color = COLORS.red
		gspStroke.Transparency = 0.35
	end

	guardianTitleLabel = makeLabel("GUARDIAN", Enum.Font.GothamBold, COLORS.red, guardianStatusPanel)
	guardianTitleLabel.Size = UDim2.new(1, 0, 0, 13)
	guardianTitleLabel.TextSize = 11

	guardianDirectiveLabel = makeLabel(
		"Stop the thieves. Shift Rush | Q Reveal | R Roar | E Catch",
		Enum.Font.GothamBold, COLORS.white, guardianStatusPanel
	)
	guardianDirectiveLabel.Size = UDim2.new(1, 0, 0, 18)
	guardianDirectiveLabel.Position = UDim2.fromOffset(0, 14)
	guardianDirectiveLabel.TextSize = 15

	guardianCatchPromptLabel = makeLabel("", Enum.Font.GothamBold, COLORS.teal, guardianStatusPanel)
	guardianCatchPromptLabel.Size = UDim2.new(1, 0, 0, 14)
	guardianCatchPromptLabel.Position = UDim2.fromOffset(0, 34)
	guardianCatchPromptLabel.TextSize = 12

	guardianRushLabel = makeLabel("RUSH READY", Enum.Font.GothamBold, COLORS.grey, guardianStatusPanel)
	guardianRushLabel.Size = UDim2.new(1, 0, 0, 13)
	guardianRushLabel.Position = UDim2.fromOffset(0, 50)
	guardianRushLabel.TextSize = 11

	guardianCarrierLabel = makeLabel("", Enum.Font.Gotham, COLORS.red, guardianStatusPanel)
	guardianCarrierLabel.Size = UDim2.new(1, 0, 0, 14)
	guardianCarrierLabel.Position = UDim2.fromOffset(0, 65)
	guardianCarrierLabel.TextSize = 12

	guardianAlertLabel = makeLabel("", Enum.Font.GothamBold, COLORS.red, guardianStatusPanel)
	guardianAlertLabel.Size = UDim2.new(1, 0, 0, 14)
	guardianAlertLabel.Position = UDim2.fromOffset(0, 82)
	guardianAlertLabel.TextSize = 11

	-- Rush panel (guardian ability cooldown bar)
	rushPanel = makePanel(UDim2.fromOffset(220, 36), UDim2.new(1, -236, 1, -112), gui, 0.2)
	rushShadow = makeShadow(rushPanel)
	rushPanel.Visible = false
	rushShadow.Visible = false
	rushLabel = makeLabel("RUSH", Enum.Font.GothamBold, COLORS.white, rushPanel)
	rushLabel.Size = UDim2.fromOffset(64, 20)
	rushLabel.Position = UDim2.fromOffset(8, 8)
	rushLabel.TextSize = 14
	barBg = Instance.new("Frame")
	barBg.Size = UDim2.fromOffset(136, 12)
	barBg.Position = UDim2.fromOffset(74, 12)
	barBg.BackgroundColor3 = COLORS.panelSoft
	barBg.BorderSizePixel = 0
	barBg.Parent = rushPanel
	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0, 6)
	barBgCorner.Parent = barBg
	barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = COLORS.white
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(0, 6)
	barFillCorner.Parent = barFill

	-- Remote connections
	local co = sh.connectOptional
	local Remotes = sh.Remotes

	co(Remotes.Names.GuardianAbilityCooldown, function(abilityName, seconds)
		if type(abilityName) ~= "string" then return end
		local secs = math.max(0, tonumber(seconds) or 0)
		guardianAbilityCooldownEnds[abilityName] = os.clock() + secs
		GuardianHudController.UpdateAbilityLine()
	end)

	co(Remotes.Names.GuardianRushStarted, function()
		GuardianHudController.SetAlert("Rush", 1.5)
	end)

	co(Remotes.Names.GuardianRushFailed, function(reason)
		GuardianHudController.SetAlert(sh.readableFailure(reason), 2)
		sh.showFailure(reason)
	end)

	co(Remotes.Names.GuardianCatchFailed, function(reason)
		sh.showFailure(reason)
	end)

	co(Remotes.Names.GuardianRevealStarted, function(revealed)
		local count = type(revealed) == "table" and #revealed or 0
		GuardianHudController.SetAlert("Reveal: " .. tostring(count) .. " thieves", 2)
	end)

	co(Remotes.Names.GuardianRevealFailed, function(reason)
		GuardianHudController.SetAlert(sh.readableFailure(reason), 2)
		sh.showFailure(reason)
	end)

	co(Remotes.Names.GuardianRoarActivated, function(_, _, affectedCount)
		GuardianHudController.SetAlert("Roar hit " .. tostring(tonumber(affectedCount) or 0), 2)
	end)

	co(Remotes.Names.GuardianRoarFailed, function(reason)
		GuardianHudController.SetAlert(sh.readableFailure(reason), 2)
		sh.showFailure(reason)
	end)

	-- Dead remotes (not in registry; connectOptional returns nil silently)
	co("GuardianCatchPrompt", function(canCatch, targetName)
		GuardianHudController.SetCatchPrompt(canCatch, targetName)
	end)

	co("GuardianAlert", function(text, dur)
		GuardianHudController.SetAlert(text, dur)
	end)
end

function GuardianHudController.SetVisible(visible)
	if visible and not sharedHud.isGuardianRole() then return end
	guardianStatusPanel.Visible = visible
	guardianStatusShadow.Visible = visible
end

function GuardianHudController.SetPanelsForRole(isGuardian)
	guardianStatusPanel.Visible = isGuardian
	guardianStatusShadow.Visible = isGuardian
	rushPanel.Visible = isGuardian
	rushShadow.Visible = isGuardian
end

function GuardianHudController.Reset()
	guardianRushReady = true
	guardianCanCatch = false
	guardianTargetName = nil
	guardianCurrentAlert = nil
	guardianCarrierName = nil
	guardianCarrierUserId = nil
	guardianDirectiveLabel.Text = "Stop the thieves. Shift Rush | Q Reveal | R Roar | E Catch"
	guardianCatchPromptLabel.Text = ""
	guardianAbilityCooldownEnds.Rush = 0
	guardianAbilityCooldownEnds.Reveal = 0
	guardianAbilityCooldownEnds.Roar = 0
	guardianRushLabel.Text = "Rush READY | Reveal READY | Roar READY"
	guardianAlertLabel.Text = ""
	guardianCarrierLabel.Text = ""
	guardianStatusPanel.Visible = false
	guardianStatusShadow.Visible = false
end

function GuardianHudController.SetDirective(text)
	if not sharedHud.isGuardianRole() then return end
	if type(text) == "string" and #text > 0 then
		guardianDirectiveLabel.Text = text
	end
end

function GuardianHudController.UpdateAbilityLine()
	if not sharedHud.isGuardianRole() then return end
	local now = os.clock()
	local parts = {}
	for _, ability in ipairs({"Rush", "Reveal", "Roar"}) do
		local remaining = math.max(0, (guardianAbilityCooldownEnds[ability] or 0) - now)
		if remaining > 0 then
			table.insert(parts, string.format("%s %.0fs", ability, remaining))
		else
			table.insert(parts, ability .. " READY")
		end
	end
	guardianRushLabel.Text = table.concat(parts, " | ")
end

function GuardianHudController.SetAlert(text, dur)
	if not sharedHud.isGuardianRole() then return end
	if type(text) ~= "string" or #text == 0 then return end
	guardianAlertLabel.Text = text
	guardianCurrentAlert = text
	lastObjectiveAlertTime = os.clock()
	if type(dur) == "number" and dur > 0 then
		local captured = text
		task.delay(dur, function()
			if guardianAlertLabel.Parent and guardianAlertLabel.Text == captured then
				guardianAlertLabel.Text = ""
			end
		end)
	end
end

function GuardianHudController.SetCatchPrompt(canCatch, targetName)
	if not sharedHud.isGuardianRole() then return end
	guardianCanCatch = canCatch == true
	if guardianCanCatch then
		local name = (type(targetName) == "string" and #targetName > 0) and targetName or "thief"
		guardianTargetName = name
		guardianCatchPromptLabel.Text = "Press E to catch " .. name
	else
		guardianCatchPromptLabel.Text = ""
		guardianTargetName = nil
	end
end

function GuardianHudController.GetCatchPromptText()
	return guardianCatchPromptLabel.Text
end

function GuardianHudController.SetCarrier(carrierUserId, carrierName)
	if not sharedHud.isGuardianRole() then return end
	guardianCarrierUserId = carrierUserId
	guardianCarrierName = carrierName
	local displayName = (type(carrierName) == "string" and #carrierName > 0) and carrierName or "Carrier"
	guardianCarrierLabel.Text = "Carrier: " .. displayName
	GuardianHudController.SetDirective(displayName .. " has the idol. Hunt them.")
	GuardianHudController.SetAlert(displayName .. " has the idol.", 4)
end

function GuardianHudController.ClearCarrier()
	if not sharedHud.isGuardianRole() then return end
	guardianCarrierUserId = nil
	guardianCarrierName = nil
	guardianCarrierLabel.Text = ""
end

function GuardianHudController.SetAbilityCooldownEnd(ability, clockTime)
	guardianAbilityCooldownEnds[ability] = clockTime
end

return GuardianHudController
