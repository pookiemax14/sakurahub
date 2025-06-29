local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = workspace
local Camera = Workspace.CurrentCamera

local flyEnabled = false
local flySpeed = 50
local bodyGyro, bodyVelocity

local antiRagdollEnabled = false

local espEnabled = false
local tracersEnabled = false
local usernamesEnabled = false
local espColor = Color3.fromRGB(255, 0, 0)

local brainrotGodESPEnabled = false

local espBoxes = {}
local tracerLines = {}
local nameTexts = {}

local brainrotBoxes = {}
local brainrotNameTexts = {}

local colorsByName = {
    ["tralalero tralala"] = Color3.fromRGB(0, 0, 255),        -- Blue
    ["odin din din dun"] = Color3.fromRGB(255, 165, 0),      -- Orange
    ["gattatino nyanino"] = Color3.fromRGB(255, 192, 203),   -- Pink (cat Brainrot)
    ["matteo"] = Color3.fromRGB(165, 42, 42),                -- Brown (Matteo)
    ["cocofanto elefanto"] = Color3.fromRGB(139, 69, 19),    -- Dark Brown
    ["giraffa celeste"] = Color3.fromRGB(0, 255, 0),         -- Green
}

local function getColorForModelName(name)
    local lowerName = string.lower(name)
    for prefix, color in pairs(colorsByName) do
        if lowerName:find("^" .. prefix) then
            return color
        end
    end
    return Color3.new(1, 1, 1) -- Default white
end

local function applyFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if flyEnabled then
        hum.WalkSpeed = 0
        hum.JumpPower = 0

        if not bodyGyro then
            bodyGyro = Instance.new("BodyGyro", hrp)
            bodyGyro.P = 9e4
            bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bodyGyro.CFrame = hrp.CFrame
        end
        if not bodyVelocity then
            bodyVelocity = Instance.new("BodyVelocity", hrp)
            bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end

        local moveDirection = Vector3.new(0, 0, 0)
        local cameraCFrame = Camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + cameraCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - cameraCFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - cameraCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + cameraCFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * flySpeed
            bodyGyro.CFrame = cameraCFrame
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    else
        if hum.WalkSpeed ~= 16 then
            hum.WalkSpeed = 16
        end
        if hum.JumpPower ~= 50 then
            hum.JumpPower = 50
        end
        if bodyGyro then
            bodyGyro:Destroy()
            bodyGyro = nil
        end
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
    end
end

local function applyAntiRagdoll()
    if not antiRagdollEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
    end
end

local function projectToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    if onScreen and screenPos.Z > 0 then
        return Vector2.new(screenPos.X, screenPos.Y)
    end
    return nil
end

