@echo off
color 0E
title ModuleScript Analyzer - Fish It (Floating UI)

echo.
echo  ==========================================
echo   📁 MODULESCRIPT ANALYZER
echo   Floating UI Version
echo  ==========================================
echo.

echo  [INFO] Initializing ModuleScript Analyzer with Floating UI...
timeout /t 2 /nobreak >nul

if exist "module_analyzer.lua" (
    echo  [✓] Module Analyzer script found
) else (
    echo  [X] Module Analyzer script missing!
    echo  [ERROR] Please ensure module_analyzer.lua is in this folder
    pause
    exit /b 1
)

echo.
echo  ==========================================
echo   🎨 FLOATING UI FEATURES
echo  ==========================================
echo.
echo  📁 Floating Toggle Button:
echo    • Always visible floating button with 📁 icon
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
echo  🎯 AUTOFISHINGCONTROLLER ANALYSIS
echo  ==========================================
echo.
echo  📁 AutoFishingController Details:
echo    • Location: ReplicatedStorage.Controllers.AutoFishingController
echo    • Type: ModuleScript (requires loading)
echo    • Purpose: Auto fishing functionality controller
echo    • Access: require() method needed
echo.
echo  🔍 Expected Methods/Properties:
echo    • StartAutoFishing() - Start auto fishing
echo    • StopAutoFishing() - Stop auto fishing
echo    • ToggleAutoFishing() - Toggle auto fishing state
echo    • IsAutoFishing - Current state property
echo    • SetFishingMode() - Set fishing mode
echo    • GetFishingSettings() - Get current settings
echo.
echo  💡 Analysis Strategy:
echo    1. Scan all ModuleScripts in ReplicatedStorage
echo    2. Load AutoFishingController via require()
echo    3. Analyze all available methods and properties
echo    4. Test method calls with different arguments
echo    5. Monitor results and side effects
echo.

:menu
echo  ==========================================
echo   🚀 Launch Options
echo  ==========================================
echo.
echo  [1] 📁 Launch Module Analyzer (Floating UI)
echo  [2] 🎣 Quick AutoFishingController Analysis
echo  [3] 🔍 Scan All Controllers
echo  [4] 📖 AutoFishingController Guide
echo  [5] 🧪 Experimental Mode
echo  [6] 📱 UI Control Guide
echo  [7] 📚 Module Reference
echo  [8] ❌ Exit
echo.

set /p choice="Select option (1-8): "

if "%choice%"=="1" goto launch_analyzer
if "%choice%"=="2" goto quick_autofish
if "%choice%"=="3" goto scan_controllers
if "%choice%"=="4" goto autofish_guide
if "%choice%"=="5" goto experimental_mode
if "%choice%"=="6" goto ui_guide
if "%choice%"=="7" goto module_reference
if "%choice%"=="8" goto exit

echo Invalid choice! Please select 1-8.
goto menu

:launch_analyzer
echo.
echo  [INFO] Launching Module Analyzer with Floating UI...
echo  [INFO] Mode: Full ModuleScript analysis
echo  [INFO] UI: Floating toggle button interface
echo  [INFO] Target: All ModuleScripts
echo.
call :launch_script "floating"
goto post_launch

:quick_autofish
echo.
echo  [INFO] Quick AutoFishingController Analysis...
echo  [INFO] Mode: AutoFish focused with Floating UI
echo  [INFO] Auto-loading AutoFishingController
echo.

REM Create AutoFish specific version
echo -- Module Analyzer AutoFish Mode (Floating UI) > temp_autofish_analyzer.lua
echo local autoFishMode = true >> temp_autofish_analyzer.lua
echo local targetModule = "AutoFishingController" >> temp_autofish_analyzer.lua
echo local floatingUI = true >> temp_autofish_analyzer.lua
echo. >> temp_autofish_analyzer.lua

REM Append main script
type "module_analyzer.lua" >> temp_autofish_analyzer.lua

