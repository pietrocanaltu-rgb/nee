-- ╔══════════════════════════════════════════════╗
-- ║         N3on Hub — ModuleScript Base         ║
-- ║   require() este módulo nos seus scripts     ║
-- ╚══════════════════════════════════════════════╝
--
-- USO:
--   local Hub = require(game.ReplicatedStorage.N3onHubModule)
--   Hub:Tab("Minha Aba", "⚙️", function() ... end)
--   Hub:Slider(...)  Hub:Toggle(...)  Hub:Btn(...)
--   Hub:Sep(...)     Hub:Info(...)
--   Hub:Clear()      Hub:ShowHub()   Hub:HideHub(cb)

local Module = {}

----------------------------------------------------------------
-- SERVIÇOS
----------------------------------------------------------------
local Player       = game.Players.LocalPlayer
local PlayerGui    = Player:WaitForChild("PlayerGui")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

----------------------------------------------------------------
-- LIMPA INSTÂNCIA ANTIGA
----------------------------------------------------------------
if PlayerGui:FindFirstChild("N3onHub") then
    PlayerGui:FindFirstChild("N3onHub"):Destroy()
end

----------------------------------------------------------------
-- PALETA
----------------------------------------------------------------
local C = {
    bg1     = Color3.fromRGB(18,  6,  35),
    bg2     = Color3.fromRGB(28, 10,  50),
    bg3     = Color3.fromRGB(45, 18,  75),
    accent  = Color3.fromRGB(140,  0, 255),
    accent2 = Color3.fromRGB(180, 80, 255),
    text    = Color3.fromRGB(230, 210, 255),
    textDim = Color3.fromRGB(160, 130, 200),
    green   = Color3.fromRGB( 50, 200, 100),
    red     = Color3.fromRGB(200,  50,  80),
}
Module.Colors = C

----------------------------------------------------------------
-- HUB SCREENGUI
----------------------------------------------------------------
local Hub = Instance.new("ScreenGui", PlayerGui)
Hub.ResetOnSpawn   = false
Hub.IgnoreGuiInset = true
Hub.Name           = "N3onHub"
Hub.DisplayOrder   = 10

----------------------------------------------------------------
-- PAINEL PRINCIPAL (F1) + SIDEBAR (F2)
----------------------------------------------------------------
local F1 = Instance.new("Frame", Hub)
F1.Size             = UDim2.fromOffset(700, 430)
F1.Position         = UDim2.fromScale(.5, .5)
F1.AnchorPoint      = Vector2.new(.5, .5)
F1.BackgroundColor3 = C.bg1
F1.BorderSizePixel  = 0
Instance.new("UICorner", F1).CornerRadius = UDim.new(0, 14)
local s1 = Instance.new("UIStroke", F1); s1.Color = C.accent; s1.Thickness = 1.5

local F2 = Instance.new("Frame", Hub)
F2.Size             = UDim2.fromOffset(165, 430)
F2.AnchorPoint      = Vector2.new(1, .5)
F2.BackgroundColor3 = C.bg2
F2.BorderSizePixel  = 0
Instance.new("UICorner", F2).CornerRadius = UDim.new(0, 14)
local s2 = Instance.new("UIStroke", F2); s2.Color = C.accent; s2.Thickness = 1.5

local function AlignSidebar()
    F2.Position = UDim2.new(
        F1.Position.X.Scale,
        F1.Position.X.Offset - (F1.AbsoluteSize.X / 2) - (F2.AbsoluteSize.X / 2) - 8,
        F1.Position.Y.Scale,
        F1.Position.Y.Offset
    )
end
AlignSidebar()

----------------------------------------------------------------
-- TOPBAR + TÍTULO
----------------------------------------------------------------
local TopBar = Instance.new("Frame", F1)
TopBar.Size             = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = C.bg2
TopBar.BorderSizePixel  = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 14)
-- cobre arredondamento inferior do topbar
local Fix = Instance.new("Frame", TopBar)
Fix.Size             = UDim2.new(1, 0, 0, 14)
Fix.Position         = UDim2.new(0, 0, 1, -14)
Fix.BackgroundColor3 = C.bg2
Fix.BorderSizePixel  = 0

