-- autofish_fishit_optimized.lua
-- Optimized AutoFish script for Fish It game using discovered RemoteEvents
-- Based on actual remote names found: PlayFishingEffect, FishCaught, CancelFishingInputs, etc.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- AutoFish System for Fish It (Optimized)
local AutoFish = {
    enabled = false,
    mode = "Normal", -- "Normal", "Fast", "Turbo"
    fishing = false,
    charging = false,
    clicking = false,
    lastCastTime = 0,
    catchCount = 0,
    sessionStartTime = tick(),
    autoSell = true,
    antiAFK = true,
    lastAFKTime = 0,
    clickSpeed = 20,
    fishingActive = false,
    lastFishCaught = 0
}

-- Statistics
local Stats = {
    totalCatches = 0,
    shinyFish = 0,
    legendaryFish = 0,
    totalSold = 0,
    sessionTime = 0,
    fishPerHour = 0,
    remoteCalls = 0
}

-- Fish It Remote Handler (Optimized)
local RemoteHandler = {
    -- Discovered remote events from console
    fishingRemotes = {
        playEffect = nil,       -- RE/PlayFishingEffect
        fishCaught = nil,       -- RE/FishCaught
        cancelInputs = nil,     -- RF/CancelFishingInputs
        fishingStopped = nil,   -- RE/FishingStopped
        fishingCompleted = nil, -- RE/FishingCompleted
        minigameChanged = nil,  -- RE/FishingMinigameChanged
        newFishNotif = nil     -- RE/ObtainedNewFishNotification
    },
    sellRemotes = {},
    useRemotes = true,
    remoteMethod = "remote" -- Prioritize remote since we found them
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
    print(string.format("[AutoFish Optimized] %s: %s", title, message))
end

-- Optimized remote scanning based on discovered names
local function scanForOptimizedRemotes()
    print("🔍 Scanning for Fish It RemoteEvents (Optimized)...")
    
    if not ReplicatedStorage then return end
    
    -- Scan for specific remote names we discovered
    local remoteNames = {
        "PlayFishingEffect",
        "FishCaught", 
        "CancelFishingInputs",
        "FishingStopped",
        "FishingCompleted",
        "FishingMinigameChanged",
        "ObtainedNewFishNotification"
    }
    
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local name = remote.Name
            
            -- Map specific remotes
            if name == "PlayFishingEffect" then
                RemoteHandler.fishingRemotes.playEffect = remote
                print("🎣 Found PlayFishingEffect remote")
            elseif name == "FishCaught" then
                RemoteHandler.fishingRemotes.fishCaught = remote
                print("🐟 Found FishCaught remote")
            elseif name == "CancelFishingInputs" then
                RemoteHandler.fishingRemotes.cancelInputs = remote
                print("❌ Found CancelFishingInputs remote")
            elseif name == "FishingStopped" then
                RemoteHandler.fishingRemotes.fishingStopped = remote
                print("⏹️ Found FishingStopped remote")
            elseif name == "FishingCompleted" then
                RemoteHandler.fishingRemotes.fishingCompleted = remote
                print("✅ Found FishingCompleted remote")
            elseif name == "FishingMinigameChanged" then
                RemoteHandler.fishingRemotes.minigameChanged = remote
                print("🎮 Found FishingMinigameChanged remote")
            elseif name == "ObtainedNewFishNotification" then
                RemoteHandler.fishingRemotes.newFishNotif = remote
                print("🆕 Found ObtainedNewFishNotification remote")
            end
            
            -- Still check for selling remotes
            if name:lower():find("sell") or name:lower():find("shop") or name:lower():find("merchant") then
                table.insert(RemoteHandler.sellRemotes, remote)
                print("💰 Found selling remote: " .. name)
            end
        end
    end
    
    -- Count found remotes
    local foundCount = 0
    for _, remote in pairs(RemoteHandler.fishingRemotes) do
        if remote then foundCount = foundCount + 1 end
    end
    
    print("📊 Optimized remote scan complete:")
    print("  • Fishing remotes found: " .. foundCount .. "/7")
    print("  • Selling remotes found: " .. #RemoteHandler.sellRemotes)
end

-- Listen for fish catch notifications
local function setupFishCatchListener()
    -- Listen to FishCaught remote
    if RemoteHandler.fishingRemotes.fishCaught then
        RemoteHandler.fishingRemotes.fishCaught.OnClientEvent:Connect(function(...)
            AutoFish.catchCount = AutoFish.catchCount + 1
            Stats.totalCatches = Stats.totalCatches + 1
            AutoFish.lastFishCaught = tick()
            
            print("🐟 Fish caught via remote! Total: " .. Stats.totalCatches)
            Notify("AutoFish", "🐟 Fish caught! Total: " .. Stats.totalCatches)
            
            -- Auto-sell check
            if AutoFish.autoSell and Stats.totalCatches > 0 and Stats.totalCatches % 25 == 0 then
                task.spawn(autoSellFish)
            end
        end)
        print("👂 Listening for FishCaught events")
    end
    
    -- Listen to ObtainedNewFishNotification
    if RemoteHandler.fishingRemotes.newFishNotif then
        RemoteHandler.fishingRemotes.newFishNotif.OnClientEvent:Connect(function(fishData)
            if fishData and fishData.rarity then
                if fishData.rarity == "Shiny" then
                    Stats.shinyFish = Stats.shinyFish + 1
                    Notify("Shiny Fish!", "✨ Caught a shiny fish!")
                elseif fishData.rarity == "Legendary" then
                    Stats.legendaryFish = Stats.legendaryFish + 1
                    Notify("Legendary Fish!", "👑 Caught a legendary fish!")
                end
            end
        end)
        print("👂 Listening for NewFishNotification events")
    end
end

-- Optimized fish clicking using discovered remotes
local function performOptimizedClick()
    Stats.remoteCalls = Stats.remoteCalls + 1
    
    -- Use PlayFishingEffect for clicking
    if RemoteHandler.fishingRemotes.playEffect then
        pcall(function()
            RemoteHandler.fishingRemotes.playEffect:FireServer()
        end)
        return true
    end
    
    -- Fallback to VirtualInput
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.01)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    return true
end

-- Enhanced fast clicking using remote optimization
local function optimizedFastClick()
    if AutoFish.clicking then return end
    
    AutoFish.clicking = true
    print("🖱️ Optimized fast clicking activated!")
    
    local clicksPerSecond = AutoFish.mode == "Turbo" and 30 or AutoFish.mode == "Fast" and 25 or 20
    local clickDelay = 1 / clicksPerSecond
    
    local startTime = tick()
    while AutoFish.clicking and (tick() - startTime) < 10 do
        -- Stop if we caught a fish recently
        if tick() - AutoFish.lastFishCaught < 1 then
            break
        end
        
        performOptimizedClick()
        task.wait(clickDelay)
    end
    
    AutoFish.clicking = false
    print("✋ Optimized fast clicking stopped")
end

-- Auto-sell using remotes
local function autoSellFish()
    if not AutoFish.autoSell then return end
    
    print("💰 Looking for fish merchant...")
    
    -- Try remote-based selling first
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
    
    Stats.totalSold = Stats.totalSold + 1
    return true
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
                    LocalPlayer.Character.Humanoid:MoveTo(pos + Vector3.new(2, 0, 0))
                    task.wait(1)
                    LocalPlayer.Character.Humanoid:MoveTo(pos)
                    print("🚶 Anti-AFK: Movement")
                end
            end
        }
        
        local randomAction = actions[math.random(1, #actions)]
        randomAction()
        
        AutoFish.lastAFKTime = currentTime
    end
end

-- Simple fishing state detection
local function isInFishingMode()
    -- Check if any fishing UI is visible
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    for _, gui in pairs(playerGui:GetChildren()) do
        if gui.Name:lower():find("fish") and gui.Visible then
            return true
        end
    end
    
    return false
end

-- Main optimized fishing loop
local function optimizedFishingLoop()
    while AutoFish.enabled do
        task.wait(0.3) -- Faster loop for better responsiveness
        
        if not LocalPlayer.Character then
            task.wait(2)
            continue
        end
        
        -- Anti-AFK
        performAntiAFK()
        
        -- Check fishing state
        AutoFish.fishingActive = isInFishingMode()
        
        if AutoFish.fishingActive then
            -- Start fast clicking if not already clicking
            if not AutoFish.clicking then
                task.spawn(optimizedFastClick)
            end
        else
            -- Try to start fishing
            if tick() - AutoFish.lastCastTime >= 2 then
                performOptimizedClick()
                AutoFish.lastCastTime = tick()
                print("🎣 Attempting to start fishing...")
            end
        end
        
        -- Stop clicking if we caught fish recently
        if AutoFish.clicking and (tick() - AutoFish.lastFishCaught < 2) then
            AutoFish.clicking = false
            task.wait(3) -- Wait before next fishing attempt
        end
    end
end

-- Create optimized GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFishOptimizedUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main panel (compact design)
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 380, 0, 420)
mainPanel.Position = UDim2.new(0.5, -190, 0.5, -210)
mainPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainPanel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainPanel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Text = "🎣 AutoFish Fish It (Optimized)"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16
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
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -20, 1, -50)
contentArea.Position = UDim2.new(0, 10, 0, 45)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainPanel

