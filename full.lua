-- ═══════════════════════════════════════════════════════════════
-- 🎣 FISH IT CHARGE & ROLL ENHANCER 
-- ═══════════════════════════════════════════════════════════════
-- Purpose: Enhanced charge cast power & speed roll untuk modernv1.lua
-- Fixes: Rod orientation + optimized fishing parameters
-- ═══════════════════════════════════════════════════════════════

print("🎣 Fish It Charge & Roll Enhancer - Starting enhancements...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Enhanced Fishing Config
local FishingEnhancer = {
    -- Power Enhancement Settings
    chargeConfig = {
        maxPower = 100,        -- Maximum charge power (100%)
        perfectTiming = true,   -- Always perfect timing
        minChargeTime = 0.5,   -- Minimum charge time untuk realistic
        maxChargeTime = 1.2    -- Maximum charge time untuk optimal power
    },
    
    -- Speed Roll Settings
    rollConfig = {
        maxSpeed = 2.0,        -- Maximum roll speed multiplier
        perfectAccuracy = true, -- Always perfect center (0, 0)
        quickRoll = true,      -- Enable quick rolling
        rollDelay = 0.1        -- Minimal delay between rolls
    },
    
    -- Rod Orientation Fix
    orientationConfig = {
        enabled = true,
        forwardAngle = 180,    -- Degrees untuk menghadap depan
        fixInterval = 0.02     -- Interval fix orientation (50fps)
    },
    
    isActive = false,
    hooks = {},
    stats = {
        enhanced_charges = 0,
        enhanced_rolls = 0,
        orientation_fixes = 0
    }
}

-- ═══════════════════════════════════════════════════════════════
-- 🔧 ENHANCED ROD ORIENTATION FIX
-- ═══════════════════════════════════════════════════════════════

local function FixRodOrientationEnhanced()
    if not FishingEnhancer.orientationConfig.enabled then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local equippedTool = character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end
    
    -- Pastikan ini fishing rod
    local isRod = equippedTool.Name:lower():find("rod") or 
                  equippedTool:FindFirstChild("Rod") or
                  equippedTool:FindFirstChild("Handle")
    if not isRod then return end
    
    -- Method 1: Motor6D Fix (Most Effective)
    local rightArm = character:FindFirstChild("Right Arm")
    if rightArm then
        local rightGrip = rightArm:FindFirstChild("RightGrip")
        if rightGrip and rightGrip:IsA("Motor6D") then
            -- PERFECT orientation for forward facing like game's auto fish
            local forwardAngle = math.rad(FishingEnhancer.orientationConfig.forwardAngle)
            rightGrip.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), forwardAngle, 0)
            rightGrip.C1 = CFrame.new(0, 0, 0)
            
            FishingEnhancer.stats.orientation_fixes = FishingEnhancer.stats.orientation_fixes + 1
            return true
        end
    end
    
    -- Method 2: Tool Grip Fix
    local handle = equippedTool:FindFirstChild("Handle")
    if handle then
        local toolGrip = equippedTool:FindFirstChild("Grip")
        if not toolGrip then
            toolGrip = Instance.new("CFrameValue")
            toolGrip.Name = "Grip"
            toolGrip.Parent = equippedTool
        end
        
        if toolGrip:IsA("CFrameValue") then
            local forwardAngle = math.rad(FishingEnhancer.orientationConfig.forwardAngle)
            toolGrip.Value = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-90), forwardAngle, 0)
            return true
        end
    end
    
    return false
end

-- ═══════════════════════════════════════════════════════════════
-- ⚡ CHARGE POWER ENHANCER
-- ═══════════════════════════════════════════════════════════════

local function EnhanceChargePower(originalArgs)
    local enhanced = {}
    
    for i, arg in ipairs(originalArgs) do
        -- Detect power/charge values (usually 0-100 or 0-1)
        if type(arg) == "number" then
            if arg >= 0 and arg <= 1 then
                -- Normalized power (0-1) → set to 1 (100%)
                enhanced[i] = 1.0
                print("🔋 Enhanced charge power:", arg, "→", 1.0)
                FishingEnhancer.stats.enhanced_charges = FishingEnhancer.stats.enhanced_charges + 1
            elseif arg >= 0 and arg <= 100 then
                -- Percentage power (0-100) → set to 100
                enhanced[i] = FishingEnhancer.chargeConfig.maxPower
                print("🔋 Enhanced charge power:", arg, "→", FishingEnhancer.chargeConfig.maxPower)
                FishingEnhancer.stats.enhanced_charges = FishingEnhancer.stats.enhanced_charges + 1
            else
                enhanced[i] = arg -- Keep original if not power value
            end
        else
            enhanced[i] = arg -- Keep non-number values
        end
    end
    
    return enhanced
