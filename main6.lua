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

-- Smart Enchant Targeting System
local SmartEnchant = {
    enabled = false,
    targetEnchant = nil,
    targetFound = false,
    rollCount = 0,
    maxRolls = 50, -- Maximum rolls before stopping
    enchantDatabase = {
        -- Positive Enchants
        ["Stargazer I"] = { tier = 1, type = "luck", description = "+60% luck at night", rarity = "uncommon" },
        ["Glistening I"] = { tier = 1, type = "shiny", description = "Increase chance of obtaining shiny fish by 10%", rarity = "uncommon" },
        ["XPerienced I"] = { tier = 1, type = "xp", description = "1.5x more xp from all fish catches", rarity = "common" },
        ["Stormhunter I"] = { tier = 1, type = "weather", description = "+80% luck during rain", rarity = "rare" },
        ["Prismatic I"] = { tier = 1, type = "rainbow", description = "Rainbow boost activates with 10 less throws", rarity = "uncommon" },
        ["Mutation Hunter I"] = { tier = 1, type = "mutation", description = "10% more chance for mutation", rarity = "uncommon" },
        ["Big Hunter I"] = { tier = 1, type = "size", description = "Makes fish 10% bigger", rarity = "common" },
        ["Reeler I"] = { tier = 1, type = "speed", description = "Reel in fish +7% faster", rarity = "common" },
        ["Gold Digger I"] = { tier = 1, type = "gold", description = "10% chance to get Gold mutation", rarity = "rare" },
        ["Leprechaun I"] = { tier = 1, type = "luck", description = "+30% luck", rarity = "uncommon" },
        ["Empowered I"] = { tier = 1, type = "combo", description = "+20% luck, +10% faster reel", rarity = "rare" },
        ["Mutation Hunter II"] = { tier = 2, type = "mutation", description = "30% more chance for mutation", rarity = "rare" },
        ["Leprechaun II"] = { tier = 2, type = "luck", description = "+50% luck", rarity = "rare" },
        
        -- Negative Enchants
        ["Cursed I"] = { tier = 1, type = "negative", description = "-75% luck, +75% mutation chance", rarity = "cursed" }
    }
}

-- Auto Teleport Configuration (Global)
local ENCHANT_ALTAR_POSITION = CFrame.new(3237.61, -1302.33, 1398.04)
local ALTAR_DISTANCE_THRESHOLD = 50 -- Maximum distance from altar to enchant

