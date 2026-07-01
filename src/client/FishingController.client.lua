-- FishingController
-- FishingController
-- Manages fishing button and timing bar

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:WaitForChild("MainGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local CastRod            = RemoteEvents:WaitForChild("CastRod")
local CatchFish          = RemoteEvents:WaitForChild("CatchFish")
local UpdateRodLevel     = RemoteEvents:WaitForChild("UpdateRodLevel")
local RequestPlayerState = RemoteEvents:WaitForChild("RequestPlayerState")

-- ==============================
-- STATE
-- ==============================

local isFishing = false
local TEXT_SIZE = 22
local rodLevel = 1

local rodWaitTimes = {
	[1] = {8, 12}, [2] = {6, 9}, [3] = {5, 7},
	[4] = {3, 5},  [5] = {2, 4}, [6] = {1, 3},
}

-- B3: розмір "Ideal" зони і швидкість повзунка ростуть з рівнем вудки
local rodZoneConfig = {
	[1] = { idealSize = 0.08, sliderSpeed = 0.85 },
	[2] = { idealSize = 0.10, sliderSpeed = 1.00 },
	[3] = { idealSize = 0.13, sliderSpeed = 1.15 },
	[4] = { idealSize = 0.16, sliderSpeed = 1.30 },
	[5] = { idealSize = 0.19, sliderSpeed = 1.45 },
	[6] = { idealSize = 0.23, sliderSpeed = 1.60 },
}
local currentSliderSpeed = rodZoneConfig[1].sliderSpeed

local rarityGlow = {
	Common    = Color3.fromRGB(200, 200, 200),
	Uncommon  = Color3.fromRGB(80, 255, 80),
	Rare      = Color3.fromRGB(80, 150, 255),
	Epic      = Color3.fromRGB(200, 80, 255),
	Legendary = Color3.fromRGB(255, 215, 0),
}

local zones = {
	{ name = "Weak",    size = 0.37, color = Color3.fromRGB(220, 50,  50),  result = "weak",    label = "x0.5" },
	{ name = "Medium",  size = 0.35, color = Color3.fromRGB(220, 180, 0),   result = "medium",  label = "x1.0" },
	{ name = "Good",    size = 0.20, color = Color3.fromRGB(50,  200, 50),  result = "good",    label = "x1.5" },
	{ name = "Perfect", size = 0.08, color = Color3.fromRGB(50,  150, 255), result = "perfect", label = "x2.0" },
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
	element.TextXAlignment = Enum.TextXAlignment.Center
	element.TextYAlignment = Enum.TextYAlignment.Center
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
-- FISHING BUTTON
-- ==============================

local fishButton = newButton(
	screenGui, "🎣 Cast Rod",
	UDim2.new(0, 220, 0, 65),
	UDim2.new(0.5, -110, 1, -85),
	Color3.fromRGB(0, 130, 255), 5
)

-- ==============================
-- TIMING BAR
-- ==============================

local timingBarBG = newFrame(
	screenGui,
	UDim2.new(0, 500, 0, 100),
	UDim2.new(0.5, -250, 0.5, -50),
	Color3.fromRGB(20, 20, 20), 0.15, 10
)
timingBarBG.Visible = false
addRound(timingBarBG, 14)
addBorder(timingBarBG, Color3.fromRGB(255, 255, 255), 3)

newLabel(
	timingBarBG, "🎯 Tap to catch!",
	UDim2.new(1, 0, 0.3, 0),
	UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(255, 255, 255), 11
)

local timingBar = newFrame(
	timingBarBG,
	UDim2.new(0.95, 0, 0.55, 0),
	UDim2.new(0.025, 0, 0.4, 0),
	Color3.fromRGB(40, 40, 40), 0, 11
)
addRound(timingBar, 8)

-- Створюємо зони з текстом множника
local zoneFrames = {}
local totalOffset = 0
for _, zone in ipairs(zones) do
	local zf = newFrame(
		timingBar,
		UDim2.new(zone.size, 0, 1, 0),
		UDim2.new(totalOffset, 0, 0, 0),
		zone.color, 0, 12
	)
	zf.Name = zone.name
	zoneFrames[zone.name] = zf

	-- Множник по центру зони
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = zone.label
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lbl.TextStrokeTransparency = 0
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = false
	lbl.TextSize = TEXT_SIZE
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.ZIndex = 13
	lbl.Parent = zf

	totalOffset = totalOffset + zone.size
end

local slider = newFrame(
	timingBar,
	UDim2.new(0, 8, 1.2, 0),
	UDim2.new(0, 0, -0.1, 0),
	Color3.fromRGB(255, 255, 255), 0, 14
)
addRound(slider, 4)

-- ==============================
-- ROD LEVEL
-- ==============================

local weakZone = zones[1]
local perfectZone = zones[4]

local function applyRodLevel(level)
	rodLevel = level
	local cfg = rodZoneConfig[level] or rodZoneConfig[1]
	perfectZone.size = cfg.idealSize
	weakZone.size = 0.45 - cfg.idealSize
	currentSliderSpeed = cfg.sliderSpeed
end

UpdateRodLevel.OnClientEvent:Connect(applyRodLevel)

-- Слухач уже підписаний вище — тепер безпечно запитати актуальний rodLevel
RequestPlayerState:FireServer()

-- ==============================
-- CATCH NOTIFICATION
-- ==============================

local catchNotif = newFrame(
	screenGui,
	UDim2.new(0, 320, 0, 90),
	UDim2.new(0.5, -160, 0.35, 0),
	Color3.fromRGB(20, 20, 20), 0.15, 20
)
catchNotif.Visible = false
addRound(catchNotif, 16)
addBorder(catchNotif, Color3.fromRGB(255, 215, 0), 3)

local catchLabel = newLabel(
	catchNotif, "",
	UDim2.new(1, -10, 1, 0),
	UDim2.new(0, 5, 0, 0),
	Color3.fromRGB(255, 255, 255), 21
)

-- ==============================
-- SHUFFLE ZONES
-- ==============================

local shuffledZones = {}

local function shuffleZones()
	shuffledZones = {}
	for _, z in ipairs(zones) do
		table.insert(shuffledZones, z)
	end
	for i = #shuffledZones, 2, -1 do
		local j = math.random(i)
		shuffledZones[i], shuffledZones[j] = shuffledZones[j], shuffledZones[i]
	end

	local offset = 0
	for _, zone in ipairs(shuffledZones) do
		local zf = zoneFrames[zone.name]
		if zf then
			zf.Position = UDim2.new(offset, 0, 0, 0)
			zf.Size = UDim2.new(zone.size, 0, 1, 0)
		end
		offset = offset + zone.size
	end
end

-- ==============================
-- TIMING BAR LOGIC
-- ==============================

local function getZoneAtPosition(pos)
	local offset = 0
	for _, zone in ipairs(shuffledZones) do
		offset = offset + zone.size
		if pos <= offset then
			return zone.result
		end
	end
	return "weak"
end

local function runTimingBar(callback)
	shuffleZones()
	timingBarBG.Visible = true

	local sliderPos = 0
	local direction = 1
	local speed = currentSliderSpeed
	local active = true
	local timeLeft = 3

	local hb, cc

	local function cleanup(result)
		if not active then return end
		active = false
		hb:Disconnect()
		cc:Disconnect()
		timingBarBG.Visible = false
		callback(result)
	end

	hb = RunService.Heartbeat:Connect(function(dt)
		if not active then return end
		sliderPos = math.clamp(sliderPos + direction * speed * dt, 0, 1)
		if sliderPos >= 1 then direction = -1
		elseif sliderPos <= 0 then direction = 1 end
		slider.Position = UDim2.new(sliderPos, -4, -0.1, 0)
		timeLeft = timeLeft - dt
		if timeLeft <= 0 then cleanup(nil) end
	end)

	cc = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			cleanup(getZoneAtPosition(sliderPos))
		end
	end)
end

-- ==============================
-- FISHING CYCLE
-- ==============================

local function resetFishButton()
	fishButton.Text = "🎣 Cast Rod"
	fishButton.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
	fishButton.Active = true
	isFishing = false
end

local function showCatchNotif(fish, missed)
	if missed then
		addBorder(catchNotif, Color3.fromRGB(200, 50, 50), 3)
		catchLabel.Text = "🐟 The fish got away!"
		catchLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		local prefix = fish.prefix and fish.prefix .. " " or ""
		catchLabel.Text = "✨ " .. prefix .. fish.name .. "\n[" .. fish.rarity .. "]"
		catchLabel.TextColor3 = rarityGlow[fish.rarity] or Color3.fromRGB(255, 255, 255)
		addBorder(catchNotif, rarityGlow[fish.rarity] or Color3.fromRGB(255, 255, 255), 3)
	end
	catchNotif.Visible = true
	task.delay(2.5, function() catchNotif.Visible = false end)
end

fishButton.MouseButton1Click:Connect(function()
	if isFishing then return end
	isFishing = true

	fishButton.Text = "⏳ Waiting..."
	fishButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	fishButton.Active = false

	local waitRange = rodWaitTimes[rodLevel] or rodWaitTimes[1]
	local waitTime = math.random(waitRange[1], waitRange[2])
	task.wait(waitTime)
	if not isFishing then return end

	fishButton.Text = "🐟 Pull!"
	fishButton.BackgroundColor3 = Color3.fromRGB(220, 90, 0)
	fishButton.Active = true

	local pulled = false
	local pullConn
	pullConn = fishButton.MouseButton1Click:Connect(function()
		if not pulled then
			pulled = true
			pullConn:Disconnect()
		end
	end)

	local elapsed = 0
	while elapsed < 5 and not pulled do
		elapsed = elapsed + task.wait(0.1)
	end

	if not pulled then
		pullConn:Disconnect()
		showCatchNotif(nil, true)
		resetFishButton()
		return
	end

	fishButton.Text = "🎣 Fishing..."
	fishButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	fishButton.Active = false

	runTimingBar(function(result)
		if result == nil then
			showCatchNotif(nil, true)
		else
			CastRod:FireServer(result, false, 1)
		end
		resetFishButton()
	end)
end)

-- ==============================
-- SERVER EVENTS
-- ==============================

CatchFish.OnClientEvent:Connect(function(fish, reason)
	if reason == "full" then
		addBorder(catchNotif, Color3.fromRGB(200, 50, 50), 3)
		catchLabel.Text = "🎒 Inventory full!"
		catchLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		catchNotif.Visible = true
		task.delay(2.5, function() catchNotif.Visible = false end)
	else
		showCatchNotif(fish, false)
	end
end)

print("[FishingController] Initialized successfully!")