-- autofish_fisch.lua
-- Complete AutoFish script for Roblox "Fisch" game with UI interface

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- AutoFish System
local AutoFish = {
    enabled = false,
    mode = "Normal", -- "Normal", "Fast", "Safe"
    rodEquipped = false,
    fishing = false,
    lastCastTime = 0,
    catchCount = 0,
    sessionStartTime = tick(),
    currentSpot = "None",
    autoSell = false,
    antiAFK = true,
    lastAFKTime = 0
}

-- Statistics
local Stats = {
    totalCatches = 0,
    commonFish = 0,
    uncommonFish = 0,
    rareFish = 0,
    legendaryFish = 0,
    mythicFish = 0,
    sessionTime = 0,
    fishPerHour = 0
}

-- Fishing Spots
local FishingSpots = {
    ["Moosewood"] = {pos = Vector3.new(-1463, 131, 213), biome = "Freshwater"},
    ["Snowcap"] = {pos = Vector3.new(2648, 140, 2522), biome = "Arctic"},
    ["Mushgrove"] = {pos = Vector3.new(2500, 131, -721), biome = "Swamp"},
    ["Roslit"] = {pos = Vector3.new(-1742, 131, -1006), biome = "Ocean"},
    ["Sunstone"] = {pos = Vector3.new(-934, 131, -1113), biome = "Desert"},
    ["Forsaken"] = {pos = Vector3.new(-2895, 131, 1717), biome = "Desolate"},
    ["Altar"] = {pos = Vector3.new(1306, -806, -105), biome = "Deep Ocean"}
}

-- Notification function
local function Notify(title, message, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 3
        })
    end)
    print(string.format("[AutoFish] %s: %s", title, message))
end

-- Check if rod is equipped
local function isRodEquipped()
    if not LocalPlayer.Character then return false end
    
    -- Check for fishing rod in character
    for _, item in pairs(LocalPlayer.Character:GetChildren()) do
        if item:IsA("Tool") and (
            item.Name:lower():find("rod") or 
            item.Name:lower():find("fishing") or
            item.Name:lower():find("pole")
        ) then
            return true, item
        end
    end
    
    return false
end

-- Equip fishing rod
local function equipRod()
    if not LocalPlayer.Character then return false end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return false end
    
    -- Find fishing rod in backpack
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (
            item.Name:lower():find("rod") or 
            item.Name:lower():find("fishing") or
            item.Name:lower():find("pole")
        ) then
            -- Equip the rod
            LocalPlayer.Character.Humanoid:EquipTool(item)
            task.wait(1)
            return true
        end
    end
    
    return false
end

