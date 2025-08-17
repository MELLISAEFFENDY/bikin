-- movement_testing_ui.lua
-- Comprehensive UI for testing all movement functions

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Load movement systems
local generalMovements = loadstring(readfile("movement_examples.lua"))()
local fishingMovements = loadstring(readfile("fishing_movements.lua"))()

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

-- Movement Testing System
local MovementTester = {
    currentTest = nil,
    testRunning = false,
    testResults = {},
    activeConnections = {}
}

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovementTestingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main panel
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 600, 0, 500)
mainPanel.Position = UDim2.new(0.5, -300, 0.5, -250)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainPanel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 120, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainPanel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Text = "🎮 Movement Testing Interface"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.BackgroundTransparency = 1
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn)

-- Tab system
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -20, 0, 35)
tabContainer.Position = UDim2.new(0, 10, 0, 50)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainPanel

-- Content area
local contentArea = Instance.new("ScrollingFrame")
contentArea.Size = UDim2.new(1, -20, 1, -100)
contentArea.Position = UDim2.new(0, 10, 0, 90)
contentArea.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
contentArea.BorderSizePixel = 0
contentArea.CanvasSize = UDim2.new(0, 0, 0, 0)
contentArea.ScrollBarThickness = 8
contentArea.Parent = mainPanel

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentArea

-- Status bar
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, 25)
statusBar.Position = UDim2.new(0, 0, 1, -25)
statusBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
statusBar.BorderSizePixel = 0
statusBar.Parent = mainPanel

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -10, 1, 0)
statusText.Position = UDim2.new(0, 5, 0, 0)
statusText.Text = "Ready to test movements"
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 12
statusText.TextColor3 = Color3.fromRGB(150, 150, 150)
statusText.BackgroundTransparency = 1
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBar

