-- SharedHud: gui, helpers, COLORS, shared state, proximity utils, failure display.
-- All controllers require this module first; it creates the one ScreenGui.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local Constants = require(ReplicatedStorage:WaitForChild("Constants"))

local SharedHud = {}

SharedHud.localPlayer = localPlayer
SharedHud.Players = Players

SharedHud.COLORS = {
	bg        = Color3.fromRGB(8, 10, 16),
	panel     = Color3.fromRGB(12, 16, 24),
	panelSoft = Color3.fromRGB(18, 24, 34),
	white     = Color3.fromRGB(245, 248, 255),
	grey      = Color3.fromRGB(150, 165, 185),
	teal      = Color3.fromRGB(120, 220, 255),
	tealDeep  = Color3.fromRGB(40, 150, 220),
	red       = Color3.fromRGB(230, 65, 75),
	warning   = Color3.fromRGB(255, 150, 80),
	gold      = Color3.fromRGB(220, 175, 55),
}

function SharedHud.tweenIn(element, property, targetValue, duration, style, direction)
	local props = {}
	props[property] = targetValue
	local t = TweenService:Create(
		element,
		TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

function SharedHud.makePanel(size, position, parent, transparency)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = SharedHud.COLORS.panel
	f.BackgroundTransparency = transparency or 0.2
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Transparency = 0.85
	s.Thickness = 1
	s.Parent = f
	local p = Instance.new("UIPadding")
	p.PaddingTop    = UDim.new(0, 8)
	p.PaddingBottom = UDim.new(0, 8)
	p.PaddingLeft   = UDim.new(0, 8)
	p.PaddingRight  = UDim.new(0, 8)
	p.Parent = f
	return f
end

function SharedHud.makeShadow(frame)
	local sh = Instance.new("Frame")
	sh.Size = frame.Size
	sh.Position = frame.Position + UDim2.fromOffset(2, 2)
	sh.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	sh.BackgroundTransparency = 0.6
	sh.ZIndex = frame.ZIndex - 1
	sh.Parent = frame.Parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = sh
	return sh
end

function SharedHud.makeLabel(text, font, textColor, parent)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = font
	l.TextColor3 = textColor
	l.Parent = parent
	return l
end

-- The ONE ScreenGui for the entire HUD. All controllers parent their frames here.
local gui = Instance.new("ScreenGui")
gui.Name = "RoundUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui
SharedHud.gui = gui

-- Shared mutable state (cross-controller)
local isRoundActive = false
local roundEndTime = 0
local duration = 0
local sealsBroken = 0
local vaultOpen = false
local idolCarrierUserId = nil
local idolTaken = false
local extractProgress = 0
local lastReportedSealCount = 0
local thievesCaughtByGuardian = 0
local lastFailureAt = {}

function SharedHud.getIsRoundActive()            return isRoundActive end
function SharedHud.setIsRoundActive(v)           isRoundActive = v end
function SharedHud.getRoundEndTime()             return roundEndTime end
function SharedHud.setRoundEndTime(v)            roundEndTime = v end
function SharedHud.getDuration()                 return duration end
function SharedHud.setDuration(v)                duration = v end
function SharedHud.getSealsBroken()              return sealsBroken end
function SharedHud.setSealsBroken(v)             sealsBroken = v end
function SharedHud.getVaultOpen()                return vaultOpen end
function SharedHud.setVaultOpen(v)               vaultOpen = v end
function SharedHud.getIdolCarrierUserId()        return idolCarrierUserId end
function SharedHud.setIdolCarrierUserId(v)       idolCarrierUserId = v end
function SharedHud.getIdolTaken()                return idolTaken end
function SharedHud.setIdolTaken(v)               idolTaken = v end
function SharedHud.getExtractProgress()          return extractProgress end
function SharedHud.setExtractProgress(v)         extractProgress = v end
function SharedHud.getLastReportedSealCount()    return lastReportedSealCount end
function SharedHud.setLastReportedSealCount(v)   lastReportedSealCount = v end
function SharedHud.getThievesCaughtByGuardian()  return thievesCaughtByGuardian end
function SharedHud.setThievesCaughtByGuardian(v) thievesCaughtByGuardian = v end

-- Role helpers
function SharedHud.isGuardianRole()
	return localPlayer:GetAttribute("Role") == "Guardian"
end

function SharedHud.isThiefRole()
	return localPlayer:GetAttribute("Role") == "Thief"
end

-- Proximity helpers
function SharedHud.getRootPart(player)
	local c = player and player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

function SharedHud.isIdolAvailableNear(root)
	if not root then return false end
	local maxDist = Constants.IDOL_INTERACT_DISTANCE or 10
	for _, part in ipairs(CollectionService:GetTagged("Idol")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			local state = part:GetAttribute("IdolState")
			if state ~= "Locked" and state ~= "Carried" then
				if (part.Position - root.Position).Magnitude <= maxDist then
					return true
				end
			end
		end
	end
	return false
end

function SharedHud.isNearExtract(root)
	if not root then return false end
	local maxDist = Constants.EXTRACT_INTERACT_DISTANCE or 14
	for _, part in ipairs(CollectionService:GetTagged("ExtractPoint")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			if (part.Position - root.Position).Magnitude <= maxDist then
				return true
			end
		end
	end
	return false
end

function SharedHud.isNearIncompleteObjective(root)
	if not root then return false end
	local maxDist = Constants.OBJECTIVE_INTERACT_DISTANCE or 12
	for _, part in ipairs(CollectionService:GetTagged("ObjectiveStation")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace)
				and part:GetAttribute("ObjectiveCompleted") ~= true then
			if (part.Position - root.Position).Magnitude <= maxDist then
				return true
			end
		end
	end
	return false
end

function SharedHud.isNearCagedTeammate(root)
	if not root then return false end
	local maxDist = Constants.CAGE_RESCUE_DISTANCE or 12
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer and
				(p:GetAttribute("IsCaged") == true or p:GetAttribute("RoundState") == "Caged") then
			local pRoot = SharedHud.getRootPart(p)
			if pRoot and (pRoot.Position - root.Position).Magnitude <= maxDist then
				return true
			end
		end
	end
	return false
end

-- Failure display (cross-cutting; KillFeed reference injected by bootstrap after KillFeed.Init)
local FAILURE_TEXT = {
	too_far              = "Too far",
	not_eligible         = "Not available",
	already_completed    = "Already complete",
	objective_unbound    = "Seal is not ready",
	vault_not_open       = "Vault is still locked",
	not_carrier          = "You need the idol",
	already_carried      = "Idol already taken",
	idol_unbound         = "Idol is not ready",
	too_far_from_extract = "Too far from extraction",
	no_extract_points    = "No extraction point",
	no_character         = "Not available",
	missing_target       = "No teammate to rescue",
	no_target            = "No teammate to rescue",
	target_not_caged     = "No teammate to rescue",
	cannot_rescue_self   = "Cannot rescue yourself",
	round_inactive       = "Round inactive",
	not_guardian         = "Not available",
	on_cooldown          = "Ability cooling down",
	cooldown             = "Cooling down",
	already_rushing      = "Already rushing",
	no_humanoid          = "Not available",
	interrupted          = "Interrupted",
	moved_away           = "Moved away",
}

function SharedHud.readableFailure(reason)
	if type(reason) ~= "string" or reason == "" then return "Not available" end
	return FAILURE_TEXT[reason] or reason:gsub("_", " ")
end

local _killFeedAdd = nil
function SharedHud.injectKillFeed(fn) _killFeedAdd = fn end

function SharedHud.showFailure(reason)
	local text = SharedHud.readableFailure(reason)
	local now = os.clock()
	if now - (lastFailureAt[text] or 0) < 1.25 then return end
	lastFailureAt[text] = now
	if _killFeedAdd then _killFeedAdd(text) end
end

-- connectOptional: safe wrapper used by every controller for optional remotes.
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
SharedHud.Remotes = Remotes

function SharedHud.connectOptional(name, handler)
	local remote = Remotes.Find(name)
	if remote then
		remote.OnClientEvent:Connect(handler)
	end
end

return SharedHud
