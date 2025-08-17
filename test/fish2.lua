-- autofish_fishit.lua
-- Complete AutoFish script for Roblox "Fish It" game with UI interface
-- Optimized for Fish It's "click to charge up" and "click as fast as you can" mechanics

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- AutoFish System for Fish It
local AutoFish = {
    enabled = false,
    mode = "Normal", -- "Normal", "Fast", "Turbo"
    fishing = false,
    charging = false,
    clicking = false,
    lastCastTime = 0,
    catchCount = 0,
    sessionStartTime = tick(),
    currentIsland = "Stingray Shores",
    autoSell = true,
    antiAFK = true,
    lastAFKTime = 0,
    clickSpeed = 20, -- clicks per second
    chargeTime = 2, -- seconds to charge
    fishingActive = false
}

-- Statistics
local Stats = {
    totalCatches = 0,
    shinyFish = 0,
    legendaryFish = 0,
    totalSold = 0,
    sessionTime = 0,
    fishPerHour = 0,
    moneyEarned = 0
}

-- Fish It Game Detection Functions
local function getFishingUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    -- Look for fishing GUI elements
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui.Name:lower():find("fish") or gui.Name:lower():find("catch") or gui.Name:lower():find("click") then
            return gui
        end
    end
    
    return nil
end

-- Remote Detection and Integration
local RemoteHandler = {
    fishingRemotes = {},
    sellRemotes = {},
    useRemotes = true,
    remoteMethod = "hybrid" -- "ui", "remote", "hybrid"
}

