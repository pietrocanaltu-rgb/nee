local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Evita carregar duas vezes
if _G.N3onHub and _G.N3onHub._loaded then
	warn("[N3on Hub] Já carregado! Ignorando segunda execução.")
	return
end

----------------------------------------------------------------
-- GUI BASE
----------------------------------------------------------------

-- Remove instância antiga se existir
if PlayerGui:FindFirstChild("N3onHub") then
	PlayerGui:FindFirstChild("N3onHub"):Destroy()
end

local Hub = Instance.new("ScreenGui", PlayerGui)
Hub.ResetOnSpawn = false
Hub.IgnoreGuiInset = true
Hub.Name = "N3onHub"

local F1 = Instance.new("Frame", Hub)
F1.Size = UDim2.fromOffset(720, 420)
F1.Position = UDim2.fromScale(.5,.5)
F1.AnchorPoint = Vector2.new(.5,.5)
F1.BackgroundColor3 = Color3.fromRGB(35,15,60)
Instance.new("UICorner",F1).CornerRadius = UDim.new(0,14)
Instance.new("UIStroke",F1).Color = Color3.fromRGB(140,0,255)
F1.Position = UDim2.fromScale(.5, .5)
F1.AnchorPoint = Vector2.new(.5, .5)
F1.BackgroundColor3 = Color3.fromRGB(35, 15, 60)
Instance.new("UICorner", F1).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", F1).Color = Color3.fromRGB(140, 0, 255)

local F2 = Instance.new("Frame", Hub)
F2.Size = UDim2.fromOffset(180, 420)
F2.Position = F1.Position - UDim2.fromOffset(450,0)
F2.AnchorPoint = Vector2.new(.5,.5)
F2.BackgroundColor3 = Color3.fromRGB(30,10,50)
Instance.new("UICorner",F2).CornerRadius = UDim.new(0,14)
Instance.new("UIStroke",F2).Color = Color3.fromRGB(140,0,255)
F2.Position = F1.Position - UDim2.fromOffset(450, 0)
F2.AnchorPoint = Vector2.new(.5, .5)
F2.BackgroundColor3 = Color3.fromRGB(30, 10, 50)
Instance.new("UICorner", F2).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", F2).Color = Color3.fromRGB(140, 0, 255)

----------------------------------------------------------------
-- TITLE
----------------------------------------------------------------

local Title = Instance.new("TextLabel",F1)
Title.Size = UDim2.new(1,0,0,40)
local Title = Instance.new("TextLabel", F1)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "N3on Hub"
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.TextColor3 = Color3.fromRGB(200,150,255)
Title.TextColor3 = Color3.fromRGB(200, 150, 255)

----------------------------------------------------------------
-- TOP BUTTONS
----------------------------------------------------------------

local MinBtn = Instance.new("TextButton",F1)
MinBtn.Size = UDim2.fromOffset(30,30)
MinBtn.Position = UDim2.new(1,-70,0,5)
local MinBtn = Instance.new("TextButton", F1)
MinBtn.Size = UDim2.fromOffset(30, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.Text = "–"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextScaled = true
MinBtn.BackgroundColor3 = Color3.fromRGB(80,30,120)
Instance.new("UICorner",MinBtn)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
MinBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", MinBtn)

local CloseBtn = Instance.new("TextButton",F1)
CloseBtn.Size = UDim2.fromOffset(30,30)
CloseBtn.Position = UDim2.new(1,-35,0,5)
local CloseBtn = Instance.new("TextButton", F1)
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextScaled = true
CloseBtn.BackgroundColor3 = Color3.fromRGB(120,30,60)
Instance.new("UICorner",CloseBtn)
CloseBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 60)
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CloseBtn)

----------------------------------------------------------------
-- CONTENT
----------------------------------------------------------------

local Content = Instance.new("Frame",F1)
Content.Size = UDim2.new(1,-20,1,-60)
Content.Position = UDim2.fromOffset(10,50)
local Content = Instance.new("Frame", F1)
Content.Size = UDim2.new(1, -20, 1, -60)
Content.Position = UDim2.fromOffset(10, 50)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = false

@@ -85,7 +98,7 @@ ScrollContent.ScrollBarThickness = 6
ScrollContent.CanvasSize = UDim2.new(0, 0, 0, 0)

