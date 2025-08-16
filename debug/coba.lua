-- ═══════════════════════════════════════════════════════════════
-- 🔍 FISH IT AUTO FISHING ANALYSIS
-- ═══════════════════════════════════════════════════════════════
-- Purpose: Analyze how the built-in auto fishing works
-- Method: Hook and monitor all auto fishing calls
-- ═══════════════════════════════════════════════════════════════

print("🔍 Fish It Auto Fishing Analysis - Starting analysis...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local AutoFishAnalysis = {
    calls = {},
    patterns = {},
    timings = {},
    parameters = {},
    rodOrientations = {},
    isMonitoring = false
}

-- ═══════════════════════════════════════════════════════════════
-- 📊 CALL PATTERN ANALYZER
-- ═══════════════════════════════════════════════════════════════

local function AnalyzeCall(remoteName, args, callType)
    local timestamp = tick()
    local callData = {
        remote = remoteName,
        args = args,
        type = callType,
        time = timestamp,
        argCount = #args,
        argTypes = {}
    }
    
    -- Analyze argument types and values
    for i, arg in ipairs(args) do
        callData.argTypes[i] = type(arg)
        
        if type(arg) == "number" then
            -- Check if it's a power value (0-1 or 0-100)
            if arg >= 0 and arg <= 1 then
                print(string.format("🔋 POWER VALUE: %s arg[%d] = %.6f (normalized)", remoteName, i, arg))
            elseif arg >= 0 and arg <= 100 then
                print(string.format("🔋 POWER VALUE: %s arg[%d] = %.2f (percentage)", remoteName, i, arg))
            -- Check if it's coordinates (-1 to 1)
            elseif arg >= -1 and arg <= 1 then
                print(string.format("🎯 COORDINATE: %s arg[%d] = %.6f", remoteName, i, arg))
            else
                print(string.format("📊 NUMBER: %s arg[%d] = %s", remoteName, i, tostring(arg)))
            end
        else
            print(string.format("📝 %s: %s arg[%d] = %s", type(arg):upper(), remoteName, i, tostring(arg)))
        end
    end
    
    table.insert(AutoFishAnalysis.calls, callData)
    
    -- Pattern detection
    if remoteName:lower():find("charge") or remoteName:lower():find("rod") then
        print("⚡ CHARGING PHASE DETECTED")
        AutoFishAnalysis.patterns.charging = callData
    elseif remoteName:lower():find("mini") or remoteName:lower():find("game") then
        print("🎮 MINI-GAME PHASE DETECTED")
        AutoFishAnalysis.patterns.minigame = callData
    elseif remoteName:lower():find("finish") or remoteName:lower():find("complete") then
        print("🏁 COMPLETION PHASE DETECTED")
        AutoFishAnalysis.patterns.completion = callData
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 🎣 ROD ORIENTATION MONITOR
-- ═══════════════════════════════════════════════════════════════

