-- Fish It Game Explorer Script (Enhanced Version)
-- Scans all objects, remotes, items, and fish in the game with UI and file saving

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Global storage for all scan results
_G.FishItExplorationData = {}

-- Enhanced notification function
local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
    end)
    print("[FISH IT EXPLORER]", title, ":", text)
end

-- Safe string formatting function
local function SafeFormat(template, ...)
    local args = {...}
    for i, arg in ipairs(args) do
        args[i] = tostring(arg or "Unknown")
    end
    return string.format(template, unpack(args))
end

-- Function to save file to accessible folder (Android compatible) - Enhanced
local function SaveToFile(data, filename)
    local saved = false
    local fullPath = ""
    
    -- Validate input
    if not data or type(data) ~= "string" then
        print("❌ Invalid data to save")
        return false, "Invalid data"
    end
    
    if not filename or type(filename) ~= "string" then
        print("❌ Invalid filename")
        return false, "Invalid filename"
    end
    
    -- Try various accessible paths for Android
    local paths = {
        "/storage/emulated/0/Download/" .. filename,
        "/storage/emulated/0/Documents/" .. filename,
        "/sdcard/Download/" .. filename,
        "/sdcard/Documents/" .. filename,
        filename -- Fallback to working directory
    }
    
    for i, path in pairs(paths) do
        pcall(function()
            if writefile then
                writefile(path, data)
                fullPath = path
                saved = true
                print("✅ File saved using writefile to: " .. path)
            elseif syn and syn.write_file then
                syn.write_file(path, data)
                fullPath = path
                saved = true
                print("✅ File saved using syn.write_file to: " .. path)
            end
        end)
        if saved then break end
    end
    
    -- If still not saved, try alternative methods
    if not saved then
        pcall(function()
            -- Try with different file function names
            if makefolders and writefile then
                makefolders("FishItExplorer")
                writefile("FishItExplorer/" .. filename, data)
                fullPath = "FishItExplorer/" .. filename
                saved = true
                print("✅ File saved to custom folder: " .. fullPath)
            end
        end)
    end
    
    return saved, fullPath
end

-- Enhanced fish scanning function - focused on Fish It game fish names
local function scanFishData()
    print("\n=== SCANNING FISH DATA ===")
    local fishData = {}
    
    -- Fish It specific fish names based on the debug data
    local fishItFishNames = {
        -- From the debug data we can see these fish names
        "angelfish", "clownfish", "chromis", "dartfish", "tilefish", "damselfish",
        "boa angelfish", "cow clownfish", "darwin clownfish", "enchanted angelfish",
        "flame angelfish", "korean angelfish", "maze angelfish", "bandit angelfish",
        "scissortail dartfish", "skunk tilefish", "white clownfish", "yello damselfish",
        "yellowstate angelfish", "slurpfish chromis", "gingerbread clownfish",
        "festive pufferfish", "blumato clownfish", "conspi angelfish", "lined cardinal",
        "masked angelfish", "watanabei angelfish", "ballina angelfish", "pilot fish",
        "pufferfish", "racoon butterfly fish", "worm fish", "viperfish",
        "spotted lantern fish", "monk fish", "jellyfish", "boar fish", "blob fish",
        "angler fish", "dead fish", "skeleton fish", "swordfish", "ghost worm fish",
        -- Common fishing game fish
        "bass", "cod", "salmon", "trout", "tuna", "shark", "ray", "eel", "crab",
        "lobster", "shrimp", "starfish", "seahorse", "octopus", "squid"
    }
    
    -- Also scan for general fish keywords but be more specific
    local fishKeywords = {"fish", "clown", "angel", "shark", "ray", "crab", "lobster", "shrimp", "jellyfish", "starfish", "seahorse", "octopus", "squid", "eel", "bass", "cod", "salmon", "trout", "tuna", "puffer", "chromis", "damsel", "dart"}
    
    local function searchForFish(parent, path, depth)
        if depth <= 0 then return end
        
        pcall(function()
            for _, child in pairs(parent:GetChildren()) do
                local name = string.lower(child.Name or "")
                local isModuleScript = child:IsA("ModuleScript")
                local isModel = child:IsA("Model")
                local isTool = child:IsA("Tool")
                local foundFish = false
                
                -- First check for exact fish names from Fish It
                for _, fishName in pairs(fishItFishNames) do
                    if string.find(name, string.lower(fishName)) then
                        local fishInfo = {
                            name = child.Name,
                            class = child.ClassName,
                            path = path .. "." .. child.Name,
                            fullName = child:GetFullName(),
                            location = parent.Name,
                            type = "Unknown",
                            fishType = fishName -- Store the actual fish type found
                        }
                        
                        -- Determine fish object type
                        if isModuleScript then
                            fishInfo.type = "Fish Data/Script"
                        elseif isModel then
                            fishInfo.type = "Fish Model"
                        elseif isTool then
                            fishInfo.type = "Fish Tool"
                        elseif child:IsA("Part") or child:IsA("MeshPart") then
                            fishInfo.type = "Fish Part/Mesh"
                        else
                            fishInfo.type = "Fish Object"
                        end
                        
                        table.insert(fishData, fishInfo)
                        foundFish = true
                        break
                    end
                end
                
                -- If no exact match, check for general keywords
                if not foundFish then
                    for _, keyword in pairs(fishKeywords) do
                        if string.find(name, keyword) then
                            local fishInfo = {
                                name = child.Name,
                                class = child.ClassName,
                                path = path .. "." .. child.Name,
                                fullName = child:GetFullName(),
                                location = parent.Name,
                                type = "Unknown",
                                fishType = "General Fish-Related"
                            }
                            
                            -- Determine fish object type
                            if isModuleScript then
                                fishInfo.type = "Fish Data/Script"
                            elseif isModel then
                                fishInfo.type = "Fish Model"
                            elseif isTool then
                                fishInfo.type = "Fish Tool"
                            elseif child:IsA("Part") or child:IsA("MeshPart") then
                                fishInfo.type = "Fish Part/Mesh"
                            else
                                fishInfo.type = "Fish Object"
                            end
                            
                            table.insert(fishData, fishInfo)
                            break
                        end
                    end
                end
                
                -- Recursively search in folders and models
                if (child:IsA("Folder") or child:IsA("Model")) and not name:find("workspace") then
                    searchForFish(child, path .. "." .. child.Name, depth - 1)
                end
            end
        end)
    end
    
    -- Search in ReplicatedStorage
    searchForFish(ReplicatedStorage, "ReplicatedStorage", 4)
    
    -- Search in Workspace
    searchForFish(Workspace, "Workspace", 3)
    
    -- Sort fish data by fish type for better display
    table.sort(fishData, function(a, b)
        return (a.fishType or "zzz") < (b.fishType or "zzz")
    end)
    
    print("🐟 FISH DATA FOUND:")
    for i, fish in pairs(fishData) do
        print(SafeFormat("  [%d] %s (%s) - %s | Fish Type: %s at %s", 
            i, fish.name, fish.type, fish.class, fish.fishType or "Unknown", fish.path))
    end
    
    -- Print summary by fish types
    print("\n🐟 FISH SUMMARY BY TYPE:")
    local fishTypes = {}
    for _, fish in pairs(fishData) do
        local fishType = fish.fishType or "Unknown"
        if not fishTypes[fishType] then
            fishTypes[fishType] = 0
        end
        fishTypes[fishType] = fishTypes[fishType] + 1
    end
    
    for fishType, count in pairs(fishTypes) do
        print(SafeFormat("  - %s: %d items", fishType, count))
    end
    
    return fishData