local function Clear()
	for _,v in pairs(ScrollContent:GetChildren()) do
	for _, v in pairs(ScrollContent:GetChildren()) do
if not v:IsA("UIListLayout") then
v:Destroy()
end
@@ -99,14 +112,14 @@ listLayout.SortOrder = Enum.SortOrder.LayoutOrder
local function UpdateCanvasSize()
ScrollContent.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)

----------------------------------------------------------------
-- SISTEMA DE MODULES
-- GLOBAL
----------------------------------------------------------------

_G.N3onHub = _G.N3onHub or {}
_G.N3onHub = {}
_G.N3onHub._loaded = true
_G.N3onHub.GUI = {
Hub = Hub,
F1 = F1,
@@ -116,21 +129,57 @@ _G.N3onHub.GUI = {
UpdateCanvasSize = UpdateCanvasSize
}

----------------------------------------------------------------
-- TWEEN OPEN/HIDE
----------------------------------------------------------------

-- Tween de abertura: escala de pequeno pra normal
local function ShowHub()
	F1.Visible = true
	F2.Visible = true
	F1.Size = UDim2.fromOffset(660, 390)
	F1.BackgroundTransparency = 0.8
	F2.BackgroundTransparency = 0.8
	TweenService:Create(F1, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(720, 420),
		BackgroundTransparency = 0
	}):Play()
	TweenService:Create(F2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0
	}):Play()
end

local function HideHub(callback)
	TweenService:Create(F1, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(660, 390),
		BackgroundTransparency = 0.8
	}):Play()
	local t = TweenService:Create(F2, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 0.8
	})
	t:Play()
	t.Completed:Connect(function()
		F1.Visible = false
		F2.Visible = false
		F1.Size = UDim2.fromOffset(720, 420)
		if callback then callback() end
	end)
end

ShowHub()

----------------------------------------------------------------
-- HOME
----------------------------------------------------------------

local function LoadHome()
Clear()

	local homeText = "Welcome to N3on Hub\n\nPvP Hackers System\nUI Inspired Hub\n\n🎮 Universal Features Available!"

local HomeFrame = Instance.new("Frame", ScrollContent)
HomeFrame.Size = UDim2.new(1, 0, 0, 180)
HomeFrame.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
HomeFrame.BackgroundTransparency = 0.3
Instance.new("UICorner", HomeFrame)

local stroke = Instance.new("UIStroke", HomeFrame)
stroke.Color = Color3.fromRGB(140, 0, 255)
stroke.Thickness = 2
@@ -149,7 +198,7 @@ local function LoadHome()
text.Size = UDim2.new(1, -20, 1, -60)
text.Position = UDim2.fromOffset(10, 50)
text.BackgroundTransparency = 1
	text.Text = homeText
	text.Text = "Welcome to N3on Hub\n\nPvP Hackers System\nUI Inspired Hub\n\n🎮 Universal Features Available!"
text.Font = Enum.Font.Gotham
text.TextScaled = true
text.TextWrapped = true
@@ -170,95 +219,85 @@ local function GetHum()
end

local savedStates = {
	speed = 16,
	speed    = 16,
jumpPower = 50,
	noclip = false,
	infjump = false,
	fly = false,
	noclip   = false,
	infjump  = false,
	fly      = false,
flySpeed = 50
}

_G.N3onHub.SavedStates = savedStates
_G.N3onHub.GetHum = GetHum

local function Slider(name,min,max,default,callback)
	if min < 1 then
		min = 1
	end
----------------------------------------------------------------
-- WIDGETS
----------------------------------------------------------------

	local frame = Instance.new("Frame",ScrollContent)
	frame.Size = UDim2.new(1,0,0,50)
local function Slider(name, min, max, default, callback)
	if min < 1 then min = 1 end

	local frame = Instance.new("Frame", ScrollContent)
	frame.Size = UDim2.new(1, 0, 0, 50)
frame.BackgroundTransparency = 1

	local label = Instance.new("TextLabel",frame)
	label.Size = UDim2.new(1,0,0,20)
	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, 0, 0, 20)
label.BackgroundTransparency = 1
	label.Text = name.." : "..default
	label.Text = name .. " : " .. default
