-- ╔══════════════════════════════════════════════════════════════╗
-- ║  N3ON HUB - BASE UNIVERSAL v5.0                            ║
-- ║  Visual LINDO + Funcionalidades ETW v4                     ║
-- ║  Tema: Dark Modern Neon Purple/Blue                        ║
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
    Background      = Color3.fromRGB(12, 12, 22),
    Sidebar         = Color3.fromRGB(18, 18, 32),
    Card            = Color3.fromRGB(22, 22, 38),
    Accent          = Color3.fromRGB(130, 90, 255),
    AccentLight     = Color3.fromRGB(170, 140, 255),
    AccentDark      = Color3.fromRGB(90, 60, 200),
    Text            = Color3.fromRGB(240, 240, 255),
    TextSecondary   = Color3.fromRGB(170, 170, 200),
    Success         = Color3.fromRGB(80, 220, 130),
    Danger          = Color3.fromRGB(255, 80, 80),
    Warning         = Color3.fromRGB(255, 200, 60),
    SliderTrack     = Color3.fromRGB(35, 35, 55),
    CheckboxBg      = Color3.fromRGB(28, 28, 48),
    Border          = Color3.fromRGB(55, 55, 90),
    Shadow          = Color3.fromRGB(0, 0, 0),
}

-- ═══════════════════════════════════════════════════════════════
-- REMOVE ANTIGO
-- ═══════════════════════════════════════════════════════════════

if PlayerGui:FindFirstChild("N3onHub") then
    PlayerGui:FindFirstChild("N3onHub"):Destroy()
end

-- ═══════════════════════════════════════════════════════════════
-- SCREEN GUI
-- ═══════════════════════════════════════════════════════════════

local Hub = Instance.new("ScreenGui", PlayerGui)
Hub.ResetOnSpawn = false
Hub.IgnoreGuiInset = true
Hub.Name = "N3onHub"
Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ═══════════════════════════════════════════════════════════════
-- SHADOW
-- ═══════════════════════════════════════════════════════════════

local Shadow = Instance.new("Frame", Hub)
Shadow.Size = UDim2.fromScale(1, 1)
Shadow.BackgroundColor3 = Colors.Shadow
Shadow.BackgroundTransparency = 1
Shadow.ZIndex = 1
Shadow.Visible = false

-- ═══════════════════════════════════════════════════════════════
-- MAIN CONTAINER
-- ═══════════════════════════════════════════════════════════════

local MainContainer = Instance.new("Frame", Hub)
MainContainer.Size = UDim2.fromOffset(750, 480)
MainContainer.Position = UDim2.fromScale(0.5, 0.5)
MainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
MainContainer.BackgroundColor3 = Colors.Background
MainContainer.BorderSizePixel = 0
MainContainer.ZIndex = 2
MainContainer.Visible = false

-- Top bar com gradiente
local TopBar = Instance.new("Frame", MainContainer)
TopBar.Size = UDim2.new(1, 0, 0, 3)
TopBar.BorderSizePixel = 0
TopBar.BackgroundColor3 = Colors.Accent
TopBar.ZIndex = 3

local TopGradient = Instance.new("UIGradient", TopBar)
TopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Colors.Accent),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 180, 255)),
    ColorSequenceKeypoint.new(1, Colors.Accent),
})

local MainCorner = Instance.new("UICorner", MainContainer)
MainCorner.CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", MainContainer)
MainStroke.Color = Color3.fromRGB(45, 45, 75)
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

-- Cover pro canto direito
local SidebarCover = Instance.new("Frame", Sidebar)
SidebarCover.Size = UDim2.fromOffset(14, 480)
SidebarCover.Position = UDim2.new(1, -14, 0, 0)
SidebarCover.BackgroundColor3 = Colors.Sidebar
SidebarCover.BorderSizePixel = 0
SidebarCover.ZIndex = 4

