-- simple_enchant_debug.lua
-- Debug tool sederhana untuk enchanting remotes

print("🔍 Simple Enchanting Debug Tool")
print("===============================")

-- Basic safety checks
if not game then
    error("Must run in Roblox!")
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Simple network finder
local function FindRemoteFolder()
    print("🔍 Looking for remote folder...")
    
    -- Common paths where remotes might be
    local paths = {
        ReplicatedStorage:FindFirstChild("net"),
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("RemoteEvents"),
        ReplicatedStorage:FindFirstChild("RemoteFunctions"),
    }
    
    -- Try packages path
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if packages then
        local index = packages:FindFirstChild("_Index")
        if index then
            for _, child in pairs(index:GetChildren()) do
                if child.Name:find("net") then
                    local net = child:FindFirstChild("net")
                    if net then
                        table.insert(paths, net)
                    end
                end
            end
        end
    end
    
    for i, path in pairs(paths) do
        if path then
            print("✅ Found remote folder:", path:GetFullName())
            return path
        end
    end
    
    print("❌ No remote folder found")
    return nil
end

-- List all remotes
local function ListAllRemotes()
    local folder = FindRemoteFolder()
    if not folder then
        print("❌ Cannot find remote folder")
        return
    end
    
    print("\n📋 All Remotes in", folder.Name .. ":")
    print("============================")
    
    local count = 0
    for _, child in pairs(folder:GetChildren()) do
        count = count + 1
        print(count .. ". " .. child.Name .. " (" .. child.ClassName .. ")")
        
        -- Check if name contains enchanting keywords
        local name = child.Name:lower()
        if name:find("enchant") or name:find("altar") or name:find("roll") or name:find("magic") then
            print("   🔮 ^^ POSSIBLE ENCHANTING REMOTE ^^")
        end
    end
    
    if count == 0 then
        print("No remotes found in this folder")
    end
end

-- Test a specific remote
local function TestRemote(remoteName)
    print("\n🧪 Testing remote:", remoteName)
    
    local folder = FindRemoteFolder()
    if not folder then
        print("❌ Cannot find remote folder")
        return
    end
    
    local remote = folder:FindFirstChild(remoteName)
    if not remote then
        print("❌ Remote not found:", remoteName)
        print("💡 Available remotes:")
        for _, child in pairs(folder:GetChildren()) do
            print("   -", child.Name)
        end
        return
    end
    
    print("✅ Remote found:", remote.Name, "(" .. remote.ClassName .. ")")
    
    -- Try to call the remote
    local success, result = pcall(function()
        if remote:IsA("RemoteFunction") then
            print("📞 Calling RemoteFunction...")
            return remote:InvokeServer()
        elseif remote:IsA("RemoteEvent") then
            print("📡 Firing RemoteEvent...")
            remote:FireServer()
            return "Event fired successfully"
        else
            return "Unknown remote type"
        end
    end)
    
    if success then
        print("✅ Success:", tostring(result))
    else
        print("❌ Failed:", tostring(result))
    end
end

-- Auto run
print("\n🚀 Starting automatic scan...")
ListAllRemotes()

print("\n💡 Manual Testing:")
print("To test a remote, use: _G.TestRemote('RemoteName')")
print("Example: _G.TestRemote('RE/RollEnchant')")

-- Export functions
_G.TestRemote = TestRemote
_G.ListAllRemotes = ListAllRemotes
_G.FindRemoteFolder = FindRemoteFolder

print("\n✅ Functions available:")
print("_G.TestRemote('name') - Test specific remote")
print("_G.ListAllRemotes() - List all remotes again")
