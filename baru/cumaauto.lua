

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
    return math.random(50, 100) / 1000
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
        local ok, err
        task.wait(randomWait())
        ok, err = pcall(function()
            print("[DEBUG] CancelFishing")
            CancelFishing:InvokeServer()
        end)
        if not ok then warn("[ERROR] CancelFishing: "..tostring(err)) end

        task.wait(randomWait())
        ok, err = pcall(function()
            print("[DEBUG] EquipRod")
            EquipRod:FireServer(1)
        end)
        if not ok then warn("[ERROR] EquipRod: "..tostring(err)) end

        task.wait(randomWait())
        ok, err = pcall(function()
            print("[DEBUG] ChargeRod")
            ChargeRod:InvokeServer(workspace:GetServerTimeNow())
        end)
        if not ok then warn("[ERROR] ChargeRod: "..tostring(err)) end

        task.wait(randomWait())
        ok, err = pcall(function()
            print("[DEBUG] RequestFishing")
            RequestFishing:InvokeServer(-1.23, 0.98)
        end)
        if not ok then warn("[ERROR] RequestFishing: "..tostring(err)) end

        task.wait(0.1+ randomWait())
        ok, err = pcall(function()
            print("[DEBUG] FishingComplete")
            FishingComplete:FireServer()
        end)
        if not ok then warn("[ERROR] FishingComplete: "..tostring(err)) end
    end
end

-- Mulai auto fishing
toggleFishing(true)