-- Logo
local LogoFrame = Instance.new("Frame", Sidebar)
LogoFrame.Size = UDim2.new(1, -20, 0, 55)
LogoFrame.Position = UDim2.fromOffset(10, 15)
LogoFrame.BackgroundColor3 = Colors.Card
LogoFrame.BorderSizePixel = 0
LogoFrame.ZIndex = 5
Instance.new("UICorner", LogoFrame).CornerRadius = UDim.new(0, 10)

local LogoGlow = Instance.new("Frame", LogoFrame)
LogoGlow.Size = UDim2.fromOffset(35, 3)
LogoGlow.Position = UDim2.fromOffset(12, 42)
LogoGlow.BackgroundColor3 = Colors.Accent
LogoGlow.BorderSizePixel = 0
Instance.new("UICorner", LogoGlow).CornerRadius = UDim.new(1, 0)

local LogoText = Instance.new("TextLabel", LogoFrame)
LogoText.Size = UDim2.new(1, -10, 1, -15)
LogoText.Position = UDim2.fromOffset(5, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "⚡ N3ON"
LogoText.Font = Enum.Font.GothamBlack
LogoText.TextSize = 20
LogoText.TextColor3 = Colors.Text
LogoText.ZIndex = 6

local LogoSub = Instance.new("TextLabel", LogoFrame)
LogoSub.Size = UDim2.new(1, 0, 0, 12)
LogoSub.Position = UDim2.fromOffset(8, 30)
LogoSub.BackgroundTransparency = 1
LogoSub.Text = "HUB"
LogoSub.Font = Enum.Font.GothamBold
LogoSub.TextSize = 8
LogoSub.TextColor3 = Colors.AccentLight
LogoSub.ZIndex = 6

local VersionText = Instance.new("TextLabel", Sidebar)
VersionText.Size = UDim2.new(1, -20, 0, 16)
VersionText.Position = UDim2.fromOffset(12, 75)
VersionText.BackgroundTransparency = 1
VersionText.Text = "v5.0 • Universal"
VersionText.Font = Enum.Font.Gotham
VersionText.TextSize = 8
VersionText.TextColor3 = Colors.TextSecondary
VersionText.TextXAlignment = Enum.TextXAlignment.Left
VersionText.ZIndex = 5

-- ═══════════════════════════════════════════════════════════════
-- TABS SCROLL
-- ═══════════════════════════════════════════════════════════════

local TabsScroll = Instance.new("ScrollingFrame", Sidebar)
TabsScroll.Size = UDim2.new(1, -10, 1, -110)
TabsScroll.Position = UDim2.fromOffset(5, 100)
TabsScroll.BackgroundTransparency = 1
TabsScroll.BorderSizePixel = 0
TabsScroll.ScrollBarThickness = 3
TabsScroll.ScrollBarImageColor3 = Colors.Accent
TabsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TabsScroll.ZIndex = 5

local TabsLayout = Instance.new("UIListLayout", TabsScroll)
TabsLayout.Padding = UDim.new(0, 6)
TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder

TabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabsScroll.CanvasSize = UDim2.new(0, 0, 0, TabsLayout.AbsoluteContentSize.Y + 10)
end)

-- ═══════════════════════════════════════════════════════════════
-- CONTENT AREA
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

local TitleDivider = Instance.new("Frame", ContentArea)
TitleDivider.Size = UDim2.new(1, 0, 0, 2)
TitleDivider.Position = UDim2.fromOffset(0, 33)
TitleDivider.BackgroundColor3 = Colors.Accent
TitleDivider.BorderSizePixel = 0
TitleDivider.BackgroundTransparency = 0.4
Instance.new("UICorner", TitleDivider).CornerRadius = UDim.new(1, 0)

-- ═══════════════════════════════════════════════════════════════
-- CONTENT SCROLL
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

local function Clear()
    for _, v in pairs(ScrollContent:GetChildren()) do
        if not v:IsA("UIListLayout") then
            v:Destroy()
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- BOTÕES DO TOPO
-- ═══════════════════════════════════════════════════════════════