label.Font = Enum.Font.GothamBold
label.TextScaled = true
	label.TextColor3 = Color3.new(1,1,1)
	label.TextColor3 = Color3.new(1, 1, 1)
label.TextXAlignment = Enum.TextXAlignment.Left

	local bar = Instance.new("Frame",frame)
	bar.Size = UDim2.new(1,0,0,8)
	bar.Position = UDim2.fromOffset(0,28)
	bar.BackgroundColor3 = Color3.fromRGB(60,30,90)
	Instance.new("UICorner",bar).CornerRadius = UDim.new(1,0)

	local fill = Instance.new("Frame",bar)
	fill.Size = UDim2.fromScale((default-min)/(max-min),1)
	fill.BackgroundColor3 = Color3.fromRGB(170,0,255)
	Instance.new("UICorner",fill)

	local knob = Instance.new("Frame",bar)
	knob.Size = UDim2.fromOffset(18,18)
	knob.AnchorPoint = Vector2.new(0.5,0.5)
	knob.Position = UDim2.fromScale(fill.Size.X.Scale,0.5)
	knob.BackgroundColor3 = Color3.fromRGB(220,180,255)
	Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

	local stroke = Instance.new("UIStroke",knob)
	stroke.Color = Color3.fromRGB(120,0,255)
	stroke.Thickness = 2

	local dragging=false

	local bar = Instance.new("Frame", frame)
	bar.Size = UDim2.new(1, 0, 0, 8)
	bar.Position = UDim2.fromOffset(0, 28)
	bar.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", bar)
	fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
	fill.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
	Instance.new("UICorner", fill)

	local knob = Instance.new("Frame", bar)
	knob.Size = UDim2.fromOffset(18, 18)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.fromScale(fill.Size.X.Scale, 0.5)
	knob.BackgroundColor3 = Color3.fromRGB(220, 180, 255)
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	local kstroke = Instance.new("UIStroke", knob)
	kstroke.Color = Color3.fromRGB(120, 0, 255)
	kstroke.Thickness = 2

	local dragging = false
local function update(inputX)
		local size = math.clamp(
			(inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
			0,1
		)

		fill.Size = UDim2.fromScale(size,1)
		knob.Position = UDim2.fromScale(size,0.5)

		local value = math.floor(min+(max-min)*size)
		label.Text = name.." : "..value

		local size = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.fromScale(size, 1)
		knob.Position = UDim2.fromScale(size, 0.5)
		local value = math.floor(min + (max - min) * size)
		label.Text = name .. " : " .. value
callback(value)
end

bar.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			update(i.Position.X)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; update(i.Position.X)
end
end)

knob.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging=true
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
end
end)

UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			dragging=false
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
end
end)

UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
update(i.Position.X)
end
end)
@@ -267,42 +306,41 @@ local function Slider(name,min,max,default,callback)
return frame
end

local function Checkbox(name,defaultState,callback)
	local frame = Instance.new("Frame",ScrollContent)
	frame.Size = UDim2.new(1,0,0,40)
local function Checkbox(name, defaultState, callback)
	local frame = Instance.new("Frame", ScrollContent)
	frame.Size = UDim2.new(1, 0, 0, 40)
frame.BackgroundTransparency = 0.5
	frame.BackgroundColor3 = Color3.fromRGB(60,30,90)
	Instance.new("UICorner",frame)
	frame.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
	Instance.new("UICorner", frame)

	local label = Instance.new("TextLabel",frame)
	label.Size = UDim2.new(1,-40,1,0)
	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, -40, 1, 0)
label.BackgroundTransparency = 1
label.Text = name
label.Font = Enum.Font.GothamBold
label.TextScaled = true
	label.TextColor3 = Color3.new(1,1,1)
	label.TextColor3 = Color3.new(1, 1, 1)
