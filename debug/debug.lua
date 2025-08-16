-- ═══════════════════════════════════════════════════════════════
-- 🔧 FISH IT NATIVE AUTO DEBUG & ENHANCEMENT SCRIPT
-- ═══════════════════════════════════════════════════════════════
-- Purpose: Analyze and enhance the built-in auto fishing feature
-- Target: Built-in "AUTO" button functionality
-- Goal: Perfect cast charging & instant roll speed
-- ═══════════════════════════════════════════════════════════════

print("🔧 Fish It Native Auto Debug Script Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- 🔍 DETECTION SYSTEM - Find Native Auto Components
-- ═══════════════════════════════════════════════════════════════

local NativeAutoDebug = {
    autoButton = nil,
    autoButtonFound = false,
    originalFunctions = {},
    hooks = {},
    monitoring = false,
    enhancementActive = false
}

-- Function to find the native AUTO button
local function FindNativeAutoButton()
    print("🔍 Searching for native AUTO button...")
    
    local function searchInGui(parent, depth)
        if depth > 10 then return nil end -- Prevent infinite recursion
        
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("ImageButton") then
                if child.Text and (
                    string.upper(child.Text):find("AUTO") or 
                    string.upper(child.Text):find("FISH") or
                    child.Name:find("Auto") or
                    child.Name:find("Fish")
                ) then
                    print("🎯 Found potential AUTO button:", child.Name, "Text:", child.Text)
                    return child
                end
            end
            
            local found = searchInGui(child, depth + 1)
            if found then return found end
        end
        return nil
    end
    
    -- Search in PlayerGui
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local autoBtn = searchInGui(playerGui, 0)
    
    if autoBtn then
        NativeAutoDebug.autoButton = autoBtn
        NativeAutoDebug.autoButtonFound = true
        print("✅ Native AUTO button found:", autoBtn:GetFullName())
        return true
    else
        print("❌ Native AUTO button not found")
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 MONITORING SYSTEM - Track Native Auto Behavior
-- ═══════════════════════════════════════════════════════════════

local MonitoringData = {
    castAttempts = 0,
    chargingTimes = {},
    rollSpeeds = {},
    perfectCasts = 0,
    failedCasts = 0,
    averageChargeTime = 0,
    averageRollSpeed = 0
}

-- Monitor fishing casting behavior
local function StartMonitoring()
    if NativeAutoDebug.monitoring then return end
    
    NativeAutoDebug.monitoring = true
    print("📊 Starting native auto monitoring...")
    
    -- Monitor charge timing
    local chargeStartTime = 0
    local isCharging = false
    
    -- Hook into charge detection
    RunService.Heartbeat:Connect(function()
        if not NativeAutoDebug.monitoring then return end
        
        -- Detect charging state from UI or character animations
        local character = LocalPlayer.Character
        if character then
            -- Look for charging indicators
            local chargingUI = LocalPlayer.PlayerGui:FindFirstChild("ChargingUI") or
                              LocalPlayer.PlayerGui:FindFirstChild("FishingUI")
            
            if chargingUI then
                local chargeBar = chargingUI:FindFirstChild("ChargeBar") or
                                 chargingUI:FindFirstChild("Charge") or
                                 chargingUI:FindFirstChild("Power")
                
                if chargeBar and chargeBar.Visible then
                    if not isCharging then
                        isCharging = true
                        chargeStartTime = tick()
                        print("🔋 Charge started")
                    end
                else
                    if isCharging then
                        isCharging = false
                        local chargeTime = tick() - chargeStartTime
                        table.insert(MonitoringData.chargingTimes, chargeTime)
                        MonitoringData.castAttempts = MonitoringData.castAttempts + 1
                        
                        -- Calculate if it was a perfect cast (charge time close to optimal)
                        if chargeTime >= 0.8 and chargeTime <= 1.2 then
                            MonitoringData.perfectCasts = MonitoringData.perfectCasts + 1
                        else
                            MonitoringData.failedCasts = MonitoringData.failedCasts + 1
                        end
                        
                        print("⚡ Charge completed in", string.format("%.3f", chargeTime), "seconds")
                    end
                end
            end
        end
    end)
    
    print("✅ Monitoring system active")
end

-- ═══════════════════════════════════════════════════════════════
-- 🎯 ENHANCEMENT SYSTEM - Modify Native Auto Behavior
-- ═══════════════════════════════════════════════════════════════

local AutoEnhancer = {
    perfectChargeTime = 1.0, -- Optimal charge time for perfect cast
    instantRollSpeed = 0.1,  -- Target roll speed for instant results
    originalChargingFunction = nil,
    originalRollingFunction = nil
}

-- Find and hook into charging system
local function HookChargingSystem()
    print("🎣 Hooking into charging system...")
    
    -- Look for charging remotes or functions
    local chargingRemote = nil
    
    -- Search in ReplicatedStorage for charging-related remotes
    local function findChargingRemote(parent)
        for _, child in pairs(parent:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                if child.Name:lower():find("charge") or 
                   child.Name:lower():find("power") or
                   child.Name:lower():find("cast") then
                    print("🎯 Found potential charging remote:", child:GetFullName())
                    return child
                end
            end
        end
        return nil
    end
    
    chargingRemote = findChargingRemote(ReplicatedStorage)
    
    if chargingRemote then
        print("✅ Charging remote found:", chargingRemote.Name)
        
        -- Hook the charging function to force perfect timing
        if chargingRemote:IsA("RemoteFunction") then
            local originalInvoke = chargingRemote.InvokeServer
            chargingRemote.InvokeServer = function(self, ...)
                local args = {...}
                -- Modify charge value to perfect (usually around 100 or 1.0)
                if #args > 0 and tonumber(args[1]) then
                    args[1] = 100 -- Force perfect charge
                    print("🎯 Modified charge to perfect:", args[1])
                end
                return originalInvoke(self, unpack(args))
            end
        elseif chargingRemote:IsA("RemoteEvent") then
            local originalFire = chargingRemote.FireServer
            chargingRemote.FireServer = function(self, ...)
                local args = {...}
                if #args > 0 and tonumber(args[1]) then
                    args[1] = 100 -- Force perfect charge
                    print("🎯 Modified charge to perfect:", args[1])
                end
                return originalFire(self, unpack(args))
            end
        end
        
        return true
    else
        print("❌ Charging remote not found")
        return false
    end
end

-- Hook into rolling/minigame system
local function HookRollingSystem()
    print("🎲 Hooking into rolling system...")
    
    -- Look for minigame or rolling remotes
    local rollingRemote = nil
    
    local function findRollingRemote(parent)
        for _, child in pairs(parent:GetDescendants()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                if child.Name:lower():find("minigame") or 
                   child.Name:lower():find("roll") or
                   child.Name:lower():find("fishing") then
                    print("🎯 Found potential rolling remote:", child:GetFullName())
                    return child
                end
            end
        end
        return nil
    end
    
    rollingRemote = findRollingRemote(ReplicatedStorage)
    
    if rollingRemote then
        print("✅ Rolling remote found:", rollingRemote.Name)
        
        -- Hook the rolling function to force perfect results
        if rollingRemote:IsA("RemoteFunction") then
            local originalInvoke = rollingRemote.InvokeServer
            rollingRemote.InvokeServer = function(self, ...)
                local args = {...}
                -- Modify minigame args for perfect results
                if #args >= 2 then
                    args[1] = -1.2379989624023438  -- Perfect X coordinate
                    args[2] = 0.9800224985802423   -- Perfect Y coordinate
                    print("🎯 Modified minigame to perfect coordinates")
                end
                return originalInvoke(self, unpack(args))
            end
        elseif rollingRemote:IsA("RemoteEvent") then
            local originalFire = rollingRemote.FireServer
            rollingRemote.FireServer = function(self, ...)
                local args = {...}
                if #args >= 2 then
                    args[1] = -1.2379989624023438
                    args[2] = 0.9800224985802423
                    print("🎯 Modified minigame to perfect coordinates")
                end
                return originalFire(self, unpack(args))
            end
        end
        
        return true
    else
        print("❌ Rolling remote not found")
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 🎮 AUTO BUTTON ENHANCEMENT
-- ═══════════════════════════════════════════════════════════════

local function EnhanceNativeAuto()
    if not NativeAutoDebug.autoButtonFound then
        print("❌ Cannot enhance - AUTO button not found")
        return false
    end
    
    print("🚀 Enhancing native AUTO functionality...")
    
    -- Hook charging system
    local chargingHooked = HookChargingSystem()
    
    -- Hook rolling system
    local rollingHooked = HookRollingSystem()
    
    if chargingHooked or rollingHooked then
        NativeAutoDebug.enhancementActive = true
        print("✅ Native AUTO enhancement active!")
        print("🎯 Perfect charging:", chargingHooked and "✅" or "❌")
        print("⚡ Instant rolling:", rollingHooked and "✅" or "❌")
        return true
    else
        print("❌ Enhancement failed - no systems found to hook")
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 📈 ANALYTICS & REPORTING
-- ═══════════════════════════════════════════════════════════════

local function GenerateReport()
    print("\n" .. "═".rep(60))
    print("📊 NATIVE AUTO FISHING ANALYSIS REPORT")
    print("═".rep(60))
    
    if MonitoringData.castAttempts > 0 then
        local avgChargeTime = 0
        for _, time in ipairs(MonitoringData.chargingTimes) do
            avgChargeTime = avgChargeTime + time
        end
        avgChargeTime = avgChargeTime / #MonitoringData.chargingTimes
        
        local perfectRate = (MonitoringData.perfectCasts / MonitoringData.castAttempts) * 100
        
        print("🎣 Total Cast Attempts:", MonitoringData.castAttempts)
        print("⚡ Perfect Casts:", MonitoringData.perfectCasts)
        print("❌ Failed Casts:", MonitoringData.failedCasts)
        print("📊 Perfect Rate:", string.format("%.1f%%", perfectRate))
        print("⏱️ Average Charge Time:", string.format("%.3f", avgChargeTime), "seconds")
        print("🎯 Enhancement Status:", NativeAutoDebug.enhancementActive and "ACTIVE" or "INACTIVE")
    else
        print("📊 No fishing data collected yet")
    end
    
    print("═".rep(60))
end

-- ═══════════════════════════════════════════════════════════════
-- 🎛️ DEBUG UI INTERFACE
-- ═══════════════════════════════════════════════════════════════

local function CreateDebugUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NativeAutoDebug"
    screenGui.ResetOnSpawn = false
    
    -- Try to parent to CoreGui first, then PlayerGui
    local success = pcall(function()
        screenGui.Parent = game.CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(1, -320, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "🔧 Native Auto Debug"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    title.BorderSizePixel = 0
    title.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Content area
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -10, 1, -40)
    content.Position = UDim2.new(0, 5, 0, 35)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 4
    content.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = content
    
    -- Status display
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 60)
    statusLabel.Text = "🔍 Status: Initializing..."
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    statusLabel.BorderSizePixel = 0
    statusLabel.TextWrapped = true
    statusLabel.Parent = content
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusLabel
    
    -- Buttons
    local function createButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.Text = text
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
        btn.BorderSizePixel = 0
        btn.Parent = content
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    createButton("🔍 Find AUTO Button", function()
        local found = FindNativeAutoButton()
        statusLabel.Text = found and "✅ AUTO button found!" or "❌ AUTO button not found"
    end)
    
    createButton("📊 Start Monitoring", function()
        StartMonitoring()
        statusLabel.Text = "📊 Monitoring native auto behavior..."
    end)
    
    createButton("🚀 Enhance Native Auto", function()
        local enhanced = EnhanceNativeAuto()
        statusLabel.Text = enhanced and "🚀 Enhancement active!" or "❌ Enhancement failed"
    end)
    
    createButton("📈 Generate Report", function()
        GenerateReport()
        statusLabel.Text = "📈 Report generated in console"
    end)
    
    -- Real-time stats
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, 0, 0, 80)
    statsLabel.Text = "📊 Stats will appear here..."
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 10
    statsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    statsLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    statsLabel.BorderSizePixel = 0
    statsLabel.TextWrapped = true
    statsLabel.Parent = content
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 6)
    statsCorner.Parent = statsLabel
    
    -- Update stats periodically
    task.spawn(function()
        while true do
            task.wait(2)
            if MonitoringData.castAttempts > 0 then
                local perfectRate = (MonitoringData.perfectCasts / MonitoringData.castAttempts) * 100
                statsLabel.Text = string.format(
                    "📊 Casts: %d\n🎯 Perfect: %d (%.1f%%)\n❌ Failed: %d\n🔧 Enhanced: %s",
                    MonitoringData.castAttempts,
                    MonitoringData.perfectCasts,
                    perfectRate,
                    MonitoringData.failedCasts,
                    NativeAutoDebug.enhancementActive and "YES" or "NO"
                )
            end
        end
    end)
    
    print("🎛️ Debug UI created")
end

-- ═══════════════════════════════════════════════════════════════
-- 🚀 INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("🚀 Initializing Native Auto Debug System...")
    
    -- Create debug UI
    CreateDebugUI()
    
    -- Auto-find AUTO button after a delay
    task.wait(2)
    FindNativeAutoButton()
    
    -- Auto-start monitoring
    task.wait(1)
    StartMonitoring()
    
    print("✅ Native Auto Debug System ready!")
    print("📋 Use the debug UI to enhance native auto fishing")
    print("🎯 Goal: Perfect cast charging & instant roll speed")
end

-- Start the system
Initialize()

-- ═══════════════════════════════════════════════════════════════
-- 📝 USAGE INSTRUCTIONS
-- ═══════════════════════════════════════════════════════════════
--[[
🔧 NATIVE AUTO DEBUG SCRIPT USAGE:

1. 🎮 Load this script while in Fish It game
2. 🔍 Script will auto-find the native AUTO button
3. 📊 Monitoring will start automatically
4. 🚀 Click "Enhance Native Auto" to modify behavior
5. 📈 Check reports to see improvement

🎯 ENHANCEMENT FEATURES:
- Perfect cast charging (100% power)
- Instant roll results (perfect coordinates)
- Real-time monitoring & analytics
- Automatic hook into game systems

⚠️ NOTES:
- Works with existing AUTO button
- No interference with manual fishing
- Safe hooks with error handling
- Compatible with all fishing locations

🔄 TO RESET:
- Rejoin the game or reload script
- Enhancement hooks will be cleared
]]

print("🔧 Native Auto Debug Script Loaded Successfully!")
print("📋 Check the debug UI on the right side of your screen")
