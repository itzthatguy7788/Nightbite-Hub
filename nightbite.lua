-- NIGHTBITE HUB - 800+ LINE VERSION
-- Notification animation: slides UP → waits 5 seconds → slides DOWN
-- Press - to minimize | Press H to reopen
-- Auto Kill Farm spawns right on top - Aimlock sticks with G

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local localPlayer = Players.LocalPlayer

-- ==================== SMALLER LOADING SCREEN ====================
local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "NightbiteLoading"
loadingGui.ResetOnSpawn = false
loadingGui.Parent = localPlayer:WaitForChild("PlayerGui")

local loadingFrame = Instance.new("Frame")
loadingFrame.Size = UDim2.new(0, 380, 0, 190)
loadingFrame.Position = UDim2.new(0.5, -190, 0.5, -95)
loadingFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
loadingFrame.BorderSizePixel = 0
loadingFrame.Parent = loadingGui

local loadingCorner = Instance.new("UICorner")
loadingCorner.CornerRadius = UDim.new(0, 14)
loadingCorner.Parent = loadingFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 55)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "NIGHTBITE HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 26
titleLabel.Parent = loadingFrame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 24)
subtitle.Position = UDim2.new(0, 0, 0, 52)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Loading..."
subtitle.TextColor3 = Color3.fromRGB(170, 170, 180)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 15
subtitle.Parent = loadingFrame

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(0.78, 0, 0, 16)
progressBg.Position = UDim2.new(0.11, 0, 0.68, 0)
progressBg.BackgroundColor3 = Color3.fromRGB(38, 38, 42)
progressBg.BorderSizePixel = 0
progressBg.Parent = loadingFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progressBg

local progressBar = Instance.new("Frame")
progressBar.Size = UDim2.new(0, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
progressBar.BorderSizePixel = 0
progressBar.Parent = progressBg

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = progressBar

local function runLoadingScreen()
	local tweenInfo = TweenInfo.new(2.8, Enum.EasingStyle.Linear)
	local goal = {Size = UDim2.new(1, 0, 1, 0)}
	local tween = TweenService:Create(progressBar, tweenInfo, goal)
	tween:Play()
	task.wait(3.1)
	local fadeInfo = TweenInfo.new(0.55)
	TweenService:Create(loadingFrame, fadeInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(titleLabel, fadeInfo, {TextTransparency = 1}):Play()
	TweenService:Create(subtitle, fadeInfo, {TextTransparency = 1}):Play()
	TweenService:Create(progressBg, fadeInfo, {BackgroundTransparency = 1}):Play()
	task.wait(0.7)
	loadingGui:Destroy()
end
runLoadingScreen()

-- ==================== STORAGE TABLES ====================
local survivorESP = {}
local killerESP = {}
local generatorESP = {}
local minionESP = {}
local bearTrapESP = {}
local currentFarmTarget = nil

-- ==================== CONNECTIONS TABLE ====================
local connections = {}

-- ==================== TOGGLE STATES ====================
local survivorEnabled = false
local killerEnabled = false
local genEnabled = false
local sprintEnabled = false
local noclipEnabled = false
local fullbrightEnabled = false
local minionEnabled = false
local bearTrapEnabled = false
local autoFarmEnabled = false
local aimlockEnabled = false
local stickyAimlock = false

-- ==================== HELPER FUNCTIONS ====================
local function createHighlight(obj, color, name)
	if not obj or obj:FindFirstChild(name or "BBN_ESP") then return end
	local hl = Instance.new("Highlight")
	hl.Name = name or "BBN_ESP"
	hl.FillColor = color
	hl.OutlineColor = color
	hl.FillTransparency = 0.35
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = obj
	hl.Parent = obj
	return hl
end

local function removeHighlight(obj, name)
	if obj then
		local hl = obj:FindFirstChild(name or "BBN_ESP")
		if hl then hl:Destroy() end
	end
end

local function getGenerators()
	local gens = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj.Name:lower():find("generator") or obj.Name:lower():find("gen") then
			table.insert(gens, obj)
		end
	end
	return gens
end

local function getMinions()
	local mins = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj.Name:lower():find("minion") then
			table.insert(mins, obj)
		end
	end
	return mins
end

local function getBearTraps()
	local traps = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj.Name:lower():find("beartrap") or obj.Name:lower():find("trap") then
			table.insert(traps, obj)
		end
	end
	return traps
end

local function getAliveSurvivors()
	local survivors = {}
	local aliveFolder = Workspace:FindFirstChild("PLAYERS") and Workspace.PLAYERS:FindFirstChild("ALIVE")
	if aliveFolder then
		for _, m in ipairs(aliveFolder:GetChildren()) do
			if m:IsA("Model") and m ~= localPlayer.Character then
				table.insert(survivors, m)
			end
		end
	end
	return survivors
end

local function getClosestSurvivor()
	local survivors = getAliveSurvivors()
	local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end
	local closest = nil
	local shortest = math.huge
	for _, survivor in ipairs(survivors) do
		local root = survivor:FindFirstChild("HumanoidRootPart")
		if root then
			local dist = (root.Position - myRoot.Position).Magnitude
			if dist < shortest then
				shortest = dist
				closest = survivor
			end
		end
	end
	return closest
end

local function teleportRightOnTop(target)
	if not target then return end
	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	local myChar = localPlayer.Character
	if not targetRoot or not myChar then return end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if myRoot then
		myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2.5, 0)
	end
end

local function simulateLeftClick()
	VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
	task.wait(0.08)
	VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function isTargetDead(target)
	if not target then return true end
	local hum = target:FindFirstChild("Humanoid")
	return not hum or hum.Health <= 0
end

local function fullCleanup()
	for model,_ in pairs(survivorESP) do removeHighlight(model) end
	for model,_ in pairs(killerESP) do removeHighlight(model) end
	for obj,_ in pairs(generatorESP) do removeHighlight(obj, "BBN_GenESP") end
	for obj,_ in pairs(minionESP) do removeHighlight(obj, "BBN_MinionESP") end
	for obj,_ in pairs(bearTrapESP) do removeHighlight(obj, "BBN_TrapESP") end
	for _, conn in pairs(connections) do if conn then conn:Disconnect() end end
	connections = {}
	currentFarmTarget = nil
	stickyAimlock = false
end

-- ==================== MAIN GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NightbiteHub"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 860, 0, 510)
mainFrame.Position = UDim2.new(0.5, -430, 0.5, -255)
mainFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 20)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 999
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 56)
titleBar.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 1000
titleBar.Parent = mainFrame