label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = UDim2.fromOffset(10,0)

	local box = Instance.new("Frame",frame)
	box.Size = UDim2.fromOffset(24,24)
	box.Position = UDim2.new(1,-28,.5,-12)
	box.BackgroundColor3 = Color3.fromRGB(50,50,50)
	Instance.new("UICorner",box)

	local fill = Instance.new("Frame",box)
	fill.Size = UDim2.new(1,-6,1,-6)
	fill.Position = UDim2.fromOffset(3,3)
	fill.BackgroundColor3 = Color3.fromRGB(170,0,255)
	label.Position = UDim2.fromOffset(10, 0)

	local box = Instance.new("Frame", frame)
	box.Size = UDim2.fromOffset(24, 24)
	box.Position = UDim2.new(1, -28, .5, -12)
	box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	Instance.new("UICorner", box)

	local fill = Instance.new("Frame", box)
	fill.Size = UDim2.new(1, -6, 1, -6)
	fill.Position = UDim2.fromOffset(3, 3)
	fill.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
fill.Visible = defaultState
	Instance.new("UICorner",fill)
	Instance.new("UICorner", fill)

local state = defaultState

frame.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			state=not state
			fill.Visible=state
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			state = not state
			fill.Visible = state
callback(state)
end
end)
@@ -311,398 +349,346 @@ local function Checkbox(name,defaultState,callback)
return frame
end

_G.N3onHub.Slider = Slider
_G.N3onHub.Slider   = Slider
_G.N3onHub.Checkbox = Checkbox

----------------------------------------------------------------
-- NOCLIP / INF JUMP
----------------------------------------------------------------

local noclip = false
local infjump = false
local flying = false
local flySpeed = 50

-- Loop para manter WalkSpeed e JumpPower
local speedLoopActive = false
local jumpLoopActive = false

local function StartSpeedLoop()
	if speedLoopActive then return end
	speedLoopActive = true
	
	spawn(function()
		while speedLoopActive do
			local hum = GetHum()
			if hum and hum.WalkSpeed ~= savedStates.speed then
				hum.WalkSpeed = savedStates.speed
			end
			task.wait(0.1)
		end
	end)
end

local function StartJumpLoop()
	if jumpLoopActive then return end
	jumpLoopActive = true
	
	spawn(function()
		while jumpLoopActive do
			local hum = GetHum()
			if hum and hum.JumpPower ~= savedStates.jumpPower then
				hum.JumpPower = savedStates.jumpPower
			end
			task.wait(0.1)
		end
	end)
end

StartSpeedLoop()
StartJumpLoop()

Player.CharacterAdded:Connect(function()
	task.wait(0.5)
	StartSpeedLoop()
	StartJumpLoop()
	
	local hum = GetHum()
	if hum then
		hum.WalkSpeed = savedStates.speed
		hum.JumpPower = savedStates.jumpPower
	end
end)

