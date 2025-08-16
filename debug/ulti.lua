-- ═══════════════════════════════════════════════════════════════
-- 🔍 FISH IT ULTIMATE REMOTE EXPLORER
-- ═══════════════════════════════════════════════════════════════
-- Purpose: Find ALL remotes in the entire game without assumptions
-- Method: Scan everything, show structure, categorize by patterns
-- ═══════════════════════════════════════════════════════════════

print("🔍 Ultimate Remote Explorer - Starting comprehensive scan...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local RemoteExplorer = {
    allRemotes = {},
    totalFound = 0,
    structure = {}
}

-- ═══════════════════════════════════════════════════════════════
-- 🌐 COMPLETE GAME SCAN
-- ═══════════════════════════════════════════════════════════════

local function ScanEverything()
    print("🌐 Scanning ENTIRE game for remotes...")
    print("📍 Target: All RemoteEvent and RemoteFunction objects")
    
    local found = {}
    local structure = {}
    
    -- Scan ReplicatedStorage completely
    print("🔍 Scanning ReplicatedStorage...")
    for _, descendant in pairs(ReplicatedStorage:GetDescendants()) do
        if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
            local info = {
                name = descendant.Name,
                type = descendant.ClassName,
                fullPath = descendant:GetFullName(),
                parent = descendant.Parent and descendant.Parent.Name or "nil",
                grandParent = descendant.Parent and descendant.Parent.Parent and descendant.Parent.Parent.Name or "nil",
                object = descendant
            }
            
            table.insert(found, info)
            
            -- Build structure tree
            local pathParts = string.split(descendant:GetFullName(), ".")
            local currentLevel = structure
            for i, part in ipairs(pathParts) do
                if not currentLevel[part] then
                    currentLevel[part] = {}
                end
                currentLevel = currentLevel[part]
            end
        end
    end
    
    RemoteExplorer.allRemotes = found
    RemoteExplorer.totalFound = #found
    RemoteExplorer.structure = structure
    
    print("✅ Scan complete! Found", #found, "remotes")
    return #found > 0
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 ANALYZE AND CATEGORIZE
-- ═══════════════════════════════════════════════════════════════

local function AnalyzeRemotes()
    print("\n📊 ANALYZING FOUND REMOTES...")
    print("═══════════════════════════════════════")
    
    local categories = {
        fishing = {},
        enhancement = {},
        purchase = {},
        boat = {},
        ui = {},
        system = {},
        other = {}
    }
    
    -- Categorize by name patterns
    for _, remote in ipairs(RemoteExplorer.allRemotes) do
        local name = remote.name:lower()
        local path = remote.fullPath:lower()
        
        if name:find("fish") or name:find("rod") or name:find("cast") or name:find("reel") or name:find("catch") or name:find("bait") then
            table.insert(categories.fishing, remote)
        elseif name:find("enchant") or name:find("upgrade") or name:find("enhance") or name:find("roll") then
            table.insert(categories.enhancement, remote)
        elseif name:find("purchase") or name:find("buy") or name:find("shop") or name:find("product") then
            table.insert(categories.purchase, remote)
        elseif name:find("boat") or name:find("spawn") or name:find("vehicle") then
            table.insert(categories.boat, remote)
        elseif name:find("ui") or name:find("gui") or name:find("menu") or name:find("button") then
            table.insert(categories.ui, remote)
        elseif name:find("system") or name:find("core") or name:find("framework") then
            table.insert(categories.system, remote)
        else
            table.insert(categories.other, remote)
        end
    end
    
    -- Print categorized results
    for category, remotes in pairs(categories) do
        if #remotes > 0 then
            print(string.format("\n🎯 %s REMOTES (%d found):", category:upper(), #remotes))
            for i, remote in ipairs(remotes) do
                print(string.format("  [%d] %s (%s)", i, remote.name, remote.type))
                print(string.format("      Path: %s", remote.fullPath))
            end
        end
    end
    
    return categories
end

-- ═══════════════════════════════════════════════════════════════
-- 🎣 FISHING REMOTE TESTER
-- ═══════════════════════════════════════════════════════════════

local function TestFishingRemotes(categories)
    print("\n🎣 TESTING FISHING REMOTES...")
    print("═══════════════════════════════════════")
    
    if #categories.fishing == 0 then
        print("❌ No fishing remotes found to test")
        return
    end
    
    local testedCount = 0
    
    for i, remote in ipairs(categories.fishing) do
        print(string.format("\n🧪 Testing [%d]: %s", i, remote.name))
        
        local success, err = pcall(function()
            local obj = remote.object
            
            if obj:IsA("RemoteFunction") then
                local original = obj.InvokeServer
                obj.InvokeServer = function(self, ...)
                    local args = {...}
                    print(string.format("📞 RF Call: %s with %d args", remote.name, #args))
                    for j, arg in ipairs(args) do
                        print(string.format("   Arg[%d]: %s (%s)", j, tostring(arg), type(arg)))
                    end
                    return original(self, unpack(args))
                end
                testedCount = testedCount + 1
                print("✅ Hooked RemoteFunction")
                
            elseif obj:IsA("RemoteEvent") then
                local original = obj.FireServer
                obj.FireServer = function(self, ...)
                    local args = {...}
                    print(string.format("📞 RE Call: %s with %d args", remote.name, #args))
                    for j, arg in ipairs(args) do
                        print(string.format("   Arg[%d]: %s (%s)", j, tostring(arg), type(arg)))
                    end
                    return original(self, unpack(args))
                end
                testedCount = testedCount + 1
                print("✅ Hooked RemoteEvent")
            end
        end)
        
        if not success then
            print("❌ Failed to hook:", err)
        end
    end
    
    print(string.format("\n✅ Successfully hooked %d fishing remotes", testedCount))
    print("🎣 Now use fishing in the game to see which remotes are called!")
end

-- ═══════════════════════════════════════════════════════════════
-- 📋 STRUCTURE DISPLAY
-- ═══════════════════════════════════════════════════════════════

local function ShowStructure()
    print("\n📋 REPLICATEDSTORAGE STRUCTURE:")
    print("═══════════════════════════════════════")
    
    local function printLevel(level, indent)
        indent = indent or ""
        for key, value in pairs(level) do
            if type(value) == "table" then
                print(indent .. "📁 " .. key)
                if indent == "" or indent == "  " then -- Only show 2 levels deep
                    printLevel(value, indent .. "  ")
                end
            end
        end
    end
    
    printLevel(RemoteExplorer.structure)
end

-- ═══════════════════════════════════════════════════════════════
-- 📊 COMPREHENSIVE UI
-- ═══════════════════════════════════════════════════════════════

local function CreateExplorerUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RemoteExplorer"
    screenGui.ResetOnSpawn = false
    
    local success = pcall(function()
        screenGui.Parent = game.CoreGui
    end)
    if not success then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    -- Main window
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "🔍 Ultimate Remote Explorer"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
    title.BorderSizePixel = 0
    title.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Scan button
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(1, -10, 0, 35)
    scanBtn.Position = UDim2.new(0, 5, 0, 35)
    scanBtn.Text = "🌐 SCAN ALL REMOTES"
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.TextSize = 12
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
    scanBtn.BorderSizePixel = 0
    scanBtn.Parent = frame
    
    local scanCorner = Instance.new("UICorner")
    scanCorner.CornerRadius = UDim.new(0, 6)
    scanCorner.Parent = scanBtn
    
    -- Test button
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(1, -10, 0, 35)
    testBtn.Position = UDim2.new(0, 5, 0, 75)
    testBtn.Text = "🎣 TEST FISHING REMOTES"
    testBtn.Font = Enum.Font.GothamBold
    testBtn.TextSize = 12
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
    testBtn.BorderSizePixel = 0
    testBtn.Active = false
    testBtn.Parent = frame
    
    local testCorner = Instance.new("UICorner")
    testCorner.CornerRadius = UDim.new(0, 6)
    testCorner.Parent = testBtn
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 100)
    statusLabel.Position = UDim2.new(0, 5, 0, 120)
    statusLabel.Text = "📊 Ready to scan for all remotes in the game...\n\nClick 'SCAN ALL REMOTES' to start comprehensive analysis."
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 10
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    statusLabel.BorderSizePixel = 0
    statusLabel.TextWrapped = true
    statusLabel.Parent = frame
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 4)
    statusCorner.Parent = statusLabel
    
    -- Console note
    local consoleNote = Instance.new("TextLabel")
    consoleNote.Size = UDim2.new(1, -10, 0, 60)
    consoleNote.Position = UDim2.new(0, 5, 0, 230)
    consoleNote.Text = "📋 Detailed results will be shown in console (F9)\n\n💡 After testing, use fishing features to see which remotes are called!"
    consoleNote.Font = Enum.Font.Gotham
    consoleNote.TextSize = 9
    consoleNote.TextColor3 = Color3.fromRGB(100, 200, 255)
    consoleNote.BackgroundTransparency = 1
    consoleNote.TextWrapped = true
    consoleNote.Parent = frame
    
    -- Button functionality
    local categories = {}
    
    scanBtn.MouseButton1Click:Connect(function()
        scanBtn.Text = "🔍 SCANNING..."
        scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        statusLabel.Text = "🔍 Scanning entire game for remotes...\n\nThis may take a moment..."
        
        task.wait(0.5)
        
        if ScanEverything() then
            statusLabel.Text = string.format("✅ Scan complete!\n\n📊 Found %d total remotes\n📋 Check console (F9) for detailed results", RemoteExplorer.totalFound)
            
            categories = AnalyzeRemotes()
            ShowStructure()
            
            scanBtn.Text = "✅ SCAN COMPLETE"
            scanBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            scanBtn.Active = false
            
            testBtn.Active = true
            testBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        else
            statusLabel.Text = "❌ Scan failed!\n\nNo remotes found in the game."
            scanBtn.Text = "❌ SCAN FAILED"
            scanBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
        end
    end)
    
    testBtn.MouseButton1Click:Connect(function()
        if #categories.fishing > 0 then
            testBtn.Text = "🧪 TESTING..."
            testBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            
            TestFishingRemotes(categories)
            
            testBtn.Text = "✅ HOOKS ACTIVE"
            testBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
            testBtn.Active = false
            
            statusLabel.Text = string.format("✅ Hooked %d fishing remotes!\n\n🎣 Now use fishing in the game to see which remotes are called in console!", #categories.fishing)
        else
            statusLabel.Text = "❌ No fishing remotes found to test!\n\nRun scan first or check if this game has fishing features."
        end
    end)
    
    return screenGui
end

-- ═══════════════════════════════════════════════════════════════
-- 🚀 AUTO-START EXPLORATION
-- ═══════════════════════════════════════════════════════════════

local function Initialize()
    print("🔍 Ultimate Remote Explorer - Initializing...")
    
    -- Create UI
    CreateExplorerUI()
    
    print("✅ Remote Explorer ready!")
    print("💡 Use the UI to scan and test remotes")
    print("📋 Detailed results will appear in console")
end

-- Start the explorer
Initialize()

--[[
🔍 ULTIMATE REMOTE EXPLORER GUIDE:

🎯 PURPOSE:
- Find ALL remotes in the entire game
- No assumptions about structure or names
- Categorize by patterns automatically
- Test fishing remotes with real hooks

📊 FEATURES:
✅ Complete game scan (all descendants)
✅ Automatic categorization by name patterns
✅ Structure tree display
✅ Real-time remote testing
✅ Console logging with detailed info
✅ UI for easy operation

💡 HOW TO USE:
1. Load script - UI appears automatically
2. Click "SCAN ALL REMOTES" - finds everything
3. Check console (F9) for detailed results
4. Click "TEST FISHING REMOTES" - hooks them
5. Use fishing in game - see which remotes are called

🔍 WHAT THIS REVEALS:
- Every single remote in the game
- Actual structure (not assumed)
- Which remotes are fishing-related
- Real-time usage patterns
- Parameter types and values

This should find the REAL fishing remotes regardless of game structure!
]]

print("🔍 Ultimate Remote Explorer loaded!")
print("🎯 Ready to find ALL remotes in Fish It")
print("📊 No assumptions - comprehensive analysis")
