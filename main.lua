--[[
    BOT FISH IT V1 - Modern UI
    Comparison Auto Fishing Script
    AFK V1 (old.lua) vs AFK V2 (new.lua)
    
    Features:
    - Modern table-based UI design
    - Minimize & Floating button functionality
    - Clean, professional interface
    - Mobile-friendly responsive design
--]]

print("🔥 Loading BOT FISH IT V1...")

-- ═══════════════════════════════════════════════════════════════
-- SERVICES & CORE SETUP
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════
-- UI STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════

local UIState = {
    isMinimized = false,
    isDragging = false,
    dragStart = nil,
    startPos = nil
}

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function Notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "BOT FISH IT V1",
            Text = text or "Notification", 
            Duration = duration,
            Icon = "rbxassetid://6023426923"
        })
    end)
    print("📢", title, "-", text)
end

-- ═══════════════════════════════════════════════════════════════
-- MODERN UI CREATION
-- ═══════════════════════════════════════════════════════════════

-- Cleanup existing UI
if LocalPlayer.PlayerGui:FindFirstChild("BotFishItV1") then
    LocalPlayer.PlayerGui.BotFishItV1:Destroy()
end

-- Create main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BotFishItV1"
ScreenGui.Parent = LocalPlayer.PlayerGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Main Frame (Table Container)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.3, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 400, 0, 250)
MainFrame.Active = true
MainFrame.Draggable = true

-- Add corner radius
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Add gradient background
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35))
}
Gradient.Rotation = 45
Gradient.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 40)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- Title gradient
local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 25))
}
TitleGradient.Rotation = 90
TitleGradient.Parent = TitleBar

-- Title Text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "BOT FISH IT V1"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Name = "MinimizeBtn"
MinimizeBtn.Parent = TitleBar
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Position = UDim2.new(1, -65, 0.5, -10)
MinimizeBtn.Size = UDim2.new(0, 25, 0, 20)
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.Text = "—"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 14

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 4)
MinimizeCorner.Parent = MinimizeBtn

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -35, 0.5, -10)
CloseBtn.Size = UDim2.new(0, 25, 0, 20)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 4)
CloseCorner.Parent = CloseBtn

-- Table Container
local TableContainer = Instance.new("Frame")
TableContainer.Name = "TableContainer"
TableContainer.Parent = MainFrame
TableContainer.BackgroundTransparency = 1
TableContainer.Position = UDim2.new(0, 10, 0, 50)
TableContainer.Size = UDim2.new(1, -20, 1, -60)

-- Table Header
local HeaderFrame = Instance.new("Frame")
HeaderFrame.Name = "HeaderFrame"
HeaderFrame.Parent = TableContainer
HeaderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
HeaderFrame.BorderSizePixel = 0
HeaderFrame.Size = UDim2.new(1, 0, 0, 35)

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 6)
HeaderCorner.Parent = HeaderFrame

-- Header gradient
local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 55, 55))
}
HeaderGradient.Rotation = 90
HeaderGradient.Parent = HeaderFrame

-- Header Columns
local AutoFishingHeader = Instance.new("TextLabel")
AutoFishingHeader.Name = "AutoFishingHeader"
AutoFishingHeader.Parent = HeaderFrame
AutoFishingHeader.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
AutoFishingHeader.BorderSizePixel = 0
AutoFishingHeader.Position = UDim2.new(0, 5, 0, 5)
AutoFishingHeader.Size = UDim2.new(0, 120, 1, -10)
AutoFishingHeader.Font = Enum.Font.SourceSansBold
AutoFishingHeader.Text = "AUTO FISHING"
AutoFishingHeader.TextColor3 = Color3.fromRGB(0, 0, 0)
AutoFishingHeader.TextSize = 14
AutoFishingHeader.TextXAlignment = Enum.TextXAlignment.Center

local AutoHeaderCorner = Instance.new("UICorner")
AutoHeaderCorner.CornerRadius = UDim.new(0, 4)
AutoHeaderCorner.Parent = AutoFishingHeader

