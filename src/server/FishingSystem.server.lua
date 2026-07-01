-- FishingSystem
-- FishingSystem
-- Fishing mechanics: fish formula, timing bar, catch cycle

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(ServerScriptService.DataManager)
local FishData = require(ServerScriptService.FishData)

-- Wait for GameManager to create RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CastRod = RemoteEvents:WaitForChild("CastRod")
local CatchFish = RemoteEvents:WaitForChild("CatchFish")
local UpdateInventory = RemoteEvents:WaitForChild("UpdateInventory")
local UpdateWeather = RemoteEvents:WaitForChild("UpdateWeather")
local FishSpoiled = RemoteEvents:WaitForChild("FishSpoiled")

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

	-- Використовуємо РЕАЛЬНУ рідкість спійманої риби, а не ту, що випала
	-- в rollRarity — getRandomFishByRarity міг підмінити її на Common,
	-- якщо для випавшої рідкості не знайшлось риби за поточних умов
	local caughtFish = {
		name = fishName,
		rarity = fishInfo.rarity,
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
			.. " (" .. fishInfo.rarity .. ")")
		CatchFish:FireClient(player, caughtFish)
		UpdateInventory:FireClient(player, data.inventory)
	else
		print("[FishingSystem] Інвентар повний для: " .. player.Name)
		CatchFish:FireClient(player, nil, "full")
	end
end

-- ==============================
-- FISH SPOILAGE (D2/F3)
-- ==============================

local SPOIL_CHECK_INTERVAL = 30 -- секунд

-- Прибирає протухлу рибу з рюкзака (spoilTimer рахується від caughtAt,
-- тому час офлайн враховується автоматично — окрема логіка для входу не потрібна)
local function removeSpoiledFish(data)
	local removed = 0
	local i = 1
	while i <= #data.inventory.fish do
		local fish = data.inventory.fish[i]
		if fish.spoilTimer ~= math.huge and (os.time() - fish.caughtAt) >= fish.spoilTimer then
			table.remove(data.inventory.fish, i)
			removed = removed + 1
		else
			i = i + 1
		end
	end
	return removed
end

local function checkPlayerSpoilage(player)
	local data = DataManager.getData(player)
	if not data then return end

	local removed = removeSpoiledFish(data)
	if removed > 0 then
		print("[FishingSystem] Протухло риби в " .. player.Name .. ": " .. removed)
		UpdateInventory:FireClient(player, data.inventory)
		FishSpoiled:FireClient(player, removed)
	end
end

-- Періодична перевірка всіх активних гравців
task.spawn(function()
	while true do
		task.wait(SPOIL_CHECK_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			checkPlayerSpoilage(player)
		end
	end
end)

-- Одразу перевіряємо при вході (риба могла протухнути, поки гравця не було)
Players.PlayerAdded:Connect(function(player)
	task.wait(1) -- даємо DataManager час завантажити дані
	checkPlayerSpoilage(player)
end)

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