-- Tab definitions
local tabs = {
    {
        name = "Basic",
        icon = "🚶",
        tests = {
            {name = "Jump", func = function() generalMovements.jump() end, desc = "Simple character jump"},
            {name = "Walk Forward", func = function() generalMovements.walkTo(Vector3.new(0, 0, 1), 20) task.wait(2) generalMovements.stop() end, desc = "Walk forward for 2 seconds"},
            {name = "Walk Left", func = function() generalMovements.walkTo(Vector3.new(-1, 0, 0), 16) task.wait(2) generalMovements.stop() end, desc = "Walk left for 2 seconds"},
            {name = "Walk Right", func = function() generalMovements.walkTo(Vector3.new(1, 0, 0), 16) task.wait(2) generalMovements.stop() end, desc = "Walk right for 2 seconds"},
            {name = "Walk Backward", func = function() generalMovements.walkTo(Vector3.new(0, 0, -1), 16) task.wait(2) generalMovements.stop() end, desc = "Walk backward for 2 seconds"},
            {name = "Stop Movement", func = function() generalMovements.stop() end, desc = "Stop all movement"},
        }
    },
    {
        name = "Teleport",
        icon = "📍",
        tests = {
            {name = "Teleport Up", func = function() 
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = LocalPlayer.Character.HumanoidRootPart.Position
                    generalMovements.teleport(pos + Vector3.new(0, 10, 0))
                end
            end, desc = "Teleport 10 studs up"},
            {name = "Teleport Forward", func = function() generalMovements.teleportForward(10) end, desc = "Teleport 10 studs forward"},
            {name = "Teleport to Spawn", func = function() generalMovements.teleport(Vector3.new(0, 10, 0)) end, desc = "Teleport to spawn area"},
            {name = "Random Teleport", func = function()
                local randomPos = Vector3.new(math.random(-50, 50), 10, math.random(-50, 50))
                generalMovements.teleport(randomPos)
            end, desc = "Teleport to random nearby location"},
        }
    },
    {
        name = "Advanced",
        icon = "✈️",
        tests = {
            {name = "Enable Fly", func = function() 
                MovementTester.flyControl = generalMovements.fly(50)
                Notify("Fly Mode", "Fly enabled! Use WASD to control")
            end, desc = "Enable fly mode with speed 50"},
            {name = "Disable Fly", func = function()
                if MovementTester.flyControl then
                    MovementTester.flyControl:Destroy()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.PlatformStand = false
                    end
                    Notify("Fly Mode", "Fly disabled")
                end
            end, desc = "Disable fly mode"},
            {name = "Enable Noclip", func = function() generalMovements.noclip() end, desc = "Enable noclip (walk through walls)"},
            {name = "Disable Noclip", func = function() generalMovements.disableNoclip() end, desc = "Disable noclip"},
            {name = "Smooth Rotation", func = function()
                generalMovements.smoothRotate(Vector3.new(1, 0, 0), 2)
            end, desc = "Smooth rotate to face right"},
        }
    },
    {
        name = "Patterns",
        icon = "🔄",
        tests = {
            {name = "Circle Walk (Small)", func = function() 
                MovementTester.currentTest = "circlewalk"
                task.spawn(function() generalMovements.circleWalk(5, 16, 10) end)
            end, desc = "Walk in small circle for 10 seconds"},
            {name = "Circle Walk (Large)", func = function() 
                MovementTester.currentTest = "circlewalk"
                task.spawn(function() generalMovements.circleWalk(15, 20, 15) end)
            end, desc = "Walk in large circle for 15 seconds"},
            {name = "Random Movement", func = function() 
                MovementTester.currentTest = "random"
                task.spawn(function() generalMovements.randomMove(10, 18) end)
            end, desc = "Random movement for 10 seconds"},
            {name = "Figure 8 Pattern", func = function()
                MovementTester.currentTest = "figure8"
                task.spawn(function()
                    -- Custom figure 8 movement
                    if not LocalPlayer.Character then return end
                    local humanoid = LocalPlayer.Character.Humanoid
                    local rootPart = LocalPlayer.Character.HumanoidRootPart
                    local centerPos = rootPart.Position
                    
                    for i = 1, 100 do
                        if not LocalPlayer.Character then break end
                        local angle = i * 0.2
                        local x = centerPos.X + math.sin(angle) * 8
                        local z = centerPos.Z + math.sin(angle * 2) * 8
                        humanoid:MoveTo(Vector3.new(x, centerPos.Y, z))
                        task.wait(0.1)
                    end
                end)
            end, desc = "Walk in figure 8 pattern"},
        }
    },
    {
        name = "Anti-AFK",
        icon = "🦘",
        tests = {
            {name = "AFK Jump", func = function() fishingMovements.antiAfk.jump() end, desc = "Standard anti-AFK jump"},
            {name = "Small Step", func = function() 
                task.spawn(function() fishingMovements.antiAfk.smallStep() end)
            end, desc = "Take small step and return"},
            {name = "Look Around", func = function() 
                task.spawn(function() fishingMovements.antiAfk.lookAround() end)
            end, desc = "Look left and right"},
            {name = "Crouch Toggle", func = function() 
                task.spawn(function() fishingMovements.antiAfk.crouchToggle() end)
            end, desc = "Toggle crouch position"},
            {name = "Random AFK Move", func = function() fishingMovements.randomAntiAfk() end, desc = "Random anti-AFK behavior"},
            {name = "Natural Idle", func = function() fishingMovements.naturalIdle() end, desc = "Natural looking idle movement"},
            {name = "Auto AFK (30s)", func = function()
                MovementTester.currentTest = "autoafk"
                MovementTester.testRunning = true
                task.spawn(function()
                    for i = 1, 6 do
                        if not MovementTester.testRunning then break end
                        fishingMovements.randomAntiAfk()
                        task.wait(5)
                    end
                    MovementTester.testRunning = false
                end)
            end, desc = "Auto anti-AFK for 30 seconds"},
        }
    },
    {
        name = "Input Sim",
        icon = "⌨️",
        tests = {
            {name = "Space Key", func = function() generalMovements.keyPress(Enum.KeyCode.Space, 0.1) end, desc = "Simulate space key press"},
            {name = "W Key (1s)", func = function() generalMovements.keyPress(Enum.KeyCode.W, 1) end, desc = "Hold W key for 1 second"},
            {name = "A Key (1s)", func = function() generalMovements.keyPress(Enum.KeyCode.A, 1) end, desc = "Hold A key for 1 second"},
            {name = "S Key (1s)", func = function() generalMovements.keyPress(Enum.KeyCode.S, 1) end, desc = "Hold S key for 1 second"},
            {name = "D Key (1s)", func = function() generalMovements.keyPress(Enum.KeyCode.D, 1) end, desc = "Hold D key for 1 second"},
            {name = "WASD Sequence", func = function()
                task.spawn(function()
                    generalMovements.keyPress(Enum.KeyCode.W, 0.5)
                    task.wait(0.1)
                    generalMovements.keyPress(Enum.KeyCode.A, 0.5)
                    task.wait(0.1)
                    generalMovements.keyPress(Enum.KeyCode.S, 0.5)
                    task.wait(0.1)
                    generalMovements.keyPress(Enum.KeyCode.D, 0.5)
                end)
            end, desc = "Press W-A-S-D in sequence"},
            {name = "Mouse Click Center", func = function() 
                local screenSize = workspace.CurrentCamera.ViewportSize
                generalMovements.mouseClick(Vector2.new(screenSize.X/2, screenSize.Y/2))
            end, desc = "Click center of screen"},
        }
    },
    {
        name = "Fishing",
        icon = "🎣",
        tests = {
            {name = "Walk to Moosewood", func = function() 
                task.spawn(function() fishingMovements.walkToSpot("Moosewood") end)
            end, desc = "Auto walk to Moosewood fishing spot"},
            {name = "Walk to Snowcap", func = function() 
                task.spawn(function() fishingMovements.walkToSpot("Snowcap") end)
            end, desc = "Auto walk to Snowcap fishing spot"},
            {name = "Walk to Mushgrove", func = function() 
                task.spawn(function() fishingMovements.walkToSpot("Mushgrove") end)
            end, desc = "Auto walk to Mushgrove fishing spot"},
            {name = "Walk to Altar", func = function() 
                task.spawn(function() fishingMovements.walkToSpot("Altar") end)
            end, desc = "Auto walk to Altar fishing spot"},
            {name = "Dodge Players", func = function() 
                local dodged = fishingMovements.dodgePlayers(15)
                if dodged then
                    Notify("Player Dodge", "Dodged nearby player!")
                else
                    Notify("Player Dodge", "No players nearby")
                end
            end, desc = "Check and dodge nearby players"},
            {name = "Emergency Escape", func = function() 
                task.spawn(function() fishingMovements.emergencyEscape() end)
            end, desc = "Perform emergency escape"},
        }
    },
    {
        name = "Animation",
        icon = "🎭",
        tests = {
            {name = "Wave Emote", func = function() generalMovements.emote("wave") end, desc = "Play wave emote"},
            {name = "Dance Emote", func = function() generalMovements.emote("dance") end, desc = "Play dance emote"},
            {name = "Point Emote", func = function() generalMovements.emote("point") end, desc = "Play point emote"},
            {name = "Laugh Emote", func = function() generalMovements.emote("laugh") end, desc = "Play laugh emote"},
            {name = "Cheer Emote", func = function() generalMovements.emote("cheer") end, desc = "Play cheer emote"},
            {name = "Custom Animation", func = function() 
                -- Example animation ID (replace with actual ID)
                local animId = "507770239" -- Example: Gangnam Style
                generalMovements.animate(animId)
            end, desc = "Play custom animation"},
        }
    }
}

