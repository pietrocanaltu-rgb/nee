-- ╔══════════════════════════════════════════════════════════════╗
-- ║  N3ON HUB - BASE UNIVERSAL v3.0 (COMPLETO E FUNCIONAL)      ║
-- ║  Tema: Dark Modern Neon Purple/Blue                         ║
-- ╚══════════════════════════════════════════════════════════════╝

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ═══════════════════════════════════════════════════════════════
-- PALETA DE CORES
-- ═══════════════════════════════════════════════════════════════

local Colors = {
    Background      = Color3.fromRGB(15, 15, 25),
    Sidebar         = Color3.fromRGB(20, 20, 35),
    Card            = Color3.fromRGB(25, 25, 40),
    Accent          = Color3.fromRGB(120, 80, 255),
    AccentLight     = Color3.fromRGB(160, 130, 255),
    AccentDark      = Color3.fromRGB(80, 50, 180),
    Text            = Color3.fromRGB(240, 240, 255),
    TextSecondary   = Color3.fromRGB(180, 180, 200),
    Success         = Color3.fromRGB(80, 220, 120),
    Danger          = Color3.fromRGB(255, 80, 80),
    SliderTrack     = Color3.fromRGB(40, 40, 60),
    SliderFill      = Color3.fromRGB(120, 80, 255),
    CheckboxBg      = Color3.fromRGB(30, 30, 50),
    Border          = Color3.fromRGB(60, 60, 100),
    Shadow          = Color3.fromRGB(0, 0, 0),
}

-- ═══════════════════════════════════════════════════════════════
-- REMOVE INSTÂNCIA ANTIGA
-- ═══════════════════════════════════════════════════════════════

if PlayerGui:FindFirstChild("N3onHub") then
    PlayerGui:FindFirstChild("N3onHub"):Destroy()
end

-- ═══════════════════════════════════════════════════════════════
-- SCREEN GUI PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local Hub = Instance.new("ScreenGui", PlayerGui)
Hub.ResetOnSpawn = false
Hub.IgnoreGuiInset = true
Hub.Name = "N3onHub"
Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ═══════════════════════════════════════════════════════════════
-- SHADOW DE FUNDO
-- ═══════════════════════════════════════════════════════════════

local Shadow = Instance.new("Frame", Hub)
Shadow.Size = UDim2.fromScale(1, 1)
Shadow.BackgroundColor3 = Colors.Shadow
Shadow.BackgroundTransparency = 1
Shadow.ZIndex = 1
Shadow.Visible = false

-- ═══════════════════════════════════════════════════════════════
-- CONTAINER PRINCIPAL
-- ═══════════════════════════════════════════════════════════════

local MainContainer = Instance.new("Frame", Hub)
MainContainer.Size = UDim2.fromOffset(750, 480)
MainContainer.Position = UDim2.fromScale(0.5, 0.5)
MainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
MainContainer.BackgroundColor3 = Colors.Background
MainContainer.BorderSizePixel = 0
MainContainer.ZIndex = 2
MainContainer.Visible = false

local TopGradient = Instance.new("Frame", MainContainer)
TopGradient.Size = UDim2.new(1, 0, 0, 3)
TopGradient.BorderSizePixel = 0
TopGradient.BackgroundColor3 = Colors.Accent
TopGradient.ZIndex = 3

local MainCorner = Instance.new("UICorner", MainContainer)
MainCorner.CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", MainContainer)
MainStroke.Color = Color3.fromRGB(50, 50, 80)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.5

-- ═══════════════════════════════════════════════════════════════
-- SIDEBAR
-- ═══════════════════════════════════════════════════════════════

local Sidebar = Instance.new("Frame", MainContainer)
Sidebar.Size = UDim2.fromOffset(200, 480)
Sidebar.Position = UDim2.fromOffset(0, 0)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3

local SidebarCorner = Instance.new("UICorner", Sidebar)
SidebarCorner.CornerRadius = UDim.new(0, 14)

