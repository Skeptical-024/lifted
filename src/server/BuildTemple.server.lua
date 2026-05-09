-- BuildTemple.server.lua
-- Run once on server start. Builds the full Lifted temple map.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
local constantsModule = sharedFolder and sharedFolder:FindFirstChild("Constants")
if not constantsModule then
	constantsModule = ReplicatedStorage:WaitForChild("Constants")
end
local Constants = require(constantsModule)

if Constants.TEST_MAP_ENABLED then
	warn("BuildTemple disabled because TEST_MAP_ENABLED is true. TestMapService will create the gameplay test map.")
	return
end

local existing = workspace:FindFirstChild("TempleMap")
if existing then
	existing:Destroy()
end

local templeMap = Instance.new("Folder")
templeMap.Name = "TempleMap"
templeMap.Parent = workspace

local COLORS = {
	PrimaryStone = Color3.fromRGB(105, 95, 82),
	DarkStone = Color3.fromRGB(72, 65, 55),
	AccentStone = Color3.fromRGB(130, 115, 95),
	FloorStone = Color3.fromRGB(88, 80, 68),
	GoldAccent = Color3.fromRGB(180, 145, 60),
	TorchOrange = Color3.fromRGB(255, 130, 30),
	TorchGlow = Color3.fromRGB(255, 200, 80),
	MossAccent = Color3.fromRGB(65, 85, 55),
	DarkMetal = Color3.fromRGB(55, 50, 45),
	MarbleWhite = Color3.fromRGB(210, 200, 185),
	WoodColor = Color3.fromRGB(120, 90, 55),
	IdolGold = Color3.fromRGB(255, 185, 40),
}