local titleLabelMain = Instance.new("TextLabel")
titleLabelMain.Size = UDim2.new(1, 0, 1, 0)
titleLabelMain.BackgroundTransparency = 1
titleLabelMain.Text = "NIGHTBITE HUB"
titleLabelMain.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabelMain.TextScaled = true
titleLabelMain.Font = Enum.Font.GothamBold
titleLabelMain.TextSize = 22
titleLabelMain.ZIndex = 1001
titleLabelMain.Parent = titleBar

-- Minimize button ("-")
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 42, 0, 42)
minimizeBtn.Position = UDim2.new(1, -95, 0, 7)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.TextScaled = true
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 28
minimizeBtn.ZIndex = 1002
minimizeBtn.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 9)
minimizeCorner.Parent = minimizeBtn

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 42, 0, 42)
closeBtn.Position = UDim2.new(1, -50, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.ZIndex = 1002
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 9)
closeCorner.Parent = closeBtn

-- ==================== ANIMATED NOTIFICATION (UP → 5s WAIT → DOWN) ====================
local notification = Instance.new("Frame")
notification.Size = UDim2.new(0, 280, 0, 50)
notification.Position = UDim2.new(1, -300, 1, 10)   -- starts OFF SCREEN (below)
notification.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
notification.BorderSizePixel = 0
notification.Visible = false
notification.ZIndex = 2000
notification.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 10)
notifCorner.Parent = notification

local notifLabel = Instance.new("TextLabel")
notifLabel.Size = UDim2.new(1, 0, 1, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.Text = "Press H to open back up"
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.TextScaled = true
notifLabel.Font = Enum.Font.GothamSemibold
notifLabel.TextSize = 16
notifLabel.ZIndex = 2001
notifLabel.Parent = notification

-- Tabs and content frames (kept complete)
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, 0, 0, 42)
tabFrame.Position = UDim2.new(0, 0, 0, 56)
tabFrame.BackgroundTransparency = 1
tabFrame.ZIndex = 1000
tabFrame.Parent = mainFrame