echo -- Auto-load AutoFishingController >> temp_autofish_analyzer.lua
echo task.spawn(function() >> temp_autofish_analyzer.lua
echo     task.wait(3) >> temp_autofish_analyzer.lua
echo     if loadModule then >> temp_autofish_analyzer.lua
echo         loadModule("AutoFishingController") >> temp_autofish_analyzer.lua
echo         if updateMethods then >> temp_autofish_analyzer.lua
echo             updateMethods("AutoFishingController") >> temp_autofish_analyzer.lua
echo         end >> temp_autofish_analyzer.lua
echo     end >> temp_autofish_analyzer.lua
echo end) >> temp_autofish_analyzer.lua

call :launch_script_file "temp_autofish_analyzer.lua"
goto post_launch

:scan_controllers
echo.
echo  [INFO] Scanning All Controllers with Floating UI...
echo  [INFO] Target: Controllers folder
echo  [INFO] Analysis: All controller modules
echo.

REM Create controller scan version
echo -- Module Analyzer Controller Scan (Floating UI) > temp_controller_scan.lua
echo local controllerMode = true >> temp_controller_scan.lua
echo local floatingUI = true >> temp_controller_scan.lua
echo local targetControllers = { >> temp_controller_scan.lua
echo     "AutoFishingController", >> temp_controller_scan.lua
echo     "FishingController", >> temp_controller_scan.lua
echo     "BaitShopController", >> temp_controller_scan.lua
echo     "RodShopController" >> temp_controller_scan.lua
echo } >> temp_controller_scan.lua
echo. >> temp_controller_scan.lua

REM Append main script
type "module_analyzer.lua" >> temp_controller_scan.lua

call :launch_script_file "temp_controller_scan.lua"
goto post_launch

:autofish_guide
echo.
echo  ==========================================
echo   📖 AutoFishingController Usage Guide
echo  ==========================================
echo.
echo  🎯 FLOATING UI WORKFLOW:
echo.
echo  Step 1 - Access UI:
echo  1. 📁 Purple floating button appears on left side
echo  2. Click button to show Module Analyzer UI
echo  3. Button turns green when UI is visible
echo  4. Drag button to convenient position if needed
echo.
echo  Step 2 - Module Analysis:
echo  1. Click "📁 Scan All Modules" in UI
echo  2. Look for AutoFishingController in results
echo  3. Click "AutoFishingController" quick button
echo  4. Wait for module to load and analyze
echo.
echo  Step 3 - Method Discovery:
echo  1. Check "Methods" section for available functions
echo  2. Look for auto fishing related methods
echo  3. Try calling methods with no arguments first
echo  4. Monitor execution results
echo.
echo  🎣 ACCESSING AUTOFISHINGCONTROLLER:
echo.
echo  1. Basic Access:
echo     local AFC = require(ReplicatedStorage.Controllers.AutoFishingController)
echo.
echo  2. Check Available Methods:
echo     for key, value in pairs(AFC) do
echo         print(key, type(value))
echo     end
echo.
echo  3. Common Method Patterns:
echo     • AFC:StartAutoFishing()
echo     • AFC:StopAutoFishing()
echo     • AFC:ToggleAutoFishing()
echo     • AFC.IsEnabled (property)
echo.
echo  🔍 ANALYSIS METHODS:
echo.
echo  Method Discovery:
echo  • Load module via Module Analyzer floating UI
echo  • Check all properties and functions
echo  • Test with different arguments
echo  • Monitor game state changes
echo.
echo  Testing Strategy:
echo  1. Start with parameter-less methods
echo  2. Try boolean toggles (true/false)
echo  3. Test with fishing rod IDs
echo  4. Check state properties
echo.
echo  🎣 EXPECTED FUNCTIONALITY:
echo.
echo  AutoFishing Features:
echo  • Automatic rod casting
echo  • Fish detection and reeling
echo  • Bait management
echo  • Fishing location optimization
echo  • Anti-AFK functionality
echo.
echo  Integration Points:
echo  • Works with UpdateAutoFishingState remote
echo  • Connects to FishingController
echo  • Uses ChargeFishingRod remote
echo  • Monitors FishCaught events
echo.
echo  💡 FLOATING UI ADVANTAGES:
echo.
echo  • Clean interface - UI hidden when not needed
echo  • Quick access via floating button
echo  • Persistent button position
echo  • Easy toggle during gameplay
echo  • Non-intrusive design
echo.
pause
goto menu

