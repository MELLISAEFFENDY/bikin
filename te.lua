-- Fish It AutoFish Control
-- Script untuk mengontrol AutoFish Fish It (On/Off)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Fish It Control",
            Text = tostring(msg),
            Duration = 3
        })
        print("[Fish It Control] " .. tostring(msg))
    end)
end

-- Get AutoFish remote
local UpdateAutoFish
pcall(function()
    UpdateAutoFish = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RF.UpdateAutoFishingState
end)

if not UpdateAutoFish then
    notify("❌ AutoFish remote not found!")
    return
end

-- Control functions
local function EnableAutoFish()
    pcall(function()
        local result = UpdateAutoFish:InvokeServer(true)
        notify("🎣 AutoFish ENABLED! Result: " .. tostring(result))
    end)
end

local function DisableAutoFish()
    pcall(function()
        local result = UpdateAutoFish:InvokeServer(false)
        notify("🛑 AutoFish DISABLED! Result: " .. tostring(result))
    end)
end

-- Global access
_G.FishItControl = {
    Enable = EnableAutoFish,
    Disable = DisableAutoFish,
    On = EnableAutoFish,
    Off = DisableAutoFish
}

notify("🎮 Fish It AutoFish Control loaded!")
notify("📖 Use: _G.FishItControl.On() or _G.FishItControl.Off()")

-- Auto-enable for quick testing
EnableAutoFish()
