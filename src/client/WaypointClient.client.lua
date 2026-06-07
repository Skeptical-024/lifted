-- Lightweight role-aware objective marker. One marker is reused and updated at low frequency.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local localPlayer = Players.LocalPlayer
local marker = nil
local markerAdornee = nil

local function clearMarker()
	if marker then
		marker:Destroy()
	end
	marker = nil
	markerAdornee = nil
end

local function getRoot(player)
	local character = player and player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function nearestTagged(tag, origin, predicate)
	local nearest = nil
	local best = math.huge
	for _, part in ipairs(CollectionService:GetTagged(tag)) do
		if part:IsA("BasePart") and part:IsDescendantOf(workspace)
			and (not predicate or predicate(part)) then
			local distance = origin and (part.Position - origin).Magnitude or 0
			if distance < best then
				best = distance
				nearest = part
			end
		end
	end
	return nearest
end

local function getCagedTeammateRoot()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer
			and player:GetAttribute("Role") == "Thief"
			and player:GetAttribute("RoundState") == "Caged" then
			local root = getRoot(player)
			if root then
				return root
			end
		end
	end
	return nil
end

local function chooseTarget()
	local state = localPlayer:GetAttribute("RoundState")
	local role = localPlayer:GetAttribute("Role")
	if state ~= "Alive" then
		return nil, nil, nil
	end
	local root = getRoot(localPlayer)
	if not root then
		return nil, nil, nil
	end

	if role == "Guardian" then
		local cage = getCagedTeammateRoot()
		return cage, cage and "CAGE" or nil, Color3.fromRGB(220, 80, 80)
	end
	if role ~= "Thief" then
		return nil, nil, nil
	end

	if localPlayer:GetAttribute("HasIdol") == true then
		return nearestTagged("ExtractPoint", root.Position), "EXTRACT", Color3.fromRGB(70, 220, 110)
	end

	local cage = getCagedTeammateRoot()
	if cage then
		return cage, "RESCUE", Color3.fromRGB(220, 90, 210)
	end

	local idol = nearestTagged("Idol", root.Position, function(part)
		local idolState = part:GetAttribute("IdolState")
		return idolState == "Available" or idolState == "Dropped"
	end)
	if idol then
		return idol, "IDOL", Color3.fromRGB(230, 185, 60)
	end

	local objective = nearestTagged("ObjectiveStation", root.Position, function(part)
		return part:GetAttribute("ObjectiveCompleted") ~= true
	end)
	return objective, objective and "SEAL" or nil, Color3.fromRGB(50, 220, 200)
end

local function showMarker(adornee, text, color)
	if markerAdornee == adornee and marker then
		local label = marker:FindFirstChild("Label")
		if label then
			label.Text = text
			label.TextColor3 = color
		end
		return
	end
	clearMarker()
	if not adornee then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LIFTED_ObjectiveWaypoint"
	billboard.Size = UDim2.fromOffset(100, 30)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = adornee
	billboard.Parent = workspace
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	label.BackgroundTransparency = 0.25
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label
	marker = billboard
	markerAdornee = adornee
end

task.spawn(function()
	while true do
		local adornee, text, color = chooseTarget()
		showMarker(adornee, text, color)
		task.wait(0.5)
	end
end)
