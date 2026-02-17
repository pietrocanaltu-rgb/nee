-- N3on Hub - Base Universal
-- Sistema principal que funciona em qualquer jogo

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

----------------------------------------------------------------
-- GUI BASE
----------------------------------------------------------------

local Hub = Instance.new("ScreenGui", PlayerGui)
Hub.ResetOnSpawn = false
Hub.IgnoreGuiInset = true
Hub.Name = "N3onHub"

local F1 = Instance.new("Frame", Hub)
F1.Size = UDim2.fromOffset(720, 420)
F1.Position = UDim2.fromScale(.5, .5)
F1.AnchorPoint = Vector2.new(.5, .5)
F1.BackgroundColor3 = Color3.fromRGB(35, 15, 60)
F1.BackgroundTransparency = 1
Instance.new("UICorner", F1).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", F1).Color = Color3.fromRGB(140, 0, 255)

local F2 = Instance.new("Frame", Hub)
F2.Size = UDim2.fromOffset(180, 420)
F2.Position = F1.Position - UDim2.fromOffset(450, 0)
F2.AnchorPoint = Vector2.new(.5, .5)
F2.BackgroundColor3 = Color3.fromRGB(30, 10, 50)
F2.BackgroundTransparency = 1
Instance.new("UICorner", F2).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", F2).Color = Color3.fromRGB(140, 0, 255)

----------------------------------------------------------------
-- TWEEN OPEN / HIDE
----------------------------------------------------------------

local function ShowHub()
	F1.Visible = true
	F2.Visible = true
	F1.Size = UDim2.fromOffset(680, 380)
	TweenService:Create(F1, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Size = UDim2.fromOffset(720, 420)
	}):Play()
	TweenService:Create(F2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()
end

local function HideHub(callback)
	TweenService:Create(F1, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(680, 380)
	}):Play()
	local t2 = TweenService:Create(F2, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})
	t2:Play()
	t2.Completed:Connect(function()
		F1.Visible = false
		F2.Visible = false
		F1.Size = UDim2.fromOffset(720, 420)
		if callback then callback() end
	end)
end

ShowHub()

----------------------------------------------------------------
-- TITLE
----------------------------------------------------------------

local Title = Instance.new("TextLabel", F1)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "N3on Hub"
Title.Font = Enum.Font.GothamBold
Title.TextScaled = true
Title.TextColor3 = Color3.fromRGB(200, 150, 255)

----------------------------------------------------------------
-- TOP BUTTONS
----------------------------------------------------------------

local MinBtn = Instance.new("TextButton", F1)
MinBtn.Size = UDim2.fromOffset(30, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.Text = "–"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextScaled = true
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
MinBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", MinBtn)

local CloseBtn = Instance.new("TextButton", F1)
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextScaled = true
CloseBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 60)
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CloseBtn)

----------------------------------------------------------------
-- CONTENT
----------------------------------------------------------------

local Content = Instance.new("Frame", F1)
Content.Size = UDim2.new(1, -20, 1, -60)
Content.Position = UDim2.fromOffset(10, 50)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true

local ScrollContent = Instance.new("ScrollingFrame", Content)
ScrollContent.Size = UDim2.new(1, 0, 1, 0)
ScrollContent.BackgroundTransparency = 1
ScrollContent.BorderSizePixel = 0
ScrollContent.ScrollBarThickness = 6
ScrollContent.CanvasSize = UDim2.new(0, 0, 0, 0)

local function Clear()
	for _, v in pairs(ScrollContent:GetChildren()) do
		if not v:IsA("UIListLayout") then v:Destroy() end
	end
end

local listLayout = Instance.new("UIListLayout", ScrollContent)
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function UpdateCanvasSize()
	ScrollContent.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)

----------------------------------------------------------------
-- GLOBAL
----------------------------------------------------------------

_G.N3onHub = _G.N3onHub or {}
_G.N3onHub.GUI = {
	Hub = Hub, F1 = F1, F2 = F2,
	ScrollContent = ScrollContent,
	Clear = Clear,
	UpdateCanvasSize = UpdateCanvasSize
}

