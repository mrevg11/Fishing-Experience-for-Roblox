-- HudController
-- HudController
-- Manages HUD elements: coins, weather, time of day

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:WaitForChild("MainGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateCoins = RemoteEvents:WaitForChild("UpdateCoins")

-- ==============================
-- HELPERS
-- ==============================

local TEXT_SIZE = 22

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

-- ==============================
-- COINS
-- ==============================

local coinsFrame = newFrame(
	screenGui,
	UDim2.new(0, 220, 0, 55),
	UDim2.new(0, 15, 0, 15),
	Color3.fromRGB(20, 20, 20), 0.3, 5
)
addRound(coinsFrame, 14)
addBorder(coinsFrame, Color3.fromRGB(255, 215, 0), 3)

local coinsLabel = newLabel(
	coinsFrame, "🪙 0",
	UDim2.new(1, 0, 1, 0),
	UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(255, 215, 0), 6
)

-- ==============================
-- WEATHER & TIME
-- ==============================

local weatherFrame = newFrame(
	screenGui,
	UDim2.new(0, 280, 0, 55),
	UDim2.new(0.5, -140, 0, -45),
	Color3.fromRGB(20, 20, 20), 0.3, 5
)
addRound(weatherFrame, 14)
addBorder(weatherFrame, Color3.fromRGB(100, 200, 255), 3)

local weatherLabel = newLabel(
	weatherFrame, "🌅 Morning | ☀️ Clear",
	UDim2.new(1, 0, 1, 0),
	UDim2.new(0, 0, 0, 0),
	Color3.fromRGB(200, 240, 255), 6
)

-- ==============================
-- SERVER EVENTS
-- ==============================

UpdateCoins.OnClientEvent:Connect(function(coins)
	coinsLabel.Text = "$ " .. tostring(coins)
end)

print("[HudController] Initialized successfully!")