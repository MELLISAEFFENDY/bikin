-- fishing_movements.lua
-- Gerakan khusus untuk game fishing

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ========================================
-- FISHING SPECIFIC MOVEMENTS
-- ========================================

-- Anti-AFK movements (berbagai variasi)
local AntiAFKMoves = {
    -- Simple jump
    jump = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Jump = true
            print("🦘 Anti-AFK: Jump performed")
        end
    end,
    
    -- Small steps (jalan kecil)
    smallStep = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local humanoid = LocalPlayer.Character.Humanoid
            local rootPart = LocalPlayer.Character.HumanoidRootPart
            
            -- Random small direction
            local direction = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)).Unit
            local targetPos = rootPart.Position + (direction * 2) -- 2 studs only
            
            humanoid:MoveTo(targetPos)
            print("👣 Anti-AFK: Small step taken")
            
            -- Return to original position after 1 second
            task.wait(1)
            humanoid:MoveTo(rootPart.Position)
        end
    end,
    
    -- Look around (menoleh kiri-kanan)
    lookAround = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = LocalPlayer.Character.HumanoidRootPart
            local originalCFrame = rootPart.CFrame
            
            -- Look left
            local leftCFrame = originalCFrame * CFrame.Angles(0, math.rad(45), 0)
            rootPart.CFrame = leftCFrame
            
            task.wait(0.5)
            
            -- Look right
            local rightCFrame = originalCFrame * CFrame.Angles(0, math.rad(-45), 0)
            rootPart.CFrame = rightCFrame
            
            task.wait(0.5)
            
            -- Return to original
            rootPart.CFrame = originalCFrame
            print("👀 Anti-AFK: Looked around")
        end
    end,
    
    -- Crouch toggle (if game supports it)
    crouchToggle = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local humanoid = LocalPlayer.Character.Humanoid
            
            -- Simulate Ctrl key for crouching
            pcall(function()
                local VirtualInputManager = game:GetService("VirtualInputManager")
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                
                task.wait(1)
                
                -- Toggle back
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
            end)
            print("🏃 Anti-AFK: Crouch toggled")
        end
    end
}

-- Auto-walk to fishing spots
local function walkToFishingSpot(spotName)
    local fishingSpots = {
        ["Moosewood"] = Vector3.new(-1463, 131, 213),
        ["Snowcap"] = Vector3.new(2648, 140, 2522),
        ["Mushgrove"] = Vector3.new(2500, 131, -721),
        ["Roslit"] = Vector3.new(-1742, 131, -1006),
        ["Sunstone"] = Vector3.new(-934, 131, -1113),
        ["Forsaken"] = Vector3.new(-2895, 131, 1717),
        ["Altar"] = Vector3.new(1306, -806, -105)
    }
    
    local targetPosition = fishingSpots[spotName]
    if not targetPosition then
        print("❌ Unknown fishing spot:", spotName)
        return false
    end
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
        print("❌ Character not found")
        return false
    end
    
    local humanoid = LocalPlayer.Character.Humanoid
    print("🎣 Walking to fishing spot:", spotName)
    
    humanoid:MoveTo(targetPosition)
    humanoid.MoveToFinished:Wait()
    print("✅ Arrived at", spotName)
    return true
end

-- Auto-dodge players (avoid other players)
local function autoDodgeNearbyPlayers(detectionRadius)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local myPosition = LocalPlayer.Character.HumanoidRootPart.Position
    local humanoid = LocalPlayer.Character.Humanoid
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local theirPosition = player.Character.HumanoidRootPart.Position
            local distance = (myPosition - theirPosition).Magnitude
            
            if distance < (detectionRadius or 10) then
                -- Move away from player
                local awayDirection = (myPosition - theirPosition).Unit
                local safePosition = myPosition + (awayDirection * 15)
                
                humanoid:MoveTo(safePosition)
                print("🚶 Dodging player:", player.Name, "Distance:", math.floor(distance))
                return true
            end
        end
    end
    
    return false
end

-- Smart positioning for fishing
local function smartFishingPosition(targetWaterPosition)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    local humanoid = LocalPlayer.Character.Humanoid
    
    -- Calculate optimal position (3-5 studs from water edge)
    local direction = (targetWaterPosition - rootPart.Position).Unit
    local optimalPosition = targetWaterPosition - (direction * 4)
    
    -- Move to optimal position
    humanoid:MoveTo(optimalPosition)
    humanoid.MoveToFinished:Wait()
    
    -- Face the water
    local lookDirection = (targetWaterPosition - rootPart.Position).Unit
    local targetCFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + lookDirection)
    rootPart.CFrame = targetCFrame
    
    print("🎯 Positioned for optimal fishing")
    return true
end