-- Method Column Headers
local MethodHeader1 = Instance.new("TextLabel")
MethodHeader1.Name = "MethodHeader1"
MethodHeader1.Parent = HeaderFrame
MethodHeader1.BackgroundTransparency = 1
MethodHeader1.Position = UDim2.new(0, 135, 0, 0)
MethodHeader1.Size = UDim2.new(0, 100, 1, 0)
MethodHeader1.Font = Enum.Font.SourceSansBold
MethodHeader1.Text = "METHOD"
MethodHeader1.TextColor3 = Color3.fromRGB(255, 255, 255)
MethodHeader1.TextSize = 14
MethodHeader1.TextXAlignment = Enum.TextXAlignment.Center

local StatusHeader = Instance.new("TextLabel")
StatusHeader.Name = "StatusHeader"
StatusHeader.Parent = HeaderFrame
StatusHeader.BackgroundTransparency = 1
StatusHeader.Position = UDim2.new(0, 245, 0, 0)
StatusHeader.Size = UDim2.new(0, 100, 1, 0)
StatusHeader.Font = Enum.Font.SourceSansBold
StatusHeader.Text = "STATUS"
StatusHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusHeader.TextSize = 14
StatusHeader.TextXAlignment = Enum.TextXAlignment.Center

-- Table Rows Container
local RowsContainer = Instance.new("Frame")
RowsContainer.Name = "RowsContainer"
RowsContainer.Parent = TableContainer
RowsContainer.BackgroundTransparency = 1
RowsContainer.Position = UDim2.new(0, 0, 0, 45)
RowsContainer.Size = UDim2.new(1, 0, 1, -45)

-- AFK 1 Row
local AFK1Row = Instance.new("Frame")
AFK1Row.Name = "AFK1Row"
AFK1Row.Parent = RowsContainer
AFK1Row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AFK1Row.BorderSizePixel = 0
AFK1Row.Position = UDim2.new(0, 0, 0, 5)
AFK1Row.Size = UDim2.new(1, 0, 0, 40)

local AFK1Corner = Instance.new("UICorner")
AFK1Corner.CornerRadius = UDim.new(0, 6)
AFK1Corner.Parent = AFK1Row

-- AFK 1 Labels
local AFK1Label = Instance.new("TextLabel")
AFK1Label.Name = "AFK1Label"
AFK1Label.Parent = AFK1Row
AFK1Label.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
AFK1Label.BorderSizePixel = 0
AFK1Label.Position = UDim2.new(0, 5, 0, 5)
AFK1Label.Size = UDim2.new(0, 120, 1, -10)
AFK1Label.Font = Enum.Font.SourceSansBold
AFK1Label.Text = "AFK 1"
AFK1Label.TextColor3 = Color3.fromRGB(0, 0, 0)
AFK1Label.TextSize = 16

local AFK1LabelCorner = Instance.new("UICorner")
AFK1LabelCorner.CornerRadius = UDim.new(0, 4)
AFK1LabelCorner.Parent = AFK1Label

local AFK1Method = Instance.new("TextLabel")
AFK1Method.Name = "AFK1Method"
AFK1Method.Parent = AFK1Row
AFK1Method.BackgroundTransparency = 1
AFK1Method.Position = UDim2.new(0, 135, 0, 0)
AFK1Method.Size = UDim2.new(0, 100, 1, 0)
AFK1Method.Font = Enum.Font.SourceSans
AFK1Method.Text = "Simple"
AFK1Method.TextColor3 = Color3.fromRGB(200, 200, 200)
AFK1Method.TextSize = 14
AFK1Method.TextXAlignment = Enum.TextXAlignment.Center

-- AFK 1 Toggle Button
local AFK1Toggle = Instance.new("TextButton")
AFK1Toggle.Name = "AFK1Toggle"
AFK1Toggle.Parent = AFK1Row
AFK1Toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AFK1Toggle.BorderSizePixel = 0
AFK1Toggle.Position = UDim2.new(0, 255, 0.5, -12)
AFK1Toggle.Size = UDim2.new(0, 80, 0, 24)
AFK1Toggle.Font = Enum.Font.SourceSansBold
AFK1Toggle.Text = "OFF"
AFK1Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AFK1Toggle.TextSize = 14

local AFK1ToggleCorner = Instance.new("UICorner")
AFK1ToggleCorner.CornerRadius = UDim.new(0, 5)
AFK1ToggleCorner.Parent = AFK1Toggle