-- Cast fishing line
local function castLine()
    if not LocalPlayer.Character then return false end
    
    local equipped, rod = isRodEquipped()
    if not equipped then
        if not equipRod() then
            Notify("AutoFish", "❌ No fishing rod found!")
            return false
        end
        equipped, rod = isRodEquipped()
    end
    
    if not rod then return false end
    
    -- Try multiple casting methods
    -- Method 1: Click detector
    local clickDetector = rod:FindFirstChildOfClass("ClickDetector")
    if clickDetector then
        fireclickdetector(clickDetector)
        print("🎣 Cast method 1: ClickDetector")
        return true
    end
    
    -- Method 2: Remote events
    for _, remote in pairs(rod:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            remote:FireServer()
            print("🎣 Cast method 2: RemoteEvent")
            return true
        end
    end
    
    -- Method 3: ProximityPrompt
    for _, prompt in pairs(rod:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            fireproximityprompt(prompt)
            print("🎣 Cast method 3: ProximityPrompt")
            return true
        end
    end
    
    -- Method 4: Mouse click simulation
    if rod:FindFirstChild("Handle") then
        local mouse = LocalPlayer:GetMouse()
        mouse.Button1Down:Connect(function() end)
        print("🎣 Cast method 4: Mouse simulation")
        return true
    end
    
    print("⚠️ Could not cast - no valid method found")
    return false
end

-- Check for fish bite/catch
local function checkForBite()
    if not LocalPlayer.Character then return false end
    
    -- Check for UI indicators
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        -- Look for fishing UI
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui.Name:lower():find("fish") or gui.Name:lower():find("catch") then
                for _, element in pairs(gui:GetDescendants()) do
                    if element:IsA("TextLabel") or element:IsA("TextButton") then
                        local text = element.Text:lower()
                        if text:find("catch") or text:find("reel") or text:find("bite") then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    -- Check for bobber movement/animation
    local equipped, rod = isRodEquipped()
    if equipped and rod then
        -- Look for fishing line/bobber
        for _, part in pairs(workspace:GetDescendants()) do
            if part.Name:lower():find("bobber") or part.Name:lower():find("float") then
                if part:IsA("BasePart") and part.Velocity.Magnitude > 5 then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Reel in fish
local function reelIn()
    if not LocalPlayer.Character then return false end
    
    local equipped, rod = isRodEquipped()
    if not equipped or not rod then return false end
    
    -- Try multiple reeling methods
    -- Method 1: Key press simulation (usually space or mouse)
    local VirtualInputManager = game:GetService("VirtualInputManager")
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    
    -- Method 2: Mouse click
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    
    -- Method 3: Tool activation
    if rod:FindFirstChild("Handle") then
        rod:Activate()
    end
    
    print("🎣 Attempting to reel in...")
    return true
end

-- Auto-sell fish
local function autoSellFish()
    if not AutoFish.autoSell then return end
    
    -- Find merchant/shop
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc.Name:lower():find("merchant") or npc.Name:lower():find("shop") then
            if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
                local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    -- Walk to merchant
                    local distance = (humanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                    if distance > 10 then
                        LocalPlayer.Character.Humanoid:MoveTo(npc.HumanoidRootPart.Position)
                        LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
                    end
                    
                    -- Try to interact
                    local proximityPrompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
                    if proximityPrompt then
                        fireproximityprompt(proximityPrompt)
                        task.wait(2)
                        
                        -- Look for sell all button
                        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                        if playerGui then
                            for _, gui in pairs(playerGui:GetDescendants()) do
                                if gui:IsA("TextButton") and gui.Text:lower():find("sell") then
                                    gui:Fire()
                                    break
                                end
                            end
                        end
                    end
                end
                break
            end
        end
    end
end

-- Anti-AFK system
local function performAntiAFK()
    if not AutoFish.antiAFK then return end
    
    local currentTime = tick()
    if currentTime - AutoFish.lastAFKTime < 120 then return end -- Every 2 minutes
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local actions = {
            function() LocalPlayer.Character.Humanoid.Jump = true end,
            function() 
                local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local pos = rootPart.Position
                    LocalPlayer.Character.Humanoid:MoveTo(pos + Vector3.new(2, 0, 0))
                    task.wait(1)
                    LocalPlayer.Character.Humanoid:MoveTo(pos)
                end
            end,
            function()
                local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local originalCFrame = rootPart.CFrame
                    rootPart.CFrame = originalCFrame * CFrame.Angles(0, math.rad(45), 0)
                    task.wait(0.5)
                    rootPart.CFrame = originalCFrame
                end
            end
        }
        
        local randomAction = actions[math.random(1, #actions)]
        randomAction()
        
        AutoFish.lastAFKTime = currentTime
        print("🤖 Anti-AFK action performed")
    end
end

-- Walk to fishing spot
local function walkToSpot(spotName)
    local spot = FishingSpots[spotName]
    if not spot then
        Notify("AutoFish", "❌ Unknown fishing spot: " .. spotName)
        return false
    end
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
        return false
    end
    
    Notify("AutoFish", "🚶 Walking to " .. spotName .. "...")
    
    LocalPlayer.Character.Humanoid:MoveTo(spot.pos)
    LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
    
    AutoFish.currentSpot = spotName
    Notify("AutoFish", "✅ Arrived at " .. spotName)
    return true
end

-- Main fishing loop
local function fishingLoop()
    while AutoFish.enabled do
        task.wait(1)
        
        if not LocalPlayer.Character then
            task.wait(5)
            continue
        end
        
        -- Anti-AFK
        performAntiAFK()
        
        -- Check if rod is equipped
        local equipped = isRodEquipped()
        if not equipped then
            if not equipRod() then
                Notify("AutoFish", "❌ No fishing rod found! Stopping...")
                AutoFish.enabled = false
                break
            end
        end
        
        -- Fishing logic based on mode
        local castDelay = AutoFish.mode == "Fast" and 0.5 or AutoFish.mode == "Safe" and 3 or 1.5
        
        if not AutoFish.fishing then
            -- Cast line
            if tick() - AutoFish.lastCastTime >= castDelay then
                if castLine() then
                    AutoFish.fishing = true
                    AutoFish.lastCastTime = tick()
                    print("🎣 Line cast successfully")
                end
            end
        else
            -- Check for bite
            if checkForBite() then
                task.wait(0.5) -- Small delay before reeling
                if reelIn() then
                    AutoFish.catchCount = AutoFish.catchCount + 1
                    Stats.totalCatches = Stats.totalCatches + 1
                    print("🐟 Fish caught! Total: " .. Stats.totalCatches)
                    Notify("AutoFish", "🐟 Fish caught! Total: " .. Stats.totalCatches)
                end
                AutoFish.fishing = false
                task.wait(2) -- Wait before next cast
            elseif tick() - AutoFish.lastCastTime > 30 then
                -- Timeout - recast
                print("⏰ Fishing timeout, recasting...")
                AutoFish.fishing = false
            end
        end
        
        -- Auto-sell every 50 catches
        if AutoFish.autoSell and Stats.totalCatches > 0 and Stats.totalCatches % 50 == 0 then
            autoSellFish()
        end
    end
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFishUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main panel
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 400, 0, 450)
mainPanel.Position = UDim2.new(0.5, -200, 0.5, -225)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainPanel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 120, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainPanel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.Text = "🎣 AutoFish - Fisch Game"
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

-- Content area
local contentArea = Instance.new("ScrollingFrame")
contentArea.Size = UDim2.new(1, -20, 1, -50)
contentArea.Position = UDim2.new(0, 10, 0, 45)
contentArea.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
contentArea.BorderSizePixel = 0
contentArea.CanvasSize = UDim2.new(0, 0, 0, 800)
contentArea.ScrollBarThickness = 6
contentArea.Parent = mainPanel

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = contentArea

-- Control Section
local controlSection = Instance.new("Frame")
controlSection.Size = UDim2.new(1, -20, 0, 100)
controlSection.Position = UDim2.new(0, 10, 0, 10)
controlSection.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
controlSection.BorderSizePixel = 0
controlSection.Parent = contentArea
Instance.new("UICorner", controlSection)

local controlTitle = Instance.new("TextLabel")
controlTitle.Size = UDim2.new(1, -10, 0, 25)
controlTitle.Position = UDim2.new(0, 5, 0, 5)
controlTitle.Text = "🎮 AutoFish Controls"
controlTitle.Font = Enum.Font.GothamBold
controlTitle.TextSize = 14
controlTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
controlTitle.BackgroundTransparency = 1
controlTitle.TextXAlignment = Enum.TextXAlignment.Left
controlTitle.Parent = controlSection

-- Start/Stop button
local startStopBtn = Instance.new("TextButton")
startStopBtn.Size = UDim2.new(0, 120, 0, 35)
startStopBtn.Position = UDim2.new(0, 10, 0, 35)
startStopBtn.Text = "🚀 Start AutoFish"
startStopBtn.Font = Enum.Font.GothamSemibold
startStopBtn.TextSize = 12
startStopBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
startStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startStopBtn.Parent = controlSection
Instance.new("UICorner", startStopBtn)

-- Mode selector
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0, 80, 0, 35)
modeLabel.Position = UDim2.new(0, 140, 0, 35)
modeLabel.Text = "Mode:"
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextSize = 12
modeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
modeLabel.BackgroundTransparency = 1
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = controlSection

local modeDropdown = Instance.new("TextButton")
modeDropdown.Size = UDim2.new(0, 100, 0, 35)
modeDropdown.Position = UDim2.new(0, 180, 0, 35)
modeDropdown.Text = "Normal ▼"
modeDropdown.Font = Enum.Font.GothamSemibold
modeDropdown.TextSize = 11
modeDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
modeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
modeDropdown.Parent = controlSection
Instance.new("UICorner", modeDropdown)

-- Status section
local statusSection = Instance.new("Frame")
statusSection.Size = UDim2.new(1, -20, 0, 120)
statusSection.Position = UDim2.new(0, 10, 0, 120)
statusSection.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
statusSection.BorderSizePixel = 0
statusSection.Parent = contentArea
Instance.new("UICorner", statusSection)

local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, -10, 0, 25)
statusTitle.Position = UDim2.new(0, 5, 0, 5)
statusTitle.Text = "📊 Status & Statistics"
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextSize = 14
statusTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
statusTitle.BackgroundTransparency = 1
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusSection

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -20, 0, 85)
statusText.Position = UDim2.new(0, 10, 0, 30)
statusText.Text = "Status: Ready\nTotal Catches: 0\nSession Time: 00:00:00\nCurrent Spot: None\nFish/Hour: 0"
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 11
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.BackgroundTransparency = 1
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextYAlignment = Enum.TextYAlignment.Top
statusText.Parent = statusSection

-- Fishing spots section
local spotsSection = Instance.new("Frame")
spotsSection.Size = UDim2.new(1, -20, 0, 200)
spotsSection.Position = UDim2.new(0, 10, 0, 250)
spotsSection.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
spotsSection.BorderSizePixel = 0
spotsSection.Parent = contentArea
Instance.new("UICorner", spotsSection)

local spotsTitle = Instance.new("TextLabel")
spotsTitle.Size = UDim2.new(1, -10, 0, 25)
spotsTitle.Position = UDim2.new(0, 5, 0, 5)
spotsTitle.Text = "🗺️ Fishing Spots"
spotsTitle.Font = Enum.Font.GothamBold
spotsTitle.TextSize = 14
spotsTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
spotsTitle.BackgroundTransparency = 1
spotsTitle.TextXAlignment = Enum.TextXAlignment.Left
spotsTitle.Parent = spotsSection

-- Create spot buttons
local spotButtons = {}
local yOffset = 35
for spotName, spotData in pairs(FishingSpots) do
    local spotBtn = Instance.new("TextButton")
    spotBtn.Size = UDim2.new(0, 170, 0, 25)
    spotBtn.Position = UDim2.new(0, 10, 0, yOffset)
    spotBtn.Text = "🎣 " .. spotName .. " (" .. spotData.biome .. ")"
    spotBtn.Font = Enum.Font.GothamSemibold
    spotBtn.TextSize = 10
    spotBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
    spotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    spotBtn.Parent = spotsSection
    Instance.new("UICorner", spotBtn)
    
    spotBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            walkToSpot(spotName)
        end)
    end)
    
    spotButtons[spotName] = spotBtn
    yOffset = yOffset + 30