-- Control section
local controlSection = Instance.new("Frame")
controlSection.Size = UDim2.new(1, 0, 0, 80)
controlSection.Position = UDim2.new(0, 0, 0, 10)
controlSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
controlSection.BorderSizePixel = 0
controlSection.Parent = contentArea
Instance.new("UICorner", controlSection)

-- Start/Stop button
local startStopBtn = Instance.new("TextButton")
startStopBtn.Size = UDim2.new(0, 160, 0, 35)
startStopBtn.Position = UDim2.new(0, 10, 0, 10)
startStopBtn.Text = "🚀 Start AutoFish"
startStopBtn.Font = Enum.Font.GothamBold
startStopBtn.TextSize = 12
startStopBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
startStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startStopBtn.Parent = controlSection
Instance.new("UICorner", startStopBtn)

-- Mode selector
local modeDropdown = Instance.new("TextButton")
modeDropdown.Size = UDim2.new(0, 120, 0, 35)
modeDropdown.Position = UDim2.new(0, 180, 0, 10)
modeDropdown.Text = "Normal ▼"
modeDropdown.Font = Enum.Font.GothamSemibold
modeDropdown.TextSize = 11
modeDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
modeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
modeDropdown.Parent = controlSection
Instance.new("UICorner", modeDropdown)

