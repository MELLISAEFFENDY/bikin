@echo off
color 0D
title Remote Event/Function Tester - Fish It (Floating UI)

echo.
echo  ==========================================
echo   🔧 REMOTE EVENT/FUNCTION TESTER
echo   Floating UI Version
echo  ==========================================
echo.

echo  [INFO] Initializing Remote Tester with Floating UI...
timeout /t 2 /nobreak >nul

if exist "remote_tester.lua" (
    echo  [✓] Remote Tester script found
) else (
    echo  [X] Remote Tester script missing!
    echo  [ERROR] Please ensure remote_tester.lua is in this folder
    pause
    exit /b 1
)

echo.
echo  ==========================================
echo   🎨 FLOATING UI FEATURES
echo  ==========================================
echo.
echo  🔧 Floating Toggle Button:
echo    • Always visible floating button with 🔧 icon
echo    • Click to show/hide the main UI
echo    • Draggable anywhere on screen
echo    • Color changes: Purple (hidden) / Green (shown)
echo    • Button shadow for better visibility
echo.
echo  📱 Enhanced User Experience:
echo    • UI starts hidden for clean interface
echo    • Easy toggle access without cluttering screen
echo    • Persistent floating button position
echo    • Smooth show/hide animations
echo    • Non-intrusive design
echo.
echo  🔍 Remote Scanner:
echo    • Scan all RemoteEvents and RemoteFunctions
echo    • Automatic detection from ReplicatedStorage
echo    • Categorized results (Events vs Functions)
echo    • Real-time scanning progress
echo.
echo  🚀 Remote Executor:
echo    • Execute any remote with custom arguments
echo    • Support for RemoteEvents and RemoteFunctions
echo    • Argument parsing (numbers, booleans, strings)
echo    • Error handling and success tracking
echo.
echo  ⚡ Quick Actions:
echo    • PlayFishingEffect - Start fishing effects
echo    • ChargeFishingRod - Charge fishing rod
echo    • SellAllItems - Sell all caught fish
echo    • CancelFishingInputs - Cancel fishing actions
echo.
echo  📋 History ^& Results:
echo    • Execution history with timestamps
echo    • Success/failure tracking
echo    • Return value display
echo    • Scrollable results window
echo.

:menu
echo  ==========================================
echo   🚀 Launch Options
echo  ==========================================
echo.
echo  [1] 🔧 Launch Remote Tester (Floating UI)
echo  [2] 📊 Remote Tester Guide
echo  [3] 🎣 Quick Fish It Remotes
echo  [4] 🔍 Fish It Remote Reference
echo  [5] 🧪 Test Mode (Pre-loaded remotes)
echo  [6] 📱 UI Control Guide
echo  [7] ❌ Exit
echo.

set /p choice="Select option (1-7): "

if "%choice%"=="1" goto launch_tester
if "%choice%"=="2" goto tester_guide
if "%choice%"=="3" goto quick_fish
if "%choice%"=="4" goto remote_reference
if "%choice%"=="5" goto test_mode
if "%choice%"=="6" goto ui_guide
if "%choice%"=="7" goto exit

echo Invalid choice! Please select 1-7.
goto menu

:launch_tester
echo.
echo  [INFO] Launching Remote Tester with Floating UI...
echo  [INFO] Mode: Full remote testing suite
echo  [INFO] UI: Floating toggle button interface
echo.
call :launch_script "floating"
goto post_launch

