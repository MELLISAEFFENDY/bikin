-- ═══════════════════════════════════════════════════════════════
-- 🎣 FISH IT UNIVERSAL AUTO ENHANCER - SIMPLE & EFFECTIVE
-- ═══════════════════════════════════════════════════════════════
-- Purpose: Hook fishing without knowing exact remote names
-- Method: Monitor ALL remote calls and enhance fishing-like patterns
-- Strategy: Universal approach that works regardless of structure
-- ═══════════════════════════════════════════════════════════════

print("🎣 Fish It Universal Auto Enhancer - Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local UniversalEnhancer = {
    hookedRemotes = 0,
    enhancedCalls = 0,
    monitoredCalls = 0,
    isActive = false
}

-- ═══════════════════════════════════════════════════════════════
-- 🌐 UNIVERSAL REMOTE HOOKER
-- ═══════════════════════════════════════════════════════════════

local function HookAllRemotes()
    print("🌐 Hooking ALL remotes for universal enhancement...")
    
    local hooked = 0
    
    for _, descendant in pairs(ReplicatedStorage:GetDescendants()) do
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            local success, err = pcall(function()
                local remoteName = descendant.Name
                local remotePath = descendant:GetFullName()
                
                if descendant:IsA("RemoteFunction") then
                    local original = descendant.InvokeServer
                    descendant.InvokeServer = function(self, ...)
                        local args = {...}
                        UniversalEnhancer.monitoredCalls = UniversalEnhancer.monitoredCalls + 1
                        
                        -- Check if this looks like a fishing call
                        local enhanced = false
                        
                        -- Pattern 1: Single number (likely charge/power)
                        if #args == 1 and tonumber(args[1]) then
                            local num = tonumber(args[1])
                            if num >= 0 and num <= 100 then
                                args[1] = 100  -- Perfect power
                                enhanced = true
                                print("⚡ Enhanced power:", remoteName, "→ 100")
                            end
                        end
                        
                        -- Pattern 2: Two numbers (likely coordinates)  
                        if #args == 2 and tonumber(args[1]) and tonumber(args[2]) then
                            local x, y = tonumber(args[1]), tonumber(args[2])
                            if x >= -5 and x <= 5 and y >= -5 and y <= 5 then
                                args[1] = 0  -- Perfect center X
                                args[2] = 0  -- Perfect center Y
                                enhanced = true
                                print("🎯 Enhanced coords:", remoteName, "→ (0, 0)")
                            end
                        end
                        
                        -- Pattern 3: Boolean (likely auto state)
                        if #args == 1 and type(args[1]) == "boolean" then
                            print("🎣 Auto state:", remoteName, "→", args[1])
                        end
                        
                        if enhanced then
                            UniversalEnhancer.enhancedCalls = UniversalEnhancer.enhancedCalls + 1
                        end
                        
                        return original(self, unpack(args))
                    end
                    hooked = hooked + 1
                    
                elseif descendant:IsA("RemoteEvent") then
                    local original = descendant.FireServer
                    descendant.FireServer = function(self, ...)
                        local args = {...}
                        UniversalEnhancer.monitoredCalls = UniversalEnhancer.monitoredCalls + 1
                        
                        -- Same enhancement logic for RemoteEvents
                        local enhanced = false
                        
                        if #args == 1 and tonumber(args[1]) then
                            local num = tonumber(args[1])
                            if num >= 0 and num <= 100 then
                                args[1] = 100
                                enhanced = true
                                print("⚡ Enhanced power:", remoteName, "→ 100")
                            end
                        end
                        
                        if #args == 2 and tonumber(args[1]) and tonumber(args[2]) then
                            local x, y = tonumber(args[1]), tonumber(args[2])
                            if x >= -5 and x <= 5 and y >= -5 and y <= 5 then
                                args[1] = 0
                                args[2] = 0
                                enhanced = true
                                print("🎯 Enhanced coords:", remoteName, "→ (0, 0)")
                            end
                        end
                        
                        if #args == 1 and type(args[1]) == "boolean" then
                            print("🎣 Auto state:", remoteName, "→", args[1])
                        end
                        
                        if enhanced then
                            UniversalEnhancer.enhancedCalls = UniversalEnhancer.enhancedCalls + 1
                        end
                        
                        return original(self, unpack(args))
                    end
                    hooked = hooked + 1
                end
            end)
            
            if not success then
                print("⚠️ Failed to hook:", descendant:GetFullName())
            end
        end
    end
    
    UniversalEnhancer.hookedRemotes = hooked
    UniversalEnhancer.isActive = true
    
    print("✅ Hooked", hooked, "remotes for universal enhancement")
    return hooked > 0
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 SIMPLE MONITORING UI
-- ═══════════════════════════════════════════════════════════════

