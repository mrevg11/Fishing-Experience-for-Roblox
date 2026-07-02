-- HubBuilder
-- HubBuilder
-- Процедурно створює особистий острів кожного гравця (A1): NPC, магазин,
-- музей, льох, склад, дошки аукціону/квестів. Кожен з 8 гравців отримує
-- окрему копію на власному слоті в ряду островів (WorldBuilder будує
-- спільний місток/причал/океан за ними). Тимчасові частини — заміняться
-- на фінальний 3D-арт друга пізніше.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataManager = require(ServerScriptService.DataManager)
local EconomyUtils = require(ServerScriptService.EconomyUtils)
local WorldConfig = require(ServerScriptService.WorldConfig)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateInventory = RemoteEvents:WaitForChild("UpdateInventory")
local ShowNotification = RemoteEvents:WaitForChild("ShowNotification")

local hubFolder = Instance.new("Folder")
hubFolder.Name = "Hub"
hubFolder.Parent = Workspace

-- Слот (1..MAX_SLOTS) <-> гравець, зайнятий слот = острів гравця в ряду
local playerBySlot = {}
local slotByPlayer = {}

-- ==============================
-- HELPERS
-- ==============================

local function notify(player, text, color, borderColor)
	ShowNotification:FireClient(player, text, color, borderColor)
end

local function createHubPoint(parentFolder, name, origin, offset, color, actionText)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(8, 1, 8)
	part.Position = origin + offset
	part.Anchored = true
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parentFolder

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 160, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 50
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = billboard

	local prompt
	if actionText then
		prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = name
		prompt.ActionText = actionText
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
	end

	return part, prompt
end

local function buildIslandPlatform(parentFolder, origin)
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(WorldConfig.ISLAND_WIDTH, 1, WorldConfig.ISLAND_DEPTH)
	platform.Position = origin + Vector3.new(WorldConfig.CENTER_X, -1, 0)
	platform.Anchored = true
	platform.Color = Color3.fromRGB(210, 180, 120)
	platform.Material = Enum.Material.Sand
	platform.Parent = parentFolder
end

local function sellAllFish(player)
	local data = DataManager.getData(player)
	if not data then return end

	if #data.inventory.fish == 0 then
		notify(player, "🎣 No fish to sell!", Color3.fromRGB(255, 200, 100), Color3.fromRGB(200, 150, 50))
		return
	end

	local total = 0
	for _, fish in ipairs(data.inventory.fish) do
		total = total + EconomyUtils.calculatePrice(fish)
	end

	data.inventory.fish = {}
	EconomyUtils.addCoins(player, total)

	UpdateInventory:FireClient(player, data.inventory)
	notify(player, "💰 Sold all fish for " .. total .. " coins!",
		Color3.fromRGB(255, 215, 0), Color3.fromRGB(200, 150, 0))
end

-- ==============================
-- ОСТРІВ ГРАВЦЯ
-- ==============================

local function findFreeSlot()
	for slot = 1, WorldConfig.MAX_SLOTS do
		if not playerBySlot[slot] then
			return slot
		end
	end
	return nil
end

local function spawnPointFor(origin)
	return origin + Vector3.new(WorldConfig.CENTER_X, 4, -70)
end

local function buildIslandFor(player, slot)
	local origin = WorldConfig.islandOrigin(slot)

	local islandFolder = Instance.new("Folder")
	islandFolder.Name = "Player_" .. player.UserId
	islandFolder.Parent = hubFolder

	buildIslandPlatform(islandFolder, origin)

	local _, tutorialPrompt = createHubPoint(
		islandFolder, "Tutorial NPC", origin, Vector3.new(-280, 0, 0),
		Color3.fromRGB(150, 150, 150), "Talk"
	)
	tutorialPrompt.Triggered:Connect(function(triggeringPlayer)
		notify(triggeringPlayer,
			"🎣 Welcome! Cast your rod to catch fish, sell them at the shop, and upgrade your gear.",
			Color3.fromRGB(100, 220, 255), Color3.fromRGB(0, 180, 255))
	end)

	local _, shopPrompt = createHubPoint(
		islandFolder, "Shop", origin, Vector3.new(-200, 0, 0),
		Color3.fromRGB(60, 180, 60), "Sell All Fish"
	)
	shopPrompt.Triggered:Connect(sellAllFish)

	-- Музей — сама точка тут, UI-логіку відкриття веде MuseumController
	-- (клієнт сам слухає ProximityPrompt.Triggered на своєму власному острові)
	createHubPoint(islandFolder, "Museum", origin, Vector3.new(-120, 0, 0), Color3.fromRGB(60, 110, 220), "Open Museum")

	local comingSoonPoints = {
		{ name = "Ice Vault",     offset = Vector3.new(-40, 0, 0), color = Color3.fromRGB(120, 200, 220) },
		{ name = "Warehouse",     offset = Vector3.new(40, 0, 0),  color = Color3.fromRGB(150, 110, 70) },
		{ name = "Auction Board", offset = Vector3.new(120, 0, 0), color = Color3.fromRGB(150, 60, 200) },
		{ name = "Quest Board",   offset = Vector3.new(200, 0, 0), color = Color3.fromRGB(220, 140, 40) },
	}
	for _, point in ipairs(comingSoonPoints) do
		local _, prompt = createHubPoint(islandFolder, point.name, origin, point.offset, point.color, "Interact")
		prompt.Triggered:Connect(function(triggeringPlayer)
			notify(triggeringPlayer, "🚧 " .. point.name .. " is coming soon!",
				Color3.fromRGB(220, 220, 220), Color3.fromRGB(150, 150, 150))
		end)
	end

	return islandFolder, origin
end

local function teleportToIsland(player, origin)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = CFrame.new(spawnPointFor(origin))
end

Players.PlayerAdded:Connect(function(player)
	local slot = findFreeSlot()
	if not slot then
		notify(player, "⚠️ The hub is full right now, try rejoining shortly.",
			Color3.fromRGB(255, 100, 100), Color3.fromRGB(200, 50, 50))
		return
	end

	playerBySlot[slot] = player
	slotByPlayer[player] = slot

	local _, origin = buildIslandFor(player, slot)

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		teleportToIsland(player, origin)
	end)

	if player.Character then
		teleportToIsland(player, origin)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local slot = slotByPlayer[player]
	if not slot then return end

	local islandFolder = hubFolder:FindFirstChild("Player_" .. player.UserId)
	if islandFolder then
		islandFolder:Destroy()
	end

	playerBySlot[slot] = nil
	slotByPlayer[player] = nil
end)

print("[HubBuilder] Готовий видавати особисті острови гравцям!")