-- Scan for Fish It RemoteEvents
local function scanForRemotes()
    print("🔍 Scanning for Fish It RemoteEvents...")
    
    -- Check ReplicatedStorage for remotes
    if ReplicatedStorage then
        for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                local name = remote.Name:lower()
                
                -- Fishing related remotes
                if name:find("fish") or name:find("cast") or name:find("reel") or name:find("catch") then
                    table.insert(RemoteHandler.fishingRemotes, remote)
                    print("🎣 Found fishing remote: " .. remote.Name)
                end
                
                -- Selling related remotes
                if name:find("sell") or name:find("shop") or name:find("merchant") or name:find("trade") then
                    table.insert(RemoteHandler.sellRemotes, remote)
                    print("💰 Found selling remote: " .. remote.Name)
                end
            end
        end
    end
    
    -- Check StarterGui for remotes
    local starterGui = game:GetService("StarterGui")
    for _, remote in pairs(starterGui:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local name = remote.Name:lower()
            if name:find("fish") or name:find("sell") then
                print("📡 Found GUI remote: " .. remote.Name)
            end
        end
    end
    
    print("📊 Remote scan complete:")
    print("  • Fishing remotes found: " .. #RemoteHandler.fishingRemotes)
    print("  • Selling remotes found: " .. #RemoteHandler.sellRemotes)
end

-- Try remote-based fishing action
local function tryRemoteFishing(action)
    if not RemoteHandler.useRemotes then return false end
    
    for _, remote in pairs(RemoteHandler.fishingRemotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(action)
                print("🎯 Fired remote: " .. remote.Name .. " with action: " .. action)
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(action)
                print("🎯 Invoked remote: " .. remote.Name .. " with action: " .. action)
            end
        end)
    end
    
    return #RemoteHandler.fishingRemotes > 0
end

-- Try remote-based selling
local function tryRemoteSelling()
    if not RemoteHandler.useRemotes then return false end
    
    for _, remote in pairs(RemoteHandler.sellRemotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer("sell_all")
                print("💰 Fired sell remote: " .. remote.Name)
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer("sell_all")
                print("💰 Invoked sell remote: " .. remote.Name)
            end
        end)
        task.wait(0.5)
    end
    
    return #RemoteHandler.sellRemotes > 0
end

-- Check if we're in fishing mode
local function isFishingActive()
    local fishingUI = getFishingUI()
    if not fishingUI then return false end
    
    -- Look for fishing indicators
    for _, element in pairs(fishingUI:GetDescendants()) do
        if element:IsA("TextLabel") then
            local text = element.Text:lower()
            if text:find("click") or text:find("charge") or text:find("cast") or text:find("reel") then
                return true
            end
        end
    end
    
    return false
end

-- Check if we need to charge up
local function needsCharging()
    local fishingUI = getFishingUI()
    if not fishingUI then return false end
    
    for _, element in pairs(fishingUI:GetDescendants()) do
        if element:IsA("TextLabel") then
            local text = element.Text:lower()
            if text:find("charge") or text:find("hold") or text:find("press") then
                return true
            end
        end
        if element:IsA("Frame") or element:IsA("GuiObject") then
            -- Look for charge bar or progress indicator
            if element.Name:lower():find("charge") or element.Name:lower():find("progress") then
                return true
            end
        end
    end
    
    return false
end

-- Check if we need to click fast
local function needsFastClicking()
    local fishingUI = getFishingUI()
    if not fishingUI then return false end
    
    for _, element in pairs(fishingUI:GetDescendants()) do
        if element:IsA("TextLabel") then
            local text = element.Text:lower()
            if text:find("click as fast") or text:find("click fast") or text:find("rapid") or text:find("mash") then
                return true
            end
        end
    end
    
    return false
end

-- Notification function
local function Notify(title, message, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 3
        })
    end)
    print(string.format("[AutoFish Fish It] %s: %s", title, message))
end

-- Perform mouse click with remote backup
local function performClick()
    -- Method 1: Try remote first if available
    if RemoteHandler.remoteMethod == "remote" or RemoteHandler.remoteMethod == "hybrid" then
        if tryRemoteFishing("click") then
            return true
        end
    end
    
    -- Method 2: Fallback to VirtualInput
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    return true
end

-- Enhanced charge fishing with remote support
local function chargeFishing()
    if AutoFish.charging then return end
    
    AutoFish.charging = true
    print("🔋 Charging fishing rod...")
    
    -- Method 1: Try remote-based charging
    if RemoteHandler.remoteMethod == "remote" or RemoteHandler.remoteMethod == "hybrid" then
        if tryRemoteFishing("charge_start") then
            local chargeTime = AutoFish.mode == "Fast" and 1.5 or AutoFish.mode == "Turbo" and 1 or 2
            task.wait(chargeTime)
            tryRemoteFishing("charge_end")
            AutoFish.charging = false
            print("⚡ Fishing rod charged via remote!")
            return
        end
    end
    
    -- Method 2: Fallback to mouse hold
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    
    local chargeTime = AutoFish.mode == "Fast" and 1.5 or AutoFish.mode == "Turbo" and 1 or 2
    task.wait(chargeTime)
    
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    
    AutoFish.charging = false
    print("⚡ Fishing rod charged via input!")
end

-- Enhanced fast clicking with remote support
local function fastClick()
    if AutoFish.clicking then return end
    
    AutoFish.clicking = true
    print("🖱️ Fast clicking activated!")
    
    -- Method 1: Try remote-based rapid clicking
    if RemoteHandler.remoteMethod == "remote" or RemoteHandler.remoteMethod == "hybrid" then
        local clicksPerSecond = AutoFish.mode == "Turbo" and 30 or AutoFish.mode == "Fast" and 25 or 20
        
        local startTime = tick()
        while AutoFish.clicking and (tick() - startTime) < 10 do
            if not needsFastClicking() then break end
            
            -- Try remote click first
            if not tryRemoteFishing("rapid_click") then
                -- Fallback to regular click
                performClick()
            end
            
            task.wait(1 / clicksPerSecond)
        end
    else
        -- Method 2: Regular fast clicking
        local clicksPerSecond = AutoFish.mode == "Turbo" and 30 or AutoFish.mode == "Fast" and 25 or 20
        local clickDelay = 1 / clicksPerSecond
        
        local startTime = tick()
        while AutoFish.clicking and (tick() - startTime) < 10 do
            if not needsFastClicking() then break end
            
            performClick()
            task.wait(clickDelay)
        end
    end
    
    AutoFish.clicking = false
    print("✋ Fast clicking stopped")
end

-- Enhanced auto-sell with remote support
local function autoSellFish()
    if not AutoFish.autoSell then return end
    
    print("💰 Looking for fish merchant...")
    
    -- Method 1: Try remote-based selling first
    if RemoteHandler.remoteMethod == "remote" or RemoteHandler.remoteMethod == "hybrid" then
        if tryRemoteSelling() then
            Stats.totalSold = Stats.totalSold + 1
            print("💰 Fish sold via remote!")
            return true
        end
    end
    
    -- Method 2: UI-based selling
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui.Name:lower():find("shop") or gui.Name:lower():find("sell") or gui.Name:lower():find("merchant") then
                -- Look for sell button
                for _, element in pairs(gui:GetDescendants()) do
                    if element:IsA("TextButton") and element.Text:lower():find("sell") then
                        element:Fire()
                        print("💰 Fish sold via UI!")
                        Stats.totalSold = Stats.totalSold + 1
                        return true
                    end
                end
            end
        end
    end
    
    -- Method 3: NPC-based selling
    for _, npc in pairs(workspace:GetDescendants()) do
        if npc.Name:lower():find("merchant") or npc.Name:lower():find("shop") then
            if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
                local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    -- Walk to merchant if far
                    local distance = (humanoidRootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                    if distance > 15 then
                        LocalPlayer.Character.Humanoid:MoveTo(npc.HumanoidRootPart.Position)
                        LocalPlayer.Character.Humanoid.MoveToFinished:Wait()
                    end
                    
                    -- Try to interact
                    local proximityPrompt = npc:FindFirstChildOfClass("ProximityPrompt", true)
                    if proximityPrompt then
                        fireproximityprompt(proximityPrompt)
                        task.wait(2)
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

-- Anti-AFK system
local function performAntiAFK()
    if not AutoFish.antiAFK then return end
    
    local currentTime = tick()
    if currentTime - AutoFish.lastAFKTime < 180 then return end -- Every 3 minutes
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local actions = {
            function() 
                LocalPlayer.Character.Humanoid.Jump = true 
                print("🦘 Anti-AFK: Jump")
            end,
            function() 
                local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local pos = rootPart.Position
                    LocalPlayer.Character.Humanoid:MoveTo(pos + Vector3.new(3, 0, 0))
                    task.wait(1)
                    LocalPlayer.Character.Humanoid:MoveTo(pos)
                    print("🚶 Anti-AFK: Movement")
                end
            end,
            function()
                local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local originalCFrame = rootPart.CFrame
                    rootPart.CFrame = originalCFrame * CFrame.Angles(0, math.rad(90), 0)
                    task.wait(0.5)
                    rootPart.CFrame = originalCFrame
                    print("👀 Anti-AFK: Look around")
                end
            end
        }
        
        local randomAction = actions[math.random(1, #actions)]
        randomAction()
        
        AutoFish.lastAFKTime = currentTime
    end
end

-- Detect fish catch (disabled to avoid false positives)
local function detectFishCatch()
    -- Fish catch detection disabled
    -- User will manually monitor catches or rely on auto-sell timing
    return false
end

-- Main fishing loop for Fish It
local function fishingLoop()
    while AutoFish.enabled do
        task.wait(0.5)
        
        if not LocalPlayer.Character then
            task.wait(2)
            continue
        end
        
        -- Anti-AFK
        performAntiAFK()
        
        -- Check if fishing UI is active
        AutoFish.fishingActive = isFishingActive()
        
        if AutoFish.fishingActive then
            -- Check what action is needed
            if needsCharging() and not AutoFish.charging then
                task.spawn(chargeFishing)
            elseif needsFastClicking() and not AutoFish.clicking then
                task.spawn(fastClick)
            end
        else
            -- Try to start fishing
            if tick() - AutoFish.lastCastTime >= 3 then
                -- Click to start fishing
                performClick()
                AutoFish.lastCastTime = tick()
                print("🎣 Attempting to start fishing...")
            end
        end
        
        -- Estimated catch tracking (no UI detection)
        -- Estimate catches based on successful fishing cycles
        if AutoFish.clicking and not needsFastClicking() then
            -- Fast clicking phase ended, likely caught something
            AutoFish.catchCount = AutoFish.catchCount + 1
            Stats.totalCatches = Stats.totalCatches + 1
            print("🐟 Estimated fish caught! Total: " .. Stats.totalCatches)
            Notify("AutoFish", "🐟 Estimated catch! Total: " .. Stats.totalCatches)
            
            -- Reset clicking state
            AutoFish.clicking = false
            
            -- Auto-sell every 25 catches
            if AutoFish.autoSell and Stats.totalCatches > 0 and Stats.totalCatches % 25 == 0 then
                task.spawn(autoSellFish)
            end
            
            -- Wait before next fishing attempt
            task.wait(2)
        end
    end
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFishFishItUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main panel
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 420, 0, 480)
mainPanel.Position = UDim2.new(0.5, -210, 0.5, -240)
mainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 15)
mainCorner.Parent = mainPanel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 150, 220)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainPanel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 15)
titleCorner.Parent = titleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -50, 1, 0)
titleText.Position = UDim2.new(0, 15, 0, 0)
titleText.Text = "🐟 AutoFish - Fish It Game"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 18
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.BackgroundTransparency = 1
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn)

