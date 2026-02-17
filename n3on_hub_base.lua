local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Evita carregar duas vezes
if _G.N3onHub and _G.N3onHub._loaded then
	warn("[N3on Hub] Já carregado!")
	return
end

----------------------------------------------------------------
-- CONFIGURAÇÕES E ESTADOS
----------------------------------------------------------------

local savedStates = {
	speed = 16,
	jumpPower = 50,
	noclip = false,
	infjump = false,
	fly = false,
	flySpeed = 50
}

local flying = false
local flyConnection = nil
local mobileButtons = nil
local FlyControls = nil

----------------------------------------------------------------
-- GUI BASE
----------------------------------------------------------------

if PlayerGui:FindFirstChild("N3onHub") then
	PlayerGui:FindFirstChild("N3onHub"):Destroy()
end

local Hub = Instance.new("ScreenGui", PlayerGui)
Hub.Name = "N3onHub"
Hub.ResetOnSpawn = false
Hub.IgnoreGuiInset = true

-- Painel Principal (F1)
local F1 = Instance.new("Frame", Hub)
F1.Size = UDim2.fromOffset(720, 420)
F1.Position = UDim2.fromScale(.5, .5)
F1.AnchorPoint = Vector2.new(.5, .5)
F1.BackgroundColor3 = Color3.fromRGB(35, 15, 60)
Instance.new("UICorner", F1).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", F1).Color = Color3.fromRGB(140, 0, 255)

-- Barra Lateral (F2)
local F2 = Instance.new("Frame", Hub)
F2.Size = UDim2.fromOffset(180, 420)
F2.Position = UDim2.new(0.5, -450, 0.5, 0)
F2.AnchorPoint = Vector2.new(.5, .5)
F2.BackgroundColor3 = Color3.fromRGB(30, 10, 50)
Instance.new("UICorner", F2).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", F2).Color = Color3.fromRGB(140, 0, 255)

-- Container de Conteúdo
local Content = Instance.new("Frame", F1)
Content.Size = UDim2.new(1, -20, 1, -60)
Content.Position = UDim2.fromOffset(10, 50)
Content.BackgroundTransparency = 1

local ScrollContent = Instance.new("ScrollingFrame", Content)
ScrollContent.Size = UDim2.fromScale(1, 1)
ScrollContent.BackgroundTransparency = 1
ScrollContent.ScrollBarThickness = 4
ScrollContent.CanvasSize = UDim2.new(0, 0, 0, 0)

local listLayout = Instance.new("UIListLayout", ScrollContent)
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollContent.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

----------------------------------------------------------------
-- TÍTULO E BOTÕES TOPO
----------------------------------------------------------------

local Title = Instance.new("TextLabel", F1)
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "N3on Hub"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(200, 150, 255)
Title.TextScaled = true
Title.BackgroundTransparency = 1

local MinBtn = Instance.new("TextButton", F1)
MinBtn.Size = UDim2.fromOffset(30, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.Text = "–"
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
MinBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", MinBtn)

local CloseBtn = Instance.new("TextButton", F1)
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 60)
CloseBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", CloseBtn)

----------------------------------------------------------------
-- SISTEMA DE FLY (VOO)
----------------------------------------------------------------

local function RemoveFlyControls()
    if FlyControls then FlyControls:Destroy(); FlyControls = nil end
end

local function CreateFlyControls()
    RemoveFlyControls()
    FlyControls = Instance.new("ScreenGui", PlayerGui)
    FlyControls.Name = "N3onFly"
    
    local Container = Instance.new("Frame", FlyControls)
    Container.Size = UDim2.fromOffset(180, 180)
    Container.Position = UDim2.new(1, -200, 1, -200)
    Container.BackgroundTransparency = 1

    local btns = {}
    local function CB(name, text, pos, size)
        local b = Instance.new("TextButton", Container)
        b.Size = size or UDim2.fromOffset(50, 50)
        b.Position = pos
        b.Text = text
        b.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
        b.TextColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", b)
        
        btns[name] = {pressed = false, btn = b}
        b.InputBegan:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then 
                btns[name].pressed = true 
                b.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
            end 
        end)
        b.InputEnded:Connect(function(i) 
            if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then 
                btns[name].pressed = false 
                b.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
            end 
        end)
    end

    CB("W", "▲", UDim2.fromOffset(65, 0))
    CB("S", "▼", UDim2.fromOffset(65, 130))
    CB("A", "◄", UDim2.fromOffset(0, 65))
    CB("D", "►", UDim2.fromOffset(130, 65))
    CB("Space", "△", UDim2.fromOffset(65, 45), UDim2.fromOffset(50, 35))
    CB("Shift", "▽", UDim2.fromOffset(65, 85), UDim2.fromOffset(50, 35))

    mobileButtons = btns