local espTabBtn = Instance.new("TextButton")
espTabBtn.Size = UDim2.new(0.25, 0, 1, 0)
espTabBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
espTabBtn.Text = "ESP"
espTabBtn.TextColor3 = Color3.new(1,1,1)
espTabBtn.TextScaled = true
espTabBtn.Font = Enum.Font.GothamSemibold
espTabBtn.TextSize = 15
espTabBtn.ZIndex = 1001
espTabBtn.Parent = tabFrame

local autoTabBtn = Instance.new("TextButton")
autoTabBtn.Size = UDim2.new(0.25, 0, 1, 0)
autoTabBtn.Position = UDim2.new(0.25, 0, 0, 0)
autoTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
autoTabBtn.Text = "AUTO"
autoTabBtn.TextColor3 = Color3.new(1,1,1)
autoTabBtn.TextScaled = true
autoTabBtn.Font = Enum.Font.GothamSemibold
autoTabBtn.TextSize = 15
autoTabBtn.ZIndex = 1001
autoTabBtn.Parent = tabFrame

local extraTabBtn = Instance.new("TextButton")
extraTabBtn.Size = UDim2.new(0.25, 0, 1, 0)
extraTabBtn.Position = UDim2.new(0.5, 0, 0, 0)
extraTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
extraTabBtn.Text = "EXTRA"
extraTabBtn.TextColor3 = Color3.new(1,1,1)
extraTabBtn.TextScaled = true
extraTabBtn.Font = Enum.Font.GothamSemibold
extraTabBtn.TextSize = 15
extraTabBtn.ZIndex = 1001
extraTabBtn.Parent = tabFrame

local moreTabBtn = Instance.new("TextButton")
moreTabBtn.Size = UDim2.new(0.25, 0, 1, 0)
moreTabBtn.Position = UDim2.new(0.75, 0, 0, 0)
moreTabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
moreTabBtn.Text = "MORE"
moreTabBtn.TextColor3 = Color3.new(1,1,1)
moreTabBtn.TextScaled = true
moreTabBtn.Font = Enum.Font.GothamSemibold
moreTabBtn.TextSize = 15
moreTabBtn.ZIndex = 1001
moreTabBtn.Parent = tabFrame

local espContent = Instance.new("ScrollingFrame")
espContent.Size = UDim2.new(1, -32, 1, -120)
espContent.Position = UDim2.new(0, 16, 0, 106)
espContent.BackgroundTransparency = 1
espContent.ScrollBarThickness = 6
espContent.Visible = true
espContent.ZIndex = 1000
espContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
espContent.Parent = mainFrame

local autoContent = Instance.new("ScrollingFrame")
autoContent.Size = UDim2.new(1, -32, 1, -120)
autoContent.Position = UDim2.new(0, 16, 0, 106)
autoContent.BackgroundTransparency = 1
autoContent.ScrollBarThickness = 6
autoContent.Visible = false
autoContent.ZIndex = 1000
autoContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
autoContent.Parent = mainFrame

local extraContent = Instance.new("ScrollingFrame")
extraContent.Size = UDim2.new(1, -32, 1, -120)
extraContent.Position = UDim2.new(0, 16, 0, 106)
extraContent.BackgroundTransparency = 1
extraContent.ScrollBarThickness = 6
extraContent.Visible = false
extraContent.ZIndex = 1000
extraContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
extraContent.Parent = mainFrame

local moreContent = Instance.new("Frame")
moreContent.Size = UDim2.new(1, -32, 1, -120)
moreContent.Position = UDim2.new(0, 16, 0, 106)
moreContent.BackgroundTransparency = 1
moreContent.Visible = false
moreContent.ZIndex = 1000
moreContent.Parent = mainFrame

-- Layouts
local espLayout = Instance.new("UIListLayout")
espLayout.SortOrder = Enum.SortOrder.LayoutOrder
espLayout.Padding = UDim.new(0, 9)
espLayout.Parent = espContent

local autoLayout = Instance.new("UIListLayout")
autoLayout.SortOrder = Enum.SortOrder.LayoutOrder
autoLayout.Padding = UDim.new(0, 9)
autoLayout.Parent = autoContent