-- Function to detect current enchantment from game UI
local function DetectCurrentEnchant()
    -- Try to find enchanting UI elements
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    -- Look for common enchanting UI names (adjust based on actual game UI)
    local possibleGuis = {"EnchantingGui", "EnchantGui", "AlchemyGui", "CraftingGui"}
    
    for _, guiName in pairs(possibleGuis) do
        local gui = playerGui:FindFirstChild(guiName)
        if gui then
            -- Look for text labels that might contain enchant names
            local function scanForEnchantText(parent)
                for _, child in pairs(parent:GetChildren()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        local text = child.Text
                        -- Check if text matches any known enchantment
                        for enchantName, _ in pairs(SmartEnchant.enchantDatabase) do
                            if text:find(enchantName) then
                                return enchantName
                            end
                        end
                    end
                    
                    -- Recursively scan children
                    local found = scanForEnchantText(child)
                    if found then return found end
                end
                return nil
            end
            
            local found = scanForEnchantText(gui)
            if found then return found end
        end
    end
    
    -- If no GUI detection works, simulate based on rarity weights for testing
    -- In real implementation, this should be removed and only GUI detection used
    local rarityWeights = {
        common = 40,     -- 40% chance
        uncommon = 30,   -- 30% chance  
        rare = 20,       -- 20% chance
        cursed = 10      -- 10% chance
    }
    
    local totalWeight = 0
    for _, weight in pairs(rarityWeights) do
        totalWeight = totalWeight + weight
    end
    
    local roll = math.random(1, totalWeight)
    local currentWeight = 0
    local selectedRarity = nil
    
    for rarity, weight in pairs(rarityWeights) do
        currentWeight = currentWeight + weight
        if roll <= currentWeight then
            selectedRarity = rarity
            break
        end
    end
    
    -- Get random enchant of selected rarity
    local enchantsOfRarity = {}
    for enchantName, data in pairs(SmartEnchant.enchantDatabase) do
        if data.rarity == selectedRarity then
            table.insert(enchantsOfRarity, enchantName)
        end
    end
    
    if #enchantsOfRarity > 0 then
        return enchantsOfRarity[math.random(1, #enchantsOfRarity)]
    end
    
    return nil
end

-- Helper function for Advanced features
local function GetRemote(name)
    local net = FindNet()
    if not net then return nil end
    local ok, rem = pcall(function() return net:FindFirstChild(name) end)
    return ok and rem or nil
end

local rodRemote = ResolveRemote("RF/ChargeFishingRod")
local miniGameRemote = ResolveRemote("RF/RequestFishingMinigameStarted")
local finishRemote = ResolveRemote("RE/FishingCompleted")
local equipRemote = ResolveRemote("RE/EquipToolFromHotbar")

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
    mode = "secure",
    autoRecastDelay = 0.6,
    safeModeChance = 70,
    secure_max_actions_per_minute = 120,
    secure_detection_cooldown = 5,
    enabled = false,
    antiAfkEnabled = false
}

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

local function DoFastCycle()
    if equipRemote then pcall(function() equipRemote:FireServer(1) end) end
    local usePerfect = math.random(1,100) <= Config.safeModeChance
    local timestamp = usePerfect and GetServerTime() or GetServerTime() + math.random()*0.5
    if rodRemote and rodRemote:IsA("RemoteFunction") then pcall(function() rodRemote:InvokeServer(timestamp) end) end
    task.wait(0.08 + math.random()*0.06)
    local x = usePerfect and -1.238 or (math.random(-1000,1000)/1000)
    local y = usePerfect and 0.969 or (math.random(0,1000)/1000)
    if miniGameRemote and miniGameRemote:IsA("RemoteFunction") then pcall(function() miniGameRemote:InvokeServer(x,y) end) end
    task.wait(1.0 + math.random()*0.4)
    if finishRemote then pcall(function() finishRemote:FireServer() end) end
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
end

local function AutofishRunner(mySession)
    Notify("modern_autofish", "AutoFishing started (mode: " .. Config.mode .. ")")
    while Config.enabled and sessionId == mySession do
        local ok, err = pcall(function()
            if Config.mode == "fast" then DoFastCycle() else DoSecureCycle() end
        end)
        if not ok then
            warn("modern_autofish: cycle error:", err)
            Notify("modern_autofish", "Cycle error: " .. tostring(err))
            task.wait(0.5 + math.random()*0.5)
        end
        local delay = Config.autoRecastDelay + (math.random()*0.2 - 0.1)
        if delay < 0.05 then delay = 0.05 end
        local elapsed = 0
        while elapsed < delay do
            if not Config.enabled or sessionId ~= mySession then break end
            task.wait(0.05)
            elapsed = elapsed + 0.05
        end
    end
    Notify("modern_autofish", "AutoFishing stopped")
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
    panel.Size = UDim2.new(0, 480, 0, 320)
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
    btnContainer.Size = UDim2.new(0, 110, 1, 0)
    -- place container near right edge but keep a small margin so it's not flush
    btnContainer.Position = UDim2.new(1, -120, 0, 0)
    btnContainer.BackgroundTransparency = 1

    -- Minimize: keep a small left padding inside container so it isn't flush
    local minimizeBtn = Instance.new("TextButton", btnContainer)
    minimizeBtn.Size = UDim2.new(0, 36, 0, 28)
    minimizeBtn.Position = UDim2.new(0, 8, 0.5, -14)
    minimizeBtn.Text = "_"
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 18
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,66); minimizeBtn.TextColor3 = Color3.fromRGB(230,230,230)
    Instance.new("UICorner", minimizeBtn)

    -- Close: anchored to right of container with right padding
    local closeBtn = Instance.new("TextButton", btnContainer)
    closeBtn.Size = UDim2.new(0, 36, 0, 28)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, -8, 0.5, -14)
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

    local dashboardTabBtn = Instance.new("TextButton", sidebar)
    dashboardTabBtn.Size = UDim2.new(1, -10, 0, 40)
    dashboardTabBtn.Position = UDim2.new(0, 5, 0, 210)
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

    local advancedTabBtn = Instance.new("TextButton", sidebar)
    advancedTabBtn.Size = UDim2.new(1, -10, 0, 40)
    advancedTabBtn.Position = UDim2.new(0, 5, 0, 260)
    advancedTabBtn.Text = "🚀 Advanced"
    advancedTabBtn.Font = Enum.Font.GothamSemibold
    advancedTabBtn.TextSize = 14
    advancedTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
    advancedTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
    advancedTabBtn.TextXAlignment = Enum.TextXAlignment.Left
    local advancedTabCorner = Instance.new("UICorner", advancedTabBtn)
    advancedTabCorner.CornerRadius = UDim.new(0, 6)
    local advancedTabPadding = Instance.new("UIPadding", advancedTabBtn)
    advancedTabPadding.PaddingLeft = UDim.new(0, 10)

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
    local modeLabel = Instance.new("TextLabel", leftCol); modeLabel.Size = UDim2.new(1,0,0,18); modeLabel.Text = "Mode"; modeLabel.BackgroundTransparency = 1; modeLabel.Font = Enum.Font.GothamSemibold; modeLabel.TextColor3 = Color3.fromRGB(200,200,200)
        local modeButtons = Instance.new("Frame", leftCol); modeButtons.Size = UDim2.new(1,-12,0,70); modeButtons.Position = UDim2.new(0,6,0,24); modeButtons.BackgroundTransparency = 1
        local fastButton = Instance.new("TextButton", modeButtons); fastButton.Size = UDim2.new(0.46,-6,0,34); fastButton.Position = UDim2.new(0,6,0,0); fastButton.Text = "Fast"; fastButton.BackgroundColor3 = Color3.fromRGB(75,95,165); local fastCorner = Instance.new("UICorner", fastButton); fastCorner.CornerRadius = UDim.new(0,8)
        local secureButton = Instance.new("TextButton", modeButtons); secureButton.Size = UDim2.new(0.46,-6,0,34); secureButton.Position = UDim2.new(0.52,6,0,0); secureButton.Text = "Secure"; secureButton.BackgroundColor3 = Color3.fromRGB(74,155,88); local secureCorner = Instance.new("UICorner", secureButton); secureCorner.CornerRadius = UDim.new(0,8)

    -- right: numeric controls
    local delayLabel = Instance.new("TextLabel", rightCol)
    delayLabel.Size = UDim2.new(1,0,0,18)
    delayLabel.Text = string.format("Recast Delay: %.2fs", Config.autoRecastDelay)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Font = Enum.Font.GothamSemibold
    delayLabel.TextColor3 = Color3.fromRGB(180,180,200)
    delayLabel.TextSize = 13
    local delayControls = Instance.new("Frame", rightCol)
    delayControls.Size = UDim2.new(1,0,0,28)
    delayControls.Position = UDim2.new(0,0,0,26)
    delayControls.BackgroundTransparency = 1
    delayControls.BackgroundColor3 = Color3.fromRGB(28,28,34)
    local delayMinus = Instance.new("TextButton", delayControls)
    delayMinus.Size = UDim2.new(0,32,1,0)
    delayMinus.Position = UDim2.new(0,4,0,0) -- small left padding
    delayMinus.Text = "-"
    delayMinus.BackgroundColor3 = Color3.fromRGB(72,72,72)
    delayMinus.TextColor3 = Color3.fromRGB(255,255,255)
    delayMinus.TextSize = 18
    Instance.new("UICorner", delayMinus)
    local delayPlus = Instance.new("TextButton", delayControls)
    delayPlus.Size = UDim2.new(0,32,1,0)
    delayPlus.Position = UDim2.new(1,-36,0,0) -- keep 4px gap from right edge
    delayPlus.Text = "+"
    delayPlus.BackgroundColor3 = Color3.fromRGB(72,72,72)
    delayPlus.TextColor3 = Color3.fromRGB(255,255,255)
    delayPlus.TextSize = 18
    Instance.new("UICorner", delayPlus)

    local chanceLabel = Instance.new("TextLabel", rightCol)
    chanceLabel.Size = UDim2.new(1,0,0,18)
    chanceLabel.Position = UDim2.new(0,0,0,58)
    chanceLabel.Text = string.format("Safe Perfect %%: %d", Config.safeModeChance)
    chanceLabel.BackgroundTransparency = 1
    chanceLabel.Font = Enum.Font.GothamSemibold
    chanceLabel.TextColor3 = Color3.fromRGB(180,180,200)
    chanceLabel.TextSize = 13
    local chanceControls = Instance.new("Frame", rightCol)
    chanceControls.Size = UDim2.new(1,0,0,28)
    chanceControls.Position = UDim2.new(0,0,0,82)
    chanceControls.BackgroundTransparency = 1
    chanceControls.BackgroundColor3 = Color3.fromRGB(28,28,34)
    local chanceMinus = Instance.new("TextButton", chanceControls)
    chanceMinus.Size = UDim2.new(0,32,1,0)
    chanceMinus.Position = UDim2.new(0,4,0,0)
    chanceMinus.Text = "-"
    chanceMinus.BackgroundColor3 = Color3.fromRGB(72,72,72)
    chanceMinus.TextColor3 = Color3.fromRGB(255,255,255)
    chanceMinus.TextSize = 18
    Instance.new("UICorner", chanceMinus)
    local chancePlus = Instance.new("TextButton", chanceControls)
    chancePlus.Size = UDim2.new(0,32,1,0)
    chancePlus.Position = UDim2.new(1,-36,0,0)
    chancePlus.Text = "+"
    chancePlus.BackgroundColor3 = Color3.fromRGB(72,72,72)
    chancePlus.TextColor3 = Color3.fromRGB(255,255,255)
    chancePlus.TextSize = 18
    Instance.new("UICorner", chancePlus)

    -- Sell All button in Main tab
    local sellBtn = Instance.new("TextButton", content)
    sellBtn.Size = UDim2.new(1, 0, 0, 32)
    sellBtn.Position = UDim2.new(0, 0, 1, -67)
    sellBtn.Text = "Sell All Items"
    sellBtn.Font = Enum.Font.GothamSemibold
    sellBtn.TextSize = 14
    sellBtn.BackgroundColor3 = Color3.fromRGB(180,120,60)
    sellBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", sellBtn)

    -- AntiAFK Section
    local antiAfkSection = Instance.new("Frame", content)
    antiAfkSection.Size = UDim2.new(1, 0, 0, 28)
    antiAfkSection.Position = UDim2.new(0, 0, 1, -35)
    antiAfkSection.BackgroundColor3 = Color3.fromRGB(35,35,42)
    antiAfkSection.BorderSizePixel = 0
    Instance.new("UICorner", antiAfkSection)

    local antiAfkLabel = Instance.new("TextLabel", antiAfkSection)
    antiAfkLabel.Size = UDim2.new(0.6, -10, 1, 0)
    antiAfkLabel.Position = UDim2.new(0, 10, 0, 0)
    antiAfkLabel.Text = "AntiAFK: Disabled"
    antiAfkLabel.Font = Enum.Font.GothamSemibold
    antiAfkLabel.TextSize = 12
    antiAfkLabel.TextColor3 = Color3.fromRGB(200,200,200)
    antiAfkLabel.BackgroundTransparency = 1
    antiAfkLabel.TextXAlignment = Enum.TextXAlignment.Left
    antiAfkLabel.TextYAlignment = Enum.TextYAlignment.Center

    local antiAfkToggle = Instance.new("TextButton", antiAfkSection)
    antiAfkToggle.Size = UDim2.new(0, 60, 0, 20)
    antiAfkToggle.Position = UDim2.new(1, -70, 0.5, -10)
    antiAfkToggle.Text = "OFF"
    antiAfkToggle.Font = Enum.Font.GothamBold
    antiAfkToggle.TextSize = 10
    antiAfkToggle.BackgroundColor3 = Color3.fromRGB(160,60,60)
    antiAfkToggle.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", antiAfkToggle)

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
        ["🗿ENCHANT STONE"] = CFrame.new(3237.61, -1302.33, 1398.04),
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

    -- Speed Control Section
    local speedSection = Instance.new("Frame", featureFrame)
    speedSection.Size = UDim2.new(1, 0, 0, 80)
    speedSection.Position = UDim2.new(0, 0, 0, 35)
    speedSection.BackgroundColor3 = Color3.fromRGB(35,35,42)
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
    local jumpSection = Instance.new("Frame", featureFrame)
    jumpSection.Size = UDim2.new(1, 0, 0, 80)
    jumpSection.Position = UDim2.new(0, 0, 0, 125)
    jumpSection.BackgroundColor3 = Color3.fromRGB(35,35,42)
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

    -- 📊 Dashboard Tab Content
    local dashboardFrame = Instance.new("Frame", contentContainer)
    dashboardFrame.Size = UDim2.new(1, 0, 1, -10)
    dashboardFrame.Position = UDim2.new(0, 0, 0, 0)
    dashboardFrame.BackgroundTransparency = 1
    dashboardFrame.Visible = false

    local dashboardTitle = Instance.new("TextLabel", dashboardFrame)
    dashboardTitle.Size = UDim2.new(1, 0, 0, 24)
    dashboardTitle.Text = "📊 Statistics Dashboard"
    dashboardTitle.Font = Enum.Font.GothamBold
    dashboardTitle.TextSize = 16
    dashboardTitle.TextColor3 = Color3.fromRGB(235,235,235)
    dashboardTitle.BackgroundTransparency = 1
    dashboardTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Simple stats display (no complex tracking for now)
    local statsContainer = Instance.new("Frame", dashboardFrame)
    statsContainer.Size = UDim2.new(1, 0, 0, 120)
    statsContainer.Position = UDim2.new(0, 0, 0, 35)
    statsContainer.BackgroundColor3 = Color3.fromRGB(35,35,42)
    statsContainer.BorderSizePixel = 0
    Instance.new("UICorner", statsContainer)

    local statsTitle = Instance.new("TextLabel", statsContainer)
    statsTitle.Size = UDim2.new(1, -20, 0, 20)
    statsTitle.Position = UDim2.new(0, 10, 0, 5)
    statsTitle.Text = "📈 Session Overview"
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.TextSize = 13
    statsTitle.TextColor3 = Color3.fromRGB(235,235,235)
    statsTitle.BackgroundTransparency = 1
    statsTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Stats grid (2x3)
    local statsGrid = Instance.new("Frame", statsContainer)
    statsGrid.Size = UDim2.new(1, -20, 1, -30)
    statsGrid.Position = UDim2.new(0, 10, 0, 25)
    statsGrid.BackgroundTransparency = 1

    -- Create simple stat cards
    local function createStatCard(parent, position, icon, label, value, color)
        local card = Instance.new("Frame", parent)
        card.Size = UDim2.new(0.32, 0, 0.45, 0)
        card.Position = position
        card.BackgroundColor3 = Color3.fromRGB(45,45,52)
        Instance.new("UICorner", card)
        
        local iconLabel = Instance.new("TextLabel", card)
        iconLabel.Size = UDim2.new(0, 20, 0, 20)
        iconLabel.Position = UDim2.new(0, 8, 0, 5)
        iconLabel.Text = icon
        iconLabel.Font = Enum.Font.GothamBold
        iconLabel.TextSize = 14
        iconLabel.BackgroundTransparency = 1
        iconLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        local valueLabel = Instance.new("TextLabel", card)
        valueLabel.Size = UDim2.new(1, -35, 0, 16)
        valueLabel.Position = UDim2.new(0, 30, 0, 6)
        valueLabel.Text = value
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 16
        valueLabel.TextColor3 = color
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local nameLabel = Instance.new("TextLabel", card)
        nameLabel.Size = UDim2.new(1, -10, 0, 12)
        nameLabel.Position = UDim2.new(0, 5, 1, -17)
        nameLabel.Text = label
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 9
        nameLabel.TextColor3 = Color3.fromRGB(180,180,180)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        return valueLabel
    end

    -- Create stat cards
    local fishCountLabel = createStatCard(statsGrid, UDim2.new(0, 0, 0, 0), "🐟", "Fish Caught", "0", Color3.fromRGB(120,200,255))
    local rareFishLabel = createStatCard(statsGrid, UDim2.new(0.34, 0, 0, 0), "⭐", "Rare Fish", "0", Color3.fromRGB(255,215,0))
    local timeLabel = createStatCard(statsGrid, UDim2.new(0.68, 0, 0, 0), "⏱️", "Session Time", "0s", Color3.fromRGB(150,255,150))
    
    local statusLabel = createStatCard(statsGrid, UDim2.new(0, 0, 0.55, 0), "🎣", "Status", "Ready", Color3.fromRGB(255,150,255))
    local modeLabel = createStatCard(statsGrid, UDim2.new(0.34, 0, 0.55, 0), "⚡", "Mode", "Secure", Color3.fromRGB(150,220,255))
    local antiafkLabel = createStatCard(statsGrid, UDim2.new(0.68, 0, 0.55, 0), "🛡️", "AntiAFK", "Disabled", Color3.fromRGB(255,120,120))

    -- Control section
    local controlSection = Instance.new("Frame", dashboardFrame)
    controlSection.Size = UDim2.new(1, 0, 0, 60)
    controlSection.Position = UDim2.new(0, 0, 0, 170)
    controlSection.BackgroundColor3 = Color3.fromRGB(35,35,42)
    controlSection.BorderSizePixel = 0
    Instance.new("UICorner", controlSection)

    local controlTitle = Instance.new("TextLabel", controlSection)
    controlTitle.Size = UDim2.new(1, -20, 0, 20)
    controlTitle.Position = UDim2.new(0, 10, 0, 5)
    controlTitle.Text = "🎛️ Quick Controls"
    controlTitle.Font = Enum.Font.GothamBold
    controlTitle.TextSize = 13
    controlTitle.TextColor3 = Color3.fromRGB(235,235,235)
    controlTitle.BackgroundTransparency = 1
    controlTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Quick action buttons
    local refreshBtn = Instance.new("TextButton", controlSection)
    refreshBtn.Size = UDim2.new(0, 80, 0, 28)
    refreshBtn.Position = UDim2.new(0, 15, 0, 27)
    refreshBtn.Text = "🔄 Refresh"
    refreshBtn.Font = Enum.Font.GothamSemibold
    refreshBtn.TextSize = 10
    refreshBtn.BackgroundColor3 = Color3.fromRGB(60,120,180)
    refreshBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", refreshBtn)

    local resetBtn = Instance.new("TextButton", controlSection)
    resetBtn.Size = UDim2.new(0, 80, 0, 28)
    resetBtn.Position = UDim2.new(0, 105, 0, 27)
    resetBtn.Text = "🔄 Reset"
    resetBtn.Font = Enum.Font.GothamSemibold
    resetBtn.TextSize = 10
    resetBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
    resetBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", resetBtn)

    local exportBtn = Instance.new("TextButton", controlSection)
    exportBtn.Size = UDim2.new(0, 80, 0, 28)
    exportBtn.Position = UDim2.new(0, 195, 0, 27)
    exportBtn.Text = "📋 Export"
    exportBtn.Font = Enum.Font.GothamSemibold
    exportBtn.TextSize = 10
    exportBtn.BackgroundColor3 = Color3.fromRGB(180,120,60)
    exportBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", exportBtn)

    -- Simple update function for dashboard
    local sessionStartTime = tick()
    local totalFishCaught = 0
    local rareFishCaught = 0
    
    -- Fish detection system
    local function initializeFishTracking()
        -- Try to find Fish It remotes for tracking
        pcall(function()
            local fishCaughtRemote = net and net:FindFirstChild("RE") and net.RE:FindFirstChild("FishCaught")
            local newFishRemote = net and net:FindFirstChild("RE") and net.RE:FindFirstChild("ObtainedNewFishNotification")
            
            if fishCaughtRemote then
                fishCaughtRemote.OnClientEvent:Connect(function(fishData)
                    totalFishCaught = totalFishCaught + 1
                    
                    -- Simple rare fish detection based on common patterns
                    if fishData and type(fishData) == "table" then
                        local fishName = fishData.Name or fishData.FishName or ""
                        local rarity = fishData.Rarity or fishData.RarityLevel or ""
                        
                        -- Check for rare indicators
                        if string.find(string.lower(fishName), "rare") or 
                           string.find(string.lower(fishName), "legendary") or
                           string.find(string.lower(fishName), "epic") or
                           string.find(string.lower(rarity), "rare") or
                           string.find(string.lower(rarity), "legendary") or
                           string.find(string.lower(rarity), "epic") then
                            rareFishCaught = rareFishCaught + 1
                        end
                    end
                    
                    if dashboardFrame.Visible then
                        updateDashboard()
                    end
                end)
            end
            
            if newFishRemote then
                newFishRemote.OnClientEvent:Connect(function(fishData)
                    -- New fish notifications usually indicate rare catches
                    rareFishCaught = rareFishCaught + 1
                    if dashboardFrame.Visible then
                        updateDashboard()
                    end
                end)
            end
        end)
    end
    
    -- Initialize fish tracking
    initializeFishTracking()
    
    local function updateDashboard()
        local elapsed = tick() - sessionStartTime
        local minutes = math.floor(elapsed / 60)
        local seconds = math.floor(elapsed % 60)
        timeLabel.Text = string.format("%dm %ds", minutes, seconds)
        
        fishCountLabel.Text = tostring(totalFishCaught)
        rareFishLabel.Text = tostring(rareFishCaught)
        modeLabel.Text = Config.mode:upper()
        statusLabel.Text = Config.enabled and "Running" or "Stopped"
        statusLabel.TextColor3 = Config.enabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
        antiafkLabel.Text = AntiAFK.enabled and "Enabled" or "Disabled"
        antiafkLabel.TextColor3 = AntiAFK.enabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,120,120)
    end

    -- Button actions
    refreshBtn.MouseButton1Click:Connect(function()
        updateDashboard()
        Notify("Dashboard", "Stats refreshed!")
    end)

    resetBtn.MouseButton1Click:Connect(function()
        totalFishCaught = 0
        rareFishCaught = 0
        sessionStartTime = tick()
        updateDashboard()
        Notify("Dashboard", "Stats reset successfully!")
    end)

    exportBtn.MouseButton1Click:Connect(function()
        local elapsed = tick() - sessionStartTime
        local rarePercentage = totalFishCaught > 0 and (rareFishCaught / totalFishCaught * 100) or 0
        local report = string.format(
            "📊 AutoFish Dashboard Report\n" ..
            "═══════════════════════════\n" ..
            "🐟 Total Fish: %d\n" ..
            "⭐ Rare Fish: %d (%.1f%%)\n" ..
            "⏱️ Session Time: %dm %ds\n" ..
            "⚡ Mode: %s\n" ..
            "🎣 Status: %s\n" ..
            "🛡️ AntiAFK: %s\n" ..
            "═══════════════════════════\n" ..
            "Generated: %s",
            totalFishCaught,
            rareFishCaught, rarePercentage,
            math.floor(elapsed / 60), math.floor(elapsed % 60),
            Config.mode:upper(),
            Config.enabled and "Running" or "Stopped",
            AntiAFK.enabled and "Enabled" or "Disabled",
            os.date("%Y-%m-%d %H:%M:%S")
        )
        
        print(report)
        pcall(function() setclipboard(report) end)
        Notify("Dashboard", "Report exported to console & clipboard!")
    end)

    -- Auto-update dashboard every second when visible
    spawn(function()
        while true do
            task.wait(1)
            if dashboardFrame.Visible then
                updateDashboard()
            end
        end
    end)

    -- 🚀 Advanced Tab Content
    local advancedFrame = Instance.new("Frame", contentContainer)
    advancedFrame.Size = UDim2.new(1, 0, 1, -10)
    advancedFrame.Position = UDim2.new(0, 0, 0, 0)
    advancedFrame.BackgroundTransparency = 1
    advancedFrame.Visible = false

    local advancedTitle = Instance.new("TextLabel", advancedFrame)
    advancedTitle.Size = UDim2.new(1, 0, 0, 24)
    advancedTitle.Text = "🚀 Advanced Automation"
    advancedTitle.Font = Enum.Font.GothamBold
    advancedTitle.TextSize = 16
    advancedTitle.TextColor3 = Color3.fromRGB(235,235,235)
    advancedTitle.BackgroundTransparency = 1
    advancedTitle.TextXAlignment = Enum.TextXAlignment.Left

    local advancedScroll = Instance.new("ScrollingFrame", advancedFrame)
    advancedScroll.Size = UDim2.new(1, 0, 1, -40)
    advancedScroll.Position = UDim2.new(0, 0, 0, 30)
    advancedScroll.BackgroundTransparency = 1
    advancedScroll.BorderSizePixel = 0
    advancedScroll.ScrollBarThickness = 4
    advancedScroll.ScrollBarImageColor3 = Color3.fromRGB(64,64,64)
    advancedScroll.CanvasSize = UDim2.new(0, 0, 0, 900)

    -- Weather Event Section
    local weatherSection = Instance.new("Frame", advancedScroll)
    weatherSection.Size = UDim2.new(1, 0, 0, 150)
    weatherSection.Position = UDim2.new(0, 0, 0, 10)
    weatherSection.BackgroundColor3 = Color3.fromRGB(48,48,54)
    local weatherCorner = Instance.new("UICorner", weatherSection)
    weatherCorner.CornerRadius = UDim.new(0, 8)

    local weatherTitle = Instance.new("TextLabel", weatherSection)
    weatherTitle.Size = UDim2.new(1, -20, 0, 30)
    weatherTitle.Position = UDim2.new(0, 10, 0, 10)
    weatherTitle.Text = "🌤️ Weather Event Automation"
    weatherTitle.Font = Enum.Font.GothamBold
    weatherTitle.TextSize = 14
    weatherTitle.TextColor3 = Color3.fromRGB(255,193,7)
    weatherTitle.BackgroundTransparency = 1
    weatherTitle.TextXAlignment = Enum.TextXAlignment.Left

    local weatherDesc = Instance.new("TextLabel", weatherSection)
    weatherDesc.Size = UDim2.new(1, -20, 0, 40)
    weatherDesc.Position = UDim2.new(0, 10, 0, 40)
    weatherDesc.Text = "Automatically purchase weather effects for optimal fishing conditions"
    weatherDesc.Font = Enum.Font.Gotham
    weatherDesc.TextSize = 12
    weatherDesc.TextColor3 = Color3.fromRGB(180,180,180)
    weatherDesc.BackgroundTransparency = 1
    weatherDesc.TextXAlignment = Enum.TextXAlignment.Left
    weatherDesc.TextWrapped = true

    local weatherToggle = Instance.new("TextButton", weatherSection)
    weatherToggle.Size = UDim2.new(0, 120, 0, 30)
    weatherToggle.Position = UDim2.new(0, 10, 0, 90)
    weatherToggle.Text = "Auto Weather: OFF"
    weatherToggle.Font = Enum.Font.GothamSemibold
    weatherToggle.TextSize = 12
    weatherToggle.BackgroundColor3 = Color3.fromRGB(220,53,69)
    weatherToggle.TextColor3 = Color3.fromRGB(255,255,255)
    local weatherToggleCorner = Instance.new("UICorner", weatherToggle)
    weatherToggleCorner.CornerRadius = UDim.new(0, 6)

    local weatherBuyBtn = Instance.new("TextButton", weatherSection)
    weatherBuyBtn.Size = UDim2.new(0, 100, 0, 30)
    weatherBuyBtn.Position = UDim2.new(0, 140, 0, 90)
    weatherBuyBtn.Text = "Buy Event"
    weatherBuyBtn.Font = Enum.Font.GothamSemibold
    weatherBuyBtn.TextSize = 12
    weatherBuyBtn.BackgroundColor3 = Color3.fromRGB(40,167,69)
    weatherBuyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local weatherBuyCorner = Instance.new("UICorner", weatherBuyBtn)
    weatherBuyCorner.CornerRadius = UDim.new(0, 6)

    -- Boat Management Section
    local boatSection = Instance.new("Frame", advancedScroll)
    boatSection.Size = UDim2.new(1, 0, 0, 180)
    boatSection.Position = UDim2.new(0, 0, 0, 170)
    boatSection.BackgroundColor3 = Color3.fromRGB(48,48,54)
    local boatCorner = Instance.new("UICorner", boatSection)
    boatCorner.CornerRadius = UDim.new(0, 8)

    local boatTitle = Instance.new("TextLabel", boatSection)
    boatTitle.Size = UDim2.new(1, -20, 0, 30)
    boatTitle.Position = UDim2.new(0, 10, 0, 10)
    boatTitle.Text = "🚢 Boat Management"
    boatTitle.Font = Enum.Font.GothamBold
    boatTitle.TextSize = 14
    boatTitle.TextColor3 = Color3.fromRGB(52,152,219)
    boatTitle.BackgroundTransparency = 1
    boatTitle.TextXAlignment = Enum.TextXAlignment.Left

    local boatDesc = Instance.new("TextLabel", boatSection)
    boatDesc.Size = UDim2.new(1, -20, 0, 30)
    boatDesc.Position = UDim2.new(0, 10, 0, 40)
    boatDesc.Text = "Smart boat spawning and positioning for optimal fishing spots"
    boatDesc.Font = Enum.Font.Gotham
    boatDesc.TextSize = 12
    boatDesc.TextColor3 = Color3.fromRGB(180,180,180)
    boatDesc.BackgroundTransparency = 1
    boatDesc.TextXAlignment = Enum.TextXAlignment.Left
    boatDesc.TextWrapped = true

    -- Boat selector dropdown
    local boatSelectorLabel = Instance.new("TextLabel", boatSection)
    boatSelectorLabel.Size = UDim2.new(0, 100, 0, 20)
    boatSelectorLabel.Position = UDim2.new(0, 10, 0, 75)
    boatSelectorLabel.Text = "Select Boat:"
    boatSelectorLabel.Font = Enum.Font.GothamSemibold
    boatSelectorLabel.TextSize = 11
    boatSelectorLabel.TextColor3 = Color3.fromRGB(200,200,200)
    boatSelectorLabel.BackgroundTransparency = 1
    boatSelectorLabel.TextXAlignment = Enum.TextXAlignment.Left

    local boatSelector = Instance.new("TextButton", boatSection)
    boatSelector.Size = UDim2.new(1, -20, 0, 25)
    boatSelector.Position = UDim2.new(0, 10, 0, 95)
    boatSelector.Text = "Auto-Detect Boat ▼"
    boatSelector.Font = Enum.Font.GothamSemibold
    boatSelector.TextSize = 11
    boatSelector.BackgroundColor3 = Color3.fromRGB(50,50,60)
    boatSelector.TextColor3 = Color3.fromRGB(255,255,255)
    boatSelector.TextXAlignment = Enum.TextXAlignment.Left
    local boatSelectorCorner = Instance.new("UICorner", boatSelector)
    boatSelectorCorner.CornerRadius = UDim.new(0, 4)
    local boatSelectorPadding = Instance.new("UIPadding", boatSelector)
    boatSelectorPadding.PaddingLeft = UDim.new(0, 8)

    local spawnBoatBtn = Instance.new("TextButton", boatSection)
    spawnBoatBtn.Size = UDim2.new(0, 100, 0, 30)
    spawnBoatBtn.Position = UDim2.new(0, 10, 0, 130)
    spawnBoatBtn.Text = "Spawn Boat"
    spawnBoatBtn.Font = Enum.Font.GothamSemibold
    spawnBoatBtn.TextSize = 12
    spawnBoatBtn.BackgroundColor3 = Color3.fromRGB(40,167,69)
    spawnBoatBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local spawnBoatCorner = Instance.new("UICorner", spawnBoatBtn)
    spawnBoatCorner.CornerRadius = UDim.new(0, 6)

    local despawnBoatBtn = Instance.new("TextButton", boatSection)
    despawnBoatBtn.Size = UDim2.new(0, 100, 0, 30)
    despawnBoatBtn.Position = UDim2.new(0, 120, 0, 130)
    despawnBoatBtn.Text = "Despawn"
    despawnBoatBtn.Font = Enum.Font.GothamSemibold
    despawnBoatBtn.TextSize = 12
    despawnBoatBtn.BackgroundColor3 = Color3.fromRGB(220,53,69)
    despawnBoatBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local despawnBoatCorner = Instance.new("UICorner", despawnBoatBtn)
    despawnBoatCorner.CornerRadius = UDim.new(0, 6)

    -- Enchanting Section
    local enchantSection = Instance.new("Frame", advancedScroll)
    enchantSection.Size = UDim2.new(1, 0, 0, 230)
    enchantSection.Position = UDim2.new(0, 0, 0, 330)
    enchantSection.BackgroundColor3 = Color3.fromRGB(48,48,54)
    local enchantCorner = Instance.new("UICorner", enchantSection)
    enchantCorner.CornerRadius = UDim.new(0, 8)

    local enchantTitle = Instance.new("TextLabel", enchantSection)
    enchantTitle.Size = UDim2.new(1, -20, 0, 30)
    enchantTitle.Position = UDim2.new(0, 10, 0, 10)
    enchantTitle.Text = "💎 Enchanting Integration"
    enchantTitle.Font = Enum.Font.GothamBold
    enchantTitle.TextSize = 14
    enchantTitle.TextColor3 = Color3.fromRGB(138,43,226)
    enchantTitle.BackgroundTransparency = 1
    enchantTitle.TextXAlignment = Enum.TextXAlignment.Left

    local enchantDesc = Instance.new("TextLabel", enchantSection)
    enchantDesc.Size = UDim2.new(1, -20, 0, 40)
    enchantDesc.Position = UDim2.new(0, 10, 0, 40)
    enchantDesc.Text = "Requirements: 1) Get enchant stone from items 2) Equip stone 3) Go to altar"
    enchantDesc.Font = Enum.Font.Gotham
    enchantDesc.TextSize = 12
    enchantDesc.TextColor3 = Color3.fromRGB(180,180,180)
    enchantDesc.BackgroundTransparency = 1
    enchantDesc.TextXAlignment = Enum.TextXAlignment.Left
    enchantDesc.TextWrapped = true

    local enchantToggle = Instance.new("TextButton", enchantSection)
    enchantToggle.Size = UDim2.new(0, 120, 0, 30)
    enchantToggle.Position = UDim2.new(0, 10, 0, 90)
    enchantToggle.Text = "Auto Enchant: OFF"
    enchantToggle.Font = Enum.Font.GothamSemibold
    enchantToggle.TextSize = 12
    enchantToggle.BackgroundColor3 = Color3.fromRGB(220,53,69)
    enchantToggle.TextColor3 = Color3.fromRGB(255,255,255)
    local enchantToggleCorner = Instance.new("UICorner", enchantToggle)
    enchantToggleCorner.CornerRadius = UDim.new(0, 6)

    local rollEnchantBtn = Instance.new("TextButton", enchantSection)
    rollEnchantBtn.Size = UDim2.new(0, 100, 0, 30)
    rollEnchantBtn.Position = UDim2.new(0, 140, 0, 90)
    rollEnchantBtn.Text = "Roll Enchant"
    rollEnchantBtn.Font = Enum.Font.GothamSemibold
    rollEnchantBtn.TextSize = 12
    rollEnchantBtn.BackgroundColor3 = Color3.fromRGB(138,43,226)
    rollEnchantBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local rollEnchantCorner = Instance.new("UICorner", rollEnchantBtn)
    rollEnchantCorner.CornerRadius = UDim.new(0, 6)

    -- Auto Equip toggle
    local autoEquipToggle = Instance.new("TextButton", enchantSection)
    autoEquipToggle.Size = UDim2.new(0, 100, 0, 30)
    autoEquipToggle.Position = UDim2.new(0, 250, 0, 90)
    autoEquipToggle.Text = "Auto Equip: ON"
    autoEquipToggle.Font = Enum.Font.GothamSemibold
    autoEquipToggle.TextSize = 11
    autoEquipToggle.BackgroundColor3 = Color3.fromRGB(40,167,69)
    autoEquipToggle.TextColor3 = Color3.fromRGB(255,255,255)
    local autoEquipCorner = Instance.new("UICorner", autoEquipToggle)
    autoEquipCorner.CornerRadius = UDim.new(0, 6)

    -- Auto Teleport to Altar toggle
    local autoTeleportToggle = Instance.new("TextButton", enchantSection)
    autoTeleportToggle.Size = UDim2.new(0, 100, 0, 30)
    autoTeleportToggle.Position = UDim2.new(0, 360, 0, 90)
    autoTeleportToggle.Text = "Auto Teleport: ON"
    autoTeleportToggle.Font = Enum.Font.GothamSemibold
    autoTeleportToggle.TextSize = 9
    autoTeleportToggle.BackgroundColor3 = Color3.fromRGB(40,167,69)
    autoTeleportToggle.TextColor3 = Color3.fromRGB(255,255,255)
    local autoTeleportCorner = Instance.new("UICorner", autoTeleportToggle)
    autoTeleportCorner.CornerRadius = UDim.new(0, 6)

    -- Manual Teleport to Altar button
    local manualTeleportBtn = Instance.new("TextButton", enchantSection)
    manualTeleportBtn.Size = UDim2.new(0, 100, 0, 25)
    manualTeleportBtn.Position = UDim2.new(0, 470, 0, 90)
    manualTeleportBtn.Text = "📍 Go to Altar"
    manualTeleportBtn.Font = Enum.Font.GothamSemibold
    manualTeleportBtn.TextSize = 10
    manualTeleportBtn.BackgroundColor3 = Color3.fromRGB(75,0,130)
    manualTeleportBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local manualTeleportCorner = Instance.new("UICorner", manualTeleportBtn)
    manualTeleportCorner.CornerRadius = UDim.new(0, 6)

    -- Smart Enchant Targeting Section
    local smartTargetSection = Instance.new("Frame", enchantSection)
    smartTargetSection.Size = UDim2.new(1, -20, 0, 120)
    smartTargetSection.Position = UDim2.new(0, 10, 0, 130)
    smartTargetSection.BackgroundColor3 = Color3.fromRGB(40,40,46)
    local smartTargetCorner = Instance.new("UICorner", smartTargetSection)
    smartTargetCorner.CornerRadius = UDim.new(0, 6)

    local smartTargetTitle = Instance.new("TextLabel", smartTargetSection)
    smartTargetTitle.Size = UDim2.new(1, -10, 0, 20)
    smartTargetTitle.Position = UDim2.new(0, 5, 0, 5)
    smartTargetTitle.Text = "🎯 Smart Target Enchant"
    smartTargetTitle.Font = Enum.Font.GothamBold
    smartTargetTitle.TextSize = 11
    smartTargetTitle.TextColor3 = Color3.fromRGB(255,215,0)
    smartTargetTitle.BackgroundTransparency = 1
    smartTargetTitle.TextXAlignment = Enum.TextXAlignment.Left

    -- Target enchant dropdown/selector
    local targetEnchantSelector = Instance.new("TextButton", smartTargetSection)
    targetEnchantSelector.Size = UDim2.new(0.6, -5, 0, 25)
    targetEnchantSelector.Position = UDim2.new(0, 5, 0, 25)
    targetEnchantSelector.Text = "📋 Open Enchant List"
    targetEnchantSelector.Font = Enum.Font.Gotham
    targetEnchantSelector.TextSize = 10
    targetEnchantSelector.BackgroundColor3 = Color3.fromRGB(70,130,180)
    targetEnchantSelector.TextColor3 = Color3.fromRGB(255,255,255)
    local targetEnchantCorner = Instance.new("UICorner", targetEnchantSelector)
    targetEnchantCorner.CornerRadius = UDim.new(0, 4)

    -- Smart target toggle
    local smartTargetToggle = Instance.new("TextButton", smartTargetSection)
    smartTargetToggle.Size = UDim2.new(0.35, -5, 0, 25)
    smartTargetToggle.Position = UDim2.new(0.65, 0, 0, 25)
    smartTargetToggle.Text = "Target: OFF"
    smartTargetToggle.Font = Enum.Font.GothamSemibold
    smartTargetToggle.TextSize = 10
    smartTargetToggle.BackgroundColor3 = Color3.fromRGB(160,60,60)
    smartTargetToggle.TextColor3 = Color3.fromRGB(255,255,255)
    local smartTargetToggleCorner = Instance.new("UICorner", smartTargetToggle)
    smartTargetToggleCorner.CornerRadius = UDim.new(0, 4)

    -- Target status label
    local targetStatusLabel = Instance.new("TextLabel", smartTargetSection)
    targetStatusLabel.Size = UDim2.new(1, -10, 0, 20)
    targetStatusLabel.Position = UDim2.new(0, 5, 0, 55)
    targetStatusLabel.Text = "Status: No target selected"
    targetStatusLabel.Font = Enum.Font.Gotham
    targetStatusLabel.TextSize = 9
    targetStatusLabel.TextColor3 = Color3.fromRGB(150,150,150)
    targetStatusLabel.BackgroundTransparency = 1
    targetStatusLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Quick target buttons for popular enchants
    local quickTargetFrame = Instance.new("Frame", smartTargetSection)
    quickTargetFrame.Size = UDim2.new(1, -10, 0, 35)
    quickTargetFrame.Position = UDim2.new(0, 5, 0, 75)
    quickTargetFrame.BackgroundTransparency = 1

    local quickTargetLabel = Instance.new("TextLabel", quickTargetFrame)
    quickTargetLabel.Size = UDim2.new(1, 0, 0, 12)
    quickTargetLabel.Text = "Quick Select:"
    quickTargetLabel.Font = Enum.Font.Gotham
    quickTargetLabel.TextSize = 8
    quickTargetLabel.TextColor3 = Color3.fromRGB(180,180,180)
    quickTargetLabel.BackgroundTransparency = 1
    quickTargetLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Quick buttons for popular enchants
    local quickEnchants = {"Stargazer I", "Gold Digger I", "Mutation Hunter II", "Cursed I"}
    for i, enchantName in ipairs(quickEnchants) do
        local quickBtn = Instance.new("TextButton", quickTargetFrame)
        quickBtn.Size = UDim2.new(0.23, 0, 0, 20)
        quickBtn.Position = UDim2.new((i-1) * 0.25, 2, 0, 15)
        quickBtn.Text = enchantName:gsub(" I+", ""):sub(1,8) -- Shorten name
        quickBtn.Font = Enum.Font.Gotham
        quickBtn.TextSize = 7
        quickBtn.BackgroundColor3 = Color3.fromRGB(60,90,120)
        quickBtn.TextColor3 = Color3.fromRGB(255,255,255)
        local quickBtnCorner = Instance.new("UICorner", quickBtn)
        quickBtnCorner.CornerRadius = UDim.new(0, 3)
        
        quickBtn.MouseButton1Click:Connect(function()
            SmartEnchant.targetEnchant = enchantName
            targetEnchantSelector.Text = "Selected: " .. enchantName:sub(1,12) .. "..."
            targetStatusLabel.Text = "Target: " .. enchantName
            Notify("🎯 Smart Target", "Quick selected: " .. enchantName)
        end)
    end

    -- Trading Section
    local tradeSection = Instance.new("Frame", advancedScroll)
    tradeSection.Size = UDim2.new(1, 0, 0, 150)
    tradeSection.Position = UDim2.new(0, 0, 0, 570)
    tradeSection.BackgroundColor3 = Color3.fromRGB(48,48,54)
    local tradeCorner = Instance.new("UICorner", tradeSection)
    tradeCorner.CornerRadius = UDim.new(0, 8)

    local tradeTitle = Instance.new("TextLabel", tradeSection)
    tradeTitle.Size = UDim2.new(1, -20, 0, 30)
    tradeTitle.Position = UDim2.new(0, 10, 0, 10)
    tradeTitle.Text = "🔄 Trading System"
    tradeTitle.Font = Enum.Font.GothamBold
    tradeTitle.TextSize = 14
    tradeTitle.TextColor3 = Color3.fromRGB(255,152,0)
    tradeTitle.BackgroundTransparency = 1
    tradeTitle.TextXAlignment = Enum.TextXAlignment.Left

    local tradeDesc = Instance.new("TextLabel", tradeSection)
    tradeDesc.Size = UDim2.new(1, -20, 0, 40)
    tradeDesc.Position = UDim2.new(0, 10, 0, 40)
    tradeDesc.Text = "Smart trading automation for optimizing fish values and exchanges"
    tradeDesc.Font = Enum.Font.Gotham
    tradeDesc.TextSize = 12
    tradeDesc.TextColor3 = Color3.fromRGB(180,180,180)
    tradeDesc.BackgroundTransparency = 1
    tradeDesc.TextXAlignment = Enum.TextXAlignment.Left
    tradeDesc.TextWrapped = true

    local tradeToggle = Instance.new("TextButton", tradeSection)
    tradeToggle.Size = UDim2.new(0, 120, 0, 30)
    tradeToggle.Position = UDim2.new(0, 10, 0, 90)
    tradeToggle.Text = "Auto Trade: OFF"
    tradeToggle.Font = Enum.Font.GothamSemibold
    tradeToggle.TextSize = 12
    tradeToggle.BackgroundColor3 = Color3.fromRGB(220,53,69)
    tradeToggle.TextColor3 = Color3.fromRGB(255,255,255)
    local tradeToggleCorner = Instance.new("UICorner", tradeToggle)
    tradeToggleCorner.CornerRadius = UDim.new(0, 6)

    local initiateTradeBtn = Instance.new("TextButton", tradeSection)
    initiateTradeBtn.Size = UDim2.new(0, 100, 0, 30)
    initiateTradeBtn.Position = UDim2.new(0, 140, 0, 90)
    initiateTradeBtn.Text = "Initiate Trade"
    initiateTradeBtn.Font = Enum.Font.GothamSemibold
    initiateTradeBtn.TextSize = 12
    initiateTradeBtn.BackgroundColor3 = Color3.fromRGB(255,152,0)
    initiateTradeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local initiateTradeCorner = Instance.new("UICorner", initiateTradeBtn)
    initiateTradeCorner.CornerRadius = UDim.new(0, 6)

    -- Data Export Section
    local dataSection = Instance.new("Frame", advancedScroll)
    dataSection.Size = UDim2.new(1, 0, 0, 140)
    dataSection.Position = UDim2.new(0, 0, 0, 880)
    dataSection.BackgroundColor3 = Color3.fromRGB(48,48,54)
    local dataCorner = Instance.new("UICorner", dataSection)
    dataCorner.CornerRadius = UDim.new(0, 8)

    local dataTitle = Instance.new("TextLabel", dataSection)
    dataTitle.Size = UDim2.new(1, -20, 0, 30)
    dataTitle.Position = UDim2.new(0, 10, 0, 10)
    dataTitle.Text = "💾 Data Export & Save"
    dataTitle.Font = Enum.Font.GothamBold
    dataTitle.TextSize = 14
    dataTitle.TextColor3 = Color3.fromRGB(156,39,176)
    dataTitle.BackgroundTransparency = 1
    dataTitle.TextXAlignment = Enum.TextXAlignment.Left

    local dataDesc = Instance.new("TextLabel", dataSection)
    dataDesc.Size = UDim2.new(1, -20, 0, 30)
    dataDesc.Position = UDim2.new(0, 10, 0, 40)
    dataDesc.Text = "Export game data, remotes, boats, and script configurations to files"
    dataDesc.Font = Enum.Font.Gotham
    dataDesc.TextSize = 12
    dataDesc.TextColor3 = Color3.fromRGB(180,180,180)
    dataDesc.BackgroundTransparency = 1
    dataDesc.TextXAlignment = Enum.TextXAlignment.Left
    dataDesc.TextWrapped = true

    local exportDataBtn = Instance.new("TextButton", dataSection)
    exportDataBtn.Size = UDim2.new(0, 120, 0, 30)
    exportDataBtn.Position = UDim2.new(0, 10, 0, 80)
    exportDataBtn.Text = "📁 Export Data"
    exportDataBtn.Font = Enum.Font.GothamSemibold
    exportDataBtn.TextSize = 12
    exportDataBtn.BackgroundColor3 = Color3.fromRGB(156,39,176)
    exportDataBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local exportDataCorner = Instance.new("UICorner", exportDataBtn)
    exportDataCorner.CornerRadius = UDim.new(0, 6)

    local scanGameBtn = Instance.new("TextButton", dataSection)
    scanGameBtn.Size = UDim2.new(0, 120, 0, 30)
    scanGameBtn.Position = UDim2.new(0, 140, 0, 80)
    scanGameBtn.Text = "🔍 Scan Game"
    scanGameBtn.Font = Enum.Font.GothamSemibold
    scanGameBtn.TextSize = 12
    scanGameBtn.BackgroundColor3 = Color3.fromRGB(52,152,219)
    scanGameBtn.TextColor3 = Color3.fromRGB(255,255,255)
    local scanGameCorner = Instance.new("UICorner", scanGameBtn)
    scanGameCorner.CornerRadius = UDim.new(0, 6)

    -- Update scroll frame size to accommodate new section
    advancedScroll.CanvasSize = UDim2.new(0, 0, 0, 1030)

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
    local Tabs = { Main = content, Teleport = teleportFrame, Player = playerFrame, Feature = featureFrame, Dashboard = dashboardFrame, Advanced = advancedFrame }
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
            dashboardTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            dashboardTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            contentTitle.Text = "Character Features"
        elseif name == "Dashboard" then
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
            contentTitle.Text = "Statistics Dashboard"
        end
    end

    mainTabBtn.MouseButton1Click:Connect(function() SwitchTo("Main") end)
    teleportTabBtn.MouseButton1Click:Connect(function() SwitchTo("Teleport") end)
    playerTabBtn.MouseButton1Click:Connect(function() SwitchTo("Player") end)
    featureTabBtn.MouseButton1Click:Connect(function() SwitchTo("Feature") end)
    dashboardTabBtn.MouseButton1Click:Connect(function() SwitchTo("Dashboard") end)
    advancedTabBtn.MouseButton1Click:Connect(function() SwitchTo("Advanced") end)

    -- Advanced Features
    local AdvancedFeatures = {
        autoWeather = false,
        autoEnchant = false,
        autoTrade = false,
        autoEquipStone = true, -- Default ON untuk auto equip enchant stone
        autoTeleportAltar = true -- Default ON untuk auto teleport ke altar
    }

    -- Data Export Functions
    local function ExportGameData()
        print("[DATA-EXPORT] Starting game data export...")
        Notify("Data Export", "Exporting game data...")
        
        -- Gather current script data
        local scriptData = {
            gameInfo = {
                placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
                placeId = game.PlaceId,
                exportTime = os.date("%Y-%m-%d %H:%M:%S"),
                playerName = LocalPlayer.Name
            },
            fishingStats = {
                totalFish = totalFishCaught or 0,
                rareFish = rareFishCaught or 0,
                sessionTime = tick() - (sessionStartTime or tick()),
                mode = Config.mode,
                enabled = Config.enabled,
                antiAfkEnabled = AntiAFK.enabled
            },
            configuration = {
                autoRecastDelay = Config.autoRecastDelay,
                safeModeChance = Config.safeModeChance,
                advancedFeatures = AdvancedFeatures,
                boatConfig = BoatConfig,
                smartEnchant = {
                    enabled = SmartEnchant.enabled,
                    targetEnchant = SmartEnchant.targetEnchant,
                    maxRolls = SmartEnchant.maxRolls
                }
            },
            detectedBoats = BoatConfig.detectedRemotes or {}
        }
        
        -- Export as JSON
        local HttpService = game:GetService("HttpService")
        local jsonData = HttpService:JSONEncode(scriptData)
        
        print("\n" .. "=" .. string.rep("=", 60))
        print("📁 FISH IT SCRIPT DATA EXPORT")
        print("=" .. string.rep("=", 60))
        print(jsonData)
        print("=" .. string.rep("=", 60))
        print("💾 Copy the JSON data above to save as fishit_script_data.json")
        
        -- Also create readable format
        local readable = {
            "🎮 FISH IT SCRIPT DATA EXPORT",
            "=" .. string.rep("=", 40),
            "Game: " .. scriptData.gameInfo.placeName,
            "Place ID: " .. scriptData.gameInfo.placeId,
            "Export Time: " .. scriptData.gameInfo.exportTime,
            "Player: " .. scriptData.gameInfo.playerName,
            "",
            "📊 FISHING STATISTICS:",
            "  Total Fish Caught: " .. scriptData.fishingStats.totalFish,
            "  Rare Fish Caught: " .. scriptData.fishingStats.rareFish,
            "  Session Time: " .. math.floor(scriptData.fishingStats.sessionTime / 60) .. "m " .. math.floor(scriptData.fishingStats.sessionTime % 60) .. "s",
            "  Current Mode: " .. scriptData.fishingStats.mode:upper(),
            "  Status: " .. (scriptData.fishingStats.enabled and "Running" or "Stopped"),
            "  AntiAFK: " .. (scriptData.fishingStats.antiAfkEnabled and "Enabled" or "Disabled"),
            "",
            "⚙️ CONFIGURATION:",
            "  Recast Delay: " .. scriptData.configuration.autoRecastDelay .. "s",
            "  Safe Perfect %: " .. scriptData.configuration.safeModeChance .. "%",
            "  Auto Weather: " .. (scriptData.configuration.advancedFeatures.autoWeather and "ON" or "OFF"),
            "  Auto Enchant: " .. (scriptData.configuration.advancedFeatures.autoEnchant and "ON" or "OFF"),
            "  Auto Trade: " .. (scriptData.configuration.advancedFeatures.autoTrade and "ON" or "OFF"),
            "",
            "🚤 BOAT CONFIGURATION:",
            "  Selected Boat: " .. (scriptData.configuration.boatConfig.selectedBoat or "none"),
            "  Detected Remotes: " .. #scriptData.detectedBoats,
            "",
            "🎯 SMART ENCHANT:",
            "  Target: " .. (scriptData.configuration.smartEnchant.targetEnchant or "none"),
            "  Max Rolls: " .. scriptData.configuration.smartEnchant.maxRolls,
            "  Status: " .. (scriptData.configuration.smartEnchant.enabled and "Active" or "Inactive"),
            "",
            "=" .. string.rep("=", 40)
        }
        
        local readableData = table.concat(readable, "\n")
        print("\n" .. readableData)
        
        -- Try to copy to clipboard
        pcall(function() setclipboard(jsonData) end)
        
        Notify("Data Export", "✅ Data exported! Check console for files to save.")
        return scriptData
    end

    local function ScanGameForData()
        print("[GAME-SCAN] Starting comprehensive game scan...")
        Notify("Game Scan", "Scanning game for remotes and data...")
        
        -- Auto-detect boat remotes
        local detectedRemotes = detectBoatRemotes()
        
        -- Scan for additional remotes
        local net = FindNet()
        local allRemotes = {}
        
        if net then
            for _, remote in pairs(net:GetChildren()) do
                table.insert(allRemotes, {
                    name = remote.Name,
                    class = remote.ClassName,
                    type = "unknown"
                })
            end
        end
        
        -- Quick workspace scan for boats
        local existingBoats = {}
        pcall(function()
            for _, child in pairs(workspace:GetChildren()) do
                if child:IsA("Model") then
                    local name = child.Name:lower()
                    if name:find("boat") or name:find("ship") or name:find("raft") then
                        table.insert(existingBoats, {
                            name = child.Name,
                            class = child.ClassName,
                            owner = child:GetAttribute("Owner") or "Unknown"
                        })
                    end
                end
            end
        end)
        
        -- Scan results
        print("\n📊 GAME SCAN RESULTS:")
        print("  Boat remotes detected: " .. #detectedRemotes)
        print("  Total remotes found: " .. #allRemotes)
        print("  Existing boats: " .. #existingBoats)
        
        -- Update boat config with detected remotes
        BoatConfig.detectedRemotes = detectedRemotes
        BoatConfig.lastScanTime = tick()
        
        Notify("Game Scan", "✅ Scan complete! Found " .. #detectedRemotes .. " boat remotes")
        
        return {
            boatRemotes = detectedRemotes,
            allRemotes = allRemotes,
            existingBoats = existingBoats
        }
    end

    -- Weather Event Functions
    local function PurchaseWeatherEvent()
        local weatherRemote = GetRemote("RF/PurchaseWeatherEvent")
        if weatherRemote then
            local ok, result = pcall(function()
                if weatherRemote:IsA("RemoteFunction") then
                    return weatherRemote:InvokeServer()
                else
                    weatherRemote:FireServer()
                    return "Event fired"
                end
            end)
            if ok then
                Notify("Weather", "Weather event purchased!")
            else
                Notify("Error", "Failed to purchase weather event")
            end
        else
            Notify("Error", "Weather remote not found")
        end
    end

    -- Boat Configuration and Detection
    local BoatConfig = {
        selectedBoat = "auto-detect",
        availableBoats = {
            "auto-detect",
            "Basic Boat",
            "Small Boat", 
            "Medium Boat",
            "Large Boat",
            "Speed Boat",
            "Fishing Boat",
            "Yacht",
            "Sailboat",
            "Motorboat",
            "Raft",
            "Kayak",
            "Canoe",
            "Catamaran",
            "Dinghy"
        },
        detectedRemotes = {},
        lastScanTime = 0
    }

    -- Smart boat remote detection
    local function detectBoatRemotes()
        if tick() - BoatConfig.lastScanTime < 30 then 
            return BoatConfig.detectedRemotes -- Cache for 30 seconds
        end
        
        BoatConfig.detectedRemotes = {}
        BoatConfig.lastScanTime = tick()
        
        local net = FindNet()
        if not net then 
            print("[BOAT-DETECT] Net framework not found")
            return {}
        end
        
        -- Common boat-related remote patterns
        local boatPatterns = {
            "SpawnBoat", "PurchaseBoat", "BuyBoat", "SummonBoat",
            "Boat/Spawn", "Vehicle/Spawn", "Spawn/Boat",
            "RF/SpawnBoat", "RE/SpawnBoat", "RF/Boat", "RE/Boat"
        }
        
        local despawnPatterns = {
            "DespawnBoat", "RemoveBoat", "DeleteBoat", "Boat/Despawn",
            "RF/DespawnBoat", "RE/DespawnBoat"
        }
        
        print("[BOAT-DETECT] Scanning for boat remotes...")
        
        -- Scan for spawn remotes
        for _, pattern in pairs(boatPatterns) do
            local remote = net:FindFirstChild(pattern)
            if remote then
                table.insert(BoatConfig.detectedRemotes, {
                    name = pattern,
                    type = "spawn",
                    remote = remote,
                    class = remote.ClassName
                })
                print("[BOAT-DETECT] ✅ Found spawn remote: " .. pattern)
            end
        end
        
        -- Scan for despawn remotes  
        for _, pattern in pairs(despawnPatterns) do
            local remote = net:FindFirstChild(pattern)
            if remote then
                table.insert(BoatConfig.detectedRemotes, {
                    name = pattern,
                    type = "despawn", 
                    remote = remote,
                    class = remote.ClassName
                })
                print("[BOAT-DETECT] ✅ Found despawn remote: " .. pattern)
            end
        end
        
        -- Generic scan for any boat-related remotes
        for _, child in pairs(net:GetChildren()) do
            local name = child.Name:lower()
            if (name:find("boat") or name:find("ship") or name:find("vehicle")) and 
               not BoatConfig.detectedRemotes[child.Name] then
                table.insert(BoatConfig.detectedRemotes, {
                    name = child.Name,
                    type = "generic",
                    remote = child,
                    class = child.ClassName
                })
                print("[BOAT-DETECT] 🔍 Found generic boat remote: " .. child.Name)
            end
        end
        
        print("[BOAT-DETECT] Scan complete. Found " .. #BoatConfig.detectedRemotes .. " boat remotes")
        return BoatConfig.detectedRemotes
    end

    -- Boat Management Functions
    local function SpawnBoat()
        print("[BOAT-SPAWN] Attempting to spawn boat...")
        Notify("Boat", "Attempting to spawn boat...")
        
        -- Detect available remotes first
        local detectedRemotes = detectBoatRemotes()
        local spawnRemotes = {}
        
        for _, remoteData in pairs(detectedRemotes) do
            if remoteData.type == "spawn" or remoteData.type == "generic" then
                table.insert(spawnRemotes, remoteData)
            end
        end
        
        if #spawnRemotes == 0 then
            print("[BOAT-SPAWN] No spawn remotes found, trying fallback...")
            -- Fallback to common remote names
            local fallbackNames = {"RF/SpawnBoat", "SpawnBoat", "RF/Boat", "PurchaseBoat"}
            for _, name in pairs(fallbackNames) do
                local remote = GetRemote(name)
                if remote then
                    table.insert(spawnRemotes, {name = name, remote = remote, class = remote.ClassName})
                    print("[BOAT-SPAWN] Found fallback remote: " .. name)
                    break
                end
            end
        end
        
        if #spawnRemotes == 0 then
            Notify("Error", "❌ No boat spawn remotes found")
            print("[BOAT-SPAWN] ❌ No spawn remotes available")
            return
        end
        
        -- Try each spawn remote until one works
        for i, remoteData in pairs(spawnRemotes) do
            print("[BOAT-SPAWN] Trying remote: " .. remoteData.name)
            
            local ok, result = pcall(function()
                if remoteData.remote:IsA("RemoteFunction") then
                    if BoatConfig.selectedBoat == "auto-detect" then
                        return remoteData.remote:InvokeServer()
                    else
                        return remoteData.remote:InvokeServer(BoatConfig.selectedBoat)
                    end
                else
                    if BoatConfig.selectedBoat == "auto-detect" then
                        remoteData.remote:FireServer()
                    else
                        remoteData.remote:FireServer(BoatConfig.selectedBoat)
                    end
                    return "Event fired"
                end
            end)
            
            if ok then
                Notify("Boat", "✅ Boat spawned successfully!")
                print("[BOAT-SPAWN] ✅ Success with remote: " .. remoteData.name)
                return
            else
                print("[BOAT-SPAWN] ❌ Failed with remote: " .. remoteData.name .. " - " .. tostring(result))
                if i == #spawnRemotes then
                    Notify("Error", "❌ Failed to spawn boat with all remotes")
                end
            end
        end
    end

    local function DespawnBoat()
        print("[BOAT-DESPAWN] Attempting to despawn boat...")
        Notify("Boat", "Attempting to despawn boat...")
        
        -- Detect available remotes first
        local detectedRemotes = detectBoatRemotes()
        local despawnRemotes = {}
        
        for _, remoteData in pairs(detectedRemotes) do
            if remoteData.type == "despawn" or (remoteData.type == "generic" and remoteData.name:lower():find("despawn")) then
                table.insert(despawnRemotes, remoteData)
            end
        end
        
        if #despawnRemotes == 0 then
            print("[BOAT-DESPAWN] No despawn remotes found, trying fallback...")
            -- Fallback to common remote names
            local fallbackNames = {"RF/DespawnBoat", "DespawnBoat", "RemoveBoat", "DeleteBoat"}
            for _, name in pairs(fallbackNames) do
                local remote = GetRemote(name)
                if remote then
                    table.insert(despawnRemotes, {name = name, remote = remote, class = remote.ClassName})
                    print("[BOAT-DESPAWN] Found fallback remote: " .. name)
                    break
                end
            end
        end
        
        if #despawnRemotes == 0 then
            Notify("Error", "❌ No boat despawn remotes found")
            print("[BOAT-DESPAWN] ❌ No despawn remotes available")
            return
        end
        
        -- Try each despawn remote until one works
        for i, remoteData in pairs(despawnRemotes) do
            print("[BOAT-DESPAWN] Trying remote: " .. remoteData.name)
            
            local ok, result = pcall(function()
                if remoteData.remote:IsA("RemoteFunction") then
                    return remoteData.remote:InvokeServer()
                else
                    remoteData.remote:FireServer()
                    return "Event fired"
                end
            end)
            
            if ok then
                Notify("Boat", "✅ Boat despawned successfully!")
                print("[BOAT-DESPAWN] ✅ Success with remote: " .. remoteData.name)
                return
            else
                print("[BOAT-DESPAWN] ❌ Failed with remote: " .. remoteData.name .. " - " .. tostring(result))
                if i == #despawnRemotes then
                    Notify("Error", "❌ Failed to despawn boat with all remotes")
                end
            end
        end
    end

    -- Enchanting Functions
    local function ActivateEnchantingAltar()
        local enchantRemote = GetRemote("RE/ActivateEnchantingAltar")
        if enchantRemote then
            -- Use direct FireServer instead of safeInvoke for enchanting
            local ok, result = pcall(function()
                enchantRemote:FireServer()
                return "Event fired"
            end)
            if ok then
                Notify("Enchanting", "Enchanting altar activated!")
                print("[DEBUG] Enchanting altar activated successfully")
            else
                Notify("Error", "Failed to activate enchanting altar")
                print("[DEBUG] Failed to activate enchanting altar:", result)
            end
        else
            Notify("Error", "RE/ActivateEnchantingAltar remote not found")
            print("[DEBUG] RE/ActivateEnchantingAltar remote not found")
        end
    end

    -- Auto Teleport to Enchanting Altar Function
    local function CheckDistanceToAltar()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return false, "Character not found"
        end
        
        local playerPosition = LocalPlayer.Character.HumanoidRootPart.Position
        local altarPosition = ENCHANT_ALTAR_POSITION.Position
        local distance = (playerPosition - altarPosition).Magnitude
        
        return distance <= ALTAR_DISTANCE_THRESHOLD, distance
    end
    
    local function AutoTeleportToAltar()
        if not AdvancedFeatures.autoTeleportAltar then
            print("[AUTO-TELEPORT] Auto teleport to altar disabled")
            return false
        end
        
        local isNearAltar, distance = CheckDistanceToAltar()
        
        if isNearAltar then
            print("[AUTO-TELEPORT] Already near altar (distance: " .. math.floor(distance) .. ")")
            return true
        end
        
        print("[AUTO-TELEPORT] Too far from altar (distance: " .. math.floor(distance) .. "), teleporting...")
        Notify("Auto Teleport", "Teleporting to enchanting altar...")
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = ENCHANT_ALTAR_POSITION
            task.wait(0.5) -- Wait for teleport to complete
            
            -- Verify teleport success
            local newIsNear, newDistance = CheckDistanceToAltar()
            if newIsNear then
                print("[AUTO-TELEPORT] ✅ Successfully teleported to altar")
                Notify("Auto Teleport", "✅ Arrived at enchanting altar")
                return true
            else
                print("[AUTO-TELEPORT] ❌ Teleport failed, distance still: " .. math.floor(newDistance))
                Notify("Auto Teleport", "❌ Teleport failed - please go to altar manually")
                return false
            end
        else
            print("[AUTO-TELEPORT] ❌ Character not found for teleport")
            Notify("Auto Teleport", "❌ Character not found")
            return false
        end
    end

    -- Auto Equip Enchant Stone Function
    local function AutoEquipEnchantStone()
        -- Check if auto equip is enabled
        if not AdvancedFeatures.autoEquipStone then
            print("[AUTO-EQUIP] Auto equip disabled - skipping")
            return false
        end
        
        print("[AUTO-EQUIP] Searching for enchant stone...")
        Notify("Auto Equip", "Searching for enchant stone...")
        
        -- Look for enchant stone in different possible locations
        local enchantStoneNames = {"Enchant Stone", "EnchantStone", "Enchanting Stone", "Stone"}
        local foundStone = nil
        
        -- Check player's inventory/backpack
        local player = LocalPlayer
        if player and player.Character then
            -- Try different methods to find enchant stone
            
            -- Method 1: Look in PlayerGui for inventory
            if player.PlayerGui then
                local function scanForEnchantStone(parent)
                    for _, child in pairs(parent:GetChildren()) do
                        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") then
                            for _, stoneName in pairs(enchantStoneNames) do
                                if child.Name:find(stoneName) or (child.Text and child.Text:find(stoneName)) then
                                    print("[AUTO-EQUIP] Found potential enchant stone: " .. child.Name)
                                    return child
                                end
                            end
                        end
                        local found = scanForEnchantStone(child)
                        if found then return found end
                    end
                    return nil
                end
                
                foundStone = scanForEnchantStone(player.PlayerGui)
            end
            
            -- Method 2: Try direct remote calls for equipping
            local equipRemotes = {"RE/EquipItem", "RF/EquipItem", "RE/Equip", "RF/Equip"}
            for _, remoteName in pairs(equipRemotes) do
                local equipRemote = GetRemote(remoteName)
                if equipRemote then
                    for _, stoneName in pairs(enchantStoneNames) do
                        local success = pcall(function()
                            if equipRemote:IsA("RemoteFunction") then
                                equipRemote:InvokeServer(stoneName)
                            else
                                equipRemote:FireServer(stoneName)
                            end
                        end)
                        if success then
                            print("[AUTO-EQUIP] ✅ Successfully equipped: " .. stoneName)
                            Notify("Auto Equip", "✅ Equipped: " .. stoneName)
                            return true
                        end
                    end
                end
            end
            
            -- Method 3: Try item IDs or common enchant stone IDs
            local stoneIds = {1, "enchant_stone", "EnchantStone", "stone"}
            local equipRemote = GetRemote("RE/EquipItem") or GetRemote("RF/EquipItem")
            if equipRemote then
                for _, stoneId in pairs(stoneIds) do
                    local success = pcall(function()
                        if equipRemote:IsA("RemoteFunction") then
                            equipRemote:InvokeServer(stoneId)
                        else
                            equipRemote:FireServer(stoneId)
                        end
                    end)
                    if success then
                        print("[AUTO-EQUIP] ✅ Successfully equipped stone ID: " .. tostring(stoneId))
                        Notify("Auto Equip", "✅ Equipped enchant stone")
                        return true
                    end
                end
            end
        end
        
        print("[AUTO-EQUIP] ❌ Could not find or equip enchant stone")
        Notify("Auto Equip", "❌ Enchant stone not found - please equip manually")
        return false
    end

    local function RollEnchant()
        -- Check for roll enchant remote after altar activation
        local rollRemote = GetRemote("RE/RollEnchant") or GetRemote("RF/RollEnchant") or GetRemote("RE/EnchantRoll")
        if rollRemote then
            -- Use direct call instead of safeInvoke
            local ok, result = pcall(function()
                if rollRemote:IsA("RemoteFunction") then
                    return rollRemote:InvokeServer()
                else
                    rollRemote:FireServer()
                    return "Event fired"
                end
            end)
            if ok then
                Notify("Enchanting", "Enchantment rolled!")
                print("[DEBUG] Enchantment rolled successfully")
            else
                Notify("Error", "Failed to roll enchantment")
                print("[DEBUG] Failed to roll enchantment:", result)
            end
        else
            Notify("Error", "Roll enchant remote not found")
            print("[DEBUG] Roll enchant remotes not found")
            print("[DEBUG] Make sure you have:")
            print("1. Enchant stone in inventory")
            print("2. Enchant stone equipped")
            print("3. At enchanting altar/table")
        end
    end

    -- Enhanced Auto-Enchanting with Smart Target support
    local function AutoEnchantSequence()
        if not AdvancedFeatures.autoEnchant or not Config.enabled then
            return
        end
        
        print("[AUTO-ENCHANT] Starting enchanting sequence...")
        Notify("Auto Enchant", "Starting enchant sequence...")
        
        -- Step 0: Auto teleport to altar if needed
        print("[AUTO-ENCHANT] Step 0: Checking altar proximity...")
        local atAltar = AutoTeleportToAltar()
        if not atAltar then
            print("[AUTO-ENCHANT] ❌ Could not reach altar, aborting sequence")
            Notify("Auto Enchant", "❌ Could not reach altar")
            return false
        end
        
        -- Step 1: Try to auto-equip enchant stone
        print("[AUTO-ENCHANT] Step 1: Auto-equipping enchant stone...")
        local stoneEquipped = AutoEquipEnchantStone()
        
        -- Step 2: Activate altar
        print("[AUTO-ENCHANT] Step 2: Activating enchanting altar...")
        ActivateEnchantingAltar()
        
        -- Step 3: Wait a bit then roll
        print("[AUTO-ENCHANT] Step 3: Waiting 2 seconds...")
        task.wait(2)
        
        print("[AUTO-ENCHANT] Step 4: Rolling enchantment...")
        RollEnchant()
        
        -- Step 5: If Smart Target is enabled, check the result
        if SmartEnchant.enabled and SmartEnchant.targetEnchant then
            task.wait(1) -- Wait for UI to update
            local currentEnchant = DetectCurrentEnchant()
            SmartEnchant.rollCount = SmartEnchant.rollCount + 1
            
            print("[SMART-TARGET] Roll #" .. SmartEnchant.rollCount .. " - Got: " .. (currentEnchant or "Unknown"))
            
            if currentEnchant == SmartEnchant.targetEnchant then
                SmartEnchant.targetFound = true
                SmartEnchant.enabled = false -- Stop targeting
                Notify("🎯 Smart Target", "TARGET FOUND! Got " .. currentEnchant .. " after " .. SmartEnchant.rollCount .. " rolls!")
                print("[SMART-TARGET] ✅ TARGET FOUND: " .. currentEnchant)
                return true -- Stop enchanting
            elseif SmartEnchant.rollCount >= SmartEnchant.maxRolls then
                SmartEnchant.enabled = false -- Stop after max rolls
                Notify("🎯 Smart Target", "Max rolls reached (" .. SmartEnchant.maxRolls .. "). Stopping.")
                print("[SMART-TARGET] ❌ Max rolls reached. Target not found.")
                return false
            else
                Notify("🎯 Smart Target", "Roll " .. SmartEnchant.rollCount .. "/" .. SmartEnchant.maxRolls .. " - Got: " .. (currentEnchant or "Unknown"))
            end
        end
        
        print("[AUTO-ENCHANT] Enchanting sequence completed")
        local statusMsg = "Enchant sequence completed!"
        if atAltar then 
            statusMsg = statusMsg .. " (Auto-teleported)"
        end
        if stoneEquipped then 
            statusMsg = statusMsg .. " (Auto-equipped)"
        end
        Notify("Auto Enchant", statusMsg)
    end

    -- Smart Target Enchanting - keeps rolling until target is found
    local function SmartTargetEnchantSequence()
        if not SmartEnchant.enabled or not SmartEnchant.targetEnchant then
            Notify("🎯 Smart Target", "No target selected or targeting disabled")
            return
        end
        
        -- Initial teleport to altar
        print("[SMART-TARGET] Ensuring we're at the altar...")
        local atAltar = AutoTeleportToAltar()
        if not atAltar then
            Notify("🎯 Smart Target", "❌ Could not reach altar - aborting")
            SmartEnchant.enabled = false
            return
        end
        
        SmartEnchant.rollCount = 0
        SmartEnchant.targetFound = false
        
        Notify("🎯 Smart Target", "Targeting: " .. SmartEnchant.targetEnchant .. " (Max: " .. SmartEnchant.maxRolls .. " rolls)")
        
        while SmartEnchant.enabled and not SmartEnchant.targetFound and SmartEnchant.rollCount < SmartEnchant.maxRolls do
            -- Check if we're still near altar (in case player moved)
            local stillNearAltar = CheckDistanceToAltar()
            if not stillNearAltar then
                print("[SMART-TARGET] Moved away from altar, re-teleporting...")
                AutoTeleportToAltar()
            end
            
            -- Auto-equip enchant stone
            print("[SMART-TARGET] Roll #" .. (SmartEnchant.rollCount + 1) .. " - Auto-equipping enchant stone...")
            local stoneEquipped = AutoEquipEnchantStone()
            
            if not stoneEquipped then
                print("[SMART-TARGET] ⚠️ Stone not auto-equipped, trying anyway...")
            end
            
            -- Activate altar and roll
            ActivateEnchantingAltar()
            task.wait(2)
            RollEnchant()
            task.wait(1) -- Wait for result
            
            -- Check result
            local currentEnchant = DetectCurrentEnchant()
            SmartEnchant.rollCount = SmartEnchant.rollCount + 1
            
            print("[SMART-TARGET] Roll #" .. SmartEnchant.rollCount .. " - Got: " .. (currentEnchant or "Unknown"))
            
            if currentEnchant == SmartEnchant.targetEnchant then
                SmartEnchant.targetFound = true
                Notify("🎯 Smart Target", "✅ TARGET FOUND! Got " .. currentEnchant .. " after " .. SmartEnchant.rollCount .. " rolls!")
                break
            else
                Notify("🎯 Smart Target", "Roll " .. SmartEnchant.rollCount .. "/" .. SmartEnchant.maxRolls .. " - Got: " .. (currentEnchant or "Unknown"))
                
                if SmartEnchant.rollCount < SmartEnchant.maxRolls then
                    -- Brief pause before next roll
                    print("[SMART-TARGET] Preparing for next roll...")
                    task.wait(2) -- Give time for UI updates
                end
            end
        end
        
        if not SmartEnchant.targetFound then
            Notify("🎯 Smart Target", "❌ Target not found after " .. SmartEnchant.rollCount .. " rolls")
        end
        
        SmartEnchant.enabled = false -- Stop targeting after completion
    end

    -- Manual enchanting function for Roll Enchant button
    local function ManualRollEnchant()
        print("[MANUAL-ENCHANT] Manual enchant requested...")
        Notify("Manual Enchant", "Starting manual enchant...")
        
        -- Check if near altar and auto-teleport if needed
        print("[MANUAL-ENCHANT] Checking altar proximity...")
        local atAltar = AutoTeleportToAltar()
        if not atAltar then
            Notify("Manual Enchant", "❌ Could not reach altar")
            return
        end
        
        -- Try to auto-equip enchant stone first
        print("[MANUAL-ENCHANT] Auto-equipping enchant stone...")
        local stoneEquipped = AutoEquipEnchantStone()
        
        -- Do the activation and roll
        ActivateEnchantingAltar()
        task.wait(2)
        RollEnchant()
        
        local statusMsg = "✅ Completed!"
        if atAltar then 
            statusMsg = statusMsg .. " (Auto-teleported)"
        end
        if stoneEquipped then 
            statusMsg = statusMsg .. " (Auto-equipped)"
        end
        Notify("Manual Enchant", statusMsg)
    end

    -- Trading Functions
    local function InitiateTrade()
        local tradeRemote = GetRemote("RF/InitiateTrade")
        if tradeRemote then
            local ok, result = pcall(function()
                if tradeRemote:IsA("RemoteFunction") then
                    return tradeRemote:InvokeServer()
                else
                    tradeRemote:FireServer()
                    return "Event fired"
                end
            end)
            if ok then
                Notify("Trading", "Trade initiated!")
            else
                Notify("Error", "Failed to initiate trade")
            end
        else
            Notify("Error", "Trade remote not found")
        end
    end

    -- Event Handlers for Advanced Features
    weatherToggle.MouseButton1Click:Connect(function()
        AdvancedFeatures.autoWeather = not AdvancedFeatures.autoWeather
        weatherToggle.Text = AdvancedFeatures.autoWeather and "Auto Weather: ON" or "Auto Weather: OFF"
        weatherToggle.BackgroundColor3 = AdvancedFeatures.autoWeather and Color3.fromRGB(40,167,69) or Color3.fromRGB(220,53,69)
    end)

    weatherBuyBtn.MouseButton1Click:Connect(PurchaseWeatherEvent)
    
    -- Boat selector dropdown event handler
    boatSelector.MouseButton1Click:Connect(function()
        -- Create boat selection window if it doesn't exist
        local boatListWindow = screenGui:FindFirstChild("BoatListWindow")
        
        if not boatListWindow then
            -- Create main window
            boatListWindow = Instance.new("Frame", screenGui)
            boatListWindow.Name = "BoatListWindow"
            boatListWindow.Size = UDim2.new(0, 280, 0, 320)
            boatListWindow.Position = UDim2.new(0.5, -140, 0.5, -160)
            boatListWindow.BackgroundColor3 = Color3.fromRGB(30,30,36)
            boatListWindow.BorderSizePixel = 1
            boatListWindow.BorderColor3 = Color3.fromRGB(100,100,100)
            boatListWindow.ZIndex = 200
            boatListWindow.Visible = false
            local windowCorner = Instance.new("UICorner", boatListWindow)
            windowCorner.CornerRadius = UDim.new(0, 8)
            
            -- Window header
            local header = Instance.new("Frame", boatListWindow)
            header.Size = UDim2.new(1, 0, 0, 35)
            header.BackgroundColor3 = Color3.fromRGB(40,40,46)
            header.BorderSizePixel = 0
            header.ZIndex = 201
            local headerCorner = Instance.new("UICorner", header)
            headerCorner.CornerRadius = UDim.new(0, 8)
            
            local headerTitle = Instance.new("TextLabel", header)
            headerTitle.Size = UDim2.new(1, -40, 1, 0)
            headerTitle.Position = UDim2.new(0, 10, 0, 0)
            headerTitle.Text = "🚤 Select Boat Type"
            headerTitle.Font = Enum.Font.GothamBold
            headerTitle.TextSize = 14
            headerTitle.TextColor3 = Color3.fromRGB(52,152,219)
            headerTitle.BackgroundTransparency = 1
            headerTitle.TextXAlignment = Enum.TextXAlignment.Left
            headerTitle.TextYAlignment = Enum.TextYAlignment.Center
            headerTitle.ZIndex = 201
            
            -- Close button
            local closeBtn = Instance.new("TextButton", header)
            closeBtn.Size = UDim2.new(0, 25, 0, 25)
            closeBtn.Position = UDim2.new(1, -30, 0, 5)
            closeBtn.Text = "✕"
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.TextSize = 14
            closeBtn.BackgroundColor3 = Color3.fromRGB(220,53,69)
            closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
            closeBtn.ZIndex = 202
            local closeBtnCorner = Instance.new("UICorner", closeBtn)
            closeBtnCorner.CornerRadius = UDim.new(0, 4)
            
            -- Scrolling frame for boats
            local scrollFrame = Instance.new("ScrollingFrame", boatListWindow)
            scrollFrame.Size = UDim2.new(1, -20, 1, -50)
            scrollFrame.Position = UDim2.new(0, 10, 0, 40)
            scrollFrame.BackgroundTransparency = 1
            scrollFrame.ScrollBarThickness = 8
            scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(120,120,120)
            scrollFrame.ZIndex = 201
            
            local yPos = 0
            for i, boatName in pairs(BoatConfig.availableBoats) do
                local boatFrame = Instance.new("Frame", scrollFrame)
                boatFrame.Size = UDim2.new(1, -10, 0, 35)
                boatFrame.Position = UDim2.new(0, 5, 0, yPos)
                boatFrame.BackgroundColor3 = boatName == BoatConfig.selectedBoat and Color3.fromRGB(52,152,219) or Color3.fromRGB(40,40,46)
                boatFrame.ZIndex = 201
                local frameCorner = Instance.new("UICorner", boatFrame)
                frameCorner.CornerRadius = UDim.new(0, 6)
                
                -- Boat name with icon
                local nameLabel = Instance.new("TextLabel", boatFrame)
                nameLabel.Size = UDim2.new(1, -70, 1, 0)
                nameLabel.Position = UDim2.new(0, 10, 0, 0)
                nameLabel.Text = (boatName == "auto-detect" and "🔍 " or "🚤 ") .. boatName
                nameLabel.Font = Enum.Font.GothamSemibold
                nameLabel.TextSize = 11
                nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextYAlignment = Enum.TextYAlignment.Center
                nameLabel.ZIndex = 202
                
                -- Select button
                local selectBtn = Instance.new("TextButton", boatFrame)
                selectBtn.Size = UDim2.new(0, 50, 0, 25)
                selectBtn.Position = UDim2.new(1, -60, 0, 5)
                selectBtn.Text = boatName == BoatConfig.selectedBoat and "✓" or "SELECT"
                selectBtn.Font = Enum.Font.GothamSemibold
                selectBtn.TextSize = 9
                selectBtn.BackgroundColor3 = boatName == BoatConfig.selectedBoat and Color3.fromRGB(40,167,69) or Color3.fromRGB(60,60,66)
                selectBtn.TextColor3 = Color3.fromRGB(255,255,255)
                selectBtn.ZIndex = 202
                local selectBtnCorner = Instance.new("UICorner", selectBtn)
                selectBtnCorner.CornerRadius = UDim.new(0, 4)
                
                selectBtn.MouseButton1Click:Connect(function()
                    BoatConfig.selectedBoat = boatName
                    boatSelector.Text = boatName == "auto-detect" and "Auto-Detect Boat ▼" or boatName .. " ▼"
                    boatListWindow.Visible = false
                    Notify("Boat", "Selected: " .. boatName)
                    print("[BOAT-SELECTOR] Selected boat: " .. boatName)
                end)
                
                yPos = yPos + 40
            end
            
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
            
            -- Event handlers
            closeBtn.MouseButton1Click:Connect(function()
                boatListWindow.Visible = false
            end)
        end
        
        -- Toggle window visibility
        boatListWindow.Visible = not boatListWindow.Visible
    end)
    
    spawnBoatBtn.MouseButton1Click:Connect(SpawnBoat)
    despawnBoatBtn.MouseButton1Click:Connect(DespawnBoat)

    -- Data Export Event Handlers
    exportDataBtn.MouseButton1Click:Connect(function()
        ExportGameData()
    end)
    
    scanGameBtn.MouseButton1Click:Connect(function()
        ScanGameForData()
    end)

    enchantToggle.MouseButton1Click:Connect(function()
        AdvancedFeatures.autoEnchant = not AdvancedFeatures.autoEnchant
        enchantToggle.Text = AdvancedFeatures.autoEnchant and "Auto Enchant: ON" or "Auto Enchant: OFF"
        enchantToggle.BackgroundColor3 = AdvancedFeatures.autoEnchant and Color3.fromRGB(40,167,69) or Color3.fromRGB(220,53,69)
        
        -- Notify user about the change
        if AdvancedFeatures.autoEnchant then
            Notify("Auto Enchant", "Enabled! Will auto-enchant every 60 seconds")
            print("[AUTO-ENCHANT] Auto enchanting enabled")
            print("[AUTO-ENCHANT] Requirements: Enchant stone equipped + At altar")
        else
            Notify("Auto Enchant", "Disabled")
            print("[AUTO-ENCHANT] Auto enchanting disabled")
        end
    end)

    rollEnchantBtn.MouseButton1Click:Connect(ManualRollEnchant)

    autoEquipToggle.MouseButton1Click:Connect(function()
        AdvancedFeatures.autoEquipStone = not AdvancedFeatures.autoEquipStone
        autoEquipToggle.Text = AdvancedFeatures.autoEquipStone and "Auto Equip: ON" or "Auto Equip: OFF"
        autoEquipToggle.BackgroundColor3 = AdvancedFeatures.autoEquipStone and Color3.fromRGB(40,167,69) or Color3.fromRGB(220,53,69)
        
        if AdvancedFeatures.autoEquipStone then
            Notify("Auto Equip", "✅ Auto equip enchant stone enabled")
            print("[AUTO-EQUIP] Auto equip enchant stone enabled")
        else
            Notify("Auto Equip", "❌ Auto equip enchant stone disabled")
            print("[AUTO-EQUIP] Auto equip enchant stone disabled")
        end
    end)

    autoTeleportToggle.MouseButton1Click:Connect(function()
        AdvancedFeatures.autoTeleportAltar = not AdvancedFeatures.autoTeleportAltar
        autoTeleportToggle.Text = AdvancedFeatures.autoTeleportAltar and "Auto Teleport: ON" or "Auto Teleport: OFF"
        autoTeleportToggle.BackgroundColor3 = AdvancedFeatures.autoTeleportAltar and Color3.fromRGB(40,167,69) or Color3.fromRGB(220,53,69)
        
        if AdvancedFeatures.autoTeleportAltar then
            Notify("Auto Teleport", "✅ Auto teleport to altar enabled")
            print("[AUTO-TELEPORT] Auto teleport to altar enabled")
        else
            Notify("Auto Teleport", "❌ Auto teleport to altar disabled")
            print("[AUTO-TELEPORT] Auto teleport to altar disabled")
        end
    end)

    manualTeleportBtn.MouseButton1Click:Connect(function()
        print("[MANUAL-TELEPORT] Manual teleport to altar requested...")
        local isNear, distance = CheckDistanceToAltar()
        
        if isNear then
            Notify("Teleport", "✅ Already at altar (distance: " .. math.floor(distance) .. ")")
        else
            Notify("Teleport", "Teleporting to enchanting altar...")
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = ENCHANT_ALTAR_POSITION
                Notify("Teleport", "✅ Teleported to enchanting altar")
            else
                Notify("Teleport", "❌ Character not found")
            end
        end
    end)

    -- Smart Target Enchant Event Handlers
    local enchantListWindow = nil -- Reference to enchant list window
    
    targetEnchantSelector.MouseButton1Click:Connect(function()
        -- Create enchant list window if it doesn't exist
        if not enchantListWindow then
            -- Create main window
            enchantListWindow = Instance.new("Frame", screenGui)
            enchantListWindow.Size = UDim2.new(0, 350, 0, 400)
            enchantListWindow.Position = UDim2.new(0.5, -175, 0.5, -200)
            enchantListWindow.BackgroundColor3 = Color3.fromRGB(30,30,36)
            enchantListWindow.BorderSizePixel = 1
            enchantListWindow.BorderColor3 = Color3.fromRGB(100,100,100)
            enchantListWindow.ZIndex = 200
            enchantListWindow.Visible = false
            local windowCorner = Instance.new("UICorner", enchantListWindow)
            windowCorner.CornerRadius = UDim.new(0, 8)
            
            -- Window header
            local header = Instance.new("Frame", enchantListWindow)
            header.Size = UDim2.new(1, 0, 0, 35)
            header.BackgroundColor3 = Color3.fromRGB(40,40,46)
            header.BorderSizePixel = 0
            header.ZIndex = 201
            local headerCorner = Instance.new("UICorner", header)
            headerCorner.CornerRadius = UDim.new(0, 8)
            
            local headerTitle = Instance.new("TextLabel", header)
            headerTitle.Size = UDim2.new(1, -40, 1, 0)
            headerTitle.Position = UDim2.new(0, 10, 0, 0)
            headerTitle.Text = "🎯 Select Target Enchantment"
            headerTitle.Font = Enum.Font.GothamBold
            headerTitle.TextSize = 14
            headerTitle.TextColor3 = Color3.fromRGB(255,215,0)
            headerTitle.BackgroundTransparency = 1
            headerTitle.TextXAlignment = Enum.TextXAlignment.Left
            headerTitle.TextYAlignment = Enum.TextYAlignment.Center
            headerTitle.ZIndex = 201
            
            -- Close button
            local closeBtn = Instance.new("TextButton", header)
            closeBtn.Size = UDim2.new(0, 25, 0, 25)
            closeBtn.Position = UDim2.new(1, -30, 0, 5)
            closeBtn.Text = "✕"
            closeBtn.Font = Enum.Font.GothamBold
            closeBtn.TextSize = 14
            closeBtn.BackgroundColor3 = Color3.fromRGB(220,53,69)
            closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
            closeBtn.ZIndex = 202
            local closeBtnCorner = Instance.new("UICorner", closeBtn)
            closeBtnCorner.CornerRadius = UDim.new(0, 4)
            
            -- Scrolling frame for enchants
            local scrollFrame = Instance.new("ScrollingFrame", enchantListWindow)
            scrollFrame.Size = UDim2.new(1, -20, 1, -50)
            scrollFrame.Position = UDim2.new(0, 10, 0, 40)
            scrollFrame.BackgroundTransparency = 1
            scrollFrame.ScrollBarThickness = 8
            scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(120,120,120)
            scrollFrame.ZIndex = 201
            
            local yPos = 0
            for enchantName, data in pairs(SmartEnchant.enchantDatabase) do
                local enchantFrame = Instance.new("Frame", scrollFrame)
                enchantFrame.Size = UDim2.new(1, -10, 0, 45)
                enchantFrame.Position = UDim2.new(0, 5, 0, yPos)
                enchantFrame.BackgroundColor3 = Color3.fromRGB(40,40,46)
                enchantFrame.ZIndex = 201
                local frameCorner = Instance.new("UICorner", enchantFrame)
                frameCorner.CornerRadius = UDim.new(0, 6)
                
                -- Enchant name
                local nameLabel = Instance.new("TextLabel", enchantFrame)
                nameLabel.Size = UDim2.new(1, -80, 0, 20)
                nameLabel.Position = UDim2.new(0, 10, 0, 5)
                nameLabel.Text = enchantName
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextSize = 12
                nameLabel.TextColor3 = data.rarity == "cursed" and Color3.fromRGB(255,100,100) or 
                                     data.rarity == "rare" and Color3.fromRGB(100,200,255) or 
                                     data.rarity == "uncommon" and Color3.fromRGB(150,255,150) or
                                     Color3.fromRGB(200,200,200)
                nameLabel.BackgroundTransparency = 1
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.ZIndex = 202
                
                -- Description
                local descLabel = Instance.new("TextLabel", enchantFrame)
                descLabel.Size = UDim2.new(1, -80, 0, 15)
                descLabel.Position = UDim2.new(0, 10, 0, 25)
                descLabel.Text = data.description
                descLabel.Font = Enum.Font.Gotham
                descLabel.TextSize = 9
                descLabel.TextColor3 = Color3.fromRGB(150,150,150)
                descLabel.BackgroundTransparency = 1
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.ZIndex = 202
                
                -- Select button
                local selectBtn = Instance.new("TextButton", enchantFrame)
                selectBtn.Size = UDim2.new(0, 60, 0, 30)
                selectBtn.Position = UDim2.new(1, -70, 0, 7)
                selectBtn.Text = "SELECT"
                selectBtn.Font = Enum.Font.GothamSemibold
                selectBtn.TextSize = 10
                selectBtn.BackgroundColor3 = Color3.fromRGB(40,167,69)
                selectBtn.TextColor3 = Color3.fromRGB(255,255,255)
                selectBtn.ZIndex = 202
                local selectBtnCorner = Instance.new("UICorner", selectBtn)
                selectBtnCorner.CornerRadius = UDim.new(0, 4)
                
                selectBtn.MouseButton1Click:Connect(function()
                    SmartEnchant.targetEnchant = enchantName
                    targetEnchantSelector.Text = "Selected: " .. enchantName:sub(1,12) .. "..."
                    targetStatusLabel.Text = "Target: " .. enchantName .. " (" .. data.rarity .. ")"
                    enchantListWindow.Visible = false
                    Notify("🎯 Smart Target", "Target set to: " .. enchantName)
                    print("[SMART-TARGET] Target selected: " .. enchantName)
                end)
                
                yPos = yPos + 50
            end
            
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yPos)
            
            -- Event handlers
            closeBtn.MouseButton1Click:Connect(function()
                enchantListWindow.Visible = false
            end)
            
            -- Make window draggable
            local dragging = false
            local dragStart = nil
            local startPos = nil
            
            header.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragStart = input.Position
                    startPos = enchantListWindow.Position
                end
            end)
            
            header.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                    local delta = input.Position - dragStart
                    enchantListWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            
            header.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
        end
        
        -- Toggle window visibility
        enchantListWindow.Visible = not enchantListWindow.Visible
        if enchantListWindow.Visible then
            local enchantCount = 0
            for _ in pairs(SmartEnchant.enchantDatabase) do
                enchantCount = enchantCount + 1
            end
            print("[SMART-TARGET] Enchant list opened with " .. enchantCount .. " enchants")
            Notify("🎯 Smart Target", "Enchant list opened - " .. enchantCount .. " available")
        end
    end)
    
    smartTargetToggle.MouseButton1Click:Connect(function()
        if not SmartEnchant.targetEnchant then
            Notify("🎯 Smart Target", "Please select a target enchant first!")
            return
        end
        
        SmartEnchant.enabled = not SmartEnchant.enabled
        smartTargetToggle.Text = SmartEnchant.enabled and "Target: ON" or "Target: OFF"
        smartTargetToggle.BackgroundColor3 = SmartEnchant.enabled and Color3.fromRGB(40,167,69) or Color3.fromRGB(160,60,60)
        
        if SmartEnchant.enabled then
            targetStatusLabel.Text = "Status: Targeting " .. SmartEnchant.targetEnchant .. "..."
            Notify("🎯 Smart Target", "Smart targeting enabled for: " .. SmartEnchant.targetEnchant)
            
            -- Start smart targeting in background
            spawn(function()
                SmartTargetEnchantSequence()
                -- Update UI when finished
                smartTargetToggle.Text = "Target: OFF"
                smartTargetToggle.BackgroundColor3 = Color3.fromRGB(160,60,60)
                if SmartEnchant.targetFound then
                    targetStatusLabel.Text = "Status: ✅ Target found! (" .. SmartEnchant.rollCount .. " rolls)"
                else
                    targetStatusLabel.Text = "Status: ❌ Target not found (" .. SmartEnchant.rollCount .. " rolls)"
                end
            end)
        else
            targetStatusLabel.Text = "Status: Targeting disabled"
            Notify("🎯 Smart Target", "Smart targeting disabled")
        end
    end)

    tradeToggle.MouseButton1Click:Connect(function()
        AdvancedFeatures.autoTrade = not AdvancedFeatures.autoTrade
        tradeToggle.Text = AdvancedFeatures.autoTrade and "Auto Trade: ON" or "Auto Trade: OFF"
        tradeToggle.BackgroundColor3 = AdvancedFeatures.autoTrade and Color3.fromRGB(40,167,69) or Color3.fromRGB(220,53,69)
    end)

    initiateTradeBtn.MouseButton1Click:Connect(InitiateTrade)

    -- Auto Weather Event Loop
    spawn(function()
        while true do
            task.wait(30) -- Check every 30 seconds
            if AdvancedFeatures.autoWeather and Config.enabled then
                pcall(PurchaseWeatherEvent)
            end
        end
    end)

    -- Auto Enchanting Loop
    spawn(function()
        while true do
            task.wait(60) -- Check every minute
            if AdvancedFeatures.autoEnchant and Config.enabled then
                pcall(AutoEnchantSequence)
            end
        end
    end)

    -- Auto Trading Loop
    spawn(function()
        while true do
            task.wait(120) -- Check every 2 minutes
            if AdvancedFeatures.autoTrade and Config.enabled then
                pcall(InitiateTrade)
            end
        end
    end)

    -- Start with Main visible
    SwitchTo("Main")

    -- callbacks
    fastButton.MouseButton1Click:Connect(function() Config.mode = "fast"; Notify("modern_autofish", "Mode set to FAST") end)
    secureButton.MouseButton1Click:Connect(function() Config.mode = "secure"; Notify("modern_autofish", "Mode set to SECURE") end)

    -- AntiAFK toggle
    antiAfkToggle.MouseButton1Click:Connect(function()
        AntiAFK.enabled = not AntiAFK.enabled
        Config.antiAfkEnabled = AntiAFK.enabled
        
        if AntiAFK.enabled then
            antiAfkToggle.Text = "ON"
            antiAfkToggle.BackgroundColor3 = Color3.fromRGB(70,170,90)
            antiAfkLabel.Text = "AntiAFK: Enabled"
            antiAfkLabel.TextColor3 = Color3.fromRGB(100,255,150)
            
            AntiAFK.sessionId = AntiAFK.sessionId + 1
            task.spawn(function() AntiAfkRunner(AntiAFK.sessionId) end)
        else
            antiAfkToggle.Text = "OFF"
            antiAfkToggle.BackgroundColor3 = Color3.fromRGB(160,60,60)
            antiAfkLabel.Text = "AntiAFK: Disabled"
            antiAfkLabel.TextColor3 = Color3.fromRGB(200,200,200)
            
            AntiAFK.sessionId = AntiAFK.sessionId + 1
        end
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
        delayLabel.Text = string.format("Recast Delay: %.2fs", Config.autoRecastDelay)
    end)
    delayPlus.MouseButton1Click:Connect(function()
        Config.autoRecastDelay = Config.autoRecastDelay + 0.1
        delayLabel.Text = string.format("Recast Delay: %.2fs", Config.autoRecastDelay)
    end)

    chanceMinus.MouseButton1Click:Connect(function()
        Config.safeModeChance = math.max(0, Config.safeModeChance - 5)
        chanceLabel.Text = string.format("Safe Perfect %%: %d", Config.safeModeChance)
    end)
    chancePlus.MouseButton1Click:Connect(function()
        Config.safeModeChance = math.min(100, Config.safeModeChance + 5)
        chanceLabel.Text = string.format("Safe Perfect %%: %d", Config.safeModeChance)
    end)

    Notify("modern_autofish", "UI ready - Select mode and press Start")
end

-- Build UI and ready
BuildUI()

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
    Config = Config,
    AntiAFK = AntiAFK
}

print("modern_autofish loaded - UI created and API available via _G.ModernAutoFish")
