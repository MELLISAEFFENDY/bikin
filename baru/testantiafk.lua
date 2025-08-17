-- test_antiafk_advanced.lua
-- Advanced Anti AFK Test with multiple jump methods and detailed monitoring
-- Versi yang lebih komprehensif untuk debugging jump issues

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("test_antiafk_advanced: LocalPlayer missing")
    return
end

-- Notification function
local function Notify(title, message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = 4
        })
    end)
    print(string.format("[%s] %s", title, message))
end

-- Advanced Test AntiAFK System
local AdvancedTestAntiAFK = {
    enabled = false,
    lastJumpTime = 0,
    nextJumpTime = 0,
    sessionId = 0,
    jumpCount = 0,
    successfulJumps = 0,
    failedJumps = 0
}

-- Generate random time for testing
local function generateTestJumpTime()
    return math.random(8, 20) -- 8-20 seconds for better observation
end

-- Check if character can jump
local function canCharacterJump()
    if not LocalPlayer.Character then return false, "No character" end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return false, "No humanoid" end
    
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false, "No root part" end
    
    -- Check if character is on ground
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Freefall or 
       state == Enum.HumanoidStateType.Flying or
       state == Enum.HumanoidStateType.Jumping then
        return false, "Character not grounded (state: " .. tostring(state) .. ")"
    end
    
    return true, "Ready to jump"
end

-- Monitor jump success
local function monitorJumpSuccess(humanoid, rootPart)
    local startY = rootPart.Position.Y
    local maxHeight = startY
    local jumpDetected = false
    
    print("📊 Monitoring jump... Start Y:", startY)
    
    -- Monitor for 3 seconds
    for i = 1, 30 do
        task.wait(0.1)
        if not rootPart.Parent then break end
        
        local currentY = rootPart.Position.Y
        local velocity = rootPart.Velocity
        
        if currentY > maxHeight then
            maxHeight = currentY
        end
        
        -- Check if character is jumping/falling
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or 
           state == Enum.HumanoidStateType.Freefall or
           velocity.Y > 5 then
            jumpDetected = true
            print("✅ Jump detected! Height:", currentY, "Velocity Y:", velocity.Y, "State:", state)
        end
        
        -- If back on ground and we detected a jump
        if jumpDetected and (state == Enum.HumanoidStateType.Running or 
                           state == Enum.HumanoidStateType.Landed) then
            local heightGained = maxHeight - startY
            print("🎯 Jump completed! Height gained:", heightGained)
            return true, heightGained
        end
    end
    
    if jumpDetected then
        local heightGained = maxHeight - startY
        print("⚠️ Jump detected but monitoring timeout. Height gained:", heightGained)
        return true, heightGained
    else
        print("❌ No jump detected after 3 seconds")
        return false, 0
    end
end

