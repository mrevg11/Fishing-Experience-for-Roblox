-- EconomyUtils
-- Спільна логіка ціни риби і монет — використовується EconomySystem
-- (продаж однієї риби) і HubBuilder (NPC-магазин, продаж усього рюкзака)

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(ServerScriptService.DataManager)
local FishData = require(ServerScriptService.FishData)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateCoins = RemoteEvents:WaitForChild("UpdateCoins")

local EconomyUtils = {}

-- Ціна продажу стала за будь-якої погоди/часу доби.
-- Єдиний бонус — префікс, яким риба вже позначена в момент лову.
local prefixBonuses = {
	Rainy    = 0.10,
	Dusk     = 0.15,
	Midnight = 0.20,
	Stormy   = 0.35,
	Misty    = 0.35,
}

function EconomyUtils.calculatePrice(fish)
	local fishInfo = FishData[fish.name]
	if not fishInfo then return 0 end

	local multiplier = 1.0
	if fish.prefix and prefixBonuses[fish.prefix] then
		multiplier = multiplier + prefixBonuses[fish.prefix]
	end

	return math.floor(fishInfo.basePrice * multiplier)
end

-- Завжди оновлює баланс і одразу ж рефрешить HUD клієнта —
-- жоден виклик не може "забути" це зробити
function EconomyUtils.addCoins(player, amount)
	local data = DataManager.getData(player)
	if not data then return end

	data.coins = data.coins + amount
	UpdateCoins:FireClient(player, data.coins)
	print("[EconomyUtils] " .. player.Name .. " отримав " .. amount .. " монет. Всього: " .. data.coins)
end

function EconomyUtils.removeCoins(player, amount)
	local data = DataManager.getData(player)
	if not data then return false end

	if data.coins < amount then
		return false
	end

	data.coins = data.coins - amount
	UpdateCoins:FireClient(player, data.coins)
	print("[EconomyUtils] " .. player.Name .. " витратив " .. amount .. " монет. Залишок: " .. data.coins)
	return true
end

return EconomyUtils