-- Current active tab
local currentTab = 1

-- Create tab buttons
local tabButtons = {}
for i, tab in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1/#tabs, -2, 1, 0)
    tabBtn.Position = UDim2.new((i-1)/#tabs, 1, 0, 0)
    tabBtn.Text = tab.icon .. " " .. tab.name
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextSize = 12
    tabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(40, 40, 45)
    tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = tabContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabBtn
    
    tabButtons[i] = tabBtn
    
    tabBtn.MouseButton1Click:Connect(function()
        currentTab = i
        for j, btn in ipairs(tabButtons) do
            btn.BackgroundColor3 = j == i and Color3.fromRGB(50, 120, 200) or Color3.fromRGB(40, 40, 45)
        end
        updateTabContent()
    end)
end

-- Create test buttons for current tab
local testButtons = {}

local function updateTabContent()
    -- Clear existing buttons
    for _, btn in ipairs(testButtons) do
        btn:Destroy()
    end
    testButtons = {}
    
    local tab = tabs[currentTab]
    local yOffset = 10
    
    for i, test in ipairs(tab.tests) do
        -- Test container
        local testContainer = Instance.new("Frame")
        testContainer.Size = UDim2.new(1, -20, 0, 60)
        testContainer.Position = UDim2.new(0, 10, 0, yOffset)
        testContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        testContainer.BorderSizePixel = 0
        testContainer.Parent = contentArea
        
        local containerCorner = Instance.new("UICorner")
        containerCorner.CornerRadius = UDim.new(0, 8)
        containerCorner.Parent = testContainer
        
        -- Test button
        local testBtn = Instance.new("TextButton")
        testBtn.Size = UDim2.new(0, 120, 0, 35)
        testBtn.Position = UDim2.new(0, 10, 0, 5)
        testBtn.Text = "▶ " .. test.name
        testBtn.Font = Enum.Font.GothamSemibold
        testBtn.TextSize = 12
        testBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
        testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        testBtn.Parent = testContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = testBtn
        
        -- Test description
        local testDesc = Instance.new("TextLabel")
        testDesc.Size = UDim2.new(1, -140, 1, -10)
        testDesc.Position = UDim2.new(0, 135, 0, 5)
        testDesc.Text = test.desc
        testDesc.Font = Enum.Font.Gotham
        testDesc.TextSize = 11
        testDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
        testDesc.BackgroundTransparency = 1
        testDesc.TextXAlignment = Enum.TextXAlignment.Left
        testDesc.TextWrapped = true
        testDesc.Parent = testContainer
        
        -- Test result indicator
        local resultIndicator = Instance.new("Frame")
        resultIndicator.Size = UDim2.new(0, 8, 0, 8)
        resultIndicator.Position = UDim2.new(1, -15, 0, 5)
        resultIndicator.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        resultIndicator.BorderSizePixel = 0
        resultIndicator.Parent = testContainer
        
        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0.5, 0)
        indicatorCorner.Parent = resultIndicator
        
        -- Button click handler
        testBtn.MouseButton1Click:Connect(function()
            if MovementTester.testRunning and MovementTester.currentTest then
                MovementTester.testRunning = false
                testBtn.Text = "▶ " .. test.name
                testBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
                statusText.Text = "Test stopped: " .. test.name
                resultIndicator.BackgroundColor3 = Color3.fromRGB(255, 150, 0) -- Orange for stopped
                return
            end
            
            statusText.Text = "Running test: " .. test.name
            testBtn.Text = "⏹ Stop"
            testBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
            resultIndicator.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Yellow for running
            
            MovementTester.testRunning = true
            MovementTester.currentTest = test.name
            
            task.spawn(function()
                local success = pcall(function()
                    test.func()
                end)
                
                task.wait(1) -- Give time for test to complete
                
                if success then
                    resultIndicator.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green for success
                    Notify("Test Result", "✅ " .. test.name .. " completed successfully")
                else
                    resultIndicator.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red for error
                    Notify("Test Result", "❌ " .. test.name .. " failed")
                end
                
                testBtn.Text = "▶ " .. test.name
                testBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
                statusText.Text = "Test completed: " .. test.name
                MovementTester.testRunning = false
                MovementTester.currentTest = nil
            end)
        end)
        
        table.insert(testButtons, testContainer)
        yOffset = yOffset + 70
    end
    
    -- Update canvas size
    contentArea.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)