-- Advanced jump function with multiple methods
local function performAdvancedJump()
    print("\n=== ADVANCED JUMP TEST ===")
    
    -- Pre-jump checks
    local canJump, reason = canCharacterJump()
    if not canJump then
        print("❌ Cannot jump:", reason)
        Notify("Advanced Test", "❌ Cannot jump: " .. reason)
        AdvancedTestAntiAFK.failedJumps = AdvancedTestAntiAFK.failedJumps + 1
        return false
    end
    
    print("✅ Pre-jump check passed:", reason)
    
    local humanoid = LocalPlayer.Character.Humanoid
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    
    -- Log character state before jump
    print("📋 Before jump:")
    print("  - Position:", rootPart.Position)
    print("  - Velocity:", rootPart.Velocity) 
    print("  - State:", humanoid:GetState())
    print("  - Jump Power:", humanoid.JumpPower or humanoid.JumpHeight or "Unknown")
    print("  - Platform Stand:", humanoid.PlatformStand)
    
    -- Method 1: Standard Jump
    print("🚀 Method 1: Standard Jump")
    humanoid.Jump = true
    task.wait(0.1)
    
    -- Method 2: Force Jump State
    print("🚀 Method 2: Force Jump State")
    pcall(function()
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
    task.wait(0.1)
    
    -- Method 3: Simulate Space Key (alternative approach)
    print("🚀 Method 3: Simulate Input")
    pcall(function()
        -- This simulates the space key press
        local VirtualInputManager = game:GetService("VirtualInputManager")
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
    
    -- Monitor jump success
    local success, heightGained = monitorJumpSuccess(humanoid, rootPart)
    
    -- Update counters
    AdvancedTestAntiAFK.jumpCount = AdvancedTestAntiAFK.jumpCount + 1
    if success then
        AdvancedTestAntiAFK.successfulJumps = AdvancedTestAntiAFK.successfulJumps + 1
        print("✅ JUMP SUCCESS! Height gained:", heightGained)
        Notify("Advanced Test", string.format("✅ Jump #%d success! Height: %.2f", AdvancedTestAntiAFK.jumpCount, heightGained))
    else
        AdvancedTestAntiAFK.failedJumps = AdvancedTestAntiAFK.failedJumps + 1
        print("❌ JUMP FAILED!")
        Notify("Advanced Test", string.format("❌ Jump #%d failed!", AdvancedTestAntiAFK.jumpCount))
    end
    
    -- Update timing
    local currentTime = tick()
    AdvancedTestAntiAFK.lastJumpTime = currentTime
    AdvancedTestAntiAFK.nextJumpTime = currentTime + generateTestJumpTime()
    
    print("=== JUMP TEST COMPLETE ===\n")
    return success
end

-- Main test runner
local function AdvancedTestRunner(mySessionId)
    AdvancedTestAntiAFK.nextJumpTime = tick() + generateTestJumpTime()
    print("🚀 Advanced Anti AFK test started")
    Notify("Advanced Test", "🚀 Advanced test started (detailed monitoring)")
    
    while AdvancedTestAntiAFK.enabled and AdvancedTestAntiAFK.sessionId == mySessionId do
        local currentTime = tick()
        
        -- Check if it's time to jump
        if currentTime >= AdvancedTestAntiAFK.nextJumpTime then
            performAdvancedJump()
        end
        
        -- Show countdown
        local timeLeft = AdvancedTestAntiAFK.nextJumpTime - currentTime
        if timeLeft > 0 and timeLeft <= 15 and math.floor(timeLeft) % 3 == 0 then
            print(string.format("⏰ Next jump in %.0f seconds...", timeLeft))
        end
        
        task.wait(1)
    end
    
    -- Final stats
    local successRate = AdvancedTestAntiAFK.jumpCount > 0 and 
                       (AdvancedTestAntiAFK.successfulJumps / AdvancedTestAntiAFK.jumpCount * 100) or 0
    
    print("🛑 Advanced test stopped")
    print(string.format("📊 Final Stats: %d total, %d success, %d failed (%.1f%% success rate)", 
          AdvancedTestAntiAFK.jumpCount, AdvancedTestAntiAFK.successfulJumps, 
          AdvancedTestAntiAFK.failedJumps, successRate))
    
    Notify("Advanced Test", string.format("🛑 Test complete! Success rate: %.1f%%", successRate))
end

-- Create enhanced GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdvancedTestAntiAFK"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main panel (larger for more info)
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 400, 0, 280)
panel.Position = UDim2.new(0.5, -200, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
panel.BorderSizePixel = 0
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.new(0, 10, 0, 10)
title.Text = "🔬 Advanced Anti AFK Test"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(120, 200, 255)
title.BackgroundTransparency = 1
title.Parent = panel

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 55)
statusLabel.Text = "Status: Ready for advanced testing"
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.TextSize = 12
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

-- Stats labels
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, -20, 0, 60)
statsLabel.Position = UDim2.new(0, 10, 0, 85)
statsLabel.Text = "Total Jumps: 0\nSuccessful: 0\nFailed: 0\nSuccess Rate: 0%"
statsLabel.Font = Enum.Font.GothamSemibold
statsLabel.TextSize = 11
statsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Parent = panel