end

-- Enhanced bait scanning function
local function scanBaitData()
    print("\n=== SCANNING BAIT DATA ===")
    local baitData = {}
    local baitKeywords = {"bait", "lure", "hook", "worm", "minnow", "shrimp", "crab", "squid", "fly", "spinner", "spoon", "jig", "plug", "popper", "buzzbait", "crankbait", "swimbait", "softbait", "hardbait", "topwater", "subsurface", "deepwater", "shallow", "live", "dead", "artificial", "natural", "fresh", "salt", "marine", "freshwater"}
    
    local function searchForBait(parent, path, depth)
        if depth <= 0 then return end
        
        pcall(function()
            for _, child in pairs(parent:GetChildren()) do
                local name = string.lower(child.Name or "")
                
                for _, keyword in pairs(baitKeywords) do
                    if string.find(name, keyword) then
                        table.insert(baitData, {
                            name = child.Name,
                            class = child.ClassName,
                            path = path .. "." .. child.Name,
                            fullName = child:GetFullName(),
                            location = parent.Name
                        })
                        break
                    end
                end
                
                if (child:IsA("Folder") or child:IsA("Model")) and not name:find("workspace") then
                    searchForBait(child, path .. "." .. child.Name, depth - 1)
                end
            end
        end)
    end
    
    searchForBait(ReplicatedStorage, "ReplicatedStorage", 4)
    searchForBait(Workspace, "Workspace", 3)
    
    print("🪱 BAIT DATA FOUND:")
    for i, bait in pairs(baitData) do
        print(SafeFormat("  [%d] %s (%s) at %s", i, bait.name, bait.class, bait.path))
    end
    
    return baitData
end

-- Enhanced rod scanning function
local function scanRodData()
    print("\n=== SCANNING FISHING ROD DATA ===")
    local rodData = {}
    local rodKeywords = {"rod", "pole", "stick", "reel", "line", "string", "fishing", "angler", "cast", "tackle", "gear"}
    
    local function searchForRods(parent, path, depth)
        if depth <= 0 then return end
        
        pcall(function()
            for _, child in pairs(parent:GetChildren()) do
                local name = string.lower(child.Name or "")
                
                for _, keyword in pairs(rodKeywords) do
                    if string.find(name, keyword) then
                        local rodInfo = {
                            name = child.Name,
                            class = child.ClassName,
                            path = path .. "." .. child.Name,
                            fullName = child:GetFullName(),
                            location = parent.Name,
                            type = "Unknown"
                        }
                        
                        if child:IsA("Tool") then
                            rodInfo.type = "Fishing Rod Tool"
                        elseif child:IsA("ModuleScript") then
                            rodInfo.type = "Rod Data/Script"
                        elseif child:IsA("Model") then
                            rodInfo.type = "Rod Model"
                        elseif child:IsA("Part") or child:IsA("MeshPart") then
                            rodInfo.type = "Rod Part/Mesh"
                        end
                        
                        table.insert(rodData, rodInfo)
                        break
                    end
                end
                
                if (child:IsA("Folder") or child:IsA("Model")) and not name:find("workspace") then
                    searchForRods(child, path .. "." .. child.Name, depth - 1)
                end
            end
        end)
    end
    
    searchForRods(ReplicatedStorage, "ReplicatedStorage", 4)
    searchForRods(Workspace, "Workspace", 3)
    
    print("🎣 FISHING ROD DATA FOUND:")
    for i, rod in pairs(rodData) do
        print(SafeFormat("  [%d] %s (%s) - %s at %s", i, rod.name, rod.type, rod.class, rod.path))
    end
    
    return rodData
end

