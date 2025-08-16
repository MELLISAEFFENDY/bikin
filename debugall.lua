-- debug_remotes.lua
-- Debug tool untuk mencari remotes yang tersedia di Fish It game

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Simple notifier
local function Notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = 5})
    end)
    print("[DEBUG]", title, text)
end

-- Find network folder
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

-- List all remotes with filtering
local function ListAllRemotes()
    print("==========================================")
    print("=== FISH IT REMOTE DEBUG TOOL ===")
    print("==========================================")
    
    local net = FindNet()
    if not net then
        print("[ERROR] Network folder not found!")
        print("Check ReplicatedStorage structure:")
        print("- ReplicatedStorage")
        print("  └─ Packages")
        print("    └─ _Index")
        print("      └─ sleitnick_net@0.2.0")
        print("        └─ net")
        Notify("Debug Error", "Network folder not found!")
        return
    end

    print("[SUCCESS] Network folder found!")
    print("\n=== ALL AVAILABLE REMOTES ===")
    
    local enchantingRemotes = {}
    local boatRemotes = {}
    local weatherRemotes = {}
    local tradeRemotes = {}
    local fishingRemotes = {}
    local otherRemotes = {}
    
    -- Categorize remotes
    for _, child in pairs(net:GetChildren()) do
        local name = child.Name
        local remoteName = name:lower()
        
        if remoteName:find("enchant") or remoteName:find("roll") or remoteName:find("altar") then
            table.insert(enchantingRemotes, {name = name, type = child.ClassName})
        elseif remoteName:find("boat") or remoteName:find("spawn") or remoteName:find("despawn") then
            table.insert(boatRemotes, {name = name, type = child.ClassName})
        elseif remoteName:find("weather") or remoteName:find("event") then
            table.insert(weatherRemotes, {name = name, type = child.ClassName})
        elseif remoteName:find("trade") or remoteName:find("trading") then
            table.insert(tradeRemotes, {name = name, type = child.ClassName})
        elseif remoteName:find("fish") or remoteName:find("rod") or remoteName:find("catch") then
            table.insert(fishingRemotes, {name = name, type = child.ClassName})
        else
            table.insert(otherRemotes, {name = name, type = child.ClassName})
        end
    end
    
    -- Print categorized results
    print("\n🎣 === FISHING REMOTES ===")
    for _, remote in pairs(fishingRemotes) do
        print("  " .. remote.name .. " (" .. remote.type .. ")")
    end
    
    print("\n💎 === ENCHANTING REMOTES ===")
    for _, remote in pairs(enchantingRemotes) do
        print("  " .. remote.name .. " (" .. remote.type .. ")")
    end
    
    print("\n🚢 === BOAT REMOTES ===")
    for _, remote in pairs(boatRemotes) do
        print("  " .. remote.name .. " (" .. remote.type .. ")")
    end
    
    print("\n🌤️ === WEATHER REMOTES ===")
    for _, remote in pairs(weatherRemotes) do
        print("  " .. remote.name .. " (" .. remote.type .. ")")
    end
    
    print("\n🔄 === TRADE REMOTES ===")
    for _, remote in pairs(tradeRemotes) do
        print("  " .. remote.name .. " (" .. remote.type .. ")")
    end
    
    print("\n📦 === OTHER REMOTES ===")
    for _, remote in pairs(otherRemotes) do
        print("  " .. remote.name .. " (" .. remote.type .. ")")
    end
    
    print("\n==========================================")
    print("=== USAGE INSTRUCTIONS ===")
    print("1. Look for enchanting related remotes above")
    print("2. Common patterns to look for:")
    print("   - EnchantTable, EnchantItem, RollEnchant")
    print("   - ActivateAltar, UseTable, StartEnchant")
    print("   - RF/ = RemoteFunction, RE/ = RemoteEvent")
    print("3. Copy the exact remote name to use in script")
    print("==========================================")
    
    Notify("Debug Complete", "Remote list printed to console (F9)")