local function MonitorRodOrientation()
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    if not isRod then return end
    
    -- Monitor Motor6D orientation
    local rightArm = character:FindFirstChild("Right Arm")
    if rightArm then
        local rightGrip = rightArm:FindFirstChild("RightGrip")
        if rightGrip and rightGrip:IsA("Motor6D") then
            local c0 = rightGrip.C0
            local c1 = rightGrip.C1
            
            -- Extract rotation angles
            local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = c0:GetComponents()
            local yaw = math.atan2(r10, r00)
            local pitch = math.asin(-r20)
            local roll = math.atan2(r21, r22)
            
            local orientationData = {
                time = tick(),
                c0 = c0,
                c1 = c1,
                yaw = math.deg(yaw),
                pitch = math.deg(pitch),
                roll = math.deg(roll)
            }
            
            table.insert(AutoFishAnalysis.rodOrientations, orientationData)
            
            -- Only print significant changes
            local lastOrientation = AutoFishAnalysis.rodOrientations[#AutoFishAnalysis.rodOrientations - 1]
            if not lastOrientation or 
               math.abs(orientationData.yaw - lastOrientation.yaw) > 5 or
               math.abs(orientationData.pitch - lastOrientation.pitch) > 5 then
                print(string.format("🔧 ROD ORIENTATION: Yaw=%.1f°, Pitch=%.1f°, Roll=%.1f°", 
                    orientationData.yaw, orientationData.pitch, orientationData.roll))
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 🔗 COMPREHENSIVE REMOTE HOOKING
-- ═══════════════════════════════════════════════════════════════

local function HookAllRemotes()
    print("🔗 Hooking ALL remotes to analyze auto fishing behavior...")
    
    local hooked = 0
    
    for _, descendant in pairs(ReplicatedStorage:GetDescendants()) do
        if descendant:IsA("RemoteFunction") then
            local remoteName = descendant.Name
            local originalInvoke = descendant.InvokeServer
            
            descendant.InvokeServer = function(self, ...)
                local args = {...}
                
                -- Log the call
                print(string.format("\n📞 RF CALL: %s", remoteName))
                print(string.format("🕐 Time: %.3f", tick()))
                AnalyzeCall(remoteName, args, "RemoteFunction")
                
                -- Call original
                return originalInvoke(self, unpack(args))
            end
            
            hooked = hooked + 1
            
        elseif descendant:IsA("RemoteEvent") then
            local remoteName = descendant.Name
            local originalFire = descendant.FireServer
            
            descendant.FireServer = function(self, ...)
                local args = {...}
                
                -- Log the call
                print(string.format("\n🔥 RE CALL: %s", remoteName))
                print(string.format("🕐 Time: %.3f", tick()))
                AnalyzeCall(remoteName, args, "RemoteEvent")
                
                -- Call original
                return originalFire(self, unpack(args))
            end
            
            hooked = hooked + 1
        end
    end
    
    print(string.format("✅ Hooked %d total remotes for analysis", hooked))
    return hooked > 0
end

-- ═══════════════════════════════════════════════════════════════
-- 📈 TIMING ANALYSIS
-- ═══════════════════════════════════════════════════════════════

local function AnalyzeTiming()
    if #AutoFishAnalysis.calls < 2 then return end
    
    print("\n📈 TIMING ANALYSIS:")
    print("═══════════════════════════════════════")
    
    for i = 2, #AutoFishAnalysis.calls do
        local current = AutoFishAnalysis.calls[i]
        local previous = AutoFishAnalysis.calls[i-1]
        local timeDiff = current.time - previous.time
        
        print(string.format("⏱️  %s → %s: %.3f seconds", 
            previous.remote, current.remote, timeDiff))
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 PATTERN SUMMARY
-- ═══════════════════════════════════════════════════════════════

local function ShowPatternSummary()
    print("\n📊 AUTO FISHING PATTERN SUMMARY:")
    print("═══════════════════════════════════════")
    
    if AutoFishAnalysis.patterns.charging then
        local data = AutoFishAnalysis.patterns.charging
        print("⚡ CHARGING PHASE:")
        print(string.format("   Remote: %s", data.remote))
        print(string.format("   Args: %d", data.argCount))
        for i, arg in ipairs(data.args) do
            print(string.format("   Arg[%d]: %s (%s)", i, tostring(arg), data.argTypes[i]))
        end
    end
    
    if AutoFishAnalysis.patterns.minigame then
        local data = AutoFishAnalysis.patterns.minigame
        print("\n🎮 MINI-GAME PHASE:")
        print(string.format("   Remote: %s", data.remote))
        print(string.format("   Args: %d", data.argCount))
        for i, arg in ipairs(data.args) do
            print(string.format("   Arg[%d]: %s (%s)", i, tostring(arg), data.argTypes[i]))
        end
    end
    
    if AutoFishAnalysis.patterns.completion then
        local data = AutoFishAnalysis.patterns.completion
        print("\n🏁 COMPLETION PHASE:")
        print(string.format("   Remote: %s", data.remote))
        print(string.format("   Args: %d", data.argCount))
        for i, arg in ipairs(data.args) do
            print(string.format("   Arg[%d]: %s (%s)", i, tostring(arg), data.argTypes[i]))
        end
    end
    
    print(string.format("\n📊 Total calls analyzed: %d", #AutoFishAnalysis.calls))
end

-- ═══════════════════════════════════════════════════════════════
-- 🎮 ANALYSIS UI
-- ═══════════════════════════════════════════════════════════════

local function CreateAnalysisUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFishAnalysis"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function()
        screenGui.Parent = game.CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0, 20, 0, 300)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "🔍 Auto Fishing Analyzer"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
    title.BorderSizePixel = 0
    title.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 1, -70)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.Text = "📊 Monitoring auto fishing calls...\n\n🎣 Use the built-in AUTO button\n📝 Check console (F9) for detailed analysis"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextWrapped = true
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Parent = frame
    
    -- Summary button
    local summaryBtn = Instance.new("TextButton")
    summaryBtn.Size = UDim2.new(1, -10, 0, 30)
    summaryBtn.Position = UDim2.new(0, 5, 1, -35)
    summaryBtn.Text = "📊 Show Pattern Summary"
    summaryBtn.Font = Enum.Font.GothamBold
    summaryBtn.TextSize = 11
    summaryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    summaryBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    summaryBtn.BorderSizePixel = 0
    summaryBtn.Parent = frame
    
    local summaryCorner = Instance.new("UICorner")
    summaryCorner.CornerRadius = UDim.new(0, 6)
    summaryCorner.Parent = summaryBtn
    
    summaryBtn.MouseButton1Click:Connect(function()
        ShowPatternSummary()
        AnalyzeTiming()
        statusLabel.Text = string.format("📊 Analysis complete!\n\n📞 Total calls: %d\n📋 Check console for detailed results", #AutoFishAnalysis.calls)
    end)
    
    return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- 🚀 START ANALYSIS
-- ═══════════════════════════════════════════════════════════════

local function StartAnalysis()
    print("🚀 Fish It Auto Fishing Analysis - Starting...")
    
    -- Hook all remotes
    local success = HookAllRemotes()
    
    -- Start rod orientation monitoring
    local orientationConnection = RunService.Heartbeat:Connect(function()
        if AutoFishAnalysis.isMonitoring then
            MonitorRodOrientation()
        end
    end)
    
    -- Create UI
    CreateAnalysisUI()
    
    if success then
        AutoFishAnalysis.isMonitoring = true
        print("✅ Analysis system active!")
        print("🎣 Now use the built-in AUTO FISHING button in game")
        print("📊 All calls will be logged and analyzed")
        print("📋 Check console (F9) for detailed results")
    else
        print("❌ Failed to setup analysis")
    end
    
    return orientationConnection
end

-- Start the analysis
StartAnalysis()

--[[
🔍 AUTO FISHING ANALYSIS GUIDE:

🎯 PURPOSE:
- Understand how built-in auto fishing works
- Analyze parameter patterns and values
- Monitor rod orientation changes
- Discover timing patterns

📊 WHAT IT ANALYZES:
✅ All remote calls (RF/RE)
✅ Parameter types and values
✅ Power values (0-1 or 0-100)
✅ Coordinate values (-1 to 1)
✅ Timing between calls
✅ Rod orientation changes

💡 HOW TO USE:
1. Load this script
2. Use the built-in AUTO button in game
3. Watch console (F9) for detailed logs
4. Click "Show Pattern Summary" for analysis

🔍 WHAT YOU'LL DISCOVER:
- Exact parameter values used by auto fishing
- Timing patterns between phases
- Rod orientation mechanics
- Perfect values for charge/roll

This will show you exactly how the game's auto fishing works!
]]

print("🔍 Auto Fishing Analyzer loaded!")
print("🎣 Ready to analyze built-in auto fishing behavior")
print("📊 Use AUTO button in game and check console!")
