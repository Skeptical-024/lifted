local BrazierManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Constants"))
local Types = require(ReplicatedStorage:WaitForChild("Types"))

local guardianBrazierSequenceRemote = ReplicatedStorage:WaitForChild("GuardianBrazierSequence")
local brazierStateChangedRemote = ReplicatedStorage:WaitForChild("BrazierStateChanged")

local ALL_BRAZIERS = {
	"Brazier1", "Brazier2", "Brazier3", "Brazier4",
	"Brazier5", "Brazier6", "Brazier7", "Brazier8",
}

local sequence = {}
local litBraziers = {}
local litOrder = {}
local litCount = 0

local function findBrazierPart(name)
	local instance = workspace:FindFirstChild(name, true)
	if instance and instance:IsA("BasePart") then
		return instance
	end
	return nil
end

local function getBrazierFillPart(name)
	local suffix = string.match(name, "Brazier(%d+)")
	if suffix then
		local fill = workspace:FindFirstChild("BrazierFill" .. suffix, true)
		if fill and fill:IsA("BasePart") then
			return fill
		end
	end
	return findBrazierPart(name)
end

local function setLight(fill, enabled)
	local light = fill:FindFirstChild("BrazierLight")
	if enabled then
		if not light then
			light = Instance.new("PointLight")
			light.Name = "BrazierLight"
			light.Brightness = 5
			light.Range = 15
			light.Color = Color3.fromRGB(255, 160, 60)
			light.Parent = fill
		end
	else
		if light then
			light:Destroy()
		end
	end
end

local function setUnlit(name)
	local fill = getBrazierFillPart(name)
	if not fill then
		return
	end
	fill.Color = Color3.fromRGB(40, 35, 30)
	fill.Material = Enum.Material.Cobblestone
	setLight(fill, false)
end

local function setLit(name)
	local fill = getBrazierFillPart(name)
	if not fill then
		return
	end
	fill.Color = Color3.fromRGB(255, 140, 30)
	fill.Material = Enum.Material.Neon
	setLight(fill, true)
end

local function flashWrong(name)
	local fill = getBrazierFillPart(name)
	if not fill then
		return
	end
	fill.Color = Color3.fromRGB(200, 50, 50)
	fill.Material = Enum.Material.Neon
	task.delay(0.5, function()
		if litBraziers[name] then
			setLit(name)
		else
			setUnlit(name)
		end
	end)
end

local function getRootPart(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function isNearBrazier(player, brazierName)
	local root = getRootPart(player)
	local brazier = findBrazierPart(brazierName)
	if not root or not brazier then
		return false
	end
	return (root.Position - brazier.Position).Magnitude <= Constants.BRAZIER_INTERACT_DISTANCE
end

local function getLitNames()
	local names = {}
	for name in litBraziers do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

local function fireStateChanged()
	brazierStateChangedRemote:FireAllClients(getLitNames())
end

local function buildSequence()
	local pool = table.clone(ALL_BRAZIERS)
	for i = #pool, 2, -1 do
		local j = math.random(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	sequence = {}
	for i = 1, Constants.BRAZIER_SEQUENCE_LENGTH do
		sequence[i] = pool[i]
	end
end

function BrazierManager.InitRound(rolesByPlayer)
	buildSequence()
	litBraziers = {}
	litOrder = {}
	litCount = 0

	for _, name in ipairs(ALL_BRAZIERS) do
		setUnlit(name)
	end

	for player, role in rolesByPlayer do
		if role == Types.PlayerRole.Guardian and Players:FindFirstChild(player.Name) then
			guardianBrazierSequenceRemote:FireClient(player, sequence)
		end
	end

	fireStateChanged()
end

function BrazierManager.TryLightBrazier(player, brazierName, rolesByPlayer, roundActive)
	if not roundActive then
		return false
	end
	if rolesByPlayer[player] ~= Types.PlayerRole.Thief then
		return false
	end
	if type(brazierName) ~= "string" then
		return false
	end
	if litBraziers[brazierName] then
		return false
	end
	if not isNearBrazier(player, brazierName) then
		return false
	end

	local nextExpected = sequence[litCount + 1]
	if brazierName ~= nextExpected then
		flashWrong(brazierName)
		return false
	end

	litCount += 1
	litBraziers[brazierName] = true
	table.insert(litOrder, brazierName)
	setLit(brazierName)
	fireStateChanged()
	return true
end

function BrazierManager.TryExtinguishBrazier(player, brazierName, rolesByPlayer, roundActive)
	if not roundActive then
		return false
	end
	if rolesByPlayer[player] ~= Types.PlayerRole.Guardian then
		return false
	end
	if type(brazierName) ~= "string" then
		return false
	end
	if not litBraziers[brazierName] then
		return false
	end
	if not isNearBrazier(player, brazierName) then
		return false
	end

	local cutIndex = nil
	for i, name in ipairs(litOrder) do
		if name == brazierName then
			cutIndex = i
			break
		end
	end
	if not cutIndex then
		return false
	end

	for i = cutIndex, #litOrder do
		local name = litOrder[i]
		litBraziers[name] = nil
		setUnlit(name)
	end
	for i = #litOrder, cutIndex, -1 do
		table.remove(litOrder, i)
	end
	litCount = #litOrder
	fireStateChanged()
	return true
end

function BrazierManager.IsUnlocked()
	return litCount >= Constants.BRAZIER_SEQUENCE_LENGTH
end

function BrazierManager.GetLitCount()
	return litCount
end

function BrazierManager.Reset()
	litBraziers = {}
	litOrder = {}
	litCount = 0
	sequence = {}
	for _, name in ipairs(ALL_BRAZIERS) do
		setUnlit(name)
	end
	fireStateChanged()
end

return BrazierManager