RunService.Heartbeat:Connect(function()
	if not noclip then return end
	if not Player.Character then return end

	if not noclip or not Player.Character then return end
for _, part in ipairs(Player.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
		if part:IsA("BasePart") then part.CanCollide = false end
end
end)

UIS.JumpRequest:Connect(function()
	if infjump then
		GetHum():ChangeState("Jumping")
	end
	if infjump then GetHum():ChangeState("Jumping") end
end)

----------------------------------------------------------------
-- FLY SYSTEM
----------------------------------------------------------------

local flying  = false
local flySpeed = 50
local FlyControls = nil
local flyConnection = nil
local mobileButtons = nil

local function CreateFlyControls()
	if FlyControls then return end

	if FlyControls then return mobileButtons end
FlyControls = Instance.new("ScreenGui", PlayerGui)
FlyControls.Name = "FlyControls"
FlyControls.ResetOnSpawn = false
FlyControls.DisplayOrder = 100

local Container = Instance.new("Frame", FlyControls)
Container.Size = UDim2.fromOffset(180, 180)
Container.Position = UDim2.new(1, -200, 1, -200)
Container.BackgroundTransparency = 1

	local function CreateButton(text, pos, size)
	local function CB(text, pos, size)
local btn = Instance.new("TextButton", Container)
btn.Size = size or UDim2.fromOffset(50, 50)
		btn.Position = pos
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextScaled = true
		btn.Position = pos; btn.Text = text
		btn.Font = Enum.Font.GothamBold; btn.TextScaled = true
btn.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.BorderSizePixel = 0
		btn.TextColor3 = Color3.new(1, 1, 1); btn.BorderSizePixel = 0
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
return btn
end

	local UpBtn = CreateButton("▲", UDim2.fromOffset(65, 0))
	local DownBtn = CreateButton("▼", UDim2.fromOffset(65, 130))
	local LeftBtn = CreateButton("◄", UDim2.fromOffset(0, 65))
	local RightBtn = CreateButton("►", UDim2.fromOffset(130, 65))

	local RiseBtn = CreateButton("△", UDim2.fromOffset(65, 30), UDim2.fromOffset(50, 30))
	local FallBtn = CreateButton("▽", UDim2.fromOffset(65, 100), UDim2.fromOffset(50, 30))

local buttons = {
		W = {pressed = false, btn = UpBtn},
		S = {pressed = false, btn = DownBtn},
		A = {pressed = false, btn = LeftBtn},
		D = {pressed = false, btn = RightBtn},
		Space = {pressed = false, btn = RiseBtn},
		Shift = {pressed = false, btn = FallBtn}
		W     = {pressed=false, btn=CB("▲", UDim2.fromOffset(65,0))},
		S     = {pressed=false, btn=CB("▼", UDim2.fromOffset(65,130))},
		A     = {pressed=false, btn=CB("◄", UDim2.fromOffset(0,65))},
		D     = {pressed=false, btn=CB("►", UDim2.fromOffset(130,65))},
		Space = {pressed=false, btn=CB("△", UDim2.fromOffset(65,30), UDim2.fromOffset(50,30))},
		Shift = {pressed=false, btn=CB("▽", UDim2.fromOffset(65,100), UDim2.fromOffset(50,30))},
}

	for key, data in pairs(buttons) do
		data.btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				data.pressed = true
				data.btn.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
	for _, data in pairs(buttons) do
		data.btn.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
				data.pressed=true; data.btn.BackgroundColor3=Color3.fromRGB(140,0,255)
end
end)

		data.btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				data.pressed = false
				data.btn.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
		data.btn.InputEnded:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
				data.pressed=false; data.btn.BackgroundColor3=Color3.fromRGB(80,30,120)
end
end)
end

	mobileButtons = buttons
return buttons
end

local function RemoveFlyControls()
	if FlyControls then
		FlyControls:Destroy()
		FlyControls = nil
	end
	if FlyControls then FlyControls:Destroy(); FlyControls = nil end
end

local flyConnection
local mobileButtons

local function StartFly()
if flyConnection then return end

flying = true
	mobileButtons = CreateFlyControls()

	CreateFlyControls()
local char = Player.Character
if not char then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end

local bg = Instance.new("BodyGyro", hrp)
	bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.P = 9e9
	bg.D = 500

	bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=9e9; bg.D=500
local bv = Instance.new("BodyVelocity", hrp)
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity = Vector3.new(0, 0, 0)

	bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Velocity=Vector3.new(0,0,0)
flyConnection = RunService.Heartbeat:Connect(function()
if not flying or not char or not char.Parent then
			if flyConnection then
				flyConnection:Disconnect()
				flyConnection = nil
			end
			if bg then bg:Destroy() end
			if bv then bv:Destroy() end
			return
		end

		local camera = workspace.CurrentCamera
		bg.CFrame = camera.CFrame

		local moveDirection = Vector3.new(0, 0, 0)

		if UIS:IsKeyDown(Enum.KeyCode.W) or (mobileButtons and mobileButtons.W.pressed) then
			moveDirection = moveDirection + (camera.CFrame.LookVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) or (mobileButtons and mobileButtons.S.pressed) then
			moveDirection = moveDirection - (camera.CFrame.LookVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) or (mobileButtons and mobileButtons.A.pressed) then
			moveDirection = moveDirection - (camera.CFrame.RightVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) or (mobileButtons and mobileButtons.D.pressed) then
			moveDirection = moveDirection + (camera.CFrame.RightVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.Space) or (mobileButtons and mobileButtons.Space.pressed) then
			moveDirection = moveDirection + Vector3.new(0, 1, 0)
		end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or (mobileButtons and mobileButtons.Shift.pressed) then
			moveDirection = moveDirection - Vector3.new(0, 1, 0)
		end

		if moveDirection.Magnitude > 0 then
			bv.Velocity = moveDirection.Unit * flySpeed
		else
			bv.Velocity = Vector3.new(0, 0, 0)
			if flyConnection then flyConnection:Disconnect(); flyConnection=nil end
			bg:Destroy(); bv:Destroy(); return
end
		local cam = workspace.CurrentCamera
		bg.CFrame = cam.CFrame
		local dir = Vector3.new(0,0,0)
		if UIS:IsKeyDown(Enum.KeyCode.W) or (mobileButtons and mobileButtons.W.pressed) then dir+=cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) or (mobileButtons and mobileButtons.S.pressed) then dir-=cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) or (mobileButtons and mobileButtons.A.pressed) then dir-=cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) or (mobileButtons and mobileButtons.D.pressed) then dir+=cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) or (mobileButtons and mobileButtons.Space.pressed) then dir+=Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or (mobileButtons and mobileButtons.Shift.pressed) then dir-=Vector3.new(0,1,0) end
		bv.Velocity = if dir.Magnitude>0 then dir.Unit*flySpeed else Vector3.new(0,0,0)
