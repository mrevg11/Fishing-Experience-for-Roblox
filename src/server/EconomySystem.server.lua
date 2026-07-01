-- EconomySystem
-- EconomySystem
-- Handles fish selling, price calculation, coins management

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(ServerScriptService.DataManager)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local SellFish = RemoteEvents:WaitForChild("SellFish")
local UpdateCoins = RemoteEvents:WaitForChild("UpdateCoins")
local UpdateInventory = RemoteEvents:WaitForChild("UpdateInventory")

-- ==============================
-- PRICE CALCULATION
-- ==============================

local weatherBonusConditions = {"rain", "fog", "storm"}
local timeBonusConditions = {"night", "evening"}

local prefixBonuses = {
	Rainy    = 0.10,
	Dusk     = 0.15,
	Midnight = 0.20,
	Stormy   = 0.35,
	Misty    = 0.35,
}

local function calculatePrice(fish, currentWeather, currentTimeOfDay)
	local basePrice = fish.basePrice
	local multiplier = 1.0

	-- Weather bonus +25%
	for _, condition in ipairs(weatherBonusConditions) do
		if currentWeather == condition then
			multiplier = multiplier + 0.25
			break
		end
	end

	-- Time bonus +25%
	for _, condition in ipairs(timeBonusConditions) do
		if currentTimeOfDay == condition then
			multiplier = multiplier + 0.25
			break
		end
	end

	-- Prefix bonus
	if fish.prefix and prefixBonuses[fish.prefix] then
		multiplier = multiplier + prefixBonuses[fish.prefix]
	end

	return math.floor(basePrice * multiplier)
end

-- ==============================
-- COINS MANAGEMENT
-- ==============================

local function addCoins(player, amount)
	local data = DataManager.getData(player)
	if not data then return end

	data.coins = data.coins + amount
	UpdateCoins:FireClient(player, data.coins)
	print("[EconomySystem] " .. player.Name .. " отримав " .. amount .. " монет. Всього: " .. data.coins)
end

local function removeCoins(player, amount)
	local data = DataManager.getData(player)
	if not data then return false end

	if data.coins < amount then
		return false
	end

	data.coins = data.coins - amount
	UpdateCoins:FireClient(player, data.coins)
	print("[EconomySystem] " .. player.Name .. " витратив " .. amount .. " монет. Залишок: " .. data.coins)
	return true
end

-- ==============================
-- SELL FISH TO NPC
-- ==============================

local function findFishInInventory(inventory, fishName, prefix)
	for i, fish in ipairs(inventory.fish) do
		if fish.name == fishName and fish.prefix == prefix then
			return i, fish
		end
	end
	return nil, nil
end

SellFish.OnServerEvent:Connect(function(player, fishName, prefix)
	local data = DataManager.getData(player)
	if not data then return end

	-- Find fish in inventory
	local index, fish = findFishInInventory(data.inventory, fishName, prefix)
	if not index then
		warn("[EconomySystem] Риба не знайдена в інвентарі: " .. player.Name)
		return
	end

	-- Get current weather and time from FishingSystem
	-- We pass them from client for now, server will validate later
	local price = calculatePrice(fish, "clear", "day")

	-- Remove fish from inventory
	table.remove(data.inventory.fish, index)

	-- Add coins
	addCoins(player, price)

	-- Update client inventory
	UpdateInventory:FireClient(player, data.inventory)

	print("[EconomySystem] " .. player.Name .. " продав " ..
		(prefix and prefix .. " " or "") .. fishName ..
		" за " .. price .. " монет")
end)

-- ==============================
-- PUBLIC API
-- ==============================

local EconomySystem = {}

function EconomySystem.addCoins(player, amount)
	addCoins(player, amount)
end

function EconomySystem.removeCoins(player, amount)
	return removeCoins(player, amount)
end

function EconomySystem.calculatePrice(fish, weather, timeOfDay)
	return calculatePrice(fish, weather, timeOfDay)
end

print("[EconomySystem] Ініціалізовано успішно!")

return EconomySystem