----------------------------------------------------------------
-- HOME
----------------------------------------------------------------

local function LoadHome()
	Clear()
	local HomeFrame = Instance.new("Frame", ScrollContent)
	HomeFrame.Size = UDim2.new(1, 0, 0, 180)
	HomeFrame.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
	HomeFrame.BackgroundTransparency = 0.3
	Instance.new("UICorner", HomeFrame)
	local stroke = Instance.new("UIStroke", HomeFrame)
	stroke.Color = Color3.fromRGB(140, 0, 255); stroke.Thickness = 2

	local title = Instance.new("TextLabel", HomeFrame)
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.fromOffset(10, 10)
	title.BackgroundTransparency = 1
	title.Text = "🏠 Home"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(220, 200, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left

	local text = Instance.new("TextLabel", HomeFrame)
	text.Size = UDim2.new(1, -20, 1, -60)
	text.Position = UDim2.fromOffset(10, 50)
	text.BackgroundTransparency = 1
	text.Text = "Welcome to N3on Hub\n\nPvP Hackers System\nUI Inspired Hub\n\n🎮 Universal Features Available!"
	text.Font = Enum.Font.Gotham
	text.TextScaled = true; text.TextWrapped = true
	text.TextColor3 = Color3.fromRGB(230, 210, 255)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	UpdateCanvasSize()
end

----------------------------------------------------------------
-- PLAYER SYSTEM
----------------------------------------------------------------

local function GetHum()
	local char = Player.Character or Player.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid")
end

local savedStates = {
	speed = 16, jumpPower = 50,
	noclip = false, infjump = false,
	fly = false, flySpeed = 50
}

_G.N3onHub.SavedStates = savedStates
_G.N3onHub.GetHum = GetHum

----------------------------------------------------------------
-- WIDGETS
----------------------------------------------------------------

local function Slider(name, min, max, default, callback)
	if min < 1 then min = 1 end
	local frame = Instance.new("Frame", ScrollContent)
	frame.Size = UDim2.new(1, 0, 0, 50)
	frame.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Text = name .. " : " .. default
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left

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
	kstroke.Color = Color3.fromRGB(120, 0, 255); kstroke.Thickness = 2

	local dragging = false
	local function update(inputX)
		local size = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.fromScale(size, 1)
		knob.Position = UDim2.fromScale(size, 0.5)
		local value = math.floor(min + (max - min) * size)
		label.Text = name .. " : " .. value
		callback(value)
	end

	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; update(i.Position.X)
		end
	end)
	knob.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			update(i.Position.X)
		end
	end)
	UpdateCanvasSize()
	return frame
end

local function Checkbox(name, defaultState, callback)
	local frame = Instance.new("Frame", ScrollContent)
	frame.Size = UDim2.new(1, 0, 0, 40)
	frame.BackgroundTransparency = 0.5
	frame.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
	Instance.new("UICorner", frame)

	local label = Instance.new("TextLabel", frame)
	label.Size = UDim2.new(1, -40, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
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
	Instance.new("UICorner", fill)

	local state = defaultState
	frame.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			state = not state
			fill.Visible = state
			callback(state)
		end
	end)
	UpdateCanvasSize()
	return frame
end

_G.N3onHub.Slider = Slider
_G.N3onHub.Checkbox = Checkbox

----------------------------------------------------------------
-- NOCLIP / INFJUMP
----------------------------------------------------------------

local noclip = false
local infjump = false

