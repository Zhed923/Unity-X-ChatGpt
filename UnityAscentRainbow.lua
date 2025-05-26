-- Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- Player and PlayerGui
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") -- Ensure PlayerGui exists

-------------------------------------------------------------------------------
--                        NO WHITELIST (UNIVERSAL ACCESS)                    --
-- This script is now universal and can be used by anyone.                   --
-------------------------------------------------------------------------------

-- Store player's original movement properties
local OriginalWalkSpeed = 16 -- Default Roblox WalkSpeed
local OriginalJumpPower = 50 -- Default Roblox JumpPower

-- Listen for CharacterAdded to get Humanoid for player movement lock
LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    if humanoid then
        -- Update original values based on the new character's humanoid
        OriginalWalkSpeed = humanoid.WalkSpeed
        OriginalJumpPower = humanoid.JumpPower

        -- If player movement was locked before character died, re-apply it
        if isPlayerMovementLocked then
            pcall(function() humanoid.WalkSpeed = 0 end)
            pcall(function() humanoid.JumpPower = 0 end)
        end
    end
end)

-- Rainbow color utility
local function getRainbowColor()
    local t = tick()
    local r = math.floor(math.sin(t * 2) * 127 + 128)
    local g = math.floor(math.sin(t * 2 + 2) * 127 + 128)
    local b = math.floor(math.sin(t * 2 + 4) * 127 + 128)
    return Color3.fromRGB(r, g, b)
end

local function makeRainbowText(textObject)
    coroutine.wrap(function()
        while textObject and textObject.Parent do
            textObject.TextColor3 = getRainbowColor()
            task.wait()
        end
    end)()
end

-- UI Constants
local UNFOLDED_WIDTH = 160
local UNFOLDED_HEIGHT = 200
local FOLDED_HEIGHT = 18
local TITLE_HEIGHT = 18
local INFO_BAR_HEIGHT = 15

local BUTTON_HEIGHT = 20
local BUTTON_TEXT_SIZE = 11
local VERTICAL_SPACING = 3
local INITIAL_BUTTON_Y = 5

local UNFOLDED_SIZE = UDim2.new(0, UNFOLDED_WIDTH, 0, UNFOLDED_HEIGHT)
local FOLDED_SIZE = UDim2.new(0, UNFOLDED_WIDTH, 0, FOLDED_HEIGHT)
local COMPACT_MODE_SIZE = UDim2.new(0, 50, 0, 50)

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BUTTON_SIZE = UDim2.new(1, -10, 0, BUTTON_HEIGHT)
local BUTTON_INSET_X = 5
local BUTTON_CORNER_RADIUS = UDim.new(0, 5)

-- Global UI State Variables (FOR PERSISTENCE)
local isFolded = false
local isUIPositionLocked = false
local isPlayerMovementLocked = false
local inCompactMode = false
local dragons = false -- Auto Rebirth state
local autoChests = false
local autoJoinBrawl = false
local autoHandstands = false
local autoSitups = false
local autoPushups = false

-- Reference to the ScreenGui (will be set when created)
local ScreenGui
local MainFrame
local TitleLabel
local FPSLabel
local MSLabel
local ContentFrame

