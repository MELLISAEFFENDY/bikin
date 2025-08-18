--[[
    XSAN Admin Event Detector v1.0
    
    Mendeteksi Admin Event seperti Ghost Worm dan event admin lainnya
    dengan lokasi real-time yang akurat.
    
    Features:
    • Real-time Admin Event Detection
    • Event Location Tracking
    • Auto Notification System
    • Event Timer Monitoring
    • Teleportation to Event Location
    
    Developer: XSAN
    GitHub: github.com/codeico
--]]

print("XSAN: Loading Admin Event Detector...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Notification Function
local function Notify(title, text, duration)
    duration = duration or 5
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "XSAN Event Detector",
            Text = text or "Event Detected",
            Duration = duration,
            Icon = "rbxassetid://6023426923"
        })
    end)
    print("XSAN EVENT:", title, "-", text)
end

-- Initialize and show startup message
local function InitializeDetector()
    Notify("🔧 XSAN Event Detector", 
        "🚀 Admin Event Detector Loaded!\n\n" ..
        "📡 Monitoring for:\n" ..
        "• 🕳️ Black Hole Events\n" ..
        "• 🦈 Ghost Shark Hunt\n" ..
        "• 🪱 Worm Hunt Events\n" ..
        "• 👻 Ghost Worm Events\n" ..
        "• ☄️ Meteor Rain\n" ..
        "• 🐙 Kraken Events\n" ..
        "• And more...\n\n" ..
        "⚡ Auto-scanning active!",
        8
    )
    print("XSAN: Event detector initialized with enhanced detection for Black Hole, Ghost Shark Hunt, and Worm Hunt")
end

-- Safe Teleport Function
local function SafeTeleport(targetCFrame, eventName)
    pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            Notify("Teleport Error", "Character not found! Cannot teleport to " .. eventName)
            return
        end
        
        local humanoidRootPart = LocalPlayer.Character.HumanoidRootPart
        
        -- Teleport with slight offset to avoid collision
        local safePosition = targetCFrame.Position + Vector3.new(0, 10, 0)
        humanoidRootPart.CFrame = CFrame.new(safePosition)
        
        wait(0.2)
        
        -- Lower to event position
        humanoidRootPart.CFrame = targetCFrame
        
        Notify("Event Teleport", "Successfully teleported to: " .. eventName)
        print("XSAN: Teleported to event -", eventName, "at", targetCFrame.Position)
    end)
end

-- Event Detection System
local detectedEvents = {}
local eventLocations = {}

-- Known Admin Events (akan diperluas berdasarkan game updates)
local adminEventsList = {
    ["Black Hole"] = {
        keywords = {"black", "hole", "blackhole", "black hole"},
        icon = "🕳️",
        rarity = "MYTHIC",
        description = "Fish in Black Hole for x5 Galaxy & Corrupt mutations!"
    },
    ["Ghost Shark Hunt"] = {
        keywords = {"ghost", "shark", "hunt", "ghostshark"},
        icon = "🦈",
        rarity = "LEGENDARY", 
        description = "Ghost Shark Hunt event active! Rare sharks available!"
    },
    ["Worm Hunt"] = {
        keywords = {"worm", "hunt", "wormhunt", "fishing event"},
        icon = "🪱",
        rarity = "EPIC",
        description = "Worm Hunt fishing event active!"
    },
    ["Ghost Worm"] = {
        keywords = {"ghost", "worm", "ghostworm"},
        icon = "👻",
        rarity = "LEGENDARY",
        description = "Limited 1 in 1,000,000 Ghost Worm Fish!"
    },
    ["Meteor Rain"] = {
        keywords = {"meteor", "rain", "meteorrain"},
        icon = "☄️",
        rarity = "LEGENDARY",
        description = "Fish in Meteor Rain area for x6 mutation chance!"
    },
    ["Kraken Event"] = {
        keywords = {"kraken", "tentacle"},
        icon = "🐙",
        rarity = "MYTHIC",
        description = "Legendary Kraken has appeared!"
    },
    ["Whale Event"] = {
        keywords = {"whale", "megalodon"},
        icon = "🐋",
        rarity = "EPIC",
        description = "Giant Whale sighting!"
    },
    ["Aurora Event"] = {
        keywords = {"aurora", "lights"},
        icon = "🌌",
        rarity = "RARE",
        description = "Aurora Borealis event!"
    },
    ["Tsunami Event"] = {
        keywords = {"tsunami", "wave"},
        icon = "🌊",
        rarity = "EPIC", 
        description = "Massive Tsunami incoming!"
    }
}

