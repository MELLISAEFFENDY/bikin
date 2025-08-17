-- module_analyzer.lua
-- Analyzer untuk ModuleScript Fish It game
-- Tool untuk menganalisis dan menggunakan ModuleScript functions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Module Analyzer System
local ModuleAnalyzer = {
    foundModules = {},
    loadedModules = {},
    methods = {},
    lastResults = {},
    history = {}
}

-- Notification function
local function Notify(title, message, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 3
        })
    end)
    print(string.format("[Module Analyzer] %s: %s", title, message))
end

-- Scan for ModuleScripts
local function scanModuleScripts()
    ModuleAnalyzer.foundModules = {}
    
    print("🔍 Scanning for ModuleScripts...")
    
    if not ReplicatedStorage then 
        print("❌ ReplicatedStorage not found!")
        return 
    end
    
    local function scanContainer(container, path)
        for _, item in pairs(container:GetChildren()) do
            local fullPath = path .. "/" .. item.Name
            
            if item:IsA("ModuleScript") then
                table.insert(ModuleAnalyzer.foundModules, {
                    name = item.Name,
                    path = fullPath,
                    object = item,
                    category = "ModuleScript"
                })
                print("📁 Found ModuleScript: " .. fullPath)
                
            elseif item:IsA("Folder") then
                pcall(function()
                    scanContainer(item, fullPath)
                end)
            end
        end
    end
    
    -- Scan ReplicatedStorage
    scanContainer(ReplicatedStorage, "ReplicatedStorage")
    
    print("📊 ModuleScript scan complete:")
    print("  • Total modules found: " .. #ModuleAnalyzer.foundModules)
    
    Notify("Module Scanner", "Found " .. #ModuleAnalyzer.foundModules .. " modules!")
    return ModuleAnalyzer.foundModules
end

-- Load and analyze a module
local function loadModule(moduleName)
    local moduleScript = nil
    local modulePath = ""
    
    -- Find the module
    for _, m in pairs(ModuleAnalyzer.foundModules) do
        if m.name == moduleName or m.path:find(moduleName) then
            moduleScript = m.object
            modulePath = m.path
            break
        end
    end
    
    if not moduleScript then
        Notify("Error", "❌ Module '" .. moduleName .. "' not found!")
        return false, "Module not found"
    end
    
    print("📁 Loading module: " .. modulePath)
    
    local success, moduleData = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        ModuleAnalyzer.loadedModules[moduleName] = moduleData
        
        -- Analyze methods
        local methods = {}
        if type(moduleData) == "table" then
            for key, value in pairs(moduleData) do
                table.insert(methods, {
                    name = key,
                    type = type(value),
                    value = value
                })
                print("  📋 Method: " .. key .. " (" .. type(value) .. ")")
            end
        end
        
        ModuleAnalyzer.methods[moduleName] = methods
        
        print("✅ Module loaded successfully!")
        print("📊 Found " .. #methods .. " methods/properties")
        Notify("Success", "✅ " .. moduleName .. " loaded!")
        
        return true, moduleData
    else
        print("❌ Failed to load module!")
        print("💥 Error: " .. tostring(moduleData))
        Notify("Error", "❌ Failed to load " .. moduleName)
        return false, moduleData
    end
end

-- Call a module method
local function callModuleMethod(moduleName, methodName, args)
    local moduleData = ModuleAnalyzer.loadedModules[moduleName]
    
    if not moduleData then
        Notify("Error", "❌ Module '" .. moduleName .. "' not loaded!")
        return false, "Module not loaded"
    end
    
    local method = moduleData[methodName]
    if not method then
        Notify("Error", "❌ Method '" .. methodName .. "' not found!")
        return false, "Method not found"
    end
    
    if type(method) ~= "function" then
        print("📋 Property value: " .. tostring(method))
        Notify("Info", "Property: " .. tostring(method))
        return true, method
    end
    
    print("🚀 Calling method: " .. moduleName .. "." .. methodName)
    print("📋 Arguments: " .. tostring(args))
    
    local success, result = pcall(function()
        if args and args ~= "" then
            -- Parse arguments
            local parsedArgs = {}
            for arg in string.gmatch(args, "[^,]+") do
                arg = arg:gsub("^%s*(.-)%s*$", "%1")
                
                local num = tonumber(arg)
                if num then
                    table.insert(parsedArgs, num)
                elseif arg:lower() == "true" then
                    table.insert(parsedArgs, true)
                elseif arg:lower() == "false" then
                    table.insert(parsedArgs, false)
                else
                    table.insert(parsedArgs, arg)
                end
            end
            
            return method(unpack(parsedArgs))
        else
            return method()
        end
    end)
    
    -- Log to history
    table.insert(ModuleAnalyzer.history, {
        time = os.date("%H:%M:%S"),
        module = moduleName,
        method = methodName,
        args = args or "",
        success = success,
        result = result
    })
    
    if success then
        print("✅ Method called successfully!")
        print("📤 Result: " .. tostring(result))
        Notify("Success", "✅ " .. methodName .. " executed!")
        return true, result
    else
        print("❌ Method call failed!")
        print("💥 Error: " .. tostring(result))
        Notify("Error", "❌ " .. methodName .. " failed!")
        return false, result
    end
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ModuleAnalyzerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main panel
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 550, 0, 650)
mainPanel.Position = UDim2.new(0.5, -275, 0.5, -325)
mainPanel.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainPanel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(150, 75, 200)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainPanel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Text = "📁 ModuleScript Analyzer & Executor"
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 16
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.BackgroundTransparency = 1
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn)

-- Content area
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -20, 1, -50)
contentArea.Position = UDim2.new(0, 10, 0, 45)
contentArea.BackgroundTransparency = 1
contentArea.Parent = mainPanel

