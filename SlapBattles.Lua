--[[
    N3ON HUB - BASE ENGINE "COMPLETAÇO"
    Sistema Central com UI Escalável e Funções de Movimento
]]

local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- SISTEMA DE DADOS (GLOBAL)
----------------------------------------------------------------
_G.N3onHub = {
    _loaded = true,
    SavedStates = {
        speed = 16,
        jump = 50,
        infJump = false,
        noclip = false,
        fly = false,
        flySpeed = 50
    },
    -- Funções exportadas para os módulos
    GUI = {},
}

local SS = _G.N3onHub.SavedStates

----------------------------------------------------------------
-- CONSTRUÇÃO DA INTERFACE (UI)
----------------------------------------------------------------
if PlayerGui:FindFirstChild("N3onHub_Ultimate") then
    PlayerGui.N3onHub_Ultimate:Destroy()
end

local Screen = Instance.new("ScreenGui", PlayerGui)
Screen.Name = "N3onHub_Ultimate"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true

-- Quadro Principal
local Main = Instance.new("Frame", Screen)
Main.Size = UDim2.fromOffset(680, 420)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 15)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(140, 0, 255)
Stroke.Thickness = 2.5

-- Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(10, 5, 20)
Instance.new("UICorner", Sidebar)

local SidebarList = Instance.new("UIListLayout", Sidebar)
SidebarList.Padding = UDim.new(0, 10)
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center

local SidebarPadding = Instance.new("UIPadding", Sidebar)
SidebarPadding.PaddingTop = UDim.new(0, 15)

-- Container de Conteúdo (Direita)
local Content = Instance.new("ScrollingFrame", Main)
Content.Size = UDim2.new(1, -200, 1, -20)
Content.Position = UDim2.fromOffset(190, 10)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 4
Content.CanvasSize = UDim2.new(0, 0, 0, 0)

local ContentList = Instance.new("UIListLayout", Content)
ContentList.Padding = UDim.new(0, 12)

ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 20)
end)

----------------------------------------------------------------
-- TOOLKIT DE COMPONENTES (BOTÕES, SLIDERS, ETC)
----------------------------------------------------------------

local function ClearContent()
    for _, v in pairs(Content:GetChildren()) do
        if not v:IsA("UIListLayout") then v:Destroy() end
    end
end

_G.N3onHub.CreateTitle = function(text)
    local t = Instance.new("TextLabel", Content)
    t.Size = UDim2.new(0.95, 0, 0, 45)
    t.BackgroundTransparency = 1
    t.Text = ">> " .. text .. " <<"
    t.TextColor3 = Color3.fromRGB(180, 100, 255)
    t.Font = Enum.Font.GothamBold
    t.TextScaled = true
end

_G.N3onHub.CreateToggle = function(text, state_key, callback)
    local bg = Instance.new("Frame", Content)
    bg.Size = UDim2.new(0.95, 0, 0, 55)
    bg.BackgroundColor3 = Color3.fromRGB(25, 15, 45)
    Instance.new("UICorner", bg)

    local label = Instance.new("TextLabel", bg)
    label.Size = UDim2.new(0.7, 0, 0.7, 0)
    label.Position = UDim2.fromScale(0.05, 0.15)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(0.2, 0, 0.6, 0)
    btn.Position = UDim2.fromScale(0.75, 0.2)
    btn.BackgroundColor3 = SS[state_key] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
    btn.Text = SS[state_key] and "ON" or "OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    Instance.new("UICorner", btn)

    btn.MouseButton1Click:Connect(function()
        SS[state_key] = not SS[state_key]
        btn.Text = SS[state_key] and "ON" or "OFF"
        btn.BackgroundColor3 = SS[state_key] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
        if callback then callback(SS[state_key]) end
    end)
end

