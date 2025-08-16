-- Fish It Quick AutoFish Test
-- Simple script untuk test built-in AutoFish function

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Quick notification
local function notify(msg)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Fish It Test",
            Text = tostring(msg),
            Duration = 3
        })
        print("[Fish It] " .. tostring(msg))
    end)
end

-- Test built-in AutoFish
notify("🔄 Testing Fish It built-in AutoFish...")

pcall(function()
    -- Berdasarkan debug results
    local UpdateAutoFish = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RF.UpdateAutoFishingState
    
    if UpdateAutoFish then
        notify("✅ Found UpdateAutoFishingState remote!")
        
        -- Try to activate AutoFish
        local success, result = pcall(function()
            return UpdateAutoFish:InvokeServer(true)
        end)
        
        if success then
            notify("🎣 AutoFish activated! Result: " .. tostring(result))
        else
            notify("❌ AutoFish activation failed: " .. tostring(result))
        end
    else
        notify("❌ UpdateAutoFishingState remote not found!")
    end
end)

-- Test auto sell
task.wait(2)
notify("💰 Testing auto sell function...")

pcall(function()
    local SellAll = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RF.SellAllItems
    
    if SellAll then
        notify("✅ Found SellAllItems remote!")
        
        local success, result = pcall(function()
            return SellAll:InvokeServer()
        end)
        
        if success then
            notify("💰 Sell all executed! Result: " .. tostring(result))
        else
            notify("❌ Sell all failed: " .. tostring(result))
        end
    else
        notify("❌ SellAllItems remote not found!")
    end
end)

-- Monitor fish caught events
task.wait(1)
notify("👁️ Setting up event monitoring...")

pcall(function()
    local FishCaught = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RE.FishCaught
    
    if FishCaught then
        FishCaught.OnClientEvent:Connect(function(...)
            local args = {...}
            notify("🐟 Fish caught! Args: " .. table.concat(args, ", "))
        end)
        notify("👁️ Fish caught monitoring active!")
    end
    
    local FishingCompleted = ReplicatedStorage.Packages._Index.sleitnick_net@0.2.0.net.RE.FishingCompleted
    
    if FishingCompleted then
        FishingCompleted.OnClientEvent:Connect(function(...)
            local args = {...}
            notify("✅ Fishing completed! Args: " .. table.concat(args, ", "))
        end)
        notify("👁️ Fishing completion monitoring active!")
    end
end)

notify("🚀 Fish It test script loaded! Watch for fishing events...")