-- Content area
local contentArea = Instance.new("ScrollingFrame")
contentArea.Size = UDim2.new(1, -20, 1, -55)
contentArea.Position = UDim2.new(0, 10, 0, 50)
contentArea.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
contentArea.BorderSizePixel = 0
contentArea.CanvasSize = UDim2.new(0, 0, 0, 800)
contentArea.ScrollBarThickness = 8
contentArea.Parent = mainPanel

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 10)
contentCorner.Parent = contentArea

-- Control Section
local controlSection = Instance.new("Frame")
controlSection.Size = UDim2.new(1, -20, 0, 110)
controlSection.Position = UDim2.new(0, 10, 0, 10)
controlSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
controlSection.BorderSizePixel = 0
controlSection.Parent = contentArea
Instance.new("UICorner", controlSection)

local controlTitle = Instance.new("TextLabel")
controlTitle.Size = UDim2.new(1, -10, 0, 25)
controlTitle.Position = UDim2.new(0, 5, 0, 5)
controlTitle.Text = "🎮 Fish It AutoFish Controls"
controlTitle.Font = Enum.Font.GothamBold
controlTitle.TextSize = 14
controlTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
controlTitle.BackgroundTransparency = 1
controlTitle.TextXAlignment = Enum.TextXAlignment.Left
controlTitle.Parent = controlSection