-- AFK 2 Row
local AFK2Row = Instance.new("Frame")
AFK2Row.Name = "AFK2Row"
AFK2Row.Parent = RowsContainer
AFK2Row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
AFK2Row.BorderSizePixel = 0
AFK2Row.Position = UDim2.new(0, 0, 0, 55)
AFK2Row.Size = UDim2.new(1, 0, 0, 40)

local AFK2Corner = Instance.new("UICorner")
AFK2Corner.CornerRadius = UDim.new(0, 6)
AFK2Corner.Parent = AFK2Row

-- AFK 2 Labels
local AFK2Label = Instance.new("TextLabel")
AFK2Label.Name = "AFK2Label"
AFK2Label.Parent = AFK2Row
AFK2Label.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
AFK2Label.BorderSizePixel = 0
AFK2Label.Position = UDim2.new(0, 5, 0, 5)
AFK2Label.Size = UDim2.new(0, 120, 1, -10)
AFK2Label.Font = Enum.Font.SourceSansBold
AFK2Label.Text = "AFK 2"
AFK2Label.TextColor3 = Color3.fromRGB(0, 0, 0)
AFK2Label.TextSize = 16

local AFK2LabelCorner = Instance.new("UICorner")
AFK2LabelCorner.CornerRadius = UDim.new(0, 4)
AFK2LabelCorner.Parent = AFK2Label

local AFK2Method = Instance.new("TextLabel")
AFK2Method.Name = "AFK2Method"
AFK2Method.Parent = AFK2Row
AFK2Method.BackgroundTransparency = 1
AFK2Method.Position = UDim2.new(0, 135, 0, 0)
AFK2Method.Size = UDim2.new(0, 100, 1, 0)
AFK2Method.Font = Enum.Font.SourceSans
AFK2Method.Text = "Advanced"
AFK2Method.TextColor3 = Color3.fromRGB(200, 200, 200)
AFK2Method.TextSize = 14
AFK2Method.TextXAlignment = Enum.TextXAlignment.Center

-- AFK 2 Toggle Button
local AFK2Toggle = Instance.new("TextButton")
AFK2Toggle.Name = "AFK2Toggle"
AFK2Toggle.Parent = AFK2Row
AFK2Toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AFK2Toggle.BorderSizePixel = 0
AFK2Toggle.Position = UDim2.new(0, 255, 0.5, -12)
AFK2Toggle.Size = UDim2.new(0, 80, 0, 24)
AFK2Toggle.Font = Enum.Font.SourceSansBold
AFK2Toggle.Text = "OFF"
AFK2Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
AFK2Toggle.TextSize = 14

local AFK2ToggleCorner = Instance.new("UICorner")
AFK2ToggleCorner.CornerRadius = UDim.new(0, 5)
AFK2ToggleCorner.Parent = AFK2Toggle

-- Floating Button (Hidden by default)
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "FloatingBtn"
FloatingBtn.Parent = ScreenGui
FloatingBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Position = UDim2.new(0, 20, 0.5, -25)
FloatingBtn.Size = UDim2.new(0, 50, 0, 50)
FloatingBtn.Font = Enum.Font.SourceSansBold
FloatingBtn.Text = "🎣"
FloatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatingBtn.TextSize = 20
FloatingBtn.Visible = false

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(0, 25)
FloatingCorner.Parent = FloatingBtn

local FloatingGradient = Instance.new("UIGradient")
FloatingGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 30))
}
FloatingGradient.Rotation = 45
FloatingGradient.Parent = FloatingBtn

-- ═══════════════════════════════════════════════════════════════
-- UI FUNCTIONALITY & ANIMATIONS
-- ═══════════════════════════════════════════════════════════════

-- Smooth animation function
local function animateButton(button, targetColor, targetSize)
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    if targetColor then
        local colorTween = TweenService:Create(button, tweenInfo, {BackgroundColor3 = targetColor})
        colorTween:Play()
    end
    
    if targetSize then
        local sizeTween = TweenService:Create(button, tweenInfo, {Size = targetSize})
        sizeTween:Play()
    end
end