end

-- Control panel (always visible)
local controlPanel = Instance.new("Frame")
controlPanel.Size = UDim2.new(1, -20, 0, 80)
controlPanel.Position = UDim2.new(0, 10, 1, -90)
controlPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
controlPanel.BorderSizePixel = 0
controlPanel.Parent = contentArea

local controlCorner = Instance.new("UICorner")
controlCorner.CornerRadius = UDim.new(0, 8)
controlCorner.Parent = controlPanel

-- Emergency stop button
local emergencyStopBtn = Instance.new("TextButton")
emergencyStopBtn.Size = UDim2.new(0, 100, 0, 30)
emergencyStopBtn.Position = UDim2.new(0, 10, 0, 10)
emergencyStopBtn.Text = "🚨 STOP ALL"
emergencyStopBtn.Font = Enum.Font.GothamBold
emergencyStopBtn.TextSize = 12
emergencyStopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
emergencyStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emergencyStopBtn.Parent = controlPanel
Instance.new("UICorner", emergencyStopBtn)

-- Reset character button
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 100, 0, 30)
resetBtn.Position = UDim2.new(0, 120, 0, 10)
resetBtn.Text = "💀 Reset Char"
resetBtn.Font = Enum.Font.GothamSemibold
resetBtn.TextSize = 12
resetBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Parent = controlPanel
Instance.new("UICorner", resetBtn)