-- Start/Stop button
local startStopBtn = Instance.new("TextButton")
startStopBtn.Size = UDim2.new(0, 140, 0, 40)
startStopBtn.Position = UDim2.new(0, 10, 0, 35)
startStopBtn.Text = "🚀 Start AutoFish"
startStopBtn.Font = Enum.Font.GothamBold
startStopBtn.TextSize = 13
startStopBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
startStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startStopBtn.Parent = controlSection
Instance.new("UICorner", startStopBtn)

-- Mode selector
local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0, 60, 0, 40)
modeLabel.Position = UDim2.new(0, 160, 0, 35)
modeLabel.Text = "Mode:"
modeLabel.Font = Enum.Font.Gotham
modeLabel.TextSize = 12
modeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
modeLabel.BackgroundTransparency = 1
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = controlSection

local modeDropdown = Instance.new("TextButton")
modeDropdown.Size = UDim2.new(0, 120, 0, 40)
modeDropdown.Position = UDim2.new(0, 220, 0, 35)
modeDropdown.Text = "Normal ▼"
modeDropdown.Font = Enum.Font.GothamSemibold
modeDropdown.TextSize = 12
modeDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
modeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
modeDropdown.Parent = controlSection
Instance.new("UICorner", modeDropdown)

-- Info section
local infoSection = Instance.new("Frame")
infoSection.Size = UDim2.new(1, -20, 0, 80)
infoSection.Position = UDim2.new(0, 10, 0, 130)
infoSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
infoSection.BorderSizePixel = 0
infoSection.Parent = contentArea
Instance.new("UICorner", infoSection)