-- Toggle UI visibility with smooth animation
local function toggleUI()
    UIState.isMinimized = not UIState.isMinimized
    
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    if UIState.isMinimized then
        -- Hide main frame
        local hideTween = TweenService:Create(MainFrame, tweenInfo, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        hideTween:Play()
        
        hideTween.Completed:Connect(function()
            MainFrame.Visible = false
            FloatingBtn.Visible = true
            
            -- Animate floating button entrance
            FloatingBtn.Size = UDim2.new(0, 0, 0, 0)
            local showFloating = TweenService:Create(FloatingBtn, tweenInfo, {
                Size = UDim2.new(0, 50, 0, 50)
            })
            showFloating:Play()
        end)
    else
        -- Show main frame
        FloatingBtn.Visible = false
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        local showTween = TweenService:Create(MainFrame, tweenInfo, {
            Size = UDim2.new(0, 400, 0, 250),
            Position = UDim2.new(0.3, 0, 0.3, 0)
        })
        showTween:Play()
    end
end

-- Button hover effects
local function setupButtonHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        animateButton(button, hoverColor)
    end)
    
    button.MouseLeave:Connect(function()
        animateButton(button, normalColor)
    end)
end

-- Setup hover effects for all buttons
setupButtonHover(MinimizeBtn, Color3.fromRGB(70, 70, 70), Color3.fromRGB(90, 90, 90))
setupButtonHover(CloseBtn, Color3.fromRGB(200, 50, 50), Color3.fromRGB(220, 70, 70))
setupButtonHover(FloatingBtn, Color3.fromRGB(40, 40, 40), Color3.fromRGB(60, 60, 60))

-- ═══════════════════════════════════════════════════════════════
-- UI EVENT HANDLERS
-- ═══════════════════════════════════════════════════════════════

-- Close button functionality
CloseBtn.MouseButton1Click:Connect(function()
    animateButton(CloseBtn, Color3.fromRGB(255, 100, 100))
    
    local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeTween = TweenService:Create(ScreenGui, fadeInfo, {
        Enabled = false
    })
    fadeTween:Play()
    
    task.wait(0.3)
    ScreenGui:Destroy()
    Notify("BOT FISH IT V1", "👋 UI Closed - Thanks for using!")
end)

-- Minimize button functionality
MinimizeBtn.MouseButton1Click:Connect(function()
    animateButton(MinimizeBtn, Color3.fromRGB(90, 90, 90))
    toggleUI()
end)

-- Floating button functionality
FloatingBtn.MouseButton1Click:Connect(function()
    animateButton(FloatingBtn, Color3.fromRGB(60, 60, 60))
    toggleUI()
end)

-- ═══════════════════════════════════════════════════════════════
-- FISHING SYSTEM VARIABLES
-- ═══════════════════════════════════════════════════════════════

local FishingState = {
    AFK1 = {
        active = false,
        fishCount = 0,
        startTime = 0,
        connection = nil
    },
    AFK2 = {
        active = false,
        fishCount = 0,
        startTime = 0,
        connection = nil,
        perfectCasts = 0,
        normalCasts = 0
    }
}

-- ═══════════════════════════════════════════════════════════════
-- REMOTE EVENTS SETUP
-- ═══════════════════════════════════════════════════════════════

local Rs = ReplicatedStorage
local Remotes = {}

-- Try to find remotes
pcall(function()
    local net = Rs.Packages._Index["sleitnick_net@0.2.0"].net
    Remotes = {
        EquipRod = net["RE/EquipToolFromHotbar"],
        UnEquipRod = net["RE/UnequipToolFromHotbar"],
        RequestFishing = net["RF/RequestFishingMinigameStarted"],
        ChargeRod = net["RF/ChargeFishingRod"],
        FishingComplete = net["RE/FishingCompleted"],
        CancelFishing = net["RF/CancelFishingInputs"],
        SellAll = net["RF/SellAllItems"]
    }
end)

-- ═══════════════════════════════════════════════════════════════
-- AFK FISHING SYSTEMS
-- ═══════════════════════════════════════════════════════════════

-- AFK 1 System (Simple approach)
local function startAFK1()
    if FishingState.AFK1.active then return end
    
    FishingState.AFK1.active = true
    FishingState.AFK1.startTime = tick()
    FishingState.AFK1.fishCount = 0
    
    Notify("AFK 1 Started", "🎣 Simple fishing mode activated!")
    
    -- Update UI
    AFK1Toggle.Text = "ON"
    AFK1Toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    
    -- Simple fishing loop
    FishingState.AFK1.connection = task.spawn(function()
        while FishingState.AFK1.active do
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                
                local success = pcall(function()
                    if Remotes.RequestFishing then
                        Remotes.RequestFishing:InvokeServer()
                        task.wait(0.1)
                        
                        if Remotes.ChargeRod then
                            Remotes.ChargeRod:InvokeServer(100)
                        end
                        
                        task.wait(0.5)
                        
                        if Remotes.FishingComplete then
                            Remotes.FishingComplete:FireServer()
                        end
                        
                        FishingState.AFK1.fishCount = FishingState.AFK1.fishCount + 1
                    end
                end)
                
                if not success then
                    print("❌ AFK1: Fishing attempt failed")
                end
            end
            
            task.wait(0.4) -- Simple delay
        end
    end)
