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
    enabled = false
}

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
    panel.Size = UDim2.new(0, 380, 0, 200)
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
    minimizeBtn.Text = "_" minimizeBtn.Font = Enum.Font.GothamBold minimizeBtn.TextSize = 18
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60,60,66); minimizeBtn.TextColor3 = Color3.fromRGB(230,230,230)
    Instance.new("UICorner", minimizeBtn)

    -- Close: anchored to right of container with right padding
    local closeBtn = Instance.new("TextButton", btnContainer)
    closeBtn.Size = UDim2.new(0, 36, 0, 28)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, -8, 0.5, -14)
    closeBtn.Text = "X" closeBtn.Font = Enum.Font.GothamBold closeBtn.TextSize = 16
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

    -- Tab bar (Main / Settings)
    local tabBar = Instance.new("Frame", panel)
    tabBar.Size = UDim2.new(1, -20, 0, 32)
    tabBar.Position = UDim2.new(0, 10, 0, 44)
    tabBar.BackgroundTransparency = 1

    local mainTabBtn = Instance.new("TextButton", tabBar)
    mainTabBtn.Size = UDim2.new(0, 100, 1, 0)
    mainTabBtn.Position = UDim2.new(0, 0, 0, 0)
    mainTabBtn.Text = "Main"
    mainTabBtn.Font = Enum.Font.GothamSemibold
    mainTabBtn.TextSize = 14
    mainTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
    mainTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
    Instance.new("UICorner", mainTabBtn)

    local settingsTabBtn = Instance.new("TextButton", tabBar)
    settingsTabBtn.Size = UDim2.new(0, 120, 1, 0)
    settingsTabBtn.Position = UDim2.new(0, 106, 0, 0)
    settingsTabBtn.Text = "Settings"
    settingsTabBtn.Font = Enum.Font.GothamSemibold
    settingsTabBtn.TextSize = 14
    settingsTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
    settingsTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
    Instance.new("UICorner", settingsTabBtn)

    -- Settings frame (hidden by default)
    local settingsFrame = Instance.new("Frame", panel)
    settingsFrame.Size = UDim2.new(1, -20, 1, -96)
    settingsFrame.Position = UDim2.new(0, 10, 0, 80)
    settingsFrame.BackgroundTransparency = 1
    settingsFrame.Visible = false

    -- Sell All button in Settings
    local sellBtn = Instance.new("TextButton", settingsFrame)
    sellBtn.Size = UDim2.new(0.6, 0, 0, 40)
    sellBtn.Position = UDim2.new(0.5, -0.3 * settingsFrame.AbsoluteSize.X/2, 0, 10)
    sellBtn.AnchorPoint = Vector2.new(0.5, 0)
    sellBtn.Text = "Sell All Items"
    sellBtn.Font = Enum.Font.GothamBold
    sellBtn.TextSize = 16
    sellBtn.BackgroundColor3 = Color3.fromRGB(70,130,170)
    sellBtn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", sellBtn)

    -- Switch tab function
    local function SwitchTab(name)
        if name == "Main" then
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            mainTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            settingsTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            settingsTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            if content then content.Visible = true end
            if actions then actions.Visible = true end
            settingsFrame.Visible = false
        else
            mainTabBtn.BackgroundColor3 = Color3.fromRGB(40,40,46)
            mainTabBtn.TextColor3 = Color3.fromRGB(200,200,200)
            settingsTabBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
            settingsTabBtn.TextColor3 = Color3.fromRGB(235,235,235)
            if content then content.Visible = false end
            if actions then actions.Visible = false end
            settingsFrame.Visible = true
        end
    end

    mainTabBtn.MouseButton1Click:Connect(function() SwitchTab("Main") end)
    settingsTabBtn.MouseButton1Click:Connect(function() SwitchTab("Settings") end)

    -- content area (Main tab)
    local content = Instance.new("Frame", panel)
    content.Size = UDim2.new(1, -20, 1, -96); content.Position = UDim2.new(0, 10, 0, 80); content.BackgroundTransparency = 1
    local leftCol = Instance.new("Frame", content); leftCol.Size = UDim2.new(0.5, -6, 1, 0); leftCol.BackgroundTransparency = 1
    local rightCol = Instance.new("Frame", content); rightCol.Size = UDim2.new(0.5, -6, 1, 0); rightCol.Position = UDim2.new(0.5, 12, 0, 0); rightCol.BackgroundTransparency = 1
    -- thin divider between columns for visual separation
    local divider = Instance.new("Frame", content)
    divider.Size = UDim2.new(0, 2, 1, 0)
    divider.Position = UDim2.new(0.5, -6, 0, 0)
    divider.BackgroundColor3 = Color3.fromRGB(40,40,48)
    divider.BorderSizePixel = 0
    local dividerCorner = Instance.new("UICorner", divider)
    dividerCorner.CornerRadius = UDim.new(0, 2)

    -- left: mode
    local modeLabel = Instance.new("TextLabel", leftCol); modeLabel.Size = UDim2.new(1,0,0,18); modeLabel.Text = "Mode"; modeLabel.BackgroundTransparency = 1; modeLabel.Font = Enum.Font.GothamSemibold; modeLabel.TextColor3 = Color3.fromRGB(200,200,200)
    local modeButtons = Instance.new("Frame", leftCol); modeButtons.Size = UDim2.new(1,0,0,70); modeButtons.Position = UDim2.new(0,0,0,24); modeButtons.BackgroundTransparency = 1
    local fastButton = Instance.new("TextButton", modeButtons); fastButton.Size = UDim2.new(0.48,0,0,34); fastButton.Position = UDim2.new(0,0,0,0); fastButton.Text = "Fast"; fastButton.BackgroundColor3 = Color3.fromRGB(75,95,165); Instance.new("UICorner", fastButton)
    local secureButton = Instance.new("TextButton", modeButtons); secureButton.Size = UDim2.new(0.48,0,0,34); secureButton.Position = UDim2.new(0.52,0,0,0); secureButton.Text = "Secure"; secureButton.BackgroundColor3 = Color3.fromRGB(74,155,88); Instance.new("UICorner", secureButton)

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

    -- actions (part of Main tab)
    local actions = Instance.new("Frame", panel); actions.Size = UDim2.new(1,-20,0,42); actions.Position = UDim2.new(0,10,1,-50); actions.BackgroundTransparency = 1
    local startBtn = Instance.new("TextButton", actions); startBtn.Size = UDim2.new(0.5,-6,1,0); startBtn.Position = UDim2.new(0,0,0,0); startBtn.Text = "Start"; startBtn.BackgroundColor3 = Color3.fromRGB(70,170,90); startBtn.TextColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", startBtn)
    local stopBtn = Instance.new("TextButton", actions); stopBtn.Size = UDim2.new(0.5,-6,1,0); stopBtn.Position = UDim2.new(0.5,12,0,0); stopBtn.Text = "Stop"; stopBtn.BackgroundColor3 = Color3.fromRGB(190,60,60); stopBtn.TextColor3 = Color3.fromRGB(255,255,255); Instance.new("UICorner", stopBtn)

    -- floating toggle
    -- Floating toggle: keep margin so it doesn't overlap header on small screens
    local floatBtn = Instance.new("TextButton", screenGui); floatBtn.Name = "FloatToggle"; floatBtn.Size = UDim2.new(0,44,0,44); floatBtn.Position = UDim2.new(0,12,0,12); floatBtn.Text = "≡"; Instance.new("UICorner", floatBtn)
    floatBtn.BackgroundColor3 = Color3.fromRGB(40,40,46); floatBtn.Font = Enum.Font.GothamBold; floatBtn.TextSize = 20; floatBtn.TextColor3 = Color3.fromRGB(235,235,235)
    floatBtn.MouseButton1Click:Connect(function() panel.Visible = not panel.Visible end)

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

    -- callbacks
    fastButton.MouseButton1Click:Connect(function() Config.mode = "fast"; Notify("modern_autofish", "Mode set to FAST") end)
    secureButton.MouseButton1Click:Connect(function() Config.mode = "secure"; Notify("modern_autofish", "Mode set to SECURE") end)

    local origPanelSize = panel.Size; local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        content.Visible = not minimized
        actions.Visible = not minimized
        panel.Size = minimized and UDim2.new(0,380,0,60) or origPanelSize
    end)

    closeBtn.MouseButton1Click:Connect(function()
        Config.enabled = false; sessionId = sessionId + 1
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
    Config = Config
}

print("modern_autofish loaded - UI created and API available via _G.ModernAutoFish")