local function MakeTopBtn(text, bgColor, posX)
    local btn = Instance.new("TextButton", MainContainer)
    btn.Size = UDim2.fromOffset(28, 28)
    btn.Position = UDim2.new(1, posX, 0, 8)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Colors.Text
    btn.BackgroundColor3 = bgColor
    btn.BorderSizePixel = 0
    btn.ZIndex = 10
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = bgColor:Lerp(Color3.new(1,1,1), 0.25)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = bgColor
        }):Play()
    end)
    
    return btn
end

local MinBtn = MakeTopBtn("─", Color3.fromRGB(45, 45, 65), -68)
local CloseBtn = MakeTopBtn("✕", Color3.fromRGB(180, 50, 50), -34)

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
-- TWEENS
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
    TweenService:Create(Sidebar, TweenInfo.new(0.2), {
        BackgroundTransparency = 1
    }):Play()
    local t = TweenService:Create(Shadow, TweenInfo.new(0.2), {
        BackgroundTransparency = 1
    })
    t:Play()
    t.Completed:Connect(function()
        Shadow.Visible = false
        MainContainer.Visible = false
        MainContainer.Size = UDim2.fromOffset(750, 480)
        if callback then callback() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- HOME
-- ═══════════════════════════════════════════════════════════════

local function LoadHome()
    Clear()
    TabTitle.Text = "🏠 Home"

    local WelcomeCard = Instance.new("Frame", ScrollContent)
    WelcomeCard.Size = UDim2.new(1, 0, 0, 155)
    WelcomeCard.BackgroundColor3 = Colors.Card
    WelcomeCard.BorderSizePixel = 0
    Instance.new("UICorner", WelcomeCard).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", WelcomeCard).Color = Colors.Accent
    Instance.new("UIStroke", WelcomeCard).Transparency = 0.7

    local IconBox = Instance.new("Frame", WelcomeCard)
    IconBox.Size = UDim2.fromOffset(48, 48)
    IconBox.Position = UDim2.fromOffset(18, 18)
    IconBox.BackgroundColor3 = Colors.AccentDark
    IconBox.BorderSizePixel = 0
    Instance.new("UICorner", IconBox).CornerRadius = UDim.new(0, 12)

    local Icon = Instance.new("TextLabel", IconBox)
    Icon.Size = UDim2.new(1, 0, 1, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "⚡"
    Icon.Font = Enum.Font.GothamBold
    Icon.TextSize = 24
    Icon.TextColor3 = Colors.AccentLight

    local WelcomeTitle = Instance.new("TextLabel", WelcomeCard)
    WelcomeTitle.Size = UDim2.new(1, -85, 0, 22)
    WelcomeTitle.Position = UDim2.fromOffset(80, 18)
    WelcomeTitle.BackgroundTransparency = 1
    WelcomeTitle.Text = "Bem-vindo ao N3on Hub"
    WelcomeTitle.Font = Enum.Font.GothamBold
    WelcomeTitle.TextSize = 15
    WelcomeTitle.TextColor3 = Colors.Text
    WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left

    local WelcomeDesc = Instance.new("TextLabel", WelcomeCard)
    WelcomeDesc.Size = UDim2.new(1, -36, 0, 55)
    WelcomeDesc.Position = UDim2.fromOffset(18, 80)
    WelcomeDesc.BackgroundTransparency = 1
    WelcomeDesc.Text = "Hub multi-jogo com visual moderno.\n🔹 Suporte a vários jogos\n🔹 Interface fluida e animada\n🔹 Atualizações frequentes"
    WelcomeDesc.Font = Enum.Font.Gotham
    WelcomeDesc.TextSize = 9
    WelcomeDesc.TextColor3 = Colors.TextSecondary
    WelcomeDesc.TextXAlignment = Enum.TextXAlignment.Left
    WelcomeDesc.TextWrapped = true

    local StatusCard = Instance.new("Frame", ScrollContent)
    StatusCard.Size = UDim2.new(1, 0, 0, 45)
    StatusCard.BackgroundColor3 = Colors.Card
    StatusCard.BorderSizePixel = 0
    Instance.new("UICorner", StatusCard).CornerRadius = UDim.new(0, 10)

    local Dot = Instance.new("Frame", StatusCard)
    Dot.Size = UDim2.fromOffset(10, 10)
    Dot.Position = UDim2.fromOffset(14, 17)
    Dot.BackgroundColor3 = Colors.Success
    Dot.BorderSizePixel = 0
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        while Dot and Dot.Parent do
            TweenService:Create(Dot, TweenInfo.new(0.7), {BackgroundTransparency = 0.5}):Play()
            task.wait(0.7)
            TweenService:Create(Dot, TweenInfo.new(0.7), {BackgroundTransparency = 0}):Play()
            task.wait(0.7)
        end
    end)

    local StatusLabel = Instance.new("TextLabel", StatusCard)
    StatusLabel.Size = UDim2.new(1, -38, 1, 0)
    StatusLabel.Position = UDim2.fromOffset(32, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "✅ Conectado • " .. Player.Name
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 10
    StatusLabel.TextColor3 = Colors.TextSecondary
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

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
-- WIDGETS (BONITOS)
-- ═══════════════════════════════════════════════════════════════

local function Slider(name, min, max, default, callback)
    if min < 1 then min = 1 end

    local frame = Instance.new("Frame", ScrollContent)
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundColor3 = Colors.Card
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", frame).Color = Colors.Border

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -20, 0, 16)
    label.Position = UDim2.fromOffset(12, 7)
    label.BackgroundTransparency = 1
    label.Text = name .. " : " .. default
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, -24, 0, 6)
    bar.Position = UDim2.fromOffset(12, 30)
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
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Colors.Card
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", frame).Color = Colors.Border

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -48, 1, 0)
    label.Position = UDim2.fromOffset(12, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
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

local function Button(name, color, callback)
    local btn = Instance.new("TextButton", ScrollContent)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Colors.Text
    btn.BackgroundColor3 = color or Colors.Accent
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (color or Colors.Accent):Lerp(Color3.new(1,1,1), 0.2)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = color or Colors.Accent
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
-- TABS
-- ═══════════════════════════════════════════════════════════════

local activeTabBtn = nil

local function Tab(name, emoji, _y, callback)
    local btn = Instance.new("TextButton", TabsScroll)
    btn.Size = UDim2.new(1, -10, 0, 42)
    btn.Text = "  " .. emoji .. "  " .. name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextColor3 = Colors.TextSecondary
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BackgroundColor3 = Colors.Card
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 5
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.fromOffset(3, 18)
    indicator.Position = UDim2.fromOffset(2, 12)
    indicator.BackgroundColor3 = Colors.Accent
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        if activeTabBtn then
            local oldInd = activeTabBtn:FindFirstChild("Frame")
            if oldInd then
                TweenService:Create(oldInd, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
            TweenService:Create(activeTabBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Colors.Card,
                TextColor3 = Colors.TextSecondary
            }):Play()
        end
        
        activeTabBtn = btn
        TweenService:Create(indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.AccentDark,
            TextColor3 = Colors.Text
        }):Play()
        
        callback()
    end)

    TabsScroll.CanvasSize = UDim2.new(0, 0, 0, TabsLayout.AbsoluteContentSize.Y + 10)
    return btn