_G.N3onHub.CreateSlider = function(text, min, max, state_key)
    local bg = Instance.new("Frame", Content)
    bg.Size = UDim2.new(0.95, 0, 0, 75)
    bg.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", bg)
    label.Size = UDim2.new(1, 0, 0, 30)
    label.Text = text .. ": " .. SS[state_key]
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.BackgroundTransparency = 1

    local bar = Instance.new("Frame", bg)
    bar.Size = UDim2.new(1, -20, 0, 14)
    bar.Position = UDim2.fromOffset(10, 40)
    bar.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
    Instance.new("UICorner", bar)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.fromScale((SS[state_key] - min) / (max - min), 1)
    fill.BackgroundColor3 = Color3.fromRGB(140, 0, 255)
    Instance.new("UICorner", fill)

    local dragging = false
    local function Update()
        local percent = math.clamp((UIS:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.fromScale(percent, 1)
        local val = math.floor(min + (max - min) * percent)
        SS[state_key] = val
        label.Text = text .. ": " .. val
    end

    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then Update() end end)
end

----------------------------------------------------------------
-- SISTEMA DE ABAS (SIDEBAR)
----------------------------------------------------------------

local function AddTab(name, emoji, callback)
    local b = Instance.new("TextButton", Sidebar)
    b.Size = UDim2.new(0.9, 0, 0, 45)
    b.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
    b.Text = emoji .. " " .. name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        ClearContent()
        callback()
    end)
end

----------------------------------------------------------------
-- SISTEMA DE FLY (PC/MOBILE)
----------------------------------------------------------------
local function StartFly()
    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    local bg = Instance.new("BodyGyro", hrp)
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.P = 9e9; bg.CFrame = hrp.CFrame
    local bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.new(0,0,0)
    
    task.spawn(function()
        while SS.fly do
            local cam = workspace.CurrentCamera
            local dir = Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            bv.Velocity = dir * SS.flySpeed
            bg.CFrame = cam.CFrame
            task.wait()
        end
        bg:Destroy(); bv:Destroy()
    end)
end

----------------------------------------------------------------
-- CONTEÚDO DAS ABAS
----------------------------------------------------------------

local function LoadHome()
    _G.N3onHub.CreateTitle("BEM-VINDO AO N3ON HUB")
    local t = Instance.new("TextLabel", Content)
    t.Size = UDim2.new(1,0,0,120)
    t.BackgroundTransparency = 1
    t.Text = "Usuário: " .. Player.Name .. "\nStatus: Premium / Executado\n\nEste é o Hub Base. Use as abas para gerenciar o player ou injetar módulos de jogos."
    t.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    t.Font = Enum.Font.Gotham
    t.TextScaled = true
end

local function LoadPlayer()
    _G.N3onHub.CreateTitle("CONFIGS DO PERSONAGEM")
    _G.N3onHub.CreateSlider("Velocidade (WalkSpeed)", 16, 500, "speed")
    _G.N3onHub.CreateSlider("Pulo (JumpPower)", 50, 1000, "jump")
    _G.N3onHub.CreateToggle("Pulo Infinito", "infJump")
    _G.N3onHub.CreateToggle("Noclip (Sem Colisão)", "noclip")
    _G.N3onHub.CreateToggle("Fly (Voar)", "fly", function(v) if v then StartFly() end end)
    _G.N3onHub.CreateSlider("Velocidade do Voo", 10, 300, "flySpeed")
end

AddTab("Início", "🏠", LoadHome)
AddTab("Player", "👤", LoadPlayer)

----------------------------------------------------------------
-- LOOP DE FUNCIONAMENTO (RUNSERVICE)
----------------------------------------------------------------
RunService.Stepped:Connect(function()
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = SS.speed
            hum.JumpPower = SS.jump
        end
        if SS.noclip then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if SS.infJump then
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

-- Arrastar Menu
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = Main.Position end end)
Main.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end end)
UIS.InputChanged:Connect(function(i) if i == dragInput and dragging then
    local delta = i.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

LoadHome()
print("N3on Hub: Base Engine Ativada com Sucesso.")