local SidebarRightCover = Instance.new("Frame", Sidebar)
SidebarRightCover.Size = UDim2.fromOffset(14, 480)
SidebarRightCover.Position = UDim2.new(1, -14, 0, 0)
SidebarRightCover.BackgroundColor3 = Colors.Sidebar
SidebarRightCover.BorderSizePixel = 0
SidebarRightCover.ZIndex = 4

-- Logo
local LogoContainer = Instance.new("Frame", Sidebar)
LogoContainer.Size = UDim2.new(1, -20, 0, 60)
LogoContainer.Position = UDim2.fromOffset(10, 15)
LogoContainer.BackgroundColor3 = Colors.Card
LogoContainer.BorderSizePixel = 0
LogoContainer.ZIndex = 5
Instance.new("UICorner", LogoContainer).CornerRadius = UDim.new(0, 10)

local LogoText = Instance.new("TextLabel", LogoContainer)
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "N3ON"
LogoText.Font = Enum.Font.GothamBlack
LogoText.TextSize = 22
LogoText.TextColor3 = Colors.Text
LogoText.ZIndex = 6

local HubSubtitle = Instance.new("TextLabel", LogoContainer)
HubSubtitle.Size = UDim2.new(1, 0, 0, 12)
HubSubtitle.Position = UDim2.fromOffset(0, 28)
HubSubtitle.BackgroundTransparency = 1
HubSubtitle.Text = "HUB"
HubSubtitle.Font = Enum.Font.GothamBold
HubSubtitle.TextSize = 9
HubSubtitle.TextColor3 = Colors.AccentLight
HubSubtitle.ZIndex = 6

local VersionLabel = Instance.new("TextLabel", Sidebar)
VersionLabel.Size = UDim2.new(1, -20, 0, 18)
VersionLabel.Position = UDim2.fromOffset(10, 80)
VersionLabel.BackgroundTransparency = 1
VersionLabel.Text = "v3.0 • Universal"
VersionLabel.Font = Enum.Font.Gotham
VersionLabel.TextSize = 9
VersionLabel.TextColor3 = Colors.TextSecondary
VersionLabel.TextXAlignment = Enum.TextXAlignment.Left
VersionLabel.ZIndex = 5

-- ═══════════════════════════════════════════════════════════════
-- SCROLL DE TABS
-- ═══════════════════════════════════════════════════════════════

local TabsContainer = Instance.new("ScrollingFrame", Sidebar)
TabsContainer.Size = UDim2.new(1, -10, 1, -115)
TabsContainer.Position = UDim2.fromOffset(5, 105)
TabsContainer.BackgroundTransparency = 1
TabsContainer.BorderSizePixel = 0
TabsContainer.ScrollBarThickness = 3
TabsContainer.ScrollBarImageColor3 = Colors.Accent
TabsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
TabsContainer.ZIndex = 5

local TabsLayout = Instance.new("UIListLayout", TabsContainer)
TabsLayout.Padding = UDim.new(0, 5)
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder

TabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabsContainer.CanvasSize = UDim2.new(0, 0, 0, TabsLayout.AbsoluteContentSize.Y + 10)
end)

-- ═══════════════════════════════════════════════════════════════
-- ÁREA DE CONTEÚDO
-- ═══════════════════════════════════════════════════════════════

local ContentArea = Instance.new("Frame", MainContainer)
ContentArea.Size = UDim2.new(1, -215, 1, -20)
ContentArea.Position = UDim2.fromOffset(210, 10)
ContentArea.BackgroundTransparency = 1
ContentArea.BorderSizePixel = 0
ContentArea.ZIndex = 3

local TabTitle = Instance.new("TextLabel", ContentArea)
TabTitle.Size = UDim2.new(1, 0, 0, 30)
TabTitle.BackgroundTransparency = 1
TabTitle.Text = "Home"
TabTitle.Font = Enum.Font.GothamBold
TabTitle.TextSize = 18
TabTitle.TextColor3 = Colors.Text
TabTitle.TextXAlignment = Enum.TextXAlignment.Left
TabTitle.ZIndex = 5