-- Function to create and set up the UI
local function createUI()
    -- Clean up existing UI if it somehow persists (though PlayerGui usually handles this)
    if ScreenGui and ScreenGui.Parent then
        ScreenGui:Destroy()
    end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Unity Ascent✨💪🏿"
    ScreenGui.Parent = PlayerGui -- Parent to PlayerGui

    -- Create a main frame to hold the buttons
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UNFOLDED_SIZE
    MainFrame.Position = UDim2.new(0.01, 0, 0.01, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    MainFrame.BorderSizePixel = 0
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    -- Create a UI Corner for rounded edges on MainFrame
    local UICornerMain = Instance.new("UICorner")
    UICornerMain.CornerRadius = UDim.new(0, 8)
    UICornerMain.Parent = MainFrame

    -- Create a title label (now also acts as the fold/unfold button)
    TitleLabel = Instance.new("TextButton")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
    TitleLabel.Position = UDim2.new(0, 0, 0, 0)
    TitleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.TextSize = 13
    TitleLabel.Text = "Unity Ascent✨💪🏿"
    TitleLabel.Parent = MainFrame

    makeRainbowText(TitleLabel)

    -- FPS Display Label
    FPSLabel = Instance.new("TextLabel")
    FPSLabel.Name = "FPSLabel"
    FPSLabel.Size = UDim2.new(0.5, -5, 0, INFO_BAR_HEIGHT)
    FPSLabel.Position = UDim2.new(0, 5, 0, TITLE_HEIGHT)
    FPSLabel.BackgroundTransparency = 1
    FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FPSLabel.Font = Enum.Font.SourceSans
    FPSLabel.TextSize = 10
    FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
    FPSLabel.Text = "FPS: loading..."
    FPSLabel.Parent = MainFrame

    makeRainbowText(FPSLabel)

    -- MS (Ping) Display Label
    MSLabel = Instance.new("TextLabel")
    MSLabel.Name = "MSLabel"
    MSLabel.Size = UDim2.new(0.5, 0, 0, INFO_BAR_HEIGHT)
    MSLabel.Position = UDim2.new(0.5, 0, 0, TITLE_HEIGHT)
    MSLabel.BackgroundTransparency = 1
    MSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    MSLabel.Font = Enum.Font.SourceSans
    MSLabel.TextSize = 10
    MSLabel.TextXAlignment = Enum.TextXAlignment.Right
    MSLabel.Text = "MS: loading..."
    MSLabel.Parent = MainFrame

    makeRainbowText(MSLabel)

    -- Create a ScrollingFrame for the content (buttons)
    ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -(TITLE_HEIGHT + INFO_BAR_HEIGHT))
    ContentFrame.Position = UDim2.new(0, 0, 0, TITLE_HEIGHT + INFO_BAR_HEIGHT)
    ContentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ClipsDescendants = true
    ContentFrame.Parent = MainFrame

    -- Scrollbar properties
    ContentFrame.ScrollBarImageTransparency = 0.5
    ContentFrame.ScrollBarThickness = 8
    ContentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    ContentFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always

    -- Fold/Unfold Logic
    local function toggleFold()
        if inCompactMode then return end

        isFolded = not isFolded
        local targetSize = isFolded and FOLDED_SIZE or UNFOLDED_SIZE

        TweenService:Create(MainFrame, TWEEN_INFO, {Size = targetSize}):Play()
        ContentFrame.Visible = not isFolded
        FPSLabel.Visible = not isFolded
        MSLabel.Visible = not isFolded
    end

    TitleLabel.MouseButton1Click:Connect(toggleFold)

    -- Helper function to get tool
    local function equipTool(toolName)
        local tool = LocalPlayer.Backpack:FindFirstChild(toolName)
        if tool and tool.ClassName == "Tool" then
            tool.Parent = LocalPlayer.Character
        end
    end

    -- Function to create a toggle button
    local function createToggleButton(name, yPosition, stateVariableRef, callback)
        local Button = Instance.new("TextButton")
        Button.Name = name:gsub(" ", "")
        Button.Size = BUTTON_SIZE
        Button.Position = UDim2.new(0, BUTTON_INSET_X, 0, yPosition)
        Button.Parent = ContentFrame

        local UICornerBtn = Instance.new("UICorner")
        UICornerBtn.CornerRadius = BUTTON_CORNER_RADIUS
        UICornerBtn.Parent = Button

        -- Rainbowify the text!
        makeRainbowText(Button)

        -- Get current state from the persistent variable
        local isToggled = _G[stateVariableRef] or false

        Button.Text = name .. ": " .. (isToggled and "ON" or "OFF")
        Button.BackgroundColor3 = isToggled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Font = Enum.Font.SourceSansSemibold
        Button.TextSize = BUTTON_TEXT_SIZE

        Button.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            _G[stateVariableRef] = isToggled
            Button.Text = name .. ": " .. (isToggled and "ON" or "OFF")
            Button.BackgroundColor3 = isToggled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
            callback(isToggled)
        end)
    end

    -- Function to create a standard button
    local function createButton(name, yPosition, callback)
        local Button = Instance.new("TextButton")
        Button.Name = name:gsub(" ", "")
        Button.Size = BUTTON_SIZE
        Button.Position = UDim2.new(0, BUTTON_INSET_X, 0, yPosition)
        Button.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.Font = Enum.Font.SourceSansSemibold
        Button.TextSize = BUTTON_TEXT_SIZE
        Button.Text = name
        Button.Parent = ContentFrame

        -- Rainbow text!
        makeRainbowText(Button)

        Button.MouseButton1Click:Connect(callback)

        local UICornerBtn = Instance.new("UICorner")
        UICornerBtn.CornerRadius = BUTTON_CORNER_RADIUS
        UICornerBtn.Parent = Button
    end

    -- Function to get the next Y position for a button/element
    local function getNextY(currentCount)
        return INITIAL_BUTTON_Y + (currentCount * (BUTTON_HEIGHT + VERTICAL_SPACING))
    end

    local buttonCount = 0 -- Keep track of how many buttons/elements are added for yPosition calculation

    --- Auto Rebirth
    buttonCount = buttonCount + 1
    createToggleButton("Auto Rebirth", getNextY(buttonCount - 1), "dragons", function(State)
        dragons = State
        while dragons do
            task.wait(0.1)
            local success, result = pcall(function()
                if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.rebirthRemote then
                    ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                else
                    warn("Auto Rebirth: 'rebirthRemote' not found.")
                end
            end)
            if not success then warn("Auto Rebirth error:", result) end
        end
    end)

    --- Lock UI Position
    buttonCount = buttonCount + 1
    createToggleButton("Lock UI Position", getNextY(buttonCount - 1), "isUIPositionLocked", function(State)
        isUIPositionLocked = State
        MainFrame.Draggable = not isUIPositionLocked and not inCompactMode
    end)

    --- Lock Player Movement
    buttonCount = buttonCount + 1
    createToggleButton("Lock Player Movement", getNextY(buttonCount - 1), "isPlayerMovementLocked", function(State)
        isPlayerMovementLocked = State
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChild("Humanoid")

        if humanoid then
            if isPlayerMovementLocked then
                pcall(function() humanoid.WalkSpeed = 0 end)
                pcall(function() humanoid.JumpPower = 0 end)
            else
                pcall(function() humanoid.WalkSpeed = OriginalWalkSpeed end)
                pcall(function() humanoid.JumpPower = OriginalJumpPower end)
            end
        end
    end)

    --- Compact Mode
    buttonCount = buttonCount + 1
    createToggleButton("Compact Mode", getNextY(buttonCount - 1), "inCompactMode", function(State)
        inCompactMode = State
        if inCompactMode then
            TweenService:Create(MainFrame, TWEEN_INFO, {Size = COMPACT_MODE_SIZE}):Play()
            ContentFrame.Visible = false
            MainFrame.Draggable = false
            TitleLabel.Text = "UA"
            FPSLabel.Visible = false
            MSLabel.Visible = false
        else
            local targetSize = isFolded and FOLDED_SIZE or UNFOLDED_SIZE
            TweenService:Create(MainFrame, TWEEN_INFO, {Size = targetSize}):Play()
            ContentFrame.Visible = not isFolded
            MainFrame.Draggable = not isUIPositionLocked
            TitleLabel.Text = "Unity Ascent✨💪🏿"
            FPSLabel.Visible = not isFolded
            MSLabel.Visible = not isFolded
        end
    end)

    --- Auto Chests
    buttonCount = buttonCount + 1
    createToggleButton("Auto Chests", getNextY(buttonCount - 1), "autoChests", function(State)
        autoChests = State
        local chestTypes = {"Magma Chest", "Mythical Chest", "Golden Chest", "Enchanted Chest", "Legends Chest"}
        local currentIndex = 1

        while autoChests do
            task.wait(0.1)
            local args = {
                [1] = chestTypes[currentIndex]
            }
            local success, result = pcall(function()
                if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.checkChestRemote then
                    ReplicatedStorage.rEvents.checkChestRemote:InvokeServer(unpack(args))
                else
                    warn("Auto Chests: 'checkChestRemote' not found.")
                end
            end)
            if not success then warn("Auto Chests error:", result) end

            currentIndex = currentIndex + 1
            if currentIndex > #chestTypes then
                currentIndex = 1
            end
        end
    end)

    --- Auto Join Brawl
    buttonCount = buttonCount + 1
    createToggleButton("Auto Join Brawl", getNextY(buttonCount - 1), "autoJoinBrawl", function(State)
        autoJoinBrawl = State
        while autoJoinBrawl do
            task.wait(2)
            local args = {
                [1] = "joinBrawl"
            }
            local success, result = pcall(function()
                if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.brawlEvent then
                    ReplicatedStorage.rEvents.brawlEvent:FireServer(unpack(args))
                else
                    warn("Auto Join Brawl: 'brawlEvent' not found.")
                end
            end)
            if not success then warn("Auto Join Brawl error:", result) end
        end
    end)

    --- Turn Small
    buttonCount = buttonCount + 1
    createButton("Turn Small", getNextY(buttonCount - 1), function()
        local args = {
            [1] = "changeSize",
            [2] = 1
        }
        local success, result = pcall(function()
            if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.changeSpeedSizeRemote then
                ReplicatedStorage.rEvents.changeSpeedSizeRemote:InvokeServer(unpack(args))
            else
                warn("Turn Small: 'changeSpeedSizeRemote' not found.")
            end
        end)
        if not success then warn("Turn Small error:", result) end
    end)

    --- Blue Crystal
    buttonCount = buttonCount + 1
    createButton("Blue Crystal", getNextY(buttonCount - 1), function()
        local args = {
            [1] = "openCrystal",
            [2] = "Blue Crystal"
        }
        local success, result = pcall(function()
            if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.openCrystalRemote then
                ReplicatedStorage.rEvents.openCrystalRemote:InvokeServer(unpack(args))
            else
                warn("Blue Crystal: 'openCrystalRemote' not found.")
            end
        end)
        if not success then warn("Blue Crystal error:", result) end
    end)

    --- Green Crystal
    buttonCount = buttonCount + 1
    createButton("Green Crystal", getNextY(buttonCount - 1), function()
        local args = {
            [1] = "openCrystal",
            [2] = "Green Crystal"
        }
        local success, result = pcall(function()
            if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.openCrystalRemote then
                ReplicatedStorage.rEvents.openCrystalRemote:InvokeServer(unpack(args))
            else
                warn("Green Crystal: 'openCrystalRemote' not found.")
            end
        end)
        if not success then warn("Green Crystal error:", result) end
    end)

    --- Mythical Crystal
    buttonCount = buttonCount + 1
    createButton("Mythical Crystal", getNextY(buttonCount - 1), function()
        local args = {
            [1] = "openCrystal",
            [2] = "Mythical Crystal"
        }
        local success, result = pcall(function()
            if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.openCrystalRemote then
                ReplicatedStorage.rEvents.openCrystalRemote:InvokeServer(unpack(args))
            else
                warn("Mythical Crystal: 'openCrystalRemote' not found.")
            end
        end)
        if not success then warn("Mythical Crystal error:", result) end
    end)

    --- Frost Crystal
    buttonCount = buttonCount + 1
    createButton("Frost Crystal", getNextY(buttonCount - 1), function()
        local args = {
            [1] = "openCrystal",
            [2] = "Frost Crystal"
        }
        local success, result = pcall(function()
            if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.openCrystalRemote then
                ReplicatedStorage.rEvents.openCrystalRemote:InvokeServer(unpack(args))
            else
                warn("Frost Crystal: 'openCrystalRemote' not found.")
            end
        end)
        if not success then warn("Frost Crystal error:", result) end
    end)

    --- Inferno Crystal
    buttonCount = buttonCount + 1
    createButton("Inferno Crystal", getNextY(buttonCount - 1), function()
        local args = {
            [1] = "openCrystal",
            [2] = "Inferno Crystal"
        }
        local success, result = pcall(function()
            if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.openCrystalRemote then
                ReplicatedStorage.rEvents.openCrystalRemote:InvokeServer(unpack(args))
            else
                warn("Inferno Crystal: 'openCrystalRemote' not found.")
            end
        end)
        if not success then warn("Inferno Crystal error:", result) end
    end)

    --- Legends Crystal
    buttonCount = buttonCount + 1
    createButton("Legends Crystal", getNextY(buttonCount - 1), function()
        local args = {
            [1] = "openCrystal",
            [2] = "Legends Crystal"
        }
        local success, result = pcall(function()
            if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.openCrystalRemote then
                ReplicatedStorage.rEvents.openCrystalRemote:InvokeServer(unpack(args))
            else
                warn("Legends Crystal: 'openCrystalRemote' not found.")
            end
        end)
        if not success then warn("Legends Crystal error:", result) end
    end)

    --- Muscle Elite Crystal
    buttonCount = buttonCount + 1
    createButton("Muscle Elite Crystal", getNextY(buttonCount - 1), function()
        local args = {
            [1] = "openCrystal",
            [2] = "Muscle Elite Crystal"
        }
        local success, result = pcall(function()
            if ReplicatedStorage.rEvents and ReplicatedStorage.rEvents.openCrystalRemote then
                ReplicatedStorage.rEvents.openCrystalRemote:InvokeServer(unpack(args))
            else
                warn("Muscle Elite Crystal: 'openCrystalRemote' not found.")
            end
        end)
        if not success then warn("Muscle Elite Crystal error:", result) end
    end)

    --- Auto Handstands
    buttonCount = buttonCount + 1
    createToggleButton("Auto Handstands", getNextY(buttonCount - 1), "autoHandstands", function(State)
        autoHandstands = State
        while autoHandstands do
            task.wait(0.1)
            local success, result = pcall(function()
                if LocalPlayer.muscleEvent then
                    LocalPlayer.muscleEvent:FireServer("rep")
                else
                    warn("Auto Handstands: 'muscleEvent' not found.")
                end
   
