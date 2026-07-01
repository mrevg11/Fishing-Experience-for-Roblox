-- NotificationController
-- NotificationController
-- Manages system notifications and messages to player

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local screenGui = playerGui:WaitForChild("MainGui")

local TEXT_SIZE = 22

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

-- ==============================
-- NOTIFICATION QUEUE
-- ==============================

local notifQueue = {}
local isShowing = false
local NOTIF_DURATION = 3

local notifFrame = newFrame(
	screenGui,
	UDim2.new(0, 380, 0, 90),
	UDim2.new(0.5, -190, 0, -200),
	Color3.fromRGB(20, 20, 20), 0.1, 50
)
addRound(notifFrame, 14)
addBorder(notifFrame, Color3.fromRGB(255, 255, 255), 3)
-- Єдиний UIStroke, який далі лише перефарбовується — без цього
-- кожен виклик showNextNotif() накладав ще одну рамку поверх старої
local notifStroke = notifFrame:FindFirstChildOfClass("UIStroke")

local notifLabel = newLabel(
	notifFrame, "",
	UDim2.new(1, -20, 1, -10),
	UDim2.new(0, 10, 0, 5),
	Color3.fromRGB(255, 255, 255), 51
)
notifLabel.TextWrapped = true

local function showNextNotif()
	if #notifQueue == 0 then
		isShowing = false
		return
	end

	isShowing = true
	local notif = table.remove(notifQueue, 1)

	notifLabel.Text = notif.text
	notifLabel.TextColor3 = notif.color or Color3.fromRGB(255, 255, 255)
	notifStroke.Color = notif.borderColor or Color3.fromRGB(255, 255, 255)

	notifFrame.Position = UDim2.new(0.5, -190, 0, -200)
	local tweenIn = TweenService:Create(
		notifFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -190, 0, 15) }
	)
	tweenIn:Play()

	task.delay(NOTIF_DURATION, function()
		local tweenOut = TweenService:Create(
			notifFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Position = UDim2.new(0.5, -190, 0, -200) }
		)
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			showNextNotif()
		end)
	end)
end

-- ==============================
-- PUBLIC API
-- ==============================

local NotificationController = {}

function NotificationController.show(text, color, borderColor)
	table.insert(notifQueue, {
		text = text,
		color = color or Color3.fromRGB(255, 255, 255),
		borderColor = borderColor or Color3.fromRGB(255, 255, 255),
	})
	if not isShowing then
		showNextNotif()
	end
end

-- ==============================
-- BUILT-IN NOTIFICATIONS
-- ==============================

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local FishSpoiled = RemoteEvents:WaitForChild("FishSpoiled")
local ShowNotification = RemoteEvents:WaitForChild("ShowNotification")

task.delay(2, function()
	NotificationController.show(
		"🎣 Welcome to Fishing Experience!",
		Color3.fromRGB(100, 220, 255),
		Color3.fromRGB(0, 180, 255)
	)
end)

FishSpoiled.OnClientEvent:Connect(function(count)
	NotificationController.show(
		"🐟💀 " .. count .. " fish spoiled in your backpack!",
		Color3.fromRGB(255, 120, 120),
		Color3.fromRGB(200, 50, 50)
	)
end)

-- Дозволяє сервер-скриптам (HubBuilder тощо) показувати тости гравцю
ShowNotification.OnClientEvent:Connect(function(text, color, borderColor)
	NotificationController.show(text, color, borderColor)
end)

print("[NotificationController] Initialized successfully!")

return NotificationController