-- Toggle buttons
local autoSellToggle = Instance.new("TextButton")
autoSellToggle.Size = UDim2.new(0, 140, 0, 25)
autoSellToggle.Position = UDim2.new(0, 10, 0, 50)
autoSellToggle.Text = "💰 Auto-Sell: ON"
autoSellToggle.Font = Enum.Font.GothamSemibold
autoSellToggle.TextSize = 10
autoSellToggle.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
autoSellToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
autoSellToggle.Parent = controlSection
Instance.new("UICorner", autoSellToggle)

local antiAFKToggle = Instance.new("TextButton")
antiAFKToggle.Size = UDim2.new(0, 140, 0, 25)
antiAFKToggle.Position = UDim2.new(0, 160, 0, 50)
antiAFKToggle.Text = "🤖 Anti-AFK: ON"
antiAFKToggle.Font = Enum.Font.GothamSemibold
antiAFKToggle.TextSize = 10
antiAFKToggle.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
antiAFKToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
antiAFKToggle.Parent = controlSection
Instance.new("UICorner", antiAFKToggle)

-- Status section
local statusSection = Instance.new("Frame")
statusSection.Size = UDim2.new(1, 0, 0, 120)
statusSection.Position = UDim2.new(0, 0, 0, 100)
statusSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
statusSection.BorderSizePixel = 0
statusSection.Parent = contentArea
Instance.new("UICorner", statusSection)

local statusTitle = Instance.new("TextLabel")
statusTitle.Size = UDim2.new(1, -10, 0, 20)
statusTitle.Position = UDim2.new(0, 5, 0, 5)
statusTitle.Text = "📊 Status & Statistics"
statusTitle.Font = Enum.Font.GothamBold
statusTitle.TextSize = 12
statusTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
statusTitle.BackgroundTransparency = 1
statusTitle.TextXAlignment = Enum.TextXAlignment.Left
statusTitle.Parent = statusSection

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -20, 0, 90)
statusText.Position = UDim2.new(0, 10, 0, 25)
statusText.Text = "Status: Ready\nTotal Catches: 0\nShiny Fish: 0\nSession Time: 00:00:00\nRemote Calls: 0\nFish/Hour: 0"
statusText.Font = Enum.Font.Gotham
statusText.TextSize = 10
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.BackgroundTransparency = 1
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextYAlignment = Enum.TextYAlignment.Top
statusText.Parent = statusSection