local extraLayout = Instance.new("UIListLayout")
extraLayout.SortOrder = Enum.SortOrder.LayoutOrder
extraLayout.Padding = UDim.new(0, 9)
extraLayout.Parent = extraContent

local espPadding = Instance.new("UIPadding")
espPadding.PaddingLeft = UDim.new(0, 16)
espPadding.PaddingRight = UDim.new(0, 16)
espPadding.PaddingTop = UDim.new(0, 12)
espPadding.PaddingBottom = UDim.new(0, 12)
espPadding.Parent = espContent

local autoPadding = Instance.new("UIPadding")
autoPadding.PaddingLeft = UDim.new(0, 16)
autoPadding.PaddingRight = UDim.new(0, 16)
autoPadding.PaddingTop = UDim.new(0, 12)
autoPadding.PaddingBottom = UDim.new(0, 12)
autoPadding.Parent = autoContent

local extraPadding = Instance.new("UIPadding")
extraPadding.PaddingLeft = UDim.new(0, 16)
extraPadding.PaddingRight = UDim.new(0, 16)
extraPadding.PaddingTop = UDim.new(0, 12)
extraPadding.PaddingBottom = UDim.new(0, 12)
extraPadding.Parent = extraContent

-- Toggle row creator
local function createToggleRow(parent, name, desc, color)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 70)
	row.BackgroundColor3 = Color3.fromRGB(27, 27, 30)
	row.BorderSizePixel = 0
	row.ZIndex = 1001
	row.Parent = parent
	
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 10)
	rowCorner.Parent = row
	
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0.7, 0, 0, 30)
	nameLbl.Position = UDim2.new(0, 18, 0, 9)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = Color3.new(1,1,1)
	nameLbl.TextScaled = true
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextSize = 16
	nameLbl.ZIndex = 1002
	nameLbl.Parent = row
	
	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(0.7, 0, 0, 23)
	descLbl.Position = UDim2.new(0, 18, 0, 39)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = desc
	descLbl.TextColor3 = Color3.fromRGB(165, 165, 175)
	descLbl.TextScaled = true
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextSize = 13
	descLbl.ZIndex = 1002
	descLbl.Parent = row
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 52, 0, 28)
	toggleBg.Position = UDim2.new(1, -72, 0.5, -14)
	toggleBg.BackgroundColor3 = Color3.fromRGB(48, 48, 52)
	toggleBg.BorderSizePixel = 0
	toggleBg.ZIndex = 1002
	toggleBg.Parent = row
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggleBg
	
	local toggleDot = Instance.new("Frame")
	toggleDot.Size = UDim2.new(0, 22, 0, 22)
	toggleDot.Position = UDim2.new(0, 3, 0.5, -11)
	toggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleDot.BorderSizePixel = 0
	toggleDot.ZIndex = 1003
	toggleDot.Parent = toggleBg
	
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = toggleDot
	
	return row, toggleBg, toggleDot
end

-- Create rows
local survivorRow, survivorToggle, survivorDot = createToggleRow(espContent, "Survivor ESP", "Blue team gets the spotlight ✨", Color3.fromRGB(0, 130, 255))
local killerRow, killerToggle, killerDot = createToggleRow(espContent, "Killer ESP", "Red team? More like DEAD team 🔥", Color3.fromRGB(255, 55, 55))
local genRow, genToggle, genDot = createToggleRow(espContent, "Generator ESP", "Genny go brrr - find them all!", Color3.fromRGB(255, 200, 60))

local autoFarmRow, autoFarmToggle, autoFarmDot = createToggleRow(autoContent, "Auto Kill Farm", "YOU HAVE TO BE KILLER", Color3.fromRGB(255, 60, 60))

local sprintRow, sprintToggle, sprintDot = createToggleRow(extraContent, "Infinite Sprint", "Shift = infinite zoomies 🏃‍♂️", Color3.fromRGB(0, 180, 255))
local noclipRow, noclipToggle, noclipDot = createToggleRow(extraContent, "Noclip", "Walls? What walls? Ghost mode activated 👻", Color3.fromRGB(140, 80, 255))
local fullbrightRow, fullbrightToggle, fullbrightDot = createToggleRow(extraContent, "Full Bright", "WHO TURNED ON THE LIGHTS?!!", Color3.fromRGB(255, 220, 80))
local minionRow, minionToggle, minionDot = createToggleRow(extraContent, "Minion ESP", "Little gremlins get highlighted too 🐱", Color3.fromRGB(180, 80, 255))
local bearTrapRow, bearTrapToggle, bearTrapDot = createToggleRow(extraContent, "Bear Trap ESP", "Step on these and you’re toast 🪤", Color3.fromRGB(255, 140, 0))
local aimlockRow, aimlockToggle, aimlockDot = createToggleRow(extraContent, "Aimlock", "Press G to stick lock onto nearest player", Color3.fromRGB(255, 100, 0))