local function calculateBox(player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local heightStuds = 7.3
    local baseWidthStuds = heightStuds / 5
    local widthStuds = baseWidthStuds * 1.5

    local rootCFrame = rootPart.CFrame
    local top = rootCFrame.Position + Vector3.new(0, heightStuds / 2, 0)
    local bottom = rootCFrame.Position - Vector3.new(0, heightStuds / 2, 0)

    local topScreen = projectToScreen(top)
    local bottomScreen = projectToScreen(bottom)
    if not topScreen or not bottomScreen then return nil end

    local boxHeight = (bottomScreen - topScreen).Magnitude
    local boxWidth = math.max(boxHeight / (heightStuds / widthStuds), 15)

    local topLeft = Vector2.new(topScreen.X - boxWidth / 2, topScreen.Y)
    return topLeft, boxWidth, boxHeight
end

local function clearESPForPlayer(player)
    if espBoxes[player] then
        espBoxes[player].Visible = false
        espBoxes[player] = nil
    end
    if tracerLines[player] then
        tracerLines[player].Visible = false
        tracerLines[player] = nil
    end
    if nameTexts[player] then
        nameTexts[player].Visible = false
        nameTexts[player] = nil
    end
end

local function onPlayerAdded(player)
    player.CharacterRemoving:Connect(function()
        clearESPForPlayer(player)
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

local function getPartCorners(part)
    local cf = part.CFrame
    local size = part.Size / 2

    return {
        cf * Vector3.new( size.X,  size.Y,  size.Z),
        cf * Vector3.new( size.X,  size.Y, -size.Z),
        cf * Vector3.new( size.X, -size.Y,  size.Z),
        cf * Vector3.new( size.X, -size.Y, -size.Z),
        cf * Vector3.new(-size.X,  size.Y,  size.Z),
        cf * Vector3.new(-size.X,  size.Y, -size.Z),
        cf * Vector3.new(-size.X, -size.Y,  size.Z),
        cf * Vector3.new(-size.X, -size.Y, -size.Z),
    }
end

local MAX_BOX_SIZE = 350  -- max pixels width/height

local function calculateBoundingBox(model)
    local corners = {}
    local primaryPart = model:FindFirstChild("RootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return nil, nil end
    local centerPos = primaryPart.Position

    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            if (part.Position - centerPos).Magnitude <= 20 then
                local partCorners = getPartCorners(part)
                for _, corner in pairs(partCorners) do
                    local screenPos = projectToScreen(corner)
                    if screenPos then
                        table.insert(corners, screenPos)
                    end
                end
            end
        end
    end

    if #corners == 0 then return nil, nil end

    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge

    for _, corner in pairs(corners) do
        if corner.X < minX then minX = corner.X end
        if corner.X > maxX then maxX = corner.X end
        if corner.Y < minY then minY = corner.Y end
        if corner.Y > maxY then maxY = corner.Y end
    end

    local width = maxX - minX
    local height = maxY - minY

    if width > MAX_BOX_SIZE then
        local centerX = (minX + maxX) / 2
        minX = centerX - MAX_BOX_SIZE / 2
        maxX = centerX + MAX_BOX_SIZE / 2
    end
    if height > MAX_BOX_SIZE then
        local centerY = (minY + maxY) / 2
        minY = centerY - MAX_BOX_SIZE / 2
        maxY = centerY + MAX_BOX_SIZE / 2
    end

    local topLeft = Vector2.new(minX, minY)
    local size = Vector2.new(maxX - minX, maxY - minY)

    return topLeft, size
end

local function isBrainrotModel(name)
    local cleanName = string.lower(name):gsub("^%s*(.-)%s*$", "%1")
    return cleanName:find("^tralalero tralala") or cleanName:find("^odin din din dun") or cleanName:find("^gattatino nyanino") or cleanName:find("^matteo") or cleanName:find("^cocofanto elefanto") or cleanName:find("^giraffa celeste")
end

local selectedBrainrots = {
    ["tralalero tralala"] = true,
    ["odin din din dun"] = true,
    ["gattatino nyanino"] = true,
    ["matteo"] = true,
    ["cocofanto elefanto"] = true,
    ["giraffa celeste"] = true,
}

local function isSelectedBrainrot(name)
    local lowerName = string.lower(name)
    for prefix, _ in pairs(selectedBrainrots) do
        if lowerName:find("^" .. prefix) then
            return selectedBrainrots[prefix]
        end
    end
    return false
end

local function drawBrainrotESP(model)
    local color = getColorForModelName(model.Name)

    local topLeft, size = calculateBoundingBox(model)
    if not topLeft or not size then return end

    if not brainrotBoxes[model] then
        brainrotBoxes[model] = Drawing.new("Square")
        brainrotBoxes[model].Thickness = 2
        brainrotBoxes[model].Filled = false
    end
    local box = brainrotBoxes[model]
    box.Position = topLeft
    box.Size = size
    box.Color = color
    box.Visible = true

    local primaryPart = model:FindFirstChild("RootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if primaryPart then
        local headPos, onScreen = Camera:WorldToViewportPoint(primaryPart.Position + Vector3.new(0, 3, 0))
        if onScreen and headPos.Z > 0 then
            if not brainrotNameTexts[model] then
                local text = Drawing.new("Text")
                text.Center = true
                text.Outline = true
                text.Font = 3
                text.Size = 18
                brainrotNameTexts[model] = text
            end
            local text = brainrotNameTexts[model]
            text.Text = model.Name
            text.Position = Vector2.new(headPos.X, headPos.Y)
            text.Color = color
            text.Visible = true
        elseif brainrotNameTexts[model] then
            brainrotNameTexts[model].Visible = false
        end
    end
end

RunService.RenderStepped:Connect(function()
    applyFly()
    applyAntiRagdoll()

    for _, player in pairs(Players:GetPlayers()) do
        local valid = player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild('HumanoidRootPart')
            and player.Character:FindFirstChild('Humanoid')
            and player.Character.Humanoid.Health > 0

        if valid then
            if espEnabled then
                local topLeft, boxWidth, boxHeight = calculateBox(player)
                if topLeft then
                    if not espBoxes[player] then
                        espBoxes[player] = Drawing.new("Square")
                        espBoxes[player].Thickness = 2
                        espBoxes[player].Filled = false
                    end
                    local box = espBoxes[player]
                    box.Position = topLeft
                    box.Size = Vector2.new(boxWidth, boxHeight)
                    box.Color = espColor
                    box.Visible = true
                else
                    clearESPForPlayer(player)
                end
            else
                clearESPForPlayer(player)
            end

            if tracersEnabled then
                local rootPosScreen = projectToScreen(player.Character.HumanoidRootPart.Position)
                if rootPosScreen then
                    if not tracerLines[player] then
                        tracerLines[player] = Drawing.new("Line")
                        tracerLines[player].Thickness = 1
                    end
                    local line = tracerLines[player]
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = rootPosScreen
                    line.Color = espColor
                    line.Visible = true
                else
                    if tracerLines[player] then
                        tracerLines[player].Visible = false
                        tracerLines[player] = nil
                    end
                end
            else
                if tracerLines[player] then
                    tracerLines[player].Visible = false
                    tracerLines[player] = nil
                end
            end

            if usernamesEnabled then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local headPosScreen = projectToScreen(head.Position + Vector3.new(0, 0.5, 0))
                    if headPosScreen then
                        if not nameTexts[player] then
                            nameTexts[player] = Drawing.new("Text")
                            nameTexts[player].Center = true
                            nameTexts[player].Outline = true
                            nameTexts[player].Font = 3
                            nameTexts[player].Size = 16
                        end
                        local text = nameTexts[player]
                        text.Text = player.Name
                        text.Position = headPosScreen
                        text.Color = espColor
                        text.Visible = true
                    else
                        if nameTexts[player] then
                            nameTexts[player].Visible = false
                            nameTexts[player] = nil
                        end
                    end
                else
                    if nameTexts[player] then
                        nameTexts[player].Visible = false
                        nameTexts[player] = nil
                    end
                end
            else
                if nameTexts[player] then
                    nameTexts[player].Visible = false
                    nameTexts[player] = nil
                end
            end
        else
            clearESPForPlayer(player)
        end
    end

    if brainrotGodESPEnabled then
        for _, model in pairs(Workspace:GetChildren()) do
            if model:IsA("Model") and isBrainrotModel(model.Name) and isSelectedBrainrot(model.Name) then
                drawBrainrotESP(model)
            end
        end
    else
        for model, box in pairs(brainrotBoxes) do
            box.Visible = false
        end
        for model, text in pairs(brainrotNameTexts) do
            text.Visible = false
        end
    end
end)

local Window = Rayfield:CreateWindow({
    Name = "Sakura Hub",
    LoadingTitle = "Loading Sakura Hub...",
    LoadingSubtitle = "Welcome!",
    Theme = "Bloom",
    ConfigurationSaving = {
        Enabled = false,
    },

    Discord = {
        Enabled = true,
        Invite = "dRpMySe4UA",
        RememberJoins = true,
    },

    KeySystem = false,
    KeySettings = {
        Title = "Sakura Hub Key System",
        Subtitle = "Enter your key",
        Note = "Obtain your key from our Discord:\nhttps://discord.gg/dRpMySe4UA",
        FileName = "SakuraKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"sakura1982444"},
    },
})

local MainTab = Window:CreateTab("Main", "home")

local FlyToggle = MainTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(value)
        flyEnabled = value
    end,
})

MainTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 40},
    Increment = 1,
    CurrentValue = flySpeed,
    Flag = "FlySpeedSlider",
    Callback = function(value)
        flySpeed = value
    end,
})

