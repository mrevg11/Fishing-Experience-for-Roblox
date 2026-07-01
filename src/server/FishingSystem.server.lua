-- FishingSystem
-- FishingSystem
-- Fishing mechanics: fish formula, timing bar, catch cycle

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(ServerScriptService.DataManager)

-- Wait for GameManager to create RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CastRod = RemoteEvents:WaitForChild("CastRod")
local CatchFish = RemoteEvents:WaitForChild("CatchFish")
local UpdateInventory = RemoteEvents:WaitForChild("UpdateInventory")
local UpdateWeather = RemoteEvents:WaitForChild("UpdateWeather")

-- ==============================
-- FISH DATA
-- ==============================

local FishData = {
	-- ZONE 1 — SHALLOWS
	["Perch"]           = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 10,   museumIncome = 1.0,  spoilTime = 1800 },
	["Pond Lurker"]     = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 12,   museumIncome = 1.2,  spoilTime = 1800 },
	["Roach"]           = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 10,   museumIncome = 1.0,  spoilTime = 1800 },
	["Goby"]            = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 11,   museumIncome = 1.1,  spoilTime = 1800 },
	["Surf Crab"]       = { rarity = "Common",    zone = 1, condition = "anytime", basePrice = 13,   museumIncome = 1.3,  spoilTime = 1800 },
	["Serpent Crawler"] = { rarity = "Uncommon",  zone = 1, condition = "anytime", basePrice = 32,   museumIncome = 3.0,  spoilTime = 3600 },
	["Silver Bream"]    = { rarity = "Uncommon",  zone = 1, condition = "anytime", basePrice = 38,   museumIncome = 3.5,  spoilTime = 3600 },
	["Copper Eel"]      = { rarity = "Rare",      zone = 1, condition = "anytime", basePrice = 110,  museumIncome = 8.5,  spoilTime = 10800 },
	["Goldfin Pike"]    = { rarity = "Rare",      zone = 1, condition = "anytime", basePrice = 120,  museumIncome = 9.0,  spoilTime = 10800 },
	["Guardian Crab"]   = { rarity = "Epic",      zone = 1, condition = "day",     basePrice = 360,  museumIncome = 20.0, spoilTime = 43200 },
	["Armored Catfish"] = { rarity = "Epic",      zone = 1, condition = "day",     basePrice = 400,  museumIncome = 22.0, spoilTime = 43200 },
	["Sun Ray"]         = { rarity = "Legendary", zone = 1, condition = "day",     basePrice = 1300, museumIncome = 65.0, spoilTime = math.huge },
	["Moon Serpent"]    = { rarity = "Legendary", zone = 1, condition = "night",   basePrice = 1800, museumIncome = 80.0, spoilTime = math.huge },
	["Misty Tench"]     = { rarity = "Epic",      zone = 1, condition = "fog",     basePrice = 420,  museumIncome = 25.0, spoilTime = 43200 },
	["Thunder Jaw"]     = { rarity = "Legendary", zone = 1, condition = "storm",   basePrice = 2200, museumIncome = 90.0, spoilTime = math.huge },

	-- ZONE 2 — THE REEFS
	["Pearl Grouper"]       = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 14,   museumIncome = 1.4,  spoilTime = 1800 },
	["Painted Wrasse"]      = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 13,   museumIncome = 1.3,  spoilTime = 1800 },
	["Red Mullet"]          = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 11,   museumIncome = 1.1,  spoilTime = 1800 },
	["Spiny Drifter"]       = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 12,   museumIncome = 1.2,  spoilTime = 1800 },
	["Sea Urchin"]          = { rarity = "Common",    zone = 2, condition = "anytime", basePrice = 10,   museumIncome = 1.0,  spoilTime = 1800 },
	["Tiger Moray"]         = { rarity = "Uncommon",  zone = 2, condition = "anytime", basePrice = 40,   museumIncome = 3.8,  spoilTime = 3600 },
	["Blue Scorpionfish"]   = { rarity = "Uncommon",  zone = 2, condition = "anytime", basePrice = 45,   museumIncome = 4.0,  spoilTime = 3600 },
	["Reef Loach"]          = { rarity = "Rare",      zone = 2, condition = "anytime", basePrice = 105,  museumIncome = 8.0,  spoilTime = 10800 },
	["Clownfish"]           = { rarity = "Rare",      zone = 2, condition = "anytime", basePrice = 130,  museumIncome = 9.5,  spoilTime = 10800 },
	["Flame Anemone"]       = { rarity = "Epic",      zone = 2, condition = "day",     basePrice = 370,  museumIncome = 21.0, spoilTime = 43200 },
	["Coral Jellyfish"]     = { rarity = "Epic",      zone = 2, condition = "day",     basePrice = 420,  museumIncome = 23.0, spoilTime = 43200 },
	["Crystal Shark"]       = { rarity = "Legendary", zone = 2, condition = "day",     basePrice = 1500, museumIncome = 70.0, spoilTime = math.huge },
	["Reef Phantom"]        = { rarity = "Legendary", zone = 2, condition = "night",   basePrice = 2000, museumIncome = 85.0, spoilTime = math.huge },
	["Milky Chimera"]       = { rarity = "Legendary", zone = 2, condition = "fog",     basePrice = 2400, museumIncome = 95.0, spoilTime = math.huge },
	["Lightning Barracuda"] = { rarity = "Legendary", zone = 2, condition = "storm",   basePrice = 2600, museumIncome = 100.0, spoilTime = math.huge },
}