local TitleBar = Instance.new("Frame", ContentArea)
TitleBar.Size = UDim2.new(1, 0, 0, 2)
TitleBar.Position = UDim2.fromOffset(0, 32)
TitleBar.BackgroundColor3 = Colors.Accent
TitleBar.BorderSizePixel = 0
TitleBar.BackgroundTransparency = 0.3
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(1, 0)

-- ═══════════════════════════════════════════════════════════════
-- SCROLL DE CONTEÚDO
-- ═══════════════════════════════════════════════════════════════

local ScrollContent = Instance.new("ScrollingFrame", ContentArea)
ScrollContent.Size = UDim2.new(1, 0, 1, -45)
ScrollContent.Position = UDim2.fromOffset(0, 40)
ScrollContent.BackgroundTransparency = 1
ScrollContent.BorderSizePixel = 0
ScrollContent.ScrollBarThickness = 4
ScrollContent.ScrollBarImageColor3 = Colors.Accent
ScrollContent.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollContent.ZIndex = 4

local ContentLayout = Instance.new("UIListLayout", ScrollContent)
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function UpdateCanvasSize()
    ScrollContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
end
ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)

-- ═══════════════════════════════════════════════════════════════
-- BOTÕES DO TOPO
-- ═══════════════════════════════════════════════════════════════

local function CreateTopButton(text, color, position)
    local btn = Instance.new("TextButton", MainContainer)
    btn.Size = UDim2.fromOffset(28, 28)
    btn.Position = position
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Colors.Text
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.AutoButtonColor = false
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = color
        }):Play()
    end)
    
    return btn
end

local MinBtn = CreateTopButton("─", Color3.fromRGB(50, 50, 70), UDim2.new(1, -68, 0, 8))
local CloseBtn = CreateTopButton("✕", Color3.fromRGB(180, 50, 50), UDim2.new(1, -34, 0, 8))

-- ═══════════════════════════════════════════════════════════════
-- LIMPAR CONTEÚDO
-- ═══════════════════════════════════════════════════════════════

local function Clear()
    for _, v in pairs(ScrollContent:GetChildren()) do
        if not v:IsA("UIListLayout") then
            v:Destroy()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- EXPORTAÇÃO GLOBAL
-- ═══════════════════════════════════════════════════════════════

_G.N3onHub = {}
_G.N3onHub._loaded = true
_G.N3onHub.Colors = Colors
_G.N3onHub.GUI = {
    Hub = Hub,
    MainContainer = MainContainer,
    Sidebar = Sidebar,
    ScrollContent = ScrollContent,
    ContentArea = ContentArea,
    TabTitle = TabTitle,
    Clear = Clear,
    UpdateCanvasSize = UpdateCanvasSize,
}

-- ═══════════════════════════════════════════════════════════════
-- TWEENS ABRIR / FECHAR
-- ═══════════════════════════════════════════════════════════════

