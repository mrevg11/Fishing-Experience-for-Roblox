-- WorldBuilder
-- WorldBuilder
-- Будує спільні елементи ландшафту (A1): місток між островами гравців,
-- спільний причал, океан, Зону 1 (Мілководдя) та Зону 2 (Рифи) з
-- FishingSpot-маркерами. Будується один раз при старті сервера —
-- на відміну від HubBuilder, тут немає нічого персонального на гравця.
-- Тимчасова геометрія — заміниться на фінальний 3D-арт друга пізніше.

local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

local WorldConfig = require(ServerScriptService.WorldConfig)

local worldFolder = Instance.new("Folder")
worldFolder.Name = "World"
worldFolder.Parent = Workspace

local CENTER_X_GLOBAL = WorldConfig.HUB_ORIGIN.X + WorldConfig.CENTER_X

-- ==============================
-- МІСТОК МІЖ ОСТРОВАМИ
-- ==============================

local function buildWalkway()
	local startZ = WorldConfig.firstIslandEdgeZ()
	local endZ = WorldConfig.lastIslandEdgeZ()
	local length = endZ - startZ

	local walkway = Instance.new("Part")
	walkway.Name = "Walkway"
	walkway.Size = Vector3.new(WorldConfig.WALKWAY_WIDTH, 1, length)
	walkway.Position = Vector3.new(CENTER_X_GLOBAL, 0, startZ + length / 2)
	walkway.Anchored = true
	walkway.Color = Color3.fromRGB(170, 140, 100)
	walkway.Material = Enum.Material.WoodPlanks
	walkway.Parent = worldFolder
end

-- ==============================
-- СПІЛЬНИЙ ПРИЧАЛ
-- ==============================

local function buildPier()
	local pier = Instance.new("Part")
	pier.Name = "Pier"
	pier.Size = Vector3.new(20, 1, 100)
	pier.Position = Vector3.new(CENTER_X_GLOBAL, 0, WorldConfig.pierZ())
	pier.Anchored = true
	pier.Color = Color3.fromRGB(160, 120, 80)
	pier.Material = Enum.Material.WoodPlanks
	pier.Parent = worldFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 80
	billboard.Parent = pier

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Pier (party boats coming soon)"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard
end

-- ==============================
-- ОКЕАН
-- ==============================

local function buildOcean()
	local ocean = Instance.new("Part")
	ocean.Name = "Ocean"
	ocean.Size = Vector3.new(WorldConfig.OCEAN_WIDTH, 1, WorldConfig.OCEAN_LENGTH)
	ocean.Position = Vector3.new(
		CENTER_X_GLOBAL,
		-0.5,
		WorldConfig.oceanStartZ() + WorldConfig.OCEAN_LENGTH / 2
	)
	ocean.Anchored = true
	ocean.CanCollide = false
	ocean.Transparency = 0.3
	ocean.Color = Color3.fromRGB(30, 120, 200)
	ocean.Material = Enum.Material.Glass
	ocean.Parent = worldFolder
end

-- ==============================
-- РИБОЛОВНІ ЗОНИ
-- ==============================

local function buildFishingSpot(parentFolder, name, zone, index, position)
	local spot = Instance.new("Part")
	spot.Name = name
	spot.Shape = Enum.PartType.Cylinder
	spot.Size = Vector3.new(2, WorldConfig.SPOT_RADIUS * 2, WorldConfig.SPOT_RADIUS * 2)
	spot.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	spot.Anchored = true
	spot.CanCollide = false
	spot.Transparency = 0.7
	spot.Color = Color3.fromRGB(120, 220, 255)
	spot.Material = Enum.Material.Neon
	spot:SetAttribute("Zone", zone)
	spot:SetAttribute("SpotIndex", index)
	spot.Parent = parentFolder
end

local function buildZone(name, zone, centerZ, color, label)
	local zoneFolder = Instance.new("Folder")
	zoneFolder.Name = name
	zoneFolder.Parent = worldFolder

	local centerPos = Vector3.new(CENTER_X_GLOBAL, 0.5, centerZ)

	local island = Instance.new("Part")
	island.Name = "ResourceIsland"
	island.Size = Vector3.new(120, 1, 120)
	island.Position = centerPos
	island.Anchored = true
	island.Color = color
	island.Material = Enum.Material.Ground
	island.Parent = zoneFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 240, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 15, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 300
	billboard.Parent = island

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = label
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextStrokeTransparency = 0
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	local d = WorldConfig.SPOT_DISTANCE_FROM_CENTER
	local spotOffsets = {
		Vector3.new(0, 0, d),
		Vector3.new(d * 0.87, 0, -d * 0.5),
		Vector3.new(-d * 0.87, 0, -d * 0.5),
	}
	for i, offset in ipairs(spotOffsets) do
		buildFishingSpot(zoneFolder, "FishingSpot" .. i, zone, i, centerPos + offset)
	end
end

buildWalkway()
buildPier()
buildOcean()
buildZone("Zone1", 1, WorldConfig.zone1CenterZ(), Color3.fromRGB(210, 200, 140), "Zone 1: Shallows (Free)")
buildZone("Zone2", 2, WorldConfig.zone2CenterZ(), Color3.fromRGB(180, 160, 200), "Zone 2: The Reefs (15,000 coins/week)")

print("[WorldBuilder] Спільний ландшафт (місток/причал/океан/зони) згенеровано!")