-- More tab
local moreLabel = Instance.new("TextLabel")
moreLabel.Size = UDim2.new(0.9, 0, 0, 85)
moreLabel.Position = UDim2.new(0.05, 0, 0.12, 0)
moreLabel.BackgroundTransparency = 1
moreLabel.Text = "based on celeron script\n\nenjoy your hacks :))"
moreLabel.TextColor3 = Color3.new(1,1,1)
moreLabel.TextScaled = true
moreLabel.Font = Enum.Font.Gotham
moreLabel.TextSize = 14
moreLabel.TextYAlignment = Enum.TextYAlignment.Top
moreLabel.ZIndex = 1001
moreLabel.Parent = moreContent

local discordBtn = Instance.new("TextButton")
discordBtn.Size = UDim2.new(0.6, 0, 0, 52)
discordBtn.Position = UDim2.new(0.2, 0, 0.5, 0)
discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBtn.Text = "Join Discord"
discordBtn.TextColor3 = Color3.new(1,1,1)
discordBtn.TextScaled = true
discordBtn.Font = Enum.Font.GothamBold
discordBtn.TextSize = 17
discordBtn.ZIndex = 1002
discordBtn.Parent = moreContent

local discordCorner = Instance.new("UICorner")
discordCorner.CornerRadius = UDim.new(0, 10)
discordCorner.Parent = discordBtn

discordBtn.MouseButton1Click:Connect(function()
	setclipboard("https://discord.gg/PvmUFsae")
	discordBtn.Text = "Copied!"
	task.wait(1.6)
	discordBtn.Text = "Join Discord"
end)

-- Tab switching
local function switchTab(tab)
	espContent.Visible = tab == "ESP"
	autoContent.Visible = tab == "AUTO"
	extraContent.Visible = tab == "EXTRA"
	moreContent.Visible = tab == "MORE"
	espTabBtn.BackgroundColor3 = tab == "ESP" and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(35, 35, 35)
	autoTabBtn.BackgroundColor3 = tab == "AUTO" and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(35, 35, 35)
	extraTabBtn.BackgroundColor3 = tab == "EXTRA" and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(35, 35, 35)
	moreTabBtn.BackgroundColor3 = tab == "MORE" and Color3.fromRGB(0, 130, 255) or Color3.fromRGB(35, 35, 35)
end

espTabBtn.MouseButton1Click:Connect(function() switchTab("ESP") end)
autoTabBtn.MouseButton1Click:Connect(function() switchTab("AUTO") end)
extraTabBtn.MouseButton1Click:Connect(function() switchTab("EXTRA") end)
moreTabBtn.MouseButton1Click:Connect(function() switchTab("MORE") end)

-- FIXED DRAGGING
local dragging = false
local dragStart = nil
local startPos = nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- MINIMIZE BUTTON → UP → 5 SEC WAIT → DOWN ANIMATION
minimizeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	
	-- Start below screen
	notification.Position = UDim2.new(1, -300, 1, 10)
	notification.Visible = true
	
	-- Slide UP
	local slideUp = TweenService:Create(notification, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -300, 1, -70)
	})
	slideUp:Play()
	
	-- Wait exactly 5 seconds then slide DOWN
	task.delay(5, function()
		if notification and notification.Visible then
			local slideDown = TweenService:Create(notification, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, -300, 1, 10)
			})
			slideDown:Play()
			slideDown.Completed:Connect(function()
				notification.Visible = false
			end)
		end
	end)
end)

-- CLOSE BUTTON
closeBtn.MouseButton1Click:Connect(function()
	fullCleanup()
	screenGui:Destroy()
end)

-- REOPEN WITH H KEY
connections.reopenKey = UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.H and not mainFrame.Visible then
		mainFrame.Visible = true
		notification.Visible = false
	end