end

local function stopAFK1()
    if not FishingState.AFK1.active then return end
    
    FishingState.AFK1.active = false
    
    if FishingState.AFK1.connection then
        task.cancel(FishingState.AFK1.connection)
        FishingState.AFK1.connection = nil
    end
    
    local sessionTime = tick() - FishingState.AFK1.startTime
    
    -- Update UI
    AFK1Toggle.Text = "OFF"
    AFK1Toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    Notify("AFK 1 Stopped", 
        string.format("🎣 Session: %.1f min\n🐟 Fish: %d", 
        sessionTime / 60, FishingState.AFK1.fishCount))
end

-- AFK 2 System (Advanced approach)
local function getRandomDelay(min, max)
    return min + (math.random() * (max - min))
end

local function startAFK2()
    if FishingState.AFK2.active then return end
    
    FishingState.AFK2.active = true
    FishingState.AFK2.startTime = tick()
    FishingState.AFK2.fishCount = 0
    FishingState.AFK2.perfectCasts = 0
    FishingState.AFK2.normalCasts = 0
    
    Notify("AFK 2 Started", "⚡ Advanced fishing mode activated!\n🔒 AI systems online")
    
    -- Update UI
    AFK2Toggle.Text = "ON"
    AFK2Toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    
    -- Advanced fishing loop
    FishingState.AFK2.connection = task.spawn(function()
        while FishingState.AFK2.active do
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                
                local success = pcall(function()
                    if Remotes.RequestFishing then
                        Remotes.RequestFishing:InvokeServer()
                        
                        -- Smart delay
                        local delay = getRandomDelay(0.3, 0.7)
                        task.wait(delay)
                        
                        -- Smart casting (70% perfect, 30% random)
                        if math.random(100) <= 70 then
                            -- Perfect cast
                            if Remotes.ChargeRod then
                                Remotes.ChargeRod:InvokeServer(100)
                            end
                            FishingState.AFK2.perfectCasts = FishingState.AFK2.perfectCasts + 1
                        else
                            -- Random cast
                            if Remotes.ChargeRod then
                                Remotes.ChargeRod:InvokeServer(math.random(60, 95))
                            end
                            FishingState.AFK2.normalCasts = FishingState.AFK2.normalCasts + 1
                        end
                        
                        task.wait(0.5)
                        
                        if Remotes.FishingComplete then
                            Remotes.FishingComplete:FireServer()
                        end
                        
                        FishingState.AFK2.fishCount = FishingState.AFK2.fishCount + 1
                    end
                end)
                
                if not success then
                    print("❌ AFK2: Advanced fishing attempt failed")
                end
            end
            
            -- Variable delay for humanization
            local nextDelay = getRandomDelay(0.8, 1.2)
            task.wait(nextDelay)
        end
    end)
end

local function stopAFK2()
    if not FishingState.AFK2.active then return end
    
    FishingState.AFK2.active = false
    
    if FishingState.AFK2.connection then
        task.cancel(FishingState.AFK2.connection)
        FishingState.AFK2.connection = nil
    end
    
    local sessionTime = tick() - FishingState.AFK2.startTime
    local perfectRate = FishingState.AFK2.perfectCasts + FishingState.AFK2.normalCasts > 0 and 
        (FishingState.AFK2.perfectCasts / (FishingState.AFK2.perfectCasts + FishingState.AFK2.normalCasts) * 100) or 0
    
    -- Update UI
    AFK2Toggle.Text = "OFF"
    AFK2Toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    Notify("AFK 2 Stopped", 
        string.format("⚡ Session: %.1f min\n🐟 Fish: %d\n⭐ Perfect: %.1f%%", 
        sessionTime / 60, FishingState.AFK2.fishCount, perfectRate))
