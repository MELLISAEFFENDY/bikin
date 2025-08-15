-- fishit_debug.lua
-- Debug & Research Tool untuk Fish It Game
-- Digunakan untuk menganalisis struktur game dan menemukan fishing mechanics

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Logging system
local DebugLog = {}
local function Log(category, message)
    local timestamp = os.date("%H:%M:%S")
    local logEntry = string.format("[%s] %s: %s", timestamp, category, tostring(message))
    table.insert(DebugLog, logEntry)
    print(logEntry)
    
    -- Keep only last 100 entries
    if #DebugLog > 100 then
        table.remove(DebugLog, 1)
    end
end

-- Notification system
local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
    end)
    Log("NOTIFY", title .. ": " .. text)
end

-- Deep scan function for objects
local function DeepScan(obj, depth, maxDepth)
    depth = depth or 0
    maxDepth = maxDepth or 3
    
    if depth > maxDepth then return {} end
    
    local result = {
        Name = obj.Name,
        ClassName = obj.ClassName,
        FullName = obj:GetFullName(),
        Children = {}
    }
    
    -- Add properties for important objects
    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
        result.Type = "Remote"
        result.IsRemoteEvent = obj:IsA("RemoteEvent")
        result.IsRemoteFunction = obj:IsA("RemoteFunction")
    elseif obj:IsA("Tool") then
        result.Type = "Tool"
        result.RequiresHandle = obj.RequiresHandle
    elseif obj:IsA("LocalScript") or obj:IsA("Script") then
        result.Type = "Script"
        result.Enabled = obj.Enabled
    end
    
    -- Scan children
    for _, child in pairs(obj:GetChildren()) do
        table.insert(result.Children, DeepScan(child, depth + 1, maxDepth))
    end
    
    return result
end

