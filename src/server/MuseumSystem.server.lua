-- MuseumSystem
-- MuseumSystem
-- Handles museum donations, rarity caps, collection bonus, offline passive income (D3/F3)

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(ServerScriptService.DataManager)
local FishData = require(ServerScriptService.FishData)
local EconomyUtils = require(ServerScriptService.EconomyUtils)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local AddToMuseum = RemoteEvents:WaitForChild("AddToMuseum")
local RequestMuseum = RemoteEvents:WaitForChild("RequestMuseum")
local UpdateMuseum = RemoteEvents:WaitForChild("UpdateMuseum")
local UpdateInventory = RemoteEvents:WaitForChild("UpdateInventory")
local ShowNotification = RemoteEvents:WaitForChild("ShowNotification")

-- ==============================
-- CONSTANTS
-- ==============================

-- D3: ліміт екземплярів одного виду в музеї, за рідкістю
local rarityCaps = {
	Common    = 6,
	Uncommon  = 5,
	Rare      = 4,
	Epic      = 3,
	Legendary = 2,
}

-- Той самий бонус префікса, що й при продажу (E2)
local prefixBonuses = {
	Rainy    = 0.10,
	Dusk     = 0.15,
	Midnight = 0.20,
	Stormy   = 0.35,
	Misty    = 0.35,
}

local OFFLINE_INCOME_CAP_MINUTES = 2880 -- 48 год (F3)

local function getSpeciesInZone(zone)
	local species = {}
	for name, info in pairs(FishData) do
		if info.zone == zone then
			table.insert(species, name)
		end
	end
	return species
end

local zoneSpecies = { [1] = getSpeciesInZone(1), [2] = getSpeciesInZone(2) }

-- ==============================
-- HELPERS
-- ==============================

local function ensureMuseumShape(data)
	data.museum = data.museum or {}
	data.museum.fish = data.museum.fish or {}
end

local function notify(player, text, color, borderColor)
	ShowNotification:FireClient(player, text, color, borderColor)
end

local function findFishInInventory(inventory, fishName, prefix)
	for i, fish in ipairs(inventory.fish) do
		if fish.name == fishName and fish.prefix == prefix then
			return i, fish
		end
	end
	return nil, nil
end

-- РІШЕННЯ: +100% вимагає повної колекції ВСЬОГО музею (обидві зони на
-- максимумі кожного виду), а не тільки однієї зони — документ E2/D3 оновлено
local function isMuseumFullyMaxed(museumFish)
	local countByName = {}
	for _, specimen in ipairs(museumFish) do
		countByName[specimen.name] = (countByName[specimen.name] or 0) + 1
	end

	for name, info in pairs(FishData) do
		local cap = rarityCaps[info.rarity] or 1
		if (countByName[name] or 0) < cap then
			return false
		end
	end
	return true
end

-- E2: +30% якщо в музеї є хоча б 1 екземпляр кожного виду ЦІЄЇ зони,
-- +100% (замінює +30% в ОБОХ зонах) якщо весь музей зібраний по максимуму
local function getCollectionBonus(zone, museumFish, museumFullyMaxed)
	if museumFullyMaxed then return 1.0 end

	local species = zoneSpecies[zone]
	if not species or #species == 0 then return 0 end

	local countByName = {}
	for _, specimen in ipairs(museumFish) do
		countByName[specimen.name] = (countByName[specimen.name] or 0) + 1
	end

	for _, name in ipairs(species) do
		if (countByName[name] or 0) == 0 then return 0 end
	end
	return 0.3
end

local function getIncomeRate(specimen, collectionBonus)
	local fishInfo = FishData[specimen.name]
	if not fishInfo then return 0 end

	local prefixMult = 1 + (specimen.prefix and prefixBonuses[specimen.prefix] or 0)
	return fishInfo.museumIncome * prefixMult * (1 + collectionBonus)
end

-- Пакує дані музею + прибуток/хв на вид і загалом, для показу в MuseumController
local function buildMuseumPayload(data)
	ensureMuseumShape(data)
	local museumFish = data.museum.fish
	local museumFullyMaxed = isMuseumFullyMaxed(museumFish)

	local zoneBonus = {
		[1] = getCollectionBonus(1, museumFish, museumFullyMaxed),
		[2] = getCollectionBonus(2, museumFish, museumFullyMaxed),
	}

	-- Копія списку "для показу" з indivudual incomeRate — оригінал
	-- (data.museum.fish) лишаємо чистим, щоб не тягнути похідні поля
	-- в DataStore
	local incomeBySpecies = {}
	local totalIncomePerMinute = 0
	local fishForDisplay = {}
	for _, specimen in ipairs(museumFish) do
		local fishInfo = FishData[specimen.name]
		local rate = 0
		if fishInfo then
			rate = getIncomeRate(specimen, zoneBonus[fishInfo.zone] or 0)
			incomeBySpecies[specimen.name] = (incomeBySpecies[specimen.name] or 0) + rate
			totalIncomePerMinute = totalIncomePerMinute + rate
		end
		table.insert(fishForDisplay, {
			name = specimen.name,
			prefix = specimen.prefix,
			prefixBonus = specimen.prefixBonus,
			rarity = specimen.rarity,
			incomeRate = rate,
		})
	end

	return {
		fish = fishForDisplay,
		incomeBySpecies = incomeBySpecies,
		totalIncomePerMinute = totalIncomePerMinute,
	}