end

-- Settings section
local settingsSection = Instance.new("Frame")
settingsSection.Size = UDim2.new(1, -20, 0, 100)
settingsSection.Position = UDim2.new(0, 10, 0, 460)
settingsSection.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
settingsSection.BorderSizePixel = 0
settingsSection.Parent = contentArea
Instance.new("UICorner", settingsSection)

local settingsTitle = Instance.new("TextLabel")
settingsTitle.Size = UDim2.new(1, -10, 0, 25)
settingsTitle.Position = UDim2.new(0, 5, 0, 5)
settingsTitle.Text = "⚙️ Settings"
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 14
settingsTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
settingsTitle.BackgroundTransparency = 1
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.Parent = settingsSection

-- Auto-sell toggle
local autoSellToggle = Instance.new("TextButton")
autoSellToggle.Size = UDim2.new(0, 150, 0, 25)
autoSellToggle.Position = UDim2.new(0, 10, 0, 35)
autoSellToggle.Text = "💰 Auto-Sell: OFF"
autoSellToggle.Font = Enum.Font.GothamSemibold
autoSellToggle.TextSize = 11
autoSellToggle.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
autoSellToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoSellToggle.Parent = settingsSection
Instance.new("UICorner", autoSellToggle)

-- Anti-AFK toggle
local antiAFKToggle = Instance.new("TextButton")
antiAFKToggle.Size = UDim2.new(0, 150, 0, 25)
antiAFKToggle.Position = UDim2.new(0, 170, 0, 35)
antiAFKToggle.Text = "🤖 Anti-AFK: ON"
antiAFKToggle.Font = Enum.Font.GothamSemibold
antiAFKToggle.TextSize = 11
antiAFKToggle.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
antiAFKToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
antiAFKToggle.Parent = settingsSection
Instance.new("UICorner", antiAFKToggle)