end

-- Test a specific remote
local function TestRemote(remoteName)
    print("\n=== TESTING REMOTE: " .. remoteName .. " ===")
    
    local net = FindNet()
    if not net then
        print("[ERROR] Network folder not found!")
        return
    end
    
    local remote = net:FindFirstChild(remoteName)
    if not remote then
        print("[ERROR] Remote '" .. remoteName .. "' not found!")
        return
    end
    
    print("[SUCCESS] Remote found!")
    print("Name: " .. remote.Name)
    print("Type: " .. remote.ClassName)
    
    -- Try to invoke/fire the remote
    local ok, result = pcall(function()
        if remote:IsA("RemoteFunction") then
            print("[TEST] Attempting to invoke RemoteFunction...")
            return remote:InvokeServer()
        else
            print("[TEST] Attempting to fire RemoteEvent...")
            remote:FireServer()
            return "Event fired"
        end
    end)
    
    if ok then
        print("[SUCCESS] Remote call successful!")
        print("Result:", tostring(result))
    else
        print("[ERROR] Remote call failed!")
        print("Error:", tostring(result))
    end
end

-- Create simple GUI for easier access
local function CreateDebugGUI()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Remove existing debug GUI if any
    local existing = playerGui:FindFirstChild("RemoteDebugGUI")
    if existing then existing:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RemoteDebugGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200)
    frame.Position = UDim2.new(1, -320, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "🔍 Remote Debug Tool"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = frame
    
    local listBtn = Instance.new("TextButton")
    listBtn.Size = UDim2.new(1, -20, 0, 35)
    listBtn.Position = UDim2.new(0, 10, 0, 40)
    listBtn.Text = "📋 List All Remotes"
    listBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    listBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
    listBtn.Font = Enum.Font.GothamSemibold
    listBtn.TextSize = 12
    listBtn.Parent = frame
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = listBtn
    
    local testInput = Instance.new("TextBox")
    testInput.Size = UDim2.new(1, -20, 0, 25)
    testInput.Position = UDim2.new(0, 10, 0, 85)
    testInput.PlaceholderText = "Enter remote name to test..."
    testInput.Text = ""
    testInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    testInput.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    testInput.Font = Enum.Font.Gotham
    testInput.TextSize = 11
    testInput.Parent = frame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = testInput
    
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(1, -20, 0, 30)
    testBtn.Position = UDim2.new(0, 10, 0, 120)
    testBtn.Text = "🧪 Test Remote"
    testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    testBtn.BackgroundColor3 = Color3.fromRGB(130, 60, 200)
    testBtn.Font = Enum.Font.GothamSemibold
    testBtn.TextSize = 12
    testBtn.Parent = frame
    
    local testCorner = Instance.new("UICorner")
    testCorner.CornerRadius = UDim.new(0, 6)
    testCorner.Parent = testBtn
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -30, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = frame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    
    -- Event handlers
    listBtn.MouseButton1Click:Connect(ListAllRemotes)
    testBtn.MouseButton1Click:Connect(function()
        if testInput.Text ~= "" then
            TestRemote(testInput.Text)
        else
            Notify("Debug", "Enter a remote name to test!")
        end
    end)
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    Notify("Debug Tool", "Remote debug GUI created!")
end

-- Auto-start
print("==========================================")
print("🔍 FISH IT REMOTE DEBUG TOOL LOADED")
print("==========================================")
print("Available functions:")
print("• _G.DebugRemotes.ListAll() - List all remotes")
print("• _G.DebugRemotes.Test('RemoteName') - Test specific remote")
print("• _G.DebugRemotes.CreateGUI() - Create debug GUI")
print("==========================================")

-- Create GUI automatically
CreateDebugGUI()

-- Expose functions globally
_G.DebugRemotes = {
    ListAll = ListAllRemotes,
    Test = TestRemote,
    CreateGUI = CreateDebugGUI
}

Notify("Debug Tool Ready", "GUI created! Check top-right corner")