-- ==============================
-- WEATHER AND TIME SYSTEM
-- ==============================

local currentWeather = "clear"
local currentTimeOfDay = "morning"

-- Момент (os.clock()), коли відбудеться наступна зміна погоди/фази доби
local weatherNextChangeAt = 0
local phaseNextChangeAt = 0

local weatherChances = {
	{ weather = "clear",  chance = 35 },
	{ weather = "cloudy", chance = 30 },
	{ weather = "rain",   chance = 20 },
	{ weather = "fog",    chance = 10 },
	{ weather = "storm",  chance = 5  },
}

local function secondsLeft(nextChangeAt)
	return math.max(0, math.floor(nextChangeAt - os.clock()))
end

local function broadcastWeather(targetPlayer)
	local weatherSecondsLeft = secondsLeft(weatherNextChangeAt)
	local phaseSecondsLeft = secondsLeft(phaseNextChangeAt)
	if targetPlayer then
		UpdateWeather:FireClient(targetPlayer, currentWeather, currentTimeOfDay, weatherSecondsLeft, phaseSecondsLeft)
	else
		UpdateWeather:FireAllClients(currentWeather, currentTimeOfDay, weatherSecondsLeft, phaseSecondsLeft)
	end
end

local function rollWeather()
	local roll = math.random(1, 100)
	local cumulative = 0
	for _, entry in ipairs(weatherChances) do
		cumulative = cumulative + entry.chance
		if roll <= cumulative then
			currentWeather = entry.weather
			print("[FishingSystem] Погода змінилась: " .. currentWeather)
			broadcastWeather()
			return
		end
	end
end

local timeOfDaySchedule = {
	{ phase = "morning", duration = 10 * 60 },
	{ phase = "day",     duration = 20 * 60 },
	{ phase = "evening", duration = 15 * 60 },
	{ phase = "night",   duration = 15 * 60 },
}

local WEATHER_CHANGE_INTERVAL = 10 * 60

-- Weather cycle
task.spawn(function()
	while true do
		weatherNextChangeAt = os.clock() + WEATHER_CHANGE_INTERVAL
		task.wait(WEATHER_CHANGE_INTERVAL)
		rollWeather()
	end
end)

-- Day/night cycle
task.spawn(function()
	while true do
		for _, phase in ipairs(timeOfDaySchedule) do
			currentTimeOfDay = phase.phase
			phaseNextChangeAt = os.clock() + phase.duration
			print("[FishingSystem] Час доби: " .. currentTimeOfDay)
			broadcastWeather()
			task.wait(phase.duration)
		end
	end
end)

-- Надсилаємо новому гравцю поточний стан погоди/часу доби + таймери
Players.PlayerAdded:Connect(function(player)
	broadcastWeather(player)
end)

-- ==============================
-- FISH FORMULA
-- ==============================

local rarityBaseChances = {
	Common    = 55,
	Uncommon  = 25,
	Rare      = 12,
	Epic      = 6,
	Legendary = 2,
}

local function getTimeMultiplier(rarity)
	if currentTimeOfDay == "morning" and rarity == "Common" then return 1.1 end
	if currentTimeOfDay == "evening" and rarity == "Rare" then return 1.15 end
	if currentTimeOfDay == "night" and (rarity == "Epic" or rarity == "Legendary") then return 1.1 end
	return 1.0
end

local function getWeatherMultiplier(rarity)
	if currentWeather == "cloudy" and rarity == "Rare" then return 1.1 end
	if currentWeather == "rain" and (rarity == "Rare" or rarity == "Epic") then return 1.2 end
	if currentWeather == "fog" then
		if rarity == "Common" then return 0.7
		elseif rarity == "Uncommon" then return 1.2
		elseif rarity == "Rare" then return 1.4
		elseif rarity == "Epic" then return 1.3
		elseif rarity == "Legendary" then return 1.2
		end
	end
	if currentWeather == "storm" and (rarity == "Epic" or rarity == "Legendary") then return 1.35 end
	return 1.0