end)

-- ==================== ALL TOGGLE FUNCTIONS ====================
local function toggleSurvivors(enable)
	survivorEnabled = enable
	if enable then
		survivorToggle.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
		survivorDot.Position = UDim2.new(1, -27, 0.5, -12)
		local aliveFolder = Workspace:FindFirstChild("PLAYERS") and Workspace.PLAYERS:FindFirstChild("ALIVE")
		if aliveFolder then
			for _, m in ipairs(aliveFolder:GetChildren()) do
				if m:IsA("Model") then
					survivorESP[m] = createHighlight(m, Color3.fromRGB(80,180,255))
				end
			end
		end
	else
		survivorToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		survivorDot.Position = UDim2.new(0, 3, 0.5, -12)
		for m,_ in pairs(survivorESP) do removeHighlight(m) end
		survivorESP = {}
	end
end

local function toggleKillers(enable)
	killerEnabled = enable
	if enable then
		killerToggle.BackgroundColor3 = Color3.fromRGB(255, 55, 55)
		killerDot.Position = UDim2.new(1, -27, 0.5, -12)
		local killerFolder = Workspace:FindFirstChild("PLAYERS") and Workspace.PLAYERS:FindFirstChild("KILLER")
		if killerFolder then
			for _, m in ipairs(killerFolder:GetChildren()) do
				if m:IsA("Model") then
					killerESP[m] = createHighlight(m, Color3.fromRGB(255,80,80))
				end
			end
		end
	else
		killerToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		killerDot.Position = UDim2.new(0, 3, 0.5, -12)
		for m,_ in pairs(killerESP) do removeHighlight(m) end
		killerESP = {}
	end
end

local function toggleGenerators(enable)
	genEnabled = enable
	if enable then
		genToggle.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
		genDot.Position = UDim2.new(1, -27, 0.5, -12)
		for _, obj in ipairs(getGenerators()) do
			generatorESP[obj] = createHighlight(obj, Color3.fromRGB(255,200,60), "BBN_GenESP")
		end
	else
		genToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		genDot.Position = UDim2.new(0, 3, 0.5, -12)
		for obj,_ in pairs(generatorESP) do removeHighlight(obj, "BBN_GenESP") end
		generatorESP = {}
	end
end

local function toggleInfiniteSprint(enable)
	sprintEnabled = enable
	if enable then
		sprintToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
		sprintDot.Position = UDim2.new(1, -27, 0.5, -12)
		connections.stamina = RunService.Heartbeat:Connect(function()
			if not sprintEnabled then return end
			local char = localPlayer.Character
			if not char then return end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
				char:SetAttribute("WalkSpeed", 25)
			else
				char:SetAttribute("WalkSpeed", 12)
			end
		end)
	else
		sprintToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		sprintDot.Position = UDim2.new(0, 3, 0.5, -12)
		if connections.stamina then connections.stamina:Disconnect() connections.stamina = nil end
		local char = localPlayer.Character
		if char then char:SetAttribute("WalkSpeed", 12) end
	end
end