local function ShowHub()
    Shadow.Visible = true
    MainContainer.Visible = true
    MainContainer.Size = UDim2.fromOffset(0, 0)
    MainContainer.BackgroundTransparency = 1
    Sidebar.BackgroundTransparency = 1
    Shadow.BackgroundTransparency = 1
    
    TweenService:Create(MainContainer, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(750, 480),
        BackgroundTransparency = 0
    }):Play()
    
    TweenService:Create(Sidebar, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()
    
    TweenService:Create(Shadow, TweenInfo.new(0.35), {
        BackgroundTransparency = 0.6
    }):Play()
end

local function HideHub(callback)
    TweenService:Create(MainContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1
    }):Play()
    
    TweenService:Create(Sidebar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    }):Play()
    
    local shadowTween = TweenService:Create(Shadow, TweenInfo.new(0.2), {
        BackgroundTransparency = 1
    })
    shadowTween:Play()
    shadowTween.Completed:Connect(function()
        Shadow.Visible = false
        MainContainer.Visible = false
        MainContainer.Size = UDim2.fromOffset(750, 480) -- Reseta tamanho
        if callback then callback() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- HOME PAGE
-- ═══════════════════════════════════════════════════════════════

local function LoadHome()
    Clear()
    TabTitle.Text = "🏠 Home"
    
    local WelcomeCard = Instance.new("Frame", ScrollContent)
    WelcomeCard.Size = UDim2.new(1, 0, 0, 160)
    WelcomeCard.BackgroundColor3 = Colors.Card
    WelcomeCard.BorderSizePixel = 0
    Instance.new("UICorner", WelcomeCard).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", WelcomeCard).Color = Colors.Accent
    Instance.new("UIStroke", WelcomeCard).Transparency = 0.7
    
    local IconFrame = Instance.new("Frame", WelcomeCard)
    IconFrame.Size = UDim2.fromOffset(50, 50)
    IconFrame.Position = UDim2.fromOffset(20, 20)
    IconFrame.BackgroundColor3 = Colors.AccentDark
    IconFrame.BorderSizePixel = 0
    Instance.new("UICorner", IconFrame).CornerRadius = UDim.new(0, 12)
    
    local IconText = Instance.new("TextLabel", IconFrame)
    IconText.Size = UDim2.new(1, 0, 1, 0)
    IconText.BackgroundTransparency = 1
    IconText.Text = "⚡"
    IconText.Font = Enum.Font.GothamBold
    IconText.TextSize = 24
    IconText.TextColor3 = Colors.AccentLight
    
    local WelcomeTitle = Instance.new("TextLabel", WelcomeCard)
    WelcomeTitle.Size = UDim2.new(1, -90, 0, 25)
    WelcomeTitle.Position = UDim2.fromOffset(85, 20)
    WelcomeTitle.BackgroundTransparency = 1
    WelcomeTitle.Text = "Bem-vindo ao N3on Hub"
    WelcomeTitle.Font = Enum.Font.GothamBold
    WelcomeTitle.TextSize = 16
    WelcomeTitle.TextColor3 = Colors.Text
    WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    local WelcomeDesc = Instance.new("TextLabel", WelcomeCard)
    WelcomeDesc.Size = UDim2.new(1, -40, 0, 60)
    WelcomeDesc.Position = UDim2.fromOffset(20, 85)
    WelcomeDesc.BackgroundTransparency = 1
    WelcomeDesc.Text = "Hub multi-jogo com design moderno.\n🔹 Suporte a vários jogos\n🔹 Interface fluida e bonita\n🔹 Atualizações constantes"
    WelcomeDesc.Font = Enum.Font.Gotham
    WelcomeDesc.TextSize = 10
    WelcomeDesc.TextColor3 = Colors.TextSecondary
    WelcomeDesc.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeDesc.TextWrapped = true
    
    local StatusCard = Instance.new("Frame", ScrollContent)
    StatusCard.Size = UDim2.new(1, 0, 0, 50)
    StatusCard.BackgroundColor3 = Colors.Card
    StatusCard.BorderSizePixel = 0
    Instance.new("UICorner", StatusCard).CornerRadius = UDim.new(0, 12)
    
    local StatusDot = Instance.new("Frame", StatusCard)
    StatusDot.Size = UDim2.fromOffset(10, 10)
    StatusDot.Position = UDim2.fromOffset(15, 20)
    StatusDot.BackgroundColor3 = Colors.Success
    StatusDot.BorderSizePixel = 0
    Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)
    
    task.spawn(function()
        while StatusDot and StatusDot.Parent do
            TweenService:Create(StatusDot, TweenInfo.new(0.8), {BackgroundTransparency = 0.5}):Play()
            task.wait(0.8)
            TweenService:Create(StatusDot, TweenInfo.new(0.8), {BackgroundTransparency = 0}):Play()
            task.wait(0.8)
        end
    end)
    
    local StatusText = Instance.new("TextLabel", StatusCard)
    StatusText.Size = UDim2.new(1, -40, 1, 0)
    StatusText.Position = UDim2.fromOffset(35, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "✅ Conectado • " .. Player.Name
    StatusText.Font = Enum.Font.Gotham
    StatusText.TextSize = 11
    StatusText.TextColor3 = Colors.TextSecondary
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    
    UpdateCanvasSize()
end

-- ═══════════════════════════════════════════════════════════════
-- PLAYER SYSTEM
-- ═══════════════════════════════════════════════════════════════

local function GetHum()
    local char = Player.Character or Player.CharacterAdded:Wait()
    return char:WaitForChild("Humanoid")
end

local savedStates = {
    speed    = 16,
    jumpPower = 50,
    noclip   = false,
    infjump  = false,
    fly      = false,
    flySpeed = 50
}

_G.N3onHub.SavedStates = savedStates
_G.N3onHub.GetHum = GetHum

-- ═══════════════════════════════════════════════════════════════
-- WIDGETS
-- ═══════════════════════════════════════════════════════════════

local function Slider(name, min, max, default, callback)
    if min < 1 then min = 1 end

    local frame = Instance.new("Frame", ScrollContent)
    frame.Size = UDim2.new(1, 0, 0, 55)
    frame.BackgroundColor3 = Colors.Card
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", frame).Color = Colors.Border

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Position = UDim2.fromOffset(12, 8)
    label.BackgroundTransparency = 1
    label.Text = name .. " : " .. default
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, -24, 0, 6)
    bar.Position = UDim2.fromOffset(12, 32)
    bar.BackgroundColor3 = Colors.SliderTrack
    bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.fromScale((default - min) / (max - min), 1)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill)

    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.fromOffset(16, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.fromScale(fill.Size.X.Scale, 0.5)
    knob.BackgroundColor3 = Colors.Text
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", knob).Color = Colors.Accent

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
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3 = Colors.Card
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", frame).Color = Colors.Border

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("Frame", frame)
    box.Size = UDim2.fromOffset(22, 22)
    box.Position = UDim2.new(1, -30, 0.5, -11)
    box.BackgroundColor3 = Colors.CheckboxBg
    box.BorderSizePixel = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    Instance.new("UIStroke", box).Color = Colors.Accent

    local fill = Instance.new("Frame", box)
    fill.Size = UDim2.new(1, -4, 1, -4)
    fill.Position = UDim2.fromOffset(2, 2)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel = 0
    fill.Visible = defaultState
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)

    local check = Instance.new("TextLabel", fill)
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Text = "✓"
    check.Font = Enum.Font.GothamBold
    check.TextSize = 12
    check.TextColor3 = Colors.Text
    check.Visible = defaultState

    local state = defaultState
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            state = not state
            fill.Visible = state
            check.Visible = state
            callback(state)
        end
    end)

    UpdateCanvasSize()
    return frame