:experimental_mode
echo.
echo  [INFO] Launching Experimental Mode with Floating UI...
echo  [INFO] Mode: Advanced analysis with hooks and floating interface
echo  [INFO] Features: Method hooking, call monitoring, floating UI
echo.

REM Create experimental version
echo -- Module Analyzer Experimental Mode (Floating UI) > temp_experimental.lua
echo local experimentalMode = true >> temp_experimental.lua
echo local enableHooks = true >> temp_experimental.lua
echo local monitorCalls = true >> temp_experimental.lua
echo local floatingUI = true >> temp_experimental.lua
echo. >> temp_experimental.lua

REM Append main script
type "module_analyzer.lua" >> temp_experimental.lua

echo -- Experimental features >> temp_experimental.lua
echo if experimentalMode then >> temp_experimental.lua
echo     print("🧪 Experimental mode enabled with Floating UI") >> temp_experimental.lua
echo     print("📊 Method hooking and call monitoring active") >> temp_experimental.lua
echo     print("📁 Floating toggle button interface ready") >> temp_experimental.lua
echo end >> temp_experimental.lua

call :launch_script_file "temp_experimental.lua"
goto post_launch

:ui_guide
echo.
echo  ==========================================
echo   📱 Floating UI Control Guide
echo  ==========================================
echo.
echo  📁 FLOATING BUTTON FEATURES:
echo.
echo  Visual Design:
echo  • 📁 Folder icon for ModuleScript identification
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
echo  • Starts at top-left (20, 180) position
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
echo  1. 📁 Module Scanner - Top section
echo  2. 📋 Module Loader - Load specific modules
echo  3. 🔧 Method Executor - Execute module methods
echo  4. 📊 Methods Display - Show available methods
echo  5. 📋 Execution History - Bottom section
echo.
echo  Quick Access Buttons:
echo  • AutoFishingController - Direct load button
echo  • FishingController - Core fishing module
echo  • Baits - Bait system module
echo  • Custom module loading input
echo.
echo  💡 USAGE RECOMMENDATIONS:
echo.
echo  Optimal Workflow:
echo  1. Position floating button in convenient location
echo  2. Keep UI hidden during normal gameplay
echo  3. Show UI only when analyzing modules
echo  4. Use quick buttons for common modules
echo  5. Monitor history for successful method calls
echo.
echo  AutoFishingController Workflow:
echo  1. Click floating button to show UI
echo  2. Click "AutoFishingController" quick button
echo  3. Wait for module loading and analysis
echo  4. Check methods list for auto fishing functions
echo  5. Test discovered methods with arguments
echo  6. Hide UI when analysis complete
echo.
echo  Performance Tips:
echo  • UI starts hidden to reduce memory usage
echo  • Module scanning only when needed
echo  • History limited to recent entries
echo  • Efficient module caching system
echo.
pause
goto menu

