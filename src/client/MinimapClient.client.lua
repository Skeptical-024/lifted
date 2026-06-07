-- Tag-derived minimap. No production-map coordinates are hardcoded.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "MinimapUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local map = Instance.new("Frame")
map.Size = UDim2.fromOffset(150, 150)
map.Position = UDim2.new(1, -166, 1, -166)
map.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
map.BackgroundTransparency = 0.2
map.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = map
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(210, 165, 50)
stroke.Transparency = 0.55
stroke.Parent = map

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 16)
title.BackgroundTransparency = 1
title.Text = "TACTICAL MAP"
title.TextColor3 = Color3.fromRGB(180, 180, 190)
title.Font = Enum.Font.GothamBold
title.TextSize = 11
title.Parent = map

local dots = Instance.new("Folder")
dots.Name = "Dots"
dots.Parent = map

local function makeDot(name, size, color)
	local dot = Instance.new("Frame")
	dot.Name = name
	dot.Size = UDim2.fromOffset(size, size)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	dot.Parent = dots
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot
	return dot
end

local localDot = makeDot("Local", 8, Color3.fromRGB(245, 245, 245))
local guardianDot = makeDot("Guardian", 8, Color3.fromRGB(220, 60, 60))
local vaultDot = makeDot("Vault", 7, Color3.fromRGB(220, 175, 55))
local extractDots = {}
local otherDots = {}
local boundsMin = Vector2.new(-150, -150)
local boundsMax = Vector2.new(150, 150)
local warnedFallback = false
local revealVisibleUntil = 0
local revealedUserIds = {}

local function collectMapParts()
	local result = {}
	for _, tag in ipairs({
		"ObjectiveStation", "Vault", "Idol", "ExtractPoint",
		"ThiefSpawn", "GuardianSpawn", "CageSpawn",
	}) do
		for _, part in ipairs(CollectionService:GetTagged(tag)) do
			if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
				table.insert(result, part)
			end
		end
	end
	return result
end

local function refreshBounds()
	local parts = collectMapParts()
	if #parts == 0 then
		if not warnedFallback then
			warnedFallback = true
			warn("[Minimap] No tagged map parts found; using safe fallback bounds.")
		end
		boundsMin = Vector2.new(-150, -150)
		boundsMax = Vector2.new(150, 150)
		return
	end
	local minX, minZ = math.huge, math.huge
	local maxX, maxZ = -math.huge, -math.huge
	for _, part in ipairs(parts) do
		minX = math.min(minX, part.Position.X)
		minZ = math.min(minZ, part.Position.Z)
		maxX = math.max(maxX, part.Position.X)
		maxZ = math.max(maxZ, part.Position.Z)
	end
	local padding = 20
	boundsMin = Vector2.new(minX - padding, minZ - padding)
	boundsMax = Vector2.new(maxX + padding, maxZ + padding)
end

local function worldToMap(position)
	local spanX = math.max(1, boundsMax.X - boundsMin.X)
	local spanZ = math.max(1, boundsMax.Y - boundsMin.Y)
	local x = (position.X - boundsMin.X) / spanX
	local z = (position.Z - boundsMin.Y) / spanZ
	return UDim2.new(0, math.clamp(5 + x * 138, 5, 143), 0, math.clamp(10 + z * 133, 10, 143))
end

local function setDot(dot, part)
	dot.Visible = part ~= nil
	if part then
		dot.Position = worldToMap(part.Position)
	end
end

local function refreshStaticMarkers()
	local vault = CollectionService:GetTagged("Vault")[1]
	setDot(vaultDot, vault and vault:IsA("BasePart") and vault or nil)
	for _, dot in ipairs(extractDots) do
		dot:Destroy()
	end
	extractDots = {}
	for _, part in ipairs(CollectionService:GetTagged("ExtractPoint")) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			local dot = makeDot("Extract", 6, Color3.fromRGB(70, 220, 110))
			setDot(dot, part)
			table.insert(extractDots, dot)
		end
	end
end

refreshBounds()
refreshStaticMarkers()
task.spawn(function()
	while true do
		task.wait(5)
		refreshBounds()
		refreshStaticMarkers()
	end
end)

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator < 0.15 then return end
	accumulator = 0
	local role = localPlayer:GetAttribute("Role")
	local state = localPlayer:GetAttribute("RoundState")
	map.Visible = role ~= nil and state ~= "OutOfRound" and state ~= "Eliminated"
	if not map.Visible then return end

	local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	setDot(localDot, myRoot)
	guardianDot.Visible = false
	for _, dot in pairs(otherDots) do dot.Visible = false end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local otherRole = player:GetAttribute("Role")
			if otherRole == "Guardian" and role == "Thief" and root and myRoot
				and (root.Position - myRoot.Position).Magnitude <= 45 then
				setDot(guardianDot, root)
			elseif otherRole == "Thief" and root then
				local dot = otherDots[player]
				if not dot then
					dot = makeDot("Thief_" .. player.Name, 6, Color3.fromRGB(40, 220, 200))
					otherDots[player] = dot
				end
				local show = role == "Thief"
					or (role == "Guardian"
						and os.clock() <= revealVisibleUntil
						and revealedUserIds[player.UserId] == true)
				if show then setDot(dot, root) end
			end
		end
	end
end)

local revealRemote = Remotes.Find(Remotes.Names.GuardianRevealStarted)
if revealRemote then
	revealRemote.OnClientEvent:Connect(function(revealed, duration)
		revealedUserIds = {}
		for _, entry in ipairs(type(revealed) == "table" and revealed or {}) do
			local userId = tonumber(entry.userId)
			if userId then revealedUserIds[userId] = true end
		end
		revealVisibleUntil = os.clock() + math.max(0, tonumber(duration) or 4)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	local dot = otherDots[player]
	if dot then dot:Destroy() end
	otherDots[player] = nil
end)