end

_G.N3onHub.Tab        = Tab
_G.N3onHub.LoadHome   = LoadHome
_G.N3onHub.LoadPlayer = LoadPlayer

-- ═══════════════════════════════════════════════════════════════
-- TABS PADRÃO
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
        Bubble.TextSize = 18
        Bubble.TextColor3 = Colors.Text
        Bubble.BackgroundColor3 = Colors.Accent
        Bubble.AutoButtonColor = false
        Bubble.BorderSizePixel = 0
        Bubble.ZIndex = 100
        Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)
        Instance.new("UIStroke", Bubble).Color = Colors.AccentLight
        Instance.new("UIStroke", Bubble).Thickness = 2

        TweenService:Create(Bubble, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(55, 55)
        }):Play()

        Bubble.MouseButton1Click:Connect(function()
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

    local popup = Instance.new("Frame", overlay)
    popup.Size = UDim2.fromOffset(0, 0)
    popup.Position = UDim2.fromScale(0.5, 0.5)
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.BackgroundColor3 = Colors.Background
    popup.BorderSizePixel = 0
    popup.ZIndex = 51
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 16)
    Instance.new("UIStroke", popup).Color = Colors.Accent

    TweenService:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(320, 170)
    }):Play()

    local icon = Instance.new("TextLabel", popup)
    icon.Size = UDim2.fromOffset(40, 40)
    icon.Position = UDim2.fromOffset(140, 15)
    icon.BackgroundTransparency = 1
    icon.Text = "⚠️"
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 30
    icon.ZIndex = 52

    local msg = Instance.new("TextLabel", popup)
    msg.Size = UDim2.new(1, -20, 0, 40)
    msg.Position = UDim2.fromOffset(10, 55)
    msg.BackgroundTransparency = 1
    msg.Text = "Tem certeza que deseja fechar?\nO script precisará ser executado novamente."
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 10
    msg.TextColor3 = Colors.TextSecondary
    msg.TextWrapped = true
    msg.ZIndex = 52

    local yesBtn = Instance.new("TextButton", popup)
    yesBtn.Size = UDim2.fromOffset(110, 35)
    yesBtn.Position = UDim2.fromOffset(35, 110)
    yesBtn.Text = "Sim, fechar"
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.TextSize = 11
    yesBtn.TextColor3 = Colors.Text
    yesBtn.BackgroundColor3 = Colors.Danger
    yesBtn.BorderSizePixel = 0
    yesBtn.ZIndex = 52
    yesBtn.AutoButtonColor = false
    Instance.new("UICorner", yesBtn).CornerRadius = UDim.new(0, 8)

    local noBtn = Instance.new("TextButton", popup)
    noBtn.Size = UDim2.fromOffset(110, 35)
    noBtn.Position = UDim2.fromOffset(175, 110)
    noBtn.Text = "Cancelar"
    noBtn.Font = Enum.Font.GothamBold
    noBtn.TextSize = 11
    noBtn.TextColor3 = Colors.Text
    noBtn.BackgroundColor3 = Colors.Card
    noBtn.BorderSizePixel = 0
    noBtn.ZIndex = 52
    noBtn.AutoButtonColor = false
    Instance.new("UICorner", noBtn).CornerRadius = UDim.new(0, 8)
    
    noBtn.MouseEnter:Connect(function()
        TweenService:Create(noBtn, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Accent}):Play()
    end)
    noBtn.MouseLeave:Connect(function()
        TweenService:Create(noBtn, TweenInfo.new(0.15), {BackgroundColor3 = Colors.Card}):Play()
    end)

    local function closePopup()
        TweenService:Create(overlay, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
        local t = TweenService:Create(popup, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(0, 0)
        })
        t:Play()
        t.Completed:Connect(function() overlay:Destroy() end)
    end

    yesBtn.MouseButton1Click:Connect(function()
        overlay:Destroy()
        Hub:Destroy()
        print("[N3on Hub] Fechado pelo usuário.")
    end)
    noBtn.MouseButton1Click:Connect(closePopup)
end)

-- ═══════════════════════════════════════════════════════════════
-- TECLA INSERT (ABRIR/FECHAR)
-- ═══════════════════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if Mini and Bubble then
            TweenService:Create(Bubble, TweenInfo.new(0.2), {
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
print("║  🔮 N3ON HUB v5.0 CARREGADO!            ║")
print("║  Visual LINDO + Funcionalidades ETW v4   ║")
print("║  Pressione INSERT para abrir/fechar      ║")
print("╚══════════════════════════════════════════╝")