local TitleLbl = Instance.new("TextLabel", TopBar)
TitleLbl.Size               = UDim2.new(1, -90, 1, 0)
TitleLbl.Position           = UDim2.fromOffset(14, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text               = "✦ N3on Hub"
TitleLbl.Font               = Enum.Font.GothamBold
TitleLbl.TextScaled         = true
TitleLbl.TextColor3         = C.accent2
TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left

local function TopBtn(xOff, txt, bg)
    local b = Instance.new("TextButton", TopBar)
    b.Size             = UDim2.fromOffset(28, 28)
    b.Position         = UDim2.new(1, xOff, .5, -14)
    b.Text             = txt
    b.Font             = Enum.Font.GothamBold
    b.TextScaled       = true
    b.BackgroundColor3 = bg
    b.TextColor3       = Color3.new(1,1,1)
    b.BorderSizePixel  = 0
    b.AutoButtonColor  = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end
local MinBtn   = TopBtn(-64, "–", C.bg3)
local CloseBtn = TopBtn(-32, "✕", C.red)

-- Expõe pra quem precisar mudar o título
function Module:SetTitle(txt)
    TitleLbl.Text = txt
end

----------------------------------------------------------------
-- ÁREA DE SCROLL
----------------------------------------------------------------
local Content = Instance.new("Frame", F1)
Content.Size              = UDim2.new(1, -24, 1, -54)
Content.Position          = UDim2.fromOffset(12, 50)
Content.BackgroundTransparency = 1

local Scroll = Instance.new("ScrollingFrame", Content)
Scroll.Size                 = UDim2.new(1, 0, 1, 0)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel      = 0
Scroll.ScrollBarThickness   = 5
Scroll.ScrollBarImageColor3 = C.accent
Scroll.CanvasSize           = UDim2.new(0,0,0,0)

local List = Instance.new("UIListLayout", Scroll)
List.Padding   = UDim.new(0, 8)
List.SortOrder = Enum.SortOrder.LayoutOrder

local Pad = Instance.new("UIPadding", Scroll)
Pad.PaddingTop    = UDim.new(0, 4)
Pad.PaddingBottom = UDim.new(0, 4)

local function UpdateCanvas()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 12)
end
List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

-- Apaga widgets do scroll (mantém layout e padding)
function Module:Clear()
    for _, v in ipairs(Scroll:GetChildren()) do
        if not v:IsA("UIListLayout") and not v:IsA("UIPadding") then
            v:Destroy()
        end
    end
end

----------------------------------------------------------------
-- DRAG
----------------------------------------------------------------
local dragging, dragStart, startPos = false, nil, nil
TopBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = i.Position
        startPos  = F1.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        F1.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
        AlignSidebar()
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

----------------------------------------------------------------
-- SHOW / HIDE
----------------------------------------------------------------
function Module:ShowHub()
    F1.Visible = true; F2.Visible = true
    F1.Size = UDim2.fromOffset(660, 400)
    TweenService:Create(F1,
        TweenInfo.new(.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(700, 430)}):Play()
    AlignSidebar()
end

function Module:HideHub(callback)
    local t = TweenService:Create(F1,
        TweenInfo.new(.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.fromOffset(660, 400)})
    t:Play()
    t.Completed:Connect(function()
        F1.Visible = false; F2.Visible = false
        F1.Size = UDim2.fromOffset(700, 430)
        if callback then callback() end
    end)
end

----------------------------------------------------------------
-- WIDGETS PÚBLICOS
----------------------------------------------------------------

-- SEPARADOR
function Module:Sep(label)
    local f = Instance.new("Frame", Scroll)
    f.Size                = UDim2.new(1, 0, 0, 24)
    f.BackgroundTransparency = 1
    f.BorderSizePixel     = 0
    local line = Instance.new("Frame", f)
    line.Size             = UDim2.new(1, 0, 0, 1)
    line.Position         = UDim2.new(0, 0, .5, 0)
    line.BackgroundColor3 = C.bg3
    line.BorderSizePixel  = 0
    if label and label ~= "" then
        local t = Instance.new("TextLabel", f)
        t.Size             = UDim2.new(0, 140, 1, 0)
        t.Position         = UDim2.new(.5, -70, 0, 0)
        t.BackgroundColor3 = C.bg1
        t.BorderSizePixel  = 0
        t.Text             = "  " .. label .. "  "
        t.Font             = Enum.Font.GothamBold
        t.TextScaled       = true
        t.TextColor3       = C.textDim
    end
    UpdateCanvas()
    return f
