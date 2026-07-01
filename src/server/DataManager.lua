-- DataManager
-- DataManager
-- Відповідає за збереження і завантаження даних гравця

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerData = DataStoreService:GetDataStore("FishingGameV1")

-- Дефолтні дані для нового гравця
local function getDefaultData()
	return {
		coins = 1000,
		rodLevel = 1,
		backpackLevel = 1,
		vaultLevel = 1,
		warehouseLevel = 1,
		tutorialDone = false,
		lastOnline = os.time(),
		licenses = {
			zone1 = true,
			zone2 = false,
		},
		position = {x = 0, y = 5, z = 0},
		inventory = {
			fish = {},
			resources = {}
		},
		museum = { fish = {} },
		vault = {},
		warehouse = {}
	}
end

-- Зберігаємо дані всіх активних гравців в пам'яті сервера
local activePlayers = {}

-- Завантаження даних при вході
local function loadData(player)
	local key = "player_" .. player.UserId
	local success, data = pcall(function()
		return PlayerData:GetAsync(key)
	end)

	if success then
		if data then
			print("[DataManager] Дані завантажено для: " .. player.Name)
			return data
		else
			print("[DataManager] Новий гравець: " .. player.Name)
			return getDefaultData()
		end
	else
		warn("[DataManager] Помилка завантаження для: " .. player.Name)
		return getDefaultData()
	end
end

-- Збереження даних
local function saveData(player)
	local data = activePlayers[player.UserId]
	if not data then return end

	data.lastOnline = os.time()

	local key = "player_" .. player.UserId
	local success, err = pcall(function()
		PlayerData:SetAsync(key, data)
	end)

	if success then
		print("[DataManager] Дані збережено для: " .. player.Name)
	else
		warn("[DataManager] Помилка збереження для: " .. player.Name .. " | " .. err)
	end
end

-- Гравець зайшов
Players.PlayerAdded:Connect(function(player)
	local data = loadData(player)
	activePlayers[player.UserId] = data
end)

-- Гравець вийшов
Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	activePlayers[player.UserId] = nil
end)

-- Зберегти всі дані при закритті сервера
game:BindToClose(function()
	for userId, _ in pairs(activePlayers) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			saveData(player)
		end
	end
end)

-- Публічна функція для отримання даних гравця
-- Інші скрипти будуть використовувати цю функцію
local DataManager = {}

function DataManager.getData(player)
	return activePlayers[player.UserId]
end

function DataManager.saveData(player)
	saveData(player)
end

return DataManager