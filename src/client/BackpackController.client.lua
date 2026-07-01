-- BackpackController
-- BackpackController
-- Manages backpack UI and inventory display

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:WaitForChild("MainGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateInventory  = RemoteEvents:WaitForChild("UpdateInventory")
local RequestInventory = RemoteEvents:WaitForChild("RequestInventory")

-- ==============================
-- STATE
-- ==============================

local currentInventory = { fish = {}, resources = {} }
local currentTab = "All"

local TEXT_SIZE = 22

-- ==============================
-- COLORS
-- ==============================

local rarityColors = {
	Common    = Color3.fromRGB(100, 100, 100),
	Uncommon  = Color3.fromRGB(30, 140, 30),
	Rare      = Color3.fromRGB(30, 80, 200),
	Epic      = Color3.fromRGB(130, 30, 200),
	Legendary = Color3.fromRGB(200, 130, 0),
}

local rarityGlow = {
	Common    = Color3.fromRGB(200, 200, 200),
	Uncommon  = Color3.fromRGB(80, 255, 80),
	Rare      = Color3.fromRGB(80, 150, 255),
	Epic      = Color3.fromRGB(200, 80, 255),
	Legendary = Color3.fromRGB(255, 215, 0),
}

local tabColors = {
	All      = Color3.fromRGB(70, 70, 70),
	Fish     = Color3.fromRGB(30, 110, 220),
	Items    = Color3.fromRGB(30, 150, 30),
	Trinkets = Color3.fromRGB(150, 30, 220),
	Pets     = Color3.fromRGB(220, 110, 0),
}

-- ==============================
-- HELPERS
-- ==============================

local function addRound(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = instance
end

local function addBorder(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(255, 255, 255)
	stroke.Thickness = thickness or 3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
end

local function applyTextStyle(element, color)
	element.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	element.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	element.TextStrokeTransparency = 0
	element.Font = Enum.Font.GothamBold
	element.TextScaled = false
	element.TextSize = TEXT_SIZE
end

local function newFrame(parent, size, pos, color, alpha, zindex)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color or Color3.fromRGB(30, 30, 30)
	f.BackgroundTransparency = alpha or 0
	f.BorderSizePixel = 0
	f.ZIndex = zindex or 1
	f.Parent = parent
	return f
end

local function newLabel(parent, text, size, pos, color, zindex)
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = pos
	l.BackgroundTransparency = 1
	l.Text = text
	l.ZIndex = zindex or 1
	l.Parent = parent
	applyTextStyle(l, color)
	return l
end

local function newButton(parent, text, size, pos, bgColor, zindex)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = bgColor or Color3.fromRGB(50, 180, 50)
	b.BorderSizePixel = 0
	b.Text = text
	b.ZIndex = zindex or 1
	b.Parent = parent
	applyTextStyle(b)
	addRound(b, 10)
	addBorder(b, Color3.fromRGB(255, 255, 255), 2)
	return b
end

-- ==============================
-- BACKPACK BUTTON
-- ==============================

local backpackBtn = newButton(
	screenGui, "🎒 Backpack",
	UDim2.new(0, 220, 0, 55),
	UDim2.new(0, 15, 0, 80),
	Color3.fromRGB(30, 110, 220), 5
)

-- ==============================
-- BACKPACK WINDOW
-- ==============================

local backpackWindow = newFrame(
	screenGui,
	UDim2.new(0, 650, 0, 550),
	UDim2.new(0.5, -325, 0.5, -275),
	Color3.fromRGB(25, 25, 35), 0.05, 30
)
backpackWindow.Visible = false
addRound(backpackWindow, 16)
addBorder(backpackWindow, Color3.fromRGB(255, 255, 255), 3)

-- Header
local bpHeader = newFrame(
	backpackWindow,
	UDim2.new(1, 0, 0, 58),
	UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(30, 110, 220), 0, 31
)
addRound(bpHeader, 16)

newLabel(bpHeader, "🎒 Backpack",
	UDim2.new(1, 0, 1, 0),
	UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(255, 255, 255), 32
)

local bpClose = newButton(
	backpackWindow, "X",
	UDim2.new(0, 42, 0, 42),
	UDim2.new(1, -50, 0, 8),
	Color3.fromRGB(220, 40, 40), 33
)

-- Tabs
local tabNames = {"All", "Fish", "Items", "Trinkets", "Pets"}
local tabButtons = {}

local tabFrame = newFrame(
	backpackWindow,
	UDim2.new(1, -20, 0, 42),
	UDim2.new(0, 10, 0, 63),
	Color3.fromRGB(0, 0, 0), 1, 31
)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 15)
tabLayout.Parent = tabFrame

for i, tabName in ipairs(tabNames) do
	local tabBtn = newButton(
		tabFrame, tabName,
		UDim2.new(0, 110, 1, 0),
		UDim2.new(0, 0, 0, 0),
		tabColors[tabName], 32
	)
	tabBtn.LayoutOrder = i
	tabButtons[tabName] = tabBtn
end

-- Item grid
local itemGrid = Instance.new("ScrollingFrame")
itemGrid.Name = "ItemGrid"
itemGrid.Size = UDim2.new(1, -20, 1, -115)
itemGrid.Position = UDim2.new(0, 10, 0, 110)
itemGrid.BackgroundTransparency = 1
itemGrid.BorderSizePixel = 0
itemGrid.ScrollBarThickness = 6
itemGrid.ZIndex = 31
itemGrid.Parent = backpackWindow

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 130, 0, 130)
gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = itemGrid

-- ==============================
-- INVENTORY RENDERING
-- ==============================

local function clearGrid()
	for _, child in ipairs(itemGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
end

local function renderInventory(tab)
	clearGrid()
	currentTab = tab

	for name, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = name == tab
			and tabColors[name]
			or Color3.fromRGB(50, 50, 50)
	end

	local items = {}

	if tab == "All" or tab == "Fish" then
		for _, fish in ipairs(currentInventory.fish) do
			table.insert(items, { type = "fish", data = fish })
		end
	end

	if tab == "All" or tab == "Items" then
		for _, res in ipairs(currentInventory.resources or {}) do
			table.insert(items, { type = "resource", data = res })
		end
	end

	if #items == 0 then
		newLabel(
			itemGrid,
			"Nothing here yet! 🎣",
			UDim2.new(1, 0, 0, 50),
			UDim2.new(0, 0, 0, 10),
			Color3.fromRGB(180, 180, 180), 32
		)
		return
	end

	for i, item in ipairs(items) do
		local slot = newFrame(
			itemGrid,
			UDim2.new(0, 130, 0, 130),
			UDim2.new(0, 0, 0, 0),
			item.type == "fish"
				and (rarityColors[item.data.rarity] or Color3.fromRGB(80, 80, 80))
				or Color3.fromRGB(60, 100, 50),
			0, 32
		)
		slot.Name = "Slot" .. i
		addRound(slot, 12)
		addBorder(slot,
			item.type == "fish"
				and (rarityGlow[item.data.rarity] or Color3.white)
				or Color3.fromRGB(120, 220, 80), 2)

		newLabel(slot, item.data.name,
			UDim2.new(1, -4, 0.4, 0),
			UDim2.new(0, 2, 0, 5),
			Color3.fromRGB(255, 255, 255), 33)

		if item.type == "fish" and item.data.prefix then
			newLabel(slot, "✨ " .. item.data.prefix,
				UDim2.new(1, 0, 0.2, 0),
				UDim2.new(0, 0, 0.42, 0),
				Color3.fromRGB(255, 230, 50), 33)
		end

		if item.type == "fish" then
			if item.data.spoilTimer == math.huge then
				newLabel(slot, "∞",
					UDim2.new(1, 0, 0.22, 0),
					UDim2.new(0, 0, 0.72, 0),
					Color3.fromRGB(255, 215, 0), 33)
			else
				-- Реальний залишок часу до псування, а не повна тривалість
				local remaining = math.max(0, item.data.spoilTimer - (os.time() - item.data.caughtAt))
				local mins = math.floor(remaining / 60)
				newLabel(slot, "⏱ " .. mins .. "m",
					UDim2.new(1, 0, 0.22, 0),
					UDim2.new(0, 0, 0.72, 0),
					Color3.fromRGB(255, 120, 120), 33)
			end
		end
	end
end

-- Tab clicks
for tabName, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		renderInventory(tabName)
	end)
end

-- Toggle backpack
backpackBtn.MouseButton1Click:Connect(function()
	backpackWindow.Visible = not backpackWindow.Visible
	if backpackWindow.Visible then
		RequestInventory:FireServer()
	end
end)

bpClose.MouseButton1Click:Connect(function()
	backpackWindow.Visible = false
end)

-- Server events
UpdateInventory.OnClientEvent:Connect(function(inventory)
	currentInventory = inventory
	if backpackWindow.Visible then
		renderInventory(currentTab)
	end
end)

print("[BackpackController] Initialized successfully!")