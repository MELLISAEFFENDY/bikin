-- movement_examples.lua
-- Contoh berbagai gerakan character yang bisa dilakukan dengan script Lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- ========================================
-- 1. BASIC MOVEMENTS (Gerakan Dasar)
-- ========================================

-- Jump (Lompat)
local function performJump()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Jump = true
        print("✅ Jump performed!")
    end
end

-- Walk/Run in direction (Jalan/Lari ke arah tertentu)
local function walkToDirection(direction, speed)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        humanoid:Move(direction, true) -- Move in specific direction
        humanoid.WalkSpeed = speed or 16 -- Set walking speed
        print("🚶 Walking to direction:", direction, "Speed:", speed)
    end
end

-- Stop movement (Berhenti)
local function stopMovement()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), true)
        print("🛑 Movement stopped")
    end
end

-- ========================================
-- 2. TELEPORTATION (Teleportasi)
-- ========================================

-- Teleport to specific position
local function teleportTo(position)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
        print("📍 Teleported to:", position)
    end
end

-- Teleport forward by distance
local function teleportForward(distance)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local rootPart = LocalPlayer.Character.HumanoidRootPart
        local forwardDirection = rootPart.CFrame.LookVector
        local newPosition = rootPart.Position + (forwardDirection * distance)
        rootPart.CFrame = CFrame.new(newPosition, newPosition + forwardDirection)
        print("⬆️ Teleported forward by", distance, "units")
    end
end

-- ========================================
-- 3. ADVANCED MOVEMENTS (Gerakan Lanjutan)
-- ========================================

-- Fly mode (Terbang)
local function enableFly(speed)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    local humanoid = LocalPlayer.Character.Humanoid
    
    -- Create BodyVelocity for flying
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    
    -- Disable default physics
    humanoid.PlatformStand = true
    
    print("✈️ Fly mode enabled! Speed:", speed or 50)
    return bodyVelocity
end

-- Noclip mode (Tembus dinding)
local function enableNoclip()
    if not LocalPlayer.Character then return end
    
    for _, part in pairs(LocalPlayer.Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    print("👻 Noclip enabled!")
end

local function disableNoclip()
    if not LocalPlayer.Character then return end
    
    for _, part in pairs(LocalPlayer.Character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = true
        end
    end
    print("🚫 Noclip disabled!")
end

-- ========================================
-- 4. SMOOTH MOVEMENTS (Gerakan Halus)
-- ========================================

-- Smooth walk to target position
local function smoothWalkTo(targetPosition, duration)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local humanoid = LocalPlayer.Character.Humanoid
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    
    -- Use Humanoid:MoveTo for pathfinding
    humanoid:MoveTo(targetPosition)
    print("🎯 Walking smoothly to:", targetPosition)
    
    -- Optional: Wait for movement to complete
    humanoid.MoveToFinished:Wait()
    print("✅ Arrived at destination!")
end

-- Smooth rotation
local function smoothRotateTo(targetLookDirection, duration)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    local currentCFrame = rootPart.CFrame
    local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + targetLookDirection)
    
    -- Use TweenService for smooth rotation
    local tweenInfo = TweenInfo.new(duration or 1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    print("🔄 Rotating smoothly to direction:", targetLookDirection)
end

-- ========================================
-- 5. SPECIAL MOVEMENTS (Gerakan Khusus)
-- ========================================

-- Auto-walk in circle
local function autoCircleWalk(radius, speed, duration)
    if not LocalPlayer.Character then return end
    
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    local humanoid = LocalPlayer.Character.Humanoid
    local centerPosition = rootPart.Position
    local angle = 0
    
    humanoid.WalkSpeed = speed or 16
    
    print("🔄 Starting circle walk - Radius:", radius, "Speed:", speed, "Duration:", duration)
    
    local connection
    connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            connection:Disconnect()
            return
        end
        
        angle = angle + deltaTime * (speed / radius)
        local x = centerPosition.X + math.cos(angle) * radius
        local z = centerPosition.Z + math.sin(angle) * radius
        local targetPosition = Vector3.new(x, centerPosition.Y, z)
        
        humanoid:MoveTo(targetPosition)
    end)
    
    -- Stop after duration
    task.wait(duration or 10)
    connection:Disconnect()
    stopMovement()
    print("⏹️ Circle walk completed")
end

-- Random movement
local function randomMovement(duration, speed)
    if not LocalPlayer.Character then return end
    
    local humanoid = LocalPlayer.Character.Humanoid
    local rootPart = LocalPlayer.Character.HumanoidRootPart
    
    humanoid.WalkSpeed = speed or 16
    print("🎲 Starting random movement for", duration, "seconds")
    
    local startTime = tick()
    local connection
    
    connection = RunService.Heartbeat:Connect(function()
        if tick() - startTime >= duration then
            connection:Disconnect()
            stopMovement()
            print("⏹️ Random movement completed")
            return
        end
        
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            connection:Disconnect()
            return
        end
        
        -- Generate random direction every 2 seconds
        if math.floor(tick() - startTime) % 2 == 0 then
            local randomDirection = Vector3.new(
                math.random(-1, 1),
                0,
                math.random(-1, 1)
            ).Unit
            
            local targetPosition = rootPart.Position + (randomDirection * 10)
            humanoid:MoveTo(targetPosition)
        end
    end)
end

-- ========================================
-- 6. ANIMATION CONTROLS (Kontrol Animasi)
-- ========================================

-- Play custom animation
local function playAnimation(animationId)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = LocalPlayer.Character.Humanoid
    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. animationId
    
    local animationTrack = humanoid:LoadAnimation(animation)
    animationTrack:Play()
    
    print("🎭 Playing animation:", animationId)
    return animationTrack
end

-- Emote
local function playEmote(emoteName)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
        return
    end
    
    local humanoid = LocalPlayer.Character.Humanoid
    humanoid:PlayEmote(emoteName)
    print("😄 Playing emote:", emoteName)
end

-- ========================================
-- 7. INPUT SIMULATION (Simulasi Input)
-- ========================================

-- Simulate key press
local function simulateKeyPress(keyCode, duration)
    local VirtualInputManager = game:GetService("VirtualInputManager")
    
    -- Press key
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    print("⌨️ Key pressed:", keyCode.Name)
    
    -- Hold for duration
    task.wait(duration or 0.1)
    
    -- Release key
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    print("⌨️ Key released:", keyCode.Name)
end

-- Simulate mouse click
local function simulateMouseClick(position)
    local VirtualInputManager = game:GetService("VirtualInputManager")
    
    -- Move mouse to position
    VirtualInputManager:SendMouseMoveEvent(position.X, position.Y, game)
    
    -- Click
    VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 1)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 1)
    
    print("🖱️ Mouse clicked at:", position)