local infoTitle = Instance.new("TextLabel")
infoTitle.Size = UDim2.new(1, -10, 0, 25)
infoTitle.Position = UDim2.new(0, 5, 0, 5)
infoTitle.Text = "ℹ️ Fish It Game Info"
infoTitle.Font = Enum.Font.GothamBold
infoTitle.TextSize = 14
infoTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
infoTitle.BackgroundTransparency = 1
infoTitle.TextXAlignment = Enum.TextXAlignment.Left
infoTitle.Parent = infoSection

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -20, 0, 45)
infoText.Position = UDim2.new(0, 10, 0, 30)
infoText.Text = "🎣 How Fish It Works: Click to charge up, then click as fast as you can!\n⚡ Auto catch detection disabled - use manual counter or estimate mode."
infoText.Font = Enum.Font.Gotham
infoText.TextSize = 11
infoText.TextColor3 = Color3.fromRGB(180, 180, 180)
infoText.BackgroundTransparency = 1
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextWrapped = true
infoText.Parent = infoSection

-- Status section
local statusSection = Instance.new("Frame")
statusSection.Size = UDim2.new(1, -20, 0, 120)
statusSection.Position = UDim2.new(0, 10, 0, 220)
statusSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
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
statusText.Text = "Status: Ready\nTotal Catches: 0\nShiny Fish: 0\nSession Time: 00:00:00\nFish/Hour: 0\nTotal Sold: 0"
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 11
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.BackgroundTransparency = 1
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextYAlignment = Enum.TextYAlignment.Top
statusText.Parent = statusSection

-- Settings section
local settingsSection = Instance.new("Frame")
settingsSection.Size = UDim2.new(1, -20, 0, 120)
settingsSection.Position = UDim2.new(0, 10, 0, 350)
settingsSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
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
autoSellToggle.Size = UDim2.new(0, 160, 0, 30)
autoSellToggle.Position = UDim2.new(0, 10, 0, 35)
autoSellToggle.Text = "💰 Auto-Sell: ON"
autoSellToggle.Font = Enum.Font.GothamSemibold
autoSellToggle.TextSize = 12
autoSellToggle.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
autoSellToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoSellToggle.Parent = settingsSection
Instance.new("UICorner", autoSellToggle)

-- Anti-AFK toggle
local antiAFKToggle = Instance.new("TextButton")
antiAFKToggle.Size = UDim2.new(0, 160, 0, 30)
antiAFKToggle.Position = UDim2.new(0, 180, 0, 35)
antiAFKToggle.Text = "🤖 Anti-AFK: ON"
antiAFKToggle.Font = Enum.Font.GothamSemibold
antiAFKToggle.TextSize = 12
antiAFKToggle.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
antiAFKToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
antiAFKToggle.Parent = settingsSection
Instance.new("UICorner", antiAFKToggle)

-- Click speed setting
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 120, 0, 25)
speedLabel.Position = UDim2.new(0, 10, 0, 75)
speedLabel.Text = "Click Speed: 20 CPS"
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 11
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.BackgroundTransparency = 1
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = settingsSection

-- Remote method toggle
local remoteMethodToggle = Instance.new("TextButton")
remoteMethodToggle.Size = UDim2.new(0, 160, 0, 25)
remoteMethodToggle.Position = UDim2.new(0, 180, 0, 75)
remoteMethodToggle.Text = "🔧 Method: Hybrid"
remoteMethodToggle.Font = Enum.Font.GothamSemibold
remoteMethodToggle.TextSize = 11
remoteMethodToggle.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
remoteMethodToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
remoteMethodToggle.Parent = settingsSection
Instance.new("UICorner", remoteMethodToggle)

local speedSlider = Instance.new("Frame")
speedSlider.Size = UDim2.new(0, 120, 0, 6)
speedSlider.Position = UDim2.new(0, 10, 0, 95)
speedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
speedSlider.BorderSizePixel = 0
speedSlider.Parent = settingsSection
Instance.new("UICorner", speedSlider)