-- Emergency controls
local emergencySection = Instance.new("Frame")
emergencySection.Size = UDim2.new(1, -20, 0, 80)
emergencySection.Position = UDim2.new(0, 10, 0, 570)
emergencySection.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
emergencySection.BorderSizePixel = 0
emergencySection.Parent = contentArea
Instance.new("UICorner", emergencySection)

local emergencyTitle = Instance.new("TextLabel")
emergencyTitle.Size = UDim2.new(1, -10, 0, 25)
emergencyTitle.Position = UDim2.new(0, 5, 0, 5)
emergencyTitle.Text = "🚨 Emergency Controls"
emergencyTitle.Font = Enum.Font.GothamBold
emergencyTitle.TextSize = 14
emergencyTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
emergencyTitle.BackgroundTransparency = 1
emergencyTitle.TextXAlignment = Enum.TextXAlignment.Left
emergencyTitle.Parent = emergencySection

local emergencyStopBtn = Instance.new("TextButton")
emergencyStopBtn.Size = UDim2.new(0, 100, 0, 30)
emergencyStopBtn.Position = UDim2.new(0, 10, 0, 35)
emergencyStopBtn.Text = "🛑 STOP ALL"
emergencyStopBtn.Font = Enum.Font.GothamBold
emergencyStopBtn.TextSize = 12
emergencyStopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
emergencyStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emergencyStopBtn.Parent = emergencySection
Instance.new("UICorner", emergencyStopBtn)

