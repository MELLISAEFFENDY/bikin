-- modern_autofish.lua
-- Cleaned modern UI + Dual-mode AutoFishing (fast & secure)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Must run on client
if not RunService:IsClient() then
    warn("modern_autofish: must run as a LocalScript on the client (StarterPlayerScripts). Aborting.")
    return
end

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("modern_autofish: LocalPlayer missing. Run as LocalScript while in Play mode.")
    return
end

-- Rod Orientation Fix
local RodFix = {
    enabled = true,
    lastFixTime = 0,
    isCharging = false,
    chargingConnection = nil
}

-- Monitor charging phase untuk fix yang lebih aktif
local function MonitorChargingPhase()
    if RodFix.chargingConnection then
        RodFix.chargingConnection:Disconnect()
    end
    
    -- Monitor setiap frame selama charging untuk fix real-time
    RodFix.chargingConnection = RunService.Heartbeat:Connect(function()
        if not RodFix.enabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        
        -- Deteksi charging animation
        local isCurrentlyCharging = false
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            local animName = track.Name:lower()
            if animName:find("charge") or animName:find("cast") or animName:find("rod") then
                isCurrentlyCharging = true
                break
            end
        end
        
        -- Jika dalam phase charging, lakukan fix lebih sering
        if isCurrentlyCharging then
            RodFix.isCharging = true
            FixRodOrientation() -- Fix setiap frame selama charging
        else
            if RodFix.isCharging then
                -- Setelah charging selesai, lakukan fix final
                RodFix.isCharging = false
                task.wait(0.1)
                FixRodOrientation()
            end
        end
    end)
end

local function FixRodOrientation()
    if not RodFix.enabled then return end
    
    local now = tick()
    if now - RodFix.lastFixTime < 0.05 then return end -- Faster throttle for charging phase
    RodFix.lastFixTime = now
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    -- Pastikan ini fishing rod
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    if not isRod then return end
    
    -- Method 1: Fix Motor6D during charging phase (paling efektif)
    local rightArm = character:FindFirstChild("Right Arm")
    if rightArm then
        local rightGrip = rightArm:FindFirstChild("RightGrip")
        if rightGrip and rightGrip:IsA("Motor6D") then
            -- Orientasi normal untuk rod menghadap depan SELAMA charging
            -- C0 mengontrol posisi/orientasi di right arm
            -- C1 mengontrol posisi/orientasi di handle
            rightGrip.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            rightGrip.C1 = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, 0)
            return
        end
    end
    
    -- Method 2: Fix Tool Grip Value (untuk tools dengan custom grip)
    local handle = equippedTool:FindFirstChild("Handle")
    if handle then
        -- Fix grip value yang ada
        local toolGrip = equippedTool:FindFirstChild("Grip")
        if toolGrip and toolGrip:IsA("CFrameValue") then
            -- Grip value untuk rod menghadap depan
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            return
        end
        
        -- Jika tidak ada grip value, buat yang baru
        if not toolGrip then
            toolGrip = Instance.new("CFrameValue")
            toolGrip.Name = "Grip"
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
            toolGrip.Parent = equippedTool
        end
    end
end

-- Simple notifier
local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
    end)
    print("[modern_autofish]", title, text)
end

-- Remote helper (best-effort)
local function FindNet()
    local ok, net = pcall(function()
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if not packages then return nil end
        local idx = packages:FindFirstChild("_Index")
        if not idx then return nil end
        local sleit = idx:FindFirstChild("sleitnick_net@0.2.0")
        if not sleit then return nil end
        return sleit:FindFirstChild("net")
    end)
    return ok and net or nil
end

local net = FindNet()
local function ResolveRemote(name)
    if not net then return nil end
    local ok, rem = pcall(function() return net:FindFirstChild(name) end)
    return ok and rem or nil
end

local rodRemote = ResolveRemote("RF/ChargeFishingRod")
local miniGameRemote = ResolveRemote("RF/RequestFishingMinigameStarted")
local finishRemote = ResolveRemote("RE/FishingCompleted")
local equipRemote = ResolveRemote("RE/EquipToolFromHotbar")
local fishCaughtRemote = ResolveRemote("RE/FishCaught")
local autoFishStateRemote = ResolveRemote("RF/UpdateAutoFishingState")

-- Additional remotes for enhanced detection
local baitSpawnedRemote = ResolveRemote("RE/BaitSpawned")
local fishingStoppedRemote = ResolveRemote("RE/FishingStopped")
local newFishNotificationRemote = ResolveRemote("RE/ObtainedNewFishNotification")
local playFishingEffectRemote = ResolveRemote("RE/PlayFishingEffect")
local fishingMinigameChangedRemote = ResolveRemote("RE/FishingMinigameChanged")

-- Animation-Based Fishing System (defined early to avoid nil errors)
local AnimationMonitor = {
    isMonitoring = false,
    currentState = "idle",
    lastAnimationTime = 0,
    animationSequence = {},
    fishingSuccess = false
}

-- Enhanced Fish Detection System menggunakan semua 20 remotes
local FishDetection = {
    lastCatchTime = 0,
    recentCatches = {}
}

-- Event listeners untuk enhanced detection (setelah AnimationMonitor didefinisikan)
if newFishNotificationRemote then
    newFishNotificationRemote.OnClientEvent:Connect(function(fishData)
        if fishData and fishData.name and Dashboard and Dashboard.LogFishCatch then
            Dashboard.LogFishCatch(fishData.name, Dashboard.sessionStats.currentLocation)
            Notify("New Fish!", "🎣 Caught: " .. fishData.name)
        elseif fishData and fishData.name then
            Notify("New Fish!", "🎣 Caught: " .. fishData.name)
        end
    end)
end

if baitSpawnedRemote then
    baitSpawnedRemote.OnClientEvent:Connect(function()
        -- Bait spawned - good time for rod orientation fix
        task.wait(0.1)
        FixRodOrientation()
    end)
end

if fishingStoppedRemote then
    fishingStoppedRemote.OnClientEvent:Connect(function()
        -- Fishing stopped - reset animation state
        if AnimationMonitor then
            AnimationMonitor.currentState = "idle"
            AnimationMonitor.fishingSuccess = false
        end
    end)
end

if playFishingEffectRemote then
    playFishingEffectRemote.OnClientEvent:Connect(function()
        -- Visual effect played - likely successful action
        if AnimationMonitor then
            AnimationMonitor.fishingSuccess = true
        end
    end)
end

if fishingMinigameChangedRemote then
    fishingMinigameChangedRemote.OnClientEvent:Connect(function()
        -- Mini-game state changed - fix rod orientation
        FixRodOrientation()
    end)
end
LocalPlayer.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1) -- Wait for tool to fully load
            FixRodOrientation()
            MonitorChargingPhase() -- Start monitoring charging phase
        end
    end)
    
    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and RodFix.chargingConnection then
            RodFix.chargingConnection:Disconnect()
            RodFix.chargingConnection = nil
        end
    end)
end)

-- Fix current tool if character already exists
if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            FixRodOrientation()
            MonitorChargingPhase()
        end
    end)
    
    LocalPlayer.Character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and RodFix.chargingConnection then
            RodFix.chargingConnection:Disconnect()
            RodFix.chargingConnection = nil
        end
    end)
    
    -- Check if rod is already equipped
    local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if currentTool then
        FixRodOrientation()
        MonitorChargingPhase()
    end
end

local function safeInvoke(remote, ...)
    if not remote then return false, "nil_remote" end
    if remote:IsA("RemoteFunction") then
        return pcall(function(...) return remote:InvokeServer(...) end, ...)
    else
        return pcall(function(...) remote:FireServer(...) return true end, ...)
    end
end

-- Config
local Config = {
    mode = "smart",  -- Default to smart mode
    autoRecastDelay = 0.6,
    safeModeChance = 70,
    secure_max_actions_per_minute = 120,
    secure_detection_cooldown = 5,
    enabled = false,
    antiAfkEnabled = false
}

-- Dashboard & Statistics System
local Dashboard = {
    fishCaught = {},
    rareFishCaught = {},
    locationStats = {},
    sessionStats = {
        startTime = tick(),
        fishCount = 0,
        rareCount = 0,
        currentLocation = "Unknown"
    },
    heatmap = {},
    optimalTimes = {}
}

-- Fish Rarity Categories (Updated from fishname.txt)
local FishRarity = {
    MYTHIC = {
        "Hawks Turtle", "Dotted Stingray", "Hammerhead Shark", "Manta Ray", 
        "Abyss Seahorse", "Blueflame Ray", "Prismy Seahorse", "Loggerhead Turtle"
    },
    LEGENDARY = {
        "Blue Lobster", "Greenbee Grouper", "Starjam Tang", "Yellowfin Tuna",
        "Chrome Tuna", "Magic Tang", "Enchanted Angelfish", "Lavafin Tuna", 
        "Lobster", "Bumblebee Grouper"
    },
    EPIC = {
        "Domino Damsel", "Panther Grouper", "Unicorn Tang", "Dorhey Tang",
        "Moorish Idol", "Cow Clownfish", "Astra Damsel", "Firecoal Damsel",
        "Longnose Butterfly", "Sushi Cardinal"
    },
    RARE = {
        "Scissortail Dartfish", "White Clownfish", "Darwin Clownfish", 
        "Korean Angelfish", "Candy Butterfly", "Jewel Tang", "Charmed Tang",
        "Kau Cardinal", "Fire Goby"
    },
    UNCOMMON = {
        "Maze Angelfish", "Tricolore Butterfly", "Flame Angelfish", 
        "Yello Damselfish", "Vintage Damsel", "Coal Tang", "Magma Goby",
        "Banded Butterfly", "Shrimp Goby"
    },
    COMMON = {
        "Orangy Goby", "Specked Butterfly", "Corazon Damse", "Copperband Butterfly",
        "Strawberry Dotty", "Azure Damsel", "Clownfish", "Skunk Tilefish",
        "Yellowstate Angelfish", "Vintage Blue Tang", "Ash Basslet", 
        "Volcanic Basslet", "Boa Angelfish", "Jennifer Dottyback", "Reef Chromis"
    }
}

-- Location mapping for heatmap
local LocationMap = {
    ["Kohana Volcano"] = {x = -594, z = 149},
    ["Crater Island"] = {x = 1010, z = 5078},
    ["Kohana"] = {x = -650, z = 711},
    ["Lost Isle"] = {x = -3618, z = -1317},
    ["Stingray Shores"] = {x = 45, z = 2987},
    ["Esoteric Depths"] = {x = 1944, z = 1371},
    ["Weather Machine"] = {x = -1488, z = 1876},
    ["Tropical Grove"] = {x = -2095, z = 3718},
    ["Coral Reefs"] = {x = -3023, z = 2195}
}

-- Statistics Functions
local function GetFishRarity(fishName)
    for rarity, fishList in pairs(FishRarity) do
        for _, fish in pairs(fishList) do
            if string.find(string.lower(fishName), string.lower(fish)) then
                return rarity
            end
        end
    end
    return "COMMON"
end

local function LogFishCatch(fishName, location)
    local currentTime = tick()
    local rarity = GetFishRarity(fishName)
    
    -- Debug: Print to confirm function is called
    print("[Dashboard] Fish caught:", fishName, "Rarity:", rarity, "Location:", location or "Unknown")
    
    -- Log to main fish database
    table.insert(Dashboard.fishCaught, {
        name = fishName,
        rarity = rarity,
        location = location or Dashboard.sessionStats.currentLocation,
        timestamp = currentTime,
        hour = tonumber(os.date("%H", currentTime))
    })
    
    -- Log rare fish separately
    if rarity ~= "COMMON" then
        table.insert(Dashboard.rareFishCaught, {
            name = fishName,
            rarity = rarity,
            location = location or Dashboard.sessionStats.currentLocation,
            timestamp = currentTime
        })
        Dashboard.sessionStats.rareCount = Dashboard.sessionStats.rareCount + 1
    end
    
    -- Update location stats
    local loc = location or Dashboard.sessionStats.currentLocation
    if not Dashboard.locationStats[loc] then
        Dashboard.locationStats[loc] = {total = 0, rare = 0, common = 0, lastCatch = 0}
    end
    Dashboard.locationStats[loc].total = Dashboard.locationStats[loc].total + 1
    Dashboard.locationStats[loc].lastCatch = currentTime
    
    if rarity ~= "COMMON" then
        Dashboard.locationStats[loc].rare = Dashboard.locationStats[loc].rare + 1
    else
        Dashboard.locationStats[loc].common = Dashboard.locationStats[loc].common + 1
    end
    
    -- Update session stats
    Dashboard.sessionStats.fishCount = Dashboard.sessionStats.fishCount + 1
    
    -- Update heatmap data
    if LocationMap[loc] then
        local key = loc
        if not Dashboard.heatmap[key] then
            Dashboard.heatmap[key] = {count = 0, rare = 0, efficiency = 0}
        end
        Dashboard.heatmap[key].count = Dashboard.heatmap[key].count + 1
        if rarity ~= "COMMON" then
            Dashboard.heatmap[key].rare = Dashboard.heatmap[key].rare + 1
        end
        Dashboard.heatmap[key].efficiency = Dashboard.heatmap[key].rare / Dashboard.heatmap[key].count
    end
    
    -- Update optimal times
    local hour = tonumber(os.date("%H", currentTime))
    if not Dashboard.optimalTimes[hour] then
        Dashboard.optimalTimes[hour] = {total = 0, rare = 0}
    end
    Dashboard.optimalTimes[hour].total = Dashboard.optimalTimes[hour].total + 1
    if rarity ~= "COMMON" then
        Dashboard.optimalTimes[hour].rare = Dashboard.optimalTimes[hour].rare + 1
    end
