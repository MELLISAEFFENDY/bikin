-- remote_tester.lua
-- Remote Event/Function Tester untuk Fish It game
-- Tool untuk testing dan debugging remote calls secara langsung

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

-- Remote Tester System
local RemoteTester = {
    foundRemotes = {},
    lastResults = {},
    history = {},
    isScanning = false
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
    print(string.format("[Remote Tester] %s: %s", title, message))
end

-- Scan for all remotes
local function scanAllRemotes()
    RemoteTester.isScanning = true
    RemoteTester.foundRemotes = {}
    
    print("🔍 Scanning for all RemoteEvents and RemoteFunctions...")
    
    if not ReplicatedStorage then 
        print("❌ ReplicatedStorage not found!")
        return 
    end
    
    local function scanContainer(container, path)
        for _, item in pairs(container:GetChildren()) do
            local fullPath = path .. "/" .. item.Name
            
            if item:IsA("RemoteEvent") then
                table.insert(RemoteTester.foundRemotes, {
                    name = item.Name,
                    type = "RemoteEvent",
                    path = fullPath,
                    object = item,
                    category = "Event"
                })
                print("📡 Found RemoteEvent: " .. fullPath)
                
            elseif item:IsA("RemoteFunction") then
                table.insert(RemoteTester.foundRemotes, {
                    name = item.Name,
                    type = "RemoteFunction", 
                    path = fullPath,
                    object = item,
                    category = "Function"
                })
                print("🔧 Found RemoteFunction: " .. fullPath)
                
            elseif item:IsA("Folder") or item:IsA("ModuleScript") then
                -- Recursively scan folders and modules
                pcall(function()
                    scanContainer(item, fullPath)
                end)
            end
        end
    end
    
    -- Scan ReplicatedStorage
    scanContainer(ReplicatedStorage, "ReplicatedStorage")
    
    -- Also scan workspace for any remotes
    pcall(function()
        scanContainer(game.Workspace, "Workspace")
    end)
    
    RemoteTester.isScanning = false
    
    print("📊 Remote scan complete:")
    print("  • Total remotes found: " .. #RemoteTester.foundRemotes)
    
    local events = 0
    local functions = 0
    for _, remote in pairs(RemoteTester.foundRemotes) do
        if remote.type == "RemoteEvent" then
            events = events + 1
        else
            functions = functions + 1
        end
    end
    
    print("  • RemoteEvents: " .. events)
    print("  • RemoteFunctions: " .. functions)
    
    Notify("Remote Scanner", "Found " .. #RemoteTester.foundRemotes .. " remotes!")
    return RemoteTester.foundRemotes
end

-- Execute remote call
local function executeRemote(remoteName, args, isFunction)
    local remote = nil
    local remotePath = ""
    
    -- Find the remote
    for _, r in pairs(RemoteTester.foundRemotes) do
        if r.name == remoteName or r.path:find(remoteName) then
            remote = r.object
            remotePath = r.path
            break
        end
    end
    
    if not remote then
        Notify("Error", "❌ Remote '" .. remoteName .. "' not found!")
        return false, "Remote not found"
    end
    
    print("🚀 Executing remote: " .. remotePath)
    print("📋 Arguments: " .. tostring(args))
    
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            if args and args ~= "" then
                -- Try to parse arguments
                local parsedArgs = {}
                for arg in string.gmatch(args, "[^,]+") do
                    arg = arg:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
                    
                    -- Try to convert to number if possible
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
                
                remote:FireServer(unpack(parsedArgs))
            else
                remote:FireServer()
            end
            return "RemoteEvent fired successfully"
            
        elseif remote:IsA("RemoteFunction") then
            if args and args ~= "" then
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
                
                return remote:InvokeServer(unpack(parsedArgs))
            else
                return remote:InvokeServer()
            end
        end
    end)
    
    -- Log to history
    table.insert(RemoteTester.history, {
        time = os.date("%H:%M:%S"),
        remote = remotePath,
        args = args or "",
        success = success,
        result = result
    })
    
    if success then
        print("✅ Remote executed successfully!")
        print("📤 Result: " .. tostring(result))
        Notify("Success", "✅ " .. remoteName .. " executed!")
        return true, result
    else
        print("❌ Remote execution failed!")
        print("💥 Error: " .. tostring(result))
        Notify("Error", "❌ " .. remoteName .. " failed!")
        return false, result
    end
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RemoteTesterUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Main panel
local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 500, 0, 600)
mainPanel.Position = UDim2.new(0.5, -250, 0.5, -300)
mainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainPanel.BorderSizePixel = 0
mainPanel.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainPanel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(200, 50, 150)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainPanel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.Text = "🔧 Remote Event/Function Tester"
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
scanTitle.Text = "📡 Remote Scanner"
scanTitle.Font = Enum.Font.GothamBold
scanTitle.TextSize = 14
scanTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
scanTitle.BackgroundTransparency = 1
scanTitle.TextXAlignment = Enum.TextXAlignment.Left
scanTitle.Parent = scannerSection

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0, 200, 0, 35)
scanBtn.Position = UDim2.new(0, 10, 0, 35)
scanBtn.Text = "🔍 Scan All Remotes"
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 12
scanBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Parent = scannerSection
Instance.new("UICorner", scanBtn)