:tester_guide
echo.
echo  ==========================================
echo   📖 Remote Tester Usage Guide
echo  ==========================================
echo.
echo  🔧 FLOATING BUTTON CONTROLS:
echo.
echo  Basic Usage:
echo  1. 🔧 Purple floating button appears on left side
echo  2. Click button to show the main Remote Tester UI
echo  3. Button turns green when UI is visible
echo  4. Click again to hide UI (button returns to purple)
echo  5. Drag button anywhere on screen for convenience
echo.
echo  Button States:
echo  • 🟣 Purple = UI Hidden
echo  • 🟢 Green = UI Visible
echo  • Draggable = Move anywhere on screen
echo.
echo  🔍 REMOTE TESTING WORKFLOW:
echo.
echo  Step 1 - Scan Remotes:
echo  1. Click floating button to open UI
echo  2. Click "🔍 Scan All Remotes" button
echo  3. Wait for scan to complete
echo  4. Check status shows number of found remotes
echo.
echo  Step 2 - Execute Remote:
echo  1. Enter remote name (e.g. "PlayFishingEffect")
echo  2. Add arguments if needed (e.g. "123, true, test")
echo  3. Click "🚀 RUN REMOTE" button
echo  4. Check execution history for results
echo.
echo  Step 3 - Quick Actions:
echo  1. Use pre-configured buttons for common actions
echo  2. 🎣 PlayFishingEffect - Start fishing
echo  3. ⚡ ChargeFishingRod - Charge rod with power
echo  4. 💰 SellAllItems - Sell all caught fish
echo  5. ❌ CancelFishingInputs - Cancel fishing
echo.
echo  📱 UI MANAGEMENT:
echo.
echo  Smart Interface:
echo  • UI starts hidden for clean game experience
echo  • Floating button always accessible
echo  • Drag button to preferred position
echo  • Close button only hides UI (doesn't destroy)
echo  • Persistent settings and history
echo.
echo  Efficiency Tips:
echo  • Keep UI hidden while playing normally
echo  • Show UI only when testing remotes
echo  • Use quick actions for common tasks
echo  • Monitor history for successful calls
echo.
pause
goto menu

:quick_fish
echo.
echo  [INFO] Quick Fish It Remote Testing...
echo  [INFO] Pre-loading common fishing remotes
echo.

REM Create quick fishing version
echo -- Remote Tester Quick Fish Mode > temp_quick_fish.lua
echo local quickFishMode = true >> temp_quick_fish.lua
echo local preloadedRemotes = { >> temp_quick_fish.lua
echo     "PlayFishingEffect", >> temp_quick_fish.lua
echo     "ChargeFishingRod", >> temp_quick_fish.lua
echo     "SellAllItems", >> temp_quick_fish.lua
echo     "CancelFishingInputs", >> temp_quick_fish.lua
echo     "UpdateAutoFishingState" >> temp_quick_fish.lua
echo } >> temp_quick_fish.lua
echo. >> temp_quick_fish.lua

REM Append main script
type "remote_tester.lua" >> temp_quick_fish.lua

call :launch_script_file "temp_quick_fish.lua"
goto post_launch

:remote_reference
echo.
echo  ==========================================
echo   📚 Fish It Remote Reference
echo  ==========================================
echo.
echo  🎣 FISHING REMOTES:
echo.
echo  PlayFishingEffect:
echo  • Purpose: Start fishing effect/animation
echo  • Arguments: None or effect type
echo  • Usage: Basic fishing action trigger
echo.
echo  ChargeFishingRod:
echo  • Purpose: Charge fishing rod with power
echo  • Arguments: Power level (1-5)
echo  • Usage: Set rod charging power
echo.
echo  CancelFishingInputs:
echo  • Purpose: Cancel current fishing action
echo  • Arguments: None
echo  • Usage: Stop fishing immediately
echo.
echo  UpdateAutoFishingState:
echo  • Purpose: Toggle auto fishing mode
echo  • Arguments: Boolean (true/false)
echo  • Usage: Enable/disable auto fishing
echo.
echo  💰 SHOP ^& INVENTORY REMOTES:
echo.
echo  SellAllItems:
echo  • Purpose: Sell all fish in inventory
echo  • Arguments: None or item filter
echo  • Usage: Quick inventory clearing
echo.
echo  PurchaseItem:
echo  • Purpose: Buy items from shop
echo  • Arguments: Item ID, quantity
echo  • Usage: Shop purchases
echo.
echo  EquipRod:
echo  • Purpose: Equip fishing rod
echo  • Arguments: Rod ID or name
echo  • Usage: Change active fishing rod
echo.
echo  🎮 GAME STATE REMOTES:
echo.
echo  UpdatePlayerData:
echo  • Purpose: Sync player data with server
echo  • Arguments: Data type, value
echo  • Usage: Player progress updates
echo.
echo  ClaimReward:
echo  • Purpose: Claim daily/achievement rewards
echo  • Arguments: Reward ID
echo  • Usage: Collect rewards
echo.
echo  💡 TESTING TIPS:
echo.
echo  Safe Testing:
echo  1. Start with parameter-less remotes
echo  2. Test in safe fishing areas
echo  3. Use small values for numeric arguments
echo  4. Monitor for error messages
echo  5. Check game state changes
echo.
echo  Common Patterns:
echo  • Boolean: true, false
echo  • Numbers: 1, 2, 3 (small values)
echo  • Strings: "test", "default"
echo  • Arrays: Use comma separation
echo.
pause
goto menu

:test_mode
echo.
echo  [INFO] Test Mode - Pre-loaded Common Remotes...
echo  [INFO] Auto-loading known Fish It remotes
echo.

REM Create test mode version
echo -- Remote Tester Test Mode > temp_test_mode.lua
echo local testMode = true >> temp_test_mode.lua
echo local autoLoadRemotes = true >> temp_test_mode.lua
echo. >> temp_test_mode.lua

REM Append main script
type "remote_tester.lua" >> temp_test_mode.lua

echo -- Test mode auto-loading >> temp_test_mode.lua
echo task.spawn(function() >> temp_test_mode.lua
echo     task.wait(5) >> temp_test_mode.lua
echo     print("🧪 Test mode: Auto-scanning remotes...") >> temp_test_mode.lua
echo     scanAllRemotes() >> temp_test_mode.lua
echo     task.wait(2) >> temp_test_mode.lua
echo     print("🧪 Test mode: Ready for remote testing!") >> temp_test_mode.lua
echo end) >> temp_test_mode.lua

call :launch_script_file "temp_test_mode.lua"
goto post_launch

:ui_guide
echo.
echo  ==========================================
echo   📱 Floating UI Control Guide
echo  ==========================================
echo.
echo  🔧 FLOATING BUTTON FEATURES:
echo.
echo  Visual Design:
echo  • 🔧 Wrench icon for easy identification
echo  • Circular design with rounded corners
echo  • Drop shadow for depth and visibility
echo  • Color-coded states for instant feedback
echo.
echo  Button States:
echo  • 🟣 Purple Background = UI Hidden
echo  • 🟢 Green Background = UI Visible
echo  • Hover effects for better interaction
echo  • Smooth color transitions
echo.
echo  Positioning ^& Movement:
echo  • Starts at top-left (20, 100) position
echo  • Fully draggable to any screen position
echo  • Position persists during session
echo  • Shadow follows button movement
echo.
echo  Interaction Methods:
echo  • Left Click = Toggle UI visibility
echo  • Click and Drag = Move button position
echo  • No right-click or special gestures
echo  • Touch-friendly for mobile devices
echo.
echo  🎮 MAIN UI INTERFACE:
echo.
echo  Window Management:
echo  • Starts hidden for clean interface
echo  • Standard close button only hides window
echo  • Main window is draggable by title bar
echo  • Resizable content areas
echo.
echo  Section Organization:
echo  1. 📡 Remote Scanner - Top section
echo  2. 🚀 Remote Executor - Middle section
echo  3. ⚡ Quick Actions - Action buttons
echo  4. 📋 Execution History - Bottom section
echo.
echo  Keyboard Shortcuts:
echo  • F5 = Scan for remotes
echo  • Enter = Execute current remote
echo  • ESC = Hide UI (same as close button)
echo.
echo  💡 USAGE RECOMMENDATIONS:
echo.
echo  Optimal Workflow:
echo  1. Position floating button in convenient location
echo  2. Keep UI hidden during normal gameplay
echo  3. Show UI only when testing remotes
echo  4. Use quick actions for frequent tasks
echo  5. Monitor history for successful patterns
echo.
echo  Performance Tips:
echo  • UI starts hidden to reduce memory usage
echo  • Scanning only when needed
echo  • History limited to recent entries
echo  • Efficient remote caching system
echo.
echo  Accessibility:
echo  • High contrast colors for visibility
echo  • Large click targets for easy access
echo  • Clear visual feedback for all actions
echo  • Consistent UI patterns throughout
echo.
pause
goto menu

:launch_script
echo  [INFO] Preparing Remote Tester script...
echo  [INFO] Mode: %~1 UI with floating toggle button
echo.

REM Create launch script
echo -- Remote Tester Launch with Floating UI > temp_tester_launch.lua
echo local launchMode = "%~1" >> temp_tester_launch.lua
echo local floatingUI = true >> temp_tester_launch.lua
echo. >> temp_tester_launch.lua

REM Append main script
type "remote_tester.lua" >> temp_tester_launch.lua

echo  [INFO] Remote Tester with Floating UI ready
echo  [INFO] Copy and paste this command into Roblox executor:
echo.
echo  ==========================================
color 0A
echo  loadstring(readfile("temp_tester_launch.lua"))()
color 0D
echo  ==========================================
echo.
goto :eof

:launch_script_file
echo  [INFO] Remote Tester script ready
echo  [INFO] Copy and paste this command into Roblox executor:
echo.
echo  ==========================================
color 0A
echo  loadstring(readfile("%~1"))()
color 0D
echo  ==========================================
echo.
goto :eof

:post_launch
echo.
echo  ==========================================
echo   🔧 Remote Tester Launched (Floating UI)!
echo  ==========================================
echo.
echo  Next Steps:
echo.
echo  1. 🎮 Open your Roblox executor
echo  2. 📋 Copy the loadstring command above
echo  3. ✅ Execute in Fish It game
echo  4. 🔧 Look for purple floating button on left side
echo  5. 🖱️ Click floating button to show UI
echo.
echo  🔧 Floating Button Usage:
echo    • Purple 🔧 button = UI Hidden
echo    • Click button = Show Remote Tester UI
echo    • Green 🔧 button = UI Visible
echo    • Click again = Hide UI
echo    • Drag button = Move to preferred position
echo.
echo  🚀 Remote Testing Workflow:
echo    1. Click floating button to open UI
echo    2. Click "🔍 Scan All Remotes"
echo    3. Enter remote name (e.g. PlayFishingEffect)
echo    4. Add arguments if needed
echo    5. Click "🚀 RUN REMOTE"
echo    6. Check execution history for results
echo.
echo  ⚡ Quick Actions Available:
echo    • 🎣 PlayFishingEffect - Start fishing
echo    • ⚡ ChargeFishingRod - Charge rod
echo    • 💰 SellAllItems - Sell fish
echo    • ❌ CancelFishingInputs - Cancel fishing
echo.

:monitor
echo.
echo  ==========================================
echo   📊 Remote Tester Monitor (Floating UI)
echo  ==========================================
echo.
echo  [%date% %time%] Remote Tester Active
echo  Status: Floating UI interface ready
echo.
echo  Current Features:
echo  ✓ Floating toggle button system
echo  ✓ Remote scanner and executor
echo  ✓ Quick action buttons
echo  ✓ Execution history tracking
echo  ✓ Draggable UI elements
echo.
echo  UI State Management:
echo  • Floating button always visible
echo  • Main UI hidden by default
echo  • Toggle functionality active
echo  • Position persistence enabled
echo.
echo  Options:
echo  [1] 🔄 Restart Remote Tester
echo  [2] 🎣 Quick Fish Testing
echo  [3] 📚 Remote Reference
echo  [4] 🛑 Stop Session
echo  [5] 🏠 Back to Menu
echo.

set /p mon_choice="Select option (1-5): "

if "%mon_choice%"=="1" goto menu
if "%mon_choice%"=="2" goto quick_fish
if "%mon_choice%"=="3" goto remote_reference
if "%mon_choice%"=="4" goto stop_session
if "%mon_choice%"=="5" goto menu

echo Invalid choice!
goto monitor

:stop_session
echo.
echo  [INFO] Stopping Remote Tester session...
echo  [INFO] Click the X button on UI or close game
echo.
echo  📊 Session Summary:
echo    • Check execution history in UI
echo    • Note successful remote calls
echo    • Save working remote names
echo    • Document useful arguments
echo.
echo  🔧 Floating Button:
echo    • Button remains active until game closed
echo    • UI can be toggled anytime
echo    • Position saved for session
echo.
pause
goto menu

:exit
echo.
echo  ==========================================
echo   👋 Thanks for using Remote Tester!
echo  ==========================================
echo.
echo  [INFO] Cleaning up temporary files...

if exist "temp_tester_launch.lua" (
    del "temp_tester_launch.lua"
    echo  [✓] Launch file cleaned
)

if exist "temp_quick_fish.lua" (
    del "temp_quick_fish.lua"
    echo  [✓] Quick fish mode file cleaned
)

if exist "temp_test_mode.lua" (
    del "temp_test_mode.lua"
    echo  [✓] Test mode file cleaned
)

echo  [INFO] Remote Tester session ended
echo  [INFO] Remember to close the UI before closing Roblox
echo.
echo  🔧 Remote Tester Summary:
echo    • Floating UI for easy access
echo    • Comprehensive remote testing
echo    • Quick actions for Fish It
echo    • History tracking and results
echo.
echo  💡 Key Features Used:
echo    • 🔧 Always-visible floating button
echo    • 🔍 Remote scanner and discovery
echo    • 🚀 Safe remote execution
echo    • ⚡ Pre-configured quick actions
echo.
echo  🚀 Thank you for using Remote Tester!
echo  Perfect for Fish It remote debugging and testing!
echo.
pause
exit /b 0