end

local function Button(name, callback)
    local btn = Instance.new("TextButton", ScrollContent)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Colors.Text
    btn.BackgroundColor3 = Colors.Accent
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Colors.AccentLight
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = Colors.Accent
        }):Play()
    end)
    
    btn.MouseButton1Click:Connect(callback)
    
    UpdateCanvasSize()
    return btn
end

_G.N3onHub.Slider   = Slider
_G.N3onHub.Checkbox = Checkbox
_G.N3onHub.Button   = Button

-- ═══════════════════════════════════════════════════════════════
-- NOCLIP / INF JUMP
-- ═══════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════
-- FLY SYSTEM
-- ═══════════════════════════════════════════════════════════════

local flying  = false
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
        btn.BackgroundColor3 = Colors.AccentDark
        btn.TextColor3 = Colors.Text; btn.BorderSizePixel = 0
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
                data.pressed=true; data.btn.BackgroundColor3=Colors.AccentLight
            end
        end)
        data.btn.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
                data.pressed=false; data.btn.BackgroundColor3=Colors.AccentDark
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

-- ═══════════════════════════════════════════════════════════════
-- SPEED / JUMP LOOP
-- ═══════════════════════════════════════════════════════════════

local speedLoopActive = false
local jumpLoopActive  = false

local function StartSpeedLoop()
    if speedLoopActive then return end
    speedLoopActive = true
    task.spawn(function()
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
    task.spawn(function()
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

-- ═══════════════════════════════════════════════════════════════
-- LOAD PLAYER TAB
-- ═══════════════════════════════════════════════════════════════

local function LoadPlayer()
    Clear()
    TabTitle.Text = "👤 Player"
    
    Slider("Walk Speed", 1, 200, savedStates.speed, function(v)
        savedStates.speed = v
        local hum = GetHum(); if hum then hum.WalkSpeed = v end
    end)
    Slider("Jump Power", 1, 200, savedStates.jumpPower, function(v)
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

-- ═══════════════════════════════════════════════════════════════
-- SISTEMA DE TABS
-- ═══════════════════════════════════════════════════════════════

local activeTabBtn = nil

local function Tab(name, emoji, _y, callback)
    local btn = Instance.new("TextButton", TabsContainer)
    btn.Size = UDim2.new(1, -10, 0, 44)
    btn.Text = "  " .. emoji .. "  " .. name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.TextColor3 = Colors.TextSecondary
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BackgroundColor3 = Colors.Card
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 5
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.fromOffset(3, 20)
    indicator.Position = UDim2.fromOffset(2, 12)
    indicator.BackgroundColor3 = Colors.Accent
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    btn.MouseButton1Click:Connect(function()
        if activeTabBtn then
            local oldIndicator = activeTabBtn:FindFirstChild("Frame")
            if oldIndicator then
                TweenService:Create(oldIndicator, TweenInfo.new(0.2), {
                    BackgroundTransparency = 1
                }):Play()
            end
            TweenService:Create(activeTabBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.Card,
                TextColor3 = Colors.TextSecondary
            }):Play()
        end
        
        activeTabBtn = btn
        TweenService:Create(indicator, TweenInfo.new(0.2), {
            BackgroundTransparency = 0
        }):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.AccentDark,
            TextColor3 = Colors.Text
        }):Play()
        
        callback()
    end)
    
    TabsContainer.CanvasSize = UDim2.new(0, 0, 0, TabsLayout.AbsoluteContentSize.Y + 10)
    
    return btn
