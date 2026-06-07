-- IdolExtractController: idol status panel, extract progress bar, idol/extract remotes.

local IdolExtractController = {}

local sharedHud = nil
local killFeed = nil
local guardianHud = nil
local coreHud = nil  -- injected after CoreHud.Init via SetCoreHud()

-- Private UI
local idolStatusPanel, idolStatusShadow
local idolTitleLabel, idolStatusLabel, carrierLabel
local extractProgressBack, extractProgressFill, extractProgressLabel

local function setIdolPanelVisible(visible)
	idolStatusPanel.Visible = visible
	idolStatusShadow.Visible = visible
end

-- Internal implementation used by both public API and remote handlers.
-- Calls to coreHud are guarded since coreHud is injected after Init.
local function _setVaultOpenUI()
	sharedHud.setVaultOpen(true)
	idolStatusLabel.Text = "VAULT OPEN"
	carrierLabel.Text = "Find the idol"
	setIdolPanelVisible(true)
	killFeed.Add("Vault open. Steal the idol.")
	if coreHud then
		coreHud.SetPhase("Vault Open")
		local role = sharedHud.localPlayer:GetAttribute("Role")
		if role == "Thief" then
			coreHud.SetDirective("Vault open. Steal the idol.")
		elseif role == "Guardian" then
			coreHud.SetDirective("Vault open. Defend the idol.")
		end
	end
end

