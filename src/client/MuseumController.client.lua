-- MuseumController
-- MuseumController
-- Manages museum collection window (opens from the Museum hub point)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:WaitForChild("MainGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RequestMuseum = RemoteEvents:WaitForChild("RequestMuseum")
local UpdateMuseum  = RemoteEvents:WaitForChild("UpdateMuseum")

local TEXT_SIZE = 22

-- ==============================
-- SPECIES TEMPLATE (для показу "0/6" навіть якщо ще не спіймано)
-- Дублює зону/рідкість з FishData — клієнт не має доступу до ServerScriptService
-- ==============================

local speciesTemplate = {
	-- ZONE 1 — SHALLOWS
	{ name = "Perch",              zone = 1, rarity = "Common" },
	{ name = "Pond Lurker",        zone = 1, rarity = "Common" },
	{ name = "Roach",              zone = 1, rarity = "Common" },
	{ name = "Goby",                zone = 1, rarity = "Common" },
	{ name = "Surf Crab",           zone = 1, rarity = "Common" },
	{ name = "Serpent Crawler",     zone = 1, rarity = "Uncommon" },
	{ name = "Silver Bream",        zone = 1, rarity = "Uncommon" },
	{ name = "Copper Eel",          zone = 1, rarity = "Rare" },
	{ name = "Goldfin Pike",        zone = 1, rarity = "Rare" },
	{ name = "Guardian Crab",       zone = 1, rarity = "Epic" },
	{ name = "Armored Catfish",     zone = 1, rarity = "Epic" },
	{ name = "Sun Ray",             zone = 1, rarity = "Legendary" },
	{ name = "Moon Serpent",        zone = 1, rarity = "Legendary" },
	{ name = "Misty Tench",         zone = 1, rarity = "Epic" },
	{ name = "Thunder Jaw",         zone = 1, rarity = "Legendary" },
	-- ZONE 2 — THE REEFS
	{ name = "Pearl Grouper",       zone = 2, rarity = "Common" },
	{ name = "Painted Wrasse",      zone = 2, rarity = "Common" },
	{ name = "Red Mullet",          zone = 2, rarity = "Common" },
	{ name = "Spiny Drifter",       zone = 2, rarity = "Common" },
	{ name = "Sea Urchin",          zone = 2, rarity = "Common" },
	{ name = "Tiger Moray",         zone = 2, rarity = "Uncommon" },
	{ name = "Blue Scorpionfish",   zone = 2, rarity = "Uncommon" },
	{ name = "Reef Loach",          zone = 2, rarity = "Rare" },
	{ name = "Clownfish",           zone = 2, rarity = "Rare" },
	{ name = "Flame Anemone",       zone = 2, rarity = "Epic" },
	{ name = "Coral Jellyfish",     zone = 2, rarity = "Epic" },
	{ name = "Crystal Shark",       zone = 2, rarity = "Legendary" },
	{ name = "Reef Phantom",        zone = 2, rarity = "Legendary" },
	{ name = "Milky Chimera",       zone = 2, rarity = "Legendary" },
	{ name = "Lightning Barracuda", zone = 2, rarity = "Legendary" },
}

local rarityCaps = {
	Common    = 6,
	Uncommon  = 5,
	Rare      = 4,
	Epic      = 3,
	Legendary = 2,
}

-- speciesTemplate іде в порядку документа (де кілька спецвидів за
-- умовою вставлені не по рідкості) — сортуємо для показу, щоб однакова
-- рідкість завжди йшла разом
local rarityRank = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
local sortedSpecies = {}
for _, species in ipairs(speciesTemplate) do
	table.insert(sortedSpecies, species)
end
table.sort(sortedSpecies, function(a, b)
	if a.zone ~= b.zone then return a.zone < b.zone end
	return rarityRank[a.rarity] < rarityRank[b.rarity]
end)

local rarityColors = {
	Common    = Color3.fromRGB(100, 100, 100),
	Uncommon  = Color3.fromRGB(30, 140, 30),
	Rare      = Color3.fromRGB(30, 80, 200),
	Epic      = Color3.fromRGB(130, 30, 200),
	Legendary = Color3.fromRGB(200, 130, 0),
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
-- WINDOW
-- ==============================

local museumWindow = newFrame(
	screenGui,
	UDim2.new(0, 650, 0, 550),
	UDim2.new(0.5, -325, 0.5, -275),
	Color3.fromRGB(25, 25, 35), 0.05, 30
)
museumWindow.Visible = false
addRound(museumWindow, 16)
addBorder(museumWindow, Color3.fromRGB(255, 255, 255), 3)

local header = newFrame(
	museumWindow,
	UDim2.new(1, 0, 0, 58),
	UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(60, 110, 220), 0, 31
)
addRound(header, 16)

newLabel(header, "🏛️ Museum",
	UDim2.new(1, 0, 1, 0),
	UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(255, 255, 255), 32
)

local closeBtn = newButton(
	museumWindow, "X",
	UDim2.new(0, 42, 0, 42),
	UDim2.new(1, -50, 0, 8),
	Color3.fromRGB(220, 40, 40), 33
)

local totalIncomeLabel = newLabel(
	museumWindow, "💰 Passive income: 0.0 coins/min",
	UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 63),
	Color3.fromRGB(255, 215, 0), 32
)

local list = Instance.new("ScrollingFrame")
list.Name = "SpeciesList"
list.Size = UDim2.new(1, -20, 1, -100)
list.Position = UDim2.new(0, 10, 0, 92)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.ZIndex = 31
list.Parent = museumWindow

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = list

-- ==============================
-- RENDERING
-- ==============================

local currentMuseum = { fish = {}, incomeBySpecies = {}, totalIncomePerMinute = 0 }

-- Які види зараз розгорнуті (показують конкретні екземпляри)
local expandedSpecies = {}

local function clearList()
	for _, child in ipairs(list:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function renderMuseum()
	clearList()

	local specimensByName = {}
	for _, specimen in ipairs(currentMuseum.fish or {}) do
		specimensByName[specimen.name] = specimensByName[specimen.name] or {}
		table.insert(specimensByName[specimen.name], specimen)
	end
	local incomeBySpecies = currentMuseum.incomeBySpecies or {}

	totalIncomeLabel.Text = string.format(
		"💰 Passive income: %.1f coins/min", currentMuseum.totalIncomePerMinute or 0
	)

	local order = 0
	for zone = 1, 2 do
		order = order + 1
		local zoneHeader = newLabel(
			list, zone == 1 and "Zone 1 — Shallows" or "Zone 2 — The Reefs",
			UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0),
			Color3.fromRGB(200, 220, 255), 32
		)
		zoneHeader.LayoutOrder = order
		zoneHeader.BackgroundTransparency = 1

		for _, species in ipairs(sortedSpecies) do
			if species.zone == zone then
				order = order + 1
				local specimens = specimensByName[species.name] or {}
				local count = #specimens
				local cap = rarityCaps[species.rarity] or 1
				local income = incomeBySpecies[species.name] or 0
				local isExpanded = expandedSpecies[species.name]

				local row = newFrame(
					list, UDim2.new(1, 0, 0, 34), UDim2.new(0, 0, 0, 0),
					rarityColors[species.rarity] or Color3.fromRGB(60, 60, 60), 0.3, 32
				)
				row.LayoutOrder = order
				addRound(row, 8)

				local arrowBtn = newButton(
					row, count > 0 and (isExpanded and "▼" or "▶") or "•",
					UDim2.new(0, 24, 0, 24), UDim2.new(0, 5, 0, 5),
					Color3.fromRGB(40, 40, 40), 33
				)
				arrowBtn.Active = count > 0
				if count > 0 then
					arrowBtn.MouseButton1Click:Connect(function()
						expandedSpecies[species.name] = not expandedSpecies[species.name]
						renderMuseum()
					end)
				end

				newLabel(row, species.name,
					UDim2.new(0.5, -34, 1, 0), UDim2.new(0, 34, 0, 0),
					Color3.fromRGB(255, 255, 255), 33)

				newLabel(row, count .. " / " .. cap,
					UDim2.new(0.2, 0, 1, 0), UDim2.new(0.5, 0, 0, 0),
					count >= cap and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(220, 220, 220), 33)

				newLabel(row, count > 0 and string.format("+%.1f/min", income) or "—",
					UDim2.new(0.3, -10, 1, 0), UDim2.new(0.7, 0, 0, 0),
					Color3.fromRGB(150, 255, 150), 33)

				if isExpanded then
					for _, specimen in ipairs(specimens) do
						order = order + 1
						local subRow = newFrame(
							list, UDim2.new(1, -30, 0, 26), UDim2.new(0, 30, 0, 0),
							Color3.fromRGB(20, 20, 20), 0.2, 32
						)
						subRow.LayoutOrder = order
						addRound(subRow, 6)

						newLabel(subRow, specimen.prefix and ("✨ " .. specimen.prefix) or "No prefix",
							UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 10, 0, 0),
							specimen.prefix and Color3.fromRGB(255, 230, 50) or Color3.fromRGB(160, 160, 160), 33)

						newLabel(subRow, string.format("+%.1f/min", specimen.incomeRate or 0),
							UDim2.new(0.4, -10, 1, 0), UDim2.new(0.6, 0, 0, 0),
							Color3.fromRGB(150, 255, 150), 33)
					end
				end
			end
		end
	end
end

-- ==============================
-- OPEN / CLOSE
-- ==============================

local function openMuseum()
	museumWindow.Visible = true
	RequestMuseum:FireServer()
end

closeBtn.MouseButton1Click:Connect(function()
	museumWindow.Visible = false
end)

UpdateMuseum.OnClientEvent:Connect(function(museum)
	currentMuseum = museum
	if museumWindow.Visible then
		renderMuseum()
	end
end)

-- Слухаємо той самий ProximityPrompt, що створив HubBuilder на сервері —
-- тепер на ОСОБИСТОМУ острові гравця (Hub.Player_<UserId>), а не на
-- єдиному спільному хабі
task.spawn(function()
	local hub = Workspace:WaitForChild("Hub")
	local islandFolder = hub:WaitForChild("Player_" .. player.UserId)
	local museumPart = islandFolder:WaitForChild("Museum")
	local prompt = museumPart:WaitForChild("ProximityPrompt")

	prompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer == player then
			openMuseum()
		end
	end)
end)

print("[MuseumController] Initialized successfully!")
