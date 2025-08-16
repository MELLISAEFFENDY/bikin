-- ═══════════════════════════════════════════════════════════════
-- 🎣 FISH IT WORKING AUTO FISHING
-- ═══════════════════════════════════════════════════════════════
-- Based on Ultimate Remote Explorer findings
-- Uses discovered remote structure and alternative approach
-- ═══════════════════════════════════════════════════════════════

print("🎣 Fish It Working Auto - Starting enhanced fishing...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- 📍 DISCOVERED REMOTE PATHS (from Ultimate Explorer)
-- ═══════════════════════════════════════════════════════════════

local REMOTE_BASE = "ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net"
local KNOWN_FISHING_REMOTES = {
    "PromptProductPurchase",
    "ProductPurchaseFinished", 
    "ProductPurchaseCompleted",
    "PlayFishingEffect",
    "BoatChanged",
    "UpdateAutoFishingState",
    "ChargeFishingRod",
    "CancelFishingInputs",
    "FishingStopped"
}

local WorkingAuto = {
    isActive = false,
    stats = {
        attempts = 0,
        successes = 0,
        failures = 0,
        startTime = tick()
    },
    foundRemotes = {},
    hooks = {}
}

-- ═══════════════════════════════════════════════════════════════
-- 🔍 SMART REMOTE FINDER
-- ═══════════════════════════════════════════════════════════════

local function FindActualRemotes()
    print("🔍 Searching for actual working remotes...")
    
    local found = {}
    
    -- Try different path variations
    local pathVariations = {
        "Packages._Index.sleitnick_net@0.2.0.net",
        "Packages._Index.sleitnick_net@0.2.0.net.RE",
        "Packages._Index.sleitnick_net@0.2.0.net.RF",
        "Shared",
        "CmdrClient",
        "CmdrFunction", 
        "CmdrEvent"
    }
    
    for _, basePath in ipairs(pathVariations) do
        local success, folder = pcall(function()
            local parts = string.split(basePath, ".")
            local current = ReplicatedStorage
            for _, part in ipairs(parts) do
                current = current:FindFirstChild(part)
                if not current then return nil end
            end
            return current
        end)
        
        if success and folder then
            print("✅ Found path:", basePath)
            
            -- Look for remotes in this path
            for _, descendant in pairs(folder:GetDescendants()) do
                if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
                    local name = descendant.Name
                    if name:lower():find("fish") or name:lower():find("rod") or 
                       name:lower():find("auto") or name:lower():find("catch") then
                        found[name] = {
                            object = descendant,
                            type = descendant.ClassName,
                            path = descendant:GetFullName()
                        }
                        print("🎣 Found fishing remote:", name, "(" .. descendant.ClassName .. ")")
                    end
                end
            end
        end
    end
    
    WorkingAuto.foundRemotes = found
    return found
end

-- ═══════════════════════════════════════════════════════════════
-- 🎯 ALTERNATIVE HOOKING METHOD
-- ═══════════════════════════════════════════════════════════════

local function HookWithMetatable(remote, remoteName)
    print("🔧 Attempting metatable hook for:", remoteName)
    
    local success = pcall(function()
        if remote.type == "RemoteFunction" then
            -- Hook using metatable approach
            local mt = getrawmetatable(remote.object)
            local oldNamecall = mt.__namecall
            
            mt.__namecall = function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if self == remote.object and method == "InvokeServer" then
                    print("📞 RF Call:", remoteName, "Args:", #args)
                    
                    -- Auto fishing enhancements
                    if remoteName:lower():find("auto") or remoteName:lower():find("fish") then
                        -- Enhance single number args (power/strength)
                        for i, arg in ipairs(args) do
                            if type(arg) == "number" and arg >= 0 and arg <= 100 then
                                args[i] = 100
                                print("🎯 Enhanced power:", arg, "→", 100)
                            end
                        end
                    end
                    
                    WorkingAuto.stats.attempts = WorkingAuto.stats.attempts + 1
                end
                
                return oldNamecall(self, unpack(args))
            end
            
            return true
            
        elseif remote.type == "RemoteEvent" then
            -- Hook RemoteEvent
            local mt = getrawmetatable(remote.object)
            local oldNamecall = mt.__namecall
            
            mt.__namecall = function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if self == remote.object and method == "FireServer" then
                    print("📞 RE Call:", remoteName, "Args:", #args)
                    
                    -- Auto fishing enhancements  
                    if remoteName:lower():find("auto") or remoteName:lower():find("fish") then
                        -- Enhance coordinate args (perfect center)
                        if #args >= 2 and type(args[1]) == "number" and type(args[2]) == "number" then
                            if args[1] >= -1 and args[1] <= 1 and args[2] >= -1 and args[2] <= 1 then
                                args[1] = 0
                                args[2] = 0
                                print("🎯 Enhanced coordinates:", "→ (0, 0)")
                            end
                        end
                        
                        -- Enhance boolean args (enable auto features)
                        for i, arg in ipairs(args) do
                            if type(arg) == "boolean" and remoteName:lower():find("auto") then
                                args[i] = true
                                print("🎯 Enhanced boolean:", arg, "→", true)
                            end
                        end
                    end
                    
                    WorkingAuto.stats.attempts = WorkingAuto.stats.attempts + 1
                end
                
                return oldNamecall(self, unpack(args))
            end
            
            return true
        end
    end)
    
    if success then
        print("✅ Successfully hooked:", remoteName)
        WorkingAuto.stats.successes = WorkingAuto.stats.successes + 1
        return true
    else
        print("❌ Failed to hook:", remoteName)
        WorkingAuto.stats.failures = WorkingAuto.stats.failures + 1
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 🎣 AUTO FISHING CORE
-- ═══════════════════════════════════════════════════════════════

local function SetupAutoFishing()
    print("🎣 Setting up auto fishing system...")
    
    -- Find remotes first
    local remotes = FindActualRemotes()
    
    if next(remotes) == nil then
        print("❌ No fishing remotes found!")
        return false
    end
    
    print("🎯 Found", table.getn(remotes), "fishing remotes")
    
    -- Hook each remote with metatable method
    local hookedCount = 0
    for name, remote in pairs(remotes) do
        if HookWithMetatable(remote, name) then
            WorkingAuto.hooks[name] = remote
            hookedCount = hookedCount + 1
        end
    end
    
    print("✅ Successfully hooked", hookedCount, "fishing remotes")
    
    if hookedCount > 0 then
        WorkingAuto.isActive = true
        print("🎣 Auto fishing is now ACTIVE!")
        print("💡 Use fishing features in game - they will be enhanced automatically")
        return true
    else
        print("❌ Failed to hook any remotes!")
        return false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 MONITORING SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function CreateMonitoringUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishItWorkingAuto"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function()
        screenGui.Parent = game.CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(1, -320, 0, 20)
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
    title.Text = "🎣 Fish It Working Auto"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
    title.BorderSizePixel = 0
    title.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Status display
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 1, -40)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.Text = "🔄 Initializing auto fishing system..."
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextWrapped = true
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Parent = frame
    
    -- Update status periodically
    local function UpdateStatus()
        if WorkingAuto.isActive then
            local runtime = tick() - WorkingAuto.stats.startTime
            local minutes = math.floor(runtime / 60)
            local seconds = math.floor(runtime % 60)
            
            local statusText = string.format(
                "✅ AUTO FISHING ACTIVE\n\n" ..
                "📊 STATS:\n" ..
                "⏰ Runtime: %02d:%02d\n" ..
                "🎯 Remotes Hooked: %d\n" ..
                "📞 Total Calls: %d\n" ..
                "✅ Successes: %d\n" ..
                "❌ Failures: %d\n\n" ..
                "💡 Use fishing features in game!\nThey will be enhanced automatically.",
                minutes, seconds,
                table.getn(WorkingAuto.hooks),
                WorkingAuto.stats.attempts,
                WorkingAuto.stats.successes,
                WorkingAuto.stats.failures
            )
            
            statusLabel.Text = statusText
            
            -- Update title color based on activity
            if WorkingAuto.stats.attempts > 0 then
                title.BackgroundColor3 = Color3.fromRGB(20, 150, 50) -- Green when active
            else
                title.BackgroundColor3 = Color3.fromRGB(150, 150, 20) -- Yellow when waiting
            end
        else
            statusLabel.Text = "❌ AUTO FISHING INACTIVE\n\nFailed to hook fishing remotes.\nCheck console for details."
            title.BackgroundColor3 = Color3.fromRGB(150, 50, 20) -- Red when failed
        end
    end
    
    -- Update every 2 seconds
    spawn(function()
        while true do
            UpdateStatus()
            wait(2)
        end
    end)
    
    return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- 🚀 INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("🚀 Fish It Working Auto - Initializing...")
    
    -- Setup auto fishing system
    local success = SetupAutoFishing()
    
    -- Create monitoring UI
    CreateMonitoringUI()
    
    if success then
        print("✅ Fish It Working Auto is ready!")
        print("🎣 Auto fishing enhancements are now active")
        print("💡 Use any fishing features in the game - they will be enhanced automatically")
        print("📊 Monitor progress with the UI on the right side")
    else
        print("❌ Failed to initialize auto fishing")
        print("💡 Try running Ultimate Remote Explorer first to identify remotes")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 🎯 START AUTO FISHING
-- ═══════════════════════════════════════════════════════════════

Initialize()

--[[
🎣 FISH IT WORKING AUTO GUIDE:

🎯 FEATURES:
✅ Uses discovered remote structure from Ultimate Explorer
✅ Metatable hooking method (bypasses framework protection)
✅ Automatic enhancement of fishing calls
✅ Real-time monitoring with UI
✅ Smart parameter detection and enhancement

🔧 ENHANCEMENTS APPLIED:
- Power/strength values: 0-100 → 100 (max power)
- Coordinates: any → (0, 0) (perfect center)
- Boolean auto features: false → true (enable auto)

📊 MONITORING:
- Real-time stats display
- Hook success/failure tracking
- Runtime monitoring
- Call interception logs

💡 HOW IT WORKS:
1. Finds actual fishing remotes using discovered paths
2. Uses metatable hooking to bypass framework protection
3. Intercepts all fishing-related remote calls
4. Automatically enhances parameters for optimal results
5. Provides real-time feedback via UI

This should work even with protected remotes!
]]

print("🎣 Fish It Working Auto loaded!")
print("🎯 Ready to enhance your fishing experience")
print("📊 Check the UI for real-time status")