local scanStatus = Instance.new("TextLabel")
scanStatus.Size = UDim2.new(0, 250, 0, 35)
scanStatus.Position = UDim2.new(0, 220, 0, 35)
scanStatus.Text = "Ready to scan..."
scanStatus.Font = Enum.Font.Gotham
scanStatus.TextSize = 11
scanStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
scanStatus.BackgroundTransparency = 1
scanStatus.TextXAlignment = Enum.TextXAlignment.Left
scanStatus.Parent = scannerSection

-- Remote executor section
local executorSection = Instance.new("Frame")
executorSection.Size = UDim2.new(1, 0, 0, 140)
executorSection.Position = UDim2.new(0, 0, 0, 100)
executorSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
executorSection.BorderSizePixel = 0
executorSection.Parent = contentArea
Instance.new("UICorner", executorSection)

local execTitle = Instance.new("TextLabel")
execTitle.Size = UDim2.new(1, -10, 0, 25)
execTitle.Position = UDim2.new(0, 5, 0, 5)
execTitle.Text = "🚀 Remote Executor"
execTitle.Font = Enum.Font.GothamBold
execTitle.TextSize = 14
execTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
execTitle.BackgroundTransparency = 1
execTitle.TextXAlignment = Enum.TextXAlignment.Left
execTitle.Parent = executorSection

-- Remote name input
local remoteLabel = Instance.new("TextLabel")
remoteLabel.Size = UDim2.new(0, 120, 0, 25)
remoteLabel.Position = UDim2.new(0, 10, 0, 35)
remoteLabel.Text = "Remote Name:"
remoteLabel.Font = Enum.Font.GothamSemibold
remoteLabel.TextSize = 11
remoteLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
remoteLabel.BackgroundTransparency = 1
remoteLabel.TextXAlignment = Enum.TextXAlignment.Left
remoteLabel.Parent = executorSection

local remoteInput = Instance.new("TextBox")
remoteInput.Size = UDim2.new(0, 350, 0, 25)
remoteInput.Position = UDim2.new(0, 130, 0, 35)
remoteInput.PlaceholderText = "Enter RE/ or RF/ remote name (e.g. PlayFishingEffect)"
remoteInput.Text = ""
remoteInput.Font = Enum.Font.Gotham
remoteInput.TextSize = 10
remoteInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
remoteInput.TextColor3 = Color3.fromRGB(255, 255, 255)
remoteInput.BorderSizePixel = 0
remoteInput.Parent = executorSection
Instance.new("UICorner", remoteInput)

-- Arguments input
local argsLabel = Instance.new("TextLabel")
argsLabel.Size = UDim2.new(0, 120, 0, 25)
argsLabel.Position = UDim2.new(0, 10, 0, 70)
argsLabel.Text = "Arguments:"
argsLabel.Font = Enum.Font.GothamSemibold
argsLabel.TextSize = 11
argsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
argsLabel.BackgroundTransparency = 1
argsLabel.TextXAlignment = Enum.TextXAlignment.Left
argsLabel.Parent = executorSection

local argsInput = Instance.new("TextBox")
argsInput.Size = UDim2.new(0, 350, 0, 25)
argsInput.Position = UDim2.new(0, 130, 0, 70)
argsInput.PlaceholderText = "Arguments separated by comma (e.g. arg1, 123, true)"
argsInput.Text = ""
argsInput.Font = Enum.Font.Gotham
argsInput.TextSize = 10
argsInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
argsInput.TextColor3 = Color3.fromRGB(255, 255, 255)
argsInput.BorderSizePixel = 0
argsInput.Parent = executorSection
Instance.new("UICorner", argsInput)