end

-- ═══════════════════════════════════════════════════════════════
-- 🎯 ROLL SPEED & ACCURACY ENHANCER  
-- ═══════════════════════════════════════════════════════════════

local function EnhanceRollParameters(originalArgs)
    local enhanced = {}
    
    for i, arg in ipairs(originalArgs) do
        if type(arg) == "number" then
            -- Detect coordinate values (usually -1 to 1 for positioning)
            if arg >= -1 and arg <= 1 and i <= 2 then -- X, Y coordinates
                if FishingEnhancer.rollConfig.perfectAccuracy then
                    enhanced[i] = 0 -- Perfect center
                    print("🎯 Enhanced roll position:", arg, "→", 0)
                    FishingEnhancer.stats.enhanced_rolls = FishingEnhancer.stats.enhanced_rolls + 1
                else
                    enhanced[i] = arg
                end
            -- Detect speed values (timing multipliers)
            elseif arg > 0 and arg < 10 then
                enhanced[i] = arg * FishingEnhancer.rollConfig.maxSpeed
                print("⚡ Enhanced roll speed:", arg, "→", enhanced[i])
            else
                enhanced[i] = arg
            end
        else
            enhanced[i] = arg
        end
    end
    
    return enhanced
end

-- ═══════════════════════════════════════════════════════════════
-- 🔗 REMOTE HOOKING SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function HookFishingRemotes()
    print("🔗 Setting up fishing remote hooks...")
    
    local function HookRemoteFunction(remote, remoteName)
        if not remote or not remote:IsA("RemoteFunction") then return false end
        
        local success = pcall(function()
            local originalInvoke = remote.InvokeServer
            
            remote.InvokeServer = function(self, ...)
                local args = {...}
                
                -- Apply enhancements based on remote name
                if remoteName:lower():find("charge") or remoteName:lower():find("rod") then
                    args = EnhanceChargePower(args)
                    -- Fix rod orientation before charging
                    FixRodOrientationEnhanced()
                elseif remoteName:lower():find("mini") or remoteName:lower():find("game") or remoteName:lower():find("roll") then
                    args = EnhanceRollParameters(args)
                end
                
                print("📞 Enhanced RF call:", remoteName, "with", #args, "args")
                return originalInvoke(self, unpack(args))
            end
            
            return true
        end)
        
        if success then
            FishingEnhancer.hooks[remoteName] = remote
            print("✅ Hooked RemoteFunction:", remoteName)
            return true
        else
            print("❌ Failed to hook RemoteFunction:", remoteName)
            return false
        end
    end
    
    local function HookRemoteEvent(remote, remoteName)
        if not remote or not remote:IsA("RemoteEvent") then return false end
        
        local success = pcall(function()
            local originalFire = remote.FireServer
            
            remote.FireServer = function(self, ...)
                local args = {...}
                
                -- Apply enhancements based on remote name
                if remoteName:lower():find("charge") or remoteName:lower():find("rod") then
                    args = EnhanceChargePower(args)
                    FixRodOrientationEnhanced()
                elseif remoteName:lower():find("mini") or remoteName:lower():find("game") or remoteName:lower():find("roll") then
                    args = EnhanceRollParameters(args)
                end
                
                print("📞 Enhanced RE call:", remoteName, "with", #args, "args")
                return originalFire(self, unpack(args))
            end
            
            return true
        end)
        
        if success then
            FishingEnhancer.hooks[remoteName] = remote
            print("✅ Hooked RemoteEvent:", remoteName)
            return true
        else
            print("❌ Failed to hook RemoteEvent:", remoteName)
            return false
        end
    end
    
    -- Find and hook all fishing-related remotes
    local function ScanAndHookRemotes()
        local hooked = 0
        
        for _, descendant in pairs(ReplicatedStorage:GetDescendants()) do
            if descendant:IsA("RemoteFunction") or descendant:IsA("RemoteEvent") then
                local name = descendant.Name
                local path = descendant:GetFullName():lower()
                
                -- Check if it's fishing-related
                if name:lower():find("fish") or name:lower():find("rod") or name:lower():find("charge") or
                   name:lower():find("cast") or name:lower():find("mini") or name:lower():find("roll") or
                   path:find("fish") or path:find("rod") then
                    
                    local success = false
                    if descendant:IsA("RemoteFunction") then
                        success = HookRemoteFunction(descendant, name)
                    else
                        success = HookRemoteEvent(descendant, name)
                    end
                    
                    if success then hooked = hooked + 1 end
                end
            end
        end
        
        return hooked
    end
    
    local hookedCount = ScanAndHookRemotes()
    print("🎣 Successfully hooked", hookedCount, "fishing remotes")
    
    return hookedCount > 0
end

-- ═══════════════════════════════════════════════════════════════
-- 🎮 CONTINUOUS ORIENTATION MONITOR
-- ═══════════════════════════════════════════════════════════════

local function StartOrientationMonitor()
    print("👁️ Starting continuous rod orientation monitor...")
    
    local orientationConnection = RunService.Heartbeat:Connect(function()
        if FishingEnhancer.isActive then
            FixRodOrientationEnhanced()
        end
    end)
    
    return orientationConnection
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 MONITORING UI
-- ═══════════════════════════════════════════════════════════════

local function CreateEnhancerUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishingEnhancer"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function()
        screenGui.Parent = game.CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 200)
    frame.Position = UDim2.new(1, -300, 0, 250)
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
    title.Text = "⚡ Charge & Roll Enhancer"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    title.BorderSizePixel = 0
    title.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 1, -40)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.Text = "🔄 Initializing enhancements..."
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 10
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextWrapped = true
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Parent = frame
    
    -- Update status
    local function UpdateStatus()
        if FishingEnhancer.isActive then
            local statusText = string.format(
                "✅ ENHANCEMENTS ACTIVE\n\n" ..
                "🔋 Charge Enhancements: %d\n" ..
                "🎯 Roll Enhancements: %d\n" ..
                "🔧 Orientation Fixes: %d\n" ..
                "🔗 Hooked Remotes: %d\n\n" ..
                "⚡ Max Power: %d%%\n" ..
                "🎯 Perfect Accuracy: %s\n" ..
                "🔧 Rod Facing: Forward",
                FishingEnhancer.stats.enhanced_charges,
                FishingEnhancer.stats.enhanced_rolls,
                FishingEnhancer.stats.orientation_fixes,
                table.getn(FishingEnhancer.hooks),
                FishingEnhancer.chargeConfig.maxPower,
                FishingEnhancer.rollConfig.perfectAccuracy and "ON" or "OFF"
            )
            
            statusLabel.Text = statusText
            title.BackgroundColor3 = Color3.fromRGB(50, 200, 100) -- Green when active
        else
            statusLabel.Text = "❌ ENHANCEMENTS INACTIVE\n\nFailed to hook fishing remotes.\nCheck console for details."
            title.BackgroundColor3 = Color3.fromRGB(200, 100, 50) -- Orange when failed
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
    print("🚀 Fish It Charge & Roll Enhancer - Initializing...")
    
    -- Hook fishing remotes
    local success = HookFishingRemotes()
    
    -- Start orientation monitor
    local orientationConnection = StartOrientationMonitor()
    
    -- Create UI
    CreateEnhancerUI()
    
    if success then
        FishingEnhancer.isActive = true
        print("✅ Fishing enhancements are now ACTIVE!")
        print("🔋 Charge power enhanced to maximum")
        print("🎯 Roll accuracy set to perfect center")
        print("🔧 Rod orientation fixed to face forward")
        print("📊 Monitor progress with the UI")
    else
        print("❌ Failed to initialize enhancements")
        print("💡 Make sure you're in Fish It game")
    end
    
    return orientationConnection
