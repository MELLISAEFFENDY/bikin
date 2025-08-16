-- Fish It Data Saver & Loader
-- Saves exploration data to files and loads them back

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
    end)
    print("[DATA-SAVER]", title, text)
end

-- Data structure for Fish It exploration data
local FishItData = {
    gameInfo = {
        placeName = "Unknown Game",
        placeId = game.PlaceId or 0,
        scanTime = os.date("%Y-%m-%d %H:%M:%S"),
        playerName = LocalPlayer.Name or "Unknown Player"
    },
    remotes = {},
    boats = {
        configs = {},
        existing = {},
        remotes = {},
        shopData = {}
    },
    items = {
        tools = {},
        inventory = {}
    },
    npcs = {},
    areas = {},
    packages = {}
}

-- Safe initialization of game info
pcall(function()
    local marketplaceService = game:GetService("MarketplaceService")
    local productInfo = marketplaceService:GetProductInfo(game.PlaceId)
    FishItData.gameInfo.placeName = productInfo.Name or "Fish It"
end)

-- Save data to JSON format (for console output)
local function saveToJSON(data, filename)
    filename = filename or "fishit_data_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
    
    local jsonData = HttpService:JSONEncode(data)
    
    print("\n" .. "=" .. string.rep("=", 60))
    print("📁 FISH IT DATA EXPORT - " .. filename)
    print("=" .. string.rep("=", 60))
    print(jsonData)
    print("=" .. string.rep("=", 60))
    print("💾 Copy the JSON data above to save to file!")
    print("📋 Data size: " .. #jsonData .. " characters")
    
    Notify("Data Export", "Data exported to console! Copy and save as " .. filename)
    
    return jsonData
end

-- Save data in readable format
local function saveToReadable(data, filename)
    filename = filename or "fishit_readable_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
    
    local output = {}
    table.insert(output, "🎮 FISH IT GAME DATA EXPORT")
    table.insert(output, "=" .. string.rep("=", 50))
    table.insert(output, "Game: " .. (data.gameInfo.placeName or "Unknown Game"))
    table.insert(output, "Place ID: " .. (data.gameInfo.placeId or "Unknown"))
    table.insert(output, "Scan Time: " .. (data.gameInfo.scanTime or "Unknown"))
    table.insert(output, "Player: " .. (data.gameInfo.playerName or "Unknown Player"))
    table.insert(output, "")
    
    -- Remotes section
    table.insert(output, "📡 REMOTES FOUND (" .. #data.remotes .. "):")
    table.insert(output, "-" .. string.rep("-", 40))
    for _, remote in pairs(data.remotes) do
        local name = remote.name or "Unknown"
        local class = remote.class or "Unknown" 
        local path = remote.path or "Unknown"
        table.insert(output, "  • " .. name .. " (" .. class .. ")")
        table.insert(output, "    Path: " .. path)
    end
    table.insert(output, "")
    
    -- Boat remotes section
    table.insert(output, "🚤 BOAT REMOTES (" .. #data.boats.remotes .. "):")
    table.insert(output, "-" .. string.rep("-", 40))
    for _, remote in pairs(data.boats.remotes) do
        local name = remote.name or "Unknown"
        local class = remote.class or "Unknown"
        local rtype = remote.type or "unknown"
        table.insert(output, "  • " .. name .. " (" .. class .. ") - " .. rtype)
    end
    table.insert(output, "")
    
    -- Boat configs section
    table.insert(output, "⚙️ BOAT CONFIGS (" .. #data.boats.configs .. "):")
    table.insert(output, "-" .. string.rep("-", 40))
    for _, config in pairs(data.boats.configs) do
        local name = config.name or "Unknown"
        local class = config.class or "Unknown"
        local path = config.path or "Unknown"
        table.insert(output, "  • " .. name .. " (" .. class .. ")")
        table.insert(output, "    Path: " .. path)
    end
    table.insert(output, "")
    
    -- Existing boats section
    table.insert(output, "🛥️ EXISTING BOATS (" .. #data.boats.existing .. "):")
    table.insert(output, "-" .. string.rep("-", 40))
    for _, boat in pairs(data.boats.existing) do
        local name = boat.name or "Unknown"
        local owner = boat.owner or "Unknown"
        local path = boat.path or "Unknown"
        table.insert(output, "  • " .. name .. " (Owner: " .. owner .. ")")
        table.insert(output, "    Path: " .. path)
    end
    table.insert(output, "")
    
    -- Tools section
    table.insert(output, "🎒 TOOLS/ITEMS (" .. #data.items.tools .. "):")
    table.insert(output, "-" .. string.rep("-", 40))
    for _, tool in pairs(data.items.tools) do
        local name = tool.name or "Unknown"
        local class = tool.class or "Unknown"
        local path = tool.path or "Unknown"
        table.insert(output, "  • " .. name .. " (" .. class .. ")")
        table.insert(output, "    Path: " .. path)
    end
    table.insert(output, "")
    
    -- NPCs section
    table.insert(output, "👥 NPCs/VENDORS (" .. #data.npcs .. "):")
    table.insert(output, "-" .. string.rep("-", 40))
    for _, npc in pairs(data.npcs) do
        local name = npc.name or "Unknown"
        local class = npc.class or "Unknown"
        local path = npc.path or "Unknown"
        table.insert(output, "  • " .. name .. " (" .. class .. ")")
        table.insert(output, "    Path: " .. path)
    end
    table.insert(output, "")
    
    -- Areas section (limit to first 20)
    table.insert(output, "🏝️ AREAS/ISLANDS (showing first 20 of " .. #data.areas .. "):")
    table.insert(output, "-" .. string.rep("-", 40))
    for i, area in pairs(data.areas) do
        if i <= 20 then
            local name = area.name or "Unknown"
            local class = area.class or "Unknown"
            table.insert(output, "  • " .. name .. " (" .. class .. ")")
        end
    end
    if #data.areas > 20 then
        table.insert(output, "  ... and " .. (#data.areas - 20) .. " more areas")
    end
    table.insert(output, "")
    
    -- Packages section
    table.insert(output, "📦 PACKAGES (" .. #data.packages .. "):")
    table.insert(output, "-" .. string.rep("-", 40))
    for _, pkg in pairs(data.packages) do
        local name = pkg.name or "Unknown"
        local class = pkg.class or "Unknown"
        local path = pkg.path or "Unknown"
        table.insert(output, "  • " .. name .. " (" .. class .. ")")
        table.insert(output, "    Path: " .. path)
    end
    table.insert(output, "")
    
    table.insert(output, "=" .. string.rep("=", 50))
    table.insert(output, "💾 Data export completed at " .. os.date("%Y-%m-%d %H:%M:%S"))
    
    local readableData = table.concat(output, "\n")
    
    print("\n" .. "=" .. string.rep("=", 60))
    print("📄 FISH IT READABLE DATA EXPORT - " .. filename)
    print("=" .. string.rep("=", 60))
    print(readableData)
    print("=" .. string.rep("=", 60))
    print("📋 Copy the readable data above to save to file!")
    
    Notify("Readable Export", "Readable data exported! Copy and save as " .. filename)
    
    return readableData
end

-- Load data from global variables set by explorer scripts
local function loadFromGlobalData()
    print("📥 Loading data from global variables...")
    
    -- Load from _G.FishItExploration if available
    if _G.FishItExploration then
        print("✅ Found _G.FishItExploration data")
        
        -- Load remotes
        if _G.FishItExploration.replicatedStorage and _G.FishItExploration.replicatedStorage.remotes then
            for _, remote in pairs(_G.FishItExploration.replicatedStorage.remotes) do
                table.insert(FishItData.remotes, remote)
            end
        end
        
        -- Load boat data
        if _G.FishItExploration.workspace then
            if _G.FishItExploration.workspace.boats then
                for _, boat in pairs(_G.FishItExploration.workspace.boats) do
                    table.insert(FishItData.boats.existing, boat)
                end
            end
            if _G.FishItExploration.workspace.npcs then
                for _, npc in pairs(_G.FishItExploration.workspace.npcs) do
                    table.insert(FishItData.npcs, npc)
                end
            end
            if _G.FishItExploration.workspace.areas then
                for _, area in pairs(_G.FishItExploration.workspace.areas) do
                    table.insert(FishItData.areas, area)
                end
            end
        end
        
        -- Load inventory
        if _G.FishItExploration.inventory then
            for _, tool in pairs(_G.FishItExploration.inventory) do
                table.insert(FishItData.items.tools, tool)
            end
        end
        
        -- Load packages
        if _G.FishItExploration.replicatedStorage and _G.FishItExploration.replicatedStorage.packages then
            for _, pkg in pairs(_G.FishItExploration.replicatedStorage.packages) do
                table.insert(FishItData.packages, pkg)
            end
        end
    end
    
    -- Load from _G.BoatFinderData if available
    if _G.BoatFinderData then
        print("✅ Found _G.BoatFinderData data")
        
        if _G.BoatFinderData.remotes then
            for _, remote in pairs(_G.BoatFinderData.remotes) do
                table.insert(FishItData.boats.remotes, remote)
            end
        end
        
        if _G.BoatFinderData.configs then
            for _, config in pairs(_G.BoatFinderData.configs) do
                table.insert(FishItData.boats.configs, config)
            end
        end
        
        if _G.BoatFinderData.existing then
            for _, boat in pairs(_G.BoatFinderData.existing) do
                table.insert(FishItData.boats.existing, boat)
            end
        end
        
        if _G.BoatFinderData.shops then
            for _, shop in pairs(_G.BoatFinderData.shops) do
                table.insert(FishItData.boats.shopData, shop)
            end
        end
    end
    
    print("📊 Data loading summary:")
    print("  Remotes: " .. #FishItData.remotes)
    print("  Boat remotes: " .. #FishItData.boats.remotes)
    print("  Boat configs: " .. #FishItData.boats.configs)
    print("  Existing boats: " .. #FishItData.boats.existing)
    print("  Tools: " .. #FishItData.items.tools)
    print("  NPCs: " .. #FishItData.npcs)
    print("  Areas: " .. #FishItData.areas)
    print("  Packages: " .. #FishItData.packages)
    
    return FishItData
end

-- Generate script configuration based on found data
local function generateScriptConfig()
    print("\n🔧 GENERATING SCRIPT CONFIGURATION...")
    
    local config = {
        boatRemotes = {},
        recommendedBoats = {},
        fallbackRemotes = {}
    }
    
    -- Extract boat remote names
    for _, remote in pairs(FishItData.boats.remotes) do
        if remote.type == "spawn" then
            table.insert(config.boatRemotes, remote.name)
        end
    end
    
    -- Extract boat config names
    for _, boatConfig in pairs(FishItData.boats.configs) do
        table.insert(config.recommendedBoats, boatConfig.name)
    end
    
    -- Add fallback remotes from general remotes
    for _, remote in pairs(FishItData.remotes) do
        local name = remote.name:lower()
        if name:find("boat") or name:find("spawn") or name:find("vehicle") then
            table.insert(config.fallbackRemotes, remote.name)
        end
    end
    
    print("⚙️ Script Configuration Generated:")
    print("  Boat spawn remotes: " .. #config.boatRemotes)
    print("  Recommended boats: " .. #config.recommendedBoats)
    print("  Fallback remotes: " .. #config.fallbackRemotes)
    
    -- Generate Lua code for updating main script
    local luaConfig = {}
    table.insert(luaConfig, "-- Auto-generated Fish It configuration")
    table.insert(luaConfig, "local FishItConfig = {")
    
    table.insert(luaConfig, "    boatSpawnRemotes = {")
    for _, remote in pairs(config.boatRemotes) do
        table.insert(luaConfig, "        \"" .. remote .. "\",")
    end
    table.insert(luaConfig, "    },")
    
    table.insert(luaConfig, "    availableBoats = {")
    for _, boat in pairs(config.recommendedBoats) do
        table.insert(luaConfig, "        \"" .. boat .. "\",")
    end
    table.insert(luaConfig, "    },")
    
    table.insert(luaConfig, "    fallbackRemotes = {")
    for _, remote in pairs(config.fallbackRemotes) do
        table.insert(luaConfig, "        \"" .. remote .. "\",")
    end
    table.insert(luaConfig, "    }")
    
    table.insert(luaConfig, "}")
    table.insert(luaConfig, "")
    table.insert(luaConfig, "-- Use this configuration in your main script!")
    
    local configCode = table.concat(luaConfig, "\n")
    
    print("\n" .. "=" .. string.rep("=", 60))
    print("🔧 LUA CONFIGURATION CODE")
    print("=" .. string.rep("=", 60))
    print(configCode)
    print("=" .. string.rep("=", 60))
    
    return config, configCode
end

-- Main save function
local function saveAllData()
    print("💾 STARTING DATA SAVE PROCESS...")
    Notify("Data Saver", "Starting data export process...")
    
    -- Load data from global variables
    local data = loadFromGlobalData()
    
    -- Generate different export formats
    local jsonData = saveToJSON(data, "fishit_data.json")
    local readableData = saveToReadable(data, "fishit_data.txt")
    local config, configCode = generateScriptConfig()
    
    -- Save config code separately
    print("\n" .. "=" .. string.rep("=", 60))
    print("📝 SCRIPT UPDATE CODE - fishit_config.lua")
    print("=" .. string.rep("=", 60))
    print(configCode)
    print("=" .. string.rep("=", 60))
    
    Notify("Save Complete", "All data exported! Check console for files to copy.")
    
    return {
        json = jsonData,
        readable = readableData,
        config = configCode,
        data = data
    }
end

-- Auto-save if global data is available
if _G.FishItExploration or _G.BoatFinderData then
    print("🔍 Global exploration data found! Auto-saving...")
    local savedData = saveAllData()
    _G.FishItSavedData = savedData
    
    print("\n✅ Data save complete!")
    print("📁 Files to create:")
    print("  1. fishit_data.json - Complete data in JSON format")
    print("  2. fishit_data.txt - Human-readable data")
    print("  3. fishit_config.lua - Script configuration code")
    print("\n💡 Copy the data from console output above to create these files!")
else
    print("⚠️ No global exploration data found.")
    print("💡 Run game_explorer.lua and boat_finder.lua first, then run this script!")
end

-- Expose save function globally
_G.SaveFishItData = saveAllData

print("\n✅ Data saver loaded! Use _G.SaveFishItData() to save data anytime!")