-- Emergency controls
local emergencySection = Instance.new("Frame")
emergencySection.Size = UDim2.new(1, 0, 0, 70)
emergencySection.Position = UDim2.new(0, 0, 0, 230)
emergencySection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
emergencySection.BorderSizePixel = 0
emergencySection.Parent = contentArea
Instance.new("UICorner", emergencySection)

local emergencyTitle = Instance.new("TextLabel")
emergencyTitle.Size = UDim2.new(1, -10, 0, 20)
emergencyTitle.Position = UDim2.new(0, 5, 0, 5)
emergencyTitle.Text = "🚨 Emergency Controls"
emergencyTitle.Font = Enum.Font.GothamBold
emergencyTitle.TextSize = 12
emergencyTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
emergencyTitle.BackgroundTransparency = 1
emergencyTitle.TextXAlignment = Enum.TextXAlignment.Left
emergencyTitle.Parent = emergencySection

local emergencyStopBtn = Instance.new("TextButton")
emergencyStopBtn.Size = UDim2.new(0, 100, 0, 30)
emergencyStopBtn.Position = UDim2.new(0, 10, 0, 30)
emergencyStopBtn.Text = "🛑 STOP ALL"
emergencyStopBtn.Font = Enum.Font.GothamBold
emergencyStopBtn.TextSize = 10
emergencyStopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
emergencyStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
emergencyStopBtn.Parent = emergencySection
Instance.new("UICorner", emergencyStopBtn)

local sellFishBtn = Instance.new("TextButton")
sellFishBtn.Size = UDim2.new(0, 100, 0, 30)
sellFishBtn.Position = UDim2.new(0, 120, 0, 30)
sellFishBtn.Text = "💰 Sell Fish"
sellFishBtn.Font = Enum.Font.GothamSemibold
sellFishBtn.TextSize = 10
sellFishBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
sellFishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellFishBtn.Parent = emergencySection
Instance.new("UICorner", sellFishBtn)

local addCatchBtn = Instance.new("TextButton")
addCatchBtn.Size = UDim2.new(0, 100, 0, 30)
addCatchBtn.Position = UDim2.new(0, 230, 0, 30)
addCatchBtn.Text = "➕ Add Catch"
addCatchBtn.Font = Enum.Font.GothamSemibold
addCatchBtn.TextSize = 10
addCatchBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
addCatchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
addCatchBtn.Parent = emergencySection
Instance.new("UICorner", addCatchBtn)

-- Remote info section
local remoteSection = Instance.new("Frame")
remoteSection.Size = UDim2.new(1, 0, 0, 60)
remoteSection.Position = UDim2.new(0, 0, 0, 310)
remoteSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
remoteSection.BorderSizePixel = 0
remoteSection.Parent = contentArea
Instance.new("UICorner", remoteSection)

local remoteTitle = Instance.new("TextLabel")
remoteTitle.Size = UDim2.new(1, -10, 0, 20)
remoteTitle.Position = UDim2.new(0, 5, 0, 5)
remoteTitle.Text = "🔧 Remote Information"
remoteTitle.Font = Enum.Font.GothamBold
remoteTitle.TextSize = 12
remoteTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
remoteTitle.BackgroundTransparency = 1
remoteTitle.TextXAlignment = Enum.TextXAlignment.Left
remoteTitle.Parent = remoteSection

local remoteInfoText = Instance.new("TextLabel")
remoteInfoText.Size = UDim2.new(1, -20, 0, 30)
remoteInfoText.Position = UDim2.new(0, 10, 0, 25)
remoteInfoText.Text = "Scanning for remotes..."
remoteInfoText.Font = Enum.Font.Gotham
remoteInfoText.TextSize = 10
remoteInfoText.TextColor3 = Color3.fromRGB(200, 200, 200)
remoteInfoText.BackgroundTransparency = 1
remoteInfoText.TextXAlignment = Enum.TextXAlignment.Left
remoteInfoText.TextYAlignment = Enum.TextYAlignment.Top
remoteInfoText.Parent = remoteSection