local function createPart(name, size, position, color, material, parent, transparency, anchored, cancollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Parent = parent or templeMap
	part.Transparency = transparency or 0
	part.Anchored = anchored ~= false
	part.CanCollide = cancollide ~= false
	return part
end

local function createTorch(prefix, position)
	createPart(prefix .. "_Bracket", Vector3.new(1, 3, 1), position, COLORS.DarkMetal, Enum.Material.Metal)

	local flamePart = createPart(
		prefix .. "_Flame",
		Vector3.new(2, 3, 2),
		position + Vector3.new(0, 2, 0),
		COLORS.TorchOrange,
		Enum.Material.Neon
	)

	createPart(
		prefix .. "_Glow",
		Vector3.new(3, 4, 3),
		position + Vector3.new(0, 2, 0),
		COLORS.TorchGlow,
		Enum.Material.Neon,
		templeMap,
		0.5
	)

	local light = Instance.new("PointLight")
	light.Brightness = 4
	light.Range = 20
	light.Color = Color3.fromRGB(255, 160, 60)
	light.Parent = flamePart
end

-- === 1. GROUND FLOOR ===
createPart("MainFloor", Vector3.new(300, 1, 300), Vector3.new(0, 0, 0), COLORS.FloorStone, Enum.Material.Cobblestone)
createPart("EntrancePlatform", Vector3.new(60, 1, 20), Vector3.new(0, 0.5, 110), COLORS.AccentStone, Enum.Material.Cobblestone)
createPart("VaultPlatform", Vector3.new(80, 3, 80), Vector3.new(0, 1.5, -80), COLORS.MarbleWhite, Enum.Material.Marble)

createPart("VaultPlatformTrimNorth", Vector3.new(80, 1, 2), Vector3.new(0, 3.5, -119), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultPlatformTrimSouth", Vector3.new(80, 1, 2), Vector3.new(0, 3.5, -41), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultPlatformTrimEast", Vector3.new(2, 1, 80), Vector3.new(39, 3.5, -80), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultPlatformTrimWest", Vector3.new(2, 1, 80), Vector3.new(-39, 3.5, -80), COLORS.GoldAccent, Enum.Material.Metal)

-- === 2. OUTER WALLS ===
createPart("OuterWallNorth", Vector3.new(300, 28, 6), Vector3.new(0, 14, -150), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("OuterWallSouth", Vector3.new(300, 28, 6), Vector3.new(0, 14, 150), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("OuterWallEast", Vector3.new(6, 28, 300), Vector3.new(150, 14, 0), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("OuterWallWest", Vector3.new(6, 28, 300), Vector3.new(-150, 14, 0), COLORS.PrimaryStone, Enum.Material.Brick)

createPart("TowerNE", Vector3.new(16, 34, 16), Vector3.new(142, 17, -142), COLORS.DarkStone, Enum.Material.Brick)
createPart("TowerNW", Vector3.new(16, 34, 16), Vector3.new(-142, 17, -142), COLORS.DarkStone, Enum.Material.Brick)
createPart("TowerSE", Vector3.new(16, 34, 16), Vector3.new(142, 17, 142), COLORS.DarkStone, Enum.Material.Brick)
createPart("TowerSW", Vector3.new(16, 34, 16), Vector3.new(-142, 17, 142), COLORS.DarkStone, Enum.Material.Brick)

createPart("TowerCapNE", Vector3.new(20, 2, 20), Vector3.new(142, 35, -142), COLORS.AccentStone, Enum.Material.Slate)
createPart("TowerCapNW", Vector3.new(20, 2, 20), Vector3.new(-142, 35, -142), COLORS.AccentStone, Enum.Material.Slate)
createPart("TowerCapSE", Vector3.new(20, 2, 20), Vector3.new(142, 35, 142), COLORS.AccentStone, Enum.Material.Slate)
createPart("TowerCapSW", Vector3.new(20, 2, 20), Vector3.new(-142, 35, 142), COLORS.AccentStone, Enum.Material.Slate)

for i = 0, 9 do
	local x = -120 + (240 / 9) * i
	createPart("NorthMerlon" .. (i + 1), Vector3.new(4, 5, 6), Vector3.new(x, 31, -150), COLORS.PrimaryStone, Enum.Material.Brick)
	createPart("SouthMerlon" .. (i + 1), Vector3.new(4, 5, 6), Vector3.new(x, 31, 150), COLORS.PrimaryStone, Enum.Material.Brick)
end

for i = 0, 9 do
	local z = -120 + (240 / 9) * i
	createPart("EastMerlon" .. (i + 1), Vector3.new(6, 5, 4), Vector3.new(150, 31, z), COLORS.PrimaryStone, Enum.Material.Brick)
	createPart("WestMerlon" .. (i + 1), Vector3.new(6, 5, 4), Vector3.new(-150, 31, z), COLORS.PrimaryStone, Enum.Material.Brick)
end

-- === 3. ENTRANCE GATE ===
createPart("GatePillarLeft", Vector3.new(8, 30, 8), Vector3.new(-16, 15, 148), COLORS.AccentStone, Enum.Material.Brick)
createPart("GatePillarRight", Vector3.new(8, 30, 8), Vector3.new(16, 15, 148), COLORS.AccentStone, Enum.Material.Brick)
createPart("GateArchLintel", Vector3.new(36, 6, 6), Vector3.new(0, 28, 148), COLORS.DarkStone, Enum.Material.Brick)

createPart("GateDoorLeft", Vector3.new(14, 22, 2), Vector3.new(-9, 12, 149), COLORS.DarkMetal, Enum.Material.Metal)
createPart("GateDoorRight", Vector3.new(14, 22, 2), Vector3.new(9, 12, 149), COLORS.DarkMetal, Enum.Material.Metal)

for _, x in ipairs({-14, -4}) do
	for _, y in ipairs({4, 9, 14, 19}) do
		createPart("GateLeftRivet_" .. x .. "_" .. y, Vector3.new(1, 1, 1), Vector3.new(x, y, 150), COLORS.DarkMetal, Enum.Material.Metal)
	end
end

for _, x in ipairs({4, 14}) do
	for _, y in ipairs({4, 9, 14, 19}) do
		createPart("GateRightRivet_" .. x .. "_" .. y, Vector3.new(1, 1, 1), Vector3.new(x, y, 150), COLORS.DarkMetal, Enum.Material.Metal)
	end
end

createTorch("GateTorchLeft", Vector3.new(-22, 16, 147))
createTorch("GateTorchRight", Vector3.new(22, 16, 147))

-- === 4. ENTRANCE COURTYARD ===
createPart("CourtyardPillarA", Vector3.new(5, 16, 5), Vector3.new(-35, 8, 120), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("CourtyardPillarB", Vector3.new(5, 10, 5), Vector3.new(35, 5, 120), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("CourtyardPillarC", Vector3.new(5, 20, 5), Vector3.new(-35, 10, 90), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("CourtyardPillarD", Vector3.new(5, 8, 5), Vector3.new(35, 4, 90), COLORS.PrimaryStone, Enum.Material.Brick)

createPart("CourtyardDebrisB", Vector3.new(6, 3, 6), Vector3.new(35, 1.5, 108), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("CourtyardDebrisD", Vector3.new(6, 2, 6), Vector3.new(35, 1.5, 85), COLORS.PrimaryStone, Enum.Material.Brick)

createPart("CourtyardCover1", Vector3.new(12, 4, 4), Vector3.new(-50, 2, 130), COLORS.DarkStone, Enum.Material.Brick)
createPart("CourtyardCover2", Vector3.new(12, 4, 4), Vector3.new(50, 2, 130), COLORS.DarkStone, Enum.Material.Brick)
createPart("CourtyardCover3", Vector3.new(8, 3, 4), Vector3.new(-55, 1.5, 105), COLORS.DarkStone, Enum.Material.Brick)
createPart("CourtyardCover4", Vector3.new(8, 3, 4), Vector3.new(55, 1.5, 105), COLORS.DarkStone, Enum.Material.Brick)
createPart("CourtyardCover5", Vector3.new(16, 5, 4), Vector3.new(-45, 2.5, 88), COLORS.DarkStone, Enum.Material.Brick)
createPart("CourtyardCover6", Vector3.new(16, 5, 4), Vector3.new(45, 2.5, 88), COLORS.DarkStone, Enum.Material.Brick)

createPart("EntranceStep1", Vector3.new(30, 1, 4), Vector3.new(0, 0.5, 82), COLORS.AccentStone, Enum.Material.Cobblestone)
createPart("EntranceStep2", Vector3.new(28, 1, 4), Vector3.new(0, 1.5, 78), COLORS.AccentStone, Enum.Material.Cobblestone)
createPart("EntranceStep3", Vector3.new(26, 1, 4), Vector3.new(0, 2.5, 74), COLORS.AccentStone, Enum.Material.Cobblestone)
createPart("EntranceStep4", Vector3.new(24, 1, 4), Vector3.new(0, 3.5, 70), COLORS.AccentStone, Enum.Material.Cobblestone)

createPart("CourtyardMossPathLeft", Vector3.new(4, 0.5, 60), Vector3.new(-6, 0.6, 105), COLORS.MossAccent, Enum.Material.Cobblestone)
createPart("CourtyardMossPathRight", Vector3.new(4, 0.5, 60), Vector3.new(6, 0.6, 105), COLORS.MossAccent, Enum.Material.Cobblestone)

-- === 5. MAIN CORRIDOR ===
createPart("CorridorWallLeft", Vector3.new(6, 20, 90), Vector3.new(-24, 10, 25), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("CorridorWallRight", Vector3.new(6, 20, 90), Vector3.new(24, 10, 25), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("CorridorCeiling", Vector3.new(48, 2, 90), Vector3.new(0, 21, 25), COLORS.DarkStone, Enum.Material.Slate)

local corridorPillarZ = {60, 40, 20, 0}
for i, z in ipairs(corridorPillarZ) do
	createPart("CorridorPillarLeft" .. i, Vector3.new(4, 20, 4), Vector3.new(-21, 10, z), COLORS.AccentStone, Enum.Material.Brick)
	createPart("CorridorPillarRight" .. i, Vector3.new(4, 20, 4), Vector3.new(21, 10, z), COLORS.AccentStone, Enum.Material.Brick)

	createPart("CorridorPillarBaseLeft" .. i, Vector3.new(6, 2, 6), Vector3.new(-21, 1, z), COLORS.GoldAccent, Enum.Material.Metal)
	createPart("CorridorPillarBaseRight" .. i, Vector3.new(6, 2, 6), Vector3.new(21, 1, z), COLORS.GoldAccent, Enum.Material.Metal)

	createPart("CorridorPillarCapLeft" .. i, Vector3.new(6, 2, 6), Vector3.new(-21, 20, z), COLORS.DarkStone, Enum.Material.Marble)
	createPart("CorridorPillarCapRight" .. i, Vector3.new(6, 2, 6), Vector3.new(21, 20, z), COLORS.DarkStone, Enum.Material.Marble)
end

for i, z in ipairs({50, 30, 10, -10}) do
	createTorch("CorridorTorchLeft" .. i, Vector3.new(-23, 8, z))
	createTorch("CorridorTorchRight" .. i, Vector3.new(23, 8, z))
end

createPart("CorridorMosaicStrip", Vector3.new(6, 0.5, 90), Vector3.new(0, 0.6, 25), COLORS.GoldAccent, Enum.Material.Marble)

-- === 6. LEFT CHAMBER ===
createPart("LeftChamberNorthWall", Vector3.new(96, 18, 6), Vector3.new(-72, 9, -33), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("LeftChamberSouthWall", Vector3.new(96, 18, 6), Vector3.new(-72, 9, 33), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("LeftChamberWestWall", Vector3.new(6, 18, 66), Vector3.new(-123, 9, 0), COLORS.PrimaryStone, Enum.Material.Brick)

createPart("LeftChamberEastWallTop", Vector3.new(6, 6, 66), Vector3.new(-24, 16, 0), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("LeftChamberEastWallNorth", Vector3.new(6, 18, 18), Vector3.new(-24, 9, 24), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("LeftChamberEastWallSouth", Vector3.new(6, 18, 18), Vector3.new(-24, 9, -24), COLORS.PrimaryStone, Enum.Material.Brick)

createPart("LeftChamberCeiling", Vector3.new(99, 2, 66), Vector3.new(-72, 19, 0), COLORS.DarkStone, Enum.Material.Slate)

createPart("LeftArchJambNorth", Vector3.new(6, 14, 8), Vector3.new(-24, 7, 18), COLORS.AccentStone, Enum.Material.Brick)
createPart("LeftArchJambSouth", Vector3.new(6, 14, 8), Vector3.new(-24, 7, -18), COLORS.AccentStone, Enum.Material.Brick)
createPart("LeftArchLintel", Vector3.new(6, 4, 44), Vector3.new(-24, 16, 0), COLORS.DarkStone, Enum.Material.Brick)

createPart("LeftAltarBase", Vector3.new(10, 5, 6), Vector3.new(-80, 2.5, 0), COLORS.MarbleWhite, Enum.Material.Marble)
createPart("LeftAltarTop", Vector3.new(12, 1, 8), Vector3.new(-80, 5.5, 0), COLORS.GoldAccent, Enum.Material.Metal)

createPart("LeftSarcophagus1", Vector3.new(8, 4, 4), Vector3.new(-60, 2, 15), COLORS.DarkStone, Enum.Material.Brick)
createPart("LeftSarcophagus2", Vector3.new(8, 4, 4), Vector3.new(-60, 2, -15), COLORS.DarkStone, Enum.Material.Brick)
createPart("LeftSarcophagus3", Vector3.new(8, 4, 4), Vector3.new(-100, 2, 0), COLORS.DarkStone, Enum.Material.Brick)

createPart("LeftBrokenColumn", Vector3.new(6, 12, 6), Vector3.new(-105, 6, 20), COLORS.PrimaryStone, Enum.Material.Brick)

local fallen = Instance.new("Part")
fallen.Name = "LeftFallenColumn"
fallen.Size = Vector3.new(6, 6, 20)
fallen.CFrame = CFrame.new(-95, 3, -20) * CFrame.Angles(0, 0, math.rad(90))
fallen.Color = COLORS.PrimaryStone
fallen.Material = Enum.Material.Brick
fallen.Anchored = true
fallen.CanCollide = true
fallen.Parent = templeMap

createTorch("LeftChamberTorch1", Vector3.new(-30, 10, 22))
createTorch("LeftChamberTorch2", Vector3.new(-30, 10, -22))
createTorch("LeftChamberTorch3", Vector3.new(-110, 10, 12))
createTorch("LeftChamberTorch4", Vector3.new(-110, 10, -12))

createPart("LeftMossPatch1", Vector3.new(15, 0.5, 10), Vector3.new(-70, 0.6, 20), COLORS.MossAccent, Enum.Material.Cobblestone)
createPart("LeftMossPatch2", Vector3.new(10, 0.5, 15), Vector3.new(-95, 0.6, -10), COLORS.MossAccent, Enum.Material.Cobblestone)

-- === 7. RIGHT CHAMBER ===
createPart("RightChamberNorthWall", Vector3.new(96, 18, 6), Vector3.new(72, 9, -33), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("RightChamberSouthWall", Vector3.new(96, 18, 6), Vector3.new(72, 9, 33), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("RightChamberEastWall", Vector3.new(6, 18, 66), Vector3.new(123, 9, 0), COLORS.PrimaryStone, Enum.Material.Brick)

createPart("RightChamberWestWallTop", Vector3.new(6, 6, 66), Vector3.new(24, 16, 0), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("RightChamberWestWallNorth", Vector3.new(6, 18, 18), Vector3.new(24, 9, 24), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("RightChamberWestWallSouth", Vector3.new(6, 18, 18), Vector3.new(24, 9, -24), COLORS.PrimaryStone, Enum.Material.Brick)

createPart("RightChamberCeiling", Vector3.new(99, 2, 66), Vector3.new(72, 19, 0), COLORS.DarkStone, Enum.Material.Slate)

createPart("RightArchJambNorth", Vector3.new(6, 14, 8), Vector3.new(24, 7, 18), COLORS.AccentStone, Enum.Material.Brick)
createPart("RightArchJambSouth", Vector3.new(6, 14, 8), Vector3.new(24, 7, -18), COLORS.AccentStone, Enum.Material.Brick)
createPart("RightArchLintel", Vector3.new(6, 4, 44), Vector3.new(24, 16, 0), COLORS.DarkStone, Enum.Material.Brick)

createPart("RightBalconyPlatform", Vector3.new(30, 2, 20), Vector3.new(80, 10, -5), COLORS.AccentStone, Enum.Material.Marble)
createPart("RightBalconyRailingFront", Vector3.new(30, 4, 2), Vector3.new(80, 13, -15), COLORS.DarkStone, Enum.Material.Brick)
createPart("RightBalconyRailingLeft", Vector3.new(2, 4, 20), Vector3.new(66, 13, -5), COLORS.DarkStone, Enum.Material.Brick)
createPart("RightBalconyRailingRight", Vector3.new(2, 4, 20), Vector3.new(94, 13, -5), COLORS.DarkStone, Enum.Material.Brick)

createPart("RightBalconyStep1", Vector3.new(10, 1, 4), Vector3.new(65, 0.5, 10), COLORS.AccentStone, Enum.Material.Cobblestone)
createPart("RightBalconyStep2", Vector3.new(10, 1, 4), Vector3.new(65, 1.5, 6), COLORS.AccentStone, Enum.Material.Cobblestone)
createPart("RightBalconyStep3", Vector3.new(10, 1, 4), Vector3.new(65, 2.5, 2), COLORS.AccentStone, Enum.Material.Cobblestone)
createPart("RightBalconyStep4", Vector3.new(10, 1, 4), Vector3.new(65, 3.5, -2), COLORS.AccentStone, Enum.Material.Cobblestone)

createPart("RightCrate1", Vector3.new(5, 5, 5), Vector3.new(50, 2.5, 20), COLORS.WoodColor, Enum.Material.Wood)
createPart("RightCrate2", Vector3.new(5, 5, 5), Vector3.new(57, 2.5, 20), COLORS.WoodColor, Enum.Material.Wood)
createPart("RightCrate3", Vector3.new(5, 5, 5), Vector3.new(50, 7.5, 20), COLORS.WoodColor, Enum.Material.Wood)

createPart("RightWeaponRack", Vector3.new(2, 8, 8), Vector3.new(100, 4, 10), COLORS.DarkMetal, Enum.Material.Metal)
createPart("RightBrokenWallSection", Vector3.new(6, 8, 6), Vector3.new(120, 4, -20), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("RightRubble", Vector3.new(4, 2, 4), Vector3.new(116, 1.5, -20), COLORS.DarkStone, Enum.Material.Cobblestone)

createTorch("RightChamberTorch1", Vector3.new(30, 10, 22))
createTorch("RightChamberTorch2", Vector3.new(30, 10, -22))
createTorch("RightChamberTorch3", Vector3.new(110, 10, 12))
createTorch("RightChamberTorch4", Vector3.new(110, 10, -12))

-- === 8. VAULT CHAMBER ===
createPart("VaultWallLeft", Vector3.new(6, 28, 120), Vector3.new(-24, 14, -90), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("VaultWallRight", Vector3.new(6, 28, 120), Vector3.new(24, 14, -90), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("VaultWallBack", Vector3.new(54, 28, 6), Vector3.new(0, 14, -150), COLORS.DarkStone, Enum.Material.Brick)
createPart("VaultCeiling", Vector3.new(48, 3, 120), Vector3.new(0, 29, -90), COLORS.DarkStone, Enum.Material.Slate)

createPart("VaultArchLeftJamb", Vector3.new(6, 22, 8), Vector3.new(-24, 11, -25), COLORS.AccentStone, Enum.Material.Brick)
createPart("VaultArchRightJamb", Vector3.new(6, 22, 8), Vector3.new(24, 11, -25), COLORS.AccentStone, Enum.Material.Brick)
createPart("VaultArchLintel", Vector3.new(6, 6, 56), Vector3.new(0, 25, -25), COLORS.DarkStone, Enum.Material.Brick)

for i, z in ipairs({-50, -80, -110}) do
	createPart("VaultPillarLeft" .. i, Vector3.new(7, 28, 7), Vector3.new(-20, 14, z), COLORS.PrimaryStone, Enum.Material.Brick)
	createPart("VaultPillarRight" .. i, Vector3.new(7, 28, 7), Vector3.new(20, 14, z), COLORS.PrimaryStone, Enum.Material.Brick)

	createPart("VaultPillarBaseLeft" .. i, Vector3.new(9, 3, 9), Vector3.new(-20, 1.5, z), COLORS.GoldAccent, Enum.Material.Metal)
	createPart("VaultPillarBaseRight" .. i, Vector3.new(9, 3, 9), Vector3.new(20, 1.5, z), COLORS.GoldAccent, Enum.Material.Metal)

	createPart("VaultPillarCapLeft" .. i, Vector3.new(9, 3, 9), Vector3.new(-20, 28, z), COLORS.DarkStone, Enum.Material.Marble)
	createPart("VaultPillarCapRight" .. i, Vector3.new(9, 3, 9), Vector3.new(20, 28, z), COLORS.DarkStone, Enum.Material.Marble)
end

createPart("VaultNicheL1", Vector3.new(4, 10, 2), Vector3.new(-27, 8, -65), COLORS.DarkStone, Enum.Material.Brick)
createPart("VaultNicheL2", Vector3.new(4, 10, 2), Vector3.new(-27, 8, -95), COLORS.DarkStone, Enum.Material.Brick)
createPart("VaultNicheR1", Vector3.new(4, 10, 2), Vector3.new(27, 8, -65), COLORS.DarkStone, Enum.Material.Brick)
createPart("VaultNicheR2", Vector3.new(4, 10, 2), Vector3.new(27, 8, -95), COLORS.DarkStone, Enum.Material.Brick)

createPart("VaultNichePedestalL1", Vector3.new(4, 6, 4), Vector3.new(-27, 3, -65), COLORS.MarbleWhite, Enum.Material.Marble)
createPart("VaultNichePedestalL2", Vector3.new(4, 6, 4), Vector3.new(-27, 3, -95), COLORS.MarbleWhite, Enum.Material.Marble)
createPart("VaultNichePedestalR1", Vector3.new(4, 6, 4), Vector3.new(27, 3, -65), COLORS.MarbleWhite, Enum.Material.Marble)
createPart("VaultNichePedestalR2", Vector3.new(4, 6, 4), Vector3.new(27, 3, -95), COLORS.MarbleWhite, Enum.Material.Marble)

for i, z in ipairs({-40, -60, -80, -100, -120, -140}) do
	createTorch("VaultTorchLeft" .. i, Vector3.new(-23, 10, z))
	createTorch("VaultTorchRight" .. i, Vector3.new(23, 10, z))
end

createPart("VaultReliefPanel", Vector3.new(40, 18, 2), Vector3.new(0, 14, -149), COLORS.AccentStone, Enum.Material.Marble)

createPart("VaultReliefFrameLeft", Vector3.new(2, 18, 2), Vector3.new(-21, 14, -148), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultReliefFrameRight", Vector3.new(2, 18, 2), Vector3.new(21, 14, -148), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultReliefFrameTop", Vector3.new(40, 2, 2), Vector3.new(0, 24, -148), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultReliefFrameBottom", Vector3.new(40, 2, 2), Vector3.new(0, 5, -148), COLORS.GoldAccent, Enum.Material.Metal)

createPart("VaultCentralDiamond", Vector3.new(8, 8, 2), Vector3.new(0, 14, -149), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultCornerSymbol1", Vector3.new(3, 3, 2), Vector3.new(-16, 20, -149), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultCornerSymbol2", Vector3.new(3, 3, 2), Vector3.new(16, 20, -149), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultCornerSymbol3", Vector3.new(3, 3, 2), Vector3.new(-16, 7, -149), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultCornerSymbol4", Vector3.new(3, 3, 2), Vector3.new(16, 7, -149), COLORS.GoldAccent, Enum.Material.Metal)

local brazierPositions = {
	Vector3.new(-15, 2.5, -80), Vector3.new(15, 2.5, -80),
	Vector3.new(0, 2.5, -65), Vector3.new(0, 2.5, -95),
	Vector3.new(-11, 2.5, -69), Vector3.new(11, 2.5, -69),
	Vector3.new(-11, 2.5, -91), Vector3.new(11, 2.5, -91),
}

for i, pos in ipairs(brazierPositions) do
	createPart("Brazier" .. i, Vector3.new(4, 5, 4), pos, COLORS.DarkStone, Enum.Material.Cobblestone)
	createPart("BrazierBowl" .. i, Vector3.new(5, 2, 5), pos + Vector3.new(0, 3.5, 0), COLORS.DarkMetal, Enum.Material.Metal)
	createPart("BrazierFill" .. i, Vector3.new(4, 1, 4), pos + Vector3.new(0, 3.5, 0), Color3.fromRGB(40, 35, 30), Enum.Material.Cobblestone)
end

-- === 9. GOLDEN IDOL (vault object) ===
local vaultIdolBase = createPart("VaultIdol", Vector3.new(5, 3, 5), Vector3.new(0, 1.5, -80), COLORS.MarbleWhite, Enum.Material.Marble)
CollectionService:AddTag(vaultIdolBase, "Vault")

createPart("VaultIdolBand", Vector3.new(6, 1, 6), Vector3.new(0, 3.5, -80), COLORS.GoldAccent, Enum.Material.Metal)
createPart("VaultIdolBody", Vector3.new(3, 5, 3), Vector3.new(0, 6.5, -80), COLORS.IdolGold, Enum.Material.Metal)
createPart("VaultIdolShoulders", Vector3.new(5, 2, 3), Vector3.new(0, 9, -80), COLORS.IdolGold, Enum.Material.Metal)
createPart("VaultIdolHead", Vector3.new(3, 3, 3), Vector3.new(0, 11.5, -80), COLORS.IdolGold, Enum.Material.Metal)
createPart("VaultIdolHeaddress", Vector3.new(2, 4, 2), Vector3.new(0, 14, -80), COLORS.IdolGold, Enum.Material.Metal)
createPart("VaultIdolGem", Vector3.new(1, 1, 1), Vector3.new(0, 16.5, -80), Color3.fromRGB(255, 80, 80), Enum.Material.Neon)
createPart("VaultIdolArmLeft", Vector3.new(2, 3, 2), Vector3.new(-3, 8, -80), COLORS.IdolGold, Enum.Material.Metal)
createPart("VaultIdolArmRight", Vector3.new(2, 3, 2), Vector3.new(3, 8, -80), COLORS.IdolGold, Enum.Material.Metal)

local auraPart = createPart(
	"VaultIdolAura",
	Vector3.new(6, 14, 6),
	Vector3.new(0, 9, -80),
	COLORS.IdolGold,
	Enum.Material.Neon,
	templeMap,
	0.85,
	true,
	false
)

local idolLight = Instance.new("PointLight")
idolLight.Brightness = 6
idolLight.Range = 30
idolLight.Color = Color3.fromRGB(255, 200, 80)
idolLight.Parent = auraPart

-- === 10. ROOF STRUCTURES ===
createPart("EntranceRoof", Vector3.new(60, 5, 35), Vector3.new(0, 23, 110), COLORS.DarkStone, Enum.Material.Slate)
createPart("CorridorRoof", Vector3.new(54, 5, 95), Vector3.new(0, 23, 25), COLORS.DarkStone, Enum.Material.Slate)
createPart("LeftChamberRoof", Vector3.new(102, 5, 72), Vector3.new(-72, 22, 0), COLORS.DarkStone, Enum.Material.Slate)
createPart("RightChamberRoof", Vector3.new(102, 5, 72), Vector3.new(72, 22, 0), COLORS.DarkStone, Enum.Material.Slate)
createPart("VaultRoof", Vector3.new(54, 5, 126), Vector3.new(0, 33, -90), COLORS.DarkStone, Enum.Material.Slate)

createPart("CorridorRidgeline", Vector3.new(6, 6, 95), Vector3.new(0, 26, 25), COLORS.AccentStone, Enum.Material.Brick)
createPart("VaultRidgeline", Vector3.new(6, 8, 126), Vector3.new(0, 37, -90), COLORS.AccentStone, Enum.Material.Brick)

createPart("SpireBase", Vector3.new(14, 8, 14), Vector3.new(0, 40, -90), COLORS.DarkStone, Enum.Material.Brick)
createPart("SpireMid", Vector3.new(10, 10, 10), Vector3.new(0, 49, -90), COLORS.PrimaryStone, Enum.Material.Brick)
createPart("SpireTop", Vector3.new(6, 12, 6), Vector3.new(0, 59, -90), COLORS.AccentStone, Enum.Material.Brick)
createPart("SpireTip", Vector3.new(4, 8, 4), Vector3.new(0, 67, -90), COLORS.GoldAccent, Enum.Material.Metal)
createPart("SpireCap", Vector3.new(2, 4, 2), Vector3.new(0, 72, -90), COLORS.IdolGold, Enum.Material.Neon)

for i, basePos in ipairs({
	Vector3.new(142, 37, -142),
	Vector3.new(-142, 37, -142),
	Vector3.new(142, 37, 142),
	Vector3.new(-142, 37, 142),
}) do
	createPart("TowerSpireBase" .. i, Vector3.new(6, 10, 6), basePos, COLORS.PrimaryStone, Enum.Material.Brick)
	createPart("TowerSpireMid" .. i, Vector3.new(4, 8, 4), basePos + Vector3.new(0, 10, 0), COLORS.PrimaryStone, Enum.Material.Brick)
	createPart("TowerSpireTip" .. i, Vector3.new(2, 10, 2), basePos + Vector3.new(0, 19, 0), COLORS.IdolGold, Enum.Material.Neon)
end

-- === 11. ATMOSPHERIC LIGHTING SETUP ===
Lighting.Ambient = Color3.fromRGB(80, 72, 65)
Lighting.OutdoorAmbient = Color3.fromRGB(100, 90, 78)
Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.FogEnd = 300
Lighting.FogStart = 150
Lighting.FogColor = Color3.fromRGB(30, 25, 20)

local oldAtmosphere = Lighting:FindFirstChild("TempleAtmosphere")
if oldAtmosphere then
	oldAtmosphere:Destroy()
end

local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "TempleAtmosphere"
atmosphere.Density = 0.4
atmosphere.Offset = 0.2
atmosphere.Color = Color3.fromRGB(80, 70, 55)
atmosphere.Decay = Color3.fromRGB(40, 35, 30)
atmosphere.Glare = 0
atmosphere.Haze = 2
atmosphere.Parent = Lighting

local oldCC = Lighting:FindFirstChild("TempleColorCorrection")
if oldCC then
	oldCC:Destroy()
end

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "TempleColorCorrection"
colorCorrection.Brightness = -0.05
colorCorrection.Contrast = 0.1
colorCorrection.Saturation = -0.15
colorCorrection.TintColor = Color3.fromRGB(220, 200, 170)
colorCorrection.Parent = Lighting

-- === 12. SPAWN MARKERS ===
local guardianSpawn = createPart(
	"GuardianSpawn",
	Vector3.new(6, 0.5, 6),
	Vector3.new(0, 4.5, -80),
	Color3.fromRGB(220, 50, 50),
	Enum.Material.Neon,
	templeMap,
	0.5,
	true,
	false
)
CollectionService:AddTag(guardianSpawn, "GuardianSpawn")

local thiefSpawnPositions = {
	Vector3.new(-15, 0.5, 128),
	Vector3.new(-5, 0.5, 128),
	Vector3.new(5, 0.5, 128),
	Vector3.new(15, 0.5, 128),
}

for i, pos in ipairs(thiefSpawnPositions) do
	local marker = createPart(
		"ThiefSpawn" .. i,
		Vector3.new(6, 0.5, 6),
		pos,
		Color3.fromRGB(50, 220, 50),
		Enum.Material.Neon,
		templeMap,
		0.5,
		true,
		false
	)
	CollectionService:AddTag(marker, "ThiefSpawn")
end

-- === 13. ATMOSPHERIC DEBRIS ===
createPart("DebrisCorridor1", Vector3.new(3, 1.5, 3), Vector3.new(10, 1.5, 55), COLORS.DarkStone, Enum.Material.Cobblestone)
createPart("DebrisCorridor2", Vector3.new(2, 1.5, 2), Vector3.new(-8, 1.5, 35), COLORS.DarkStone, Enum.Material.Cobblestone)
createPart("DebrisCorridor3", Vector3.new(4, 2, 3), Vector3.new(15, 1.5, 15), COLORS.DarkStone, Enum.Material.Cobblestone)
createPart("DebrisCorridor4", Vector3.new(3, 1.5, 4), Vector3.new(-12, 1.5, -5), COLORS.DarkStone, Enum.Material.Cobblestone)

createPart("DebrisLeft1", Vector3.new(3, 1.5, 2), Vector3.new(-55, 1.5, 25), COLORS.DarkStone, Enum.Material.Cobblestone)
createPart("DebrisLeft2", Vector3.new(4, 2, 4), Vector3.new(-85, 1.5, -18), COLORS.DarkStone, Enum.Material.Cobblestone)
createPart("DebrisLeft3", Vector3.new(2, 1.5, 3), Vector3.new(-110, 1.5, 8), COLORS.DarkStone, Enum.Material.Cobblestone)

createPart("DebrisRight1", Vector3.new(3, 1.5, 3), Vector3.new(55, 1.5, -22), COLORS.DarkStone, Enum.Material.Cobblestone)
createPart("DebrisRight2", Vector3.new(4, 2, 3), Vector3.new(85, 1.5, 18), COLORS.DarkStone, Enum.Material.Cobblestone)
createPart("DebrisRight3", Vector3.new(2, 1.5, 4), Vector3.new(95, 1.5, -10), COLORS.DarkStone, Enum.Material.Cobblestone)

createPart("DebrisVault1", Vector3.new(3, 1.5, 2), Vector3.new(-8, 1.5, -45), COLORS.DarkStone, Enum.Material.Cobblestone)
createPart("DebrisVault2", Vector3.new(4, 2, 4), Vector3.new(12, 1.5, -120), COLORS.DarkStone, Enum.Material.Cobblestone)

for i, pos in ipairs({
	Vector3.new(-10, 22, -55), Vector3.new(10, 22, -55),
	Vector3.new(-10, 22, -70), Vector3.new(10, 22, -70),
	Vector3.new(-10, 22, -85), Vector3.new(10, 22, -85),
	Vector3.new(-10, 22, -100), Vector3.new(10, 22, -100),
}) do
	createPart("VaultChain" .. i, Vector3.new(1, 14, 1), pos, COLORS.DarkMetal, Enum.Material.Metal, templeMap, 0.3)
end

print("Temple build complete. Part count: " .. #templeMap:GetChildren())