end

-- ==============================
-- PASSIVE INCOME (F3: офлайн при вході + онлайн-тікер, поки грає)
-- ==============================

local ONLINE_TICK_INTERVAL = 60 -- секунд

-- Рахує дохід музею за minutesElapsed і нараховує монети (без сповіщення)
local function payIncomeForMinutes(player, data, minutesElapsed)
	ensureMuseumShape(data)
	local museumFish = data.museum.fish
	if #museumFish == 0 or minutesElapsed <= 0 then return 0 end

	local museumFullyMaxed = isMuseumFullyMaxed(museumFish)
	local zoneBonus = {
		[1] = getCollectionBonus(1, museumFish, museumFullyMaxed),
		[2] = getCollectionBonus(2, museumFish, museumFullyMaxed),
	}

	local total = 0
	for _, specimen in ipairs(museumFish) do
		local fishInfo = FishData[specimen.name]
		if fishInfo then
			total = total + getIncomeRate(specimen, zoneBonus[fishInfo.zone] or 0) * minutesElapsed
		end
	end

	total = math.floor(total)
	if total > 0 then
		EconomyUtils.addCoins(player, total)
	end
	return total
end

-- При вході — одноразовий лямп-сум за час офлайн (з тостом)
local function payOfflineIncome(player, data)
	local minutesOffline = math.min(OFFLINE_INCOME_CAP_MINUTES, math.max(0, (os.time() - data.lastOnline) / 60))
	local total = payIncomeForMinutes(player, data, minutesOffline)
	if total > 0 then
		notify(player, "🏛️ While you were away, the museum earned " .. total .. " coins!",
			Color3.fromRGB(255, 215, 0), Color3.fromRGB(200, 150, 0))
	end
	data.lastMuseumPayout = os.time()
end

Players.PlayerAdded:Connect(function(player)
	task.wait(1) -- даємо DataManager час завантажити дані
	local data = DataManager.getData(player)
	if not data then return end
	payOfflineIncome(player, data)
end)

-- Поки гравець онлайн — той самий дохід нараховується періодично
-- (тихо, без тосту; HUD оновлюється сам через EconomyUtils.addCoins)
task.spawn(function()
	while true do
		task.wait(ONLINE_TICK_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = DataManager.getData(player)
			if data then
				data.lastMuseumPayout = data.lastMuseumPayout or os.time()
				local minutesElapsed = (os.time() - data.lastMuseumPayout) / 60
				payIncomeForMinutes(player, data, minutesElapsed)
				data.lastMuseumPayout = os.time()
			end
		end
	end
end)

-- ==============================
-- ADD TO MUSEUM
-- ==============================

AddToMuseum.OnServerEvent:Connect(function(player, fishName, prefix)
	local data = DataManager.getData(player)
	if not data then return end
	ensureMuseumShape(data)

	local fishInfo = FishData[fishName]
	if not fishInfo then return end

	local index, fish = findFishInInventory(data.inventory, fishName, prefix)
	if not index then
		warn("[MuseumSystem] Риба не знайдена в інвентарі: " .. player.Name)
		return
	end

	local cap = rarityCaps[fishInfo.rarity] or 1
	local sameSpeciesCount = 0
	local weakestIndex, weakestBonus = nil, math.huge
	for i, specimen in ipairs(data.museum.fish) do
		if specimen.name == fishName then
			sameSpeciesCount = sameSpeciesCount + 1
			if (specimen.prefixBonus or 0) < weakestBonus then
				weakestIndex = i
				weakestBonus = specimen.prefixBonus or 0
			end
		end
	end

	local function donate()
		table.remove(data.inventory.fish, index)
		table.insert(data.museum.fish, {
			name = fish.name,
			prefix = fish.prefix,
			prefixBonus = fish.prefixBonus,
			rarity = fish.rarity,
		})
		UpdateInventory:FireClient(player, data.inventory)
		UpdateMuseum:FireClient(player, buildMuseumPayload(data))
	end

	if sameSpeciesCount < cap then
		donate()
		notify(player, "🏛️ Added " .. fishName .. " to the museum!",
			Color3.fromRGB(100, 220, 255), Color3.fromRGB(0, 180, 255))
		return
	end

	-- Музей уже має максимум цього виду — заміняємо найслабший екземпляр,
	-- якщо новий має вищий бонус префікса (C3/D3)
	if weakestIndex and (fish.prefixBonus or 0) > weakestBonus then
		table.remove(data.museum.fish, weakestIndex)
		donate()
		notify(player, "🏛️ Replaced a weaker " .. fishName .. " with this one!",
			Color3.fromRGB(100, 220, 255), Color3.fromRGB(0, 180, 255))
	else
		notify(player, "🏛️ Museum already has the best " .. fishName .. " specimens!",
			Color3.fromRGB(255, 200, 100), Color3.fromRGB(200, 150, 50))
	end
end)

-- ==============================
-- REQUEST MUSEUM (при відкритті вікна)
-- ==============================

RequestMuseum.OnServerEvent:Connect(function(player)
	local data = DataManager.getData(player)
	if not data then return end
	UpdateMuseum:FireClient(player, buildMuseumPayload(data))
end)

print("[MuseumSystem] Ініціалізовано успішно!")