:module_reference
echo.
echo  ==========================================
echo   📚 Fish It ModuleScript Reference
echo  ==========================================
echo.
echo  🎣 FISHING MODULES:
echo.
echo  AutoFishingController:
echo  • Purpose: Main auto fishing logic
echo  • Location: ReplicatedStorage.Controllers
echo  • Key Methods: Start/Stop/Toggle auto fishing
echo  • Floating UI: Direct quick-load button available
echo.
echo  FishingController:
echo  • Purpose: Core fishing mechanics
echo  • Location: ReplicatedStorage.Controllers
echo  • Key Methods: Cast, reel, bait management
echo  • Floating UI: Quick access button
echo.
echo  FishingRodModifiers:
echo  • Purpose: Rod stats and modifiers
echo  • Location: ReplicatedStorage.Shared
echo  • Key Data: Rod power, luck, speed values
echo.
echo  Baits:
echo  • Purpose: Bait types and effects
echo  • Location: ReplicatedStorage
echo  • Key Data: Bait stats, catch modifiers
echo  • Floating UI: Quick-load button available
echo.
echo  🛒 SHOP MODULES:
echo.
echo  RodShopController:
echo  • Purpose: Fishing rod shop logic
echo  • Methods: Purchase, upgrade, equip rods
echo.
echo  BaitShopController:
echo  • Purpose: Bait shop management
echo  • Methods: Buy baits, manage inventory
echo.
echo  CoinProducts ^& ItemProducts:
echo  • Purpose: In-game economy
echo  • Data: Prices, items, transactions
echo.
echo  🎮 GAME SYSTEMS:
echo.
echo  FishWeightChances:
echo  • Purpose: Fish weight probability
echo  • Data: Weight distribution tables
echo.
echo  Products Folder:
echo  • Purpose: All purchasable items
echo  • Modules: Coins, items, special products
echo.
echo  GiftProducts:
echo  • Purpose: Free items and rewards
echo  • Methods: Claim gifts, daily rewards
echo.
echo  🔧 UTILITIES:
echo.
echo  RaycastUtility:
echo  • Purpose: 3D positioning and detection
echo  • Methods: Raycasting for fishing spots
echo.
echo  Network ^& Net:
echo  • Purpose: Client-server communication
echo  • Methods: Remote event handling
echo.
echo  FastCastRedux:
echo  • Purpose: Projectile system (fishing line)
echo  • Methods: Line casting physics
echo.
echo  💡 FLOATING UI ANALYSIS TIPS:
echo.
echo  1. Use floating button for quick access
echo  2. Start with Controllers folder modules
echo  3. Focus on AutoFishingController first
echo  4. Check for Start/Stop/Toggle methods
echo  5. Look for state properties (IsEnabled, etc.)
echo  6. Test methods in fishing areas
echo  7. Monitor remote event calls via floating UI
echo  8. Check for required arguments
echo  9. Hide UI when not analyzing
echo  10. Use quick buttons for common modules
echo.
pause
goto menu

:launch_script
echo  [INFO] Preparing Module Analyzer script...
echo  [INFO] Mode: %~1 UI with floating toggle button
echo.

REM Create launch script
echo -- Module Analyzer Launch with Floating UI > temp_analyzer_launch.lua
echo local launchMode = "%~1" >> temp_analyzer_launch.lua
echo local floatingUI = true >> temp_analyzer_launch.lua
echo. >> temp_analyzer_launch.lua

REM Append main script
type "module_analyzer.lua" >> temp_analyzer_launch.lua

echo  [INFO] Module Analyzer with Floating UI ready
echo  [INFO] Copy and paste this command into Roblox executor:
echo.
echo  ==========================================
color 0A
echo  loadstring(readfile("temp_analyzer_launch.lua"))()
color 0E
echo  ==========================================
echo.
goto :eof

:launch_script_file
echo  [INFO] Module Analyzer script ready
echo  [INFO] Copy and paste this command into Roblox executor:
echo.
echo  ==========================================
color 0A
echo  loadstring(readfile("%~1"))()
color 0E
echo  ==========================================
echo.
goto :eof

:post_launch
echo.
echo  ==========================================
echo   📁 Module Analyzer Launched (Floating UI)!
echo  ==========================================
echo.
echo  Next Steps:
echo.
echo  1. 🎮 Open your Roblox executor
echo  2. 📋 Copy the loadstring command above
echo  3. ✅ Execute in Fish It game
echo  4. 📁 Look for purple floating button on left side
echo  5. 🖱️ Click floating button to show UI
echo.
echo  📁 Floating Button Usage:
echo    • Purple 📁 button = UI Hidden
echo    • Click button = Show Module Analyzer UI
echo    • Green 📁 button = UI Visible
echo    • Click again = Hide UI
echo    • Drag button = Move to preferred position
echo.
echo  🎯 AutoFishingController Analysis:
echo    1. Click floating button to open UI
echo    2. Click "📁 Scan All Modules" first
echo    3. Click "AutoFishingController" quick button
echo    4. Wait for module loading and analysis
echo    5. Check methods list for auto fishing functions
echo    6. Test discovered methods with arguments
echo.
echo  📁 Module Analyzer Features:
echo    • Scan all ModuleScripts automatically
echo    • Load and analyze any module
echo    • Execute methods with custom arguments
echo    • View all properties and functions
echo    • Execution history tracking
echo    • Floating UI for easy access
echo.
echo  🔍 AutoFishing Testing Sequence:
echo    1. Load AutoFishingController
echo    2. Check methods list
echo    3. Try: StartAutoFishing
echo    4. Try: StopAutoFishing
echo    5. Try: ToggleAutoFishing
echo    6. Check state properties
echo.