RunService.Heartbeat:Connect(function()
	if not noclip or not Player.Character then return end
	for _, part in ipairs(Player.Character:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false end
	end
end)

UIS.JumpRequest:Connect(function()
	if infjump then GetHum():ChangeState("Jumping") end
end)

----------------------------------------------------------------
-- FLY
----------------------------------------------------------------

local flying = false
local flySpeed = 50
local FlyControls = nil
local flyConnection = nil
local mobileButtons = nil

local function CreateFlyControls()
	if FlyControls then return mobileButtons end
	FlyControls = Instance.new("ScreenGui", PlayerGui)
	FlyControls.Name = "FlyControls"
	FlyControls.ResetOnSpawn = false
	FlyControls.DisplayOrder = 100
	local Container = Instance.new("Frame", FlyControls)
	Container.Size = UDim2.fromOffset(180, 180)
	Container.Position = UDim2.new(1, -200, 1, -200)
	Container.BackgroundTransparency = 1
	local function CB(text, pos, size)
		local btn = Instance.new("TextButton", Container)
		btn.Size = size or UDim2.fromOffset(50, 50)
		btn.Position = pos; btn.Text = text
		btn.Font = Enum.Font.GothamBold; btn.TextScaled = true
		btn.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
		btn.TextColor3 = Color3.new(1, 1, 1); btn.BorderSizePixel = 0
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		return btn
	end
	local buttons = {
		W     = {pressed=false, btn=CB("▲", UDim2.fromOffset(65,0))},
		S     = {pressed=false, btn=CB("▼", UDim2.fromOffset(65,130))},
		A     = {pressed=false, btn=CB("◄", UDim2.fromOffset(0,65))},
		D     = {pressed=false, btn=CB("►", UDim2.fromOffset(130,65))},
		Space = {pressed=false, btn=CB("△", UDim2.fromOffset(65,30), UDim2.fromOffset(50,30))},
		Shift = {pressed=false, btn=CB("▽", UDim2.fromOffset(65,100), UDim2.fromOffset(50,30))},
	}
	for _, data in pairs(buttons) do
		data.btn.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
				data.pressed=true; data.btn.BackgroundColor3=Color3.fromRGB(140,0,255)
			end
		end)
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
	if FlyControls then FlyControls:Destroy(); FlyControls = nil end
end

local function StartFly()
	if flyConnection then return end
	flying = true
	CreateFlyControls()
	local char = Player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local bg = Instance.new("BodyGyro", hrp)
	bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=9e9; bg.D=500
	local bv = Instance.new("BodyVelocity", hrp)
	bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Velocity=Vector3.new(0,0,0)
	flyConnection = RunService.Heartbeat:Connect(function()
		if not flying or not char or not char.Parent then
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
	flying=false; RemoveFlyControls()
	if flyConnection then flyConnection:Disconnect(); flyConnection=nil end
	local char = Player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			for _, obj in pairs(hrp:GetChildren()) do
				if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then obj:Destroy() end
			end
		end
	end
end

----------------------------------------------------------------
-- SPEED / JUMP LOOP
----------------------------------------------------------------

local speedLoopActive = false
local jumpLoopActive = false

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

StartSpeedLoop(); StartJumpLoop()

Player.CharacterAdded:Connect(function()
	task.wait(0.5)
	StartSpeedLoop(); StartJumpLoop()
	local hum = GetHum()
	if hum then hum.WalkSpeed=savedStates.speed; hum.JumpPower=savedStates.jumpPower end
end)

----------------------------------------------------------------
-- LOAD PLAYER TAB
----------------------------------------------------------------

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
-- SIDEBAR - Y AUTOMÁTICO
----------------------------------------------------------------

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
_G.N3onHub.LoadPlayer = LoadPlayer

Tab("Home",   "🏠", 0, LoadHome)
Tab("Player", "👤", 0, LoadPlayer)

LoadHome()

----------------------------------------------------------------
-- MINIMIZE - bola flutuante arrastável com tween
----------------------------------------------------------------

local Mini = false
local Bubble = nil

local function CreateBubble()
	Bubble = Instance.new("TextButton", Hub)
	Bubble.Size = UDim2.fromOffset(60, 60)
	Bubble.Position = UDim2.new(0.8, 0, 0.6, 0)
	Bubble.Text = "N3"
	Bubble.Font = Enum.Font.GothamBold
	Bubble.TextScaled = true
	Bubble.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
	Bubble.BackgroundTransparency = 1
	Bubble.TextTransparency = 1
	Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

	TweenService:Create(Bubble, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		TextTransparency = 0,
	}):Play()

	-- arrastar + clicar pra reabrir
	local bubbleDragging = false
	local bubbleDragStart, bubbleStartPos
	local bubbleMoved = false

	Bubble.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			bubbleDragging = true
			bubbleMoved = false
			bubbleDragStart = i.Position
			bubbleStartPos = Bubble.Position
		end
	end)

	Bubble.InputChanged:Connect(function(i)
		if bubbleDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local delta = i.Position - bubbleDragStart
			if delta.Magnitude > 6 then
				bubbleMoved = true
			end
			Bubble.Position = UDim2.new(
				bubbleStartPos.X.Scale, bubbleStartPos.X.Offset + delta.X,
				bubbleStartPos.Y.Scale, bubbleStartPos.Y.Offset + delta.Y
			)
		end
	end)

	Bubble.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			bubbleDragging = false
			-- só reabre se não arrastou
			if not bubbleMoved then
				local t = TweenService:Create(Bubble, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					BackgroundTransparency = 1,
					TextTransparency = 1,
				})
				t:Play()
				t.Completed:Connect(function()
					if Bubble then Bubble:Destroy(); Bubble = nil end
					Mini = false
					ShowHub()
				end)
			end
			bubbleMoved = false
		end
	end)
