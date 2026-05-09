-- TestMapService
-- Creates functional gameplay test map with correct CollectionService tags.
-- Runs alongside BuildTemple.server.lua which handles aesthetic geometry.
-- Replace this with real map tag injection when builder map is delivered.

local TestMapService = {}

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAP_FOLDER_NAME = "LIFTED_TestMap"
local REAL_MAP_TAG = "RealMapLoaded"

-- Helper: create a basic anchored part
local function makePart(name, size, position, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.CanCollide = true
	p.Color = color or Color3.fromRGB(100, 100, 100)
	p.Material = material or Enum.Material.SmoothPlastic
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function makeMarker(name, size, position, color, parent)
	local p = makePart(name, size, position, color, Enum.Material.Neon, parent)
	p.CanCollide = false
	p.Transparency = 0.5
	return p
end

local function tag(part, tagName)
	CollectionService:AddTag(part, tagName)
end

local function setAttribs(part, attribs)
	for k, v in pairs(attribs) do
		part:SetAttribute(k, v)
	end
end

local function getOrCreateFolder()
	local existing = workspace:FindFirstChild(MAP_FOLDER_NAME)
	if existing and existing:GetAttribute("IsGeneratedTestMap") then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = MAP_FOLDER_NAME
	folder:SetAttribute("IsGeneratedTestMap", true)
	folder:SetAttribute("MapType", "TestMap")
	folder:SetAttribute("MapName", "Cursed Temple Test Arena")
	folder.Parent = workspace
	return folder
end

local DARK_STONE = Color3.fromRGB(72, 65, 55)
local MID_STONE = Color3.fromRGB(105, 95, 82)
local CYAN = Color3.fromRGB(40, 200, 210)
local RED = Color3.fromRGB(210, 60, 60)
local GOLD = Color3.fromRGB(210, 175, 55)
local PURPLE = Color3.fromRGB(120, 60, 160)

local function buildMap(folder)
	-- Floor
	local floor = makePart("TempleFloor", Vector3.new(180, 1, 180), Vector3.new(0, 0, 0), DARK_STONE, Enum.Material.Slate, folder)

	-- Outer walls (with openings at north thief entrance and south extract)
	makePart("WallNorthEast", Vector3.new(66, 20, 3), Vector3.new(57, 10, -90), MID_STONE, Enum.Material.Brick, folder)
	makePart("WallNorthWest", Vector3.new(66, 20, 3), Vector3.new(-57, 10, -90), MID_STONE, Enum.Material.Brick, folder)
	makePart("WallSouth", Vector3.new(180, 20, 3), Vector3.new(0, 10, 90), MID_STONE, Enum.Material.Brick, folder)
	makePart("WallEast", Vector3.new(3, 20, 180), Vector3.new(90, 10, 0), MID_STONE, Enum.Material.Brick, folder)
	makePart("WallWest", Vector3.new(3, 20, 180), Vector3.new(-90, 10, 0), MID_STONE, Enum.Material.Brick, folder)

	-- Internal vault chamber walls (3 openings: west, east, south)
	makePart("VaultWallNorth", Vector3.new(60, 14, 3), Vector3.new(0, 7, -30), MID_STONE, Enum.Material.Brick, folder)
	makePart("VaultWallEastSeg1", Vector3.new(3, 14, 24), Vector3.new(30, 7, -6), MID_STONE, Enum.Material.Brick, folder)
	makePart("VaultWallEastSeg2", Vector3.new(3, 14, 24), Vector3.new(30, 7, -54), MID_STONE, Enum.Material.Brick, folder)
	makePart("VaultWallWestSeg1", Vector3.new(3, 14, 24), Vector3.new(-30, 7, -6), MID_STONE, Enum.Material.Brick, folder)
	makePart("VaultWallWestSeg2", Vector3.new(3, 14, 24), Vector3.new(-30, 7, -54), MID_STONE, Enum.Material.Brick, folder)

	-- North corridor walls (funnel from thief entrance to north objective)
	makePart("NorthCorridorWallE", Vector3.new(3, 14, 30), Vector3.new(18, 7, -60), MID_STONE, Enum.Material.Brick, folder)
	makePart("NorthCorridorWallW", Vector3.new(3, 14, 30), Vector3.new(-18, 7, -60), MID_STONE, Enum.Material.Brick, folder)

	-- East objective room walls
	makePart("EastRoomWallN", Vector3.new(24, 14, 3), Vector3.new(66, 7, -18), MID_STONE, Enum.Material.Brick, folder)
	makePart("EastRoomWallS", Vector3.new(24, 14, 3), Vector3.new(66, 7, 18), MID_STONE, Enum.Material.Brick, folder)

	-- West objective room walls
	makePart("WestRoomWallN", Vector3.new(24, 14, 3), Vector3.new(-66, 7, -18), MID_STONE, Enum.Material.Brick, folder)
	makePart("WestRoomWallS", Vector3.new(24, 14, 3), Vector3.new(-66, 7, 18), MID_STONE, Enum.Material.Brick, folder)

	-- Pillars (LOS breakers in central area)
	local pillarPositions = {
		Vector3.new(-14, 7, -16), Vector3.new(14, 7, -16),
		Vector3.new(-14, 7, 16), Vector3.new(14, 7, 16),
		Vector3.new(-22, 7, 0), Vector3.new(22, 7, 0),
		Vector3.new(0, 7, -22), Vector3.new(0, 7, 22),
	}
	for i, pos in ipairs(pillarPositions) do
		makePart("Pillar_" .. i, Vector3.new(5, 14, 5), pos, DARK_STONE, Enum.Material.Brick, folder)
	end

	-- Vault pedestal
	local pedestal = makePart("IdolPedestal", Vector3.new(6, 4, 6), Vector3.new(0, 2, -15), GOLD, Enum.Material.Metal, folder)

	-- Vault door marker
	local vaultDoor = makePart("VaultDoor", Vector3.new(10, 8, 1), Vector3.new(0, 4.5, -14), GOLD, Enum.Material.Metal, folder)
	vaultDoor.Transparency = 0.3
	tag(vaultDoor, "Vault")
	setAttribs(vaultDoor, { VaultId = "MainVault", VaultOpen = false })

	-- Idol placeholder
	local idol = makePart("IdolPlaceholder", Vector3.new(3, 5, 3), Vector3.new(0, 6.5, -15), GOLD, Enum.Material.Neon, folder)
	idol.Transparency = 0.2
	tag(idol, "Idol")
	setAttribs(idol, { IdolId = "MainIdol", IdolState = "Locked" })

	-- Objective stations
	-- Named Brazier1/2/3 for BrazierManager visual compat.
	-- ObjectiveStation tag + ObjectiveId attribute is authoritative for ObjectiveService.
	-- BrazierName is temporary visual compat only.
	local objDefs = {
		{
			name = "Brazier1",
			displayName = "FLAME SEAL",
			id = "FlameSeal",
			pos = Vector3.new(0, 2.5, -55),
			color = Color3.fromRGB(210, 100, 40),
		},
		{
			name = "Brazier2",
			displayName = "MOON LOCK",
			id = "MoonLock",
			pos = Vector3.new(55, 2.5, 0),
			color = CYAN,
		},
		{
			name = "Brazier3",
			displayName = "STONE SIGIL",
			id = "StoneSigil",
			pos = Vector3.new(-55, 2.5, 0),
			color = Color3.fromRGB(160, 155, 145),
		},
	}

	for _, def in ipairs(objDefs) do
		local base = makePart(def.name .. "_Base", Vector3.new(8, 3, 8), def.pos - Vector3.new(0, 1, 0), MID_STONE, Enum.Material.Brick, folder)

		local station = makePart(def.name, Vector3.new(4, 5, 4), def.pos, def.color, Enum.Material.Neon, folder)
		station.Transparency = 0.2

		tag(station, "ObjectiveStation")
		-- Also tag as Brazier so BrazierManager can find it for visuals
		tag(station, "Brazier")
		setAttribs(station, {
			ObjectiveId = def.id,
			ObjectiveName = def.displayName,
			ObjectiveProgress = 0,
			ObjectiveCompleted = false,
		})
	end

	-- Extract points
	local extractDefs = {
		{
			name = "Extract_JungleGate",
			id = "JungleGate",
			label = "JUNGLE GATE",
			pos = Vector3.new(0, 1.2, -82),
			size = Vector3.new(24, 1, 12),
		},
		{
			name = "Extract_BrokenBridge",
			id = "BrokenBridge",
			label = "BROKEN BRIDGE",
			pos = Vector3.new(0, 1.2, 82),
			size = Vector3.new(24, 1, 12),
		},
	}

	for _, def in ipairs(extractDefs) do
		local zone = makePart(def.name, def.size, def.pos, CYAN, Enum.Material.Neon, folder)
		zone.CanCollide = false
		zone.Transparency = 0.55
		tag(zone, "ExtractPoint")
		setAttribs(zone, { ExtractId = def.id, ExtractName = def.label })
	end

	-- Thief spawns
	local thiefPositions = {
		Vector3.new(-24, 1.5, -75),
		Vector3.new(-8, 1.5, -75),
		Vector3.new(8, 1.5, -75),
		Vector3.new(24, 1.5, -75),
	}
	for i, pos in ipairs(thiefPositions) do
		local sp = makeMarker("ThiefSpawn_" .. i, Vector3.new(4, 1, 4), pos, CYAN, folder)
		tag(sp, "ThiefSpawn")
		setAttribs(sp, { SpawnRole = "Thief", SpawnIndex = i })
	end

	-- Guardian spawn
	local gSpawn = makeMarker("GuardianSpawn_1", Vector3.new(5, 1, 5), Vector3.new(0, 1.5, 18), RED, folder)
	tag(gSpawn, "GuardianSpawn")
	setAttribs(gSpawn, { SpawnRole = "Guardian" })

	-- Cage/holding area
	local cageFloor = makePart("CageFloor", Vector3.new(18, 1, 18), Vector3.new(-70, 1, 60), PURPLE, Enum.Material.SmoothPlastic, folder)
	cageFloor.Transparency = 0.3

	local cageWall1 = makePart("CageWall_N", Vector3.new(18, 8, 2), Vector3.new(-70, 5, 51), DARK_STONE, Enum.Material.Brick, folder)
	local cageWall2 = makePart("CageWall_E", Vector3.new(2, 8, 18), Vector3.new(-61, 5, 60), DARK_STONE, Enum.Material.Brick, folder)
	local cageWall3 = makePart("CageWall_S", Vector3.new(18, 8, 2), Vector3.new(-70, 5, 69), DARK_STONE, Enum.Material.Brick, folder)

	local cageSpawn = makeMarker("CageSpawn", Vector3.new(6, 1, 6), Vector3.new(-70, 2, 60), RED, folder)
	tag(cageSpawn, "CageSpawn")
	setAttribs(cageSpawn, { CageId = "MainCage" })

	-- Simple test lighting (do not override real map lighting)
	pcall(function()
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.4
		Lighting.Ambient = Color3.fromRGB(20, 22, 35)
		Lighting.OutdoorAmbient = Color3.fromRGB(15, 18, 30)
	end)
end

-- Public API

function TestMapService.Init()
	-- Check if real map is loaded (BuildTemple tags its output)
	-- If RealMapLoaded exists, skip test map creation for gameplay tags
	-- NOTE: We still run because BuildTemple has NO gameplay tags.
	-- TestMapService adds ONLY gameplay-tagged parts alongside aesthetic geometry.
	local realMapFolder = workspace:FindFirstChild("LIFTED_RealMap")
	if realMapFolder then
		return
	end

	for _, instance in ipairs(CollectionService:GetTagged(REAL_MAP_TAG)) do
		if instance and instance.Parent then
			return
		end
	end

	local existing = workspace:FindFirstChild(MAP_FOLDER_NAME)
	if existing and existing:GetAttribute("IsGeneratedTestMap") then
		return -- Already built this session
	end

	local folder = getOrCreateFolder()
	buildMap(folder)
	print("[TestMapService] Test map built: " .. MAP_FOLDER_NAME)
end

function TestMapService.Rebuild()
	local existing = workspace:FindFirstChild(MAP_FOLDER_NAME)
	if existing and existing:GetAttribute("IsGeneratedTestMap") then
		existing:Destroy()
	end
	local folder = getOrCreateFolder()
	buildMap(folder)
	print("[TestMapService] Test map rebuilt.")
end

function TestMapService.GetFolder()
	return workspace:FindFirstChild(MAP_FOLDER_NAME)
end

return TestMapService
