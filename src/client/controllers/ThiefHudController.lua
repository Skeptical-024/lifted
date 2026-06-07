-- ThiefHudController: thief-icon panel (guardian sees it), crouch panel, ThiefCountUpdate.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local ThiefHudController = {}

local sharedHud = nil

-- Private UI
local thiefPanel, thiefShadow, thiefTitle
local thiefIconFrames = {}
local crouchPanel, crouchShadow, crouchText

-- Private state
local totalThiefIcons = 0
local thievesRemaining = 0

function ThiefHudController.Init(sh)
	sharedHud = sh

	local COLORS = sh.COLORS
	local gui = sh.gui
	local makePanel = sh.makePanel
	local makeShadow = sh.makeShadow
	local makeLabel = sh.makeLabel
	local localPlayer = sh.localPlayer

	thiefPanel = makePanel(UDim2.fromOffset(220, 52), UDim2.new(1, -236, 1, -68), gui, 0.2)
	thiefShadow = makeShadow(thiefPanel)
	thiefPanel.Visible = false
	thiefShadow.Visible = false
	local ts = thiefPanel:FindFirstChildOfClass("UIStroke")
	if ts then
		ts.Color = COLORS.red
		ts.Transparency = 0.35
	end
	thiefTitle = makeLabel("THIEVES", Enum.Font.GothamBold, COLORS.grey, thiefPanel)
	thiefTitle.Size = UDim2.new(1, 0, 0, 14)
	thiefTitle.TextSize = 12

	for i = 1, 4 do
		local sq = Instance.new("Frame")
		sq.Size = UDim2.fromOffset(20, 20)
		sq.Position = UDim2.fromOffset(10 + (i - 1) * 28, 24)
		sq.BackgroundColor3 = COLORS.red
		sq.Visible = false
		sq.Parent = thiefPanel
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 5)
		c.Parent = sq
		local t = makeLabel("", Enum.Font.GothamBold, COLORS.white, sq)
		t.Size = UDim2.fromScale(1, 1)
		t.TextSize = 16
		thiefIconFrames[i] = {frame = sq, label = t}
	end

	crouchPanel = makePanel(UDim2.fromOffset(140, 32), UDim2.new(1, -156, 1, -68), gui, 0.2)
	crouchShadow = makeShadow(crouchPanel)
	crouchPanel.Visible = false
	crouchShadow.Visible = false
	crouchText = makeLabel("CROUCHING", Enum.Font.GothamBold, COLORS.teal, crouchPanel)
	crouchText.Size = UDim2.fromScale(1, 1)
	crouchText.TextSize = 14

	-- IsCrouching attribute → show/hide crouch panel
	localPlayer:GetAttributeChangedSignal("IsCrouching"):Connect(function()
		local isCrouching = localPlayer:GetAttribute("IsCrouching") == true
		local role = localPlayer:GetAttribute("Role")
		if role == "Thief" then
			crouchPanel.Visible = isCrouching
			crouchShadow.Visible = isCrouching
			if isCrouching then
				crouchPanel.BackgroundColor3 = Color3.fromRGB(10, 40, 50)
				crouchPanel.BackgroundTransparency = 0.2
			end
		else
			crouchPanel.Visible = false
			crouchShadow.Visible = false
		end
	end)

	-- ThiefCountUpdate
	local thiefCountRemote = Remotes.Client(Remotes.Names.ThiefCountUpdate)
	thiefCountRemote.OnClientEvent:Connect(function(count)
		thievesRemaining = tonumber(count) or 0
		for i, slot in ipairs(thiefIconFrames) do
			if i <= totalThiefIcons and slot.frame.Visible then
				if i <= thievesRemaining then
					slot.frame.BackgroundColor3 = COLORS.red
					slot.label.Text = ""
				else
					slot.frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
					slot.label.Text = "X"
					slot.label.TextColor3 = COLORS.grey
				end
			end
		end
	end)
end

function ThiefHudController.UpdateIconCount(total)
	local COLORS = sharedHud.COLORS
	totalThiefIcons = math.clamp(total or 0, 0, 4)
	for i, slot in ipairs(thiefIconFrames) do
		slot.frame.Visible = i <= totalThiefIcons
		if i <= totalThiefIcons then
			slot.frame.BackgroundColor3 = COLORS.red
			slot.label.Text = ""
		end
	end
end

function ThiefHudController.InferThiefCount()
	local count = 0
	for _, p in ipairs(sharedHud.Players:GetPlayers()) do
		if p:GetAttribute("Role") == "Thief" then
			count += 1
		end
	end
	return count
end

-- Called from CoreHud.SetRole; isGuardian=true shows thiefPanel (guardian sees thief count)
function ThiefHudController.SetPanelsForRole(role)
	local isGuardian = role == "Guardian"
	thiefPanel.Visible = isGuardian
	thiefShadow.Visible = isGuardian
	-- crouchPanel always hidden on role change; restored by IsCrouching attribute
	crouchPanel.Visible = false
	crouchShadow.Visible = false
end

function ThiefHudController.HideAll()
	thiefPanel.Visible = false
	thiefShadow.Visible = false
	crouchPanel.Visible = false
	crouchShadow.Visible = false
end

function ThiefHudController.Reset()
	ThiefHudController.HideAll()
end

return ThiefHudController
