-- enchant_debug.lua
-- Khusus untuk debug enchanting remotes di Fish It
-- Jalankan script ini terpisah untuk mencari remote enchanting yang benar

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("=== 🔍 ENCHANTING DEBUG STARTED ===")

-- Helper function untuk mencari net
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

-- Cari semua remotes yang berhubungan dengan enchanting
local function SearchEnchantingRemotes()
    print("� Searching for enchanting-related remotes...")
    
    local net = FindNet()
    if not net then
        print("❌ Net not found! Check ReplicatedStorage structure")
        return
    end
    
    print("✅ Net found! Scanning for enchanting remotes...")
    
    local enchantRemotes = {}
    
    -- Function untuk scan folder secara rekursif
    local function scanFolder(folder, path)
        for _, child in pairs(folder:GetChildren()) do
            local fullPath = path .. "/" .. child.Name
            local name = child.Name:lower()
            
            -- Cek kata kunci enchanting
            if name:find("enchant") or name:find("altar") or name:find("roll") or 
               name:find("magic") or name:find("upgrade") then
                table.insert(enchantRemotes, {
                    name = child.Name,
                    path = fullPath,
                    type = child.ClassName
                })
                print("🔮 Found:", fullPath, "(" .. child.ClassName .. ")")
            end
            
            -- Scan subfolder jika ada
            if child:IsA("Folder") then
                scanFolder(child, fullPath)
            end
        end
    end
    
    scanFolder(net, "")
    
    if #enchantRemotes == 0 then
        print("❌ No enchanting remotes found!")
        print("� Try these manual steps:")
        print("   1. Go to enchanting table in-game")
        print("   2. Open Developer Console (F9)")
        print("   3. Try to enchant manually")
        print("   4. Watch for remote calls in console")
    else
        print("✅ Found " .. #enchantRemotes .. " potential enchanting remotes:")
        for i, remote in ipairs(enchantRemotes) do
            print(string.format("  %d. %s (%s)", i, remote.path, remote.type))
        end
    end
    
    return enchantRemotes
end

-- Test remote dengan berbagai parameter
local function TestEnchantingRemote(remotePath)
    print("🧪 Testing remote:", remotePath)
    
    local net = FindNet()
    if not net then
        print("❌ Net not found")
        return false
    end
    
    local remote = net:FindFirstChild(remotePath:gsub("^/", ""))
    if not remote then
        print("❌ Remote not found:", remotePath)
        return false
    end
    
    print("✅ Remote found! Type:", remote.ClassName)
    
    -- Test dengan berbagai cara
    local tests = {
        {name = "No params", params = {}},
        {name = "With true", params = {true}},
        {name = "With 1", params = {1}},
        {name = "With 'test'", params = {"test"}},
    }
    
    for _, test in ipairs(tests) do
        local ok, result = pcall(function()
            if remote:IsA("RemoteFunction") then
                return remote:InvokeServer(unpack(test.params))
            else
                remote:FireServer(unpack(test.params))
                return "fired"
            end
        end)
        
        if ok then
            print("✅ " .. test.name .. ": SUCCESS -", tostring(result))
        else
            print("❌ " .. test.name .. ": FAILED -", tostring(result))
        end
        wait(0.5) -- Delay antar test
    end
end

-- Main function
local function Main()
    print("🎯 Enchanting Debug Tool")
    print("📍 Current Player:", Players.LocalPlayer.Name)
    
    -- Cari remotes
    local remotes = SearchEnchantingRemotes()
    
    -- Print all remotes untuk manual checking
    print("📋 ALL REMOTES IN NET:")
    local net = FindNet()
    if net then
        local function listAll(folder, indent)
            for _, child in pairs(folder:GetChildren()) do
                print(indent .. child.Name .. " (" .. child.ClassName .. \

-- Test enchanting remotes
local function TestEnchantingRemotes()
    print("\n🧪 TESTING ENCHANTING REMOTES...")
    print("=================================")
    
    local net = FindNet()
    if not net then
        print("❌ Network not found!")
        return
    end
    
    local testRemotes = {
        "RF/EnchantItem", "RE/EnchantItem",
        "RF/UseEnchantingTable", "RE/UseEnchantingTable", 
        "RF/RollEnchant", "RE/RollEnchant",
        "RF/ActivateAltar", "RE/ActivateAltar",
        "RF/ActivateEnchantingAltar", "RE/ActivateEnchantingAltar"
    }
    
    for _, remoteName in pairs(testRemotes) do
        local remote = net:FindFirstChild(remoteName)
        if remote then
            print("✅ FOUND: " .. remoteName .. " (" .. remote.ClassName .. ")")
            
            -- Try to call it
            local ok, result = pcall(function()
                if remote:IsA("RemoteFunction") then
                    return remote:InvokeServer()
                else
                    remote:FireServer()
                    return "fired"
                end
            end)
            
            if ok then
                print("  ✅ Call successful: " .. tostring(result))
            else
                print("  ❌ Call failed: " .. tostring(result))
            end
        else
            print("❌ NOT FOUND: " .. remoteName)
        end
    end
    
    print("=================================")
end

-- Manual instructions
local function ShowManualInstructions()
    print("\n📋 MANUAL ENCHANTING DEBUG STEPS:")
    print("==================================")
    print("1. Go to enchanting table/altar in-game")
    print("2. Open Developer Console (F9)")
    print("3. Run: _G.EnchantDebug.FindRemotes()")
    print("4. Try to enchant something manually")
    print("5. Watch console for remote calls")
    print("6. Run: _G.EnchantDebug.TestRemotes()")
    print("7. Use found remote names in main script")
    print("==================================")
end

-- Create floating debug button
local function CreateFloatingButton()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Remove existing
    local existing = playerGui:FindFirstChild("EnchantDebugGUI")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EnchantDebugGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 80, 0, 40)
    button.Position = UDim2.new(1, -90, 0, 200)
    button.Text = "🔍\nEnchant"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 10
    button.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    local clickCount = 0
    button.MouseButton1Click:Connect(function()
        clickCount = clickCount + 1
        if clickCount == 1 then
            FindEnchantingRemotes()
            StarterGui:SetCore("SendNotification", {
                Title = "Enchant Debug", 
                Text = "Remote search complete! Check console (F9)", 
                Duration = 4
            })
        elseif clickCount == 2 then
            TestEnchantingRemotes()
            StarterGui:SetCore("SendNotification", {
                Title = "Enchant Debug", 
                Text = "Remote testing complete! Check console", 
                Duration = 4
            })
        else
            ShowManualInstructions()
            clickCount = 0
            StarterGui:SetCore("SendNotification", {
                Title = "Enchant Debug", 
                Text = "Manual instructions shown in console", 
                Duration = 4
            })
        end
    end)
    
    StarterGui:SetCore("SendNotification", {
        Title = "Enchant Debug Ready", 
        Text = "Click floating button to start debugging", 
        Duration = 5
    })
end

-- Auto-start
CreateFloatingButton()
ShowManualInstructions()

-- Global functions
_G.EnchantDebug = {
    FindRemotes = FindEnchantingRemotes,
    TestRemotes = TestEnchantingRemotes,
    Instructions = ShowManualInstructions
}

print("\n🚀 Enchanting Debug Tool Ready!")
print("• Floating button created (top-right)")
print("• Click 1x: Find enchanting remotes")
print("• Click 2x: Test common remote names") 
print("• Click 3x: Show manual instructions")
print("• Functions: _G.EnchantDebug.FindRemotes()")
print("             _G.EnchantDebug.TestRemotes()")