MainTab:CreateToggle({
    Name = "Anti Ragdoll",
    CurrentValue = false,
    Flag = "AntiRagdollToggle",
    Callback = function(value)
        antiRagdollEnabled = value
    end,
})

local BrainrotESPTab = Window:CreateTab("Brainrot ESP", "eye")

BrainrotESPTab:CreateToggle({
    Name = "Brainrot God ESP",
    CurrentValue = false,
    Flag = "BrainrotGodESPEnable",
    Callback = function(value)
        brainrotGodESPEnabled = value
    end,
})

BrainrotESPTab:CreateToggle({
    Name = "Brainrot Secret ESP",
    CurrentValue = false,
    Flag = "BrainrotSecretESPEnable",
    Callback = function(value)
        -- No logic here as requested
    end,
})

local PlayerESPTab = Window:CreateTab("Player ESP", "eye")

PlayerESPTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESPEnable",
    Callback = function(value)
        espEnabled = value
    end,
})

PlayerESPTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Flag = "TracersToggle",
    Callback = function(value)
        tracersEnabled = value
    end,
})

PlayerESPTab:CreateToggle({
    Name = "Usernames",
    CurrentValue = false,
    Flag = "UsernamesToggle",
    Callback = function(value)
        usernamesEnabled = value
    end,
})

PlayerESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = espColor,
    Flag = "ESPColorPicker",
    Callback = function(value)
        espColor = value
    end,
})

Rayfield:LoadConfiguration()

flyEnabled = false
FlyToggle:Set(false)