-- Scanner section
local scannerSection = Instance.new("Frame")
scannerSection.Size = UDim2.new(1, 0, 0, 80)
scannerSection.Position = UDim2.new(0, 0, 0, 10)
scannerSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
scannerSection.BorderSizePixel = 0
scannerSection.Parent = contentArea
Instance.new("UICorner", scannerSection)

local scanTitle = Instance.new("TextLabel")
scanTitle.Size = UDim2.new(1, -10, 0, 25)
scanTitle.Position = UDim2.new(0, 5, 0, 5)
scanTitle.Text = "📁 ModuleScript Scanner"
scanTitle.Font = Enum.Font.GothamBold
scanTitle.TextSize = 14
scanTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
scanTitle.BackgroundTransparency = 1
scanTitle.TextXAlignment = Enum.TextXAlignment.Left
scanTitle.Parent = scannerSection

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0, 200, 0, 35)
scanBtn.Position = UDim2.new(0, 10, 0, 35)
scanBtn.Text = "🔍 Scan All Modules"
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 12
scanBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Parent = scannerSection
Instance.new("UICorner", scanBtn)

local scanStatus = Instance.new("TextLabel")
scanStatus.Size = UDim2.new(0, 300, 0, 35)
scanStatus.Position = UDim2.new(0, 220, 0, 35)
scanStatus.Text = "Ready to scan..."
scanStatus.Font = Enum.Font.Gotham
scanStatus.TextSize = 11
scanStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
scanStatus.BackgroundTransparency = 1
scanStatus.TextXAlignment = Enum.TextXAlignment.Left
scanStatus.Parent = scannerSection

-- Module loader section
local loaderSection = Instance.new("Frame")
loaderSection.Size = UDim2.new(1, 0, 0, 100)
loaderSection.Position = UDim2.new(0, 0, 0, 100)
loaderSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
loaderSection.BorderSizePixel = 0
loaderSection.Parent = contentArea
Instance.new("UICorner", loaderSection)

local loaderTitle = Instance.new("TextLabel")
loaderTitle.Size = UDim2.new(1, -10, 0, 25)
loaderTitle.Position = UDim2.new(0, 5, 0, 5)
loaderTitle.Text = "📁 Module Loader"
loaderTitle.Font = Enum.Font.GothamBold
loaderTitle.TextSize = 14
loaderTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
loaderTitle.BackgroundTransparency = 1
loaderTitle.TextXAlignment = Enum.TextXAlignment.Left
loaderTitle.Parent = loaderSection

local moduleInput = Instance.new("TextBox")
moduleInput.Size = UDim2.new(0, 350, 0, 25)
moduleInput.Position = UDim2.new(0, 10, 0, 35)
moduleInput.PlaceholderText = "Enter ModuleScript name (e.g. AutoFishingController)"
moduleInput.Text = ""
moduleInput.Font = Enum.Font.Gotham
moduleInput.TextSize = 10
moduleInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
moduleInput.TextColor3 = Color3.fromRGB(255, 255, 255)
moduleInput.BorderSizePixel = 0
moduleInput.Parent = loaderSection
Instance.new("UICorner", moduleInput)

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(0, 150, 0, 25)
loadBtn.Position = UDim2.new(0, 370, 0, 35)
loadBtn.Text = "📁 Load Module"
loadBtn.Font = Enum.Font.GothamBold
loadBtn.TextSize = 11
loadBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBtn.Parent = loaderSection
Instance.new("UICorner", loadBtn)