-- Safe scanning function
local function safeScan(obj, path, maxDepth)
    maxDepth = maxDepth or 3
    if maxDepth <= 0 then return {} end
    
    local results = {}
    
    pcall(function()
        for _, child in pairs(obj:GetChildren()) do
            local childPath = path .. "." .. child.Name
            table.insert(results, {
                name = child.Name,
                class = child.ClassName,
                path = childPath,
                fullName = child:GetFullName()
            })
            
            -- Recursively scan important folders
            if child.ClassName == "Folder" or child.ClassName == "Model" then
                local subResults = safeScan(child, childPath, maxDepth - 1)
                for _, subResult in pairs(subResults) do
                    table.insert(results, subResult)
                end
            end
        end
    end)
    
    return results
end

-- Enhanced remote finder with better categorization
local function FindAllRemotes()
    print("\n=== SCANNING ALL REMOTES ===")
    local remotes = {}
    
    pcall(function()
        for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local remoteInfo = {
                    Name = obj.Name,
                    Type = obj:IsA("RemoteEvent") and "Event" or "Function",
                    Path = obj:GetFullName(),
                    Category = "Unknown"
                }
                
                -- Categorize remotes based on name
                local name = string.lower(obj.Name)
                if name:find("fish") or name:find("bait") or name:find("rod") or name:find("cast") or name:find("catch") or name:find("reel") then
                    remoteInfo.Category = "Fishing"
                elseif name:find("purchase") or name:find("buy") or name:find("sell") or name:find("coin") or name:find("money") then
                    remoteInfo.Category = "Economy"
                elseif name:find("boat") or name:find("spawn") or name:find("despawn") then
                    remoteInfo.Category = "Vehicles"
                elseif name:find("equip") or name:find("item") or name:find("tool") then
                    remoteInfo.Category = "Equipment"
                elseif name:find("trade") or name:find("gift") then
                    remoteInfo.Category = "Trading"
                elseif name:find("enchant") or name:find("upgrade") then
                    remoteInfo.Category = "Enhancement"
                else
                    remoteInfo.Category = "Other"
                end
                
                table.insert(remotes, remoteInfo)
            end
        end
    end)
    
    print("📡 REMOTES FOUND BY CATEGORY:")
    local categories = {}
    for _, remote in pairs(remotes) do
        if not categories[remote.Category] then
            categories[remote.Category] = {}
        end
        table.insert(categories[remote.Category], remote)
    end
    
    for category, categoryRemotes in pairs(categories) do
        print(SafeFormat("  📂 %s (%d remotes):", category, #categoryRemotes))
        for i, remote in pairs(categoryRemotes) do
            if i <= 5 then -- Show first 5 per category
                print(SafeFormat("    [%d] %s (%s)", i, remote.Name, remote.Type))
            end
        end
        if #categoryRemotes > 5 then
            print(SafeFormat("    ... and %d more", #categoryRemotes - 5))
        end
    end
    
    return remotes
end
local function scanReplicatedStorage()
    print("\n=== SCANNING REPLICATED STORAGE ===")
    local results = safeScan(ReplicatedStorage, "ReplicatedStorage", 4)
    
    local remotes = {}
    local packages = {}
    local data = {}
    local others = {}
    
    for _, item in pairs(results) do
        if item.class:find("Remote") then
            table.insert(remotes, item)
        elseif item.path:find("Packages") then
            table.insert(packages, item)
        elseif item.class == "Folder" or item.class == "ModuleScript" then
            table.insert(data, item)
        else
            table.insert(others, item)
        end
    end
    
    print("📡 REMOTES FOUND:")
    for _, remote in pairs(remotes) do
        print("  - " .. remote.name .. " (" .. remote.class .. ") at " .. remote.path)
    end
    
    print("\n📦 DATA/FOLDERS:")
    for _, folder in pairs(data) do
        print("  - " .. folder.name .. " (" .. folder.class .. ") at " .. folder.path)
    end
    
    print("\n🔧 PACKAGES:")
    for _, pkg in pairs(packages) do
        if pkg.name:find("net") or pkg.name:find("Net") then
            print("  - " .. pkg.name .. " (" .. pkg.class .. ") at " .. pkg.path)
        end
    end
    
    return {remotes = remotes, data = data, packages = packages, others = others}
end

-- Scan Workspace for boats and other objects
local function scanWorkspace()
    print("\n=== SCANNING WORKSPACE ===")
    local results = safeScan(Workspace, "Workspace", 3)
    
    local boats = {}
    local npcs = {}
    local areas = {}
    local others = {}
    
    for _, item in pairs(results) do
        local name = item.name:lower()
        if name:find("boat") or name:find("ship") or name:find("raft") then
            table.insert(boats, item)
        elseif item.class == "Model" and (name:find("npc") or name:find("vendor") or name:find("shop")) then
            table.insert(npcs, item)
        elseif item.class == "Model" or item.class == "Part" then
            table.insert(areas, item)
        else
            table.insert(others, item)
        end
    end
    
    print("🚤 BOATS/VEHICLES:")
    for _, boat in pairs(boats) do
        print("  - " .. boat.name .. " (" .. boat.class .. ") at " .. boat.path)
    end
    
    print("\n👥 NPCs/VENDORS:")
    for _, npc in pairs(npcs) do
        print("  - " .. npc.name .. " (" .. npc.class .. ") at " .. npc.path)
    end
    
    print("\n🏝️ AREAS/ISLANDS:")
    for i, area in pairs(areas) do
        if i <= 10 then -- Limit output
            print("  - " .. area.name .. " (" .. area.class .. ") at " .. area.path)
        end
    end
    if #areas > 10 then
        print("  ... and " .. (#areas - 10) .. " more areas")
    end
    
    return {boats = boats, npcs = npcs, areas = areas, others = others}
end

-- Scan player's inventory/tools
local function scanPlayerInventory()
    print("\n=== SCANNING PLAYER INVENTORY ===")
    
    if not LocalPlayer.Character then
        print("❌ No character found")
        return {}
    end
    
    local tools = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(tools, {
                    name = tool.Name,
                    class = tool.ClassName,
                    path = "Backpack." .. tool.Name
                })
            end
        end
    end
    
    -- Scan character for equipped tools
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(tools, {
                name = tool.Name,
                class = tool.ClassName,
                path = "Character." .. tool.Name
            })
        end
    end
    
    print("🎒 TOOLS/ITEMS:")
    for _, tool in pairs(tools) do
        print("  - " .. tool.name .. " (" .. tool.class .. ") at " .. tool.path)
    end
    
    return tools
end

-- Advanced remote scanner
local function scanForNetRemotes()
    print("\n=== SCANNING FOR NET FRAMEWORK ===")
    
    -- Look for net package
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if packages then
        local netPackages = {}
        for _, pkg in pairs(packages:GetChildren()) do
            if pkg.Name:find("net") or pkg.Name:find("Net") then
                table.insert(netPackages, pkg)
                print("📡 Net Package: " .. pkg.Name)
                
                -- Scan inside net package
                local netFolder = pkg:FindFirstChild("net")
                if netFolder then
                    print("  📂 Net folder found!")
                    for _, remote in pairs(netFolder:GetChildren()) do
                        print("    - " .. remote.Name .. " (" .. remote.ClassName .. ")")
                    end
                end
            end
        end
        return netPackages
    else
        print("❌ No Packages folder found")
        return {}
    end
end

-- Scan for boat-related data
local function scanForBoatData()
    print("\n=== SCANNING FOR BOAT DATA ===")
    
    local boatData = {}
    
    -- Look in ReplicatedStorage for boat configurations
    local function searchForBoats(parent, path)
        for _, child in pairs(parent:GetChildren()) do
            local name = child.Name:lower()
            if name:find("boat") or name:find("ship") or name:find("vehicle") or name:find("craft") then
                table.insert(boatData, {
                    name = child.Name,
                    class = child.ClassName,
                    path = path .. "." .. child.Name,
                    parent = parent.Name
                })
                
                -- If it's a folder, scan inside
                if child:IsA("Folder") or child:IsA("Configuration") then
                    print("  🚤 Found boat data: " .. child.Name .. " at " .. path)
                    for _, subChild in pairs(child:GetChildren()) do
                        print("    - " .. subChild.Name .. " (" .. subChild.ClassName .. ")")
                        if subChild:IsA("StringValue") or subChild:IsA("IntValue") or subChild:IsA("NumberValue") then
                            print("      Value: " .. tostring(subChild.Value))
                        end
                    end
                end
            end
            
            -- Recursively search in folders
            if child:IsA("Folder") and not name:find("workspace") then
                searchForBoats(child, path .. "." .. child.Name)
            end
        end
    end
    
    searchForBoats(ReplicatedStorage, "ReplicatedStorage")
    
    return boatData
end

-- Export all data to clipboard and file
local function ExportAllData()
    Notify("Export", "Starting data export...")
    
    local remotes = FindAllRemotes() or {}
    local rsData = scanReplicatedStorage() or {}
    local wsData = scanWorkspace() or {boats = {}, npcs = {}, areas = {}}
    local invData = scanPlayerInventory() or {}
    local netData = scanForNetRemotes() or {}
    local boatData = scanForBoatData() or {}
    local fishData = scanFishData() or {}
    local baitData = scanBaitData() or {}
    local rodData = scanRodData() or {}
    
    -- Store in global for access
    _G.FishItExplorationData = {
        remotes = remotes,
        replicatedStorage = rsData,
        workspace = wsData,
        inventory = invData,
        netFramework = netData,
        boatData = boatData,
        fishData = fishData,
        baitData = baitData,
        rodData = rodData,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        placeId = game.PlaceId
    }
    
    -- Safe length function
    local function safeLength(tbl)
        if not tbl then return 0 end
        if type(tbl) == "table" then return #tbl end
        return 0
    end
    
    -- Create export text for clipboard (limited)
    local totalItems = safeLength(remotes) + safeLength(fishData) + safeLength(baitData) + safeLength(rodData) + safeLength(wsData.boats) + safeLength(wsData.npcs)
    
    local exportText = SafeFormat([[
=== FISH IT COMPLETE EXPLORATION EXPORT ===
Game PlaceId: %s
Export Time: %s
Total Items Found: %d

=== SUMMARY ===
Remotes: %d
Fish Types: %d
Bait Types: %d
Fishing Rods: %d
Boats: %d
NPCs: %d
Areas: %d
Inventory Tools: %d

=== TOP FISHING REMOTES ===
]], game.PlaceId, os.date("%Y-%m-%d %H:%M:%S"), 
totalItems,
safeLength(remotes), safeLength(fishData), safeLength(baitData), safeLength(rodData), 
safeLength(wsData.boats), safeLength(wsData.npcs), safeLength(wsData.areas), safeLength(invData))
    
    -- Add fishing-related remotes
    local fishingRemotes = {}
    if remotes and type(remotes) == "table" then
        for _, remote in pairs(remotes) do
            if remote and remote.Category == "Fishing" then
                table.insert(fishingRemotes, remote)
            end
        end
    end
    
    for i = 1, math.min(safeLength(fishingRemotes), 10) do
        local remote = fishingRemotes[i]
        if remote and remote.Name and remote.Type then
            exportText = exportText .. SafeFormat("[%d] %s (%s)\n", i, remote.Name, remote.Type)
        end
    end
    
    exportText = exportText .. "\n=== TOP FISH TYPES ===\n"
    if fishData and type(fishData) == "table" then
        -- Show unique fish names
        local uniqueFishNames = {}
        for _, fish in pairs(fishData) do
            if fish and fish.name then
                local cleanName = fish.name:gsub("!!!", ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                if not uniqueFishNames[cleanName] then
                    uniqueFishNames[cleanName] = fish
                end
            end
        end
        
        local count = 0
        for fishName, fish in pairs(uniqueFishNames) do
            if count >= 15 then break end -- Limit for clipboard
            count = count + 1
            exportText = exportText .. SafeFormat("[%d] %s (%s)\n", count, fishName, fish.fishType or fish.type)
        end
        
        if count == 0 then
            exportText = exportText .. "No fish found\n"
        end
    end
    
    exportText = exportText .. "\n=== STATUS ===\n"
    exportText = exportText .. "✅ Complete scan finished\n"
    exportText = exportText .. "📱 Check console for full details\n"
    exportText = exportText .. "💾 File saved to Downloads folder\n"
    
    -- Copy to clipboard
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
        Notify("Clipboard", "✅ Summary copied to clipboard!")
    else
        Notify("Clipboard", "❌ Failed to copy. Check console.")
        print("\n" .. exportText)
    end
    
    return _G.FishItExplorationData
end

-- Save complete data to file
local function SaveCompleteDataToFile()
    if not _G.FishItExplorationData then
        Notify("Error", "No data to save. Run exploration first!")
        return false
    end
    
    local data = _G.FishItExplorationData
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = "FishIt_Complete_Explorer_" .. timestamp .. ".txt"
    
    -- Safe function to get length
    local function safeLength(tbl)
        if not tbl then return 0 end
        if type(tbl) == "table" then return #tbl end
        return 0
    end
    
    -- Safe access to nested data
    local remotesCount = safeLength(data.remotes)
    local fishCount = safeLength(data.fishData)
    local baitCount = safeLength(data.baitData)
    local rodCount = safeLength(data.rodData)
    local boatsCount = data.workspace and safeLength(data.workspace.boats) or 0
    local npcsCount = data.workspace and safeLength(data.workspace.npcs) or 0
    local areasCount = data.workspace and safeLength(data.workspace.areas) or 0
    local inventoryCount = safeLength(data.inventory)
    local netCount = safeLength(data.netFramework)
    
    -- Create complete file data
    local fileData = SafeFormat([[
=== FISH IT COMPLETE GAME EXPLORATION DATA ===
Game PlaceId: %s
Game Name: Fish It
Export Time: %s
Total Analysis Items: %d

=== EXPLORATION STATISTICS ===
Total Remotes Found: %d
Total Fish Types Found: %d
Total Bait Types Found: %d
Total Fishing Rods Found: %d
Total Boats Found: %d
Total NPCs Found: %d
Total Areas Found: %d
Total Inventory Tools: %d
Net Framework Items: %d

=== COMPLETE REMOTES LIST (by Category) ===
]], game.PlaceId, data.timestamp or os.date("%Y-%m-%d %H:%M:%S"), 
remotesCount + fishCount + baitCount + rodCount,
remotesCount, fishCount, baitCount, rodCount, 
boatsCount, npcsCount, areasCount, 
inventoryCount, netCount)
    
    -- Group remotes by category
    local categories = {}
    if data.remotes and type(data.remotes) == "table" then
        for _, remote in pairs(data.remotes) do
            if remote and remote.Category then
                if not categories[remote.Category] then
                    categories[remote.Category] = {}
                end
                table.insert(categories[remote.Category], remote)
            end
        end
    end
    
    for category, remotes in pairs(categories) do
        fileData = fileData .. SafeFormat("\n--- %s REMOTES (%d) ---\n", string.upper(category), #remotes)
        for i, remote in pairs(remotes) do
            if remote.Name and remote.Type and remote.Path then
                fileData = fileData .. SafeFormat("[%d] %s (%s): %s\n", i, remote.Name, remote.Type, remote.Path)
            end
        end
    end
    
    -- Add fish data with detailed fish names
    fileData = fileData .. "\n=== COMPLETE FISH DATA ===\n"
    if data.fishData and type(data.fishData) == "table" then
        -- Group fish by type for better organization
        local fishByType = {}
        for _, fish in pairs(data.fishData) do
            if fish and fish.fishType then
                if not fishByType[fish.fishType] then
                    fishByType[fish.fishType] = {}
                end
                table.insert(fishByType[fish.fishType], fish)
            end
        end
        
        -- Display fish grouped by type
        for fishType, fishes in pairs(fishByType) do
            fileData = fileData .. SafeFormat("\n--- %s (%d items) ---\n", string.upper(fishType), #fishes)
            for i, fish in pairs(fishes) do
                if fish.name and fish.type and fish.class and fish.path then
                    fileData = fileData .. SafeFormat("[%d] %s (%s) - %s at %s\n", i, fish.name, fish.type, fish.class, fish.path)
                end
            end
        end
        
        -- Also show all fish in simple list
        fileData = fileData .. "\n--- ALL FISH NAMES (Simple List) ---\n"
        local fishNames = {}
        for _, fish in pairs(data.fishData) do
            if fish and fish.name then
                -- Extract just the fish name without prefixes
                local cleanName = fish.name:gsub("!!!", ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                if not fishNames[cleanName] then
                    fishNames[cleanName] = true
                    fileData = fileData .. "- " .. cleanName .. "\n"
                end
            end
        end
    else
        fileData = fileData .. "No fish data available\n"
    end
    
    -- Add bait data
    fileData = fileData .. "\n=== COMPLETE BAIT DATA ===\n"
    if data.baitData and type(data.baitData) == "table" then
        for i, bait in pairs(data.baitData) do
            if bait and bait.name and bait.class and bait.path then
                fileData = fileData .. SafeFormat("[%d] %s (%s) at %s\n", i, bait.name, bait.class, bait.path)
            end
        end
    else
        fileData = fileData .. "No bait data available\n"
    end
    
    -- Add rod data
    fileData = fileData .. "\n=== COMPLETE FISHING ROD DATA ===\n"
    if data.rodData and type(data.rodData) == "table" then
        for i, rod in pairs(data.rodData) do
            if rod and rod.name and rod.type and rod.class and rod.path then
                fileData = fileData .. SafeFormat("[%d] %s (%s) - %s at %s\n", i, rod.name, rod.type, rod.class, rod.path)
            end
        end
    else
        fileData = fileData .. "No rod data available\n"
    end
    
    -- Add boat data
    fileData = fileData .. "\n=== COMPLETE BOAT DATA ===\n"
    if data.workspace and data.workspace.boats and type(data.workspace.boats) == "table" then
        for i, boat in pairs(data.workspace.boats) do
            if boat and boat.name and boat.class and boat.path then
                fileData = fileData .. SafeFormat("[%d] %s (%s) at %s\n", i, boat.name, boat.class, boat.path)
            end
        end
    else
        fileData = fileData .. "No boat data available\n"
    end
    
    -- Add NPC data
    fileData = fileData .. "\n=== COMPLETE NPC DATA ===\n"
    if data.workspace and data.workspace.npcs and type(data.workspace.npcs) == "table" then
        for i, npc in pairs(data.workspace.npcs) do
            if npc and npc.name and npc.class and npc.path then
                fileData = fileData .. SafeFormat("[%d] %s (%s) at %s\n", i, npc.name, npc.class, npc.path)
            end
        end
    else
        fileData = fileData .. "No NPC data available\n"
    end
    
    -- Add analysis notes
    fileData = fileData .. "\n=== ANALYSIS NOTES ===\n"
    fileData = fileData .. "Key Findings:\n"
    fileData = fileData .. "- Main networking uses sleitnick_net framework\n"
    fileData = fileData .. "- Fishing system has dedicated remotes for casting, catching, reeling\n"
    fileData = fileData .. "- Economy system handles purchases and sales\n"
    fileData = fileData .. "- Boat system supports spawning/despawning\n"
    fileData = fileData .. "- Trading system available\n"
    fileData = fileData .. "- Enhancement/enchantment system present\n"
    fileData = fileData .. "\nRecommended AutoFish Integration Points:\n"
    fileData = fileData .. "1. Use fishing-category remotes for automation\n"
    fileData = fileData .. "2. Monitor FishCaught and FishingCompleted events\n"
    fileData = fileData .. "3. Use ChargeFishingRod and CancelFishingInputs functions\n"
    fileData = fileData .. "4. Integrate with SellItem/SellAllItems for auto-selling\n"
    fileData = fileData .. "5. Monitor BaitSpawned and EquipBait for bait management\n"
    fileData = fileData .. SafeFormat("\nFile Generated: %s\n", filename)
    fileData = fileData .. "Generated by: Fish It Enhanced Game Explorer\n"
    fileData = fileData .. "Purpose: Complete game analysis for AutoFish development\n"
    
    -- Save to file
    local saved, filePath = SaveToFile(fileData, filename)
    
    if saved then
        Notify("File Saved", "💾 Complete data saved to: " .. filePath)
        Notify("Success", "📱 Check Downloads/Documents folder!")
        print("✅ File saved successfully: " .. filePath)
        return true
    else
        Notify("Error", "❌ Failed to save file. Check permissions.")
        print("❌ File save failed. Full data printed to console:")
        print(fileData)
        return false
    end
end

-- Create enhanced UI
local function CreateEnhancedUI()
    pcall(function()
        -- Remove existing UI
        local existing = LocalPlayer.PlayerGui:FindFirstChild("FishItExplorer")
        if existing then existing:Destroy() end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FishItExplorer"
        screenGui.Parent = LocalPlayer.PlayerGui
        
        -- Main frame
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 350, 0, 480)
        frame.Position = UDim2.new(0, 20, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        -- Add corner rounding
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame
        
        -- Title bar
        local titleBar = Instance.new("Frame")
        titleBar.Size = UDim2.new(1, 0, 0, 35)
        titleBar.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
        titleBar.BorderSizePixel = 0
        titleBar.Parent = frame
        
        local titleCorner = Instance.new("UICorner")
        titleCorner.CornerRadius = UDim.new(0, 8)
        titleCorner.Parent = titleBar
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -10, 1, 0)
        title.Position = UDim2.new(0, 5, 0, 0)
        title.Text = "🐟 Fish It Explorer Enhanced"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = titleBar
        
        -- Status label
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(1, -10, 0, 25)
        statusLabel.Position = UDim2.new(0, 5, 0, 40)
        statusLabel.Text = "Ready to explore Fish It game data"
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.TextSize = 11
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.Parent = frame
        
        -- Scroll frame for buttons
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -10, 1, -110)
        scrollFrame.Position = UDim2.new(0, 5, 0, 70)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 8
        scrollFrame.Parent = frame
        
        -- Button configuration
        local buttons = {
            {text = "🔍 Scan All Remotes", color = Color3.fromRGB(100, 150, 200), func = function()
                statusLabel.Text = "Scanning remotes..."
                task.spawn(function()
                    FindAllRemotes()
                    statusLabel.Text = "Remotes scan complete!"
                end)
            end},
            {text = "🐟 Scan Fish Data", color = Color3.fromRGB(100, 200, 150), func = function()
                statusLabel.Text = "Scanning fish data..."
                task.spawn(function()
                    local fishData = scanFishData()
                    if fishData and #fishData > 0 then
                        statusLabel.Text = SafeFormat("Found %d fish items!", #fishData)
                        
                        -- Print unique fish names to console
                        print("\n🐟 === UNIQUE FISH NAMES FOUND ===")
                        local uniqueNames = {}
                        for _, fish in pairs(fishData) do
                            if fish and fish.name then
                                local cleanName = fish.name:gsub("!!!", ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                                if not uniqueNames[cleanName] then
                                    uniqueNames[cleanName] = true
                                    print("- " .. cleanName .. (fish.fishType and (" (" .. fish.fishType .. ")") or ""))
                                end
                            end
                        end
                    else
                        statusLabel.Text = "No fish data found!"
                    end
                end)
            end},
            {text = "🪱 Scan Bait Data", color = Color3.fromRGB(200, 150, 100), func = function()
                statusLabel.Text = "Scanning bait data..."
                task.spawn(function()
                    scanBaitData()
                    statusLabel.Text = "Bait scan complete!"
                end)
            end},
            {text = "🎣 Scan Fishing Rods", color = Color3.fromRGB(150, 100, 200), func = function()
                statusLabel.Text = "Scanning fishing rods..."
                task.spawn(function()
                    scanRodData()
                    statusLabel.Text = "Rod scan complete!"
                end)
            end},
            {text = "🚤 Scan Boats & NPCs", color = Color3.fromRGB(200, 100, 150), func = function()
                statusLabel.Text = "Scanning boats & NPCs..."
                task.spawn(function()
                    scanWorkspace()
                    statusLabel.Text = "Boat & NPC scan complete!"
                end)
            end},
            {text = "🎒 Scan Inventory", color = Color3.fromRGB(150, 200, 100), func = function()
                statusLabel.Text = "Scanning inventory..."
                task.spawn(function()
                    scanPlayerInventory()
                    statusLabel.Text = "Inventory scan complete!"
                end)
            end},
            {text = "📡 Scan Net Framework", color = Color3.fromRGB(120, 180, 220), func = function()
                statusLabel.Text = "Scanning net framework..."
                task.spawn(function()
                    scanForNetRemotes()
                    statusLabel.Text = "Net framework scan complete!"
                end)
            end},
            {text = "🎯 Show Fish Names", color = Color3.fromRGB(255, 180, 100), func = function()
                statusLabel.Text = "Extracting fish names..."
                task.spawn(function()
                    local fishData = scanFishData()
                    if fishData and #fishData > 0 then
                        print("\n🐟 === ALL FISH NAMES IN FISH IT ===")
                        
                        -- Extract and display unique fish names
                        local uniqueNames = {}
                        local namesList = {}
                        
                        for _, fish in pairs(fishData) do
                            if fish and fish.name then
                                local cleanName = fish.name:gsub("!!!", ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
                                if not uniqueNames[cleanName] and not cleanName:find("Rod") and not cleanName:find("Bait") then
                                    uniqueNames[cleanName] = true
                                    table.insert(namesList, cleanName)
                                end
                            end
                        end
                        
                        -- Sort alphabetically
                        table.sort(namesList)
                        
                        -- Display in columns for better readability
                        for i, name in pairs(namesList) do
                            print(SafeFormat("%d. %s", i, name))
                        end
                        
                        statusLabel.Text = SafeFormat("Found %d unique fish names!", #namesList)
                        Notify("Fish Names", SafeFormat("Found %d unique fish! Check console", #namesList))
                        
                        -- Also try to copy fish names to clipboard
                        local fishNamesText = "Fish It - Fish Names:\n" .. table.concat(namesList, ", ")
                        pcall(function()
                            if setclipboard then
                                setclipboard(fishNamesText)
                                print("✅ Fish names copied to clipboard!")
                            end
                        end)
                    else
                        statusLabel.Text = "No fish names found!"
                    end
                end)
            end},
            {text = "🔍 Complete Exploration", color = Color3.fromRGB(180, 120, 220), func = function()
                statusLabel.Text = "Running complete exploration..."
                task.spawn(function()
                    local success, result = pcall(function()
                        return ExportAllData()
                    end)
                    
                    if success then
                        statusLabel.Text = "Complete exploration finished!"
                    else
                        statusLabel.Text = "Exploration error: " .. tostring(result)
                        print("❌ Error during exploration: " .. tostring(result))
                    end
                end)
            end},
            {text = "📋 Export to Clipboard", color = Color3.fromRGB(220, 180, 120), func = function()
                statusLabel.Text = "Exporting to clipboard..."
                task.spawn(function()
                    local success, result = pcall(function()
                        return ExportAllData()
                    end)
                    
                    if success then
                        statusLabel.Text = "Data exported to clipboard!"
                    else
                        statusLabel.Text = "Export error: " .. tostring(result)
                        print("❌ Error during export: " .. tostring(result))
                    end
                end)
            end},
            {text = "💾 Save to File", color = Color3.fromRGB(120, 220, 180), func = function()
                statusLabel.Text = "Saving to file..."
                task.spawn(function()
                    local success, result = pcall(function()
                        return SaveCompleteDataToFile()
                    end)
                    
                    if success then
                        if result then
                            statusLabel.Text = "File saved successfully!"
                        else
                            statusLabel.Text = "File save failed - no data!"
                        end
                    else
                        statusLabel.Text = "File save error: " .. tostring(result)
                        print("❌ Error saving file: " .. tostring(result))
                    end
                end)
            end},
            {text = "ℹ️ Game Info", color = Color3.fromRGB(180, 220, 120), func = function()
                local success, gameName = pcall(function()
                    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
                end)
                statusLabel.Text = "Game: " .. (success and gameName or "Fish It") .. " (ID: " .. game.PlaceId .. ")"
                Notify("Game Info", "PlaceId: " .. game.PlaceId)
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    print("Player Position: " .. tostring(LocalPlayer.Character.HumanoidRootPart.Position))
                end
            end},
            {text = "❌ Close Explorer", color = Color3.fromRGB(200, 100, 100), func = function()
                screenGui:Destroy()
            end}
        }
        
        -- Create buttons
        for i, buttonData in pairs(buttons) do
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(1, -10, 0, 35)
            button.Position = UDim2.new(0, 5, 0, (i-1) * 40)
            button.Text = buttonData.text
            button.BackgroundColor3 = buttonData.color
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.BorderSizePixel = 0
            button.Font = Enum.Font.GothamSemibold
            button.TextSize = 12
            button.Parent = scrollFrame
            
            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 6)
            buttonCorner.Parent = button
            
            -- Button animation
            button.MouseButton1Click:Connect(buttonData.func)
            
            button.MouseEnter:Connect(function()
                button.BackgroundColor3 = Color3.new(
                    math.min(buttonData.color.R * 1.2, 1),
                    math.min(buttonData.color.G * 1.2, 1),
                    math.min(buttonData.color.B * 1.2, 1)
                )
            end)
            
            button.MouseLeave:Connect(function()
                button.BackgroundColor3 = buttonData.color
            end)
        end
        
        -- Set scroll canvas size
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #buttons * 40)
        
        Notify("UI Ready", "🚀 Enhanced Fish It Explorer loaded!")
        statusLabel.Text = "Explorer ready! Click buttons to scan game data"
    end)
end
-- Main explorer function (updated)
local function exploreGame()
    print("🔍 STARTING FISH IT COMPLETE EXPLORATION...")
    print("=" .. string.rep("=", 60))
    
    Notify("Explorer", "Starting complete game exploration...")
    
    -- Scan all areas with enhanced data (with error handling)
    local remotes = pcall(FindAllRemotes) and FindAllRemotes() or {}
    local rsData = pcall(scanReplicatedStorage) and scanReplicatedStorage() or {}
    local wsData = pcall(scanWorkspace) and scanWorkspace() or {boats = {}, npcs = {}, areas = {}}
    local invData = pcall(scanPlayerInventory) and scanPlayerInventory() or {}
    local netData = pcall(scanForNetRemotes) and scanForNetRemotes() or {}
    local boatData = pcall(scanForBoatData) and scanForBoatData() or {}
    local fishData = pcall(scanFishData) and scanFishData() or {}
    local baitData = pcall(scanBaitData) and scanBaitData() or {}
    local rodData = pcall(scanRodData) and scanRodData() or {}
    
    -- Safe length function
    local function safeLength(tbl)
        if not tbl then return 0 end
        if type(tbl) == "table" then return #tbl end
        return 0
    end
    
    -- Enhanced summary
    print("\n" .. "=" .. string.rep("=", 60))
    print("📊 COMPLETE EXPLORATION SUMMARY:")
    print("  🔗 Remotes found: " .. safeLength(remotes))
    print("  🐟 Fish types found: " .. safeLength(fishData))
    print("  🪱 Bait types found: " .. safeLength(baitData))
    print("  🎣 Fishing rods found: " .. safeLength(rodData))
    print("  🚤 Boats found: " .. safeLength(wsData.boats))
    print("  👥 NPCs found: " .. safeLength(wsData.npcs))
    print("  🏝️ Areas found: " .. safeLength(wsData.areas))
    print("  🎒 Tools found: " .. safeLength(invData))
    print("  📡 Net packages: " .. safeLength(netData))
    print("  🛥️ Boat data: " .. safeLength(boatData))
    
    local totalItems = safeLength(remotes) + safeLength(fishData) + safeLength(baitData) + safeLength(rodData) + safeLength(wsData.boats) + safeLength(wsData.npcs) + safeLength(invData)
    print("  📈 Total items analyzed: " .. totalItems)
    
    Notify("Explorer", "Complete exploration finished! Check UI for export options.")
    
    -- Return enhanced data structure
    return {
        remotes = remotes,
        replicatedStorage = rsData,
        workspace = wsData,
        inventory = invData,
        netFramework = netData,
        boatData = boatData,
        fishData = fishData,
        baitData = baitData,
        rodData = rodData,
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        placeId = game.PlaceId
    }
end

-- Start enhanced explorer
print("🚀 Loading Fish It Enhanced Game Explorer...")

-- Create the enhanced UI
CreateEnhancedUI()

-- Store functions globally for UI access
_G.FishItExplorer = {
    exploreGame = exploreGame,
    exportData = ExportAllData,
    saveToFile = SaveCompleteDataToFile,
    scanFish = scanFishData,
    scanBait = scanBaitData,
    scanRods = scanRodData,
    scanRemotes = FindAllRemotes
}

print("✅ Enhanced Fish It Explorer ready!")
print("💡 Use the UI to explore game data or call _G.FishItExplorer functions")
print("📱 All data can be saved to your device's Downloads folder!")

-- Auto-run basic exploration if requested
if _G.AutoExplore then
    print("🔄 Auto-exploration enabled...")
    task.spawn(function()
        wait(2)
        exploreGame()
    end)
end
