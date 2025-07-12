local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = workspace
local Camera = Workspace.CurrentCamera
local TeleportService = game:GetService("TeleportService")
local PlaceId = game.PlaceId
local UserInputService = game:GetService("UserInputService")

local library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)()

-- Variables
local walkSpeedEnabled = false
local walkSpeedValue = 55

local espEnabled = false
local tracersEnabled = false
local usernamesEnabled = false
local espColor = Color3.fromRGB(255, 105, 180)

local rainbowEnabled = false
local normalFOV = 70

local canHop = true
local hopCooldown = 15

-- WalkSpeed Logic
local humChangedConnSpeed

local function setWalkSpeed(value)
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = value
		end
	end
end

local function enableSpeed()
	walkSpeedEnabled = true
	setWalkSpeed(walkSpeedValue)
	local char = LocalPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			if humChangedConnSpeed then humChangedConnSpeed:Disconnect() end
			humChangedConnSpeed = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if walkSpeedEnabled and hum.WalkSpeed ~= walkSpeedValue then
					hum.WalkSpeed = walkSpeedValue
				end
			end)
		end
	end
end

local function disableSpeed()
	walkSpeedEnabled = false
	if humChangedConnSpeed then humChangedConnSpeed:Disconnect() humChangedConnSpeed = nil end
	setWalkSpeed(16)
end

-- Rainbow Character
RunService:BindToRenderStep("RainbowChar", Enum.RenderPriority.Character.Value + 2, function()
	if rainbowEnabled then
		local char = LocalPlayer.Character
		if char then
			local hue = (tick() % 5) / 5
			local color = Color3.fromHSV(hue, 1, 1)
			for _, part in pairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = color
				end
			end
		end
	else
		local char = LocalPlayer.Character
		if char then
			for _, part in pairs(char:GetChildren()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.Color = Color3.new(1,1,1)
				end
			end
		end
	end
end)

-- ESP
local espBoxes = {}
local tracerLines = {}
local nameTexts = {}

local function projectToScreen(pos)
	local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
	if onScreen and screenPos.Z > 0 then
		return Vector2.new(screenPos.X, screenPos.Y)
	end
	return nil
end

local function clearESPForPlayer(player)
	if espBoxes[player] then espBoxes[player].Visible = false espBoxes[player] = nil end
	if tracerLines[player] then tracerLines[player].Visible = false tracerLines[player] = nil end
	if nameTexts[player] then nameTexts[player].Visible = false nameTexts[player] = nil end
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

RunService:BindToRenderStep("ESP", Enum.RenderPriority.Character.Value + 3, function()
	if espEnabled then
		for _, player in pairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
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
						end
					elseif tracerLines[player] then
						tracerLines[player].Visible = false
						tracerLines[player] = nil
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
							elseif nameTexts[player] then
								nameTexts[player].Visible = false
								nameTexts[player] = nil
							end
						elseif nameTexts[player] then
							nameTexts[player].Visible = false
							nameTexts[player] = nil
						end
					elseif nameTexts[player] then
						nameTexts[player].Visible = false
						nameTexts[player] = nil
					end
				else
					clearESPForPlayer(player)
				end
			else
				clearESPForPlayer(player)
			end
		end
	else
		for player, box in pairs(espBoxes) do box.Visible = false end
		for player, line in pairs(tracerLines) do line.Visible = false end
		for player, text in pairs(nameTexts) do text.Visible = false end
	end
end)

-- Server Hop
local function detectSecrets()
	local secretNames = {
		["La Vaca Saturno Saturnita"] = true,
		["Graipuss Medussi"] = true,
		["La Grande Combinasion"] = true,
		["Los Tralalleritos"] = true,
	}
	for _, obj in pairs(Workspace:GetChildren()) do
		if secretNames[obj.Name] then
			return true
		end
	end
	return false
end

local function serverHop()
	if canHop then
		if not detectSecrets() then
			canHop = false
			TeleportService:Teleport(PlaceId)
			task.delay(hopCooldown, function()
				canHop = true
			end)
		end
	end
end

-- UI
local Window = library:CreateWindow({
	Name = "Sakura Hub",
	Size = UDim2.new(0, 525, 0, 1200),
	Themeable = { Info = "Discord Server: VzYTJ7Y", Color = Color3.fromRGB(255, 105, 180) }
})

local MainTab = Window:CreateTab({ Name = "Main" })
local FunTab = Window:CreateTab({ Name = "Fun" })
local ServerTab = Window:CreateTab({ Name = "Server" })

-- Fun Tab
local FunSection = FunTab:CreateSection({ Name = "Fun Features", Side = "Left" })
FunSection:AddToggle({
	Name = "Rainbow Character",
	Flag = "RainbowToggle",
	Callback = function(value)
		rainbowEnabled = value
		if not value then
			local char = LocalPlayer.Character
			if char then
				for _, part in pairs(char:GetChildren()) do
					if part:IsA("BasePart") then
						part.Color = Color3.new(1,1,1)
					end
				end
			end
		end
	end,
})
FunSection:AddButton({ Name = "Set FOV to 120", Callback = function() Camera.FieldOfView = 120 end })
FunSection:AddButton({ Name = "Reset FOV to Default", Callback = function() Camera.FieldOfView = normalFOV end })

-- Movement
local MovementSection = MainTab:CreateSection({ Name = "Movement Controls", Side = "Left" })
MovementSection:AddToggle({
	Name = "Speed Hack",
	Flag = "SpeedToggle",
	Callback = function(v) if v then enableSpeed() else disableSpeed() end end,
})
MovementSection:AddSlider({
	Name = "Walk Speed",
	Flag = "SpeedSlider",
	Value = walkSpeedValue,
	Min = 16,
	Max = 55,
	Precise = 1,
	Callback = function(v) walkSpeedValue = v if walkSpeedEnabled then setWalkSpeed(v) end end,
})
MovementSection:AddButton({
	Name = "Teleport Up",
	Callback = function()
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = root.CFrame + Vector3.new(0, 160, 0)
		end
	end
})
MovementSection:AddButton({
	Name = "Teleport Down",
	Callback = function()
		local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = root.CFrame - Vector3.new(0, 160, 0)
		end
	end
})

-- Server Tab (new)
local ServerSection = ServerTab:CreateSection({ Name = "Server Actions", Side = "Left" })
ServerSection:AddButton({ Name = "Server Hop", Callback = function() serverHop() end })
ServerSection:AddButton({ Name = "Rejoin", Callback = function() TeleportService:Teleport(PlaceId) end })

-- ESP
local ESPSection = MainTab:CreateSection({ Name = "ESP Settings", Side = "Left" })
ESPSection:AddToggle({ Name = "Player ESP", Flag = "ESPEnable", Callback = function(v) espEnabled = v end })
ESPSection:AddToggle({ Name = "Tracers", Flag = "TracersToggle", Callback = function(v) tracersEnabled = v end })
ESPSection:AddToggle({ Name = "Usernames", Flag = "UsernamesToggle", Callback = function(v) usernamesEnabled = v end })
ESPSection:AddColor({ Name = "ESP Color", Flag = "ESPColorPicker", Color = espColor, Callback = function(v) espColor = v end })

Window:SetOpen(true)
library:LoadTheme("kura")
library:SendNotification("Loaded Sakura Hub", 5)