-- Quick load buttons
local autoFishBtn = Instance.new("TextButton")
autoFishBtn.Size = UDim2.new(0, 160, 0, 25)
autoFishBtn.Position = UDim2.new(0, 10, 0, 70)
autoFishBtn.Text = "🎣 AutoFishingController"
autoFishBtn.Font = Enum.Font.GothamSemibold
autoFishBtn.TextSize = 10
autoFishBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 50)
autoFishBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoFishBtn.Parent = loaderSection
Instance.new("UICorner", autoFishBtn)

local fishingBtn = Instance.new("TextButton")
fishingBtn.Size = UDim2.new(0, 160, 0, 25)
fishingBtn.Position = UDim2.new(0, 180, 0, 70)
fishingBtn.Text = "🎣 FishingController"
fishingBtn.Font = Enum.Font.GothamSemibold
fishingBtn.TextSize = 10
fishingBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 50)
fishingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
fishingBtn.Parent = loaderSection
Instance.new("UICorner", fishingBtn)

local baitsBtn = Instance.new("TextButton")
baitsBtn.Size = UDim2.new(0, 160, 0, 25)
baitsBtn.Position = UDim2.new(0, 350, 0, 70)
baitsBtn.Text = "🪱 Baits"
baitsBtn.Font = Enum.Font.GothamSemibold
baitsBtn.TextSize = 10
baitsBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 50)
baitsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
baitsBtn.Parent = loaderSection
Instance.new("UICorner", baitsBtn)

-- Method executor section
local executorSection = Instance.new("Frame")
executorSection.Size = UDim2.new(1, 0, 0, 120)
executorSection.Position = UDim2.new(0, 0, 0, 210)
executorSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
executorSection.BorderSizePixel = 0
executorSection.Parent = contentArea
Instance.new("UICorner", executorSection)

local execTitle = Instance.new("TextLabel")
execTitle.Size = UDim2.new(1, -10, 0, 25)
execTitle.Position = UDim2.new(0, 5, 0, 5)
execTitle.Text = "🚀 Method Executor"
execTitle.Font = Enum.Font.GothamBold
execTitle.TextSize = 14
execTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
execTitle.BackgroundTransparency = 1
execTitle.TextXAlignment = Enum.TextXAlignment.Left
execTitle.Parent = executorSection

local methodInput = Instance.new("TextBox")
methodInput.Size = UDim2.new(0, 400, 0, 25)
methodInput.Position = UDim2.new(0, 10, 0, 35)
methodInput.PlaceholderText = "Enter method name (e.g. StartAutoFishing)"
methodInput.Text = ""
methodInput.Font = Enum.Font.Gotham
methodInput.TextSize = 10
methodInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
methodInput.TextColor3 = Color3.fromRGB(255, 255, 255)
methodInput.BorderSizePixel = 0
methodInput.Parent = executorSection
Instance.new("UICorner", methodInput)

local argsInput = Instance.new("TextBox")
argsInput.Size = UDim2.new(0, 400, 0, 25)
argsInput.Position = UDim2.new(0, 10, 0, 70)
argsInput.PlaceholderText = "Arguments (comma separated)"
argsInput.Text = ""
argsInput.Font = Enum.Font.Gotham
argsInput.TextSize = 10
argsInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
argsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
argsInput.BorderSizePixel = 0
argsInput.Parent = executorSection
Instance.new("UICorner", argsInput)

local executeBtn = Instance.new("TextButton")
executeBtn.Size = UDim2.new(0, 100, 0, 60)
executeBtn.Position = UDim2.new(0, 420, 0, 35)
executeBtn.Text = "🚀 RUN"
executeBtn.Font = Enum.Font.GothamBold
executeBtn.TextSize = 12
executeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
executeBtn.Parent = executorSection
Instance.new("UICorner", executeBtn)

