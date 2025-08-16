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
    local Tabs = { Main = content, Teleport = teleportFrame, Player = playerFrame, Feature = featureFrame }
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
            contentTitle.Text = "Player Teleport"
            updatePlayerList(searchBox.Text) -- Refresh when switching to player tab
        else -- Feature
            featureTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            featureTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            mainTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            teleportTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            teleportTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            playerTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            playerTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            contentTitle.Text = "Character Features"
        end
    end

    mainTabBtn.MouseButton1Click:Connect(function() SwitchTo("Main") end)
    teleportTabBtn.MouseButton1Click:Connect(function() SwitchTo("Teleport") end)
    playerTabBtn.MouseButton1Click:Connect(function() SwitchTo("Player") end)
    featureTabBtn.MouseButton1Click:Connect(function() SwitchTo("Feature") end)

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