end

local function isConditionMet(condition)
	if condition == "anytime" then return true end
	if condition == "day" and currentTimeOfDay == "day" then return true end
	if condition == "night" and currentTimeOfDay == "night" then return true end
	if condition == "fog" and currentWeather == "fog" then return true end
	if condition == "storm" and currentWeather == "storm" then return true end
	return false
end

local function rollRarity(barMultiplier, inFishingSpot)
	local spotMultiplier = inFishingSpot and 1.2 or 0.8
	local roll = math.random(1, 10000) / 100
	local rarityOrder = {"Legendary", "Epic", "Rare", "Uncommon", "Common"}
	local cumulative = 0

	for _, rarity in ipairs(rarityOrder) do
		local chance = rarityBaseChances[rarity]
			* barMultiplier
			* getTimeMultiplier(rarity)
			* getWeatherMultiplier(rarity)
			* spotMultiplier
		cumulative = cumulative + chance
		if roll <= cumulative then
			return rarity
		end
	end
	return "Common"
end

local function getRandomFishByRarity(rarity, zone)
	local candidates = {}
	for name, data in pairs(FishData) do
		if data.rarity == rarity
			and data.zone == zone
			and isConditionMet(data.condition) then
			table.insert(candidates, name)
		end
	end

	if #candidates == 0 then
		for name, data in pairs(FishData) do
			if data.rarity == "Common" and data.zone == zone then
				table.insert(candidates, name)
			end
		end
	end

	if #candidates == 0 then return nil end
	return candidates[math.random(1, #candidates)]
end

local function rollPrefix(barResult)
	local prefixChances = {
		{ condition = "rain",    prefix = "Rainy",    bonus = 0.10, chance = 15 },
		{ condition = "evening", prefix = "Dusk",     bonus = 0.15, chance = 10 },
		{ condition = "night",   prefix = "Midnight", bonus = 0.20, chance = 8  },
		{ condition = "storm",   prefix = "Stormy",   bonus = 0.35, chance = 4  },
		{ condition = "fog",     prefix = "Misty",    bonus = 0.35, chance = 4  },
	}

	local active = {}
	for _, entry in ipairs(prefixChances) do
		if entry.condition == currentWeather or entry.condition == currentTimeOfDay then
			table.insert(active, entry)
		end
	end

	if #active == 0 then return nil, 0 end

	local chosen = active[math.random(1, #active)]
	-- C3: ідеальний хіт бару (🔵 perfect) → +5% до шансу префікса
	local chance = chosen.chance + (barResult == "perfect" and 5 or 0)
	local roll = math.random(1, 100)
	if roll <= chance then
		return chosen.prefix, chosen.bonus
	end

	return nil, 0
end

-- ==============================
-- MAIN CATCH FUNCTION
-- ==============================

local barMultipliers = {
	weak    = 0.5,
	medium  = 1.0,
	good    = 1.5,
	perfect = 2.0,
}

local function catchFish(player, barResult, inFishingSpot, zone)
	local data = DataManager.getData(player)
	if not data then return end

	local multiplier = barMultipliers[barResult] or 1.0
	local rarity = rollRarity(multiplier, inFishingSpot)
	local fishName = getRandomFishByRarity(rarity, zone or 1)

	if not fishName then
		print("[FishingSystem] Риба не знайдена для рідкості: " .. rarity)
		return
	end

	local fishInfo = FishData[fishName]
	local prefix, prefixBonus = rollPrefix(barResult)

	local caughtFish = {
		name = fishName,
		rarity = rarity,
		prefix = prefix,
		prefixBonus = prefixBonus,
		spoilTimer = fishInfo.spoilTime,
		caughtAt = os.time(),
	}

	local maxSlots = 10 + (data.backpackLevel - 1) * 5
	if #data.inventory.fish < maxSlots then
		table.insert(data.inventory.fish, caughtFish)
		print("[FishingSystem] " .. player.Name .. " спіймав: "
			.. (prefix and prefix .. " " or "") .. fishName
			.. " (" .. rarity .. ")")
		CatchFish:FireClient(player, caughtFish)
		UpdateInventory:FireClient(player, data.inventory)
	else
		print("[FishingSystem] Інвентар повний для: " .. player.Name)
		CatchFish:FireClient(player, nil, "full")
	end
end

-- ==============================
-- CLIENT EVENT HANDLERS
-- ==============================

CastRod.OnServerEvent:Connect(function(player, barResult, inFishingSpot, zone)
	if not barMultipliers[barResult] then
		warn("[FishingSystem] Невалідний barResult від: " .. player.Name)
		return
	end
	catchFish(player, barResult, inFishingSpot, zone)
end)

print("[FishingSystem] Ініціалізовано успішно!")