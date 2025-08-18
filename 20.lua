-- main18_minimal.lua - Minimal Auto AFK Version
-- Simplified version untuk testing Auto AFK feature

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("LocalPlayer missing. Run as LocalScript.")
    return
end

print("🚀 Loading Minimal Auto AFK...")

-- Simple notification
local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title;
            Text = text;
            Duration = 5;
        })
    end)
end

-- Auto AFK System (Minimal)
local AutoAFK = {
    enabled = false,
    monitoring = false,
    
    start = function()
        AutoAFK.enabled = true
        if not AutoAFK.monitoring then
            AutoAFK.monitoring = true
            task.spawn(AutoAFK.monitor)
        end
        Notify("Auto AFK", "🚀 Enhancement started!")
        print("🚀 Auto AFK: Started")
    end,
    
    stop = function()
        AutoAFK.enabled = false
        Notify("Auto AFK", "🛑 Enhancement stopped!")
        print("🛑 Auto AFK: Stopped")
    end,
    
    monitor = function()
        while AutoAFK.monitoring do
            task.wait(1)
            if AutoAFK.enabled then
                -- Simple monitoring - just print status
                print("🔍 Auto AFK: Monitoring...")
            end
        end
    end
}

-- Simple UI
local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
gui.Name = "MinimalAutoAFK"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0, 350, 0, 180)
main.Position = UDim2.new(0.5, -175, 0.5, -90)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "🚀 Auto AFK - Official Auto Enhancement"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1

local desc = Instance.new("TextLabel", main)
desc.Size = UDim2.new(1, -20, 0, 30)
desc.Position = UDim2.new(0, 10, 0, 45)
desc.Text = "Enhances official auto mode with perfect performance"
desc.Font = Enum.Font.Gotham
desc.TextSize = 11
desc.TextColor3 = Color3.fromRGB(200, 200, 200)
desc.BackgroundTransparency = 1
desc.TextWrapped = true

local startBtn = Instance.new("TextButton", main)
startBtn.Size = UDim2.new(1, -20, 0, 35)
startBtn.Position = UDim2.new(0, 10, 0, 85)
startBtn.Text = "🚀 Start Auto AFK Enhancement"
startBtn.Font = Enum.Font.GothamSemibold
startBtn.TextSize = 12
startBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.BorderSizePixel = 0
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel", main)
status.Size = UDim2.new(1, -20, 0, 25)
status.Position = UDim2.new(0, 10, 0, 130)
status.Text = "📊 Status: Ready to enhance official auto mode"
status.Font = Enum.Font.Gotham
status.TextSize = 10
status.TextColor3 = Color3.fromRGB(150, 150, 150)
status.BackgroundTransparency = 1

local closeBtn = Instance.new("TextButton", main)
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0, 5)
closeBtn.Text = "×"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

-- Event handlers
startBtn.MouseButton1Click:Connect(function()
    if AutoAFK.enabled then
        AutoAFK.stop()
        startBtn.Text = "🚀 Start Auto AFK Enhancement"
        startBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        status.Text = "📊 Status: Auto AFK enhancement stopped"
    else
        AutoAFK.start()
        startBtn.Text = "🛑 Stop Auto AFK Enhancement"
        startBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
        status.Text = "📊 Status: Auto AFK enhancement active!"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Global API
_G.MinimalAutoAFK = AutoAFK

-- Commands
_G.START_AUTO_AFK = function()
    AutoAFK.start()
end

_G.STOP_AUTO_AFK = function()
    AutoAFK.stop()
end

_G.AUTO_AFK_STATUS = function()
    print("📊 Auto AFK Status:")
    print("  Enabled:", AutoAFK.enabled)
    print("  Monitoring:", AutoAFK.monitoring)
    return {enabled = AutoAFK.enabled, monitoring = AutoAFK.monitoring}
end

print("✅ Minimal Auto AFK loaded successfully!")
print("📋 Commands: _G.START_AUTO_AFK(), _G.STOP_AUTO_AFK(), _G.AUTO_AFK_STATUS()")
Notify("Auto AFK", "✅ Minimal version loaded successfully!")