:monitor
echo.
echo  ==========================================
echo   📊 Module Analysis Monitor (Floating UI)
echo  ==========================================
echo.
echo  [%date% %time%] Module Analyzer Active
echo  Status: Floating UI interface ready
echo.
echo  Current Focus: AutoFishingController
echo  ✓ Floating toggle button system
echo  ✓ Module scanner and loader
echo  ✓ Method analysis and execution
echo  ✓ Quick access buttons
echo  ✓ Execution history tracking
echo.
echo  Expected AutoFishing Methods:
echo  • StartAutoFishing() - Begin auto fishing
echo  • StopAutoFishing() - End auto fishing
echo  • ToggleAutoFishing() - Toggle state
echo  • IsEnabled - Current state property
echo  • SetMode() - Set fishing mode
echo.
echo  UI State Management:
echo  • Floating button always visible
echo  • Main UI hidden by default
echo  • Toggle functionality active
echo  • Position persistence enabled
echo.
echo  Options:
echo  [1] 🔄 Restart Module Analyzer
echo  [2] 🎣 Focus on AutoFishingController
echo  [3] 🔍 Scan Other Controllers
echo  [4] 🛑 Stop Session
echo  [5] 🏠 Back to Menu
echo.

set /p mon_choice="Select option (1-5): "

if "%mon_choice%"=="1" goto menu
if "%mon_choice%"=="2" goto quick_autofish
if "%mon_choice%"=="3" goto scan_controllers
if "%mon_choice%"=="4" goto stop_session
if "%mon_choice%"=="5" goto menu

echo Invalid choice!
goto monitor

:stop_session
echo.
echo  [INFO] Stopping Module Analyzer session...
echo  [INFO] Click the X button on UI or close game
echo.
echo  📊 Analysis Summary:
echo    • Check loaded modules in UI
echo    • Review method execution results
echo    • Note successful AutoFishing calls
echo    • Document discovered methods
echo.
echo  🎣 AutoFishingController Findings:
echo    • Save successful method names
echo    • Document required arguments
echo    • Note any state properties
echo    • Record integration points
echo.
echo  📁 Floating UI:
echo    • Button remains active until game closed
echo    • UI can be toggled anytime
echo    • Position saved for session
echo.
pause
goto menu

:exit
echo.
echo  ==========================================
echo   👋 Thanks for using Module Analyzer!
echo  ==========================================
echo.
echo  [INFO] Cleaning up temporary files...

if exist "temp_analyzer_launch.lua" (
    del "temp_analyzer_launch.lua"
    echo  [✓] Launch file cleaned
)

if exist "temp_autofish_analyzer.lua" (
    del "temp_autofish_analyzer.lua"
    echo  [✓] AutoFish mode file cleaned
)

if exist "temp_controller_scan.lua" (
    del "temp_controller_scan.lua"
    echo  [✓] Controller scan file cleaned
)

if exist "temp_experimental.lua" (
    del "temp_experimental.lua"
    echo  [✓] Experimental mode file cleaned
)

echo  [INFO] Module Analyzer session ended
echo  [INFO] Remember to close the UI before closing Roblox
echo.
echo  📁 ModuleScript Analysis Summary:
echo    • Floating UI for easy access
echo    • Tool for analyzing ModuleScripts
echo    • Load and execute module methods
echo    • Perfect for AutoFishingController analysis
echo    • Discover hidden functionality
echo.
echo  🎣 AutoFishingController Discovery:
echo    • Use findings to integrate auto fishing
echo    • Test discovered methods in your scripts
echo    • Monitor for game updates and changes
echo    • Floating button for quick access
echo.
echo  🚀 Thank you for using Module Analyzer!
echo  Perfect for Fish It game development and research!
echo.
pause
exit /b 0