-- Execute button
local executeBtn = Instance.new("TextButton")
executeBtn.Size = UDim2.new(0, 150, 0, 35)
executeBtn.Position = UDim2.new(0, 10, 0, 105)
executeBtn.Text = "🚀 RUN REMOTE"
executeBtn.Font = Enum.Font.GothamBold
executeBtn.TextSize = 12
executeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
executeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
executeBtn.Parent = executorSection
Instance.new("UICorner", executeBtn)

-- Quick buttons
local quickSection = Instance.new("Frame")
quickSection.Size = UDim2.new(1, 0, 0, 100)
quickSection.Position = UDim2.new(0, 0, 0, 250)
quickSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
quickSection.BorderSizePixel = 0
quickSection.Parent = contentArea
Instance.new("UICorner", quickSection)

local quickTitle = Instance.new("TextLabel")
quickTitle.Size = UDim2.new(1, -10, 0, 25)
quickTitle.Position = UDim2.new(0, 5, 0, 5)
quickTitle.Text = "⚡ Quick Actions"
quickTitle.Font = Enum.Font.GothamBold
quickTitle.TextSize = 14
quickTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
quickTitle.BackgroundTransparency = 1
quickTitle.TextXAlignment = Enum.TextXAlignment.Left
quickTitle.Parent = quickSection

-- Quick buttons
local fishingBtn = Instance.new("TextButton")
fishingBtn.Size = UDim2.new(0, 140, 0, 30)
fishingBtn.Position = UDim2.new(0, 10, 0, 35)
fishingBtn.Text = "🎣 PlayFishingEffect"
fishingBtn.Font = Enum.Font.GothamSemibold
fishingBtn.TextSize = 10
fishingBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
fishingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
fishingBtn.Parent = quickSection
Instance.new("UICorner", fishingBtn)

local chargeBtn = Instance.new("TextButton")
chargeBtn.Size = UDim2.new(0, 140, 0, 30)
chargeBtn.Position = UDim2.new(0, 160, 0, 35)
chargeBtn.Text = "⚡ ChargeFishingRod"
chargeBtn.Font = Enum.Font.GothamSemibold
chargeBtn.TextSize = 10
chargeBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
chargeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
chargeBtn.Parent = quickSection
Instance.new("UICorner", chargeBtn)

local sellBtn = Instance.new("TextButton")
sellBtn.Size = UDim2.new(0, 140, 0, 30)
sellBtn.Position = UDim2.new(0, 310, 0, 35)
sellBtn.Text = "💰 SellAllItems"
sellBtn.Font = Enum.Font.GothamSemibold
sellBtn.TextSize = 10
sellBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sellBtn.Parent = quickSection
Instance.new("UICorner", sellBtn)

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(0, 140, 0, 30)
cancelBtn.Position = UDim2.new(0, 10, 0, 70)
cancelBtn.Text = "❌ CancelFishingInputs"
cancelBtn.Font = Enum.Font.GothamSemibold
cancelBtn.TextSize = 10
cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelBtn.Parent = quickSection
Instance.new("UICorner", cancelBtn)

-- Results section
local resultsSection = Instance.new("Frame")
resultsSection.Size = UDim2.new(1, 0, 0, 180)
resultsSection.Position = UDim2.new(0, 0, 0, 360)
resultsSection.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
resultsSection.BorderSizePixel = 0
resultsSection.Parent = contentArea
Instance.new("UICorner", resultsSection)

local resultsTitle = Instance.new("TextLabel")
resultsTitle.Size = UDim2.new(1, -10, 0, 25)
resultsTitle.Position = UDim2.new(0, 5, 0, 5)
resultsTitle.Text = "📋 Execution History"
resultsTitle.Font = Enum.Font.GothamBold
resultsTitle.TextSize = 14
resultsTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
resultsTitle.BackgroundTransparency = 1
resultsTitle.TextXAlignment = Enum.TextXAlignment.Left
resultsTitle.Parent = resultsSection

-- Scrolling frame for history
local historyFrame = Instance.new("ScrollingFrame")
historyFrame.Size = UDim2.new(1, -20, 0, 140)
historyFrame.Position = UDim2.new(0, 10, 0, 30)
historyFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
historyFrame.BorderSizePixel = 0
historyFrame.ScrollBarThickness = 8
historyFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
historyFrame.Parent = resultsSection
Instance.new("UICorner", historyFrame)