local resetCharBtn = Instance.new("TextButton")
resetCharBtn.Size = UDim2.new(0, 100, 0, 30)
resetCharBtn.Position = UDim2.new(0, 120, 0, 35)
resetCharBtn.Text = "💀 Reset Char"
resetCharBtn.Font = Enum.Font.GothamSemibold
resetCharBtn.TextSize = 11
resetCharBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
resetCharBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetCharBtn.Parent = emergencySection
Instance.new("UICorner", resetCharBtn)

local equipRodBtn = Instance.new("TextButton")
equipRodBtn.Size = UDim2.new(0, 100, 0, 30)
equipRodBtn.Position = UDim2.new(0, 230, 0, 35)
equipRodBtn.Text = "🎣 Equip Rod"
equipRodBtn.Font = Enum.Font.GothamSemibold
equipRodBtn.TextSize = 11
equipRodBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 180)
equipRodBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
equipRodBtn.Parent = emergencySection
Instance.new("UICorner", equipRodBtn)

-- Button handlers
startStopBtn.MouseButton1Click:Connect(function()
    AutoFish.enabled = not AutoFish.enabled
    
    if AutoFish.enabled then
        startStopBtn.Text = "⏹️ Stop AutoFish"
        startStopBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        Notify("AutoFish", "🚀 AutoFish started!")
        
        -- Start fishing loop
        task.spawn(fishingLoop)
    else
        startStopBtn.Text = "🚀 Start AutoFish"
        startStopBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
        Notify("AutoFish", "⏹️ AutoFish stopped!")
    end
end)