end

-- INFO
function Module:Info(txt)
    local l = Instance.new("TextLabel", Scroll)
    l.Size                = UDim2.new(1, 0, 0, 20)
    l.BackgroundTransparency = 1
    l.Text                = txt
    l.Font                = Enum.Font.Gotham
    l.TextScaled          = true
    l.TextColor3          = C.textDim
    l.TextXAlignment      = Enum.TextXAlignment.Left
    UpdateCanvas()
    return l
end

-- BOTÃO
function Module:Btn(txt, color, callback)
    local b = Instance.new("TextButton", Scroll)
    b.Size             = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = color or C.accent
    b.BorderSizePixel  = 0
    b.Text             = txt
    b.Font             = Enum.Font.GothamBold
    b.TextScaled       = true
    b.TextColor3       = Color3.new(1,1,1)
    b.AutoButtonColor  = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(.1), {BackgroundTransparency=.2}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(.1), {BackgroundTransparency=0}):Play() end)
    b.MouseButton1Click:Connect(callback)
    UpdateCanvas()
    return b
end

-- SLIDER
function Module:Slider(name, min, max, default, callback)
    if min < 1 then min = 1 end
    local frame = Instance.new("Frame", Scroll)
    frame.Size                = UDim2.new(1, 0, 0, 56)
    frame.BackgroundColor3    = C.bg3
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel     = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size              = UDim2.new(1, -12, 0, 22)
    lbl.Position          = UDim2.fromOffset(10, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text              = name .. " : " .. default
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextScaled        = true
    lbl.TextColor3        = C.text
    lbl.TextXAlignment    = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", frame)
    track.Size             = UDim2.new(1, -20, 0, 6)
    track.Position         = UDim2.new(0, 10, 0, 36)
    track.BackgroundColor3 = C.bg1
    track.BorderSizePixel  = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.fromScale((default - min) / (max - min), 1)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame", track)
    knob.Size             = UDim2.fromOffset(16, 16)
    knob.AnchorPoint      = Vector2.new(.5, .5)
    knob.Position         = UDim2.fromScale(fill.Size.X.Scale, .5)
    knob.BackgroundColor3 = C.accent2
    knob.BorderSizePixel  = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    local held = false
    local function update(px)
        local pct = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size     = UDim2.fromScale(pct, 1)
        knob.Position = UDim2.fromScale(pct, .5)
        local v = math.floor(min + (max - min) * pct)
        lbl.Text = name .. " : " .. v
        callback(v)
    end
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then held=true; update(i.Position.X) end end)
    knob.InputBegan:Connect(function(i)  if i.UserInputType==Enum.UserInputType.MouseButton1 then held=true end end)
    UIS.InputEnded:Connect(function(i)   if i.UserInputType==Enum.UserInputType.MouseButton1 then held=false end end)
    UIS.InputChanged:Connect(function(i)
        if held and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    UpdateCanvas()
    return frame
end

-- TOGGLE (switch animado)
-- retorna frame, api  →  api.SetState(bool)  api.GetState()
function Module:Toggle(name, default, callback)
    local frame = Instance.new("Frame", Scroll)
    frame.Size                = UDim2.new(1, 0, 0, 42)
    frame.BackgroundColor3    = C.bg3
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel     = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size              = UDim2.new(1, -70, 1, 0)
    lbl.Position          = UDim2.fromOffset(12, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text              = name
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextScaled        = true
    lbl.TextColor3        = C.text
    lbl.TextXAlignment    = Enum.TextXAlignment.Left

    local sw = Instance.new("Frame", frame)
    sw.Size             = UDim2.fromOffset(44, 24)
    sw.Position         = UDim2.new(1, -54, .5, -12)
    sw.BackgroundColor3 = default and C.accent or C.bg1
    sw.BorderSizePixel  = 0
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)

    local ball = Instance.new("Frame", sw)
    ball.Size             = UDim2.fromOffset(18,18)
    ball.Position         = default and UDim2.new(1,-21,.5,-9) or UDim2.new(0,3,.5,-9)
    ball.BackgroundColor3 = Color3.new(1,1,1)
    ball.BorderSizePixel  = 0
    Instance.new("UICorner", ball).CornerRadius = UDim.new(1,0)

    local state = default
    local api   = {}

    local function SetState(v)
        state = v
        TweenService:Create(sw,   TweenInfo.new(.18), {BackgroundColor3 = v and C.accent or C.bg1}):Play()
        TweenService:Create(ball, TweenInfo.new(.18), {Position = v and UDim2.new(1,-21,.5,-9) or UDim2.new(0,3,.5,-9)}):Play()
    end
    function api:SetState(v) SetState(v) end
    function api:GetState()  return state end

    local btn = Instance.new("TextButton", frame)
    btn.Size             = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.MouseButton1Click:Connect(function()
        SetState(not state)
        callback(state)
    end)

    UpdateCanvas()
    return frame, api
end

----------------------------------------------------------------
-- SIDEBAR — ABAS
----------------------------------------------------------------
local SideList = Instance.new("UIListLayout", F2)
SideList.Padding   = UDim.new(0, 6)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
local SidePad = Instance.new("UIPadding", F2)
SidePad.PaddingTop   = UDim.new(0, 10)
SidePad.PaddingLeft  = UDim.new(0, 8)
SidePad.PaddingRight = UDim.new(0, 8)

local activeTab = nil

-- Hub:Tab("Nome", "emoji", callback)
-- O callback é chamado toda vez que a aba é clicada.
-- É responsabilidade do callback chamar Hub:Clear() e popular o scroll.
function Module:Tab(name, emoji, callback)
    local b = Instance.new("TextButton", F2)
    b.Size             = UDim2.new(1, 0, 0, 38)
    b.BackgroundColor3 = C.bg3
    b.BackgroundTransparency = 0.5
    b.BorderSizePixel  = 0
    b.Text             = emoji .. "  " .. name
    b.Font             = Enum.Font.GothamBold
    b.TextScaled       = true
    b.TextColor3       = C.textDim
    b.TextXAlignment   = Enum.TextXAlignment.Left
    b.AutoButtonColor  = false
    local p = Instance.new("UIPadding", b); p.PaddingLeft = UDim.new(0,10)
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

    local accent = Instance.new("Frame", b)
    accent.Size             = UDim2.fromOffset(3, 20)
    accent.Position         = UDim2.new(0,-10,.5,-10)
    accent.BackgroundColor3 = C.accent
    accent.BorderSizePixel  = 0
    accent.Visible          = false
    Instance.new("UICorner", accent)

    b.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.btn.BackgroundTransparency = 0.5
            activeTab.btn.TextColor3 = C.textDim
            activeTab.acc.Visible    = false
        end
        b.BackgroundTransparency = 0.1
        b.TextColor3             = C.text
        accent.Visible           = true
        activeTab = {btn = b, acc = accent}
        callback()
    end)

    return b  -- retorna o botão pra quem quiser disparar .MouseButton1Click manualmente
