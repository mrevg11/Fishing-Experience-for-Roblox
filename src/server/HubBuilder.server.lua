-- HubBuilder
-- HubBuilder
-- Процедурно створює плейсхолдер-структури хабу (A1): NPC, музей,
-- льох, склад, дошки аукціону/квестів, причал. Це тимчасові частини —
-- заміняться на фінальний 3D-арт друга пізніше.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DataManager = require(ServerScriptService.DataManager)
local EconomyUtils = require(ServerScriptService.EconomyUtils)

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateInventory = RemoteEvents:WaitForChild("UpdateInventory")
local ShowNotification = RemoteEvents:WaitForChild("ShowNotification")

-- Точка відліку для розстановки хабу (тимчасово — поки немає готового хабу в Studio)
local HUB_ORIGIN = Vector3.new(0, 1, 60)

local hubFolder = Instance.new("Folder")
hubFolder.Name = "Hub"
hubFolder.Parent = Workspace

-- ==============================
-- HELPERS
-- ==============================

local function createHubPoint(name, offset, color, actionText)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(8, 1, 8)
	part.Position = HUB_ORIGIN + offset
	part.Anchored = true
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = hubFolder

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

local function notify(player, text, color, borderColor)
	ShowNotification:FireClient(player, text, color, borderColor)
end

-- ==============================
-- NPC ТЬЮТОРІАЛ
-- ==============================

local _, tutorialPrompt = createHubPoint(
	"Tutorial NPC", Vector3.new(-280, 0, 0),
	Color3.fromRGB(150, 150, 150), "Talk"
)

tutorialPrompt.Triggered:Connect(function(player)
	notify(player,
		"🎣 Welcome! Cast your rod to catch fish, sell them at the shop, and upgrade your gear.",
		Color3.fromRGB(100, 220, 255), Color3.fromRGB(0, 180, 255))
end)

-- ==============================
-- NPC МАГАЗИН — робочий продаж усієї риби
-- ==============================

local _, shopPrompt = createHubPoint(
	"Shop", Vector3.new(-200, 0, 0),
	Color3.fromRGB(60, 180, 60), "Sell All Fish"
)

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

shopPrompt.Triggered:Connect(sellAllFish)

-- ==============================
-- МУЗЕЙ — сама точка тут, UI-логіку відкриття веде MuseumController
-- (клієнт сам слухає ProximityPrompt.Triggered на цій точці)
-- ==============================

createHubPoint("Museum", Vector3.new(-120, 0, 0), Color3.fromRGB(60, 110, 220), "Open Museum")

-- ==============================
-- НЕГОТОВІ СИСТЕМИ — плейсхолдери з "Coming soon"
-- ==============================

local comingSoonPoints = {
	{ name = "Ice Vault",     offset = Vector3.new(-40, 0, 0),  color = Color3.fromRGB(120, 200, 220) },
	{ name = "Warehouse",     offset = Vector3.new(40, 0, 0),   color = Color3.fromRGB(150, 110, 70) },
	{ name = "Auction Board", offset = Vector3.new(120, 0, 0),  color = Color3.fromRGB(150, 60, 200) },
	{ name = "Quest Board",   offset = Vector3.new(200, 0, 0),  color = Color3.fromRGB(220, 140, 40) },
}

for _, point in ipairs(comingSoonPoints) do
	local _, prompt = createHubPoint(point.name, point.offset, point.color, "Interact")
	prompt.Triggered:Connect(function(player)
		notify(player, "🚧 " .. point.name .. " is coming soon!",
			Color3.fromRGB(220, 220, 220), Color3.fromRGB(150, 150, 150))
	end)
end

-- ==============================
-- ПРИЧАЛ — просто орієнтир, вихід в океан ще не реалізований
-- ==============================

createHubPoint("Pier", Vector3.new(280, 0, 0), Color3.fromRGB(160, 120, 80), nil)

print("[HubBuilder] Хаб згенеровано успішно!")