local function _setIdolCarrierUI(carrierUserId, carrierName)
	sharedHud.setIdolTaken(true)
	sharedHud.setIdolCarrierUserId(carrierUserId)
	local displayName = (type(carrierName) == "string" and #carrierName > 0) and carrierName or "Carrier"
	setIdolPanelVisible(true)
	idolStatusLabel.Text = "IDOL TAKEN"
	carrierLabel.Text = "Carrier: " .. displayName
	killFeed.Add(displayName .. " has the idol.")
	if coreHud then
		coreHud.SetPhase("Idol Taken")
		local localPlayer = sharedHud.localPlayer
		local role = localPlayer:GetAttribute("Role")
		if carrierUserId == localPlayer.UserId then
			coreHud.SetDirective("You have the idol. Get to extraction.")
		elseif role == "Guardian" then
			coreHud.SetDirective(displayName .. " has the idol. Hunt them.")
		elseif role == "Thief" then
			coreHud.SetDirective(displayName .. " has the idol. Protect them.")
		end
	end
end

function IdolExtractController.Init(sh, kf, gh)
	sharedHud = sh
	killFeed = kf
	guardianHud = gh

	local COLORS = sh.COLORS
	local gui = sh.gui
	local makePanel = sh.makePanel
	local makeShadow = sh.makeShadow
	local makeLabel = sh.makeLabel

	idolStatusPanel = makePanel(
		UDim2.fromOffset(220, 80),
		UDim2.new(0.5, -110, 1, -148),
		gui, 0.2
	)
	idolStatusShadow = makeShadow(idolStatusPanel)
	idolStatusPanel.Visible = false
	idolStatusShadow.Visible = false

	local idolPanelStroke = idolStatusPanel:FindFirstChildOfClass("UIStroke")
	if idolPanelStroke then
		idolPanelStroke.Color = COLORS.teal
		idolPanelStroke.Transparency = 0.35
	end

	idolTitleLabel = makeLabel("IDOL", Enum.Font.GothamBold, COLORS.grey, idolStatusPanel)
	idolTitleLabel.Size = UDim2.new(1, 0, 0, 14)
	idolTitleLabel.TextSize = 11

	idolStatusLabel = makeLabel("VAULT LOCKED", Enum.Font.GothamBold, COLORS.white, idolStatusPanel)
	idolStatusLabel.Size = UDim2.new(1, 0, 0, 18)
	idolStatusLabel.Position = UDim2.fromOffset(0, 14)
	idolStatusLabel.TextSize = 14

	carrierLabel = makeLabel("", Enum.Font.Gotham, COLORS.grey, idolStatusPanel)
	carrierLabel.Size = UDim2.new(1, 0, 0, 14)
	carrierLabel.Position = UDim2.fromOffset(0, 32)
	carrierLabel.TextSize = 12

	extractProgressBack = Instance.new("Frame")
	extractProgressBack.Size = UDim2.new(1, -16, 0, 8)
	extractProgressBack.Position = UDim2.fromOffset(8, 50)
	extractProgressBack.BackgroundColor3 = COLORS.panelSoft
	extractProgressBack.BorderSizePixel = 0
	extractProgressBack.Visible = false
	extractProgressBack.Parent = idolStatusPanel
	local epbCorner = Instance.new("UICorner")
	epbCorner.CornerRadius = UDim.new(0, 4)
	epbCorner.Parent = extractProgressBack

	extractProgressFill = Instance.new("Frame")
	extractProgressFill.Size = UDim2.fromScale(0, 1)
	extractProgressFill.BackgroundColor3 = COLORS.teal
	extractProgressFill.BorderSizePixel = 0
	extractProgressFill.Parent = extractProgressBack
	local epfCorner = Instance.new("UICorner")
	epfCorner.CornerRadius = UDim.new(0, 4)
	epfCorner.Parent = extractProgressFill

	extractProgressLabel = makeLabel("", Enum.Font.GothamBold, COLORS.teal, idolStatusPanel)
	extractProgressLabel.Size = UDim2.new(1, 0, 0, 12)
	extractProgressLabel.Position = UDim2.fromOffset(0, 62)
	extractProgressLabel.TextSize = 10

	-- Remote connections
	local co = sh.connectOptional
	local Remotes = sh.Remotes

	co(Remotes.Names.VaultOpened, function()
		if not sharedHud.getVaultOpen() then
			_setVaultOpenUI()
		end
		guardianHud.SetDirective("STOP THE ESCAPE")
		guardianHud.SetAlert("The vault is open", 4)
	end)

	co(Remotes.Names.IdolAvailable, function()
		IdolExtractController.SetAvailableUI()
	end)

	co(Remotes.Names.IdolPickedUp, function(carrierUserId, carrierName)
		_setIdolCarrierUI(carrierUserId, carrierName)
		guardianHud.SetCarrier(carrierUserId, carrierName)
	end)

	co(Remotes.Names.IdolCarrierChanged, function(carrierUserId, carrierName)
		if carrierUserId ~= nil then
			_setIdolCarrierUI(carrierUserId, carrierName)
			guardianHud.SetCarrier(carrierUserId, carrierName)
		else
			guardianHud.ClearCarrier()
		end
	end)

	co(Remotes.Names.IdolDropped, function()
		IdolExtractController.SetDroppedUI()
		guardianHud.ClearCarrier()
		guardianHud.SetDirective("RECOVER CONTROL")
		guardianHud.SetAlert("Idol dropped. Recover it.", 3)
		if coreHud then
			local role = sharedHud.localPlayer:GetAttribute("Role")
			if role == "Thief" then
				coreHud.SetDirective("Idol dropped. Recover it.")
			elseif role == "Guardian" then
				coreHud.SetDirective("Idol dropped. Recover control.")
			end
		end
	end)

	co(Remotes.Names.ExtractStarted, function()
		IdolExtractController.SetExtractProgressUI(0)
		if coreHud then
			local role = sharedHud.localPlayer:GetAttribute("Role")
			if role == "Thief" then
				coreHud.SetDirective("Extracting...")
			elseif role == "Guardian" then
				coreHud.SetDirective("Stop the extraction.")
			end
		end
	end)

	co(Remotes.Names.ExtractProgress, function(progress)
		IdolExtractController.SetExtractProgressUI(progress)
	end)

	co(Remotes.Names.ExtractCanceled, function(reason)
		IdolExtractController.SetExtractProgressUI(0)
		sharedHud.showFailure(reason or "interrupted")
	end)

	co(Remotes.Names.ExtractCompleted, function()
		IdolExtractController.SetExtractProgressUI(1)
		idolStatusLabel.Text = "EXTRACTED"
		carrierLabel.Text = "Escape complete"
		if coreHud then
			coreHud.SetPhase("Heist Complete")
		end
	end)

	co(Remotes.Names.IdolFailed, function(reason)
		sharedHud.showFailure(reason)
	end)

	co(Remotes.Names.ExtractFailed, function(reason)
		sharedHud.showFailure(reason)
		IdolExtractController.SetExtractProgressUI(0)
	end)
end

function IdolExtractController.SetCoreHud(ch)
	coreHud = ch
end

function IdolExtractController.SetPanelVisible(visible)
	setIdolPanelVisible(visible)
end

function IdolExtractController.SetVaultOpenUI()
	_setVaultOpenUI()
end

function IdolExtractController.SetAvailableUI()
	setIdolPanelVisible(true)
	idolStatusLabel.Text = "IDOL AVAILABLE"
	carrierLabel.Text = "Take the idol"
	if coreHud then
		coreHud.SetPhase("Idol Available")
	end
end

function IdolExtractController.SetCarrierUI(carrierUserId, carrierName)
	_setIdolCarrierUI(carrierUserId, carrierName)
end

function IdolExtractController.SetDroppedUI()
	sharedHud.setIdolTaken(false)
	sharedHud.setIdolCarrierUserId(nil)
	setIdolPanelVisible(true)
	idolStatusLabel.Text = "IDOL DROPPED"
	carrierLabel.Text = "Recover the idol"
	if coreHud then
		coreHud.SetPhase("Idol Dropped")
	end
	sharedHud.setExtractProgress(0)
	extractProgressFill.Size = UDim2.fromScale(0, 1)
	extractProgressBack.Visible = false
	extractProgressLabel.Text = ""
end

function IdolExtractController.SetExtractProgressUI(progress)
	progress = math.clamp(tonumber(progress) or 0, 0, 1)
	sharedHud.setExtractProgress(progress)
	setIdolPanelVisible(true)
	extractProgressBack.Visible = true
	extractProgressFill.Size = UDim2.fromScale(progress, 1)
	if progress > 0 then
		extractProgressLabel.Text = "EXTRACTING " .. math.floor(progress * 100) .. "%"
		if coreHud then coreHud.SetPhase("Extracting") end
	else
		extractProgressLabel.Text = ""
	end
end

function IdolExtractController.SetExtractedUI()
	idolStatusLabel.Text = "EXTRACTED"
	carrierLabel.Text = "Escape complete"
end

function IdolExtractController.HidePanel()
	setIdolPanelVisible(false)
end

function IdolExtractController.Reset()
	sharedHud.setVaultOpen(false)
	sharedHud.setIdolTaken(false)
	sharedHud.setIdolCarrierUserId(nil)
	sharedHud.setExtractProgress(0)
	sharedHud.setLastReportedSealCount(0)
	idolStatusLabel.Text = "VAULT LOCKED"
	carrierLabel.Text = ""
	extractProgressLabel.Text = ""
	extractProgressFill.Size = UDim2.fromScale(0, 1)
	extractProgressBack.Visible = false
	setIdolPanelVisible(false)
end

return IdolExtractController