end

-- ═══════════════════════════════════════════════════════════════
-- TOGGLE BUTTON EVENTS
-- ═══════════════════════════════════════════════════════════════

-- AFK 1 Toggle
AFK1Toggle.MouseButton1Click:Connect(function()
    animateButton(AFK1Toggle, nil, UDim2.new(0, 85, 0, 26))
    task.wait(0.1)
    animateButton(AFK1Toggle, nil, UDim2.new(0, 80, 0, 24))
    
    if FishingState.AFK1.active then
        stopAFK1()
    else
        -- Stop AFK2 if running
        if FishingState.AFK2.active then
            stopAFK2()
        end
        startAFK1()
    end
end)

-- AFK 2 Toggle
AFK2Toggle.MouseButton1Click:Connect(function()
    animateButton(AFK2Toggle, nil, UDim2.new(0, 85, 0, 26))
    task.wait(0.1)
    animateButton(AFK2Toggle, nil, UDim2.new(0, 80, 0, 24))
    
    if FishingState.AFK2.active then
        stopAFK2()
    else
        -- Stop AFK1 if running
        if FishingState.AFK1.active then
            stopAFK1()
        end
        startAFK2()
    end
end)

-- Setup hover effects for toggle buttons
setupButtonHover(AFK1Toggle, AFK1Toggle.BackgroundColor3, Color3.fromRGB(220, 70, 70))
setupButtonHover(AFK2Toggle, AFK2Toggle.BackgroundColor3, Color3.fromRGB(220, 70, 70))

-- ═══════════════════════════════════════════════════════════════
-- STATUS DISPLAY & LIVE UPDATES
-- ═══════════════════════════════════════════════════════════════

-- Status display in the method column
local function updateStatus()
    -- Update AFK1 status
    if FishingState.AFK1.active then
        AFK1Method.Text = "Running..."
        AFK1Method.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        AFK1Method.Text = "Simple"
        AFK1Method.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    -- Update AFK2 status
    if FishingState.AFK2.active then
        AFK2Method.Text = "AI Active"
        AFK2Method.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        AFK2Method.Text = "Advanced"
        AFK2Method.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