-- Button handlers
startStopBtn.MouseButton1Click:Connect(function()
    AutoFish.enabled = not AutoFish.enabled
    
    if AutoFish.enabled then
        startStopBtn.Text = "⏹️ Stop AutoFish"
        startStopBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        Notify("AutoFish", "🚀 Optimized AutoFish started!")
        
        -- Start optimized fishing loop
        task.spawn(optimizedFishingLoop)
    else
        startStopBtn.Text = "🚀 Start AutoFish"
        startStopBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
        AutoFish.clicking = false
        Notify("AutoFish", "⏹️ AutoFish stopped!")
    end
end)

-- Mode dropdown
local modes = {"Normal", "Fast", "Turbo"}
local currentModeIndex = 1

modeDropdown.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex % #modes + 1
    AutoFish.mode = modes[currentModeIndex]
    modeDropdown.Text = AutoFish.mode .. " ▼"
    
    AutoFish.clickSpeed = AutoFish.mode == "Turbo" and 30 or AutoFish.mode == "Fast" and 25 or 20
    
    Notify("AutoFish", "Mode: " .. AutoFish.mode .. " - " .. AutoFish.clickSpeed .. " CPS")
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
    AutoFish.clicking = false
    startStopBtn.Text = "🚀 Start AutoFish"
    startStopBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
    Notify("Emergency", "🛑 All activities stopped!")
end)

sellFishBtn.MouseButton1Click:Connect(function()
    task.spawn(autoSellFish)
end)

addCatchBtn.MouseButton1Click:Connect(function()
    AutoFish.catchCount = AutoFish.catchCount + 1
    Stats.totalCatches = Stats.totalCatches + 1
    Notify("Manual Count", "➕ Catch added! Total: " .. Stats.totalCatches)
    
    if AutoFish.autoSell and Stats.totalCatches > 0 and Stats.totalCatches % 25 == 0 then
        task.spawn(autoSellFish)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    AutoFish.enabled = false
    screenGui:Destroy()
    print("🎣 AutoFish Optimized UI closed")
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
    if AutoFish.clicking then status = status .. " 🖱️ Clicking" end
    
    statusText.Text = string.format(
        "Status: %s\nTotal Catches: %d\nShiny Fish: %d\nSession Time: %02d:%02d:%02d\nRemote Calls: %d\nFish/Hour: %d",
        status,
        Stats.totalCatches,
        Stats.shinyFish,
        hours, minutes, seconds,
        Stats.remoteCalls,
        fishPerHour
    )
    
    -- Update remote info
    local foundCount = 0
    for _, remote in pairs(RemoteHandler.fishingRemotes) do
        if remote then foundCount = foundCount + 1 end
    end
    
    remoteInfoText.Text = string.format("Found %d/7 fishing remotes\nUsing optimized remote calls", foundCount)
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
    elseif input.KeyCode == Enum.KeyCode.F4 then
        addCatchBtn:Fire()
    end
end)

-- Initial setup
print("🎣 AutoFish Fish It Optimized loaded!")
print("📋 Optimized Features:")
print("  • Direct remote event usage")
print("  • Fish catch event listener")
print("  • Optimized click performance")
print("  • Compact UI design")
print("  • Real-time remote monitoring")
print("🎮 Controls: F1=Start/Stop, F3=Sell Fish, F4=Add Catch, F12=Emergency Stop")

-- Scan for remotes and setup listeners
task.spawn(function()
    task.wait(2)
    scanForOptimizedRemotes()
    setupFishCatchListener()
    
    local foundCount = 0
    for _, remote in pairs(RemoteHandler.fishingRemotes) do
        if remote then foundCount = foundCount + 1 end
    end
    
    if foundCount > 0 then
        Notify("AutoFish", "🔧 Found " .. foundCount .. "/7 remotes! Optimized mode ready.")
    else
        Notify("AutoFish", "⚠️ No specific remotes found, using fallback mode.")
    end
end)

Notify("AutoFish", "🎣 Optimized AutoFish for Fish It loaded!")