-- Methods display section
local methodsSection = Instance.new("Frame")
methodsSection.Size = UDim2.new(1, 0, 0, 150)
methodsSection.Position = UDim2.new(0, 0, 0, 340)
methodsSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
methodsSection.BorderSizePixel = 0
methodsSection.Parent = contentArea
Instance.new("UICorner", methodsSection)

local methodsTitle = Instance.new("TextLabel")
methodsTitle.Size = UDim2.new(1, -10, 0, 25)
methodsTitle.Position = UDim2.new(0, 5, 0, 5)
methodsTitle.Text = "📋 Available Methods"
methodsTitle.Font = Enum.Font.GothamBold
methodsTitle.TextSize = 14
methodsTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
methodsTitle.BackgroundTransparency = 1
methodsTitle.TextXAlignment = Enum.TextXAlignment.Left
methodsTitle.Parent = methodsSection

local methodsFrame = Instance.new("ScrollingFrame")
methodsFrame.Size = UDim2.new(1, -20, 0, 110)
methodsFrame.Position = UDim2.new(0, 10, 0, 30)
methodsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
methodsFrame.BorderSizePixel = 0
methodsFrame.ScrollBarThickness = 8
methodsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
methodsFrame.Parent = methodsSection
Instance.new("UICorner", methodsFrame)

local methodsText = Instance.new("TextLabel")
methodsText.Size = UDim2.new(1, -10, 1, 0)
methodsText.Position = UDim2.new(0, 5, 0, 0)
methodsText.Text = "Load a module to see methods..."
methodsText.Font = Enum.Font.Gotham
methodsText.TextSize = 9
methodsText.TextColor3 = Color3.fromRGB(200, 200, 200)
methodsText.BackgroundTransparency = 1
methodsText.TextXAlignment = Enum.TextXAlignment.Left
methodsText.TextYAlignment = Enum.TextYAlignment.Top
methodsText.TextWrapped = true
methodsText.Parent = methodsFrame

-- History section
local historySection = Instance.new("Frame")
historySection.Size = UDim2.new(1, 0, 0, 100)
historySection.Position = UDim2.new(0, 0, 0, 500)
historySection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
historySection.BorderSizePixel = 0
historySection.Parent = contentArea
Instance.new("UICorner", historySection)

local historyTitle = Instance.new("TextLabel")
historyTitle.Size = UDim2.new(1, -10, 0, 20)
historyTitle.Position = UDim2.new(0, 5, 0, 5)
historyTitle.Text = "📋 Execution History"
historyTitle.Font = Enum.Font.GothamBold
historyTitle.TextSize = 12
historyTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
historyTitle.BackgroundTransparency = 1
historyTitle.TextXAlignment = Enum.TextXAlignment.Left
historyTitle.Parent = historySection

local historyFrame = Instance.new("ScrollingFrame")
historyFrame.Size = UDim2.new(1, -20, 0, 70)
historyFrame.Position = UDim2.new(0, 10, 0, 25)
historyFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
historyFrame.BorderSizePixel = 0
historyFrame.ScrollBarThickness = 8
historyFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
historyFrame.Parent = historySection
Instance.new("UICorner", historyFrame)

local historyText = Instance.new("TextLabel")
historyText.Size = UDim2.new(1, -10, 1, 0)
historyText.Position = UDim2.new(0, 5, 0, 0)
historyText.Text = "No method calls yet..."
historyText.Font = Enum.Font.Gotham
historyText.TextSize = 9
historyText.TextColor3 = Color3.fromRGB(200, 200, 200)
historyText.BackgroundTransparency = 1
historyText.TextXAlignment = Enum.TextXAlignment.Left
historyText.TextYAlignment = Enum.TextYAlignment.Top
historyText.TextWrapped = true
historyText.Parent = historyFrame

-- Update methods display
local function updateMethods(moduleName)
    local methods = ModuleAnalyzer.methods[moduleName]
    if not methods then
        methodsText.Text = "No methods found for " .. moduleName
        return
    end
    
    local methodLines = {}
    table.insert(methodLines, "📁 Module: " .. moduleName)
    table.insert(methodLines, "")
    
    for _, method in pairs(methods) do
        local line = "• " .. method.name .. " (" .. method.type .. ")"
        if method.type ~= "function" then
            line = line .. " = " .. tostring(method.value)
        end
        table.insert(methodLines, line)
    end
    
    methodsText.Text = table.concat(methodLines, "\n")
    
    -- Update canvas size
    local textBounds = game:GetService("TextService"):GetTextSize(
        methodsText.Text,
        methodsText.TextSize,
        methodsText.Font,
        Vector2.new(methodsFrame.AbsoluteSize.X - 10, math.huge)
    )
    methodsFrame.CanvasSize = UDim2.new(0, 0, 0, textBounds.Y + 10)
