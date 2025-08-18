

-- Proteksi executor dan environment
if not game or not game.IsA or not game:IsA("DataModel") then
    return warn("Script hanya bisa dijalankan di Roblox!")
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net or nil
if not Net then
    return warn("Net package tidak ditemukan!")
end

local EquipRod = Net["RE/EquipToolFromHotbar"]
local ChargeRod = Net["RF/ChargeFishingRod"]
local RequestFishing = Net["RF/RequestFishingMinigameStarted"]
local FishingComplete = Net["RE/FishingCompleted"]
local CancelFishing = Net["RF/CancelFishingInputs"]

local autoFishing = false

local function randomWait()
    return math.random(100, 400) / 1000
end

local function notify(msg)
    if game.StarterGui and game.StarterGui.SetCore then
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {
                Title = "Auto Fishing";
                Text = msg;
                Duration = 2;
            })
        end)
    else
        print("[Auto Fishing] " .. msg)
    end
end

function toggleFishing(state)
    autoFishing = state
    notify("Auto Fishing Started!")
    while autoFishing do
        task.wait(randomWait())
        CancelFishing:InvokeServer()
        task.wait(randomWait())
        EquipRod:FireServer(1)
        task.wait(randomWait())
        ChargeRod:InvokeServer(workspace:GetServerTimeNow())
        task.wait(randomWait())
        RequestFishing:InvokeServer(-1.23, 0.98)
        task.wait(0.1)
        FishingComplete:FireServer()
    end
end

-- Mulai auto fishing
toggleFishing(true)