-- Emergency controls
local emergencySection = Instance.new("Frame")
emergencySection.Size = UDim2.new(1, -20, 0, 90)
emergencySection.Position = UDim2.new(0, 10, 0, 480)
emergencySection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
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
emergencyStopBtn.Size = UDim2.new(0, 110, 0, 35)
emergencyStopBtn.Position = UDim2.new(0, 10, 0, 40)
emergencyStopBtn.Text = "🛑 STOP ALL"
emergencyStopBtn.Font = Enum.Font.GothamBold
emergencyStopBtn.TextSize = 12
emergencyStopBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
emergencyStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emergencyStopBtn.Parent = emergencySection
Instance.new("UICorner", emergencyStopBtn)

local resetCharBtn = Instance.new("TextButton")
resetCharBtn.Size = UDim2.new(0, 110, 0, 35)
resetCharBtn.Position = UDim2.new(0, 130, 0, 40)
resetCharBtn.Text = "💀 Reset Char"
resetCharBtn.Font = Enum.Font.GothamSemibold
resetCharBtn.TextSize = 11
resetCharBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 60)
resetCharBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetCharBtn.Parent = emergencySection
Instance.new("UICorner", resetCharBtn)

local sellFishBtn = Instance.new("TextButton")
sellFishBtn.Size = UDim2.new(0, 110, 0, 35)
sellFishBtn.Position = UDim2.new(0, 250, 0, 40)
sellFishBtn.Text = "💰 Sell Fish"
sellFishBtn.Font = Enum.Font.GothamSemibold
sellFishBtn.TextSize = 11
sellFishBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
sellFishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellFishBtn.Parent = emergencySection
Instance.new("UICorner", sellFishBtn)

-- Manual catch counter section
local manualSection = Instance.new("Frame")
manualSection.Size = UDim2.new(1, -20, 0, 80)
manualSection.Position = UDim2.new(0, 10, 0, 580)
manualSection.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
manualSection.BorderSizePixel = 0
manualSection.Parent = contentArea
Instance.new("UICorner", manualSection)

local manualTitle = Instance.new("TextLabel")
manualTitle.Size = UDim2.new(1, -10, 0, 25)
manualTitle.Position = UDim2.new(0, 5, 0, 5)
manualTitle.Text = "📊 Manual Catch Counter"
manualTitle.Font = Enum.Font.GothamBold
manualTitle.TextSize = 14
manualTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
manualTitle.BackgroundTransparency = 1
manualTitle.TextXAlignment = Enum.TextXAlignment.Left
manualTitle.Parent = manualSection

local addCatchBtn = Instance.new("TextButton")
addCatchBtn.Size = UDim2.new(0, 100, 0, 30)
addCatchBtn.Position = UDim2.new(0, 10, 0, 35)
addCatchBtn.Text = "➕ Add Catch"
addCatchBtn.Font = Enum.Font.GothamSemibold
addCatchBtn.TextSize = 11
addCatchBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
addCatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addCatchBtn.Parent = manualSection
Instance.new("UICorner", addCatchBtn)

local removeCatchBtn = Instance.new("TextButton")
removeCatchBtn.Size = UDim2.new(0, 100, 0, 30)
removeCatchBtn.Position = UDim2.new(0, 120, 0, 35)
removeCatchBtn.Text = "➖ Remove"
removeCatchBtn.Font = Enum.Font.GothamSemibold
removeCatchBtn.TextSize = 11
removeCatchBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
removeCatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
removeCatchBtn.Parent = manualSection
Instance.new("UICorner", removeCatchBtn)

local resetCountBtn = Instance.new("TextButton")
resetCountBtn.Size = UDim2.new(0, 100, 0, 30)
resetCountBtn.Position = UDim2.new(0, 230, 0, 35)
resetCountBtn.Text = "🔄 Reset Count"
resetCountBtn.Font = Enum.Font.GothamSemibold
resetCountBtn.TextSize = 11
resetCountBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
resetCountBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetCountBtn.Parent = manualSection
Instance.new("UICorner", resetCountBtn)

