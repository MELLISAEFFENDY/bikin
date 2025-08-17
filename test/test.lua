-- test.lua
-- Testing berbagai gerakan character

-- Load movement systems
local generalMovements = loadstring(readfile("movement_examples.lua"))()
local fishingMovements = loadstring(readfile("fishing_movements.lua"))()

print("🎮 Testing Character Movements")

-- ========================================
-- TEST BASIC MOVEMENTS
-- ========================================

print("\n=== TESTING BASIC MOVEMENTS ===")

-- Test 1: Simple Jump
print("Test 1: Jump")
generalMovements.jump()
task.wait(2)

-- Test 2: Walk forward
print("Test 2: Walk forward")
generalMovements.walkTo(Vector3.new(0, 0, 1), 20)
task.wait(3)
generalMovements.stop()

-- Test 3: Teleport
print("Test 3: Teleport forward")
generalMovements.teleportForward(10)
task.wait(2)

-- ========================================
-- TEST ANTI-AFK MOVEMENTS
-- ========================================

print("\n=== TESTING ANTI-AFK MOVEMENTS ===")

-- Test 4: Anti-AFK Jump
print("Test 4: Anti-AFK Jump")
fishingMovements.antiAfk.jump()
task.wait(2)

-- Test 5: Small step movement
print("Test 5: Small step movement")
fishingMovements.antiAfk.smallStep()
task.wait(3)

-- Test 6: Look around
print("Test 6: Look around")
fishingMovements.antiAfk.lookAround()
task.wait(3)

-- Test 7: Random Anti-AFK
print("Test 7: Random Anti-AFK")
fishingMovements.randomAntiAfk()
task.wait(3)

-- ========================================
-- TEST ADVANCED MOVEMENTS
-- ========================================

print("\n=== TESTING ADVANCED MOVEMENTS ===")

-- Test 8: Circle walk
print("Test 8: Circle walk (5 seconds)")
generalMovements.circleWalk(5, 16, 5)

-- Test 9: Random movement
print("Test 9: Random movement (5 seconds)")
generalMovements.randomMove(5, 20)

-- Test 10: Natural idle movement
print("Test 10: Natural idle movement")
for i = 1, 3 do
    fishingMovements.naturalIdle()
    task.wait(2)
end

-- ========================================
-- TEST INPUT SIMULATION
-- ========================================

print("\n=== TESTING INPUT SIMULATION ===")

-- Test 11: Simulate space key (jump)
print("Test 11: Simulate space key")
generalMovements.keyPress(Enum.KeyCode.Space, 0.1)
task.wait(2)

-- Test 12: Simulate WASD movement
print("Test 12: Simulate WASD movement")
generalMovements.keyPress(Enum.KeyCode.W, 1) -- Forward
task.wait(0.5)
generalMovements.keyPress(Enum.KeyCode.A, 1) -- Left
task.wait(0.5)
generalMovements.keyPress(Enum.KeyCode.S, 1) -- Backward
task.wait(0.5)
generalMovements.keyPress(Enum.KeyCode.D, 1) -- Right
task.wait(0.5)

-- ========================================
-- TEST FISHING SPECIFIC
-- ========================================

print("\n=== TESTING FISHING SPECIFIC ===")

-- Test 13: Check nearby players
print("Test 13: Check for nearby players")
local foundNearbyPlayer = fishingMovements.dodgePlayers(15)
if foundNearbyPlayer then
    print("✅ Dodged nearby player")
else
    print("ℹ️ No nearby players found")
end

-- Test 14: Smart positioning (example)
print("Test 14: Smart positioning test")
if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    local currentPos = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
    local testWaterPos = currentPos + Vector3.new(10, 0, 10)
    fishingMovements.smartPosition(testWaterPos)
end

print("\n✅ All movement tests completed!")
print("🎯 These movements can be integrated into fishing scripts for:")
print("  • Anti-AFK functionality")
print("  • Player avoidance")
print("  • Automatic positioning")
print("  • Natural-looking behavior")
print("  • Emergency escape scenarios")

-- ========================================
-- CONTINUOUS DEMO MODE
-- ========================================

local function startDemoMode()
    print("\n🎪 Starting continuous demo mode...")
    print("Press 'Q' to stop demo")
    
    local demoRunning = true
    
    -- Stop demo on Q key
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Q then
            demoRunning = false
            print("🛑 Demo mode stopped")
        end
    end)
    
    -- Demo loop
    spawn(function()
        while demoRunning do
            -- Random anti-AFK every 10-30 seconds
            local waitTime = math.random(10, 30)
            task.wait(waitTime)
            
            if demoRunning then
                fishingMovements.randomAntiAfk()
            end
        end
    end)
    
    -- Natural idle movements every 5-15 seconds
    spawn(function()
        while demoRunning do
            local waitTime = math.random(5, 15)
            task.wait(waitTime)
            
            if demoRunning then
                fishingMovements.naturalIdle()
            end
        end
    end)
end

-- Uncomment to start demo mode
-- startDemoMode()

print("\n💡 To start continuous demo: startDemoMode()")
print("💡 To test specific movement: use functions from generalMovements or fishingMovements")
