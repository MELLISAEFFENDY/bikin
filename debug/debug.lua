-- ═══════════════════════════════════════════════════════════════
-- 🔬 FISH IT DEBUG ANALYZER - BASED ON LOG DATA
-- ═══════════════════════════════════════════════════════════════
-- Purpose: Debug auto fishing mechanism based on actual game data
-- Focus: Target specific remotes identified in log analysis
-- Method: Hook confirmed fishing remotes with precise targeting
-- ═══════════════════════════════════════════════════════════════

print("🔬 Fish It Debug Analyzer - Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- 📊 FISHING REMOTES IDENTIFIED FROM LOG DEBUG
-- ═══════════════════════════════════════════════════════════════

local FishingRemotes = {
    -- Auto Fishing System
    "UpdateAutoFishingState",       -- RF/UpdateAutoFishingState
    "ChargeFishingRod",            -- RF/ChargeFishingRod  
    "CancelFishingInputs",         -- RF/CancelFishingInputs
    "RequestFishingMinigameStarted", -- RF/RequestFishingMinigameStarted
    "UpdateFishingRadar",          -- RF/UpdateFishingRadar
    
    -- Fishing Events
    "PlayFishingEffect",           -- RE/PlayFishingEffect
    "BaitSpawned",                 -- RE/BaitSpawned
    "FishCaught",                  -- RE/FishCaught
    "FishingStopped",              -- RE/FishingStopped
    "FishingCompleted",            -- RE/FishingCompleted
    "FishingMinigameChanged",      -- RE/FishingMinigameChanged
    "ObtainedNewFishNotification", -- RE/ObtainedNewFishNotification
    
    -- Equipment/Gear
    "EquipRodSkin",                -- RE/EquipRodSkin
    "UnequipRodSkin",              -- RE/UnequipRodSkin
    "EquipBait",                   -- RE/EquipBait
    
    -- Power/Charge Related
    "UpdateChargeState"            -- RE/UpdateChargeState
}

local DebugAnalyzer = {
    foundRemotes = {},
    hooksActive = false,
    debugData = {},
    callCount = 0
}

-- ═══════════════════════════════════════════════════════════════
-- 🎯 PRECISE REMOTE FINDER BASED ON LOG DATA
-- ═══════════════════════════════════════════════════════════════

local function FindExactFishingRemotes()
    print("🎯 Searching for exact fishing remotes from log data...")
    
    local found = {}
    local searchPaths = {
        "ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RF",
        "ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RE"
    }
    
    for _, remoteName in pairs(FishingRemotes) do
        for _, basePath in pairs(searchPaths) do
            local fullPath = basePath .. "/" .. remoteName
            local success, remote = pcall(function()
                return game:GetService("ReplicatedStorage"):FindFirstChild("Packages")
                    and game:GetService("ReplicatedStorage").Packages:FindFirstChild("_Index")
                    and game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_net@0.2.0")
                    and game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"]:FindFirstChild("net")
                    and game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net:FindFirstChild("RF")
                    and game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net.RF:FindFirstChild(remoteName)
                    or game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net:FindFirstChild("RE")
                    and game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net.RE:FindFirstChild(remoteName)
            end)
            
            if success and remote then
                table.insert(found, {
                    remote = remote,
                    name = remoteName,
                    path = fullPath,
                    type = remote.ClassName
                })
                print("✅ Found:", remoteName, "(" .. remote.ClassName .. ")")
            end
        end
    end
    
    -- Also scan by descendants method as backup
    for _, descendant in pairs(ReplicatedStorage:GetDescendants()) do
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            local name = descendant.Name
            for _, targetName in pairs(FishingRemotes) do
                if name == targetName then
                    -- Check if already found
                    local alreadyFound = false
                    for _, existing in pairs(found) do
                        if existing.remote == descendant then
                            alreadyFound = true
                            break
                        end
                    end
                    
                    if not alreadyFound then
                        table.insert(found, {
                            remote = descendant,
                            name = name,
                            path = descendant:GetFullName(),
                            type = descendant.ClassName
                        })
                        print("✅ Found (backup scan):", name, "(" .. descendant.ClassName .. ")")
                    end
                end
            end
        end
    end
    
    DebugAnalyzer.foundRemotes = found
    print("📊 Total fishing remotes found:", #found)
    return #found > 0
end

-- ═══════════════════════════════════════════════════════════════
-- 🔍 DEBUG HOOK SYSTEM - MONITOR ALL CALLS
-- ═══════════════════════════════════════════════════════════════

local function ApplyDebugHooks()
    if #DebugAnalyzer.foundRemotes == 0 then
        print("❌ No remotes found to debug")
        return false
    end
    
    print("🔧 Applying debug hooks to", #DebugAnalyzer.foundRemotes, "remotes...")
    local hooksApplied = 0
    
    for _, remoteData in pairs(DebugAnalyzer.foundRemotes) do
        local remote = remoteData.remote
        local remoteName = remoteData.name
        
        local success, err = pcall(function()
            if remote:IsA("RemoteFunction") then
                local original = remote.InvokeServer
                remote.InvokeServer = function(self, ...)
                    local args = {...}
                    DebugAnalyzer.callCount = DebugAnalyzer.callCount + 1
                    
                    -- Log the call
                    print("🎣 [RF]", remoteName, "called with args:", #args)
                    for i, arg in ipairs(args) do
                        print("   Arg[" .. i .. "]:", tostring(arg), "(" .. type(arg) .. ")")
                    end
                    
                    -- Store debug data
                    table.insert(DebugAnalyzer.debugData, {
                        timestamp = tick(),
                        remote = remoteName,
                        type = "RemoteFunction",
                        args = args,
                        argCount = #args
                    })
                    
                    -- Call original and capture result
                    local result = original(self, unpack(args))
                    print("   Result:", tostring(result))
                    
                    return result
                end
                hooksApplied = hooksApplied + 1
                
            elseif remote:IsA("RemoteEvent") then
                local original = remote.FireServer
                remote.FireServer = function(self, ...)
                    local args = {...}
                    DebugAnalyzer.callCount = DebugAnalyzer.callCount + 1
                    
                    -- Log the call
                    print("🎣 [RE]", remoteName, "fired with args:", #args)
                    for i, arg in ipairs(args) do
                        print("   Arg[" .. i .. "]:", tostring(arg), "(" .. type(arg) .. ")")
                    end
                    
                    -- Store debug data
                    table.insert(DebugAnalyzer.debugData, {
                        timestamp = tick(),
                        remote = remoteName,
                        type = "RemoteEvent",
                        args = args,
                        argCount = #args
                    })
                    
                    return original(self, unpack(args))
                end
                hooksApplied = hooksApplied + 1
            end
        end)
        
        if not success then
            print("⚠️ Failed to hook:", remoteName, "Error:", err)
        else
            print("✅ Hooked:", remoteName)
        end
    end
    
    DebugAnalyzer.hooksActive = true
    print("✅ Applied", hooksApplied, "debug hooks")
    return hooksApplied > 0
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 DEBUG UI WITH REAL-TIME MONITORING
-- ═══════════════════════════════════════════════════════════════

local function CreateDebugUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishItDebugAnalyzer"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function()
        screenGui.Parent = game.CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main debug window
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 500)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.Text = "🔬 Fish It Debug Analyzer"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Parent = titleBar
    
    -- Status display
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 30)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.Text = "🔍 Ready to debug Fish It auto fishing..."
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 10
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextWrapped = true
    statusLabel.Parent = frame
    
    -- Debug button
    local debugBtn = Instance.new("TextButton")
    debugBtn.Size = UDim2.new(1, -10, 0, 35)
    debugBtn.Position = UDim2.new(0, 5, 0, 70)
    debugBtn.Text = "🚀 START DEBUG MONITORING"
    debugBtn.Font = Enum.Font.GothamBold
    debugBtn.TextSize = 12
    debugBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    debugBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    debugBtn.BorderSizePixel = 0
    debugBtn.Parent = frame
    
    local debugCorner = Instance.new("UICorner")
    debugCorner.CornerRadius = UDim.new(0, 6)
    debugCorner.Parent = debugBtn
    
    -- Remote list display
    local remotesList = Instance.new("ScrollingFrame")
    remotesList.Size = UDim2.new(1, -10, 0, 180)
    remotesList.Position = UDim2.new(0, 5, 0, 110)
    remotesList.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    remotesList.BorderSizePixel = 0
    remotesList.ScrollBarThickness = 6
    remotesList.Parent = frame
    
    local remotesCorner = Instance.new("UICorner")
    remotesCorner.CornerRadius = UDim.new(0, 4)
    remotesCorner.Parent = remotesList
    
    local remotesLayout = Instance.new("UIListLayout")
    remotesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    remotesLayout.Padding = UDim.new(0, 2)
    remotesLayout.Parent = remotesList
    
    -- Debug log display
    local debugLog = Instance.new("ScrollingFrame")
    debugLog.Size = UDim2.new(1, -10, 0, 180)
    debugLog.Position = UDim2.new(0, 5, 0, 295)
    debugLog.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
    debugLog.BorderSizePixel = 0
    debugLog.ScrollBarThickness = 6
    debugLog.Parent = frame
    
    local logCorner = Instance.new("UICorner")
    logCorner.CornerRadius = UDim.new(0, 4)
    logCorner.Parent = debugLog
    
    local logLayout = Instance.new("UIListLayout")
    logLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logLayout.Padding = UDim.new(0, 1)
    logLayout.Parent = debugLog
    
    -- Stats display
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -10, 0, 20)
    statsLabel.Position = UDim2.new(0, 5, 0, 480)
    statsLabel.Text = "📊 Calls: 0 | Remotes: 0 | Status: Ready"
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 9
    statsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Parent = frame
    
    -- Button functionality
    debugBtn.MouseButton1Click:Connect(function()
        debugBtn.Text = "🔍 SCANNING..."
        statusLabel.Text = "🔍 Scanning for fishing remotes..."
        
        task.wait(0.5)
        
        if FindExactFishingRemotes() then
            statusLabel.Text = "✅ Found " .. #DebugAnalyzer.foundRemotes .. " fishing remotes"
            
            -- Update remotes list
            for i, remoteData in ipairs(DebugAnalyzer.foundRemotes) do
                local remoteLabel = Instance.new("TextLabel")
                remoteLabel.Size = UDim2.new(1, -5, 0, 20)
                remoteLabel.Text = string.format("[%d] %s (%s)", i, remoteData.name, remoteData.type)
                remoteLabel.Font = Enum.Font.Gotham
                remoteLabel.TextSize = 8
                remoteLabel.TextColor3 = Color3.fromRGB(100, 200, 100)
                remoteLabel.BackgroundTransparency = 1
                remoteLabel.TextXAlignment = Enum.TextXAlignment.Left
                remoteLabel.Parent = remotesList
            end
            
            task.wait(0.5)
            
            if ApplyDebugHooks() then
                debugBtn.Text = "✅ DEBUG MONITORING ACTIVE"
                debugBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                statusLabel.Text = "✅ Debug hooks active! Use AUTO fishing to see calls."
                debugBtn.Active = false
            else
                debugBtn.Text = "❌ DEBUG FAILED"
                debugBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
                statusLabel.Text = "❌ Failed to apply debug hooks"
            end
        else
            debugBtn.Text = "❌ NO REMOTES FOUND"
            debugBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
            statusLabel.Text = "❌ No fishing remotes found"
        end
    end)
    
    -- Real-time log updater
    local lastLogCount = 0
    task.spawn(function()
        while true do
            task.wait(0.5)
            
            -- Update stats
            statsLabel.Text = string.format("📊 Calls: %d | Remotes: %d | Status: %s", 
                DebugAnalyzer.callCount, 
                #DebugAnalyzer.foundRemotes,
                DebugAnalyzer.hooksActive and "Monitoring" or "Ready"
            )
            
            -- Update log if new entries
            if #DebugAnalyzer.debugData > lastLogCount then
                for i = lastLogCount + 1, #DebugAnalyzer.debugData do
                    local data = DebugAnalyzer.debugData[i]
                    local logEntry = Instance.new("TextLabel")
                    logEntry.Size = UDim2.new(1, -5, 0, 15)
                    logEntry.Text = string.format("[%.1f] %s: %d args", 
                        data.timestamp - DebugAnalyzer.debugData[1].timestamp, 
                        data.remote, 
                        data.argCount
                    )
                    logEntry.Font = Enum.Font.Gotham
                    logEntry.TextSize = 8
                    logEntry.TextColor3 = data.type == "RemoteFunction" and 
                        Color3.fromRGB(100, 150, 255) or Color3.fromRGB(255, 150, 100)
                    logEntry.BackgroundTransparency = 1
                    logEntry.TextXAlignment = Enum.TextXAlignment.Left
                    logEntry.Parent = debugLog
                    
                    -- Auto-scroll to bottom
                    debugLog.CanvasPosition = Vector2.new(0, debugLog.AbsoluteCanvasSize.Y)
                end
                lastLogCount = #DebugAnalyzer.debugData
            end
        end
    end)
    
    return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- 🚀 INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("🔬 Fish It Debug Analyzer - Initializing...")
    print("📊 Target remotes from log analysis:", #FishingRemotes)
    
    -- Create debug UI
    CreateDebugUI()
    
    print("✅ Debug Analyzer ready!")
    print("💡 Click 'START DEBUG MONITORING' to begin")
    print("🎣 Then use the AUTO fishing button to see remote calls")
end

-- Start the debug analyzer
Initialize()

-- ═══════════════════════════════════════════════════════════════
-- 📋 DEBUG USAGE GUIDE
-- ═══════════════════════════════════════════════════════════════
--[[
🔬 FISH IT DEBUG ANALYZER GUIDE:

🎯 PURPOSE:
- Monitor all fishing-related remote calls
- Understand how AUTO fishing works
- Identify the exact parameters used
- Debug fishing mechanism in real-time

📊 IDENTIFIED REMOTES FROM LOG:
✅ UpdateAutoFishingState - Controls AUTO fishing on/off
✅ ChargeFishingRod - Handles rod charging/power
✅ RequestFishingMinigameStarted - Starts minigame
✅ UpdateChargeState - Updates charge/power state
✅ FishingCompleted - Triggered when fishing completes
✅ FishCaught - Triggered when fish is caught

💡 HOW TO USE:
1. Load script in Fish It game
2. Click "START DEBUG MONITORING"
3. Use the native AUTO fishing button
4. Watch the debug log for remote calls
5. Analyze the parameters being sent

🔍 WHAT TO LOOK FOR:
- ChargeFishingRod parameters (power values)
- RequestFishingMinigameStarted coordinates
- UpdateAutoFishingState true/false values
- Timing between different remote calls

📝 DEBUG OUTPUT:
- Real-time remote call logging
- Parameter values and types
- Call timestamps and sequence
- Success/failure indicators
]]

print("🔬 Fish It Debug Analyzer loaded!")
print("🎯 Ready to analyze AUTO fishing mechanism")
print("📊 Based on actual game log data analysis")