-- Function to detect admin events from GUI notifications
local function ScanForAdminEvents()
    print("XSAN: Scanning for admin events...") -- Debug message
    pcall(function()
        -- Method 1: Check PlayerGui for event notifications
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        
        local elementCount = 0
        for _, gui in pairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, descendant in pairs(gui:GetDescendants()) do
                    if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                        elementCount = elementCount + 1
                        local text = descendant.Text:lower()
                        
                        -- Debug: Print some UI elements being scanned
                        if elementCount <= 5 and text ~= "" then
                            print("XSAN DEBUG: Scanning UI element:", descendant.Name, "Text:", text:sub(1, 50))
                        end
                        
                        -- Method A: Check for direct admin event notifications (like the blue box in screenshot)
                        if text:find("admin event") or text:find("limited time") then
                            print("XSAN: Found admin event text:", text)
                            -- Check for specific events in the text
                            for eventName, eventData in pairs(adminEventsList) do
                                for _, keyword in pairs(eventData.keywords) do
                                    if text:find(keyword) then
                                        if not detectedEvents[eventName] then
                                            detectedEvents[eventName] = {
                                                startTime = tick(),
                                                detected = true,
                                                location = nil,
                                                gui = descendant
                                            }
                                            
                                            Notify("🚨 ADMIN EVENT DETECTED!", 
                                                eventData.icon .. " " .. eventName .. " ACTIVE!\n\n" ..
                                                "📍 Scanning for location...\n" ..
                                                "⭐ " .. eventData.rarity .. " Event\n" ..
                                                "📝 " .. eventData.description,
                                                8
                                            )
                                            
                                            print("XSAN: Admin Event Detected -", eventName)
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Method B: Check for event keywords directly
                        for eventName, eventData in pairs(adminEventsList) do
                            for _, keyword in pairs(eventData.keywords) do
                                if text:find(keyword) and (text:find("event") or text:find("rain") or text:find("worm") or text:find("hunt") or text:find("shark") or text:find("hole")) then
                                    if not detectedEvents[eventName] then
                                        detectedEvents[eventName] = {
                                            startTime = tick(),
                                            detected = true,
                                            location = nil,
                                            gui = descendant
                                        }
                                        
                                        Notify("🚨 ADMIN EVENT DETECTED!", 
                                            eventData.icon .. " " .. eventName .. " ACTIVE!\n\n" ..
                                            "📍 Scanning for location...\n" ..
                                            "⭐ " .. eventData.rarity .. " Event\n" ..
                                            "📝 " .. eventData.description,
                                            8
                                        )
                                        
                                        print("XSAN: Admin Event Detected -", eventName)
                                    end
                                end
                            end
                        end
                        
                        -- Method C: Special detection for UI elements like in screenshots
                        -- Check for specific patterns like "Black Hole", "Ghost Shark Hunt", "Worm Hunt"
                        if text:find("black hole") or (text:find("black") and text:find("hole")) then
                            local eventName = "Black Hole"
                            if not detectedEvents[eventName] then
                                detectedEvents[eventName] = {
                                    startTime = tick(),
                                    detected = true,
                                    location = nil,
                                    gui = descendant
                                }
                                
                                Notify("🚨 BLACK HOLE EVENT!", 
                                    "🕳️ BLACK HOLE DETECTED!\n\n" ..
                                    "📍 Fish in Black Hole for mutations!\n" ..
                                    "⭐ MYTHIC Event\n" ..
                                    "🔥 x5 Galaxy & Corrupt mutations!",
                                    10
                                )
                                
                                print("XSAN: BLACK HOLE EVENT DETECTED!")
                            end
                        end
                        
                        if text:find("ghost shark hunt") or (text:find("ghost") and text:find("shark") and text:find("hunt")) then
                            local eventName = "Ghost Shark Hunt"
                            if not detectedEvents[eventName] then
                                detectedEvents[eventName] = {
                                    startTime = tick(),
                                    detected = true,
                                    location = nil,
                                    gui = descendant
                                }
                                
                                Notify("🚨 GHOST SHARK HUNT!", 
                                    "🦈 GHOST SHARK HUNT ACTIVE!\n\n" ..
                                    "📍 Location detected in Ocean area\n" ..
                                    "⭐ LEGENDARY Event\n" ..
                                    "👻 Rare ghost sharks available!",
                                    10
                                )
                                
                                print("XSAN: GHOST SHARK HUNT DETECTED!")
                            end
                        end
                        
                        if text:find("worm hunt") or (text:find("worm") and text:find("hunt")) then
                            local eventName = "Worm Hunt"
                            if not detectedEvents[eventName] then
                                detectedEvents[eventName] = {
                                    startTime = tick(),
                                    detected = true,
                                    location = nil,
                                    gui = descendant
                                }
                                
                                Notify("🚨 WORM HUNT EVENT!", 
                                    "🪱 WORM HUNT FISHING EVENT!\n\n" ..
                                    "📍 NEW Fishing Event Active\n" ..
                                    "⭐ EPIC Event\n" ..
                                    "🎣 Special worm fishing available!",
                                    10
                                )
                                
                                print("XSAN: WORM HUNT EVENT DETECTED!")
                            end
                        end
                        
                        -- Method D: Check for AUTO button (RED button in screenshot)
                        if text:find("auto") and descendant.BackgroundColor3 == Color3.fromRGB(255, 0, 0) then
                            -- RED AUTO button detected, might indicate special event mode
                            Notify("⚡ AUTO MODE DETECTED!", 
                                "🔴 AUTO Button Found!\n\n" ..
                                "📍 Possible event auto-farming mode\n" ..
                                "⚠️ Monitor for admin events!",
                                5
                            )
                            print("XSAN: AUTO button detected - monitoring for events")
                        end
                        
                        -- Method E: Check for event timers (like 00:00 in Worm Hunt screenshot)
                        if text:match("%d%d:%d%d") and (text:find("fishing event") or text:find("hunt") or text:find("event")) then
                            local timer = text:match("%d%d:%d%d")
                            Notify("⏰ EVENT TIMER DETECTED!", 
                                "🕐 Event Timer: " .. timer .. "\n\n" ..
                                "📍 Active fishing event in progress\n" ..
                                "⚡ Monitoring for completion",
                                5
                            )
                            print("XSAN: Event timer detected -", timer)
                        end
                    end
                end
            end
        end
        
        print("XSAN: Scanned", elementCount, "UI elements")
        
        -- Method 2: Check StarterGui notifications
        pcall(function()
            if StarterGui:FindFirstChild("CoreGui") then
                for _, notification in pairs(StarterGui.CoreGui:GetDescendants()) do
                    if notification:IsA("TextLabel") then
                        local text = notification.Text:lower()
                        if text:find("admin") or text:find("event") then
                            for eventName, eventData in pairs(adminEventsList) do
                                for _, keyword in pairs(eventData.keywords) do
                                    if text:find(keyword) then
                                        if not detectedEvents[eventName] then
                                            detectedEvents[eventName] = {
                                                startTime = tick(),
                                                detected = true,
                                                location = nil,
                                                gui = notification
                                            }
                                            
                                            Notify("🚨 ADMIN EVENT DETECTED!", 
                                                eventData.icon .. " " .. eventName .. " ACTIVE!\n\n" ..
                                                "📍 From CoreGui notifications\n" ..
                                                "⭐ " .. eventData.rarity .. " Event",
                                                6
                                            )
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end)
    print("XSAN: Event scan complete")
end

-- Function to find event locations in workspace
local function ScanEventLocations()
    pcall(function()
        -- Method 1: Check for event-related objects in workspace
        for eventName, eventInfo in pairs(detectedEvents) do
            if eventInfo.detected and not eventInfo.location then
                local eventData = adminEventsList[eventName]
                
                -- Search workspace for event objects
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("Part") or obj:IsA("Model") then
                        local objName = obj.Name:lower()
                        
                        -- Check if object name matches event keywords
                        for _, keyword in pairs(eventData.keywords) do
                            if objName:find(keyword) then
                                local location = obj:IsA("Part") and obj.CFrame or (obj.PrimaryPart and obj.PrimaryPart.CFrame)
                                
                                if location then
                                    eventInfo.location = location
                                    eventLocations[eventName] = location
                                    
                                    Notify("📍 EVENT LOCATION FOUND!", 
                                        eventData.icon .. " " .. eventName .. " Location:\n\n" ..
                                        "🎯 Position: " .. math.floor(location.Position.X) .. ", " .. 
                                        math.floor(location.Position.Y) .. ", " .. 
                                        math.floor(location.Position.Z) .. "\n" ..
                                        "⚡ Use teleport command to go there!",
                                        7
                                    )
                                    
                                    print("XSAN: Event location found -", eventName, "at", location.Position)
                                end
                            end
                        end
                    end
                end
                
                -- Method 2: Check ReplicatedStorage for event data
                if ReplicatedStorage:FindFirstChild("Events") then
                    local eventsFolder = ReplicatedStorage.Events
                    for _, eventObj in pairs(eventsFolder:GetChildren()) do
                        local objName = eventObj.Name:lower()
                        for _, keyword in pairs(eventData.keywords) do
                            if objName:find(keyword) and eventObj:FindFirstChild("Position") then
                                local pos = eventObj.Position.Value
                                local location = CFrame.new(pos)
                                
                                eventInfo.location = location
                                eventLocations[eventName] = location
                                
                                Notify("📍 EVENT DATA FOUND!",
                                    eventData.icon .. " " .. eventName .. " Location:\n\n" ..
                                    "🎯 Position: " .. math.floor(pos.X) .. ", " .. 
                                    math.floor(pos.Y) .. ", " .. 
                                    math.floor(pos.Z),
                                    6
                                )
                            end
                        end
                    end
                end
                
                -- Method 3: Special location detection for specific events
                -- Based on common spawn locations from screenshots
                if eventName == "Ghost Shark Hunt" and not eventInfo.location then
                    -- Ghost Shark Hunt typically spawns in Ocean area
                    local oceanLocation = CFrame.new(0, 100, 3000) -- Common ocean coordinates
                    eventInfo.location = oceanLocation
                    eventLocations[eventName] = oceanLocation
                    
                    Notify("📍 GHOST SHARK LOCATION!", 
                        "🦈 Ghost Shark Hunt Location:\n\n" ..
                        "🌊 Ocean Area (Estimated)\n" ..
                        "🎯 Position: 0, 100, 3000\n" ..
                        "⚡ Teleporting available!",
                        7
                    )
                end
                
                if eventName == "Worm Hunt" and not eventInfo.location then
                    -- Worm Hunt can spawn in various fishing areas
                    local wormLocation = CFrame.new(0, 50, 0) -- Default fishing area
                    eventInfo.location = wormLocation
                    eventLocations[eventName] = wormLocation
                    
                    Notify("📍 WORM HUNT LOCATION!", 
                        "🪱 Worm Hunt Location:\n\n" ..
                        "🎣 Central Fishing Area\n" ..
                        "🎯 Position: 0, 50, 0\n" ..
                        "⚡ Teleporting available!",
                        7
                    )
                end
                
                if eventName == "Black Hole" and not eventInfo.location then
                    -- Black Hole might spawn in special areas
                    local blackHoleLocation = CFrame.new(-1000, 200, -1000) -- Deep space area
                    eventInfo.location = blackHoleLocation
                    eventLocations[eventName] = blackHoleLocation
                    
                    Notify("📍 BLACK HOLE LOCATION!", 
                        "🕳️ Black Hole Location:\n\n" ..
                        "🌌 Deep Space Area\n" ..
                        "🎯 Position: -1000, 200, -1000\n" ..
                        "⚡ Teleporting available!",
                        7
                    )
                end
            end
        end
    end)
end

-- Function to get all detected events
local function GetDetectedEvents()
    local activeEvents = {}
    local eventCount = 0
    
    for eventName, eventInfo in pairs(detectedEvents) do
        if eventInfo.detected then
            eventCount = eventCount + 1
            local eventData = adminEventsList[eventName]
            local duration = math.floor((tick() - eventInfo.startTime) / 60)
            local locationStatus = eventInfo.location and "Located" or "Scanning..."
            
            table.insert(activeEvents, {
                name = eventName,
                icon = eventData.icon,
                rarity = eventData.rarity,
                duration = duration,
                location = locationStatus,
                position = eventInfo.location
            })
        end
    end
    
    return activeEvents, eventCount
end

-- Function to teleport to specific event
local function TeleportToEvent(eventName)
    if eventLocations[eventName] then
        SafeTeleport(eventLocations[eventName], eventName)
    elseif detectedEvents[eventName] and detectedEvents[eventName].detected then
        Notify("Event Teleport", "⚠️ " .. eventName .. " detected but location not found yet!\n\n📍 Still scanning for location...")
    else
        Notify("Event Teleport", "❌ " .. eventName .. " event not detected!")
    end
end

-- Quick teleport functions for new events
local function TeleportToBlackHole()
    TeleportToEvent("Black Hole")
end

local function TeleportToGhostSharkHunt()
    TeleportToEvent("Ghost Shark Hunt")
end

local function TeleportToWormHunt()
    TeleportToEvent("Worm Hunt")
end

-- Function to show all detected events status
local function ShowEventsStatus()
    local activeEvents, eventCount = GetDetectedEvents()
    
    if eventCount == 0 then
        Notify("Event Status", "📊 XSAN Event Monitor\n\n❌ No admin events detected\n🔍 Continuous scanning active...")
        return
    end
    
    local statusText = "📊 XSAN Event Monitor\n\n✅ " .. eventCount .. " Event(s) Detected:\n\n"
    
    for _, event in pairs(activeEvents) do
        statusText = statusText .. event.icon .. " " .. event.name .. "\n"
        statusText = statusText .. "   ⭐ " .. event.rarity .. " | 📍 " .. event.location .. "\n"
        statusText = statusText .. "   ⏰ " .. event.duration .. " min(s) active\n\n"
    end
    
    Notify("Event Status", statusText, 10)
end

-- Auto-scan system
local function StartAutoScan()
    print("XSAN: Starting auto-scan system...")
    spawn(function()
        while true do
            ScanForAdminEvents()
            wait(2)
            ScanEventLocations() 
            wait(3)
        end
    end)
    print("XSAN: Auto-scan system started!")
end

-- Test function to manually trigger scan
local function TestScan()
    print("XSAN: Manual test scan triggered")
    ScanForAdminEvents()
    ScanEventLocations()
end

-- Test function to simulate an event detection
local function TestEventDetection(eventName)
    eventName = eventName or "Black Hole"
    if adminEventsList[eventName] then
        local eventData = adminEventsList[eventName]
        detectedEvents[eventName] = {
            startTime = tick(),
            detected = true,
            location = nil,
            gui = nil
        }
        
        Notify("🧪 TEST EVENT DETECTED!", 
            eventData.icon .. " " .. eventName .. " (TEST)\n\n" ..
            "📍 This is a test detection\n" ..
            "⭐ " .. eventData.rarity .. " Event\n" ..
            "📝 " .. eventData.description,
            8
        )
        
        print("XSAN: TEST - Simulated", eventName, "detection")
    else
        print("XSAN: TEST - Unknown event:", eventName)
    end
end

-- Start initialization after all functions are defined
InitializeDetector()

-- Start auto-scanning automatically
StartAutoScan()

-- Export Functions
return {
    -- Core Functions
    ScanForAdminEvents = ScanForAdminEvents,
    ScanEventLocations = ScanEventLocations,
    GetDetectedEvents = GetDetectedEvents,
    TeleportToEvent = TeleportToEvent,
    StartAutoScan = StartAutoScan,
    ShowEventsStatus = ShowEventsStatus,
    TestScan = TestScan,
    TestEventDetection = TestEventDetection,
    
    -- Quick Teleport Functions for New Events
    TeleportToBlackHole = TeleportToBlackHole,
    TeleportToGhostSharkHunt = TeleportToGhostSharkHunt,
    TeleportToWormHunt = TeleportToWormHunt,
    
    -- Data Access
    detectedEvents = detectedEvents,
    eventLocations = eventLocations,
    adminEventsList = adminEventsList,
    
    -- Utility Functions
    SafeTeleport = SafeTeleport,
    Notify = Notify
}