-- Find fishing-related objects
local function FindFishingObjects()
    Log("SCAN", "Starting fishing objects scan...")
    
    local fishingKeywords = {
        "fish", "rod", "cast", "catch", "reel", "hook", "bait", "lure",
        "fishing", "tackle", "bite", "bobber", "line", "net", "sell"
    }
    
    local foundObjects = {}
    
    -- Scan ReplicatedStorage
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        local name = string.lower(obj.Name)
        for _, keyword in pairs(fishingKeywords) do
            if string.find(name, keyword) then
                table.insert(foundObjects, {
                    Object = obj,
                    FullName = obj:GetFullName(),
                    ClassName = obj.ClassName,
                    Keyword = keyword,
                    Location = "ReplicatedStorage"
                })
                break
            end
        end
    end
    
    -- Scan Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = string.lower(obj.Name)
        for _, keyword in pairs(fishingKeywords) do
            if string.find(name, keyword) then
                table.insert(foundObjects, {
                    Object = obj,
                    FullName = obj:GetFullName(),
                    ClassName = obj.ClassName,
                    Keyword = keyword,
                    Location = "Workspace"
                })
                break
            end
        end
    end
    
    -- Scan Player's Backpack and Character
    if LocalPlayer.Backpack then
        for _, obj in pairs(LocalPlayer.Backpack:GetDescendants()) do
            local name = string.lower(obj.Name)
            for _, keyword in pairs(fishingKeywords) do
                if string.find(name, keyword) then
                    table.insert(foundObjects, {
                        Object = obj,
                        FullName = obj:GetFullName(),
                        ClassName = obj.ClassName,
                        Keyword = keyword,
                        Location = "Backpack"
                    })
                    break
                end
            end
        end
    end
    
    if LocalPlayer.Character then
        for _, obj in pairs(LocalPlayer.Character:GetDescendants()) do
            local name = string.lower(obj.Name)
            for _, keyword in pairs(fishingKeywords) do
                if string.find(name, keyword) then
                    table.insert(foundObjects, {
                        Object = obj,
                        FullName = obj:GetFullName(),
                        ClassName = obj.ClassName,
                        Keyword = keyword,
                        Location = "Character"
                    })
                    break
                end
            end
        end
    end
    
    Log("SCAN", "Found " .. #foundObjects .. " fishing-related objects")
    return foundObjects
end

-- Find all RemoteEvents and RemoteFunctions
local function FindRemotes()
    Log("SCAN", "Scanning for RemoteEvents and RemoteFunctions...")
    
    local remotes = {}
    
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, {
                Object = obj,
                Name = obj.Name,
                FullName = obj:GetFullName(),
                Type = obj:IsA("RemoteEvent") and "RemoteEvent" or "RemoteFunction",
                Parent = obj.Parent.Name
            })
        end
    end
    
    Log("SCAN", "Found " .. #remotes .. " remotes")
    return remotes
end

-- Monitor remote calls
local RemoteCallLog = {}
local function MonitorRemotes()
    Log("MONITOR", "Starting remote monitoring...")
    
    local function hookRemote(remote)
        if remote:IsA("RemoteEvent") then
            local originalFire = remote.FireServer
            remote.FireServer = function(self, ...)
                local args = {...}
                local logEntry = {
                    Time = tick(),
                    Remote = remote:GetFullName(),
                    Type = "RemoteEvent",
                    Args = args
                }
                table.insert(RemoteCallLog, logEntry)
                Log("REMOTE", "FireServer: " .. remote.Name .. " with " .. #args .. " args")
                return originalFire(self, ...)
            end
        elseif remote:IsA("RemoteFunction") then
            local originalInvoke = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                local args = {...}
                local logEntry = {
                    Time = tick(),
                    Remote = remote:GetFullName(),
                    Type = "RemoteFunction",
                    Args = args
                }
                table.insert(RemoteCallLog, logEntry)
                Log("REMOTE", "InvokeServer: " .. remote.Name .. " with " .. #args .. " args")
                return originalInvoke(self, ...)
            end
        end
    end
    
    -- Hook existing remotes
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            hookRemote(remote)
        end
    end
    
    -- Hook new remotes
    ReplicatedStorage.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            hookRemote(obj)
            Log("MONITOR", "New remote detected: " .. obj:GetFullName())
        end
    end)
end

-- Analyze game structure
local function AnalyzeGameStructure()
    Log("ANALYZE", "Analyzing Fish It game structure...")
    
    local structure = {
        ReplicatedStorage = DeepScan(ReplicatedStorage, 0, 2),
        Workspace = {
            Name = "Workspace",
            Children = {}
        },
        PlayerData = {}
    }
    
    -- Scan important Workspace objects
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name ~= "Camera" and obj.Name ~= "Terrain" and not obj:IsA("Player") then
            table.insert(structure.Workspace.Children, {
                Name = obj.Name,
                ClassName = obj.ClassName,
                Position = obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Position or (obj:IsA("Part") and obj.Position or "N/A")
            })
        end
    end
    
    -- Player data
    if LocalPlayer.Character then
        structure.PlayerData.Character = DeepScan(LocalPlayer.Character, 0, 2)
    end
    if LocalPlayer.Backpack then
        structure.PlayerData.Backpack = DeepScan(LocalPlayer.Backpack, 0, 2)
    end
    if LocalPlayer.PlayerGui then
        structure.PlayerData.PlayerGui = DeepScan(LocalPlayer.PlayerGui, 0, 1)
    end
    
    return structure
end

-- Export functions
local function ExportDebugData()
    local data = {
        GameName = "Fish It",
        Timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        GameStructure = AnalyzeGameStructure(),
        FishingObjects = FindFishingObjects(),
        Remotes = FindRemotes(),
        RemoteCalls = RemoteCallLog,
        DebugLog = DebugLog
    }
    
    Log("EXPORT", "Debug data collected. Objects found: " .. #data.FishingObjects .. ", Remotes: " .. #data.Remotes)
    return data
end

-- Create Debug UI
local function CreateDebugUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Remove existing debug UI
    local existing = playerGui:FindFirstChild("FishItDebugUI")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishItDebugUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local panel = Instance.new("Frame")
    panel.Name = "DebugPanel"
    panel.Size = UDim2.new(0, 400, 0, 300)
    panel.Position = UDim2.new(0, 20, 0, 20)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    panel.BorderSizePixel = 0
    panel.Parent = screenGui
    Instance.new("UICorner", panel)
    
    -- Header
    local header = Instance.new("Frame", panel)
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    header.BorderSizePixel = 0
    Instance.new("UICorner", header)
    
    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Text = "Fish It Debug Tool"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 2.5)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", closeBtn)
    
    -- Content area
    local content = Instance.new("ScrollingFrame", panel)
    content.Size = UDim2.new(1, -10, 1, -80)
    content.Position = UDim2.new(0, 5, 0, 35)
    content.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 6
    Instance.new("UICorner", content)
    
    -- Buttons
    local buttonContainer = Instance.new("Frame", panel)
    buttonContainer.Size = UDim2.new(1, -10, 0, 40)
    buttonContainer.Position = UDim2.new(0, 5, 1, -45)
    buttonContainer.BackgroundTransparency = 1
    
    local function createButton(text, position, callback)
        local btn = Instance.new("TextButton", buttonContainer)
        btn.Size = UDim2.new(0.23, 0, 0, 30)
        btn.Position = UDim2.new(position * 0.25, 0, 0, 5)
        btn.Text = text
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 10
        btn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", btn)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Status display
    local statusLabel = Instance.new("TextLabel", content)
    statusLabel.Size = UDim2.new(1, -10, 0, 20)
    statusLabel.Position = UDim2.new(0, 5, 0, 5)
    statusLabel.Text = "Fish It Debug Tool Ready"
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextSize = 12
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Log display
    local logDisplay = Instance.new("TextLabel", content)
    logDisplay.Size = UDim2.new(1, -10, 1, -30)
    logDisplay.Position = UDim2.new(0, 5, 0, 25)
    logDisplay.Text = "Click buttons to start debugging..."
    logDisplay.Font = Enum.Font.SourceSans
    logDisplay.TextSize = 11
    logDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
    logDisplay.BackgroundTransparency = 1
    logDisplay.TextXAlignment = Enum.TextXAlignment.Left
    logDisplay.TextYAlignment = Enum.TextYAlignment.Top
    logDisplay.TextWrapped = true
    
    -- Update log display
    local function updateLogDisplay()
        local recentLogs = {}
        for i = math.max(1, #DebugLog - 20), #DebugLog do
            table.insert(recentLogs, DebugLog[i])
        end
        logDisplay.Text = table.concat(recentLogs, "\n")
        content.CanvasSize = UDim2.new(0, 0, 0, logDisplay.TextBounds.Y + 50)
    end
    
    -- Button callbacks
    createButton("Scan Fish", 0, function()
        statusLabel.Text = "Scanning for fishing objects..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
        
        task.spawn(function()
            local fishingObjects = FindFishingObjects()
            statusLabel.Text = "Found " .. #fishingObjects .. " fishing objects"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            updateLogDisplay()
        end)
    end)
    
    createButton("Find Remotes", 1, function()
        statusLabel.Text = "Scanning for remotes..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
        
        task.spawn(function()
            local remotes = FindRemotes()
            statusLabel.Text = "Found " .. #remotes .. " remotes"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            updateLogDisplay()
        end)
    end)
    
    createButton("Monitor", 2, function()
        statusLabel.Text = "Remote monitoring active"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        MonitorRemotes()
        updateLogDisplay()
    end)
    
    createButton("Export", 3, function()
        statusLabel.Text = "Exporting debug data..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
        
        task.spawn(function()
            local data = ExportDebugData()
            -- In a real implementation, this would save to file or copy to clipboard
            Log("EXPORT", "Data exported successfully!")
            statusLabel.Text = "Debug data exported"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            updateLogDisplay()
        end)
    end)
    
    -- Close button
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Auto-update log display
    task.spawn(function()
        while screenGui.Parent do
            updateLogDisplay()
            task.wait(2)
        end
    end)
    
    return screenGui
end

-- Initialize debug tool
local function Initialize()
    Log("INIT", "Fish It Debug Tool Initializing...")
    
    -- Check if we're in the right game
    local gameId = game.PlaceId
    Log("INIT", "Game Place ID: " .. gameId)
    
    -- Wait for game to load
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    -- Wait for LocalPlayer
    if not LocalPlayer then
        Players.PlayerAdded:Wait()
        LocalPlayer = Players.LocalPlayer
    end
    
    -- Wait for character
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    
    Log("INIT", "Game loaded, creating debug UI...")
    
    -- Create UI
    local ui = CreateDebugUI()
    
    -- Start basic monitoring
    MonitorRemotes()
    
    Log("INIT", "Fish It Debug Tool Ready!")
    Notify("Debug Tool", "Fish It Debug Tool Ready!")
    
    return ui
end

-- Auto-start
task.spawn(Initialize)

-- Global access
_G.FishItDebug = {
    Log = Log,
    Notify = Notify,
    FindFishingObjects = FindFishingObjects,
    FindRemotes = FindRemotes,
    MonitorRemotes = MonitorRemotes,
    AnalyzeGameStructure = AnalyzeGameStructure,
    ExportDebugData = ExportDebugData,
    CreateDebugUI = CreateDebugUI,
    Initialize = Initialize,
    DebugLog = DebugLog,
    RemoteCallLog = RemoteCallLog
}

print("=== FISH IT DEBUG TOOL LOADED ===")
print("Use _G.FishItDebug to access debug functions")
print("UI will appear automatically in Fish It game")
