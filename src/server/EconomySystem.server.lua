-- EconomySystem
-- EconomySystem
-- Handles fish selling, price calculation, coins management

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(ServerScriptService.DataManager)
local EconomyUtils = require(ServerScriptService.EconomyUtils)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local SellFish = RemoteEvents:WaitForChild("SellFish")
local UpdateCoins = RemoteEvents:WaitForChild("UpdateCoins")
local UpdateInventory = RemoteEvents:WaitForChild("UpdateInventory")

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

	local price = EconomyUtils.calculatePrice(fish)

	-- Remove fish from inventory
	table.remove(data.inventory.fish, index)

	-- Add coins
	EconomyUtils.addCoins(player, price)
	UpdateCoins:FireClient(player, data.coins)

	-- Update client inventory
	UpdateInventory:FireClient(player, data.inventory)

	print("[EconomySystem] " .. player.Name .. " продав " ..
		(prefix and prefix .. " " or "") .. fishName ..
		" за " .. price .. " монет")
end)

print("[EconomySystem] Ініціалізовано успішно!")
