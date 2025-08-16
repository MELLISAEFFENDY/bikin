-- Fish It Built-in AutoFish Test
-- Test script untuk menggunakan AutoFish yang sudah ada di game

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Safe notification function
local function Notify(title, message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = tostring(message),
            Duration = 5
        })
    end)
end

-- Safe logging
local function Log(message)
    print("[Fish It AutoFish] " .. tostring(message))
    Notify("Fish It AutoFish", message)
end

-- Remote references berdasarkan debug hasil
local UpdateAutoFishingState
local SellAllItems
local ChargeFishingRod
local EquipBait

-- Initialize remote references
local function InitializeRemotes()
    pcall(function()
        UpdateAutoFishingState = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RF.UpdateAutoFishingState
        SellAllItems = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RF.SellAllItems
        ChargeFishingRod = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RF.ChargeFishingRod
        EquipBait = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RE.EquipBait
        Log("✅ Remote functions loaded successfully!")
    end)
end

-- Test built-in AutoFish
local function TestBuiltInAutoFish()
    if not UpdateAutoFishingState then
        Log("❌ UpdateAutoFishingState not found!")
        return false
    end
    
    pcall(function()
        Log("🎣 Testing built-in AutoFish activation...")
        local result = UpdateAutoFishingState:InvokeServer(true)
        Log("✅ AutoFish activation result: " .. tostring(result))
        return true
    end)
    
    return false
end

-- Test auto sell function
local function TestAutoSell()
    if not SellAllItems then
        Log("❌ SellAllItems not found!")
        return false
    end
    
    pcall(function()
        Log("💰 Testing auto sell function...")
        local result = SellAllItems:InvokeServer()
        Log("✅ Auto sell result: " .. tostring(result))
        return true
    end)
    
    return false
end

-- Test manual fishing
local function TestManualFishing()
    if not ChargeFishingRod then
        Log("❌ ChargeFishingRod not found!")
        return false
    end
    
    pcall(function()
        Log("🎣 Testing manual fishing cast...")
        local result = ChargeFishingRod:InvokeServer()
        Log("✅ Manual cast result: " .. tostring(result))
        return true
    end)
    
    return false
end

-- Monitor fishing events
local function MonitorFishingEvents()
    pcall(function()
        -- Monitor FishCaught event
        local FishCaught = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RE.FishCaught
        if FishCaught then
            FishCaught.OnClientEvent:Connect(function(...)
                Log("🐟 Fish caught! Args: " .. tostring(...))
            end)
        end
        
        -- Monitor FishingCompleted event
        local FishingCompleted = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RE.FishingCompleted
        if FishingCompleted then
            FishingCompleted.OnClientEvent:Connect(function(...)
                Log("✅ Fishing completed! Args: " .. tostring(...))
            end)
        end
        
        Log("👁️ Event monitoring started!")
    end)
end

-- Create simple test UI
local function CreateTestUI()
    pcall(function()
        -- Remove existing
        local existing = LocalPlayer.PlayerGui:FindFirstChild("FishItAutoFishTest")
        if existing then existing:Destroy() end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItAutoFishTest"
        screenGui.Parent = LocalPlayer.PlayerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 320, 0, 280)
        frame.Position = UDim2.new(0, 20, 0, 100)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 40)
        title.Text = "Fish It Built-in AutoFish Test"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.Parent = frame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 8)
        titleCorner.Parent = title
        
        -- Helper function untuk buat tombol
        local function createButton(text, position, color, callback)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -20, 0, 35)
            btn.Position = UDim2.new(0, 10, 0, position)
            btn.Text = text
            btn.BackgroundColor3 = color
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.Parent = frame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                task.spawn(callback)
            end)
            
            return btn
        end
        
        -- Buttons
        createButton("🎣 Test Built-in AutoFish", 50, Color3.fromRGB(100, 150, 255), TestBuiltInAutoFish)
        createButton("💰 Test Auto Sell", 95, Color3.fromRGB(255, 150, 100), TestAutoSell)
        createButton("🎣 Test Manual Cast", 140, Color3.fromRGB(150, 255, 100), TestManualFishing)
        createButton("👁️ Start Event Monitor", 185, Color3.fromRGB(255, 100, 150), MonitorFishingEvents)
        
        -- Close button
        createButton("❌ Close", 230, Color3.fromRGB(255, 100, 100), function()
            screenGui:Destroy()
        end)
        
        Log("🎮 Test UI created!")
    end)
end

-- Auto fishing state
local AutoFishingActive = false

-- Advanced AutoFish function combining built-in and manual
local function StartAdvancedAutoFish()
    if AutoFishingActive then
        Log("⚠️ AutoFish already running!")
        return
    end
    
    AutoFishingActive = true
    Log("🚀 Starting advanced AutoFish...")
    
    -- Try built-in AutoFish first
    local builtInSuccess = TestBuiltInAutoFish()
    
    -- If built-in fails, use manual method
    if not builtInSuccess then
        Log("🔄 Built-in failed, starting manual fishing...")
        
        task.spawn(function()
            while AutoFishingActive do
                pcall(function()
                    if ChargeFishingRod then
                        ChargeFishingRod:InvokeServer()
                    end
                end)
                wait(3) -- Wait 3 seconds between casts
            end
        end)
    end
    
    -- Auto sell loop
    task.spawn(function()
        while AutoFishingActive do
            wait(30) -- Sell every 30 seconds
            pcall(function()
                if SellAllItems then
                    SellAllItems:InvokeServer()
                    Log("💰 Auto-sold items!")
                end
            end)
        end
    end)
end

-- Stop AutoFish
local function StopAutoFish()
    AutoFishingActive = false
    Log("🛑 AutoFish stopped!")
    
    -- Try to disable built-in AutoFish
    pcall(function()
        if UpdateAutoFishingState then
            UpdateAutoFishingState:InvokeServer(false)
        end
    end)
end

-- Main initialization
local function Initialize()
    Log("🔄 Initializing Fish It AutoFish Test...")
    
    InitializeRemotes()
    MonitorFishingEvents()
    CreateTestUI()
    
    Log("✅ Fish It AutoFish Test ready!")
    Log("📖 Use the UI buttons to test different functions")
    Log("🎯 Try 'Test Built-in AutoFish' first!")
end

-- Start the test
Initialize()

-- Global functions for console testing
_G.FishItTest = {
    StartAutoFish = StartAdvancedAutoFish,
    StopAutoFish = StopAutoFish,
    TestBuiltIn = TestBuiltInAutoFish,
    TestSell = TestAutoSell,
    TestCast = TestManualFishing
}

Log("🎮 Use _G.FishItTest.StartAutoFish() to begin!")