local function CreateSimpleUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UniversalEnhancer"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function()
        screenGui.Parent = game.CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main window
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
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
    title.Text = "🎣 Universal Auto Enhancer"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    title.BorderSizePixel = 0
    title.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Activate button
    local activateBtn = Instance.new("TextButton")
    activateBtn.Size = UDim2.new(1, -10, 0, 40)
    activateBtn.Position = UDim2.new(0, 5, 0, 40)
    activateBtn.Text = "🚀 ACTIVATE UNIVERSAL ENHANCEMENT"
    activateBtn.Font = Enum.Font.GothamBold
    activateBtn.TextSize = 12
    activateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    activateBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    activateBtn.BorderSizePixel = 0
    activateBtn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = activateBtn
    
    -- Stats display
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -10, 0, 80)
    statsLabel.Position = UDim2.new(0, 5, 0, 90)
    statsLabel.Text = "📊 STATS:\n🌐 Hooked Remotes: 0\n📞 Monitored Calls: 0\n⚡ Enhanced Calls: 0"
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 10
    statsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statsLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    statsLabel.BorderSizePixel = 0
    statsLabel.TextWrapped = true
    statsLabel.Parent = frame
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 4)
    statsCorner.Parent = statsLabel
    
    -- Instructions
    local instructions = Instance.new("TextLabel")
    instructions.Size = UDim2.new(1, -10, 0, 20)
    instructions.Position = UDim2.new(0, 5, 0, 175)
    instructions.Text = "💡 Works with ANY fishing system - no specific remotes needed!"
    instructions.Font = Enum.Font.Gotham
    instructions.TextSize = 9
    instructions.TextColor3 = Color3.fromRGB(100, 255, 100)
    instructions.BackgroundTransparency = 1
    instructions.TextWrapped = true
    instructions.Parent = frame
    
    -- Button functionality
    activateBtn.MouseButton1Click:Connect(function()
        activateBtn.Text = "🔄 HOOKING ALL REMOTES..."
        activateBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        
        task.wait(1)
        
        if HookAllRemotes() then
            activateBtn.Text = "✅ UNIVERSAL ENHANCEMENT ACTIVE"
            activateBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            activateBtn.Active = false
            
            instructions.Text = "✅ Active! Use any fishing feature - auto enhancements will apply!"
            instructions.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            activateBtn.Text = "❌ ACTIVATION FAILED"
            activateBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
        end
    end)
    
    -- Real-time stats updater
    task.spawn(function()
        while true do
            task.wait(1)
            if UniversalEnhancer.isActive then
                statsLabel.Text = string.format(
                    "📊 UNIVERSAL ENHANCEMENT STATS:\n🌐 Hooked Remotes: %d\n📞 Monitored Calls: %d\n⚡ Enhanced Calls: %d",
                    UniversalEnhancer.hookedRemotes,
                    UniversalEnhancer.monitoredCalls,
                    UniversalEnhancer.enhancedCalls
                )
            end
        end
    end)
    
    return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- 🚀 AUTO-ACTIVATION
-- ═══════════════════════════════════════════════════════════════

local function AutoActivate()
    print("🚀 Auto-activating universal enhancement...")
    
    task.wait(2)  -- Wait for game to fully load
    
    if HookAllRemotes() then
        print("✅ Universal enhancement auto-activated!")
        print("🎣 All fishing calls will now be enhanced automatically!")
        
        -- Show notification
        local notification = Instance.new("ScreenGui")
        notification.Name = "UniversalNotif"
        notification.Parent = LocalPlayer.PlayerGui
        
        local notifFrame = Instance.new("Frame")
        notifFrame.Size = UDim2.new(0, 280, 0, 60)
        notifFrame.Position = UDim2.new(0.5, -140, 0, 50)
        notifFrame.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        notifFrame.BorderSizePixel = 0
        notifFrame.Parent = notification
        
        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 8)
        notifCorner.Parent = notifFrame
        
        local notifText = Instance.new("TextLabel")
        notifText.Size = UDim2.new(1, 0, 1, 0)
        notifText.Text = "🎣 UNIVERSAL AUTO ENHANCEMENT ACTIVE!\n⚡ Perfect fishing guaranteed"
        notifText.Font = Enum.Font.GothamBold
        notifText.TextSize = 11
        notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
        notifText.BackgroundTransparency = 1
        notifText.TextWrapped = true
        notifText.Parent = notifFrame
        
        -- Auto-hide notification
        task.wait(4)
        notification:Destroy()
    else
        print("❌ Auto-activation failed")
    end
end

-- ═══════════════════════════════════════════════════════════════
-- 🎬 INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("🎣 Fish It Universal Auto Enhancer - Initializing...")
    
    -- Create UI
    CreateSimpleUI()
    
    -- Auto-activate
    task.spawn(AutoActivate)
    
    print("✅ Universal Auto Enhancer ready!")
end

-- Start the enhancer
Initialize()

--[[
🎣 UNIVERSAL AUTO ENHANCER GUIDE:

🎯 STRATEGY:
- Hook ALL remotes in ReplicatedStorage
- Detect fishing patterns automatically
- Enhance any call that looks like fishing
- No need to know specific remote names

📊 ENHANCEMENT PATTERNS:
✅ Single number (0-100) → Set to 100 (perfect power)
✅ Two numbers (-5 to 5) → Set to (0,0) (perfect center)
✅ Boolean values → Monitor auto state
✅ Universal approach works with any structure

💡 ADVANTAGES:
- Works regardless of game updates
- No need for specific remote knowledge
- Catches all fishing-like patterns
- Automatic enhancement
- Real-time monitoring

⚡ RESULTS:
- Perfect power on any fishing rod charge
- Perfect accuracy on any minigame
- Works with any fishing system
- Universal compatibility

🔧 HOW IT WORKS:
1. Hooks every remote in the game
2. Monitors all remote calls
3. Detects fishing patterns by arguments
4. Enhances matching patterns automatically
5. Provides real-time statistics

This approach should work even if the game structure is different!
]]

print("🎣 Universal Auto Enhancer loaded!")
print("⚡ Works with ANY fishing system structure")
print("🎯 Perfect fishing guaranteed!")
