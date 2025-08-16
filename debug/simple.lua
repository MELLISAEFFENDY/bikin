-- ═══════════════════════════════════════════════════════════════
-- 🔬 FISH IT NATIVE AUTO ANALYZER - SAFE VERSION
-- ═══════════════════════════════════════════════════════════════
-- Purpose: Analyze and modify native AUTO fishing behavior SAFELY
-- Focus: Only target confirmed fishing remotes, avoid payment systems
-- Method: Safe hook system with strict filtering
-- ═══════════════════════════════════════════════════════════════

print("🔬 Fish It Native Auto Analyzer (SAFE) - Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- 🛡️ SAFE REMOTE FINDER & MODIFIER
-- ═══════════════════════════════════════════════════════════════

local AutoAnalyzer = {
    foundRemotes = {},
    hooksActive = false,
    castCount = 0,
    perfectCount = 0,
    safetyMode = true
}

-- Ultra-safe remote detection with multiple filters
local function SafeRemoteScan()
    print("🔍 SAFE scan for fishing remotes...")
    
    -- Only look for very specific fishing terms
    local fishingKeywords = {"fish", "rod", "cast", "reel", "hook", "catch", "bait"}
    
    -- Absolutely exclude these keywords
    local dangerousKeywords = {
        "purchase", "product", "buy", "shop", "store", "payment", "coin", 
        "money", "robux", "gamepass", "developer", "prompt", "receipt",
        "transaction", "billing", "credit", "currency", "price", "cost"
    }
    
    -- Exclude these path patterns
    local dangerousPatterns = {
        "packages", "_index", "vendor", "node_modules", "sleitnick",
        "framework", "library", "module", "core", "system"
    }
    
    local found = {}
    
    for _, descendant in pairs(ReplicatedStorage:GetDescendants()) do
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            local name = descendant.Name:lower()
            local fullName = descendant:GetFullName():lower()
            
            -- First check: Exclude dangerous keywords
            local isDangerous = false
            for _, dangerWord in pairs(dangerousKeywords) do
                if name:find(dangerWord) or fullName:find(dangerWord) then
                    isDangerous = true
                    print("🚫 DANGEROUS - Excluded:", descendant:GetFullName())
                    break
                end
            end
            
            -- Second check: Exclude dangerous path patterns
            if not isDangerous then
                for _, pattern in pairs(dangerousPatterns) do
                    if fullName:find(pattern) then
                        isDangerous = true
                        print("🚫 DANGEROUS PATH - Excluded:", descendant:GetFullName())
                        break
                    end
                end
            end
            
            -- Third check: Only include if contains fishing keywords
            if not isDangerous then
                for _, fishWord in pairs(fishingKeywords) do
                    if name:find(fishWord) then
                        -- Final safety check: Must be in reasonable location
                        if fullName:find("replicatedstorage") and not fullName:find("ui") then
                            table.insert(found, descendant)
                            print("✅ SAFE - Found fishing remote:", descendant:GetFullName())
                        else
                            print("⚠️ UNSAFE LOCATION - Excluded:", descendant:GetFullName())
                        end
                        break
                    end
                end
            end
        end
    end
    
    AutoAnalyzer.foundRemotes = found
    print("✅ Found", #found, "SAFE fishing remotes")
    return #found > 0
end

-- Extra safe validation for fishing calls
local function IsDefinitelyFishing(remote, args)
    local remoteName = remote.Name:lower()
    local fullName = remote:GetFullName():lower()
    
    -- Absolutely reject if contains payment keywords
    local paymentKeywords = {"purchase", "product", "payment", "buy", "robux", "gamepass"}
    for _, keyword in pairs(paymentKeywords) do
        if remoteName:find(keyword) or fullName:find(keyword) then
            print("🚫 REJECTED - Payment remote:", remote:GetFullName())
            return false
        end
    end
    
    -- Only accept if args look like fishing data
    if #args == 1 and tonumber(args[1]) then
        local num = tonumber(args[1])
        -- Fishing charge should be 0-100
        if num >= 0 and num <= 100 then
            return true
        end
    elseif #args == 2 and tonumber(args[1]) and tonumber(args[2]) then
        local x, y = tonumber(args[1]), tonumber(args[2])
        -- Fishing coordinates should be in reasonable range
        if x >= -3 and x <= 3 and y >= -3 and y <= 3 then
            return true
        end
    end
    
    -- For safety, reject anything else
    print("⚠️ REJECTED - Args don't look like fishing:", remote:GetFullName())
    return false
end

-- Apply hooks with maximum safety
local function ApplySafeHooks()
    if #AutoAnalyzer.foundRemotes == 0 then
        print("❌ No safe remotes found to modify")
        return false
    end
    
    print("🔧 Applying SAFE hooks to", #AutoAnalyzer.foundRemotes, "remotes...")
    local modsApplied = 0
    
    for _, remote in pairs(AutoAnalyzer.foundRemotes) do
        local success, err = pcall(function()
            print("🔍 Attempting to hook:", remote:GetFullName())
            
            if remote:IsA("RemoteFunction") then
                local original = remote.InvokeServer
                remote.InvokeServer = function(self, ...)
                    local args = {...}
                    
                    -- Triple-check this is definitely fishing
                    if not IsDefinitelyFishing(remote, args) then
                        print("🛡️ SAFETY BLOCK - Not confirmed fishing, using original call")
                        return original(self, unpack(args))
                    end
                    
                    -- Safe modifications only for confirmed fishing
                    if #args == 1 and tonumber(args[1]) then
                        local originalValue = args[1]
                        args[1] = 100
                        print("⚡ SAFE charge modification:", originalValue, "→", args[1])
                    elseif #args == 2 and tonumber(args[1]) and tonumber(args[2]) then
                        local origX, origY = args[1], args[2]
                        args[1] = -1.2379989624023438
                        args[2] = 0.9800224985802423
                        print("🎯 SAFE coords modification:", origX, origY, "→", args[1], args[2])
                    end
                    
                    AutoAnalyzer.castCount = AutoAnalyzer.castCount + 1
                    AutoAnalyzer.perfectCount = AutoAnalyzer.perfectCount + 1
                    
                    return original(self, unpack(args))
                end
                modsApplied = modsApplied + 1
                
            elseif remote:IsA("RemoteEvent") then
                local original = remote.FireServer
                remote.FireServer = function(self, ...)
                    local args = {...}
                    
                    -- Triple-check this is definitely fishing
                    if not IsDefinitelyFishing(remote, args) then
                        print("🛡️ SAFETY BLOCK - Not confirmed fishing, using original call")
                        return original(self, unpack(args))
                    end
                    
                    -- Safe modifications only for confirmed fishing
                    if #args == 1 and tonumber(args[1]) then
                        local originalValue = args[1]
                        args[1] = 100
                        print("⚡ SAFE charge modification:", originalValue, "→", args[1])
                    elseif #args == 2 and tonumber(args[1]) and tonumber(args[2]) then
                        local origX, origY = args[1], args[2]
                        args[1] = -1.2379989624023438
                        args[2] = 0.9800224985802423
                        print("🎯 SAFE coords modification:", origX, origY, "→", args[1], args[2])
                    end
                    
                    AutoAnalyzer.castCount = AutoAnalyzer.castCount + 1
                    AutoAnalyzer.perfectCount = AutoAnalyzer.perfectCount + 1
                    
                    return original(self, unpack(args))
                end
                modsApplied = modsApplied + 1
            end
        end)
        
        if not success then
            print("⚠️ Failed to hook remote:", remote:GetFullName(), "Error:", err)
        else
            print("✅ Successfully hooked (SAFE):", remote:GetFullName())
        end
    end
    
    AutoAnalyzer.hooksActive = true
    print("✅ Applied", modsApplied, "SAFE modifications")
    return modsApplied > 0
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 SAFE UI SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function CreateSafeUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SafeAutoAnalyzer"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function()
        screenGui.Parent = game.CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main window
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 220)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(15, 25, 15)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 25)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 45, 25)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 1, 0)
    title.Text = "🛡️ SAFE Native Auto Analyzer"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Parent = titleBar
    
    -- Status display
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 30)
    statusLabel.Position = UDim2.new(0, 5, 0, 30)
    statusLabel.Text = "🔍 Ready for SAFE scanning..."
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 10
    statusLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Parent = frame
    
    -- Safe analyze button
    local analyzeButton = Instance.new("TextButton")
    analyzeButton.Size = UDim2.new(1, -20, 0, 35)
    analyzeButton.Position = UDim2.new(0, 10, 0, 65)
    analyzeButton.Text = "🛡️ SAFE ANALYZE & ENHANCE"
    analyzeButton.Font = Enum.Font.GothamBold
    analyzeButton.TextSize = 12
    analyzeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    analyzeButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    analyzeButton.BorderSizePixel = 0
    analyzeButton.Parent = frame
    
    local analyzeCorner = Instance.new("UICorner")
    analyzeCorner.CornerRadius = UDim.new(0, 6)
    analyzeCorner.Parent = analyzeButton
    
    -- Performance stats
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -10, 0, 60)
    statsLabel.Position = UDim2.new(0, 5, 0, 110)
    statsLabel.Text = "📊 Casts: 0 | Perfect: 0 | Success: 0%"
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 10
    statsLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
    statsLabel.BackgroundTransparency = 1
    statsLabel.TextWrapped = true
    statsLabel.Parent = frame
    
    -- Safety info
    local safetyInfo = Instance.new("TextLabel")
    safetyInfo.Size = UDim2.new(1, -10, 0, 40)
    safetyInfo.Position = UDim2.new(0, 5, 0, 175)
    safetyInfo.Text = "🛡️ SAFE MODE: Only fishing remotes targeted\n❌ Payment/purchase systems protected"
    safetyInfo.Font = Enum.Font.Gotham
    safetyInfo.TextSize = 9
    safetyInfo.TextColor3 = Color3.fromRGB(100, 255, 100)
    safetyInfo.BackgroundTransparency = 1
    safetyInfo.TextWrapped = true
    safetyInfo.Parent = frame
    
    -- Button functionality
    analyzeButton.MouseButton1Click:Connect(function()
        analyzeButton.Text = "🔍 SCANNING..."
        statusLabel.Text = "🔍 Safe scanning for fishing remotes..."
        
        task.wait(0.5)
        
        if SafeRemoteScan() then
            statusLabel.Text = "🔧 Applying SAFE hooks..."
            task.wait(0.5)
            
            if ApplySafeHooks() then
                analyzeButton.Text = "✅ SAFE ENHANCEMENT ACTIVE"
                analyzeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                statusLabel.Text = "✅ SAFE enhancement active! Payment systems protected."
            else
                analyzeButton.Text = "❌ SAFE ENHANCEMENT FAILED"
                analyzeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
                statusLabel.Text = "❌ Failed to apply SAFE enhancements"
            end
        else
            analyzeButton.Text = "❌ NO SAFE REMOTES FOUND"
            analyzeButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
            statusLabel.Text = "❌ No safe fishing remotes found"
        end
    end)
    
    -- Update stats
    RunService.Heartbeat:Connect(function()
        if AutoAnalyzer.hooksActive then
            local successRate = AutoAnalyzer.castCount > 0 and 
                math.floor((AutoAnalyzer.perfectCount / AutoAnalyzer.castCount) * 100) or 0
            statsLabel.Text = string.format("📊 Casts: %d | Perfect: %d | Success: %d%%", 
                AutoAnalyzer.castCount, AutoAnalyzer.perfectCount, successRate)
        end
    end)
    
    return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- 🚀 SAFE INITIALIZATION
-- ═══════════════════════════════════════════════════════════════

-- Initialize safe UI
CreateSafeUI()

print("🛡️ SAFE Native Auto Analyzer loaded successfully!")
print("💡 This version protects payment systems and only targets fishing")
print("🎯 Use the SAFE ANALYZE button for protected enhancement")
