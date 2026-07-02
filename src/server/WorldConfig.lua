-- WorldConfig
-- Спільні геометричні константи ландшафту: острови гравців, місток,
-- причал, океан, риболовні зони. Використовується HubBuilder і WorldBuilder.

local WorldConfig = {}

WorldConfig.HUB_ORIGIN = Vector3.new(0, 1, 60)
WorldConfig.MAX_SLOTS = 8
WorldConfig.ISLAND_SPACING = 100 -- відстань по Z між сусідніми островами

-- Точки хабу на острові розташовані по X від -280 (Tutorial NPC) до 200
-- (Quest Board), тому центр острова зміщений відносно origin
WorldConfig.CENTER_X = -40
WorldConfig.ISLAND_WIDTH = 600
WorldConfig.ISLAND_DEPTH = 60

WorldConfig.WALKWAY_WIDTH = 40

WorldConfig.PIER_GAP = 50   -- відстань від краю останнього острова до причалу
WorldConfig.OCEAN_GAP = 80  -- відстань від причалу до початку океану
WorldConfig.OCEAN_LENGTH = 700
WorldConfig.OCEAN_WIDTH = 3000

WorldConfig.ZONE1_OFFSET = 200  -- від початку океану
WorldConfig.ZONE2_OFFSET = 450
WorldConfig.SPOT_RADIUS = 80
WorldConfig.SPOT_DISTANCE_FROM_CENTER = 150 -- на скільки FishingSpot винесені від центру зони

function WorldConfig.islandOrigin(slotIndex)
	return WorldConfig.HUB_ORIGIN + Vector3.new(0, 0, (slotIndex - 1) * WorldConfig.ISLAND_SPACING)
end

function WorldConfig.firstIslandEdgeZ()
	return WorldConfig.HUB_ORIGIN.Z - WorldConfig.ISLAND_DEPTH / 2
end

function WorldConfig.lastIslandZ()
	return WorldConfig.HUB_ORIGIN.Z + (WorldConfig.MAX_SLOTS - 1) * WorldConfig.ISLAND_SPACING
end

function WorldConfig.lastIslandEdgeZ()
	return WorldConfig.lastIslandZ() + WorldConfig.ISLAND_DEPTH / 2
end

function WorldConfig.pierZ()
	return WorldConfig.lastIslandEdgeZ() + WorldConfig.PIER_GAP
end

function WorldConfig.oceanStartZ()
	return WorldConfig.pierZ() + WorldConfig.OCEAN_GAP
end

function WorldConfig.zone1CenterZ()
	return WorldConfig.oceanStartZ() + WorldConfig.ZONE1_OFFSET
end

function WorldConfig.zone2CenterZ()
	return WorldConfig.oceanStartZ() + WorldConfig.ZONE2_OFFSET
end

return WorldConfig