end

local function StartFly()
    if flyConnection then return end
    flying = true
    CreateFlyControls()
    
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    
    local bg = Instance.new("BodyGyro", hrp)
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 9e9
    
    local bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not flying or not char.Parent then
            bg:Destroy(); bv:Destroy(); flyConnection:Disconnect(); flyConnection = nil
            return
        end
        
        local cam = workspace.CurrentCamera
        bg.CFrame = cam.CFrame
        local dir = Vector3.new(0,0,0)
        
        if UIS:IsKeyDown(Enum.KeyCode.W) or (mobileButtons and mobileButtons.W.pressed) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) or (mobileButtons and mobileButtons.S.pressed) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) or (mobileButtons and mobileButtons.A.pressed) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) or (mobileButtons and mobileButtons.D.pressed) then dir += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or (mobileButtons and mobileButtons.Space.pressed) then dir += Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or (mobileButtons and mobileButtons.Shift.pressed) then dir -= Vector3.new(0,1,0) end
        
        bv.Velocity = if dir.Magnitude > 0 then dir.Unit * savedStates.flySpeed else Vector3.new(0,0,0)
    end)
end

local function StopFly()
    flying = false
    RemoveFlyControls()
end

----------------------------------------------------------------
-- WIDGETS (Slider e Checkbox)
----------------------------------------------------------------

local function Slider(name, min, max, default, callback)
    local frame = Instance.new("Frame", ScrollContent)
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = name .. " : " .. default
    label.TextColor3 = Color3.new(1, 1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, -10, 0, 8)
    bar.Position = UDim2.fromOffset(0, 28)
    bar.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
    Instance.new("UICorner", bar)
    
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    fill.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
    Instance.new("UICorner", fill)
    
    local dragging = false
    local function update(inputX)
        local size = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.fromScale(size, 1)
        local value = math.floor(min + (max - min) * size)
        label.Text = name .. " : " .. value
        callback(value)
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(i.Position.X)
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function Checkbox(name, default, callback)
    local frame = Instance.new("Frame", ScrollContent)
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
    Instance.new("UICorner", frame)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local status = Instance.new("Frame", frame)
    status.Size = UDim2.fromOffset(20, 20)
    status.Position = UDim2.new(1, -30, 0.5, -10)
    status.BackgroundColor3 = default and Color3.fromRGB(170, 0, 255) or Color3.fromRGB(40, 40, 40)
    Instance.new("UICorner", status)
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        status.BackgroundColor3 = state and Color3.fromRGB(170, 0, 255) or Color3.fromRGB(40, 40, 40)
        callback(state)
    end)
end

----------------------------------------------------------------
-- ABAS E LOOPS
----------------------------------------------------------------

local function Clear()
    for _, v in pairs(ScrollContent:GetChildren()) do
        if not v:IsA("UIListLayout") then v:Destroy() end
    end
end

local function LoadHome()
    Clear()
    local t = Instance.new("TextLabel", ScrollContent)
    t.Size = UDim2.new(1, 0, 0, 150)
    t.Text = "Welcome to N3on Hub\n\nPvP Hackers System\nUI Inspired Hub\n\n🎮 Universal Features!"
    t.TextColor3 = Color3.new(1, 1, 1)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextScaled = true
end

