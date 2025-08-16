-- Fish It Game Explorer Script
-- Scans all objects, remotes, and items in the game

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Notification function
local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 3})
    end)
    print("[EXPLORER]", title, text)
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

-- Scan ReplicatedStorage for remotes and data
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

-- Main explorer function
local function exploreGame()
    print("🔍 STARTING FISH IT GAME EXPLORATION...")
    print("=" .. string.rep("=", 50))
    
    Notify("Explorer", "Starting game exploration...")
    
    -- Scan all areas
    local rsData = scanReplicatedStorage()
    local wsData = scanWorkspace()
    local invData = scanPlayerInventory()
    local netData = scanForNetRemotes()
    local boatData = scanForBoatData()
    
    -- Summary
    print("\n" .. "=" .. string.rep("=", 50))
    print("📊 EXPLORATION SUMMARY:")
    print("  Remotes found: " .. #rsData.remotes)
    print("  Boats found: " .. #wsData.boats)
    print("  NPCs found: " .. #wsData.npcs)
    print("  Areas found: " .. #wsData.areas)
    print("  Tools found: " .. #invData)
    print("  Net packages: " .. #netData)
    print("  Boat data: " .. #boatData)
    
    Notify("Explorer", "Exploration complete! Check console for details.")
    
    -- Return all data for potential use
    return {
        replicatedStorage = rsData,
        workspace = wsData,
        inventory = invData,
        netFramework = netData,
        boatData = boatData
    }
end

-- Start exploration
local explorationData = exploreGame()

-- Expose data globally for other scripts
_G.FishItExploration = explorationData

-- Auto-save data to files if data saver is available
if _G.SaveFishItData then
    print("\n💾 Auto-saving exploration data...")
    _G.SaveFishItData()
else
    print("\n💡 Tip: Run data_saver.lua after this to save results to files!")
end

print("\n✅ Exploration complete! Data available in _G.FishItExploration")
