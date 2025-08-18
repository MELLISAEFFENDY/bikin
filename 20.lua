-- AUTO AFK TEST - Simple Version
-- Test script untuk memastikan Auto AFK system berfungsi

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

print("🚀 Auto AFK Test - Loading...")

-- Simple notification function
local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = 5;
    })
end

-- Test Auto AFK System (Simplified)
local AutoAFKTest = {
    enabled = false,
    
    start = function()
        AutoAFKTest.enabled = true
        Notify("Auto AFK Test", "✅ Enhancement started!")
        print("🚀 Auto AFK Test: Started")
    end,
    
    stop = function()
        AutoAFKTest.enabled = false
        Notify("Auto AFK Test", "🛑 Enhancement stopped!")
        print("🛑 Auto AFK Test: Stopped")
    end
}

-- Simple UI
local screenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
screenGui.Name = "AutoAFKTest"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🚀 Auto AFK Test"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1, -20, 0, 40)
startBtn.Position = UDim2.new(0, 10, 0, 60)
startBtn.Text = "🚀 Start Auto AFK Test"
startBtn.Font = Enum.Font.GothamSemibold
startBtn.TextSize = 14
startBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)

local stopBtn = Instance.new("TextButton", frame)
stopBtn.Size = UDim2.new(1, -20, 0, 40)
stopBtn.Position = UDim2.new(0, 10, 0, 110)
stopBtn.Text = "🛑 Stop Auto AFK Test"
stopBtn.Font = Enum.Font.GothamSemibold
stopBtn.TextSize = 14
stopBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 30)
status.Position = UDim2.new(0, 10, 0, 160)
status.Text = "📊 Status: Ready"
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.BackgroundTransparency = 1

-- Event handlers
startBtn.MouseButton1Click:Connect(function()
    AutoAFKTest.start()
    status.Text = "📊 Status: Auto AFK Test Active"
end)

stopBtn.MouseButton1Click:Connect(function()
    AutoAFKTest.stop()
    status.Text = "📊 Status: Auto AFK Test Stopped"
end)

-- Global API
_G.AutoAFKTest = AutoAFKTest

print("✅ Auto AFK Test loaded successfully!")
print("📋 Commands: _G.AutoAFKTest.start(), _G.AutoAFKTest.stop()")
Notify("Auto AFK Test", "✅ Test script loaded successfully!")