-- Emergency escape (if detected/stuck)
local function emergencyEscape()
    if not LocalPlayer.Character then return end
    
    print("🚨 Emergency escape activated!")
    
    -- Method 1: Random teleport nearby
    if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        local randomOffset = Vector3.new(
            math.random(-50, 50),
            10,
            math.random(-50, 50)
        )
        rootPart.CFrame = CFrame.new(rootPart.Position + randomOffset)
        print("📍 Emergency teleport executed")
    end
    
    -- Method 2: Reset character (last resort)
    task.wait(2)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = 0
        print("💀 Character reset for safety")
    end
end

-- Patrol movement (bergerak patrol untuk terlihat natural)
local function startPatrolMovement(waypoints, speed)
    if not LocalPlayer.Character then return end
    
    local humanoid = LocalPlayer.Character.Humanoid
    humanoid.WalkSpeed = speed or 16
    
    local currentWaypoint = 1
    
    print("🚶 Starting patrol movement with", #waypoints, "waypoints")
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
            connection:Disconnect()
            return
        end
        
        local targetWaypoint = waypoints[currentWaypoint]
        if not targetWaypoint then
            connection:Disconnect()
            print("⏹️ Patrol completed")
            return
        end
        
        humanoid:MoveTo(targetWaypoint)
        
        -- Check if reached waypoint
        if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - targetWaypoint).Magnitude
            if distance < 5 then
                currentWaypoint = currentWaypoint + 1
                if currentWaypoint > #waypoints then
                    currentWaypoint = 1 -- Loop back to start
                end
                print("📍 Reached waypoint", currentWaypoint - 1)
            end
        end
    end)
    
    return connection
end

-- ========================================
-- ADVANCED ANTI-DETECTION MOVEMENTS
-- ========================================

-- Random anti-AFK with multiple behaviors
local function randomAntiAFK()
    local behaviors = {
        AntiAFKMoves.jump,
        AntiAFKMoves.smallStep,
        AntiAFKMoves.lookAround,
        AntiAFKMoves.crouchToggle
    }
    
    -- Pick random behavior
    local randomBehavior = behaviors[math.random(1, #behaviors)]
    randomBehavior()
    
    print("🎲 Random anti-AFK behavior executed")
end

-- Natural-looking idle movements
local function naturalIdleMovement()
    if not LocalPlayer.Character then return end
    
    local movements = {
        function() -- Slight position shift
            if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local rootPart = LocalPlayer.Character.HumanoidRootPart
                local randomOffset = Vector3.new(
                    math.random(-1, 1) * 0.5,
                    0,
                    math.random(-1, 1) * 0.5
                )
                rootPart.CFrame = rootPart.CFrame + randomOffset
            end
        end,
        
        function() -- Micro jump
            if LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local rootPart = LocalPlayer.Character.HumanoidRootPart
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(0, 1000, 0)
                bodyVelocity.Velocity = Vector3.new(0, 5, 0)
                bodyVelocity.Parent = rootPart
                
                task.wait(0.1)
                bodyVelocity:Destroy()
            end
        end,
        
        function() -- Head movement
            if LocalPlayer.Character:FindFirstChild("Head") then
                local head = LocalPlayer.Character.Head
                local originalCFrame = head.CFrame
                head.CFrame = head.CFrame * CFrame.Angles(
                    math.rad(math.random(-5, 5)),
                    math.rad(math.random(-10, 10)),
                    0
                )
                task.wait(0.5)
                head.CFrame = originalCFrame
            end
        end
    }
    
    -- Execute random natural movement
    local randomMovement = movements[math.random(1, #movements)]
    randomMovement()
    
    print("🌿 Natural idle movement performed")
end

-- ========================================
-- USAGE EXAMPLES
-- ========================================

print("🎣 Fishing Movement System Loaded!")
print("📋 Available functions:")
print("  • AntiAFKMoves.jump() / smallStep() / lookAround() / crouchToggle()")
print("  • walkToFishingSpot('spotName') - Auto walk to fishing spots")
print("  • autoDodgeNearbyPlayers(radius) - Avoid other players")
print("  • smartFishingPosition(waterPos) - Optimal fishing positioning")
print("  • emergencyEscape() - Emergency escape if detected")
print("  • startPatrolMovement(waypoints, speed) - Patrol movement")
print("  • randomAntiAFK() - Random anti-AFK behavior")
print("  • naturalIdleMovement() - Natural-looking idle movements")

-- Return functions for external use
return {
    antiAfk = AntiAFKMoves,
    walkToSpot = walkToFishingSpot,
    dodgePlayers = autoDodgeNearbyPlayers,
    smartPosition = smartFishingPosition,
    emergencyEscape = emergencyEscape,
    patrol = startPatrolMovement,
    randomAntiAfk = randomAntiAFK,
    naturalIdle = naturalIdleMovement
}
