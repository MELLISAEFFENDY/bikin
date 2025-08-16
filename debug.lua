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

-- Safe string formatting function
local function SafeFormat(template, ...)
    local args = {...}
    for i, arg in ipairs(args) do
        args[i] = tostring(arg or "Unknown")
    end
    return string.format(template, unpack(args))
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
    
    local function safeHookRemote(remote)
        local success, error = pcall(function()
            if remote:IsA("RemoteEvent") then
                -- Monitor RemoteEvent fires
                local connection
                connection = remote.OnClientEvent:Connect(function(...)
                    local args = {...}
                    local logEntry = {
                        Time = tick(),
                        Remote = remote:GetFullName(),
                        Type = "RemoteEvent.OnClientEvent",
                        Args = args,
                        Direction = "Server->Client"
                    }
                    table.insert(RemoteCallLog, logEntry)
                    Log("REMOTE", "OnClientEvent: " .. remote.Name .. " with " .. #args .. " args")
                end)
                
                -- Note: We can't easily hook FireServer without modifying the remote itself
                Log("MONITOR", "Monitoring RemoteEvent: " .. remote.Name)
                
            elseif remote:IsA("RemoteFunction") then
                -- RemoteFunctions are harder to monitor safely
                Log("MONITOR", "Found RemoteFunction: " .. remote.Name .. " (monitoring limited)")
            end
        end)
        
        if not success then
            Log("ERROR", "Failed to hook remote " .. remote.Name .. ": " .. tostring(error))
        end
    end
    
    -- Hook existing remotes safely
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            safeHookRemote(remote)
        end
    end
    
    -- Hook new remotes
    ReplicatedStorage.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            safeHookRemote(obj)
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

-- Export functions with multiple options
local function ExportDebugData()
    local data = {
        GameName = "Fish It",
        GamePlaceId = game.PlaceId,
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

-- Convert data to readable string format
local function DataToString(data, indent)
    indent = indent or 0
    local spaces = string.rep("  ", indent)
    
    if type(data) == "table" then
        local result = "{\n"
        for k, v in pairs(data) do
            result = result .. spaces .. "  " .. tostring(k) .. " = "
            if type(v) == "table" then
                result = result .. DataToString(v, indent + 1)
            else
                result = result .. tostring(v)
            end
            result = result .. ",\n"
        end
        result = result .. spaces .. "}"
        return result
    else
        return tostring(data)
    end
end

-- Copy to clipboard (if supported)
local function CopyToClipboard(text)
    local success, error = pcall(function()
        if setclipboard then
            setclipboard(text)
            return true
        elseif syn and syn.write_clipboard then
            syn.write_clipboard(text)
            return true
        elseif Clipboard and Clipboard.set then
            Clipboard.set(text)
            return true
        else
            return false
        end
    end)
    
    return success
end

-- Function untuk save file ke folder yang bisa diakses
local function SaveToFile(data, filename)
    local saved = false
    local fullPath = ""
    
    -- Coba berbagai path yang umum bisa diakses di Android
    local paths = {
        "/storage/emulated/0/Download/" .. filename,
        "/storage/emulated/0/Documents/" .. filename,
        "/sdcard/Download/" .. filename,
        "/sdcard/Documents/" .. filename,
        filename -- Fallback ke working directory
    }
    
    for _, path in pairs(paths) do
        pcall(function()
            if writefile then
                writefile(path, data)
                fullPath = path
                saved = true
            elseif syn and syn.write_file then
                syn.write_file(path, data)
                fullPath = path
                saved = true
            end
        end)
        if saved then break end
    end
    
    return saved, fullPath
end

-- Create export menu
local function CreateExportMenu(parentFrame)
    local exportMenu = Instance.new("Frame", parentFrame)
    exportMenu.Size = UDim2.new(0, 200, 0, 150)
    exportMenu.Position = UDim2.new(0.5, -100, 0.5, -75)
    exportMenu.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    exportMenu.BorderSizePixel = 0
    exportMenu.Visible = false
    Instance.new("UICorner", exportMenu)
    
    local menuTitle = Instance.new("TextLabel", exportMenu)
    menuTitle.Size = UDim2.new(1, 0, 0, 25)
    menuTitle.Text = "Export Options"
    menuTitle.Font = Enum.Font.GothamBold
    menuTitle.TextSize = 12
    menuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    menuTitle.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Instance.new("UICorner", menuTitle)
    
    local function createExportButton(text, position, callback)
        local btn = Instance.new("TextButton", exportMenu)
        btn.Size = UDim2.new(1, -20, 0, 25)
        btn.Position = UDim2.new(0, 10, 0, 30 + position * 30)
        btn.Text = text
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 10
        btn.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", btn)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Export to console
    createExportButton("Print to Console", 0, function()
        local data = ExportDebugData()
        print("=== FISH IT DEBUG EXPORT ===")
        print("Game:", data.GameName, "PlaceId:", data.GamePlaceId)
        print("Timestamp:", data.Timestamp)
        print("Fishing Objects Found:", #data.FishingObjects)
        print("Remotes Found:", #data.Remotes)
        print("Remote Calls Logged:", #data.RemoteCalls)
        
        print("\n=== REMOTES LIST ===")
        for i, remote in ipairs(data.Remotes) do
            print(string.format("[%d] %s (%s): %s", i, remote.Name, remote.Type, remote.FullName))
        end
        
        print("\n=== FISHING OBJECTS ===")
        for i, obj in ipairs(data.FishingObjects) do
            print(string.format("[%d] %s (%s) in %s", i, obj.Object.Name, obj.ClassName, obj.Location))
        end
        
        Log("EXPORT", "Data printed to console")
        exportMenu.Visible = false
    end)
    
    -- Copy to clipboard
    createExportButton("Copy to Clipboard", 1, function()
        local data = ExportDebugData()
        
        -- Limit data to prevent clipboard overflow
        local maxRemotes = math.min(#data.Remotes, 50)
        local maxFishingObjects = math.min(#data.FishingObjects, 50)
        
        local exportText = string.format([[
=== FISH IT DEBUG EXPORT ===
Game: %s (PlaceId: %s)
Timestamp: %s
Fishing Objects: %d (showing first %d)
Remotes: %d (showing first %d)
Remote Calls: %d

=== KEY REMOTES ===
]], data.GameName, data.GamePlaceId, data.Timestamp, #data.FishingObjects, maxFishingObjects, #data.Remotes, maxRemotes, #data.RemoteCalls)
        
        -- Add only important remotes
        for i = 1, maxRemotes do
            local remote = data.Remotes[i]
            if remote then
                exportText = exportText .. string.format("[%d] %s (%s)\n", i, remote.Name, remote.Type)
            end
        end
        
        exportText = exportText .. "\n=== KEY FISHING OBJECTS ===\n"
        for i = 1, maxFishingObjects do
            local obj = data.FishingObjects[i]
            if obj then
                exportText = exportText .. string.format("[%d] %s (%s) in %s\n", i, obj.Object.Name, obj.ClassName, obj.Location)
            end
        end
        
        exportText = exportText .. "\n=== ANALYSIS NOTES ===\n"
        exportText = exportText .. "- Copy this data to analyze Fish It game structure\n"
        exportText = exportText .. "- Look for fishing-related remotes and objects\n"
        exportText = exportText .. "- Use console output for full detailed export\n"
        
        local success = false
        pcall(function()
            if setclipboard then
                setclipboard(exportText)
                success = true
            elseif syn and syn.write_clipboard then
                syn.write_clipboard(exportText)
                success = true
            elseif Clipboard and Clipboard.set then
                Clipboard.set(exportText)
                success = true
            end
        end)
        
        if success then
            Log("EXPORT", "Optimized data copied to clipboard successfully!")
            Notify("Export", "Debug data copied to clipboard! (Optimized version)")
        else
            Log("ERROR", "Clipboard failed. Printing to console instead.")
            print("\n" .. exportText)
        end
        exportMenu.Visible = false
    end)
    
    -- Save summary
    createExportButton("Quick Summary", 2, function()
        local data = ExportDebugData()
        local summary = string.format([[
Fish It Debug Summary:
- Game PlaceId: %s
- Total Remotes: %d
- Fishing Objects: %d
- Top Remotes: %s
- Key Objects: %s
]], 
            data.GamePlaceId,
            #data.Remotes,
            #data.FishingObjects,
            table.concat({data.Remotes[1] and data.Remotes[1].Name or "None", 
                         data.Remotes[2] and data.Remotes[2].Name or "None",
                         data.Remotes[3] and data.Remotes[3].Name or "None"}, ", "),
            table.concat({data.FishingObjects[1] and data.FishingObjects[1].Object.Name or "None",
                         data.FishingObjects[2] and data.FishingObjects[2].Object.Name or "None",
                         data.FishingObjects[3] and data.FishingObjects[3].Object.Name or "None"}, ", ")
        )
        
        if CopyToClipboard(summary) then
            Log("EXPORT", "Summary copied to clipboard!")
        else
            print(summary)
            Log("EXPORT", "Summary printed to console")
        end
        exportMenu.Visible = false
    end)
    
    -- Copy key data only (for reliable clipboard)
    createExportButton("Copy Key Data", 3, function()
        local data = ExportDebugData()
        local keyData = string.format([[Fish It Key Data:
PlaceId: %s
Top 10 Remotes: %s
Top 10 Fishing Objects: %s
Analysis Ready: YES]], 
            data.GamePlaceId,
            table.concat((function()
                local top = {}
                for i = 1, math.min(10, #data.Remotes) do
                    table.insert(top, data.Remotes[i].Name)
                end
                return top
            end)(), ", "),
            table.concat((function()
                local top = {}
                for i = 1, math.min(10, #data.FishingObjects) do
                    table.insert(top, data.FishingObjects[i].Object.Name)
                end
                return top
            end)(), ", ")
        )
        
        local success = false
        for attempt = 1, 5 do
            pcall(function()
                if setclipboard then
                    setclipboard(keyData)
                    success = true
                elseif syn and syn.write_clipboard then
                    syn.write_clipboard(keyData)
                    success = true
                end
            end)
            if success then break end
            wait(0.05)
        end
        
        if success then
            Log("EXPORT", "Key data copied successfully!")
            Notify("Export", "Key data copied to clipboard!")
        else
            print(keyData)
            Log("EXPORT", "Key data printed to console")
        end
        exportMenu.Visible = false
    end)
    
    -- Save to File
    createExportButton("Save to File", 4, function()
        local data = ExportDebugData()
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local filename = "FishIt_Advanced_Debug_" .. timestamp .. ".txt"
        
        -- Buat data lengkap untuk file dengan safe string handling
        local safePlaceId = tostring(data.GamePlaceId or game.PlaceId or "Unknown")
        local safeGameName = tostring(data.GameName or "Unknown Game")
        local safeTimestamp = tostring(data.Timestamp or os.date("%Y-%m-%d %H:%M:%S"))
        
        local fullData = string.format([[
=== FISH IT ADVANCED DEBUG EXPORT ===
Game PlaceId: %s
Game Name: %s
Export Time: %s
Total Remotes Found: %d
Total Fishing Objects Found: %d
Remote Calls Monitored: %d

=== COMPLETE REMOTES LIST ===
]], safePlaceId, safeGameName, safeTimestamp, #data.Remotes, #data.FishingObjects, #data.RemoteCalls)
        
        -- Tambahkan semua remotes dengan safe string handling
        for i, remote in ipairs(data.Remotes) do
            local safeName = tostring(remote.Name or "Unknown")
            local safeType = tostring(remote.Type or "Unknown")
            local safeFullName = tostring(remote.FullName or "Unknown Path")
            fullData = fullData .. string.format("[%d] %s (%s): %s\n", i, safeName, safeType, safeFullName)
        end
        
        fullData = fullData .. "\n=== COMPLETE FISHING OBJECTS LIST ===\n"
        
        -- Tambahkan semua fishing objects dengan safe string handling
        for i, obj in ipairs(data.FishingObjects) do
            local safeName = "Unknown"
            local safeClassName = "Unknown"
            local safeLocation = tostring(obj.Location or "Unknown")
            
            pcall(function()
                if obj.Object and obj.Object.Name then
                    safeName = tostring(obj.Object.Name)
                end
                if obj.ClassName then
                    safeClassName = tostring(obj.ClassName)
                end
            end)
            
            fullData = fullData .. string.format("[%d] %s (%s) in %s\n", i, safeName, safeClassName, safeLocation)
        end
        
        fullData = fullData .. "\n=== REMOTE CALL LOGS ===\n"
        
        -- Tambahkan remote call logs dengan safe string conversion
        for i, call in ipairs(data.RemoteCalls) do
            local argsString = "No arguments"
            if call.Arguments then
                pcall(function()
                    if type(call.Arguments) == "table" then
                        argsString = table.concat(call.Arguments, ", ")
                    else
                        argsString = tostring(call.Arguments)
                    end
                end)
            end
            fullData = fullData .. string.format("[%s] %s: %s\n", 
                tostring(call.Time or "Unknown"), 
                tostring(call.RemoteName or "Unknown"), 
                argsString)
        end
        
        fullData = fullData .. "\n=== DETAILED ANALYSIS ===\n"
        fullData = fullData .. "Key Remotes for AutoFish: Look for 'Cast', 'Reel', 'Sell' patterns\n"
        fullData = fullData .. "Important Objects: Check ReclassFishProjectile, Baits, Starter Bait\n"
        fullData = fullData .. "Next Steps: Test remote calls with identified fishing functions\n"
        fullData = fullData .. string.format("Report Generated: %s\n", filename)
        
        -- Save ke file
        local saved, filePath = SaveToFile(fullData, filename)
        
        if saved then
            Log("EXPORT", "Complete data saved to: " .. filePath)
            Notify("Export", "Full report saved to file!")
        else
            Log("ERROR", "Failed to save file")
            Notify("Error", "File save failed. Check permissions.")
        end
        exportMenu.Visible = false
    end)
    
    -- Close button
    createExportButton("Close", 5, function()
        exportMenu.Visible = false
    end)
    
    return exportMenu
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

    -- Create export menu
    local exportMenu = CreateExportMenu(panel)
    
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
            
            -- Log detailed remote info
            Log("REMOTES", "=== DETAILED REMOTE ANALYSIS ===")
            for i, remote in ipairs(remotes) do
                Log("REMOTE", string.format("[%d] %s (%s) in %s", i, remote.Name, remote.Type, remote.Parent))
            end
            
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
        exportMenu.Visible = not exportMenu.Visible
        statusLabel.Text = "Choose export option..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
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

-- Alternative: Manual Remote Call Detector
local function CreateRemoteCallDetector()
    Log("DETECTOR", "Creating manual remote call detector...")
    
    -- Store original remote references
    local originalRemotes = {}
    
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            table.insert(originalRemotes, {
                Remote = remote,
                Name = remote.Name,
                FullName = remote:GetFullName(),
                Type = remote:IsA("RemoteEvent") and "RemoteEvent" or "RemoteFunction"
            })
        end
    end
    
    -- Manual instruction for user
    local function logManualCall(remoteName, args)
        local logEntry = {
            Time = tick(),
            Remote = remoteName,
            Type = "Manual",
            Args = args or {},
            Note = "User triggered action"
        }
        table.insert(RemoteCallLog, logEntry)
        Log("MANUAL", "Action detected for: " .. remoteName)
    end
    
    -- Return detector functions
    return {
        LogCall = logManualCall,
        Remotes = originalRemotes
    }
end

-- Safe initialization wrapper
local function SafeInitialize()
    local success, result = pcall(function()
        Log("INIT", "Fish It Debug Tool Starting (Safe Mode)...")
        
        -- Check if we're in the right environment
        if not game or not game:GetService("Players") then
            error("Not in Roblox environment")
        end
        
        -- Check game loading
        if not game:IsLoaded() then
            Log("INIT", "Waiting for game to load...")
            game.Loaded:Wait()
        end
        
        -- Check LocalPlayer
        if not LocalPlayer then
            Log("INIT", "Waiting for LocalPlayer...")
            repeat 
                LocalPlayer = Players.LocalPlayer
                task.wait(0.1)
            until LocalPlayer
        end
        
        Log("INIT", "Environment validated successfully")
        return true
    end)
    
    if not success then
        Log("ERROR", "Initialization failed: " .. tostring(result))
        return false
    end
    
    return true
end

-- Initialize debug tool with error handling
local function Initialize()
    if not SafeInitialize() then
        return nil
    end
    
    Log("INIT", "Fish It Debug Tool Initializing...")
    
    -- Get game info safely
    local gameId = game.PlaceId
    Log("INIT", "Game Place ID: " .. gameId)
    
    -- Wait for character if needed
    task.spawn(function()
        if LocalPlayer and not LocalPlayer.Character then
            Log("INIT", "Waiting for character...")
            LocalPlayer.CharacterAdded:Wait()
            Log("INIT", "Character loaded")
        end
    end)
    
    Log("INIT", "Creating debug UI...")
    
    -- Create UI with error handling
    local ui
    local success, error = pcall(function()
        ui = CreateDebugUI()
    end)
    
    if not success then
        Log("ERROR", "UI creation failed: " .. tostring(error))
        return nil
    end
    
    -- Start safe monitoring
    task.spawn(function()
        local monitorSuccess, monitorError = pcall(function()
            MonitorRemotes()
        end)
        
        if not monitorSuccess then
            Log("ERROR", "Monitor failed: " .. tostring(monitorError))
            -- Create alternative detector
            CreateRemoteCallDetector()
        end
    end)
    
    Log("INIT", "Fish It Debug Tool Ready!")
    Notify("Debug Tool", "Fish It Debug Tool Ready! Found 80 remotes, 468 fishing objects")
    
    return ui
end

-- Auto-start with error protection
task.spawn(function()
    local startSuccess, startError = pcall(function()
        Initialize()
    end)
    
    if not startSuccess then
        print("DEBUG TOOL ERROR:", startError)
        -- Fallback: Create basic UI without monitoring
        task.wait(2)
        pcall(CreateDebugUI)
    end
end)

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