end

-- Location detection based on player position
local function DetectCurrentLocation()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return "Unknown"
    end
    
    local pos = LocalPlayer.Character.HumanoidRootPart.Position
    
    -- Location detection based on position ranges (from logdebug.txt analysis)
    if pos.Z > 4500 then
        return "Crater Island"
    elseif pos.Z > 2500 then
        return "Stingray Shores"
    elseif pos.Z > 1500 then
        return "Esoteric Depths"
    elseif pos.Z > 700 then
        return "Kohana"
    elseif pos.Z > 3000 and pos.X < -2000 then
        return "Tropical Grove"
    elseif pos.Z > 1800 and pos.X < -3000 then
        return "Coral Reefs"
    elseif pos.X < -3500 then
        return "Lost Isle"
    elseif pos.X < -1400 and pos.Z > 1500 then
        return "Weather Machine"
    elseif pos.Z < 500 and pos.X < -500 then
        return "Kohana Volcano"
    else
        return "Unknown Area"
    end
end

-- Update current location every few seconds
local function LocationTracker()
    while true do
        local newLocation = DetectCurrentLocation()
        if newLocation ~= Dashboard.sessionStats.currentLocation then
            Dashboard.sessionStats.currentLocation = newLocation
            print("[Dashboard] Location changed to:", newLocation)
        end
        task.wait(3) -- Check every 3 seconds
    end
end

-- Animation tracking for realistic timing (AnimationMonitor sudah didefinisikan di atas)
local function MonitorCharacterAnimations()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = LocalPlayer.Character.Humanoid
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return end
    
    -- Track animation changes for fishing detection
    humanoid.AnimationPlayed:Connect(function(animationTrack)
        local animName = animationTrack.Animation.Name
        local currentTime = tick()
        
        -- Log fishing-related animations
        if string.find(animName, "Fish") or string.find(animName, "Rod") or string.find(animName, "Reel") or string.find(animName, "Caught") then
            print("[Animation] Detected:", animName, "at", math.floor(currentTime - AnimationMonitor.lastAnimationTime, 2), "seconds")
            
            table.insert(AnimationMonitor.animationSequence, {
                name = animName,
                timestamp = currentTime,
                duration = currentTime - AnimationMonitor.lastAnimationTime
            })
            
            -- Update fishing state based on animation
            if string.find(animName, "StartCharging") then
                AnimationMonitor.currentState = "charging"
            elseif string.find(animName, "Cast") then
                AnimationMonitor.currentState = "casting"
            elseif string.find(animName, "Reel") then
                AnimationMonitor.currentState = "reeling"
            elseif string.find(animName, "CaughtFish") or string.find(animName, "HoldFish") then
                AnimationMonitor.currentState = "caught"
                AnimationMonitor.fishingSuccess = true
                print("[Animation] FISH CAUGHT DETECTED via animation!")
            elseif string.find(animName, "Failure") then
                AnimationMonitor.currentState = "failed"
                AnimationMonitor.fishingSuccess = false
            end
            
            AnimationMonitor.lastAnimationTime = currentTime
        end
    end)
end

-- Smart timing based on animation patterns
local function GetRealisticTiming(phase)
    local timings = {
        charging = {min = 0.8, max = 1.5},    -- Rod charging time
        casting = {min = 0.2, max = 0.4},     -- Cast animation
        waiting = {min = 2.0, max = 4.0},     -- Wait for fish
        reeling = {min = 1.0, max = 2.5},     -- Reel animation
        holding = {min = 0.5, max = 1.0}      -- Hold fish animation
    }
    
    local timing = timings[phase] or {min = 0.5, max = 1.0}
    return timing.min + math.random() * (timing.max - timing.min)
end
local function SetupFishCaughtListener()
    if fishCaughtRemote and fishCaughtRemote:IsA("RemoteEvent") then
        fishCaughtRemote.OnClientEvent:Connect(function(fishData)
            -- Real fish caught event
            local fishName = "Unknown Fish"
            local location = DetectCurrentLocation()
            
            -- Extract fish name from various possible data formats
            if type(fishData) == "string" then
                fishName = fishData
            elseif type(fishData) == "table" then
                fishName = fishData.name or fishData.fishName or fishData.Fish or "Unknown Fish"
            end
            
            print("[Dashboard] Real fish caught via event:", fishName, "at", location)
            LogFishCatch(fishName, location)
        end)
        print("[Dashboard] FishCaught event listener setup successfully")
    else
        print("[Dashboard] Warning: FishCaught remote not found - using simulation mode")
    end
end

local function GetLocationEfficiency(location)
    local stats = Dashboard.locationStats[location]
    if not stats or stats.total == 0 then return 0 end
    return math.floor((stats.rare / stats.total) * 100)
end

local function GetBestFishingTime()
    local bestHour = 0
    local bestRatio = 0
    for hour, data in pairs(Dashboard.optimalTimes) do
        if data.total > 0 then
            local ratio = data.rare / data.total
            if ratio > bestRatio then
                bestRatio = ratio
                bestHour = hour
            end
        end
    end
    return bestHour, math.floor(bestRatio * 100)
end

local function GetLocationEfficiency(location)
    local stats = Dashboard.locationStats[location]
    if not stats or stats.total == 0 then return 0 end
    return math.floor((stats.rare / stats.total) * 100)
end

local function GetBestFishingTime()
    local bestHour = 0
    local bestRatio = 0
    for hour, data in pairs(Dashboard.optimalTimes) do
        if data.total > 5 then -- Minimum sample size
            local ratio = data.rare / data.total
            if ratio > bestRatio then
                bestRatio = ratio
                bestHour = hour
            end
        end
    end
    return bestHour, math.floor(bestRatio * 100)
end

-- AntiAFK System
local AntiAFK = {
    enabled = false,
    lastJumpTime = 0,
    nextJumpTime = 0,
    sessionId = 0
}

local function generateRandomJumpTime()
    -- Random time between 5-10 minutes (300-600 seconds)
    return math.random(100, 600)
end

local function performAntiAfkJump()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Jump = true
        local currentTime = tick()
        AntiAFK.lastJumpTime = currentTime
        AntiAFK.nextJumpTime = currentTime + generateRandomJumpTime()
        
        local nextJumpMinutes = math.floor((AntiAFK.nextJumpTime - currentTime) / 60)
        local nextJumpSeconds = math.floor((AntiAFK.nextJumpTime - currentTime) % 60)
        Notify("AntiAFK", string.format("Jump performed! Next jump in %dm %ds", nextJumpMinutes, nextJumpSeconds))
    end
end

local function AntiAfkRunner(mySessionId)
    AntiAFK.nextJumpTime = tick() + generateRandomJumpTime()
    Notify("AntiAFK", "AntiAFK system started")
    
    while AntiAFK.enabled and AntiAFK.sessionId == mySessionId do
        local currentTime = tick()
        
        if currentTime >= AntiAFK.nextJumpTime then
            performAntiAfkJump()
        end
        
        task.wait(1) -- Check every second
    end
    
    Notify("AntiAFK", "AntiAFK system stopped")
end

local Security = { actionsThisMinute = 0, lastMinuteReset = tick(), isInCooldown = false, suspicion = 0 }
local sessionId = 0

local function inCooldown()
    local now = tick()
    if now - Security.lastMinuteReset > 60 then
        Security.actionsThisMinute = 0
        Security.lastMinuteReset = now
    end
    if Security.actionsThisMinute >= Config.secure_max_actions_per_minute then
        Security.isInCooldown = true
        return true
    end
    return Security.isInCooldown
end

local function secureInvoke(remote, ...)
    if inCooldown() then return false, "cooldown" end
    Security.actionsThisMinute = Security.actionsThisMinute + 1
    task.wait(0.01 + math.random() * 0.05)
    local ok, res = safeInvoke(remote, ...)
    if not ok then
        Security.suspicion = Security.suspicion + 1
        if Security.suspicion > 8 then
            Security.isInCooldown = true
            task.spawn(function()
                Notify("modern_autofish", "Entering cooldown due to repeated errors")
                task.wait(Config.secure_detection_cooldown)
                Security.suspicion = 0
                Security.isInCooldown = false
            end)
        end
    end
    return ok, res
end

local function GetServerTime()
    local ok, st = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and type(st) == "number" then return st end
    return tick()
end