local historyText = Instance.new("TextLabel")
historyText.Size = UDim2.new(1, -10, 1, 0)
historyText.Position = UDim2.new(0, 5, 0, 0)
historyText.Text = "No executions yet..."
historyText.Font = Enum.Font.Gotham
historyText.TextSize = 9
historyText.TextColor3 = Color3.fromRGB(200, 200, 200)
historyText.BackgroundTransparency = 1
historyText.TextXAlignment = Enum.TextXAlignment.Left
historyText.TextYAlignment = Enum.TextYAlignment.Top
historyText.TextWrapped = true
historyText.Parent = historyFrame

-- Update history display
local function updateHistory()
    local historyLines = {}
    
    for i = math.max(1, #RemoteTester.history - 20), #RemoteTester.history do
        local entry = RemoteTester.history[i]
        if entry then
            local status = entry.success and "✅" or "❌"
            local line = string.format("[%s] %s %s", entry.time, status, entry.remote)
            if entry.args and entry.args ~= "" then
                line = line .. " (" .. entry.args .. ")"
            end
            if entry.result and tostring(entry.result) ~= "" then
                line = line .. " → " .. tostring(entry.result)
            end
            table.insert(historyLines, line)
        end
    end
    
    if #historyLines == 0 then
        historyText.Text = "No executions yet..."
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
    if RemoteTester.isScanning then return end
    
    scanBtn.Text = "🔍 Scanning..."
    scanBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    scanStatus.Text = "Scanning remotes..."
    
    task.spawn(function()
        local remotes = scanAllRemotes()
        
        task.wait(1)
        scanBtn.Text = "🔍 Scan All Remotes"
        scanBtn.BackgroundColor3 = Color3.fromRGB(70, 170, 90)
        scanStatus.Text = "Found " .. #remotes .. " remotes"
    end)
end)

executeBtn.MouseButton1Click:Connect(function()
    local remoteName = remoteInput.Text
    local args = argsInput.Text
    
    if remoteName == "" then
        Notify("Error", "❌ Please enter a remote name!")
        return
    end
    
    executeBtn.Text = "🚀 EXECUTING..."
    executeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    task.spawn(function()
        executeRemote(remoteName, args)
        
        task.wait(0.5)
        executeBtn.Text = "🚀 RUN REMOTE"
        executeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
        
        updateHistory()
    end)
end)

-- Quick action buttons
fishingBtn.MouseButton1Click:Connect(function()
    remoteInput.Text = "PlayFishingEffect"
    argsInput.Text = ""
    executeRemote("PlayFishingEffect", "")
    updateHistory()
end)

chargeBtn.MouseButton1Click:Connect(function()
    remoteInput.Text = "ChargeFishingRod"
    argsInput.Text = "1"
    executeRemote("ChargeFishingRod", "1")
    updateHistory()
end)

sellBtn.MouseButton1Click:Connect(function()
    remoteInput.Text = "SellAllItems"
    argsInput.Text = ""
    executeRemote("SellAllItems", "")
    updateHistory()
end)

cancelBtn.MouseButton1Click:Connect(function()
    remoteInput.Text = "CancelFishingInputs"
    argsInput.Text = ""
    executeRemote("CancelFishingInputs", "")
    updateHistory()
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    print("🔧 Remote Tester UI closed")
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

-- Keybind support
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
        if remoteInput:IsFocused() or argsInput:IsFocused() then
            executeBtn:Fire()
        end
    elseif input.KeyCode == Enum.KeyCode.F5 then
        scanBtn:Fire()
    end
end)

-- Initial setup
print("🔧 Remote Event/Function Tester loaded!")
print("📋 Features:")
print("  • Scan all RemoteEvents and RemoteFunctions")
print("  • Execute remotes with custom arguments")
print("  • Quick action buttons for common remotes")
print("  • Execution history and results")
print("🎮 Controls: F5=Scan, Enter=Execute")

Notify("Remote Tester", "🔧 Remote Tester loaded! Press F5 to scan remotes.")

-- Auto-scan on load
task.spawn(function()
    task.wait(2)
    scanAllRemotes()
    scanStatus.Text = "Found " .. #RemoteTester.foundRemotes .. " remotes"
end)