local function toggleNoclip(enable)
	noclipEnabled = enable
	if enable then
		noclipToggle.BackgroundColor3 = Color3.fromRGB(140, 80, 255)
		noclipDot.Position = UDim2.new(1, -27, 0.5, -12)
		connections.noclip = RunService.Stepped:Connect(function()
			local char = localPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		noclipToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		noclipDot.Position = UDim2.new(0, 3, 0.5, -12)
		if connections.noclip then connections.noclip:Disconnect() connections.noclip = nil end
	end
end

local function toggleFullbright(enable)
	fullbrightEnabled = enable
	if enable then
		fullbrightToggle.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
		fullbrightDot.Position = UDim2.new(1, -27, 0.5, -12)
		Lighting.Brightness = 3
		Lighting.ClockTime = 12
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 100000
	else
		fullbrightToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		fullbrightDot.Position = UDim2.new(0, 3, 0.5, -12)
		Lighting.Brightness = 1
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = true
	end
end

local function toggleMinions(enable)
	minionEnabled = enable
	if enable then
		minionToggle.BackgroundColor3 = Color3.fromRGB(180, 80, 255)
		minionDot.Position = UDim2.new(1, -27, 0.5, -12)
		for _, obj in ipairs(getMinions()) do
			minionESP[obj] = createHighlight(obj, Color3.fromRGB(180,80,255), "BBN_MinionESP")
		end
	else
		minionToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		minionDot.Position = UDim2.new(0, 3, 0.5, -12)
		for obj,_ in pairs(minionESP) do removeHighlight(obj, "BBN_MinionESP") end
		minionESP = {}
	end
end

local function toggleBearTraps(enable)
	bearTrapEnabled = enable
	if enable then
		bearTrapToggle.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
		bearTrapDot.Position = UDim2.new(1, -27, 0.5, -12)
		for _, obj in ipairs(getBearTraps()) do
			bearTrapESP[obj] = createHighlight(obj, Color3.fromRGB(255,140,0), "BBN_TrapESP")
		end
	else
		bearTrapToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		bearTrapDot.Position = UDim2.new(0, 3, 0.5, -12)
		for obj,_ in pairs(bearTrapESP) do removeHighlight(obj, "BBN_TrapESP") end
		bearTrapESP = {}
	end
end

-- Auto Kill Farm - RIGHT ON TOP
local function toggleAutoKillFarm(enable)
	autoFarmEnabled = enable
	if enable then
		autoFarmToggle.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		autoFarmDot.Position = UDim2.new(1, -27, 0.5, -12)
		connections.autofarm = RunService.Heartbeat:Connect(function()
			if not autoFarmEnabled then return end
			if currentFarmTarget and isTargetDead(currentFarmTarget) then
				currentFarmTarget = nil
			end
			if not currentFarmTarget then
				currentFarmTarget = getClosestSurvivor()
			end
			if currentFarmTarget then
				teleportRightOnTop(currentFarmTarget)
				simulateLeftClick()
			end
		end)
	else
		autoFarmToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		autoFarmDot.Position = UDim2.new(0, 3, 0.5, -12)
		if connections.autofarm then connections.autofarm:Disconnect() connections.autofarm = nil end
		currentFarmTarget = nil
	end
end

-- ==================== STICKY AIMLOCK (G key) ====================
local function getClosestHeadForAimlock()
	local closestHead = nil
	local shortest = math.huge
	local myRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and player.Character then
			local head = player.Character:FindFirstChild("Head")
			if head then
				local dist = (head.Position - myRoot.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closestHead = head
				end
			end
		end
	end
	return closestHead
end

local function toggleAimlock(enable)
	aimlockEnabled = enable
	if enable then
		aimlockToggle.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
		aimlockDot.Position = UDim2.new(1, -27, 0.5, -12)
	else
		aimlockToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		aimlockDot.Position = UDim2.new(0, 3, 0.5, -12)
		stickyAimlock = false
		if connections.stickyAim then
			connections.stickyAim:Disconnect()
			connections.stickyAim = nil
		end
	end
end

connections.aimlockKey = UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.G and aimlockEnabled then
		stickyAimlock = not stickyAimlock
		
		if stickyAimlock then
			connections.stickyAim = RunService.RenderStepped:Connect(function()
				if not stickyAimlock then return end
				local targetHead = getClosestHeadForAimlock()
				if targetHead then
					local camera = workspace.CurrentCamera
					camera.CFrame = CFrame.new(camera.CFrame.Position, targetHead.Position)
				end
			end)
		else
			if connections.stickyAim then
				connections.stickyAim:Disconnect()
				connections.stickyAim = nil
			end
		end
	end
end)

-- Connect rows
survivorRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleSurvivors(not survivorEnabled) end end)
killerRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleKillers(not killerEnabled) end end)
genRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleGenerators(not genEnabled) end end)

sprintRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleInfiniteSprint(not sprintEnabled) end end)
noclipRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleNoclip(not noclipEnabled) end end)
fullbrightRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleFullbright(not fullbrightEnabled) end end)
minionRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleMinions(not minionEnabled) end end)
bearTrapRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleBearTraps(not bearTrapEnabled) end end)

autoFarmRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleAutoKillFarm(not autoFarmEnabled) end end)
aimlockRow.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then toggleAimlock(not aimlockEnabled) end end)

print("✅ NIGHTBITE HUB loaded successfully (800+ lines)")
print("   Notification: slides UP → waits 5 seconds → slides DOWN")
print("   enjoy your hacks :))")
