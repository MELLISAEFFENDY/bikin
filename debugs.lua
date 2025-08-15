-- fishit_debug_simple.lua
-- Simplified Debug Tool untuk Fish It (Error-Free Version)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Simple logging
local function SafeLog(message)
    print("[FISH-IT-DEBUG] " .. tostring(message))
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Fish It Debug",
            Text = tostring(message),
            Duration = 3
        })
    end)
end

-- Safe remote finder
local function FindAllRemotes()
    SafeLog("Scanning for remotes...")
    local remotes = {}
    
    pcall(function()
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                table.insert(remotes, {
                    Name = obj.Name,
                    Type = obj:IsA("RemoteEvent") and "Event" or "Function",
                    Path = obj:GetFullName()
                })
            end
        end
    end)
    
    SafeLog("Found " .. #remotes .. " remotes")
    
    -- Print detailed list
    for i, remote in ipairs(remotes) do
        print(string.format("[%d] %s (%s): %s", i, remote.Name, remote.Type, remote.Path))
    end
    
    return remotes
end

-- Safe fishing object finder
local function FindFishingStuff()
    SafeLog("Scanning for fishing objects...")
    local fishingObjects = {}
    
    local keywords = {"fish", "rod", "cast", "catch", "reel", "hook", "bait", "lure", "tackle", "sell"}
    
    pcall(function()
        -- Scan ReplicatedStorage
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            local name = string.lower(obj.Name)
            for _, keyword in pairs(keywords) do
                if string.find(name, keyword) then
                    table.insert(fishingObjects, {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Path = obj:GetFullName(),
                        Location = "ReplicatedStorage"
                    })
                    break
                end
            end
        end
        
        -- Scan Workspace
        for _, obj in pairs(game.Workspace:GetDescendants()) do
            local name = string.lower(obj.Name)
            for _, keyword in pairs(keywords) do
                if string.find(name, keyword) then
                    table.insert(fishingObjects, {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Path = obj:GetFullName(),
                        Location = "Workspace"
                    })
                    break
                end
            end
        end
    end)
    
    SafeLog("Found " .. #fishingObjects .. " fishing objects")
    
    -- Print detailed list
    for i, obj in ipairs(fishingObjects) do
        print(string.format("[%d] %s (%s) in %s: %s", i, obj.Name, obj.Type, obj.Location, obj.Path))
    end
    
    return fishingObjects
end
local function ExportData()
    local remotes = FindAllRemotes()
    local fishingStuff = FindFishingStuff()
    
    local exportText = string.format([[
=== FISH IT SIMPLE DEBUG EXPORT ===
Game PlaceId: %s
Timestamp: %s
Found %d Remotes and %d Fishing Objects

=== REMOTES (%d total) ===
]], game.PlaceId, os.date("%Y-%m-%d %H:%M:%S"), #remotes, #fishingStuff, #remotes)
    
    for i, remote in ipairs(remotes) do
        exportText = exportText .. string.format("[%d] %s (%s): %s\n", i, remote.Name, remote.Type, remote.Path)
    end
    
    exportText = exportText .. string.format("\n=== FISHING OBJECTS (%d total) ===\n", #fishingStuff)
    for i, obj in ipairs(fishingStuff) do
        exportText = exportText .. string.format("[%d] %s (%s) in %s: %s\n", i, obj.Name, obj.Type, obj.Location, obj.Path)
    end
    
    -- Try to copy to clipboard
    local copied = false
    pcall(function()
        if setclipboard then
            setclipboard(exportText)
            copied = true
        elseif syn and syn.write_clipboard then
            syn.write_clipboard(exportText)
            copied = true
        end
    end)
    
    if copied then
        SafeLog("✅ Data copied to clipboard!")
    else
        SafeLog("📄 Data printed to console (clipboard not available)")
        print(exportText)
    end
    
    return exportText
end
    SafeLog("Scanning for fishing objects...")
    local fishingObjects = {}
    
    local keywords = {"fish", "rod", "cast", "catch", "reel", "hook", "bait", "lure", "tackle", "sell"}
    
    pcall(function()
        -- Scan ReplicatedStorage
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            local name = string.lower(obj.Name)
            for _, keyword in pairs(keywords) do
                if string.find(name, keyword) then
                    table.insert(fishingObjects, {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Path = obj:GetFullName(),
                        Location = "ReplicatedStorage"
                    })
                    break
                end
            end
        end
        
        -- Scan Workspace
        for _, obj in pairs(game.Workspace:GetDescendants()) do
            local name = string.lower(obj.Name)
            for _, keyword in pairs(keywords) do
                if string.find(name, keyword) then
                    table.insert(fishingObjects, {
                        Name = obj.Name,
                        Type = obj.ClassName,
                        Path = obj:GetFullName(),
                        Location = "Workspace"
                    })
                    break
                end
            end
        end
    end)
    
    SafeLog("Found " .. #fishingObjects .. " fishing objects")
    
    -- Print detailed list
    for i, obj in ipairs(fishingObjects) do
        print(string.format("[%d] %s (%s) in %s: %s", i, obj.Name, obj.Type, obj.Location, obj.Path))
    end
    
    return fishingObjects
end

-- Simple UI
local function CreateSimpleUI()
    pcall(function()
        -- Remove existing
        local existing = LocalPlayer.PlayerGui:FindFirstChild("SimpleFishDebug")
        if existing then existing:Destroy() end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SimpleFishDebug"
        screenGui.Parent = LocalPlayer.PlayerGui
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 240)
        frame.Position = UDim2.new(0, 20, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        frame.Parent = screenGui
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 30)
        title.Text = "Fish It Debug (Simple)"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        title.Font = Enum.Font.GothamBold
        title.Parent = frame
        
        -- Buttons
        local btn1 = Instance.new("TextButton")
        btn1.Size = UDim2.new(1, -10, 0, 30)
        btn1.Position = UDim2.new(0, 5, 0, 40)
        btn1.Text = "Find Remotes"
        btn1.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
        btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn1.Parent = frame
        
        local btn2 = Instance.new("TextButton")
        btn2.Size = UDim2.new(1, -10, 0, 30)
        btn2.Position = UDim2.new(0, 5, 0, 80)
        btn2.Text = "Find Fishing Objects"
        btn2.BackgroundColor3 = Color3.fromRGB(100, 200, 150)
        btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn2.Parent = frame
        
        local btn3 = Instance.new("TextButton")
        btn3.Size = UDim2.new(1, -10, 0, 30)
        btn3.Position = UDim2.new(0, 5, 0, 120)
        btn3.Text = "Game Info"
        btn3.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
        btn3.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn3.Parent = frame
        
        local btn4 = Instance.new("TextButton")
        btn4.Size = UDim2.new(1, -10, 0, 30)
        btn4.Position = UDim2.new(0, 5, 0, 160)
        btn4.Text = "Export Data"
        btn4.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
        btn4.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn4.Parent = frame
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(1, -10, 0, 30)
        closeBtn.Position = UDim2.new(0, 5, 0, 200)
        closeBtn.Text = "Close"
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Parent = frame
        
        -- Button functions
        btn1.MouseButton1Click:Connect(function()
            task.spawn(FindAllRemotes)
        end)
        
        btn2.MouseButton1Click:Connect(function()
            task.spawn(FindFishingStuff)
        end)
        
        btn3.MouseButton1Click:Connect(function()
            SafeLog("Game PlaceId: " .. game.PlaceId)
            SafeLog("Game Name: " .. (game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"))
            if LocalPlayer.Character then
                SafeLog("Character Position: " .. tostring(LocalPlayer.Character.HumanoidRootPart.Position))
            end
        end)
        
        btn4.MouseButton1Click:Connect(function()
            task.spawn(ExportData)
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            screenGui:Destroy()
        end)
        
        SafeLog("Simple UI Created!")
    end)
end

-- Initialize
task.spawn(function()
    task.wait(2) -- Wait for game to load
    
    SafeLog("Fish It Simple Debug Tool Starting...")
    
    -- Create UI
    CreateSimpleUI()
    
    -- Initial scan
    task.spawn(FindAllRemotes)
    task.spawn(FindFishingStuff)
    
    SafeLog("Debug tool ready! Check console for details.")
end)

-- Global access
_G.FishItSimpleDebug = {
    FindRemotes = FindAllRemotes,
    FindFishing = FindFishingStuff,
    CreateUI = CreateSimpleUI,
    Log = SafeLog
}

print("=== FISH IT SIMPLE DEBUG LOADED ===")
print("UI will appear in 2 seconds")
print("Check console output for detailed info")