-- Live statistics update
task.spawn(function()
    while true do
        task.wait(1)
        updateStatus()
        
        -- Update fish counts in labels (optional visual enhancement)
        if FishingState.AFK1.active and FishingState.AFK1.fishCount > 0 then
            AFK1Label.Text = "AFK 1 (" .. FishingState.AFK1.fishCount .. ")"
        else
            AFK1Label.Text = "AFK 1"
        end
        
        if FishingState.AFK2.active and FishingState.AFK2.fishCount > 0 then
            AFK2Label.Text = "AFK 2 (" .. FishingState.AFK2.fishCount .. ")"
        else
            AFK2Label.Text = "AFK 2"
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- INITIALIZATION & WELCOME
-- ═══════════════════════════════════════════════════════════════

-- Initial UI state
updateStatus()

-- Welcome notification
Notify("BOT FISH IT V1", 
    "🔥 Modern UI loaded successfully!\n\n" ..
    "🎣 AFK 1: Simple & Fast\n" ..
    "⚡ AFK 2: Advanced & AI\n\n" ..
    "🖱️ Click minimize to use floating button\n" ..
    "👆 Toggle ON/OFF to start fishing!")

-- Mobile detection and optimization
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
if isMobile then
    -- Scale UI for mobile
    MainFrame.Size = UDim2.new(0, 350, 0, 220)
    TitleLabel.TextSize = 16
    
    -- Adjust button sizes for touch
    AFK1Toggle.Size = UDim2.new(0, 70, 0, 28)
    AFK2Toggle.Size = UDim2.new(0, 70, 0, 28)
    
    FloatingBtn.Size = UDim2.new(0, 60, 0, 60)
    FloatingBtn.Position = UDim2.new(0, 15, 0.5, -30)
    
    Notify("Mobile Detected", "📱 UI optimized for mobile/tablet!")
end

print("✅ BOT FISH IT V1 - Modern UI loaded successfully!")
print("🎣 Ready to fish with style!")
print("🔧 Features: Minimize, Floating Button, Smooth Animations")
print("📊 Two AFK modes available: Simple & Advanced")

-- ═══════════════════════════════════════════════════════════════
-- REMOTE EVENTS SETUP
-- ═══════════════════════════════════════════════════════════════

local Rs = ReplicatedStorage
local Remotes = {}

-- Try to find remotes (both scripts use different paths)
pcall(function()
    local net = Rs.Packages._Index["sleitnick_net@0.2.0"].net
    Remotes = {
        EquipRod = net["RE/EquipToolFromHotbar"],
        UnEquipRod = net["RE/UnequipToolFromHotbar"],
        RequestFishing = net["RF/RequestFishingMinigameStarted"],
        ChargeRod = net["RF/ChargeFishingRod"],
        FishingComplete = net["RE/FishingCompleted"],
        CancelFishing = net["RF/CancelFishingInputs"],
        SellAll = net["RF/SellAllItems"]
    }
end)

-- ═══════════════════════════════════════════════════════════════
-- AFK V1 SYSTEM (from old.lua - Simple & Direct)
-- ═══════════════════════════════════════════════════════════════

local AFKV1 = {
    -- Simple state management
    isAutoFishing = false,
    isAntiKickActive = false,
    fishCount = 0,
    startTime = 0,
    totalProfit = 0,
    
    -- Constants
    FISH_VALUE = 1,
    CHECK_INTERVAL = 0.4,
    ANTI_KICK_INTERVAL = 30
}

-- AFK V1 Functions
function AFKV1.autoFish()
    if not AFKV1.isAutoFishing then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    -- Simple remote call approach
    local success = pcall(function()
        if Remotes.RequestFishing then
            Remotes.RequestFishing:InvokeServer()
            task.wait(0.1)
            
            if Remotes.ChargeRod then
                Remotes.ChargeRod:InvokeServer(100)
            end
            
            task.wait(0.5)
            
            if Remotes.FishingComplete then
                Remotes.FishingComplete:FireServer()
            end
            
            AFKV1.fishCount = AFKV1.fishCount + 1
            AFKV1.totalProfit = AFKV1.totalProfit + AFKV1.FISH_VALUE
        end
    end)
    
    if not success then
        print("❌ AFK V1: Fishing failed")
    end
end

function AFKV1.antiKick()
    if not AFKV1.isAntiKickActive then return end
    
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid:Move(Vector3.new(0, 0, 0), true)
    end
end

function AFKV1.start()
    AFKV1.isAutoFishing = true
    AFKV1.startTime = tick()
    AFKV1.fishCount = 0
    AFKV1.totalProfit = 0
    
    Notify("AFK V1 Started", "🎣 Simple auto fishing activated!")
    
    -- Main fishing loop (Simple approach)
    task.spawn(function()
        while AFKV1.isAutoFishing do
            AFKV1.autoFish()
            task.wait(AFKV1.CHECK_INTERVAL)
        end
    end)
    
    -- Anti-kick loop
    task.spawn(function()
        while AFKV1.isAutoFishing do
            AFKV1.antiKick()
            task.wait(AFKV1.ANTI_KICK_INTERVAL)
        end
    end)
end

function AFKV1.stop()
    AFKV1.isAutoFishing = false
    AFKV1.isAntiKickActive = false
    
    local sessionTime = tick() - AFKV1.startTime
    Notify("AFK V1 Stopped", 
        string.format("🎣 Session: %.1f min\n🐟 Fish: %d\n💰 Profit: $%d", 
        sessionTime / 60, AFKV1.fishCount, AFKV1.totalProfit))
end

-- ═══════════════════════════════════════════════════════════════
-- AFK V2 SYSTEM (from new.lua - Advanced & Feature Rich)
-- ═══════════════════════════════════════════════════════════════

local AFKV2 = {
    -- Advanced state management
    autofish = false,
    autofishSession = 0,
    autofishThread = nil,
    perfectCast = false,
    safeMode = false,
    hybridMode = false,
    
    -- Statistics
    fishCaught = 0,
    itemsSold = 0,
    sessionStartTime = 0,
    perfectCasts = 0,
    normalCasts = 0,
    
    -- Configuration
    autoRecastDelay = 0.4,
    autoSellThreshold = 10,
    autoSellOnThreshold = false,
    safeModeChance = 70, -- 70% perfect cast chance
    hybridMinDelay = 1.0,
    hybridMaxDelay = 2.5,
    
    -- Feature states
    featureState = {
        AutoSell = false,
        SmartInventory = false,
        Analytics = true,
        Safety = true
    }
}

-- AFK V2 Advanced Functions
function AFKV2.getRandomDelay(min, max)
    return min + (math.random() * (max - min))
end

function AFKV2.shouldPerfectCast()
    if AFKV2.perfectCast then
        return true
    elseif AFKV2.safeMode then
        return math.random(100) <= AFKV2.safeModeChance
    elseif AFKV2.hybridMode then
        return math.random(100) <= 70 -- Hybrid 70% chance
    end
    return false
end

function AFKV2.advancedAutoFish()
    local currentSession = AFKV2.autofishSession
    
    while AFKV2.autofish and currentSession == AFKV2.autofishSession do
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            
            local success = pcall(function()
                -- Advanced fishing logic
                if Remotes.RequestFishing then
                    Remotes.RequestFishing:InvokeServer()
                    
                    -- Smart delay system
                    local delay = AFKV2.hybridMode and 
                        AFKV2.getRandomDelay(AFKV2.hybridMinDelay, AFKV2.hybridMaxDelay) or 
                        AFKV2.autoRecastDelay
                    
                    task.wait(delay)
                    
                    -- Perfect cast logic
                    if AFKV2.shouldPerfectCast() then
                        if Remotes.ChargeRod then
                            Remotes.ChargeRod:InvokeServer(100) -- Perfect cast
                        end
                        AFKV2.perfectCasts = AFKV2.perfectCasts + 1
                    else
                        if Remotes.ChargeRod then
                            Remotes.ChargeRod:InvokeServer(math.random(60, 95)) -- Random cast
                        end
                        AFKV2.normalCasts = AFKV2.normalCasts + 1
                    end
                    
                    task.wait(0.5)
                    
                    if Remotes.FishingComplete then
                        Remotes.FishingComplete:FireServer()
                    end
                    
                    AFKV2.fishCaught = AFKV2.fishCaught + 1
                    
                    -- Auto sell logic
                    if AFKV2.autoSellOnThreshold and AFKV2.fishCaught % AFKV2.autoSellThreshold == 0 then
                        if Remotes.SellAll then
                            Remotes.SellAll:InvokeServer()
                            AFKV2.itemsSold = AFKV2.itemsSold + 1
                            Notify("AFK V2 Auto Sell", "🏪 Items sold automatically!")
                        end
                    end
                end
            end)
            
            if not success then
                print("❌ AFK V2: Advanced fishing failed")
            end
            
            -- Smart delay between casts
            local nextDelay = AFKV2.hybridMode and 
                AFKV2.getRandomDelay(0.8, 1.5) or 
                AFKV2.autoRecastDelay
            
            task.wait(nextDelay)
        else
            task.wait(1) -- Wait for character
        end
    end
end

function AFKV2.start()
    AFKV2.autofish = true
    AFKV2.autofishSession = AFKV2.autofishSession + 1
    AFKV2.sessionStartTime = tick()
    AFKV2.fishCaught = 0
    AFKV2.itemsSold = 0
    AFKV2.perfectCasts = 0
    AFKV2.normalCasts = 0
    
    Notify("AFK V2 Started", 
        "🎣 Advanced auto fishing activated!\n" ..
        "⚡ AI systems online\n" ..
        "🔒 Safety protocols active")
    
    -- Advanced threading approach
    AFKV2.autofishThread = task.spawn(function()
        AFKV2.advancedAutoFish()
    end)
end

function AFKV2.stop()
    AFKV2.autofish = false
    AFKV2.autofishSession = AFKV2.autofishSession + 1
    
    if AFKV2.autofishThread then
        task.cancel(AFKV2.autofishThread)
        AFKV2.autofishThread = nil
    end
    
    local sessionTime = tick() - AFKV2.sessionStartTime
    local perfectRate = AFKV2.perfectCasts + AFKV2.normalCasts > 0 and 
        (AFKV2.perfectCasts / (AFKV2.perfectCasts + AFKV2.normalCasts) * 100) or 0
print("✅ BOT FISH IT V1 - Modern UI loaded successfully!")
print("🎣 Ready to fish with style!")
print("� Features: Minimize, Floating Button, Smooth Animations")
print("📊 Two AFK modes available: Simple & Advanced")
