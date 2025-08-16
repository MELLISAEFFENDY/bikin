-- Fish It Debug Tool (Simple & Safe Version)
-- Fixed version with proper error handling

local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Safe logging
local function SafeLog(message)
    pcall(function()
        print("[Fish It Debug] " .. tostring(message))
        StarterGui:SetCore("SendNotification", {
            Title = "Fish It Debug",
            Text = tostring(message),
            Duration = 3
        })
    end)
end

-- Safe string formatting function
local function SafeFormat(template, ...)
    local args = {...}
    for i, arg in ipairs(args) do
        args[i] = tostring(arg or "Unknown")
    end
    return string.format(template, unpack(args))
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
    
    -- Print detailed list with safe formatting
    for i, remote in ipairs(remotes) do
        print(SafeFormat("[%d] %s (%s): %s", i, remote.Name, remote.Type, remote.Path))
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
            local name = string.lower(obj.Name or "")
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
            local name = string.lower(obj.Name or "")
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
    
    -- Print detailed list with safe formatting
    for i, obj in ipairs(fishingObjects) do
        print(SafeFormat("[%d] %s (%s) in %s: %s", i, obj.Name, obj.Type, obj.Location, obj.Path))
    end
    
    return fishingObjects
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

local function ExportData()
    local remotes = FindAllRemotes()
    local fishingStuff = FindFishingStuff()
    
    -- Limit data for clipboard compatibility
    local maxRemotes = math.min(#remotes, 30)
    local maxFishing = math.min(#fishingStuff, 20)
    
    local exportText = SafeFormat([[
=== FISH IT SIMPLE DEBUG EXPORT ===
Game PlaceId: %s
Timestamp: %s
Found %d Remotes and %d Fishing Objects

=== TOP REMOTES ===
]], game.PlaceId, os.date("%Y-%m-%d %H:%M:%S"), #remotes, #fishingStuff)
    
    for i = 1, maxRemotes do
        local remote = remotes[i]
        if remote then
            exportText = exportText .. SafeFormat("[%d] %s (%s)\n", i, remote.Name, remote.Type)
        end
    end
    
    exportText = exportText .. "\n=== TOP FISHING OBJECTS ===\n"
    
    for i = 1, maxFishing do
        local obj = fishingStuff[i]
        if obj then
            exportText = exportText .. SafeFormat("[%d] %s (%s) in %s\n", i, obj.Name, obj.Type, obj.Location)
        end
    end
    
    exportText = exportText .. "\n=== SUMMARY ===\n"
    exportText = exportText .. SafeFormat("Total Items Found: %d\n", #remotes + #fishingStuff)
    exportText = exportText .. "Status: Ready for AutoFish development\n"
    
    -- Enhanced clipboard copy with multiple attempts
    local copied = false
    local attempts = 0
    
    while not copied and attempts < 3 do
        attempts = attempts + 1
        pcall(function()
            if setclipboard then
                setclipboard(exportText)
                copied = true
            elseif syn and syn.write_clipboard then
                syn.write_clipboard(exportText)
                copied = true
            elseif Clipboard and Clipboard.set then
                Clipboard.set(exportText)
                copied = true
            end
        end)
        
        if not copied then
            wait(0.1) -- Small delay before retry
        end
    end
    
    if copied then
        SafeLog("✅ Data copied to clipboard successfully! (Attempt " .. attempts .. ")")
    else
        SafeLog("📄 Clipboard failed after 3 attempts. Data printed to console:")
        print("\n" .. exportText)
    end
    
    -- Save to file untuk data lengkap
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = "FishIt_Debug_" .. timestamp .. ".txt"
    
    -- Buat data lengkap untuk file (tidak dibatasi seperti clipboard)
    local fullData = SafeFormat([[
=== FISH IT COMPLETE DEBUG DATA ===
Game PlaceId: %s
Export Time: %s
Total Remotes Found: %d
Total Fishing Objects Found: %d

=== COMPLETE REMOTES LIST ===
]], game.PlaceId, os.date("%Y-%m-%d %H:%M:%S"), #remotes, #fishingStuff)
    
    -- Tambahkan semua remotes (tidak dibatasi)
    for i, remote in ipairs(remotes) do
        fullData = fullData .. SafeFormat("[%d] %s (%s): %s\n", i, remote.Name, remote.Type, remote.Path)
    end
    
    fullData = fullData .. "\n=== COMPLETE FISHING OBJECTS LIST ===\n"
    
    -- Tambahkan semua fishing objects (tidak dibatasi)
    for i, obj in ipairs(fishingStuff) do
        fullData = fullData .. SafeFormat("[%d] %s (%s) in %s: %s\n", i, obj.Name, obj.Type, obj.Location, obj.Path)
    end
    
    fullData = fullData .. "\n=== ANALYSIS SUMMARY ===\n"
    fullData = fullData .. "Most Common Remote Types: RemoteEvent, RemoteFunction\n"
    fullData = fullData .. "Key Fishing Keywords Found: Fish, Rod, Bait, Cast, Catch\n"
    fullData = fullData .. "Recommended Next Steps: Analyze top remotes for AutoFish integration\n"
    fullData = fullData .. SafeFormat("File Generated: %s\n", filename)
    
    -- Coba save ke file
    local saved, filePath = SaveToFile(fullData, filename)
    
    if saved then
        SafeLog("💾 Complete data saved to file: " .. filePath)
        SafeLog("📱 Check your Downloads or Documents folder!")
    else
        SafeLog("❌ Failed to save file. Try running as administrator or check permissions.")
    end
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
        frame.Size = UDim2.new(0, 300, 0, 280)
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
        
        local btn5 = Instance.new("TextButton")
        btn5.Size = UDim2.new(1, -10, 0, 30)
        btn5.Position = UDim2.new(0, 5, 0, 200)
        btn5.Text = "Save to File"
        btn5.BackgroundColor3 = Color3.fromRGB(200, 100, 150)
        btn5.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn5.Parent = frame
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(1, -10, 0, 30)
        closeBtn.Position = UDim2.new(0, 5, 0, 240)
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
            local success, gameName = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
            end)
            SafeLog("Game Name: " .. (success and gameName or "Unknown"))
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                SafeLog("Character Position: " .. tostring(LocalPlayer.Character.HumanoidRootPart.Position))
            end
        end)
        
        btn4.MouseButton1Click:Connect(function()
            task.spawn(ExportData)
        end)
        
        btn5.MouseButton1Click:Connect(function()
            task.spawn(function()
                local remotes = FindAllRemotes()
                local fishingStuff = FindFishingStuff()
                local timestamp = os.date("%Y%m%d_%H%M%S")
                local filename = "FishIt_Simple_Debug_" .. timestamp .. ".txt"
                
                local fullData = SafeFormat([[
=== FISH IT SIMPLE DEBUG FILE EXPORT ===
Game PlaceId: %s
Export Time: %s
Found %d Remotes and %d Fishing Objects

=== COMPLETE REMOTES LIST ===
]], game.PlaceId, os.date("%Y-%m-%d %H:%M:%S"), #remotes, #fishingStuff)
                
                for i, remote in ipairs(remotes) do
                    fullData = fullData .. SafeFormat("[%d] %s (%s): %s\n", i, remote.Name, remote.Type, remote.Path)
                end
                
                fullData = fullData .. "\n=== COMPLETE FISHING OBJECTS LIST ===\n"
                for i, obj in ipairs(fishingStuff) do
                    fullData = fullData .. SafeFormat("[%d] %s (%s) in %s: %s\n", i, obj.Name, obj.Type, obj.Location, obj.Path)
                end
                
                fullData = fullData .. "\n=== FILE EXPORT NOTES ===\n"
                fullData = fullData .. "This file contains complete debug data from Fish It game\n"
                fullData = fullData .. "All remotes and fishing objects are listed without limitations\n"
                fullData = fullData .. "Use this data to develop AutoFish compatibility\n"
                fullData = fullData .. "Generated by Fish It Simple Debug Tool\n"
                
                local saved, filePath = SaveToFile(fullData, filename)
                
                if saved then
                    SafeLog("💾 Complete data saved to: " .. filePath)
                    SafeLog("📱 Check your Downloads or Documents folder!")
                else
                    SafeLog("❌ File save failed. Check executor permissions.")
                end
            end)
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            screenGui:Destroy()
        end)
        
        SafeLog("Fish It Debug Tool loaded! UI created.")
    end)
end

-- Start the tool
CreateSimpleUI()
SafeLog("Fish It Simple Debug Tool Ready! 🎣")