end

-- Update history display
local function updateHistory()
    local historyLines = {}
    
    for i = math.max(1, #ModuleAnalyzer.history - 10), #ModuleAnalyzer.history do
        local entry = ModuleAnalyzer.history[i]
        if entry then
            local status = entry.success and "✅" or "❌"
            local line = string.format("[%s] %s %s.%s", entry.time, status, entry.module, entry.method)
            if entry.args and entry.args ~= "" then
                line = line .. "(" .. entry.args .. ")"
            end
            if entry.result and tostring(entry.result) ~= "" then
                line = line .. " → " .. tostring(entry.result)
            end
            table.insert(historyLines, line)
        end
    end
    
    if #historyLines == 0 then
        historyText.Text = "No method calls yet..."
    else
        historyText.Text = table.concat(historyLines, "\n")
    end
    
    -- Update canvas size
    local textBounds = game:GetService("TextService"):GetTextSize(
        historyText.Text,
        historyText.TextSize,
        historyText.Font,
        Vector2.new(historyFrame.AbsoluteSize.X - 10, math.huge)
    )
    historyFrame.CanvasSize = UDim2.new(0, 0, 0, textBounds.Y + 10)
end

-- Button handlers
scanBtn.MouseButton1Click:Connect(function()
    scanBtn.Text = "🔍 Scanning..."
    scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    scanStatus.Text = "Scanning modules..."
    
    task.spawn(function()
        local modules = scanModuleScripts()
        
        task.wait(1)
        scanBtn.Text = "🔍 Scan All Modules"
        scanBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
        scanStatus.Text = "Found " .. #modules .. " modules"
    end)
end)

loadBtn.MouseButton1Click:Connect(function()
    local moduleName = moduleInput.Text
    if moduleName == "" then
        Notify("Error", "❌ Please enter a module name!")
        return
    end
    
    loadBtn.Text = "📁 Loading..."
    loadBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    task.spawn(function()
        local success, result = loadModule(moduleName)
        
        task.wait(0.5)
        loadBtn.Text = "📁 Load Module"
        loadBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
        
        if success then
            updateMethods(moduleName)
        end
    end)
end)

executeBtn.MouseButton1Click:Connect(function()
    local moduleName = moduleInput.Text
    local methodName = methodInput.Text
    local args = argsInput.Text
    
    if moduleName == "" or methodName == "" then
        Notify("Error", "❌ Please enter module and method name!")
        return
    end
    
    executeBtn.Text = "🚀 RUN"
    executeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    task.spawn(function()
        callModuleMethod(moduleName, methodName, args)
        
        task.wait(0.5)
        executeBtn.Text = "🚀 RUN"
        executeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        
        updateHistory()
    end)
end)

-- Quick load buttons
autoFishBtn.MouseButton1Click:Connect(function()
    moduleInput.Text = "AutoFishingController"
    loadModule("AutoFishingController")
    updateMethods("AutoFishingController")
end)

fishingBtn.MouseButton1Click:Connect(function()
    moduleInput.Text = "FishingController"
    loadModule("FishingController")
    updateMethods("FishingController")
end)

baitsBtn.MouseButton1Click:Connect(function()
    moduleInput.Text = "Baits"
    loadModule("Baits")
    updateMethods("Baits")
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    print("📁 Module Analyzer UI closed")
end)

-- Make draggable
local dragging = false
local dragInput, mousePos, framePos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        mousePos = input.Position
        framePos = mainPanel.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - mousePos
        mainPanel.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
    end
end)

-- Initial setup
print("📁 ModuleScript Analyzer loaded!")
print("📋 Features:")
print("  • Scan and discover ModuleScripts")
print("  • Load and analyze module methods")
print("  • Execute module functions with arguments")
print("  • Quick access to Fish It controllers")
print("🎮 Ready to analyze AutoFishingController!")

Notify("Module Analyzer", "📁 Ready to analyze ModuleScripts!")

-- Auto-scan on load
task.spawn(function()
    task.wait(2)
    scanModuleScripts()
    scanStatus.Text = "Found " .. #ModuleAnalyzer.foundModules .. " modules"
end)