end

-- Ativa a primeira aba automaticamente (chame depois de registrar todas)
function Module:ActivateFirst()
    local first = F2:FindFirstChildWhichIsA("TextButton")
    if first then
        task.defer(function() first.MouseButton1Click:Fire() end)
    end
end

----------------------------------------------------------------
-- MINIMIZE
----------------------------------------------------------------
local mini = false
local Bubble = nil

MinBtn.MouseButton1Click:Connect(function()
    if mini then return end
    mini = true
    Module:HideHub(function()
        Bubble = Instance.new("TextButton", Hub)
        Bubble.AnchorPoint      = Vector2.new(.5,.5)
        Bubble.Position         = UDim2.new(.9, 0, .9, 0)
        Bubble.Size             = UDim2.fromOffset(0, 0)
        Bubble.Text             = "N3"
        Bubble.Font             = Enum.Font.GothamBold
        Bubble.TextScaled       = true
        Bubble.TextColor3       = Color3.new(1,1,1)
        Bubble.BackgroundColor3 = C.accent
        Bubble.AutoButtonColor  = false
        Bubble.BorderSizePixel  = 0
        Bubble.ZIndex           = 15
        Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1,0)
        TweenService:Create(Bubble, TweenInfo.new(.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.fromOffset(58,58)}):Play()
        Bubble.MouseButton1Click:Connect(function()
            TweenService:Create(Bubble, TweenInfo.new(.15), {Size=UDim2.fromOffset(0,0)}):Play()
            task.delay(.15, function()
                Bubble:Destroy(); Bubble=nil; mini=false
                Module:ShowHub()
            end)
        end)
    end)