-- Button handlers
startStopBtn.MouseButton1Click:Connect(function()
    AutoFish.enabled = not AutoFish.enabled
    
    if AutoFish.enabled then
        startStopBtn.Text = "⏹️ Stop AutoFish"
        startStopBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
        Notify("AutoFish", "🚀 AutoFish started for Fish It!")
        
        -- Start fishing loop
        task.spawn(fishingLoop)
    else
        startStopBtn.Text = "🚀 Start AutoFish"
        startStopBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
        AutoFish.clicking = false
        AutoFish.charging = false
        Notify("AutoFish", "⏹️ AutoFish stopped!")
    end
end)

-- Mode dropdown
local modes = {"Normal", "Fast", "Turbo"}
local modeDescriptions = {
    Normal = "Balanced charge time (2s) and click speed (20 CPS)",
    Fast = "Faster charge time (1.5s) and click speed (25 CPS)",
    Turbo = "Fastest charge time (1s) and click speed (30 CPS)"
}
local currentModeIndex = 1

modeDropdown.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex % #modes + 1
    AutoFish.mode = modes[currentModeIndex]
    modeDropdown.Text = AutoFish.mode .. " ▼"
    
    -- Update click speed based on mode
    AutoFish.clickSpeed = AutoFish.mode == "Turbo" and 30 or AutoFish.mode == "Fast" and 25 or 20
    speedLabel.Text = "Click Speed: " .. AutoFish.clickSpeed .. " CPS"
    
    Notify("AutoFish", "Mode: " .. AutoFish.mode .. " - " .. modeDescriptions[AutoFish.mode])
end)

-- Toggle buttons
autoSellToggle.MouseButton1Click:Connect(function()
    AutoFish.autoSell = not AutoFish.autoSell
    autoSellToggle.Text = "💰 Auto-Sell: " .. (AutoFish.autoSell and "ON" or "OFF")
    autoSellToggle.BackgroundColor3 = AutoFish.autoSell and Color3.fromRGB(80, 180, 100) or Color3.fromRGB(120, 120, 120)
end)

antiAFKToggle.MouseButton1Click:Connect(function()
    AutoFish.antiAFK = not AutoFish.antiAFK
    antiAFKToggle.Text = "🤖 Anti-AFK: " .. (AutoFish.antiAFK and "ON" or "OFF")
    antiAFKToggle.BackgroundColor3 = AutoFish.antiAFK and Color3.fromRGB(80, 180, 100) or Color3.fromRGB(120, 120, 120)
end)

-- Remote method toggle handler
remoteMethodToggle.MouseButton1Click:Connect(function()
    local methods = {"UI", "Remote", "Hybrid"}
    local currentIndex = 1
    
    for i, method in ipairs(methods) do
        if RemoteHandler.remoteMethod:lower() == method:lower() then
            currentIndex = i
            break
        end
    end
    
    currentIndex = currentIndex % #methods + 1
    RemoteHandler.remoteMethod = methods[currentIndex]:lower()
    remoteMethodToggle.Text = "🔧 Method: " .. methods[currentIndex]
    
    -- Update color based on method
    local colors = {
        UI = Color3.fromRGB(150, 100, 200),      -- Purple for UI only
        Remote = Color3.fromRGB(200, 100, 100),  -- Red for Remote only  
        Hybrid = Color3.fromRGB(100, 150, 200)   -- Blue for Hybrid
    }
    remoteMethodToggle.BackgroundColor3 = colors[methods[currentIndex]]
    
    local descriptions = {
        UI = "Uses only UI interaction and input simulation",
        Remote = "Uses only RemoteEvent/Function calls",
        Hybrid = "Tries Remote first, falls back to UI"
    }
    
    Notify("AutoFish", "Method: " .. methods[currentIndex] .. " - " .. descriptions[methods[currentIndex]])
end)