end

_G.N3onHub.Tab        = Tab
_G.N3onHub.LoadHome   = LoadHome
_G.N3onHub.LoadPlayer = LoadPlayer

-- ═══════════════════════════════════════════════════════════════
-- REGISTRAR TABS PADRÃO
-- ═══════════════════════════════════════════════════════════════

Tab("Home",   "🏠", 0, LoadHome)
Tab("Player", "👤", 0, LoadPlayer)

LoadHome()

-- ═══════════════════════════════════════════════════════════════
-- MINIMIZE (FUNCIONAL)
-- ═══════════════════════════════════════════════════════════════

local Mini  = false
local Bubble = nil

MinBtn.MouseButton1Click:Connect(function()
    if Mini then return end
    Mini = true

    HideHub(function()
        Bubble = Instance.new("TextButton", Hub)
        Bubble.AnchorPoint = Vector2.new(0.5, 0.5)
        Bubble.Position = UDim2.new(0.85, 0, 0.85, 0)
        Bubble.Size = UDim2.fromOffset(0, 0)
        Bubble.Text = "N3"
        Bubble.Font = Enum.Font.GothamBlack
        Bubble.TextSize = 20
        Bubble.TextColor3 = Colors.Text
        Bubble.BackgroundColor3 = Colors.Accent
        Bubble.AutoButtonColor = false
        Bubble.BorderSizePixel = 0
        Bubble.ZIndex = 100
        Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)
        
        TweenService:Create(Bubble, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(55, 55)
        }):Play()

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

-- ═══════════════════════════════════════════════════════════════
-- CLOSE POPUP (FUNCIONAL)
-- ═══════════════════════════════════════════════════════════════