-- Character info
local charInfo = Instance.new("TextLabel")
charInfo.Size = UDim2.new(1, -240, 0, 60)
charInfo.Position = UDim2.new(0, 230, 0, 10)
charInfo.Text = "Character Info:\nPosition: Loading...\nVelocity: Loading..."
charInfo.Font = Enum.Font.Gotham
charInfo.TextSize = 10
charInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
charInfo.BackgroundTransparency = 1
charInfo.TextXAlignment = Enum.TextXAlignment.Left
charInfo.TextYAlignment = Enum.TextYAlignment.Top
charInfo.Parent = controlPanel

-- Button handlers
emergencyStopBtn.MouseButton1Click:Connect(function()
    MovementTester.testRunning = false
    MovementTester.currentTest = nil
    
    -- Stop all movements
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), true)
    end
    
    -- Disconnect all connections
    for _, connection in pairs(MovementTester.activeConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    MovementTester.activeConnections = {}
    
    -- Disable fly if active
    if MovementTester.flyControl then
        MovementTester.flyControl:Destroy()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end
    
    statusText.Text = "🚨 All tests stopped - Emergency stop activated"
    Notify("Emergency Stop", "🚨 All movements stopped!")
end)

resetBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
        statusText.Text = "💀 Character reset"
        Notify("Character Reset", "💀 Character has been reset")
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    MovementTester.testRunning = false
    screenGui:Destroy()
    print("🎮 Movement Testing UI closed")
end)

-- Update character info
local function updateCharacterInfo()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        local pos = rootPart.Position
        local vel = rootPart.Velocity
        
        charInfo.Text = string.format(
            "Character Info:\nPosition: %.1f, %.1f, %.1f\nVelocity: %.1f, %.1f, %.1f\nSpeed: %.1f",
            pos.X, pos.Y, pos.Z,
            vel.X, vel.Y, vel.Z,
            vel.Magnitude
        )
    else
        charInfo.Text = "Character Info:\nNo character found\nWaiting for respawn..."
    end
end

-- Start character info updates
RunService.Heartbeat:Connect(updateCharacterInfo)

-- Make panel draggable
local dragging = false
local dragInput, mousePos, framePos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainPanel.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainPanel.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Initialize with first tab
updateTabContent()

print("🎮 Movement Testing UI loaded!")
print("📋 Features:")
print("  • 8 categories with 40+ tests")
print("  • Real-time character monitoring")
print("  • Emergency stop functionality")
print("  • Visual test result indicators")
print("  • Draggable interface")
Notify("Movement Tester", "🎮 Testing interface loaded! Ready to test movements.")