end

-- ========================================
-- 8. EXAMPLE USAGE (Contoh Penggunaan)
-- ========================================

print("🎮 Movement Examples Loaded!")
print("📋 Available functions:")
print("  • performJump() - Jump")
print("  • walkToDirection(Vector3, speed) - Walk to direction")
print("  • teleportTo(Vector3) - Teleport to position")
print("  • teleportForward(distance) - Teleport forward")
print("  • enableFly(speed) - Enable fly mode")
print("  • enableNoclip() / disableNoclip() - Toggle noclip")
print("  • smoothWalkTo(Vector3, duration) - Smooth pathfinding")
print("  • autoCircleWalk(radius, speed, duration) - Auto circle walk")
print("  • randomMovement(duration, speed) - Random movement")
print("  • playAnimation(animationId) - Play custom animation")
print("  • simulateKeyPress(keyCode, duration) - Simulate key press")

-- Example usage:
--[[
-- Jump
performJump()

-- Walk forward
walkToDirection(Vector3.new(0, 0, 1), 20)

-- Teleport to spawn
teleportTo(Vector3.new(0, 10, 0))

-- Enable fly mode
local flyControl = enableFly(50)

-- Circle walk for 15 seconds
autoCircleWalk(10, 16, 15)

-- Random movement for 30 seconds
randomMovement(30, 20)

-- Simulate space key press (jump)
simulateKeyPress(Enum.KeyCode.Space, 0.1)
--]]

return {
    jump = performJump,
    walkTo = walkToDirection,
    stop = stopMovement,
    teleport = teleportTo,
    teleportForward = teleportForward,
    fly = enableFly,
    noclip = enableNoclip,
    disableNoclip = disableNoclip,
    smoothWalk = smoothWalkTo,
    smoothRotate = smoothRotateTo,
    circleWalk = autoCircleWalk,
    randomMove = randomMovement,
    animate = playAnimation,
    emote = playEmote,
    keyPress = simulateKeyPress,
    mouseClick = simulateMouseClick
}
