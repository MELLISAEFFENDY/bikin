-- test_antiafk.lua
-- Script khusus untuk test Anti AFK System
-- Menguji fungsi jump dengan interval yang dipercepat untuk testing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

-- Must run on client
if not RunService:IsClient() then
    warn("test_antiafk: must run as LocalScript on the client")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("test_antiafk: LocalPlayer missing")
    return
end

-- Notification function
local function Notify(title, message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = 3
        })
    end)
    print(string.format("[%s] %s", title, message))
end

-- Test AntiAFK System (accelerated for testing)
local TestAntiAFK = {
    enabled = false,
    lastJumpTime = 0,
    nextJumpTime = 0,
    sessionId = 0,
    jumpCount = 0
}

-- Generate random time for testing (5-15 seconds instead of minutes)
local function generateTestJumpTime()
    return math.random(5, 15) -- 5-15 seconds for quick testing
end

-- Perform jump with detailed logging
local function performTestJump()
    print("=== TESTING JUMP ===")
    
    -- Check character
    if not LocalPlayer.Character then
        print("❌ No character found")
        Notify("Test AntiAFK", "❌ No character found")
        return false
    end
    
    -- Check humanoid
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then
        print("❌ No humanoid found")
        Notify("Test AntiAFK", "❌ No humanoid found")
        return false
    end
    
    -- Check if character is grounded (optional check)
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        print("✅ Character position:", rootPart.Position)
    end
    
    -- Perform jump
    print("🦘 Executing jump...")
    humanoid.Jump = true
    
    -- Update timing
    local currentTime = tick()
    TestAntiAFK.lastJumpTime = currentTime
    TestAntiAFK.nextJumpTime = currentTime + generateTestJumpTime()
    TestAntiAFK.jumpCount = TestAntiAFK.jumpCount + 1
    
    -- Calculate next jump time
    local nextJumpSeconds = math.floor(TestAntiAFK.nextJumpTime - currentTime)
    
    -- Notifications and logging
    local message = string.format("Jump #%d performed! Next in %ds", TestAntiAFK.jumpCount, nextJumpSeconds)
    print("✅ " .. message)
    Notify("Test AntiAFK", message)
    
    return true
end

-- Main test runner
local function TestAntiAfkRunner(mySessionId)
    TestAntiAFK.nextJumpTime = tick() + generateTestJumpTime()
    print("🚀 Test AntiAFK system started")
    Notify("Test AntiAFK", "🚀 Test system started (accelerated timing)")
    
    while TestAntiAFK.enabled and TestAntiAFK.sessionId == mySessionId do
        local currentTime = tick()
        
        -- Check if it's time to jump
        if currentTime >= TestAntiAFK.nextJumpTime then
            local success = performTestJump()
            if not success then
                print("⚠️ Jump failed, retrying in 2 seconds...")
                TestAntiAFK.nextJumpTime = currentTime + 2
            end
        end
        
        -- Show countdown every 5 seconds
        local timeLeft = TestAntiAFK.nextJumpTime - currentTime
        if timeLeft > 0 and math.floor(timeLeft) % 5 == 0 and math.floor(timeLeft) <= 15 then
            print(string.format("⏰ Next jump in %.0f seconds...", timeLeft))
        end
        
        task.wait(1) -- Check every second
    end
    
    print("🛑 Test AntiAFK system stopped")
    Notify("Test AntiAFK", string.format("🛑 Test stopped. Total jumps: %d", TestAntiAFK.jumpCount))
end

-- Create simple test GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestAntiAFK"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 200)
panel.Position = UDim2.new(0.5, -160, 0.5, -100)
panel.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
panel.BorderSizePixel = 0
panel.Parent = screenGui
Instance.new("UICorner", panel)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 10)
title.Text = "🧪 Anti AFK Test"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(100, 200, 255)
title.BackgroundTransparency = 1
title.Parent = panel

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 50)
statusLabel.Text = "Status: Ready to test"
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

-- Jump count label
local jumpCountLabel = Instance.new("TextLabel")
jumpCountLabel.Size = UDim2.new(1, -20, 0, 25)
jumpCountLabel.Position = UDim2.new(0, 10, 0, 75)
jumpCountLabel.Text = "Jump Count: 0"
jumpCountLabel.Font = Enum.Font.GothamSemibold
jumpCountLabel.TextSize = 12
jumpCountLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
jumpCountLabel.BackgroundTransparency = 1
jumpCountLabel.TextXAlignment = Enum.TextXAlignment.Left
jumpCountLabel.Parent = panel

-- Start button
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 90, 0, 30)
startBtn.Position = UDim2.new(0, 20, 0, 110)
startBtn.Text = "🚀 Start Test"
startBtn.Font = Enum.Font.GothamSemibold
startBtn.TextSize = 12
startBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Parent = panel
Instance.new("UICorner", startBtn)

-- Stop button
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 90, 0, 30)
stopBtn.Position = UDim2.new(0, 120, 0, 110)
stopBtn.Text = "🛑 Stop Test"
stopBtn.Font = Enum.Font.GothamSemibold
stopBtn.TextSize = 12
stopBtn.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Parent = panel
Instance.new("UICorner", stopBtn)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 30)
closeBtn.Position = UDim2.new(0, 220, 0, 110)
closeBtn.Text = "❌ Close"
closeBtn.Font = Enum.Font.GothamSemibold
closeBtn.TextSize = 12
closeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn)

-- Info label
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 40)
infoLabel.Position = UDim2.new(0, 10, 0, 150)
infoLabel.Text = "⚡ Accelerated: Jumps every 5-15 seconds\n📊 Check console for detailed logs"
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 10
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.BackgroundTransparency = 1
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = panel

-- Update UI function
local function updateUI()
    if TestAntiAFK.enabled then
        statusLabel.Text = "Status: 🟢 Running - Testing jumps..."
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        startBtn.Text = "🟢 Running"
        startBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        statusLabel.Text = "Status: 🔴 Stopped"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        startBtn.Text = "🚀 Start Test"
        startBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
    end
    jumpCountLabel.Text = "Jump Count: " .. TestAntiAFK.jumpCount
end

-- Button callbacks
startBtn.MouseButton1Click:Connect(function()
    if TestAntiAFK.enabled then
        Notify("Test AntiAFK", "⚠️ Test already running!")
        return
    end
    
    TestAntiAFK.enabled = true
    TestAntiAFK.sessionId = TestAntiAFK.sessionId + 1
    TestAntiAFK.jumpCount = 0
    
    updateUI()
    task.spawn(function()
        TestAntiAfkRunner(TestAntiAFK.sessionId)
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    TestAntiAFK.enabled = false
    TestAntiAFK.sessionId = TestAntiAFK.sessionId + 1
    updateUI()
end)

closeBtn.MouseButton1Click:Connect(function()
    TestAntiAFK.enabled = false
    TestAntiAFK.sessionId = TestAntiAFK.sessionId + 1
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
    print("🧪 Test AntiAFK closed")
end)

-- Make panel draggable
local dragging = false
local dragInput, mousePos, framePos

panel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = panel.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

panel.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        panel.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Initial UI update
updateUI()

print("🧪 Test AntiAFK loaded! Use the GUI to start testing.")
Notify("Test AntiAFK", "🧪 Test interface loaded!")