end)

----------------------------------------------------------------
-- FECHAR
----------------------------------------------------------------
CloseBtn.MouseButton1Click:Connect(function()
    local ov = Instance.new("Frame", Hub)
    ov.Size               = UDim2.fromScale(1,1)
    ov.BackgroundColor3   = Color3.new(0,0,0)
    ov.BackgroundTransparency = 1
    ov.ZIndex             = 20
    TweenService:Create(ov, TweenInfo.new(.2), {BackgroundTransparency=.5}):Play()

    local pop = Instance.new("Frame", ov)
    pop.Size       = UDim2.fromOffset(0,0)
    pop.Position   = UDim2.fromScale(.5,.5)
    pop.AnchorPoint = Vector2.new(.5,.5)
    pop.BackgroundColor3 = C.bg2
    pop.ZIndex     = 21
    pop.BorderSizePixel = 0
    Instance.new("UICorner", pop)
    Instance.new("UIStroke", pop).Color = C.accent
    TweenService:Create(pop, TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.fromOffset(300,140)}):Play()

    local tx = Instance.new("TextLabel", pop)
    tx.Size   = UDim2.new(1,-16,1,-54); tx.Position = UDim2.fromOffset(8,8)
    tx.BackgroundTransparency=1; tx.TextWrapped=true; tx.TextScaled=true
    tx.Font=Enum.Font.GothamBold; tx.TextColor3=C.text; tx.ZIndex=22
    tx.Text = "Fechar o N3on Hub?\nVocê vai precisar re-executar o script."

    local function PopBtn(txt, clr, xp)
        local b = Instance.new("TextButton", pop)
        b.Size             = UDim2.fromOffset(110, 30)
        b.Position         = UDim2.new(xp, -55, 1, -38)
        b.Text             = txt
        b.Font             = Enum.Font.GothamBold
        b.TextScaled       = true
        b.BackgroundColor3 = clr
        b.TextColor3       = Color3.new(1,1,1)
        b.BorderSizePixel  = 0
        b.ZIndex           = 22
        Instance.new("UICorner", b)
        return b
    end
    local yes = PopBtn("✅ Sim", C.red,   .3)
    local no  = PopBtn("❌ Não", C.green, .7)

    yes.MouseButton1Click:Connect(function()
        ov:Destroy()
        Module:HideHub(function() Hub:Destroy() end)
    end)
    no.MouseButton1Click:Connect(function()
        TweenService:Create(ov,  TweenInfo.new(.15), {BackgroundTransparency=1}):Play()
        local t = TweenService:Create(pop, TweenInfo.new(.12), {Size=UDim2.fromOffset(0,0)})
        t:Play(); t.Completed:Connect(function() ov:Destroy() end)
    end)
end)

----------------------------------------------------------------
-- REFERÊNCIAS PÚBLICAS (somente leitura)
----------------------------------------------------------------
Module.Hub    = Hub
Module.F1     = F1
Module.F2     = F2
Module.Scroll = Scroll

----------------------------------------------------------------
-- ABRE AO CARREGAR
----------------------------------------------------------------
Module:ShowHub()

print("[N3on Hub Module] ✓ Pronto!")

return Module