local function LoadPlayer()
    Clear()
    Slider("WalkSpeed", 16, 250, savedStates.speed, function(v) savedStates.speed = v end)
    Slider("JumpPower", 50, 500, savedStates.jumpPower, function(v) savedStates.jumpPower = v end)
    Checkbox("Noclip", savedStates.noclip, function(v) savedStates.noclip = v end)
    Checkbox("Infinite Jump", savedStates.infjump, function(v) savedStates.infjump = v end)
    Checkbox("Fly", savedStates.fly, function(v)
        savedStates.fly = v
        if v then StartFly() else StopFly() end
    end)
    Slider("Fly Speed", 10, 300, savedStates.flySpeed, function(v) savedStates.flySpeed = v end)
end

local tabY = 10
local function AddTab(name, emoji, callback)
    local b = Instance.new("TextButton", F2)
    b.Size = UDim2.new(1, -20, 0, 40)
    b.Position = UDim2.fromOffset(10, tabY)
    b.Text = emoji .. " " .. name
    b.BackgroundColor3 = Color3.fromRGB(60, 20, 90)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(callback)
    tabY = tabY + 45
end

AddTab("Home", "🏠", LoadHome)
AddTab("Player", "👤", LoadPlayer)

-- Loops de Funcionamento
RunService.Stepped:Connect(function()
    local char = Player.Character
    if not char then return end
    
    if savedStates.noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = savedStates.speed
        hum.JumpPower = savedStates.jumpPower
    end
end)

UIS.JumpRequest:Connect(function()
    if savedStates.infjump then
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

----------------------------------------------------------------
-- MINIMIZE & CLOSE
----------------------------------------------------------------

local isMini = false
local Bubble = nil

MinBtn.MouseButton1Click:Connect(function()
    if isMini then return end
    isMini = true
    F1.Visible = false
    F2.Visible = false
    
    Bubble = Instance.new("TextButton", Hub)
    Bubble.Size = UDim2.fromOffset(60, 60)
    Bubble.Position = UDim2.new(0.85, 0, 0.85, 0)
    Bubble.Text = "N3"
    Bubble.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
    Bubble.TextColor3 = Color3.new(1, 1, 1)
    Bubble.Font = Enum.Font.GothamBold
    Bubble.TextScaled = true
    Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)
    
    Bubble.MouseButton1Click:Connect(function()
        F1.Visible = true
        F2.Visible = true
        Bubble:Destroy()
        isMini = false
    end)
end)

CloseBtn.MouseButton1Click:Connect(function()
    local overlay = Instance.new("Frame", Hub)
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Color3.new(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    
    local pop = Instance.new("Frame", overlay)
    pop.Size = UDim2.fromOffset(300, 150)
    pop.Position = UDim2.fromScale(0.5, 0.5)
    pop.AnchorPoint = Vector2.new(0.5, 0.5)
    pop.BackgroundColor3 = Color3.fromRGB(40, 0, 60)
    Instance.new("UICorner", pop)
    
    local txt = Instance.new("TextLabel", pop)
    txt.Size = UDim2.new(1, 0, 0.6, 0)
    txt.Text = "Deseja fechar o N3on Hub?"
    txt.TextColor3 = Color3.new(1, 1, 1)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    
    local yes = Instance.new("TextButton", pop)
    yes.Size = UDim2.fromOffset(100, 35)
    yes.Position = UDim2.new(0.25, -50, 0.8, -17)
    yes.Text = "Sim"
    yes.BackgroundColor3 = Color3.fromRGB(120, 30, 60)
    yes.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", yes)
    
    local no = Instance.new("TextButton", pop)
    no.Size = UDim2.fromOffset(100, 35)
    no.Position = UDim2.new(0.75, -50, 0.8, -17)
    no.Text = "Não"
    no.BackgroundColor3 = Color3.fromRGB(80, 30, 120)
    no.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", no)
    
    yes.MouseButton1Click:Connect(function() Hub:Destroy(); _G.N3onHub = nil end)
    no.MouseButton1Click:Connect(function() overlay:Destroy() end)
end)

LoadHome()
_G.N3onHub = { _loaded = true }