-- Emergency buttons
emergencyStopBtn.MouseButton1Click:Connect(function()
    AutoFish.enabled = false
    AutoFish.fishing = false
    AutoFish.clicking = false
    AutoFish.charging = false
    startStopBtn.Text = "🚀 Start AutoFish"
    startStopBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 100)
    Notify("Emergency", "🛑 All activities stopped!")
end)

resetCharBtn.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
        Notify("Emergency", "💀 Character reset")
    end
end)

sellFishBtn.MouseButton1Click:Connect(function()
    task.spawn(autoSellFish)
end)

-- Manual catch counter handlers
addCatchBtn.MouseButton1Click:Connect(function()
    AutoFish.catchCount = AutoFish.catchCount + 1
    Stats.totalCatches = Stats.totalCatches + 1
    print("➕ Manual catch added! Total: " .. Stats.totalCatches)
    Notify("Manual Count", "➕ Catch added! Total: " .. Stats.totalCatches)
    
    -- Auto-sell check
    if AutoFish.autoSell and Stats.totalCatches > 0 and Stats.totalCatches % 25 == 0 then
        task.spawn(autoSellFish)
    end
end)

removeCatchBtn.MouseButton1Click:Connect(function()
    if Stats.totalCatches > 0 then
        AutoFish.catchCount = AutoFish.catchCount - 1
        Stats.totalCatches = Stats.totalCatches - 1
        print("➖ Manual catch removed! Total: " .. Stats.totalCatches)
        Notify("Manual Count", "➖ Catch removed! Total: " .. Stats.totalCatches)
    end
end)

resetCountBtn.MouseButton1Click:Connect(function()
    AutoFish.catchCount = 0
    Stats.totalCatches = 0
    Stats.shinyFish = 0
    Stats.totalSold = 0
    Stats.legendaryFish = 0
    print("🔄 Catch counter reset!")
    Notify("Manual Count", "🔄 All counters reset!")
end)

closeBtn.MouseButton1Click:Connect(function()
    AutoFish.enabled = false
    screenGui:Destroy()
    print("🐟 AutoFish Fish It UI closed")
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
    if AutoFish.charging then status = status .. " ⚡ Charging"
    elseif AutoFish.clicking then status = status .. " 🖱️ Clicking"
    end
    
    statusText.Text = string.format(
        "Status: %s\nTotal Catches: %d\nShiny Fish: %d\nSession Time: %02d:%02d:%02d\nFish/Hour: %d\nTotal Sold: %d",
        status,
        Stats.totalCatches,
        Stats.shinyFish,
        hours, minutes, seconds,
        fishPerHour,
        Stats.totalSold
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

-- Keybind support
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        startStopBtn:Fire()
    elseif input.KeyCode == Enum.KeyCode.F12 then
        emergencyStopBtn:Fire()
    elseif input.KeyCode == Enum.KeyCode.F3 then
        sellFishBtn:Fire()
    end
end)

-- Initial setup and remote scanning
print("🐟 AutoFish for Fish It loaded!")
print("📋 Fish It Features:")
print("  • Automatic charge and fast click")
print("  • Optimized for Fish It's mechanics")
print("  • Three speed modes (Normal/Fast/Turbo)")
print("  • Remote + UI hybrid support")
print("  • Auto-sell functionality")
print("  • Anti-AFK system")
print("  • Real-time statistics")
print("🎮 Controls: F1=Start/Stop, F3=Sell Fish, F12=Emergency Stop")

-- Scan for remotes
task.spawn(function()
    task.wait(2) -- Wait for game to load
    scanForRemotes()
    
    if #RemoteHandler.fishingRemotes > 0 or #RemoteHandler.sellRemotes > 0 then
        Notify("AutoFish", "🔧 Found " .. (#RemoteHandler.fishingRemotes + #RemoteHandler.sellRemotes) .. " remotes! Using hybrid mode.")
    else
        Notify("AutoFish", "🎮 No remotes found, using UI mode.")
        RemoteHandler.remoteMethod = "ui"
        remoteMethodToggle.Text = "🔧 Method: UI"
        remoteMethodToggle.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
    end
end)

Notify("AutoFish", "🐟 AutoFish for Fish It loaded! Ready to fish!")