end

-- ═══════════════════════════════════════════════════════════════
-- 🎯 START ENHANCEMENTS
-- ═══════════════════════════════════════════════════════════════

local connection = Initialize()

--[[
⚡ FISH IT CHARGE & ROLL ENHANCER GUIDE:

🎯 FEATURES:
✅ Maximum charge power (100%)
✅ Perfect roll accuracy (center targeting)
✅ Rod orientation fix (forward facing)
✅ Real-time enhancement monitoring
✅ Compatible with modernv1.lua

🔧 ENHANCEMENTS:
- Charge Power: Any value → 100% maximum
- Roll Position: Any coordinates → (0, 0) perfect center
- Roll Speed: Enhanced speed multiplier
- Rod Orientation: Always facing forward like game's auto

📊 MONITORING:
- Real-time stats display
- Enhancement count tracking
- Hook success monitoring
- Live status updates

💡 USAGE:
1. Load script alongside modernv1.lua
2. Enhancements apply automatically
3. Monitor progress via UI
4. Enjoy optimal fishing performance!

This enhances your existing modernv1.lua script for better results!
]]

print("⚡ Fish It Charge & Roll Enhancer loaded!")
print("🎣 Your fishing will now be enhanced automatically")
print("📊 Check the UI for real-time enhancement stats")