end)
end

local function StopFly()
	flying = false
	RemoveFlyControls()

	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end

	flying=false; RemoveFlyControls()
	if flyConnection then flyConnection:Disconnect(); flyConnection=nil end
local char = Player.Character
if char then
local hrp = char:FindFirstChild("HumanoidRootPart")
if hrp then
for _, obj in pairs(hrp:GetChildren()) do
				if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
					obj:Destroy()
				end
				if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then obj:Destroy() end
end
end
end
end

----------------------------------------------------------------
-- LOAD PLAYER TAB
-- SPEED / JUMP LOOP
----------------------------------------------------------------

local function LoadPlayer()
	Clear()
local speedLoopActive = false
local jumpLoopActive  = false

	Slider("Speed",1,200,savedStates.speed,function(v)
		savedStates.speed = v
		local hum = GetHum()
		if hum then
			hum.WalkSpeed = v
local function StartSpeedLoop()
	if speedLoopActive then return end
	speedLoopActive = true
	spawn(function()
		while speedLoopActive do
			local hum = GetHum()
			if hum and hum.WalkSpeed ~= savedStates.speed then hum.WalkSpeed = savedStates.speed end
			task.wait(0.1)
end
end)
end

	Slider("JumpPower",1,200,savedStates.jumpPower,function(v)
		savedStates.jumpPower = v
		local hum = GetHum()
		if hum then
			hum.JumpPower = v
local function StartJumpLoop()
	if jumpLoopActive then return end
	jumpLoopActive = true
	spawn(function()
		while jumpLoopActive do
			local hum = GetHum()
			if hum and hum.JumpPower ~= savedStates.jumpPower then hum.JumpPower = savedStates.jumpPower end
			task.wait(0.1)
end
end)
end

	Checkbox("Noclip",savedStates.noclip,function(v)
		savedStates.noclip = v
		noclip=v
	end)
StartSpeedLoop(); StartJumpLoop()

	Checkbox("Infinite Jump",savedStates.infjump,function(v)
		savedStates.infjump = v
		infjump=v
	end)
Player.CharacterAdded:Connect(function()
	task.wait(0.5)
	StartSpeedLoop(); StartJumpLoop()
	local hum = GetHum()
	if hum then hum.WalkSpeed=savedStates.speed; hum.JumpPower=savedStates.jumpPower end
end)

	Checkbox("Fly",savedStates.fly,function(v)
		savedStates.fly = v
		if v then
			StartFly()
		else
			StopFly()
		end
	end)
----------------------------------------------------------------
-- LOAD PLAYER TAB
----------------------------------------------------------------

	Slider("Fly Speed",10,200,savedStates.flySpeed,function(v)
		savedStates.flySpeed = v
		flySpeed = v
local function LoadPlayer()
	Clear()
	Slider("Speed", 1, 200, savedStates.speed, function(v)
		savedStates.speed = v
		local hum = GetHum(); if hum then hum.WalkSpeed = v end
end)
	Slider("JumpPower", 1, 200, savedStates.jumpPower, function(v)
		savedStates.jumpPower = v
		local hum = GetHum(); if hum then hum.JumpPower = v end
	end)
	Checkbox("Noclip", savedStates.noclip, function(v) savedStates.noclip=v; noclip=v end)
	Checkbox("Infinite Jump", savedStates.infjump, function(v) savedStates.infjump=v; infjump=v end)
	Checkbox("Fly", savedStates.fly, function(v)
		savedStates.fly = v
		if v then StartFly() else StopFly() end
	end)
	Slider("Fly Speed", 10, 200, savedStates.flySpeed, function(v) savedStates.flySpeed=v; flySpeed=v end)
end

----------------------------------------------------------------
-- SIDEBAR
-- SIDEBAR - TAB Y AUTOMÁTICO
-- O 3º argumento (y) é ignorado, mantido só por compatibilidade
-- com módulos que ainda passam o número manualmente.
----------------------------------------------------------------

local function Tab(name,emoji,y,callback)
	local b=Instance.new("TextButton",F2)
	b.Size=UDim2.new(1,-20,0,40)
	b.Position=UDim2.fromOffset(10,y)
	b.Text=emoji.." "..name
	b.Font=Enum.Font.GothamBold
	b.TextScaled=true
	b.TextColor3=Color3.new(1,1,1)
	b.BackgroundColor3=Color3.fromRGB(60,20,90)
	Instance.new("UICorner",b)

local tabY = 10
local TAB_H = 50

local function Tab(name, emoji, _y, callback)
	local b = Instance.new("TextButton", F2)
	b.Size = UDim2.new(1, -20, 0, 40)
	b.Position = UDim2.fromOffset(10, tabY)
	b.Text = emoji .. " " .. name
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = Color3.fromRGB(60, 20, 90)
	Instance.new("UICorner", b)
b.MouseButton1Click:Connect(callback)
	tabY = tabY + TAB_H
end

_G.N3onHub.Tab = Tab
_G.N3onHub.LoadHome = LoadHome
_G.N3onHub.Tab        = Tab
_G.N3onHub.LoadHome   = LoadHome
_G.N3onHub.LoadPlayer = LoadPlayer

Tab("Home","🏠",40,LoadHome)
Tab("Player","👤",100,LoadPlayer)
Tab("Home",   "🏠", 0, LoadHome)
Tab("Player", "👤", 0, LoadPlayer)

LoadHome()

----------------------------------------------------------------
-- MINIMIZE SYSTEM
-- MINIMIZE - bolinha simples com tween de tamanho
----------------------------------------------------------------

local Mini=false
local Bubble
local Mini  = false
local Bubble = nil

MinBtn.MouseButton1Click:Connect(function()
if Mini then return end
	Mini=true

	F1.Visible=false
	F2.Visible=false

	Bubble=Instance.new("TextButton",Hub)
	Bubble.Size=UDim2.fromOffset(60,60)
	Bubble.Position=UDim2.new(.8,0,.6,0)
	Bubble.Text="N3"
	Bubble.Font=Enum.Font.GothamBold
	Bubble.TextScaled=true
	Bubble.BackgroundColor3=Color3.fromRGB(140,0,255)
	Instance.new("UICorner",Bubble).CornerRadius=UDim.new(1,0)

	Bubble.MouseButton1Click:Connect(function()
		F1.Visible=true
		F2.Visible=true
		Bubble:Destroy()
		Mini=false
	Mini = true

	HideHub(function()
		-- cria bolinha
		Bubble = Instance.new("TextButton", Hub)
		Bubble.AnchorPoint = Vector2.new(0.5, 0.5)
		Bubble.Position = UDim2.new(0.85, 0, 0.85, 0)
		Bubble.Size = UDim2.fromOffset(0, 0)  -- começa em 0 pro tween
		Bubble.Text = "N3"
		Bubble.Font = Enum.Font.GothamBold
		Bubble.TextScaled = true
		Bubble.TextColor3 = Color3.new(1, 1, 1)
		Bubble.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
		Bubble.AutoButtonColor = false
		Bubble.BorderSizePixel = 0
		Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

		-- tween de entrada
		TweenService:Create(Bubble, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(60, 60)
		}):Play()

		-- clicar pra reabrir
		Bubble.MouseButton1Click:Connect(function()
			TweenService:Create(Bubble, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.fromOffset(0, 0)
			}):Play()
			task.delay(0.2, function()
				Bubble:Destroy()
				Bubble = nil
				Mini = false
				ShowHub()
			end)
		end)
end)
end)

----------------------------------------------------------------
-- CLOSE POPUP
-- CLOSE POPUP com tween
----------------------------------------------------------------

CloseBtn.MouseButton1Click:Connect(function()
	local pop=Instance.new("Frame",Hub)
	pop.Size=UDim2.fromOffset(300,150)
	pop.Position=UDim2.fromScale(.5,.5)
	pop.AnchorPoint=Vector2.new(.5,.5)
	pop.BackgroundColor3=Color3.fromRGB(40,0,60)
	Instance.new("UICorner",pop)

	local txt=Instance.new("TextLabel",pop)
	txt.Size=UDim2.new(1,-20,1,-60)
	txt.Position=UDim2.fromOffset(10,10)
	txt.BackgroundTransparency=1
	txt.Text="Are you sure?\nYou must re-execute the script to open again."
	txt.TextScaled=true
	txt.Font=Enum.Font.GothamBold
	txt.TextColor3=Color3.new(1,1,1)

	local yes=Instance.new("TextButton",pop)
	yes.Size=UDim2.fromOffset(100,30)
	yes.Position=UDim2.new(.25,-50,1,-40)
	yes.Text="Yes"
	yes.Font=Enum.Font.GothamBold
	yes.TextScaled=true
	yes.BackgroundColor3=Color3.fromRGB(80,40,120)
	yes.TextColor3=Color3.new(1,1,1)
	Instance.new("UICorner",yes)

	local no=Instance.new("TextButton",pop)
	no.Size=UDim2.fromOffset(100,30)
	no.Position=UDim2.new(.75,-50,1,-40)
	no.Text="No"
	no.Font=Enum.Font.GothamBold
	no.TextScaled=true
	no.BackgroundColor3=Color3.fromRGB(80,40,120)
	no.TextColor3=Color3.new(1,1,1)
	Instance.new("UICorner",no)
	-- overlay escuro
	local overlay = Instance.new("Frame", Hub)
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 10
	TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.5}):Play()

	-- popup
	local pop = Instance.new("Frame", overlay)
	pop.Size = UDim2.fromOffset(0, 0) -- começa em 0 pro tween
	pop.Position = UDim2.fromScale(0.5, 0.5)
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
	pop.ZIndex = 11
	Instance.new("UICorner", pop)
	Instance.new("UIStroke", pop).Color = Color3.fromRGB(140, 0, 255)

	TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(300, 150)
	}):Play()

	local txt = Instance.new("TextLabel", pop)
	txt.Size = UDim2.new(1, -20, 1, -60)
	txt.Position = UDim2.fromOffset(10, 10)
	txt.BackgroundTransparency = 1
	txt.Text = "Tem certeza?\nVocê precisará re-executar o script para abrir novamente."
	txt.TextScaled = true
	txt.TextWrapped = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.ZIndex = 12

	local yes = Instance.new("TextButton", pop)
	yes.Size = UDim2.fromOffset(100, 30)
	yes.Position = UDim2.new(0.25, -50, 1, -40)
	yes.Text = "✅ Sim"
	yes.Font = Enum.Font.GothamBold
	yes.TextScaled = true
	yes.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
	yes.TextColor3 = Color3.new(1, 1, 1)
	yes.ZIndex = 12
	Instance.new("UICorner", yes)

	local no = Instance.new("TextButton", pop)
	no.Size = UDim2.fromOffset(100, 30)
	no.Position = UDim2.new(0.75, -50, 1, -40)
	no.Text = "❌ Não"
	no.Font = Enum.Font.GothamBold
	no.TextScaled = true
	no.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
	no.TextColor3 = Color3.new(1, 1, 1)
	no.ZIndex = 12
	Instance.new("UICorner", no)

	local function closePopup()
		TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		local t = TweenService:Create(pop, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(0, 0)
		})
		t:Play()
		t.Completed:Connect(function() overlay:Destroy() end)
	end

yes.MouseButton1Click:Connect(function()
		Hub:Destroy()
		overlay:Destroy()
		HideHub(function() Hub:Destroy() end)
end)

no.MouseButton1Click:Connect(function()
		pop:Destroy()
		closePopup()
end)
end)