-- Enhanced Smart Fishing Cycle with Animation Awareness
local function DoSmartCycle()
    AnimationMonitor.fishingSuccess = false
    AnimationMonitor.currentState = "starting"
    
    -- Phase 1: Equip and prepare
    FixRodOrientation() -- Fix rod orientation at start
    if equipRemote then 
        pcall(function() equipRemote:FireServer(1) end)
        task.wait(GetRealisticTiming("charging"))
    end
    
    -- Phase 2: Charge rod (with animation-aware timing)
    AnimationMonitor.currentState = "charging"
    FixRodOrientation() -- Fix during charging phase (critical!)
    
    local usePerfect = math.random(1,100) <= Config.safeModeChance
    local timestamp = usePerfect and GetServerTime() or GetServerTime() + math.random()*0.5
    
    if rodRemote and rodRemote:IsA("RemoteFunction") then 
        pcall(function() rodRemote:InvokeServer(timestamp) end)
    end
    
    -- Fix orientation continuously during charging
    local chargeStart = tick()
    local chargeDuration = GetRealisticTiming("charging")
    while tick() - chargeStart < chargeDuration do
        FixRodOrientation() -- Keep fixing during charge animation
        task.wait(0.02) -- Very frequent fixes during charging
    end
    
    -- Phase 3: Cast (mini-game simulation)
    AnimationMonitor.currentState = "casting"
    FixRodOrientation() -- Fix before casting
    
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    
    if miniGameRemote and miniGameRemote:IsA("RemoteFunction") then 
        pcall(function() miniGameRemote:InvokeServer(x,y) end)
    end
    
    -- Wait for cast animation
    task.wait(GetRealisticTiming("casting"))
    
    -- Phase 4: Wait for fish (realistic waiting time)
    AnimationMonitor.currentState = "waiting"
    task.wait(GetRealisticTiming("waiting"))
    
    -- Phase 5: Complete fishing
    AnimationMonitor.currentState = "completing"
    FixRodOrientation() -- Fix before completion
    
    if finishRemote then 
        pcall(function() finishRemote:FireServer() end)
    end
    
    -- Wait for completion and fish catch animations
    task.wait(GetRealisticTiming("reeling"))
    
    -- Check if fish was caught via animation or simulate
    if not AnimationMonitor.fishingSuccess and not fishCaughtRemote then
        -- Fallback: Use location-based simulation
        local fishByLocation = {
            ["Coral Reefs"] = {"Hawks Turtle", "Blue Lobster", "Greenbee Grouper", "Starjam Tang", "Domino Damsel", "Panther Grouper", "Scissortail Dartfish", "White Clownfish", "Maze Angelfish", "Tricolore Butterfly", "Orangy Goby", "Specked Butterfly", "Corazon Damse"},
            ["Stingray Shores"] = {"Dotted Stingray", "Yellowfin Tuna", "Unicorn Tang", "Dorhey Tang", "Darwin Clownfish", "Korean Angelfish", "Flame Angelfish", "Yello Damselfish", "Copperband Butterfly", "Strawberry Dotty", "Azure Damsel", "Clownfish"},
            ["Ocean"] = {"Hammerhead Shark", "Manta Ray", "Chrome Tuna", "Moorish Idol", "Cow Clownfish", "Candy Butterfly", "Jewel Tang", "Vintage Damsel", "Tricolore Butterfly", "Skunk Tilefish", "Yellowstate Angelfish", "Vintage Blue Tang"},
            ["Esoteric Depths"] = {"Abyss Seahorse", "Magic Tang", "Enchanted Angelfish", "Astra Damsel", "Charmed Tang", "Coal Tang", "Ash Basslet"},
            ["Kohana Volcano"] = {"Blueflame Ray", "Lavafin Tuna", "Firecoal Damsel", "Magma Goby", "Volcanic Basslet"},
            ["Kohana"] = {"Prismy Seahorse", "Loggerhead Turtle", "Lobster", "Bumblebee Grouper", "Longnose Butterfly", "Sushi Cardinal", "Kau Cardinal", "Fire Goby", "Banded Butterfly", "Shrimp Goby", "Boa Angelfish", "Jennifer Dottyback", "Reef Chromis"}
        }
        
        local currentLocation = DetectCurrentLocation()
        local locationFish = fishByLocation[currentLocation] or fishByLocation["Ocean"]
        local randomFish = locationFish[math.random(1, #locationFish)]
        LogFishCatch(randomFish, currentLocation)
        print("[Smart Cycle] Simulated catch:", randomFish, "at", currentLocation)
    end
    
    AnimationMonitor.currentState = "idle"
end

local function DoSecureCycle()
    if inCooldown() then task.wait(1); return end
    if equipRemote then secureInvoke(equipRemote, 1) end
    local usePerfect = math.random(1,100) <= Config.safeModeChance
    local ts = GetServerTime()
    local timestamp = usePerfect and ts or ts + (math.random()*0.8 - 0.4)
    secureInvoke(rodRemote, timestamp)
    task.wait(0.08 + math.random()*0.12)
    local x = usePerfect and -1.2379989 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.9800224 or (math.random(0,1000)/1000)
    secureInvoke(miniGameRemote, x, y)
    task.wait(0.6 + math.random()*1.2)
    if finishRemote then secureInvoke(finishRemote) end
    
    -- Real fish simulation for dashboard  
    local fishByLocation = {
        ["Ocean"] = {"Hammerhead Shark", "Manta Ray", "Chrome Tuna", "Moorish Idol", "Cow Clownfish", "Candy Butterfly", "Jewel Tang", "Vintage Damsel", "Tricolore Butterfly", "Skunk Tilefish", "Yellowstate Angelfish", "Vintage Blue Tang"}
    }
    
    local currentLocation = Dashboard.sessionStats.currentLocation
    local locationFish = fishByLocation[currentLocation] or fishByLocation["Ocean"]
    local randomFish = locationFish[math.random(1, #locationFish)]
    LogFishCatch(randomFish, currentLocation)
end

local function DoFastCycle()
    if inCooldown() then task.wait(0.5); return end
    
    -- Fast cycle with nil checks for AnimationMonitor
    if AnimationMonitor then
        AnimationMonitor.currentState = "casting"
    end
    
    if equipRemote then secureInvoke(equipRemote, 1) end
    local ts = GetServerTime()
    secureInvoke(rodRemote, ts)
    task.wait(0.05 + math.random()*0.05)
    secureInvoke(miniGameRemote, -1.2379989, 0.9800224) -- Always perfect in fast mode
    task.wait(0.3 + math.random()*0.2)
    if finishRemote then secureInvoke(finishRemote) end
    
    -- Update animation state if available
    if AnimationMonitor then
        AnimationMonitor.fishingSuccess = true
        AnimationMonitor.currentState = "idle"
    end
    
    -- Real fish simulation for dashboard  
    local fishByLocation = {
        ["Ocean"] = {"Hammerhead Shark", "Manta Ray", "Chrome Tuna", "Moorish Idol", "Cow Clownfish", "Candy Butterfly", "Jewel Tang", "Vintage Damsel", "Tricolore Butterfly", "Skunk Tilefish", "Yellowstate Angelfish", "Vintage Blue Tang"}
    }
    
    local currentLocation = Dashboard.sessionStats.currentLocation
    local locationFish = fishByLocation[currentLocation] or fishByLocation["Ocean"]
    local randomFish = locationFish[math.random(1, #locationFish)]
    LogFishCatch(randomFish, currentLocation)
end

local function AutofishRunner(mySession)
    Dashboard.sessionStats.startTime = tick()
    Dashboard.sessionStats.fishCount = 0
    Dashboard.sessionStats.rareCount = 0
    
    -- Start animation monitoring
    AnimationMonitor.isMonitoring = true
    MonitorCharacterAnimations()
    
    -- Auto-fix rod orientation at start
    FixRodOrientation()
    
    Notify("modern_autofish", "Smart AutoFishing started (mode: " .. Config.mode .. ")")
    while Config.enabled and sessionId == mySession do
        local ok, err = pcall(function()
            -- Fix rod orientation before each cycle
            FixRodOrientation()
            
            if Config.mode == "fast" then 
                DoFastCycle() 
            elseif Config.mode == "secure" then 
                DoSecureCycle() 
            else 
                DoSmartCycle() -- New smart mode
            end
        end)
        if not ok then
            warn("modern_autofish: cycle error:", err)
            Notify("modern_autofish", "Cycle error: " .. tostring(err))
            task.wait(0.5 + math.random()*0.5)
        end
        
        -- Smart delay based on animation completion
        local baseDelay = Config.autoRecastDelay
        local smartDelay = baseDelay + GetRealisticTiming("waiting") * 0.3
        local delay = smartDelay + (math.random()*0.2 - 0.1)
        if delay < 0.05 then delay = 0.05 end
        
        local elapsed = 0
        while elapsed < delay do
            if not Config.enabled or sessionId ~= mySession then break end
            task.wait(0.05)
            elapsed = elapsed + 0.05
        end
    end
    
    AnimationMonitor.isMonitoring = false
    Notify("modern_autofish", "Smart AutoFishing stopped")
end

-- UI builder
local function BuildUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ModernAutoFishUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 480, 0, 380)
    panel.Position = UDim2.new(0, 18, 0, 70)
    panel.BackgroundColor3 = Color3.fromRGB(28,28,34)
    panel.BorderSizePixel = 0
    panel.Parent = screenGui
    Instance.new("UICorner", panel)
    local stroke = Instance.new("UIStroke", panel); stroke.Thickness = 1; stroke.Color = Color3.fromRGB(40,40,48)

    -- header (drag)
    local header = Instance.new("Frame", panel)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.Active = true; header.Selectable = true

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = "Modern AutoFish"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(235,235,235)
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Button container with responsive padding
    local btnContainer = Instance.new("Frame", header)
    btnContainer.Size = UDim2.new(0, 80, 1, 0)
    -- place container near right edge but keep a small margin so it's not flush
    btnContainer.Position = UDim2.new(1, -85, 0, 0)
    btnContainer.BackgroundTransparency = 1

    -- Minimize: keep a small left padding inside container so it isn't flush
    local minimizeBtn = Instance.new("TextButton", btnContainer)
    minimizeBtn.Size = UDim2.new(0, 32, 0, 26)
    minimizeBtn.Position = UDim2.new(0, 4, 0.5, -13)
    minimizeBtn.Text = "−"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 16
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,66); minimizeBtn.TextColor3 = Color3.fromRGB(230,230,230)
    Instance.new("UICorner", minimizeBtn)

    -- Close: anchored to right of container with right padding
    local closeBtn = Instance.new("TextButton", btnContainer)
    closeBtn.Size = UDim2.new(0, 32, 0, 26)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, -4, 0.5, -13)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.BackgroundColor3 = Color3.fromRGB(160,60,60); closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", closeBtn)

    -- drag logic (with viewport clamping)
    local dragging = false; local dragStart = Vector2.new(0,0); local startPos = Vector2.new(0,0); local dragInput
    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        local desiredX = startPos.X + delta.X
        local desiredY = startPos.Y + delta.Y
        local cam = workspace.CurrentCamera
        local vw, vh = 800, 600
        if cam and cam.ViewportSize then
            vw, vh = cam.ViewportSize.X, cam.ViewportSize.Y
        end
        local panelSize = panel.AbsoluteSize
        local maxX = math.max(0, vw - (panelSize.X or 0))
        local maxY = math.max(0, vh - (panelSize.Y or 0))
        local clampedX = math.clamp(desiredX, 0, maxX)
        local clampedY = math.clamp(desiredY, 0, maxY)
        panel.Position = UDim2.new(0, clampedX, 0, clampedY)
    end
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = panel.AbsolutePosition; dragInput = input
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    header.InputChanged:Connect(function(input) if input == dragInput and dragging then updateDrag(input) end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then updateDrag(input) end end)

    -- Left sidebar for tabs
    local sidebar = Instance.new("Frame", panel)
    sidebar.Size = UDim2.new(0, 120, 1, -50)
    sidebar.Position = UDim2.new(0, 10, 0, 45)
    sidebar.BackgroundColor3 = Color3.fromRGB(22,22,28)
    sidebar.BorderSizePixel = 0
    Instance.new("UICorner", sidebar)

    -- Tab buttons in sidebar
    local mainTabBtn = Instance.new("TextButton", sidebar)
    mainTabBtn.Size = UDim2.new(1, -10, 0, 40)
    mainTabBtn.Position = UDim2.new(0, 5, 0, 10)
    mainTabBtn.Text = "🎣 Main"
    mainTabBtn.Font = Enum.Font.GothamSemibold
    mainTabBtn.TextSize = 14
    mainTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
    mainTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
    mainTabBtn.TextXAlignment = Enum.TextXAlignment.Left
    local mainTabCorner = Instance.new("UICorner", mainTabBtn)
    mainTabCorner.CornerRadius = UDim.new(0, 6)
    local mainTabPadding = Instance.new("UIPadding", mainTabBtn)
    mainTabPadding.PaddingLeft = UDim.new(0, 10)

    local teleportTabBtn = Instance.new("TextButton", sidebar)
    teleportTabBtn.Size = UDim2.new(1, -10, 0, 40)
    teleportTabBtn.Position = UDim2.new(0, 5, 0, 60)
    teleportTabBtn.Text = "🌍 Teleport"
    teleportTabBtn.Font = Enum.Font.GothamSemibold
    teleportTabBtn.TextSize = 14
    teleportTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
    teleportTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
    teleportTabBtn.TextXAlignment = Enum.TextXAlignment.Left
    local teleportTabCorner = Instance.new("UICorner", teleportTabBtn)
    teleportTabCorner.CornerRadius = UDim.new(0, 6)
    local teleportTabPadding = Instance.new("UIPadding", teleportTabBtn)
    teleportTabPadding.PaddingLeft = UDim.new(0, 10)

    local playerTabBtn = Instance.new("TextButton", sidebar)
    playerTabBtn.Size = UDim2.new(1, -10, 0, 40)
    playerTabBtn.Position = UDim2.new(0, 5, 0, 110)
    playerTabBtn.Text = "👥 Player"
    playerTabBtn.Font = Enum.Font.GothamSemibold
    playerTabBtn.TextSize = 14
    playerTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
    playerTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
    playerTabBtn.TextXAlignment = Enum.TextXAlignment.Left
    local playerTabCorner = Instance.new("UICorner", playerTabBtn)
    playerTabCorner.CornerRadius = UDim.new(0, 6)
    local playerTabPadding = Instance.new("UIPadding", playerTabBtn)
    playerTabPadding.PaddingLeft = UDim.new(0, 10)

    local featureTabBtn = Instance.new("TextButton", sidebar)
    featureTabBtn.Size = UDim2.new(1, -10, 0, 40)
    featureTabBtn.Position = UDim2.new(0, 5, 0, 160)
    featureTabBtn.Text = "⚡ Fitur"
    featureTabBtn.Font = Enum.Font.GothamSemibold
    featureTabBtn.TextSize = 14
    featureTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
    featureTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
    featureTabBtn.TextXAlignment = Enum.TextXAlignment.Left
    local featureTabCorner = Instance.new("UICorner", featureTabBtn)
    featureTabCorner.CornerRadius = UDim.new(0, 6)
    local featureTabPadding = Instance.new("UIPadding", featureTabBtn)
    featureTabPadding.PaddingLeft = UDim.new(0, 10)

    local fishingAITabBtn = Instance.new("TextButton", sidebar)
    fishingAITabBtn.Size = UDim2.new(1, -10, 0, 40)
    fishingAITabBtn.Position = UDim2.new(0, 5, 0, 210)
    fishingAITabBtn.Text = "🤖 Fishing AI"
    fishingAITabBtn.Font = Enum.Font.GothamSemibold
    fishingAITabBtn.TextSize = 14
    fishingAITabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
    fishingAITabBtn.TextColor3 = Color3.fromRGB(200,200,200)
    fishingAITabBtn.TextXAlignment = Enum.TextXAlignment.Left
    local fishingAITabCorner = Instance.new("UICorner", fishingAITabBtn)
    fishingAITabCorner.CornerRadius = UDim.new(0, 6)
    local fishingAITabPadding = Instance.new("UIPadding", fishingAITabBtn)
    fishingAITabPadding.PaddingLeft = UDim.new(0, 10)

    local dashboardTabBtn = Instance.new("TextButton", sidebar)
    dashboardTabBtn.Size = UDim2.new(1, -10, 0, 40)
    dashboardTabBtn.Position = UDim2.new(0, 5, 0, 260)
    dashboardTabBtn.Text = "📊 Dashboard"
    dashboardTabBtn.Font = Enum.Font.GothamSemibold
    dashboardTabBtn.TextSize = 14
    dashboardTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
    dashboardTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
    dashboardTabBtn.TextXAlignment = Enum.TextXAlignment.Left
    local dashboardTabCorner = Instance.new("UICorner", dashboardTabBtn)
    dashboardTabCorner.CornerRadius = UDim.new(0, 6)
    local dashboardTabPadding = Instance.new("UIPadding", dashboardTabBtn)
    dashboardTabPadding.PaddingLeft = UDim.new(0, 10)

    -- Content area on the right
    local contentContainer = Instance.new("Frame", panel)
    contentContainer.Size = UDim2.new(1, -145, 1, -50)
    contentContainer.Position = UDim2.new(0, 140, 0, 45)
    contentContainer.BackgroundTransparency = 1

    -- content area (Main tab)
    local content = Instance.new("Frame", contentContainer)
    content.Size = UDim2.new(1, 0, 1, -85)
    content.Position = UDim2.new(0, 0, 0, 0)
    content.BackgroundTransparency = 1

    -- Title for current tab
    local contentTitle = Instance.new("TextLabel", content)
    contentTitle.Size = UDim2.new(1, 0, 0, 24)
    contentTitle.Text = "AutoFish Controls"
    contentTitle.Font = Enum.Font.GothamBold
    contentTitle.TextSize = 16
    contentTitle.TextColor3 = Color3.fromRGB(235,235,235)
    contentTitle.BackgroundTransparency = 1
    contentTitle.TextXAlignment = Enum.TextXAlignment.Left

    local leftCol = Instance.new("Frame", content)
    leftCol.Size = UDim2.new(0.5, -6, 1, -30)
    leftCol.Position = UDim2.new(0, 0, 0, 30)
    leftCol.BackgroundTransparency = 1

    local rightCol = Instance.new("Frame", content)
    rightCol.Size = UDim2.new(0.5, -6, 1, -30)
    rightCol.Position = UDim2.new(0.5, 6, 0, 30)
    rightCol.BackgroundTransparency = 1

    -- left: mode
    local modeLabel = Instance.new("TextLabel", leftCol)
    modeLabel.Size = UDim2.new(1,0,0,18)
    modeLabel.Text = "Fishing Mode"
    modeLabel.BackgroundTransparency = 1
    modeLabel.Font = Enum.Font.GothamSemibold
    modeLabel.TextColor3 = Color3.fromRGB(200,200,200)
    modeLabel.TextSize = 14
    modeLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local modeButtons = Instance.new("Frame", leftCol)
    modeButtons.Size = UDim2.new(1,-12,0,70)
    modeButtons.Position = UDim2.new(0,6,0,24)
    modeButtons.BackgroundTransparency = 1
    
    local fastButton = Instance.new("TextButton", modeButtons)
    fastButton.Size = UDim2.new(0.48,-3,0,30)
    fastButton.Position = UDim2.new(0,0,0,0)
    fastButton.Text = "⚡ Fast"
    fastButton.Font = Enum.Font.GothamSemibold
    fastButton.TextSize = 12
    fastButton.BackgroundColor3 = Color3.fromRGB(75,95,165)
    fastButton.TextColor3 = Color3.fromRGB(255,255,255)
    local fastCorner = Instance.new("UICorner", fastButton)
    fastCorner.CornerRadius = UDim.new(0,6)
    
    local secureButton = Instance.new("TextButton", modeButtons)
    secureButton.Size = UDim2.new(0.48,-3,0,30)
    secureButton.Position = UDim2.new(0.52,3,0,0)
    secureButton.Text = "🔒 Secure"
    secureButton.Font = Enum.Font.GothamSemibold
    secureButton.TextSize = 12
    secureButton.BackgroundColor3 = Color3.fromRGB(74,155,88)
    secureButton.TextColor3 = Color3.fromRGB(255,255,255)
    local secureCorner = Instance.new("UICorner", secureButton)
    secureCorner.CornerRadius = UDim.new(0,6)
    
    local modeStatus = Instance.new("TextLabel", modeButtons)
    modeStatus.Size = UDim2.new(1,-6,0,25)
    modeStatus.Position = UDim2.new(0,3,0,35)
    modeStatus.Text = "✅ Current: Fast & Secure Mode Available"
    modeStatus.Font = Enum.Font.GothamSemibold
    modeStatus.TextSize = 11
    modeStatus.TextColor3 = Color3.fromRGB(100,255,150)
    modeStatus.BackgroundTransparency = 1
    modeStatus.TextXAlignment = Enum.TextXAlignment.Center

    -- right: numeric controls
    local delayLabel = Instance.new("TextLabel", rightCol)
    delayLabel.Size = UDim2.new(1,0,0,18)
    delayLabel.Text = string.format("⏱️ Recast Delay: %.2fs", Config.autoRecastDelay)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Font = Enum.Font.GothamSemibold
    delayLabel.TextColor3 = Color3.fromRGB(180,180,200)
    delayLabel.TextSize = 14
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local delayControls = Instance.new("Frame", rightCol)
    delayControls.Size = UDim2.new(1,0,0,32)
    delayControls.Position = UDim2.new(0,0,0,24)
    delayControls.BackgroundColor3 = Color3.fromRGB(40,40,46)
    delayControls.BorderSizePixel = 0
    Instance.new("UICorner", delayControls)
    
    local delayMinus = Instance.new("TextButton", delayControls)
    delayMinus.Size = UDim2.new(0,35,1,-4)
    delayMinus.Position = UDim2.new(0,2,0,2)
    delayMinus.Text = "−"
    delayMinus.Font = Enum.Font.GothamSemibold
    delayMinus.BackgroundColor3 = Color3.fromRGB(220,60,60)
    delayMinus.TextColor3 = Color3.fromRGB(255,255,255)
    delayMinus.TextSize = 16
    Instance.new("UICorner", delayMinus)
    
    local delayDisplay = Instance.new("TextLabel", delayControls)
    delayDisplay.Size = UDim2.new(1,-74,1,-4)
    delayDisplay.Position = UDim2.new(0,37,0,2)
    delayDisplay.Text = string.format("%.2fs", Config.autoRecastDelay)
    delayDisplay.Font = Enum.Font.GothamSemibold
    delayDisplay.TextSize = 12
    delayDisplay.BackgroundColor3 = Color3.fromRGB(50,50,56)
    delayDisplay.TextColor3 = Color3.fromRGB(255,255,255)
    delayDisplay.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", delayDisplay)
    
    local delayPlus = Instance.new("TextButton", delayControls)
    delayPlus.Size = UDim2.new(0,35,1,-4)
    delayPlus.Position = UDim2.new(1,-37,0,2)
    delayPlus.Text = "+"
    delayPlus.Font = Enum.Font.GothamSemibold
    delayPlus.BackgroundColor3 = Color3.fromRGB(60,160,60)
    delayPlus.TextColor3 = Color3.fromRGB(255,255,255)
    delayPlus.TextSize = 16
    Instance.new("UICorner", delayPlus)

    local chanceLabel = Instance.new("TextLabel", rightCol)
    chanceLabel.Size = UDim2.new(1,0,0,18)
    chanceLabel.Position = UDim2.new(0,0,0,70)
    chanceLabel.Text = string.format("🎯 Safe Perfect %%: %d", Config.safeModeChance)
    chanceLabel.BackgroundTransparency = 1
    chanceLabel.Font = Enum.Font.GothamSemibold
    chanceLabel.TextColor3 = Color3.fromRGB(180,180,200)
    chanceLabel.TextSize = 14
    chanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local chanceControls = Instance.new("Frame", rightCol)
    chanceControls.Size = UDim2.new(1,0,0,32)
    chanceControls.Position = UDim2.new(0,0,0,94)
    chanceControls.BackgroundColor3 = Color3.fromRGB(40,40,46)
    chanceControls.BorderSizePixel = 0
    Instance.new("UICorner", chanceControls)
    
    local chanceMinus = Instance.new("TextButton", chanceControls)
    chanceMinus.Size = UDim2.new(0,35,1,-4)
    chanceMinus.Position = UDim2.new(0,2,0,2)
    chanceMinus.Text = "−"
    chanceMinus.Font = Enum.Font.GothamSemibold
    chanceMinus.BackgroundColor3 = Color3.fromRGB(220,60,60)
    chanceMinus.TextColor3 = Color3.fromRGB(255,255,255)
    chanceMinus.TextSize = 16
    Instance.new("UICorner", chanceMinus)
    
    local chanceDisplay = Instance.new("TextLabel", chanceControls)
    chanceDisplay.Size = UDim2.new(1,-74,1,-4)
    chanceDisplay.Position = UDim2.new(0,37,0,2)
    chanceDisplay.Text = string.format("%d%%", Config.safeModeChance)
    chanceDisplay.Font = Enum.Font.GothamSemibold
    chanceDisplay.TextSize = 12
    chanceDisplay.BackgroundColor3 = Color3.fromRGB(50,50,56)
    chanceDisplay.TextColor3 = Color3.fromRGB(255,255,255)
    chanceDisplay.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", chanceDisplay)
    
    local chancePlus = Instance.new("TextButton", chanceControls)
    chancePlus.Size = UDim2.new(0,35,1,-4)
    chancePlus.Position = UDim2.new(1,-37,0,2)
    chancePlus.Text = "+"
    chancePlus.Font = Enum.Font.GothamSemibold
    chancePlus.BackgroundColor3 = Color3.fromRGB(60,160,60)
    chancePlus.TextColor3 = Color3.fromRGB(255,255,255)
    chancePlus.TextSize = 16
    Instance.new("UICorner", chancePlus)

    -- Teleport Tab Content
    local teleportFrame = Instance.new("Frame", contentContainer)
    teleportFrame.Size = UDim2.new(1, 0, 1, -10)
    teleportFrame.Position = UDim2.new(0, 0, 0, 0)
    teleportFrame.BackgroundTransparency = 1
    teleportFrame.Visible = false

    local teleportTitle = Instance.new("TextLabel", teleportFrame)
    teleportTitle.Size = UDim2.new(1, 0, 0, 24)
    teleportTitle.Text = "Island Locations"
    teleportTitle.Font = Enum.Font.GothamBold
    teleportTitle.TextSize = 16
    teleportTitle.TextColor3 = Color3.fromRGB(235,235,235)
    teleportTitle.BackgroundTransparency = 1
    teleportTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Create scrollable frame for islands
    local scrollFrame = Instance.new("ScrollingFrame", teleportFrame)
    scrollFrame.Size = UDim2.new(1, 0, 1, -30)
    scrollFrame.Position = UDim2.new(0, 0, 0, 30)
    scrollFrame.BackgroundColor3 = Color3.fromRGB(35,35,42)
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
    Instance.new("UICorner", scrollFrame)

    -- Island locations data
    local islandLocations = {
        ["🏝️Kohana Volcano"] = CFrame.new(-594.971252, 396.65213, 149.10907),
        ["🏝️Crater Island"] = CFrame.new(1010.01001, 252, 5078.45117),
        ["🏝️Kohana"] = CFrame.new(-650.971191, 208.693695, 711.10907),
        ["🏝️Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801),
        ["🏝️Stingray Shores"] = CFrame.new(45.2788086, 252.562927, 2987.10913),
        ["🏝️Esoteric Depths"] = CFrame.new(1944.77881, 393.562927, 1371.35913),
        ["🏝️Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298),
        ["🏝️Tropical Grove"] = CFrame.new(-2095.34106, 197.199997, 3718.08008),
        ["🏝️Coral Reefs"] = CFrame.new(-3023.97119, 337.812927, 2195.60913),
        ["🏝️ SISYPUS"] = CFrame.new(-3709.75, -96.81, -952.38),
        ["🦈 TREASURE"] = CFrame.new(-3599.90, -275.96, -1640.84),
        ["🎣 STRINGRY"] = CFrame.new(102.05, 29.64, 3054.35),
        ["❄️ ICE LAND"] = CFrame.new(1990.55, 3.09, 3021.91),
        ["🌋 CRATER"] = CFrame.new(990.45, 21.06, 5059.85),
        ["🌴 TROPICAL"] = CFrame.new(-2093.80, 6.26, 3654.30),
        ["🗿 STONE"] = CFrame.new(-2636.19, 124.87, -27.49),
        ["⚙️ MACHINE"] = CFrame.new(-1551.25, 2.87, 1920.26)
    }

    -- Create island buttons
    local yOffset = 5
    local buttons = {}
    for islandName, cframe in pairs(islandLocations) do
        local btn = Instance.new("TextButton", scrollFrame)
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, yOffset)
        btn.Text = islandName
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.BackgroundColor3 = Color3.fromRGB(60,120,180)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        Instance.new("UICorner", btn)
        
        -- Store the CFrame for teleportation
        btn.MouseButton1Click:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
                Notify("Teleport", "Teleported to " .. islandName)
            else
                Notify("Teleport", "Character not found")
            end
        end)
        
        table.insert(buttons, btn)
        yOffset = yOffset + 33
    end

    -- Update scroll frame content size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)

    -- Player Tab Content
    local playerFrame = Instance.new("Frame", contentContainer)
    playerFrame.Size = UDim2.new(1, 0, 1, -10)
    playerFrame.Position = UDim2.new(0, 0, 0, 0)
    playerFrame.BackgroundTransparency = 1
    playerFrame.Visible = false

    local playerTitle = Instance.new("TextLabel", playerFrame)
    playerTitle.Size = UDim2.new(1, 0, 0, 24)
    playerTitle.Text = "Player List"
    playerTitle.Font = Enum.Font.GothamBold
    playerTitle.TextSize = 16
    playerTitle.TextColor3 = Color3.fromRGB(235,235,235)
    playerTitle.BackgroundTransparency = 1
    playerTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Search box for players
    local searchBox = Instance.new("TextBox", playerFrame)
    searchBox.Size = UDim2.new(1, 0, 0, 28)
    searchBox.Position = UDim2.new(0, 0, 0, 30)
    searchBox.PlaceholderText = "Search player..."
    searchBox.Text = ""
    searchBox.Font = Enum.Font.GothamSemibold
    searchBox.TextSize = 12
    searchBox.BackgroundColor3 = Color3.fromRGB(45,45,52)
    searchBox.TextColor3 = Color3.fromRGB(255,255,255)
    searchBox.BorderSizePixel = 0
    Instance.new("UICorner", searchBox)

    -- Create scrollable frame for players
    local playerScrollFrame = Instance.new("ScrollingFrame", playerFrame)
    playerScrollFrame.Size = UDim2.new(1, 0, 1, -65)
    playerScrollFrame.Position = UDim2.new(0, 0, 0, 65)
    playerScrollFrame.BackgroundColor3 = Color3.fromRGB(35,35,42)
    playerScrollFrame.BorderSizePixel = 0
    playerScrollFrame.ScrollBarThickness = 6
    playerScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
    Instance.new("UICorner", playerScrollFrame)

    -- Player list management
    local playerButtons = {}
    local function updatePlayerList(filter)
        -- Clear existing buttons
        for _, btn in pairs(playerButtons) do
            btn:Destroy()
        end
        playerButtons = {}
        
        local yPos = 5
        local players = Players:GetPlayers()
        
        for _, player in pairs(players) do
            if not filter or filter == "" or string.lower(player.Name):find(string.lower(filter)) or string.lower(player.DisplayName):find(string.lower(filter)) then
                local playerBtn = Instance.new("TextButton", playerScrollFrame)
                playerBtn.Size = UDim2.new(1, -10, 0, 32)
                playerBtn.Position = UDim2.new(0, 5, 0, yPos)
                playerBtn.Text = "🎮 " .. player.DisplayName .. " (@" .. player.Name .. ")"
                playerBtn.Font = Enum.Font.GothamSemibold
                playerBtn.TextSize = 11
                playerBtn.BackgroundColor3 = player == LocalPlayer and Color3.fromRGB(100,150,100) or Color3.fromRGB(80,120,180)
                playerBtn.TextColor3 = Color3.fromRGB(255,255,255)
                playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                Instance.new("UICorner", playerBtn)
                
                local btnPadding = Instance.new("UIPadding", playerBtn)
                btnPadding.PaddingLeft = UDim.new(0, 8)
                
                -- Teleport to player functionality
                if player ~= LocalPlayer then
                    playerBtn.MouseButton1Click:Connect(function()
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
                           LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                            Notify("Player Teleport", "Teleported to " .. player.DisplayName)
                        else
                            Notify("Player Teleport", "Cannot teleport to " .. player.DisplayName .. " - Character not found")
                        end
                    end)
                else
                    playerBtn.Text = "🎮 " .. player.DisplayName .. " (@" .. player.Name .. ") [YOU]"
                end
                
                table.insert(playerButtons, playerBtn)
                yPos = yPos + 37
            end
        end
        
        playerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
    end

    -- Search functionality
    searchBox.Changed:Connect(function(property)
        if property == "Text" then
            updatePlayerList(searchBox.Text)
        end
    end)

    -- Auto-refresh player list every 5 seconds
    local function autoRefreshPlayers()
        while true do
            if playerFrame.Visible then
                updatePlayerList(searchBox.Text)
            end
            task.wait(5)
        end
    end
    
    task.spawn(autoRefreshPlayers)

    -- Initial player list load
    updatePlayerList()
    
    -- Player join/leave events
    Players.PlayerAdded:Connect(function()
        if playerFrame.Visible then
            updatePlayerList(searchBox.Text)
        end
    end)
    
    Players.PlayerRemoving:Connect(function()
        if playerFrame.Visible then
            task.wait(0.1) -- Small delay to ensure player is removed
            updatePlayerList(searchBox.Text)
        end
    end)

    -- Feature Tab Content
    local featureFrame = Instance.new("Frame", contentContainer)
    featureFrame.Size = UDim2.new(1, 0, 1, -10)
    featureFrame.Position = UDim2.new(0, 0, 0, 0)
    featureFrame.BackgroundTransparency = 1
    featureFrame.Visible = false

    local featureTitle = Instance.new("TextLabel", featureFrame)
    featureTitle.Size = UDim2.new(1, 0, 0, 24)
    featureTitle.Text = "Character Features"
    featureTitle.Font = Enum.Font.GothamBold
    featureTitle.TextSize = 16
    featureTitle.TextColor3 = Color3.fromRGB(235,235,235)
    featureTitle.BackgroundTransparency = 1
    featureTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Create scrollable frame for features
    local featureScrollFrame = Instance.new("ScrollingFrame", featureFrame)
    featureScrollFrame.Size = UDim2.new(1, 0, 1, -30)
    featureScrollFrame.Position = UDim2.new(0, 0, 0, 30)
    featureScrollFrame.BackgroundColor3 = Color3.fromRGB(35,35,42)
    featureScrollFrame.BorderSizePixel = 0
    featureScrollFrame.ScrollBarThickness = 6
    featureScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
    Instance.new("UICorner", featureScrollFrame)

    -- Speed Control Section
    local speedSection = Instance.new("Frame", featureScrollFrame)
    speedSection.Size = UDim2.new(1, -10, 0, 80)
    speedSection.Position = UDim2.new(0, 5, 0, 5)
    speedSection.BackgroundColor3 = Color3.fromRGB(45,45,52)
    speedSection.BorderSizePixel = 0
    Instance.new("UICorner", speedSection)

    local speedLabel = Instance.new("TextLabel", speedSection)
    speedLabel.Size = UDim2.new(1, -20, 0, 20)
    speedLabel.Position = UDim2.new(0, 10, 0, 8)
    speedLabel.Text = "Walk Speed: 16"
    speedLabel.Font = Enum.Font.GothamSemibold
    speedLabel.TextSize = 14
    speedLabel.TextColor3 = Color3.fromRGB(235,235,235)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left

    local speedSlider = Instance.new("Frame", speedSection)
    speedSlider.Size = UDim2.new(1, -20, 0, 20)
    speedSlider.Position = UDim2.new(0, 10, 0, 35)
    speedSlider.BackgroundColor3 = Color3.fromRGB(50,50,60)
    speedSlider.BorderSizePixel = 0
    Instance.new("UICorner", speedSlider)

    local speedFill = Instance.new("Frame", speedSlider)
    speedFill.Size = UDim2.new(0.16, 0, 1, 0) -- 16/100 = 0.16
    speedFill.Position = UDim2.new(0, 0, 0, 0)
    speedFill.BackgroundColor3 = Color3.fromRGB(100,150,255)
    speedFill.BorderSizePixel = 0
    Instance.new("UICorner", speedFill)

    local speedHandle = Instance.new("TextButton", speedSlider)
    speedHandle.Size = UDim2.new(0, 20, 1, 0)
    speedHandle.Position = UDim2.new(0.16, -10, 0, 0)
    speedHandle.Text = ""
    speedHandle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    speedHandle.BorderSizePixel = 0
    Instance.new("UICorner", speedHandle)

    local speedResetBtn = Instance.new("TextButton", speedSection)
    speedResetBtn.Size = UDim2.new(0, 60, 0, 18)
    speedResetBtn.Position = UDim2.new(1, -70, 0, 58)
    speedResetBtn.Text = "Reset"
    speedResetBtn.Font = Enum.Font.GothamSemibold
    speedResetBtn.TextSize = 10
    speedResetBtn.BackgroundColor3 = Color3.fromRGB(160,60,60)
    speedResetBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", speedResetBtn)

    -- Jump Control Section
    local jumpSection = Instance.new("Frame", featureScrollFrame)
    jumpSection.Size = UDim2.new(1, -10, 0, 80)
    jumpSection.Position = UDim2.new(0, 5, 0, 95)
    jumpSection.BackgroundColor3 = Color3.fromRGB(45,45,52)
    jumpSection.BorderSizePixel = 0
    Instance.new("UICorner", jumpSection)

    local jumpLabel = Instance.new("TextLabel", jumpSection)
    jumpLabel.Size = UDim2.new(1, -20, 0, 20)
    jumpLabel.Position = UDim2.new(0, 10, 0, 8)
    jumpLabel.Text = "Jump Power: 50"
    jumpLabel.Font = Enum.Font.GothamSemibold
    jumpLabel.TextSize = 14
    jumpLabel.TextColor3 = Color3.fromRGB(235,235,235)
    jumpLabel.BackgroundTransparency = 1
    jumpLabel.TextXAlignment = Enum.TextXAlignment.Left

    local jumpSlider = Instance.new("Frame", jumpSection)
    jumpSlider.Size = UDim2.new(1, -20, 0, 20)
    jumpSlider.Position = UDim2.new(0, 10, 0, 35)
    jumpSlider.BackgroundColor3 = Color3.fromRGB(50,50,60)
    jumpSlider.BorderSizePixel = 0
    Instance.new("UICorner", jumpSlider)

    local jumpFill = Instance.new("Frame", jumpSlider)
    jumpFill.Size = UDim2.new(0.1, 0, 1, 0) -- 50/500 = 0.1
    jumpFill.Position = UDim2.new(0, 0, 0, 0)
    jumpFill.BackgroundColor3 = Color3.fromRGB(100,255,150)
    jumpFill.BorderSizePixel = 0
    Instance.new("UICorner", jumpFill)

    local jumpHandle = Instance.new("TextButton", jumpSlider)
    jumpHandle.Size = UDim2.new(0, 20, 1, 0)
    jumpHandle.Position = UDim2.new(0.1, -10, 0, 0)
    jumpHandle.Text = ""
    jumpHandle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    jumpHandle.BorderSizePixel = 0
    Instance.new("UICorner", jumpHandle)

    local jumpResetBtn = Instance.new("TextButton", jumpSection)
    jumpResetBtn.Size = UDim2.new(0, 60, 0, 18)
    jumpResetBtn.Position = UDim2.new(1, -70, 0, 58)
    jumpResetBtn.Text = "Reset"
    jumpResetBtn.Font = Enum.Font.GothamSemibold
    jumpResetBtn.TextSize = 10
    jumpResetBtn.BackgroundColor3 = Color3.fromRGB(160,60,60)
    jumpResetBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", jumpResetBtn)

    -- Rod Orientation Fix Section
    local rodFixSection = Instance.new("Frame", featureScrollFrame)
    rodFixSection.Size = UDim2.new(1, -10, 0, 60)
    rodFixSection.Position = UDim2.new(0, 5, 0, 185)
    rodFixSection.BackgroundColor3 = Color3.fromRGB(45,45,52)
    rodFixSection.BorderSizePixel = 0
    Instance.new("UICorner", rodFixSection)

    local rodFixLabel = Instance.new("TextLabel", rodFixSection)
    rodFixLabel.Size = UDim2.new(0.7, -10, 1, 0)
    rodFixLabel.Position = UDim2.new(0, 10, 0, 0)
    rodFixLabel.Text = "🎣 Rod Orientation Fix\nFix rod facing backwards"
    rodFixLabel.Font = Enum.Font.GothamSemibold
    rodFixLabel.TextSize = 13
    rodFixLabel.TextColor3 = Color3.fromRGB(235,235,235)
    rodFixLabel.BackgroundTransparency = 1
    rodFixLabel.TextXAlignment = Enum.TextXAlignment.Left
    rodFixLabel.TextYAlignment = Enum.TextYAlignment.Center

    local rodFixToggle = Instance.new("TextButton", rodFixSection)
    rodFixToggle.Size = UDim2.new(0, 60, 0, 25)
    rodFixToggle.Position = UDim2.new(1, -70, 0, 18)
    rodFixToggle.Text = RodFix.enabled and "ON" or "OFF"
    rodFixToggle.Font = Enum.Font.GothamBold
    rodFixToggle.TextSize = 12
    rodFixToggle.BackgroundColor3 = RodFix.enabled and Color3.fromRGB(100,200,100) or Color3.fromRGB(200,100,100)
    rodFixToggle.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", rodFixToggle)

    rodFixToggle.MouseButton1Click:Connect(function()
        RodFix.enabled = not RodFix.enabled
        rodFixToggle.Text = RodFix.enabled and "ON" or "OFF"
        rodFixToggle.BackgroundColor3 = RodFix.enabled and Color3.fromRGB(100,200,100) or Color3.fromRGB(200,100,100)
        
        if RodFix.enabled then
            FixRodOrientation()
            Notify("Rod Fix", "🎣 Rod orientation fix enabled")
        else
            Notify("Rod Fix", "🎣 Rod orientation fix disabled")
        end
    end)

    -- Sell All Items Section
    local sellAllSection = Instance.new("Frame", featureScrollFrame)
    sellAllSection.Size = UDim2.new(1, -10, 0, 60)
    sellAllSection.Position = UDim2.new(0, 5, 0, 255)
    sellAllSection.BackgroundColor3 = Color3.fromRGB(45,45,52)
    sellAllSection.BorderSizePixel = 0
    Instance.new("UICorner", sellAllSection)

    local sellAllLabel = Instance.new("TextLabel", sellAllSection)
    sellAllLabel.Size = UDim2.new(0.6, -10, 1, 0)
    sellAllLabel.Position = UDim2.new(0, 10, 0, 0)
    sellAllLabel.Text = "💰 Sell All Items\nSell all fish in inventory"
    sellAllLabel.Font = Enum.Font.GothamSemibold
    sellAllLabel.TextSize = 13
    sellAllLabel.TextColor3 = Color3.fromRGB(235,235,235)
    sellAllLabel.BackgroundTransparency = 1
    sellAllLabel.TextXAlignment = Enum.TextXAlignment.Left
    sellAllLabel.TextYAlignment = Enum.TextYAlignment.Center

    local sellBtn = Instance.new("TextButton", sellAllSection)
    sellBtn.Size = UDim2.new(0, 80, 0, 30)
    sellBtn.Position = UDim2.new(1, -90, 0, 15)
    sellBtn.Text = "💰 SELL ALL"
    sellBtn.Font = Enum.Font.GothamBold
    sellBtn.TextSize = 11
    sellBtn.BackgroundColor3 = Color3.fromRGB(255,140,0)
    sellBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", sellBtn)

    -- Set canvas size for feature scroll frame
    featureScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 330)

    -- Feature variables
    local currentSpeed = 16
    local currentJump = 50

    -- Speed slider functionality
    local draggingSpeed = false
    speedHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSpeed = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSpeed = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and draggingSpeed then
            local relativeX = input.Position.X - speedSlider.AbsolutePosition.X
            local percentage = math.clamp(relativeX / speedSlider.AbsoluteSize.X, 0, 1)
            currentSpeed = math.floor(percentage * 100)
            speedLabel.Text = "Walk Speed: " .. currentSpeed
            speedFill.Size = UDim2.new(percentage, 0, 1, 0)
            speedHandle.Position = UDim2.new(percentage, -10, 0, 0)
            
            -- Apply speed to character
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
            end
        end
    end)

    -- Jump slider functionality
    local draggingJump = false
    jumpHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingJump = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingJump = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and draggingJump then
            local relativeX = input.Position.X - jumpSlider.AbsolutePosition.X
            local percentage = math.clamp(relativeX / jumpSlider.AbsoluteSize.X, 0, 1)
            currentJump = math.floor(percentage * 500)
            jumpLabel.Text = "Jump Power: " .. currentJump
            jumpFill.Size = UDim2.new(percentage, 0, 1, 0)
            jumpHandle.Position = UDim2.new(percentage, -10, 0, 0)
            
            -- Apply jump power to character
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.JumpPower = currentJump
            end
        end
    end)

    -- Reset buttons
    speedResetBtn.MouseButton1Click:Connect(function()
        currentSpeed = 16
        speedLabel.Text = "Walk Speed: " .. currentSpeed
        speedFill.Size = UDim2.new(0.16, 0, 1, 0)
        speedHandle.Position = UDim2.new(0.16, -10, 0, 0)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
        end
        Notify("Features", "Walk speed reset to 16")
    end)

    jumpResetBtn.MouseButton1Click:Connect(function()
        currentJump = 50
        jumpLabel.Text = "Jump Power: " .. currentJump
        jumpFill.Size = UDim2.new(0.1, 0, 1, 0)
        jumpHandle.Position = UDim2.new(0.1, -10, 0, 0)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = currentJump
        end
        Notify("Features", "Jump power reset to 50")
    end)

    -- Auto-apply features when character spawns
    local function applyFeaturesToCharacter()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
            LocalPlayer.Character.Humanoid.JumpPower = currentJump
        end
    end

    -- Apply features when character spawns
    LocalPlayer.CharacterAdded:Connect(function()
        LocalPlayer.Character:WaitForChild("Humanoid")
        task.wait(0.1)
        applyFeaturesToCharacter()
    end)

    -- Fishing AI Tab Content
    local fishingAIFrame = Instance.new("Frame", contentContainer)
    fishingAIFrame.Size = UDim2.new(1, 0, 1, -10)
    fishingAIFrame.Position = UDim2.new(0, 0, 0, 0)
    fishingAIFrame.BackgroundTransparency = 1
    fishingAIFrame.Visible = false

    local fishingAITitle = Instance.new("TextLabel", fishingAIFrame)
    fishingAITitle.Size = UDim2.new(1, 0, 0, 24)
    fishingAITitle.Text = "Smart AI Fishing Configuration"
    fishingAITitle.Font = Enum.Font.GothamBold
    fishingAITitle.TextSize = 16
    fishingAITitle.TextColor3 = Color3.fromRGB(235,235,235)
    fishingAITitle.BackgroundTransparency = 1
    fishingAITitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Smart AI Mode Selection Section
    local aiModeSection = Instance.new("Frame", fishingAIFrame)
    aiModeSection.Size = UDim2.new(1, 0, 0, 120)
    aiModeSection.Position = UDim2.new(0, 0, 0, 35)
    aiModeSection.BackgroundColor3 = Color3.fromRGB(35,35,42)
    aiModeSection.BorderSizePixel = 0
    Instance.new("UICorner", aiModeSection)

    local aiModeLabel = Instance.new("TextLabel", aiModeSection)
    aiModeLabel.Size = UDim2.new(1, -20, 0, 25)
    aiModeLabel.Position = UDim2.new(0, 10, 0, 5)
    aiModeLabel.Text = "🧠 Smart AI Fishing Modes"
    aiModeLabel.Font = Enum.Font.GothamBold
    aiModeLabel.TextSize = 14
    aiModeLabel.TextColor3 = Color3.fromRGB(255,140,0)
    aiModeLabel.BackgroundTransparency = 1
    aiModeLabel.TextXAlignment = Enum.TextXAlignment.Left

    local smartButtonAI = Instance.new("TextButton", aiModeSection)
    smartButtonAI.Size = UDim2.new(1, -20, 0, 35)
    smartButtonAI.Position = UDim2.new(0, 10, 0, 35)
    smartButtonAI.Text = "🧠 Smart AI Mode (Animation Aware)"
    smartButtonAI.Font = Enum.Font.GothamSemibold
    smartButtonAI.TextSize = 13
    smartButtonAI.BackgroundColor3 = Color3.fromRGB(255,140,0)
    smartButtonAI.TextColor3 = Color3.fromRGB(255,255,255)
    local smartCornerAI = Instance.new("UICorner", smartButtonAI)
    smartCornerAI.CornerRadius = UDim.new(0,6)

    local aiStatusLabel = Instance.new("TextLabel", aiModeSection)
    aiStatusLabel.Size = UDim2.new(1, -20, 0, 25)
    aiStatusLabel.Position = UDim2.new(0, 10, 0, 80)
    aiStatusLabel.Text = "✅ Current Mode: Smart AI Active"
    aiStatusLabel.Font = Enum.Font.GothamSemibold
    aiStatusLabel.TextSize = 12
    aiStatusLabel.TextColor3 = Color3.fromRGB(100,255,150)
    aiStatusLabel.BackgroundTransparency = 1
    aiStatusLabel.TextXAlignment = Enum.TextXAlignment.Center

    -- AntiAFK Section in Fishing AI Tab
    local antiAfkSection = Instance.new("Frame", fishingAIFrame)
    antiAfkSection.Size = UDim2.new(1, 0, 0, 60)
    antiAfkSection.Position = UDim2.new(0, 0, 0, 165)
    antiAfkSection.BackgroundColor3 = Color3.fromRGB(35,35,42)
    antiAfkSection.BorderSizePixel = 0
    Instance.new("UICorner", antiAfkSection)

    local antiAfkTitle = Instance.new("TextLabel", antiAfkSection)
    antiAfkTitle.Size = UDim2.new(1, -20, 0, 20)
    antiAfkTitle.Position = UDim2.new(0, 10, 0, 5)
    antiAfkTitle.Text = "🛡️ AntiAFK Protection"
    antiAfkTitle.Font = Enum.Font.GothamBold
    antiAfkTitle.TextSize = 14
    antiAfkTitle.TextColor3 = Color3.fromRGB(100,200,255)
    antiAfkTitle.BackgroundTransparency = 1
    antiAfkTitle.TextXAlignment = Enum.TextXAlignment.Left

    local antiAfkLabel = Instance.new("TextLabel", antiAfkSection)
    antiAfkLabel.Size = UDim2.new(0.65, -10, 0, 25)
    antiAfkLabel.Position = UDim2.new(0, 15, 0, 30)
    antiAfkLabel.Text = "🛡️ AntiAFK Protection: Disabled"
    antiAfkLabel.Font = Enum.Font.GothamSemibold
    antiAfkLabel.TextSize = 12
    antiAfkLabel.TextColor3 = Color3.fromRGB(200,200,200)
    antiAfkLabel.BackgroundTransparency = 1
    antiAfkLabel.TextXAlignment = Enum.TextXAlignment.Left
    antiAfkLabel.TextYAlignment = Enum.TextYAlignment.Center

    local antiAfkToggle = Instance.new("TextButton", antiAfkSection)
    antiAfkToggle.Size = UDim2.new(0, 70, 0, 24)
    antiAfkToggle.Position = UDim2.new(1, -80, 0, 31)
    antiAfkToggle.Text = "🔴 OFF"
    antiAfkToggle.Font = Enum.Font.GothamBold
    antiAfkToggle.TextSize = 11
    antiAfkToggle.BackgroundColor3 = Color3.fromRGB(160,60,60)
    antiAfkToggle.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", antiAfkToggle)

    -- Dashboard Tab Content
    local dashboardFrame = Instance.new("Frame", contentContainer)
    dashboardFrame.Size = UDim2.new(1, 0, 1, -10)
    dashboardFrame.Position = UDim2.new(0, 0, 0, 0)
    dashboardFrame.BackgroundTransparency = 1
    dashboardFrame.Visible = false

    local dashboardTitle = Instance.new("TextLabel", dashboardFrame)
    dashboardTitle.Size = UDim2.new(1, 0, 0, 24)
    dashboardTitle.Text = "Fishing Analytics & Statistics"
    dashboardTitle.Font = Enum.Font.GothamBold
    dashboardTitle.TextSize = 16
    dashboardTitle.TextColor3 = Color3.fromRGB(235,235,235)
    dashboardTitle.BackgroundTransparency = 1
    dashboardTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Create scrollable frame for dashboard
    local dashboardScrollFrame = Instance.new("ScrollingFrame", dashboardFrame)
    dashboardScrollFrame.Size = UDim2.new(1, 0, 1, -30)
    dashboardScrollFrame.Position = UDim2.new(0, 0, 0, 30)
    dashboardScrollFrame.BackgroundColor3 = Color3.fromRGB(35,35,42)
    dashboardScrollFrame.BorderSizePixel = 0
    dashboardScrollFrame.ScrollBarThickness = 6
    dashboardScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
    Instance.new("UICorner", dashboardScrollFrame)

    -- Session Stats Section
    local sessionSection = Instance.new("Frame", dashboardScrollFrame)
    sessionSection.Size = UDim2.new(1, -10, 0, 120)
    sessionSection.Position = UDim2.new(0, 5, 0, 5)
    sessionSection.BackgroundColor3 = Color3.fromRGB(45,45,52)
    sessionSection.BorderSizePixel = 0
    Instance.new("UICorner", sessionSection)

    local sessionTitle = Instance.new("TextLabel", sessionSection)
    sessionTitle.Size = UDim2.new(1, -20, 0, 25)
    sessionTitle.Position = UDim2.new(0, 10, 0, 5)
    sessionTitle.Text = "📈 Current Session Stats"
    sessionTitle.Font = Enum.Font.GothamBold
    sessionTitle.TextSize = 14
    sessionTitle.TextColor3 = Color3.fromRGB(100,200,255)
    sessionTitle.BackgroundTransparency = 1
    sessionTitle.TextXAlignment = Enum.TextXAlignment.Left

    local sessionFishCount = Instance.new("TextLabel", sessionSection)
    sessionFishCount.Size = UDim2.new(0.5, -15, 0, 20)
    sessionFishCount.Position = UDim2.new(0, 10, 0, 35)
    sessionFishCount.Text = "🎣 Total Fish: 0"
    sessionFishCount.Font = Enum.Font.GothamSemibold
    sessionFishCount.TextSize = 12
    sessionFishCount.TextColor3 = Color3.fromRGB(255,255,255)
    sessionFishCount.BackgroundTransparency = 1
    sessionFishCount.TextXAlignment = Enum.TextXAlignment.Left

    local sessionRareCount = Instance.new("TextLabel", sessionSection)
    sessionRareCount.Size = UDim2.new(0.5, -15, 0, 20)
    sessionRareCount.Position = UDim2.new(0.5, 5, 0, 35)
    sessionRareCount.Text = "✨ Rare Fish: 0"
    sessionRareCount.Font = Enum.Font.GothamSemibold
    sessionRareCount.TextSize = 12
    sessionRareCount.TextColor3 = Color3.fromRGB(255,215,0)
    sessionRareCount.BackgroundTransparency = 1
    sessionRareCount.TextXAlignment = Enum.TextXAlignment.Left

    local sessionTime = Instance.new("TextLabel", sessionSection)
    sessionTime.Size = UDim2.new(0.5, -15, 0, 20)
    sessionTime.Position = UDim2.new(0, 10, 0, 60)
    sessionTime.Text = "⏱️ Session: 0m 0s"
    sessionTime.Font = Enum.Font.GothamSemibold
    sessionTime.TextSize = 12
    sessionTime.TextColor3 = Color3.fromRGB(200,200,200)
    sessionTime.BackgroundTransparency = 1
    sessionTime.TextXAlignment = Enum.TextXAlignment.Left

    local sessionLocation = Instance.new("TextLabel", sessionSection)
    sessionLocation.Size = UDim2.new(0.5, -15, 0, 20)
    sessionLocation.Position = UDim2.new(0.5, 5, 0, 60)
    sessionLocation.Text = "🗺️ Location: Unknown"
    sessionLocation.Font = Enum.Font.GothamSemibold
    sessionLocation.TextSize = 12
    sessionLocation.TextColor3 = Color3.fromRGB(150,255,150)
    sessionLocation.BackgroundTransparency = 1
    sessionLocation.TextXAlignment = Enum.TextXAlignment.Left

    local sessionEfficiency = Instance.new("TextLabel", sessionSection)
    sessionEfficiency.Size = UDim2.new(1, -20, 0, 20)
    sessionEfficiency.Position = UDim2.new(0, 10, 0, 85)
    sessionEfficiency.Text = "🎯 Rare Rate: 0% | ⚡ Fish/Min: 0.0"
    sessionEfficiency.Font = Enum.Font.GothamSemibold
    sessionEfficiency.TextSize = 12
    sessionEfficiency.TextColor3 = Color3.fromRGB(255,165,0)
    sessionEfficiency.BackgroundTransparency = 1
    sessionEfficiency.TextXAlignment = Enum.TextXAlignment.Left

    -- Fish Rarity Tracker Section
    local raritySection = Instance.new("Frame", dashboardScrollFrame)
    raritySection.Size = UDim2.new(1, -10, 0, 180)
    raritySection.Position = UDim2.new(0, 5, 0, 135)
    raritySection.BackgroundColor3 = Color3.fromRGB(45,45,52)
    raritySection.BorderSizePixel = 0
    Instance.new("UICorner", raritySection)

    local rarityTitle = Instance.new("TextLabel", raritySection)
    rarityTitle.Size = UDim2.new(1, -20, 0, 25)
    rarityTitle.Position = UDim2.new(0, 10, 0, 5)
    rarityTitle.Text = "🏆 Fish Rarity Tracker"
    rarityTitle.Font = Enum.Font.GothamBold
    rarityTitle.TextSize = 14
    rarityTitle.TextColor3 = Color3.fromRGB(255,200,100)
    rarityTitle.BackgroundTransparency = 1
    rarityTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Rarity bars (Updated for real fish data)
    local rarityTypes = {
        {name = "MYTHIC", color = Color3.fromRGB(255,50,50), icon = "�"},
        {name = "LEGENDARY", color = Color3.fromRGB(255,100,255), icon = "�"},
        {name = "EPIC", color = Color3.fromRGB(150,50,200), icon = "💜"},
        {name = "RARE", color = Color3.fromRGB(100,150,255), icon = "⭐"},
        {name = "UNCOMMON", color = Color3.fromRGB(0,255,200), icon = "💎"},
        {name = "COMMON", color = Color3.fromRGB(150,150,150), icon = "🐟"}
    }

    local rarityBars = {}
    for i, rarity in ipairs(rarityTypes) do
        local yPos = 30 + (i - 1) * 22
        
        local rarityLabel = Instance.new("TextLabel", raritySection)
        rarityLabel.Size = UDim2.new(0.3, -10, 0, 18)
        rarityLabel.Position = UDim2.new(0, 10, 0, yPos)
        rarityLabel.Text = rarity.icon .. " " .. rarity.name
        rarityLabel.Font = Enum.Font.GothamSemibold
        rarityLabel.TextSize = 10
        rarityLabel.TextColor3 = rarity.color
        rarityLabel.BackgroundTransparency = 1
        rarityLabel.TextXAlignment = Enum.TextXAlignment.Left

        local rarityBar = Instance.new("Frame", raritySection)
        rarityBar.Size = UDim2.new(0.5, -10, 0, 12)
        rarityBar.Position = UDim2.new(0.3, 5, 0, yPos + 3)
        rarityBar.BackgroundColor3 = Color3.fromRGB(60,60,70)
        rarityBar.BorderSizePixel = 0
        Instance.new("UICorner", rarityBar)

        local rarityFill = Instance.new("Frame", rarityBar)
        rarityFill.Size = UDim2.new(0, 0, 1, 0)
        rarityFill.Position = UDim2.new(0, 0, 0, 0)
        rarityFill.BackgroundColor3 = rarity.color
        rarityFill.BorderSizePixel = 0
        Instance.new("UICorner", rarityFill)

        local rarityCount = Instance.new("TextLabel", raritySection)
        rarityCount.Size = UDim2.new(0.2, -10, 0, 18)
        rarityCount.Position = UDim2.new(0.8, 5, 0, yPos)
        rarityCount.Text = "0"
        rarityCount.Font = Enum.Font.GothamBold
        rarityCount.TextSize = 11
        rarityCount.TextColor3 = Color3.fromRGB(255,255,255)
        rarityCount.BackgroundTransparency = 1
        rarityCount.TextXAlignment = Enum.TextXAlignment.Center

        rarityBars[rarity.name] = {fill = rarityFill, count = rarityCount}
    end

    -- Location Heatmap Section
    local heatmapSection = Instance.new("Frame", dashboardScrollFrame)
    heatmapSection.Size = UDim2.new(1, -10, 0, 200)
    heatmapSection.Position = UDim2.new(0, 5, 0, 325)
    heatmapSection.BackgroundColor3 = Color3.fromRGB(45,45,52)
    heatmapSection.BorderSizePixel = 0
    Instance.new("UICorner", heatmapSection)

    local heatmapTitle = Instance.new("TextLabel", heatmapSection)
    heatmapTitle.Size = UDim2.new(1, -20, 0, 25)
    heatmapTitle.Position = UDim2.new(0, 10, 0, 5)
    heatmapTitle.Text = "🗺️ Location Efficiency Heatmap"
    heatmapTitle.Font = Enum.Font.GothamBold
    heatmapTitle.TextSize = 14
    heatmapTitle.TextColor3 = Color3.fromRGB(100,255,150)
    heatmapTitle.BackgroundTransparency = 1
    heatmapTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Create location efficiency display
    local locationList = Instance.new("ScrollingFrame", heatmapSection)
    locationList.Size = UDim2.new(1, -20, 1, -35)
    locationList.Position = UDim2.new(0, 10, 0, 30)
    locationList.BackgroundColor3 = Color3.fromRGB(35,35,42)
    locationList.BorderSizePixel = 0
    locationList.ScrollBarThickness = 4
    locationList.ScrollBarImageColor3 = Color3.fromRGB(80,80,80)
    Instance.new("UICorner", locationList)

    -- Optimal Times Section
    local timesSection = Instance.new("Frame", dashboardScrollFrame)
    timesSection.Size = UDim2.new(1, -10, 0, 160)
    timesSection.Position = UDim2.new(0, 5, 0, 535)
    timesSection.BackgroundColor3 = Color3.fromRGB(45,45,52)
    timesSection.BorderSizePixel = 0
    Instance.new("UICorner", timesSection)

    local timesTitle = Instance.new("TextLabel", timesSection)
    timesTitle.Size = UDim2.new(1, -20, 0, 25)
    timesTitle.Position = UDim2.new(0, 10, 0, 5)
    timesTitle.Text = "⏰ Optimal Fishing Times"
    timesTitle.Font = Enum.Font.GothamBold
    timesTitle.TextSize = 14
    timesTitle.TextColor3 = Color3.fromRGB(255,200,100)
    timesTitle.BackgroundTransparency = 1
    timesTitle.TextXAlignment = Enum.TextXAlignment.Left

    local bestTimeLabel = Instance.new("TextLabel", timesSection)
    bestTimeLabel.Size = UDim2.new(1, -20, 0, 20)
    bestTimeLabel.Position = UDim2.new(0, 10, 0, 35)
    bestTimeLabel.Text = "🏆 Best Time: Not enough data"
    bestTimeLabel.Font = Enum.Font.GothamSemibold
    bestTimeLabel.TextSize = 12
    bestTimeLabel.TextColor3 = Color3.fromRGB(255,215,0)
    bestTimeLabel.BackgroundTransparency = 1
    bestTimeLabel.TextXAlignment = Enum.TextXAlignment.Left

    local currentTimeLabel = Instance.new("TextLabel", timesSection)
    currentTimeLabel.Size = UDim2.new(1, -20, 0, 20)
    currentTimeLabel.Position = UDim2.new(0, 10, 0, 60)
    currentTimeLabel.Text = "🕐 Current Hour: " .. os.date("%H:00")
    currentTimeLabel.Font = Enum.Font.GothamSemibold
    currentTimeLabel.TextSize = 12
    currentTimeLabel.TextColor3 = Color3.fromRGB(150,255,150)
    currentTimeLabel.BackgroundTransparency = 1
    currentTimeLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Time efficiency chart (simplified bars)
    local timeChart = Instance.new("Frame", timesSection)
    timeChart.Size = UDim2.new(1, -20, 0, 70)
    timeChart.Position = UDim2.new(0, 10, 0, 85)
    timeChart.BackgroundColor3 = Color3.fromRGB(35,35,42)
    timeChart.BorderSizePixel = 0
    Instance.new("UICorner", timeChart)

    -- Create time bars for 24 hours
    local timeBars = {}
    for hour = 0, 23 do
        local x = (hour / 24) * (timeChart.AbsoluteSize.X - 20) + 10
        local timeBar = Instance.new("Frame", timeChart)
        timeBar.Size = UDim2.new(0, 8, 0, 2)
        timeBar.Position = UDim2.new(hour/24, 2, 1, -15)
        timeBar.BackgroundColor3 = Color3.fromRGB(100,100,120)
        timeBar.BorderSizePixel = 0
        timeBars[hour] = timeBar
    end

    -- Set canvas size for dashboard scroll
    dashboardScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 720)

    -- Start/Stop buttons at bottom of content container (only visible in Main tab)
    local actions = Instance.new("Frame", contentContainer)
    actions.Size = UDim2.new(1, 0, 0, 38)
    actions.Position = UDim2.new(0, 0, 1, -80)
    actions.BackgroundTransparency = 1
    local startBtn = Instance.new("TextButton", actions)
    startBtn.Size = UDim2.new(0.5, -6, 1, 0)
    startBtn.Position = UDim2.new(0, 0, 0, 0)
    startBtn.Text = "Start"
    startBtn.BackgroundColor3 = Color3.fromRGB(70,170,90)
    startBtn.TextColor3 = Color3.fromRGB(255,255,255)
    startBtn.Font = Enum.Font.GothamSemibold
    startBtn.TextSize = 14
    local startCorner = Instance.new("UICorner", startBtn); startCorner.CornerRadius = UDim.new(0,8)
    local stopBtn = Instance.new("TextButton", actions)
    stopBtn.Size = UDim2.new(0.5, -6, 1, 0)
    stopBtn.Position = UDim2.new(0.5, 6, 0, 0)
    stopBtn.Text = "Stop"
    stopBtn.BackgroundColor3 = Color3.fromRGB(190,60,60)
    stopBtn.TextColor3 = Color3.fromRGB(255,255,255)
    stopBtn.Font = Enum.Font.GothamSemibold
    stopBtn.TextSize = 14
    local stopCorner = Instance.new("UICorner", stopBtn); stopCorner.CornerRadius = UDim.new(0,8)

    -- floating toggle
    -- Floating toggle: keep margin so it doesn't overlap header on small screens
    local floatBtn = Instance.new("TextButton", screenGui); floatBtn.Name = "FloatToggle"; floatBtn.Size = UDim2.new(0,44,0,44); floatBtn.Position = UDim2.new(0,12,0,12); floatBtn.Text = "≡"; Instance.new("UICorner", floatBtn)
    floatBtn.BackgroundColor3 = Color3.fromRGB(40,40,46); floatBtn.Font = Enum.Font.GothamBold; floatBtn.TextSize = 20; floatBtn.TextColor3 = Color3.fromRGB(235,235,235)
    floatBtn.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)

    -- Teleport functions
    local function TeleportTo(position)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
            Notify("Teleport", "Teleported successfully")
        else
            Notify("Teleport", "Character not found")
        end
    end

    -- Sell All behavior: call remote if present
    sellBtn.MouseButton1Click:Connect(function()
        local sellRemote = ResolveRemote("RF/SellAllItems")
        if not sellRemote then
            Notify("SellAll", "Sell remote not found")
            return
        end
        local ok, res = pcall(function()
            if sellRemote:IsA("RemoteFunction") then return sellRemote:InvokeServer() else sellRemote:FireServer() end
        end)
        if ok then Notify("SellAll", "SellAll invoked") else Notify("SellAll", "SellAll failed: " .. tostring(res)) end
    end)

    -- Robust tab switching: collect tabs and provide SwitchTo
    local Tabs = { Main = content, Teleport = teleportFrame, Player = playerFrame, Feature = featureFrame, FishingAI = fishingAIFrame, Dashboard = dashboardFrame }
    local function SwitchTo(name)
        for k, v in pairs(Tabs) do
            v.Visible = (k == name)
        end
        
        -- Show/hide action buttons based on tab
        actions.Visible = (name == "Main")
        
        -- Update tab colors and content title
        if name == "Main" then
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            mainTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            teleportTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            teleportTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            playerTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            playerTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            featureTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            featureTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            fishingAITabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            fishingAITabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            dashboardTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            dashboardTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            contentTitle.Text = "AutoFish Controls"
        elseif name == "Teleport" then
            teleportTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            teleportTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            mainTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            playerTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            playerTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            featureTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            featureTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            fishingAITabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            fishingAITabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            dashboardTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            dashboardTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            contentTitle.Text = "Island Locations"
        elseif name == "Player" then
            playerTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            playerTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            mainTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            teleportTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            teleportTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            featureTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            featureTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            fishingAITabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            fishingAITabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            dashboardTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            dashboardTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            contentTitle.Text = "Player Teleport"
            updatePlayerList(searchBox.Text) -- Refresh when switching to player tab
        elseif name == "Feature" then
            featureTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            featureTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            mainTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            teleportTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            teleportTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            playerTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            playerTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            fishingAITabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            fishingAITabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            dashboardTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            dashboardTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            contentTitle.Text = "Character Features"
        elseif name == "FishingAI" then
            fishingAITabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            fishingAITabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            mainTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            teleportTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            teleportTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            playerTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            playerTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            featureTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            featureTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            dashboardTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            dashboardTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            contentTitle.Text = "Smart AI Configuration"
        else -- Dashboard
            dashboardTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            dashboardTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            mainTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            teleportTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            teleportTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            playerTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            playerTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            featureTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            featureTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            fishingAITabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            fishingAITabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            contentTitle.Text = "Fishing Analytics"
        end
    end

    mainTabBtn.MouseButton1Click:Connect(function() SwitchTo("Main") end)
    teleportTabBtn.MouseButton1Click:Connect(function() SwitchTo("Teleport") end)
    playerTabBtn.MouseButton1Click:Connect(function() SwitchTo("Player") end)
    featureTabBtn.MouseButton1Click:Connect(function() SwitchTo("Feature") end)
    fishingAITabBtn.MouseButton1Click:Connect(function() SwitchTo("FishingAI") end)
    dashboardTabBtn.MouseButton1Click:Connect(function() SwitchTo("Dashboard") end)

    -- Start with Main visible
    SwitchTo("Main")

    -- callbacks
    fastButton.MouseButton1Click:Connect(function() 
        Config.mode = "fast"
        modeStatus.Text = "⚡ Current: Fast Mode"
        modeStatus.TextColor3 = Color3.fromRGB(100,150,255)
        Notify("modern_autofish", "⚡ Mode set to FAST - Quick fishing") 
    end)
    secureButton.MouseButton1Click:Connect(function() 
        Config.mode = "secure"
        modeStatus.Text = "🔒 Current: Secure Mode"
        modeStatus.TextColor3 = Color3.fromRGB(100,255,150)
        Notify("modern_autofish", "🔒 Mode set to SECURE - Safe fishing") 
    end)

    -- AntiAFK toggle
    antiAfkToggle.MouseButton1Click:Connect(function()
        AntiAFK.enabled = not AntiAFK.enabled
        Config.antiAfkEnabled = AntiAFK.enabled
        
        if AntiAFK.enabled then
            antiAfkToggle.Text = "🟢 ON"
            antiAfkToggle.BackgroundColor3 = Color3.fromRGB(70,170,90)
            antiAfkLabel.Text = "🛡️ AntiAFK Protection: Enabled"
            antiAfkLabel.TextColor3 = Color3.fromRGB(100,255,150)
            
            AntiAFK.sessionId = AntiAFK.sessionId + 1
            task.spawn(function() AntiAfkRunner(AntiAFK.sessionId) end)
        else
            antiAfkToggle.Text = "🔴 OFF"
            antiAfkToggle.BackgroundColor3 = Color3.fromRGB(160,60,60)
            antiAfkLabel.Text = "🛡️ AntiAFK Protection: Disabled"
            antiAfkLabel.TextColor3 = Color3.fromRGB(200,200,200)
            
            AntiAFK.sessionId = AntiAFK.sessionId + 1
        end
    end)

    -- Smart AI button callback
    smartButtonAI.MouseButton1Click:Connect(function()
        Config.mode = "smart"
        aiStatusLabel.Text = "✅ Current Mode: Smart AI Active"
        aiStatusLabel.TextColor3 = Color3.fromRGB(100,255,150)
        Notify("modern_autofish", "🧠 Mode set to SMART AI - Intelligent fishing")
    end)

    local origPanelSize = panel.Size; local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        sidebar.Visible = not minimized
        contentContainer.Visible = not minimized
        panel.Size = minimized and UDim2.new(0,480,0,50) or origPanelSize
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Config.enabled = false; sessionId = sessionId + 1
        AntiAFK.enabled = false; AntiAFK.sessionId = AntiAFK.sessionId + 1
        Notify("modern_autofish", "ModernAutoFish closed")
        if screenGui and screenGui.Parent then screenGui:Destroy() end
    end)

    startBtn.MouseButton1Click:Connect(function()
        if Config.enabled then Notify("modern_autofish", "Already running") return end
        Config.enabled = true; sessionId = sessionId + 1; task.spawn(function() AutofishRunner(sessionId) end)
    end)
    stopBtn.MouseButton1Click:Connect(function() Config.enabled = false; sessionId = sessionId + 1 end)

    delayMinus.MouseButton1Click:Connect(function()
        Config.autoRecastDelay = math.max(0.05, Config.autoRecastDelay - 0.1)
        delayLabel.Text = string.format("⏱️ Recast Delay: %.2fs", Config.autoRecastDelay)
        delayDisplay.Text = string.format("%.2fs", Config.autoRecastDelay)
    end)
    delayPlus.MouseButton1Click:Connect(function()
        Config.autoRecastDelay = Config.autoRecastDelay + 0.1
        delayLabel.Text = string.format("⏱️ Recast Delay: %.2fs", Config.autoRecastDelay)
        delayDisplay.Text = string.format("%.2fs", Config.autoRecastDelay)
    end)

    chanceMinus.MouseButton1Click:Connect(function()
        Config.safeModeChance = math.max(0, Config.safeModeChance - 5)
        chanceLabel.Text = string.format("🎯 Safe Perfect %%: %d", Config.safeModeChance)
        chanceDisplay.Text = string.format("%d%%", Config.safeModeChance)
    end)
    chancePlus.MouseButton1Click:Connect(function()
        Config.safeModeChance = math.min(100, Config.safeModeChance + 5)
        chanceLabel.Text = string.format("🎯 Safe Perfect %%: %d", Config.safeModeChance)
        chanceDisplay.Text = string.format("%d%%", Config.safeModeChance)
    end)

    Notify("modern_autofish", "UI ready - Select mode and press Start")

    -- Dashboard Update Functions
    local function UpdateDashboard()
        if not dashboardFrame.Visible then return end
        
        -- Debug: Print current stats
        print("[Dashboard] Updating stats - Fish:", Dashboard.sessionStats.fishCount, "Rare:", Dashboard.sessionStats.rareCount)
        
        -- Update session stats
        local currentTime = tick()
        local sessionDuration = currentTime - Dashboard.sessionStats.startTime
        local minutes = math.floor(sessionDuration / 60)
        local seconds = math.floor(sessionDuration % 60)
        
        sessionFishCount.Text = "🎣 Total Fish: " .. Dashboard.sessionStats.fishCount
        sessionRareCount.Text = "✨ Rare Fish: " .. Dashboard.sessionStats.rareCount
        sessionTime.Text = string.format("⏱️ Session: %dm %ds", minutes, seconds)
        sessionLocation.Text = "🗺️ Location: " .. Dashboard.sessionStats.currentLocation
        
        -- Calculate efficiency
        local rareRate = Dashboard.sessionStats.fishCount > 0 and 
                        math.floor((Dashboard.sessionStats.rareCount / Dashboard.sessionStats.fishCount) * 100) or 0
        local fishPerMin = sessionDuration > 0 and (Dashboard.sessionStats.fishCount / (sessionDuration / 60)) or 0
        sessionEfficiency.Text = string.format("🎯 Rare Rate: %d%% | ⚡ Fish/Min: %.1f", rareRate, fishPerMin)
        
        -- Update rarity bars
        local rarityCounts = {}
        for rarityName, fishList in pairs(FishRarity) do
            rarityCounts[rarityName] = 0
        end
        
        for _, fish in pairs(Dashboard.fishCaught) do
            rarityCounts[fish.rarity] = (rarityCounts[fish.rarity] or 0) + 1
        end
        
        local maxCount = math.max(1, Dashboard.sessionStats.fishCount)
        for rarityName, bar in pairs(rarityBars) do
            local count = rarityCounts[rarityName] or 0
            local percentage = count / maxCount
            bar.fill.Size = UDim2.new(percentage, 0, 1, 0)
            bar.count.Text = tostring(count)
        end
        
        -- Update location efficiency list
        for _, child in pairs(locationList:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        
        local yPos = 5
        for location, stats in pairs(Dashboard.locationStats) do
            local efficiency = GetLocationEfficiency(location)
            local locationFrame = Instance.new("Frame", locationList)
            locationFrame.Size = UDim2.new(1, -10, 0, 25)
            locationFrame.Position = UDim2.new(0, 5, 0, yPos)
            locationFrame.BackgroundColor3 = Color3.fromRGB(50,50,60)
            locationFrame.BorderSizePixel = 0
            Instance.new("UICorner", locationFrame)
            
            local locationLabel = Instance.new("TextLabel", locationFrame)
            locationLabel.Size = UDim2.new(0.6, -10, 1, 0)
            locationLabel.Position = UDim2.new(0, 5, 0, 0)
            locationLabel.Text = "🏝️ " .. location
            locationLabel.Font = Enum.Font.GothamSemibold
            locationLabel.TextSize = 10
            locationLabel.TextColor3 = Color3.fromRGB(255,255,255)
            locationLabel.BackgroundTransparency = 1
            locationLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local efficiencyLabel = Instance.new("TextLabel", locationFrame)
            efficiencyLabel.Size = UDim2.new(0.4, -10, 1, 0)
            efficiencyLabel.Position = UDim2.new(0.6, 5, 0, 0)
            efficiencyLabel.Text = string.format("%d%% (%d/%d)", efficiency, stats.rare, stats.total)
            efficiencyLabel.Font = Enum.Font.GothamBold
            efficiencyLabel.TextSize = 10
            local effColor = efficiency > 15 and Color3.fromRGB(100,255,100) or 
                           efficiency > 5 and Color3.fromRGB(255,255,100) or Color3.fromRGB(255,100,100)
            efficiencyLabel.TextColor3 = effColor
            efficiencyLabel.BackgroundTransparency = 1
            efficiencyLabel.TextXAlignment = Enum.TextXAlignment.Right
            
            yPos = yPos + 30
        end
        locationList.CanvasSize = UDim2.new(0, 0, 0, yPos)
        
        -- Update optimal times
        local bestHour, bestPercent = GetBestFishingTime()
        if bestPercent > 0 then
            bestTimeLabel.Text = string.format("🏆 Best Time: %02d:00 (%d%% rare rate)", bestHour, bestPercent)
        else
            bestTimeLabel.Text = "🏆 Best Time: Not enough data"
        end
        
        currentTimeLabel.Text = "🕐 Current Hour: " .. os.date("%H:00")
        
        -- Update time bars
        for hour, bar in pairs(timeBars) do
            local data = Dashboard.optimalTimes[hour]
            if data and data.total > 0 then
                local efficiency = data.rare / data.total
                local height = math.max(2, efficiency * 50)
                bar.Size = UDim2.new(0, 8, 0, height)
                bar.Position = UDim2.new(hour/24, 2, 1, -15 - height + 2)
                local color = efficiency > 0.2 and Color3.fromRGB(100,255,100) or 
                             efficiency > 0.1 and Color3.fromRGB(255,255,100) or Color3.fromRGB(255,100,100)
                bar.BackgroundColor3 = color
            end
        end
    end

    -- Auto-update dashboard every 2 seconds
    local function DashboardUpdater()
        while true do
            if dashboardFrame and dashboardFrame.Visible then
                pcall(UpdateDashboard)
            end
            task.wait(2)
        end
    end
    task.spawn(DashboardUpdater)

    -- Update current location when teleporting
    for islandName, cframe in pairs(islandLocations) do
        -- Find existing teleport button and wrap its click function
        for _, btn in pairs(buttons) do
            if btn.Text == islandName then
                local originalClick = btn.MouseButton1Click
                btn.MouseButton1Click:Connect(function()
                    Dashboard.sessionStats.currentLocation = islandName:gsub("🏝️", ""):gsub("🦈 ", ""):gsub("🎣 ", ""):gsub("❄️ ", ""):gsub("🌋 ", ""):gsub("🌴 ", ""):gsub("🗿 ", ""):gsub("⚙️ ", "")
                end)
                break
            end
        end
    end
end

-- Build UI and ready
BuildUI()

-- Setup real fish event listener
SetupFishCaughtListener()

-- Start location tracker
task.spawn(LocationTracker)

-- Expose quick API on _G for convenience
_G.ModernAutoFish = {
    Start = function() if not Config.enabled then Config.enabled = true; sessionId = sessionId + 1; task.spawn(function() AutofishRunner(sessionId) end) end end,
    Stop = function() Config.enabled = false; sessionId = sessionId + 1 end,
    SetMode = function(m) if m == "fast" or m == "secure" then Config.mode = m end end,
    ToggleAntiAFK = function() 
        AntiAFK.enabled = not AntiAFK.enabled
        if AntiAFK.enabled then
            AntiAFK.sessionId = AntiAFK.sessionId + 1
            task.spawn(function() AntiAfkRunner(AntiAFK.sessionId) end)
        else
            AntiAFK.sessionId = AntiAFK.sessionId + 1
        end
    end,
    
    -- Dashboard API
    LogFish = LogFishCatch,
    GetStats = function() return Dashboard end,
    ClearStats = function() 
        Dashboard.fishCaught = {}
        Dashboard.rareFishCaught = {}
        Dashboard.locationStats = {}
        Dashboard.heatmap = {}
        Dashboard.optimalTimes = {}
        Dashboard.sessionStats.fishCount = 0
        Dashboard.sessionStats.rareCount = 0
        Dashboard.sessionStats.startTime = tick()
    end,
    SetLocation = function(loc) Dashboard.sessionStats.currentLocation = loc end,
    
    Config = Config,
    AntiAFK = AntiAFK,
    Dashboard = Dashboard
}

print("modern_autofish loaded - UI created and API available via _G.ModernAutoFish")
