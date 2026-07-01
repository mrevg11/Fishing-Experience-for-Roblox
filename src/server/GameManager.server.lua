-- GameManager
-- GameManager
-- Головний скрипт який зв'язує всі системи разом

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Підключаємо DataManager
local DataManager = require(ServerScriptService.DataManager)

-- Створюємо RemoteEvents які потрібні клієнту
local RemoteEvents = ReplicatedStorage.RemoteEvents

local function createRemoteEvent(name)
	local existing = RemoteEvents:FindFirstChild(name)
	if existing then return existing end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = RemoteEvents
	return event
end

-- Список всіх RemoteEvents
local Events = {
	-- Рибалка
	CastRod        = createRemoteEvent("CastRod"),
	CatchFish      = createRemoteEvent("CatchFish"),
	-- Інвентар
	SellFish       = createRemoteEvent("SellFish"),
	OpenInventory  = createRemoteEvent("OpenInventory"),
	-- Музей
	AddToMuseum    = createRemoteEvent("AddToMuseum"),
	-- Аукціон
	ListAuction    = createRemoteEvent("ListAuction"),
	-- UI оновлення
	UpdateCoins    = createRemoteEvent("UpdateCoins"),
	UpdateInventory = createRemoteEvent("UpdateInventory"),
	UpdateRodLevel = createRemoteEvent("UpdateRodLevel"),
	UpdateWeather  = createRemoteEvent("UpdateWeather"),
	FishSpoiled    = createRemoteEvent("FishSpoiled"),
	ShowNotification = createRemoteEvent("ShowNotification"),
}

-- Чекаємо, поки DataManager завантажить дані гравця (DataStore-запит асинхронний)
local function waitForData(player)
	local data = DataManager.getData(player)
	local attempts = 0
	while not data and attempts < 20 do
		task.wait(0.25)
		data = DataManager.getData(player)
		attempts = attempts + 1
	end
	return data
end

-- Запит інвентаря при відкритті рюкзака
local RequestInventory = createRemoteEvent("RequestInventory")

RequestInventory.OnServerEvent:Connect(function(player)
	local data = DataManager.getData(player)
	if not data then return end
	RemoteEvents.UpdateInventory:FireClient(player, data.inventory)
	RemoteEvents.UpdateCoins:FireClient(player, data.coins)
end)

-- Клієнт сам запитує свій стан при завантаженні (замість гри в вгадування таймінгу)
local RequestPlayerState = createRemoteEvent("RequestPlayerState")

RequestPlayerState.OnServerEvent:Connect(function(player)
	local data = waitForData(player)
	if not data then
		warn("[GameManager] Дані не знайдено для: " .. player.Name)
		return
	end
	Events.UpdateCoins:FireClient(player, data.coins)
	Events.UpdateRodLevel:FireClient(player, data.rodLevel)
end)

-- Гравець зайшов
Players.PlayerAdded:Connect(function(player)
	print("[GameManager] Гравець зайшов: " .. player.Name)
end)

-- Гравець вийшов
Players.PlayerRemoving:Connect(function(player)
	print("[GameManager] Гравець вийшов: " .. player.Name)
	DataManager.saveData(player)
end)

print("[GameManager] Ініціалізовано успішно!")