-- Mode dropdown
local modes = {"Normal", "Fast", "Safe"}
local currentModeIndex = 1

modeDropdown.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex % #modes + 1
    AutoFish.mode = modes[currentModeIndex]
    modeDropdown.Text = AutoFish.mode .. " ▼"
    
    local modeDescriptions = {
        Normal = "Balanced speed and safety",
        Fast = "Faster casting, higher detection risk",
        Safe = "Slower casting, lower detection risk"
    }
    
    Notify("AutoFish", "Mode: " .. AutoFish.mode .. " - " .. modeDescriptions[AutoFish.mode])
end)

-- Toggle buttons
autoSellToggle.MouseButton1Click:Connect(function()
    AutoFish.autoSell = not AutoFish.autoSell
    autoSellToggle.Text = "💰 Auto-Sell: " .. (AutoFish.autoSell and "ON" or "OFF")
    autoSellToggle.BackgroundColor3 = AutoFish.autoSell and Color3.fromRGB(70, 170, 90) or Color3.fromRGB(100, 100, 100)
end)

antiAFKToggle.MouseButton1Click:Connect(function()
    AutoFish.antiAFK = not AutoFish.antiAFK
    antiAFKToggle.Text = "🤖 Anti-AFK: " .. (AutoFish.antiAFK and "ON" or "OFF")
    antiAFKToggle.BackgroundColor3 = AutoFish.antiAFK and Color3.fromRGB(70, 170, 90) or Color3.fromRGB(100, 100, 100)
end)

-- Emergency buttons
emergencyStopBtn.MouseButton1Click:Connect(function()
    AutoFish.enabled = false
    AutoFish.fishing = false
    startStopBtn.Text = "🚀 Start AutoFish"
    startStopBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
    Notify("Emergency", "🛑 All fishing stopped!")
end)

resetCharBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
        Notify("Emergency", "💀 Character reset")
    end
end)

equipRodBtn.MouseButton1Click:Connect(function()
    if equipRod() then
        Notify("AutoFish", "🎣 Fishing rod equipped!")
    else
        Notify("AutoFish", "❌ No fishing rod found!")
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    AutoFish.enabled = false
    screenGui:Destroy()
    print("🎣 AutoFish UI closed")
end)

-- Update status
local function updateStatus()
    if not screenGui or not screenGui.Parent then return end
    
    local sessionTime = tick() - AutoFish.sessionStartTime
    local hours = math.floor(sessionTime / 3600)
    local minutes = math.floor((sessionTime % 3600) / 60)
    local seconds = math.floor(sessionTime % 60)
    
    local fishPerHour = sessionTime > 0 and math.floor((Stats.totalCatches / sessionTime) * 3600) or 0
    
    local status = AutoFish.enabled and "🟢 Running" or "🔴 Stopped"
    
    statusText.Text = string.format(
        "Status: %s\nTotal Catches: %d\nSession Time: %02d:%02d:%02d\nCurrent Spot: %s\nFish/Hour: %d",
        status,
        Stats.totalCatches,
        hours, minutes, seconds,
        AutoFish.currentSpot,
        fishPerHour
    )
end

-- Start status updates
RunService.Heartbeat:Connect(updateStatus)

-- Make draggable
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

-- Initial setup
print("🎣 AutoFish for Fisch loaded!")
print("📋 Features:")
print("  • Automatic rod casting and reeling")
print("  • Multiple fishing spots")
print("  • Auto-sell functionality")
print("  • Anti-AFK system")
print("  • Real-time statistics")
print("  • Multiple fishing modes")
Notify("AutoFish", "🎣 AutoFish UI loaded! Ready to fish!")