-- Buttons
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 110, 0, 35)
startBtn.Position = UDim2.new(0, 20, 0, 160)
startBtn.Text = "🚀 Start Advanced"
startBtn.Font = Enum.Font.GothamSemibold
startBtn.TextSize = 12
startBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Parent = panel
Instance.new("UICorner", startBtn)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 110, 0, 35)
stopBtn.Position = UDim2.new(0, 145, 0, 160)
stopBtn.Text = "🛑 Stop Test"
stopBtn.Font = Enum.Font.GothamSemibold
stopBtn.TextSize = 12
stopBtn.BackgroundColor3 = Color3.fromRGB(190, 60, 60)
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.Parent = panel
Instance.new("UICorner", stopBtn)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 110, 0, 35)
closeBtn.Position = UDim2.new(0, 270, 0, 160)
closeBtn.Text = "❌ Close"
closeBtn.Font = Enum.Font.GothamSemibold
closeBtn.TextSize = 12
closeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = panel
Instance.new("UICorner", closeBtn)

-- Manual jump button for testing
local manualBtn = Instance.new("TextButton")
manualBtn.Size = UDim2.new(0, 240, 0, 30)
manualBtn.Position = UDim2.new(0, 80, 0, 205)
manualBtn.Text = "🦘 Manual Jump Test"
manualBtn.Font = Enum.Font.GothamSemibold
manualBtn.TextSize = 12
manualBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
manualBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
manualBtn.Parent = panel
Instance.new("UICorner", manualBtn)

-- Info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 35)
infoLabel.Position = UDim2.new(0, 10, 0, 240)
infoLabel.Text = "🔬 Advanced monitoring with multiple jump methods\n📊 Detailed success tracking and height measurement"
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 10
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.BackgroundTransparency = 1
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = panel

-- Update UI function
local function updateAdvancedUI()
    if AdvancedTestAntiAFK.enabled then
        statusLabel.Text = "Status: 🟢 Running advanced test..."
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        startBtn.Text = "🟢 Running"
        startBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        statusLabel.Text = "Status: 🔴 Stopped"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        startBtn.Text = "🚀 Start Advanced"
        startBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
    end
    
    local successRate = AdvancedTestAntiAFK.jumpCount > 0 and 
                       (AdvancedTestAntiAFK.successfulJumps / AdvancedTestAntiAFK.jumpCount * 100) or 0
    
    statsLabel.Text = string.format("Total Jumps: %d\nSuccessful: %d\nFailed: %d\nSuccess Rate: %.1f%%",
                                   AdvancedTestAntiAFK.jumpCount,
                                   AdvancedTestAntiAFK.successfulJumps,
                                   AdvancedTestAntiAFK.failedJumps,
                                   successRate)
end

-- Button callbacks
startBtn.MouseButton1Click:Connect(function()
    if AdvancedTestAntiAFK.enabled then
        Notify("Advanced Test", "⚠️ Test already running!")
        return
    end
    
    AdvancedTestAntiAFK.enabled = true
    AdvancedTestAntiAFK.sessionId = AdvancedTestAntiAFK.sessionId + 1
    AdvancedTestAntiAFK.jumpCount = 0
    AdvancedTestAntiAFK.successfulJumps = 0
    AdvancedTestAntiAFK.failedJumps = 0
    
    updateAdvancedUI()
    task.spawn(function()
        AdvancedTestRunner(AdvancedTestAntiAFK.sessionId)
    end)
end)

stopBtn.MouseButton1Click:Connect(function()
    AdvancedTestAntiAFK.enabled = false
    AdvancedTestAntiAFK.sessionId = AdvancedTestAntiAFK.sessionId + 1
    updateAdvancedUI()
end)

manualBtn.MouseButton1Click:Connect(function()
    task.spawn(function()
        performAdvancedJump()
        updateAdvancedUI()
    end)
end)

closeBtn.MouseButton1Click:Connect(function()
    AdvancedTestAntiAFK.enabled = false
    AdvancedTestAntiAFK.sessionId = AdvancedTestAntiAFK.sessionId + 1
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
    print("🔬 Advanced Test AntiAFK closed")
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

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        panel.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Initial UI update
updateAdvancedUI()

print("🔬 Advanced Test AntiAFK loaded! Multiple jump methods and detailed monitoring.")
Notify("Advanced Test", "🔬 Advanced test interface loaded!")
