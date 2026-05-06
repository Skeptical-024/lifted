-- MinimapClient v1

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "MinimapUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local map = Instance.new("Frame")
map.Size = UDim2.fromOffset(140, 140)
map.Position = UDim2.new(1, -156, 1, -156)
map.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
map.BackgroundTransparency = 0.25
map.Parent = gui

local mapCorner = Instance.new("UICorner")
mapCorner.CornerRadius = UDim.new(0, 8)
mapCorner.Parent = map

local mapStroke = Instance.new("UIStroke")
mapStroke.Color = Color3.fromRGB(255, 255, 255)
mapStroke.Transparency = 0.8
mapStroke.Parent = map

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Size = UDim2.fromOffset(140, 14)
label.Position = UDim2.fromOffset(0, 0)
label.Font = Enum.Font.GothamBold
label.Text = "MAP"
label.TextColor3 = Color3.fromRGB(170, 170, 178)
label.TextSize = 12
label.Parent = map

local dotsFolder = Instance.new("Folder")
dotsFolder.Name = "Dots"
dotsFolder.Parent = map

local function makeDot(name, size, color)
	local dot = Instance.new("Frame")
	dot.Name = name
	dot.Size = UDim2.fromOffset(size, size)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	dot.Parent = dotsFolder
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, math.floor(size / 2))
	c.Parent = dot
	return dot
end

local localDot = makeDot("Local", 8, Color3.fromRGB(245, 245, 245))
local guardianDot = makeDot("Guardian", 8, Color3.fromRGB(220, 60, 60))
local vaultDot = Instance.new("Frame")
vaultDot.Name = "Vault"
vaultDot.Size = UDim2.fromOffset(6, 6)
vaultDot.BackgroundColor3 = Color3.fromRGB(210, 165, 50)
vaultDot.BorderSizePixel = 0
vaultDot.Rotation = 45
vaultDot.Parent = dotsFolder

local otherDots = {}

local function worldToMap(worldPos)
	local x = (worldPos.X + 150) / 300 * 140
	local z = (worldPos.Z + 150) / 300 * 140
	return UDim2.new(0, math.clamp(x, 0, 134), 0, math.clamp(z, 0, 134))
end

local function setDotPos(dot, worldPos)
	dot.Position = worldToMap(worldPos)
end

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.1 then return end
	accumulator = 0

	local role = localPlayer:GetAttribute("Role")	
	map.Visible = role ~= nil
	if not map.Visible then
		return
	end

	local myChar = localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if myRoot then
		setDotPos(localDot, myRoot.Position)
	end
	setDotPos(vaultDot, Vector3.new(0, 0, -80))

	for _, dot in pairs(otherDots) do
		dot.Visible = false
	end

	local guardianPlayer = nil
	local myPos = myRoot and myRoot.Position

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer then
			local pRole = p:GetAttribute("Role")
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if pRole == "Guardian" then
				guardianPlayer = p
				if root then
					local showGuardian = role == "Guardian" or (myPos and (root.Position - myPos).Magnitude <= 60)
					guardianDot.Visible = showGuardian
					if showGuardian then
						setDotPos(guardianDot, root.Position)
						local pulse = 1 + ((math.sin(os.clock() * math.pi * 2 / 0.8) + 1) * 0.1)
						guardianDot.Size = UDim2.fromOffset(8 * pulse, 8 * pulse)
					end
				end
			elseif pRole == "Thief" and root then
				local dot = otherDots[p]
				if not dot then
					dot = makeDot("Thief_" .. p.Name, 6, Color3.fromRGB(40, 220, 200))
					otherDots[p] = dot
				end
				dot.Visible = true
				setDotPos(dot, root.Position)
			end
		end
	end

	if role == "Guardian" then
		guardianDot.Visible = false
	end
	if not guardianPlayer then
		guardianDot.Visible = false
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local dot = otherDots[player]
	if dot then
		dot:Destroy()
		otherDots[player] = nil
	end
end)
