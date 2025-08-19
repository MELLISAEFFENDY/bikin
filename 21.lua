-- modern_autofish.lua (MINIMAL VERSION FOR TESTING)
-- Cleaned modern UI + Dual-mode AutoFishing (smart & secure)
-- Added new feature: Auto Mode by Spinner_xxx

-- Safe service initialization
local Players, ReplicatedStorage, RunService, UserInputService, StarterGui
pcall(function()
    Players = game:GetService("Players")
    ReplicatedStorage = game:GetService("ReplicatedStorage")
    RunService = game:GetService("RunService")
    UserInputService = game:GetService("UserInputService")
    StarterGui = game:GetService("StarterGui")
end)

-- Check if services loaded
if not Players or not ReplicatedStorage or not RunService or not UserInputService or not StarterGui then
    warn("modern_autofish: Failed to load required services. Aborting.")
    return
end

-- Must run on client
if not RunService:IsClient() then
    warn("modern_autofish: must run as a LocalScript on the client (StarterPlayerScripts). Aborting.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("modern_autofish: LocalPlayer missing. Run as LocalScript while in Play mode.")
    return
end

-- Notification function
local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
    end)
    print("[modern_autofish]", title, text)
end

print("XSAN: Modern AutoFish Minimal loaded successfully!")
Notify("AutoFish", "✅ Script loaded successfully!")

-- Minimal EventDetector for compatibility
local EventDetector = {
    detectedEvents = {},
    eventLocations = {},
    adminEventsList = {},
    isScanning = false
}

function EventDetector.ScanForAdminEvents()
    print("XSAN: EventDetector scan called (minimal)")
end

function ScanEventLocations()
    print("XSAN: ScanEventLocations called (minimal)")
end

function TeleportToEvent(eventName)
    print("XSAN: TeleportToEvent called for:", eventName)
    Notify("Test", "TeleportToEvent called for " .. eventName)
end

print("XSAN: All functions loaded!")

-- Basic UI Creation
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Main GUI
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "ModernAutoFishMinimal"
screenGui.ResetOnSpawn = false

-- Main Frame
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 600, 0, 400)
mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

-- Corner
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- Title
local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.Text = "🎣 Modern AutoFish (Minimal Test Version)"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
titleLabel.BorderSizePixel = 0

-- Title corner
Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 10)

-- Close button
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Content area
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1, -20, 1, -60)
contentFrame.Position = UDim2.new(0, 10, 0, 50)
contentFrame.BackgroundTransparency = 1

-- Status label
local statusLabel = Instance.new("TextLabel", contentFrame)
statusLabel.Size = UDim2.new(1, 0, 0, 50)
statusLabel.Position = UDim2.new(0, 0, 0, 0)
statusLabel.Text = "✅ Modern AutoFish Minimal Version Loaded!\n🎯 This is a test version to verify basic functionality."
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 14
statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
statusLabel.BackgroundTransparency = 1
statusLabel.TextWrapped = true

-- Test buttons
local testBtn1 = Instance.new("TextButton", contentFrame)
testBtn1.Size = UDim2.new(0, 150, 0, 40)
testBtn1.Position = UDim2.new(0, 0, 0, 80)
testBtn1.Text = "🔍 Test Scan"
testBtn1.Font = Enum.Font.GothamBold
testBtn1.TextSize = 12
testBtn1.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
testBtn1.TextColor3 = Color3.fromRGB(255, 255, 255)
testBtn1.BorderSizePixel = 0
Instance.new("UICorner", testBtn1)

testBtn1.MouseButton1Click:Connect(function()
    EventDetector.ScanForAdminEvents()
    Notify("Test", "Manual scan executed!")
end)

local testBtn2 = Instance.new("TextButton", contentFrame)
testBtn2.Size = UDim2.new(0, 150, 0, 40)
testBtn2.Position = UDim2.new(0, 160, 0, 80)
testBtn2.Text = "📍 Test Teleport"
testBtn2.Font = Enum.Font.GothamBold
testBtn2.TextSize = 12
testBtn2.BackgroundColor3 = Color3.fromRGB(255, 130, 70)
testBtn2.TextColor3 = Color3.fromRGB(255, 255, 255)
testBtn2.BorderSizePixel = 0
Instance.new("UICorner", testBtn2)

testBtn2.MouseButton1Click:Connect(function()
    TeleportToEvent("Test Event")
end)

print("XSAN: Minimal UI created successfully!")
Notify("UI", "🎨 Minimal UI loaded!")