end

MinBtn.MouseButton1Click:Connect(function()
	if Mini then return end
	Mini = true
	HideHub(function()
		CreateBubble()
	end)
end)

----------------------------------------------------------------
-- CLOSE POPUP com tween
----------------------------------------------------------------

CloseBtn.MouseButton1Click:Connect(function()
	local overlay = Instance.new("Frame", Hub)
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 10

	TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.55}):Play()

	local pop = Instance.new("Frame", overlay)
	pop.Size = UDim2.fromOffset(320, 160)
	pop.Position = UDim2.fromScale(0.5, 0.5)
	pop.AnchorPoint = Vector2.new(0.5, 0.5)
	pop.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
	pop.BackgroundTransparency = 1
	pop.ZIndex = 11
	Instance.new("UICorner", pop)
	Instance.new("UIStroke", pop).Color = Color3.fromRGB(140, 0, 255)

	TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()

	local txt = Instance.new("TextLabel", pop)
	txt.Size = UDim2.new(1, -20, 1, -60)
	txt.Position = UDim2.fromOffset(10, 10)
	txt.BackgroundTransparency = 1
	txt.Text = "Tem certeza?\nVocê precisará re-executar o script para abrir novamente."
	txt.TextScaled = true; txt.TextWrapped = true
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.ZIndex = 12

	local yes = Instance.new("TextButton", pop)
	yes.Size = UDim2.fromOffset(110, 35)
	yes.Position = UDim2.new(0.25, -55, 1, -45)
	yes.Text = "✅ Sim"
	yes.Font = Enum.Font.GothamBold; yes.TextScaled = true
	yes.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
	yes.TextColor3 = Color3.new(1, 1, 1)
	yes.ZIndex = 12
	Instance.new("UICorner", yes)

	local no = Instance.new("TextButton", pop)
	no.Size = UDim2.fromOffset(110, 35)
	no.Position = UDim2.new(0.75, -55, 1, -45)
	no.Text = "❌ Não"
	no.Font = Enum.Font.GothamBold; no.TextScaled = true
	no.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
	no.TextColor3 = Color3.new(1, 1, 1)
	no.ZIndex = 12
	Instance.new("UICorner", no)

	local function closePopup()
		TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		local t = TweenService:Create(pop, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		})
		t:Play()
		t.Completed:Connect(function() overlay:Destroy() end)
	end

	yes.MouseButton1Click:Connect(function()
		overlay:Destroy()
		HideHub(function() Hub:Destroy() end)
	end)

	no.MouseButton1Click:Connect(function()
		closePopup()
	end)
end)

print("[N3on Hub] Base loaded! Ready for game modules.")