CloseBtn.MouseButton1Click:Connect(function()
    local overlay = Instance.new("Frame", Hub)
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundColor3 = Colors.Shadow
    overlay.BackgroundTransparency = 1
    overlay.ZIndex = 50
    TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()

    local pop = Instance.new("Frame", overlay)
    pop.Size = UDim2.fromOffset(0, 0)
    pop.Position = UDim2.fromScale(0.5, 0.5)
    pop.AnchorPoint = Vector2.new(0.5, 0.5)
    pop.BackgroundColor3 = Colors.Background
    pop.BorderSizePixel = 0
    pop.ZIndex = 51
    Instance.new("UICorner", pop).CornerRadius = UDim.new(0, 16)
    Instance.new("UIStroke", pop).Color = Colors.Accent

    TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(320, 170)
    }):Play()

    local icon = Instance.new("TextLabel", pop)
    icon.Size = UDim2.fromOffset(40, 40)
    icon.Position = UDim2.fromOffset(140, 15)
    icon.BackgroundTransparency = 1
    icon.Text = "⚠️"
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 30
    icon.ZIndex = 52

    local txt = Instance.new("TextLabel", pop)
    txt.Size = UDim2.new(1, -20, 0, 40)
    txt.Position = UDim2.fromOffset(10, 55)
    txt.BackgroundTransparency = 1
    txt.Text = "Tem certeza que deseja fechar?\nVocê precisará re-executar o script."
    txt.Font = Enum.Font.Gotham
    txt.TextSize = 11
    txt.TextColor3 = Colors.TextSecondary
    txt.TextWrapped = true
    txt.ZIndex = 52

    local yes = Instance.new("TextButton", pop)
    yes.Size = UDim2.fromOffset(110, 35)
    yes.Position = UDim2.fromOffset(35, 110)
    yes.Text = "Sim, fechar"
    yes.Font = Enum.Font.GothamBold
    yes.TextSize = 11
    yes.TextColor3 = Colors.Text
    yes.BackgroundColor3 = Colors.Danger
    yes.BorderSizePixel = 0
    yes.ZIndex = 52
    yes.AutoButtonColor = false
    Instance.new("UICorner", yes).CornerRadius = UDim.new(0, 8)

    local no = Instance.new("TextButton", pop)
    no.Size = UDim2.fromOffset(110, 35)
    no.Position = UDim2.fromOffset(175, 110)
    no.Text = "Cancelar"
    no.Font = Enum.Font.GothamBold
    no.TextSize = 11
    no.TextColor3 = Colors.Text
    no.BackgroundColor3 = Colors.Card
    no.BorderSizePixel = 0
    no.ZIndex = 52
    no.AutoButtonColor = false
    Instance.new("UICorner", no).CornerRadius = UDim.new(0, 8)
    
    no.MouseEnter:Connect(function()
        TweenService:Create(no, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Accent}):Play()
    end)
    no.MouseLeave:Connect(function()
        TweenService:Create(no, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Card}):Play()
    end)

    local function closePopup()
        TweenService:Create(overlay, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
        local t = TweenService:Create(pop, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(0, 0)
        })
        t:Play()
        t.Completed:Connect(function() overlay:Destroy() end)
    end

    yes.MouseButton1Click:Connect(function()
        overlay:Destroy()
        Hub:Destroy()
        print("[N3on Hub] Fechado pelo usuário.")
    end)
    no.MouseButton1Click:Connect(closePopup)
end)

-- ═══════════════════════════════════════════════════════════════
-- ABRIR HUB (TECLA INSERT)
-- ═══════════════════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if Mini then
            -- Se tá minimizado, clica na bolinha pra reabrir
            if Bubble then
                -- Simula o clique na bolinha
                TweenService:Create(Bubble, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2.fromOffset(0, 0)
                }):Play()
                task.delay(0.2, function()
                    if Bubble then
                        Bubble:Destroy()
                        Bubble = nil
                        Mini = false
                        ShowHub()
                    end
                end)
            end
        elseif not MainContainer.Visible then
            ShowHub()
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- INICIAR
-- ═══════════════════════════════════════════════════════════════

ShowHub()

print("╔══════════════════════════════════════════╗")
print("║  🔮 N3ON HUB v3.0 CARREGADO!            ║")
print("║  Pressione INSERT para abrir/fechar      ║")
print("║  Minimize e Close funcionais             ║")
print("╚══════════════════════════════════════════╝")
