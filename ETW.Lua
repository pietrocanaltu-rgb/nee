-- ╔══════════════════════════════════════════════╗
-- ║   N3on Hub - Eat The World Module v3        ║
-- ║   Event-Based + Smart Sell (ProgressBar)    ║
-- ╚══════════════════════════════════════════════╝

if not _G.N3onHub then
    warn("[ETW Module] Base hub not loaded! Execute o Base primeiro.")
    return
end

local Player       = game.Players.LocalPlayer
local PlayerGui    = Player:WaitForChild("PlayerGui")
local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

print("[ETW Module v3] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------
_G.N3onHub.SavedStates = _G.N3onHub.SavedStates or {}

-- Auto Grab
_G.N3onHub.SavedStates.grabActive     = false
_G.N3onHub.SavedStates.grabInterval   = 500

-- Auto Eat
_G.N3onHub.SavedStates.eatActive      = false
_G.N3onHub.SavedStates.eatInterval    = 500

-- Auto Throw
_G.N3onHub.SavedStates.throwActive    = false
_G.N3onHub.SavedStates.throwInterval  = 500

-- Auto Sell (normal, com timer)
_G.N3onHub.SavedStates.sellActive     = false
_G.N3onHub.SavedStates.sellInterval   = 12000

-- Smart Sell (detecta ProgressBar cheia)
_G.N3onHub.SavedStates.smartSellActive = false
_G.N3onHub.SavedStates.smartSellThreshold = 0.95  -- 95% do tamanho = cheio

-- Walk
_G.N3onHub.SavedStates.walkActive     = false

-- Teleport
_G.N3onHub.SavedStates.teleActive     = false
_G.N3onHub.SavedStates.teleInterval   = 6
_G.N3onHub.SavedStates.teleRadius     = 2048

-- Misc
_G.N3onHub.SavedStates.antiKnock      = false
_G.N3onHub.SavedStates.noclip         = false
_G.N3onHub.SavedStates.infjump        = false

----------------------------------------------------------------
-- FLAGS
----------------------------------------------------------------
local grabActive    = false
local eatActive     = false
local throwActive   = false
local sellActive    = false
local smartSellActive = false
local walkActive    = false
local teleActive    = false
local antiKnock     = false
local noclip        = false
local infjump       = false

local grabGen   = 0
local eatGen    = 0
local throwGen  = 0
local sellGen   = 0
local walkGen   = 0
local teleGen   = 0

local smartSellConn = nil
local lastSmartSell = 0  -- cooldown entre sells

----------------------------------------------------------------
-- HELPERS - Eventos
----------------------------------------------------------------
local function GetEvents()
    local char = Player.Character
    if not char then return nil end
    local events = char:FindFirstChild("Events")
    return events
end

local function FireEvent(eventName)
    local events = GetEvents()
    if not events then return false end
    local event = events:FindFirstChild(eventName)
    if not event then return false end
    
    pcall(function()
        if event:IsA("RemoteEvent") then
            event:FireServer()
        elseif event:IsA("RemoteFunction") then
            event:InvokeServer()
        elseif event:IsA("BindableEvent") then
            event:Fire()
        elseif event:IsA("BindableFunction") then
            event:Invoke()
        end
    end)
    return true
end

----------------------------------------------------------------
-- HELPERS - Movimento
----------------------------------------------------------------
local function GetHRP()
    local c = Player.Character; return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local c = Player.Character; return c and c:FindFirstChild("Humanoid")
end

local function FindGround(origin)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    if Player.Character then rp.FilterDescendantsInstances = {Player.Character} end
    local hit = workspace:Raycast(origin, Vector3.new(0,-800,0), rp)
    return hit and (hit.Position + Vector3.new(0,3.5,0)) or nil
end

local function RandomWalkablePos(origin, radius)
    for _ = 1, 20 do
        local ang  = math.random()*2*math.pi
        local dist = math.random(10, radius)
        local land = FindGround(Vector3.new(
            origin.X + math.cos(ang)*dist,
            origin.Y + 600,
            origin.Z + math.sin(ang)*dist
        ))
        if land then return land end
    end
    return nil
end

local function CastCheck(origin, dir, dist)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    if Player.Character then rp.FilterDescendantsInstances = {Player.Character} end
    return workspace:Raycast(origin, dir * dist, rp)
end

local function FindWalkTarget(hrp)
    local origin = hrp.Position
    for _ = 1, 16 do
        local ang      = math.random()*2*math.pi
        local stepDist = math.random(8, 32)
        local dir      = Vector3.new(math.cos(ang), 0, math.sin(ang))
        if CastCheck(origin + Vector3.new(0,1.2,0), dir, stepDist) then continue end
        local destXZ    = origin + dir * stepDist
        local groundHit = CastCheck(
            Vector3.new(destXZ.X, origin.Y+60, destXZ.Z),
            Vector3.new(0,-1,0), 200
        )
        if not groundHit then continue end
        if groundHit.Position.Y - origin.Y > 12 then continue end
        return groundHit.Position + Vector3.new(0, 3.2, 0)
    end
    return RandomWalkablePos(origin, 60)
end

----------------------------------------------------------------
-- SMART SELL - Detecta ProgressBar
----------------------------------------------------------------
local function FindSellProgressBar()
    -- Procura em PlayerGui.ScreenGui.Sell.ProgressBar
    local screenGui = PlayerGui:FindFirstChild("ScreenGui")
    if not screenGui then return nil end
    
    local sellFrame = screenGui:FindFirstChild("Sell")
    if not sellFrame then return nil end
    
    local progressBar = sellFrame:FindFirstChild("ProgressBar")
    if not progressBar then return nil end
    
    return progressBar, sellFrame
end

local function StartSmartSell()
    if smartSellConn then smartSellConn:Disconnect() end
    
    smartSellConn = RunService.RenderStepped:Connect(function()
        if not smartSellActive then return end
        
        local progressBar, sellFrame = FindSellProgressBar()
        if not progressBar or not sellFrame then return end
        
        -- Verifica se a ProgressBar está quase do tamanho do frame Sell
        local barSize = progressBar.AbsoluteSize.X
        local frameSize = sellFrame.AbsoluteSize.X
        
        if frameSize <= 0 then return end
        
        local ratio = barSize / frameSize
        
        -- Se atingiu o threshold, vende
        if ratio >= _G.N3onHub.SavedStates.smartSellThreshold then
            local now = tick()
            -- Cooldown de 1.5s entre sells pra evitar spam
            if now - lastSmartSell > 1.5 then
                lastSmartSell = now
                FireEvent("Sell")
            end
        end
    end)
end

local function StopSmartSell()
    if smartSellConn then
        smartSellConn:Disconnect()
        smartSellConn = nil
    end
end

----------------------------------------------------------------
-- NOCLIP / INF JUMP / ANTI KNOCK
----------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    if not noclip or not Player.Character then return end
    for _, p in ipairs(Player.Character:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

UIS.JumpRequest:Connect(function()
    if infjump then
        local h = GetHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    if not antiKnock then return end
    local hrp = GetHRP()
    if hrp then pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
    end) end
end)

----------------------------------------------------------------
-- AUTO GRAB LOOP
----------------------------------------------------------------
local function StartGrabLoop()
    grabGen += 1; local myGen = grabGen
    task.spawn(function()
        while grabActive and grabGen == myGen do
            FireEvent("Grab")
            task.wait(math.max(0.05, _G.N3onHub.SavedStates.grabInterval/1000))
        end
    end)
end
local function StopGrabLoop() grabActive = false; grabGen += 1 end

----------------------------------------------------------------
-- AUTO EAT LOOP
----------------------------------------------------------------
local function StartEatLoop()
    eatGen += 1; local myGen = eatGen
    task.spawn(function()
        while eatActive and eatGen == myGen do
            FireEvent("Eat")
            task.wait(math.max(0.05, _G.N3onHub.SavedStates.eatInterval/1000))
        end
    end)
end
local function StopEatLoop() eatActive = false; eatGen += 1 end

----------------------------------------------------------------
-- AUTO THROW LOOP
----------------------------------------------------------------
local function StartThrowLoop()
    throwGen += 1; local myGen = throwGen
    task.spawn(function()
        while throwActive and throwGen == myGen do
            FireEvent("Throw")
            task.wait(math.max(0.05, _G.N3onHub.SavedStates.throwInterval/1000))
        end
    end)
end
local function StopThrowLoop() throwActive = false; throwGen += 1 end

----------------------------------------------------------------
-- AUTO SELL LOOP (com timer)
----------------------------------------------------------------
local function StartSellLoop()
    sellGen += 1; local myGen = sellGen
    task.spawn(function()
        while sellActive and sellGen == myGen do
            FireEvent("Sell")
            task.wait(math.max(0.05, _G.N3onHub.SavedStates.sellInterval/1000))
        end
    end)
end
local function StopSellLoop() sellActive = false; sellGen += 1 end

----------------------------------------------------------------
-- WALK LOOP
----------------------------------------------------------------
local function StartWalkLoop()
    walkGen += 1; local myGen = walkGen
    task.spawn(function()
        while walkActive and walkGen == myGen do
            local hrp = GetHRP(); local hum = GetHum()
            if hrp and hum and hum.Health > 0 then
                local target = FindWalkTarget(hrp)
                if target then
                    hum:MoveTo(target)
                    local t0 = tick()
                    repeat task.wait(0.08)
                        local h = GetHRP()
                        if h and (h.Position - target).Magnitude < 4 then break end
                    until tick()-t0 > 2.5 or not walkActive or walkGen ~= myGen
                    task.wait(math.random(20,60)/100)
                else
                    task.wait(0.5)
                end
            else
                task.wait(0.3)
            end
        end
        local hum = GetHum(); local hrp = GetHRP()
        if hum and hrp then hum:MoveTo(hrp.Position) end
    end)
end

local function StopWalkLoop()
    walkActive = false; walkGen += 1
    local hum = GetHum(); local hrp = GetHRP()
    if hum and hrp then hum:MoveTo(hrp.Position) end
end

----------------------------------------------------------------
-- TELE LOOP
----------------------------------------------------------------
local function StartTeleLoop()
    teleGen += 1; local myGen = teleGen
    task.spawn(function()
        while teleActive and teleGen == myGen do
            task.wait(_G.N3onHub.SavedStates.teleInterval)
            if not teleActive or teleGen ~= myGen then break end
            local hrp = GetHRP()
            if hrp then
                local dest = RandomWalkablePos(hrp.Position, _G.N3onHub.SavedStates.teleRadius)
                if dest then hrp.CFrame = CFrame.new(dest) end
            end
        end
    end)
end
local function StopTeleLoop() teleActive = false; teleGen += 1 end

----------------------------------------------------------------
-- KEYBINDS
----------------------------------------------------------------
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.G then
        grabActive = not grabActive
        _G.N3onHub.SavedStates.grabActive = grabActive
        if grabActive then StartGrabLoop() else StopGrabLoop() end
    elseif input.KeyCode == Enum.KeyCode.E then
        eatActive = not eatActive
        _G.N3onHub.SavedStates.eatActive = eatActive
        if eatActive then StartEatLoop() else StopEatLoop() end
    elseif input.KeyCode == Enum.KeyCode.T then
        throwActive = not throwActive
        _G.N3onHub.SavedStates.throwActive = throwActive
        if throwActive then StartThrowLoop() else StopThrowLoop() end
    elseif input.KeyCode == Enum.KeyCode.V then
        -- Alterna entre Smart Sell e Sell normal
        if smartSellActive then
            -- Desativa Smart Sell, ativa Sell normal
            smartSellActive = false
            _G.N3onHub.SavedStates.smartSellActive = false
            StopSmartSell()
            sellActive = true
            _G.N3onHub.SavedStates.sellActive = true
            StartSellLoop()
        else
            sellActive = not sellActive
            _G.N3onHub.SavedStates.sellActive = sellActive
            if sellActive then StartSellLoop() else StopSellLoop() end
        end
    end
end)

----------------------------------------------------------------
-- STATUS BAR
----------------------------------------------------------------
local sellModeText = "Sell"

local statusLbl = Instance.new("TextLabel", _G.N3onHub.GUI.Hub)
statusLbl.Size               = UDim2.fromOffset(500, 26)
statusLbl.Position           = UDim2.new(0, 10, 1, -38)
statusLbl.BackgroundColor3   = Color3.fromRGB(28, 10, 50)
statusLbl.BackgroundTransparency = 0.1
statusLbl.BorderSizePixel    = 0
statusLbl.TextColor3         = Color3.fromRGB(230, 210, 255)
statusLbl.Font               = Enum.Font.GothamBold
statusLbl.TextScaled         = true
statusLbl.TextXAlignment     = Enum.TextXAlignment.Left
statusLbl.ZIndex             = 20
Instance.new("UICorner", statusLbl).CornerRadius = UDim.new(0,8)
local slp = Instance.new("UIPadding", statusLbl); slp.PaddingLeft = UDim.new(0,8)

RunService.Heartbeat:Connect(function()
    if not statusLbl or not statusLbl.Parent then return end
    
    local sellIcon = "⏹"
    local sellLabel = "Sell"
    
    if smartSellActive then
        sellIcon = "🧠"
        sellLabel = "SmartSell"
    elseif sellActive then
        sellIcon = "✅"
        sellLabel = "Sell"
    end
    
    statusLbl.Text = (grabActive and "✅" or "⏹").." Grab [G]  "
        .. (eatActive and "✅" or "⏹").." Eat [E]  "
        .. (throwActive and "✅" or "⏹").." Throw [T]  "
        .. sellIcon.." "..sellLabel.." [V]  "
        .. (walkActive and "✅" or "⏹").." Walk"
end)

----------------------------------------------------------------
-- TAB: AUTO FARM
----------------------------------------------------------------
local function LoadFarmTab()
    _G.N3onHub.GUI.Clear()
    local SC = _G.N3onHub.GUI.ScrollContent

    -- SEP helper local
    local function Sep(label)
        local f = Instance.new("Frame", SC)
        f.Size = UDim2.new(1,0,0,24); f.BackgroundTransparency = 1; f.BorderSizePixel = 0
        local line = Instance.new("Frame", f)
        line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,.5,0)
        line.BackgroundColor3 = Color3.fromRGB(45, 18, 75); line.BorderSizePixel = 0
        if label and label ~= "" then
            local t = Instance.new("TextLabel", f)
            t.Size = UDim2.new(0,150,1,0); t.Position = UDim2.new(.5,-75,0,0)
            t.BackgroundColor3 = Color3.fromRGB(18, 6, 35); t.BorderSizePixel = 0
            t.Text = "  "..label.."  "; t.Font = Enum.Font.GothamBold
            t.TextScaled = true; t.TextColor3 = Color3.fromRGB(160, 130, 200)
        end
        _G.N3onHub.GUI.UpdateCanvasSize()
    end

    local function Info(txt)
        local l = Instance.new("TextLabel", SC)
        l.Size = UDim2.new(1,0,0,20); l.BackgroundTransparency = 1
        l.Text = txt; l.Font = Enum.Font.Gotham; l.TextScaled = true
        l.TextColor3 = Color3.fromRGB(160, 130, 200); l.TextXAlignment = Enum.TextXAlignment.Left
        _G.N3onHub.GUI.UpdateCanvasSize()
    end

    -- AUTO GRAB
    Sep("🖐️  AUTO GRAB")
    Info("  Envia evento 'Grab' | Tecla [G]")
    
    _G.N3onHub.Checkbox("Auto Grab", _G.N3onHub.SavedStates.grabActive, function(v)
        _G.N3onHub.SavedStates.grabActive = v
        grabActive = v
        if v then StartGrabLoop() else StopGrabLoop() end
    end)
    
    _G.N3onHub.Slider("Intervalo Grab (ms)", 100, 3000, _G.N3onHub.SavedStates.grabInterval, function(v)
        _G.N3onHub.SavedStates.grabInterval = v
    end)

    -- AUTO EAT
    Sep("🍽️  AUTO EAT")
    Info("  Envia evento 'Eat' | Tecla [E]")
    
    _G.N3onHub.Checkbox("Auto Eat", _G.N3onHub.SavedStates.eatActive, function(v)
        _G.N3onHub.SavedStates.eatActive = v
        eatActive = v
        if v then StartEatLoop() else StopEatLoop() end
    end)
    
    _G.N3onHub.Slider("Intervalo Eat (ms)", 100, 3000, _G.N3onHub.SavedStates.eatInterval, function(v)
        _G.N3onHub.SavedStates.eatInterval = v
    end)

    -- AUTO THROW
    Sep("🗑️  AUTO THROW")
    Info("  Envia evento 'Throw' | Tecla [T]")
    
    _G.N3onHub.Checkbox("Auto Throw", _G.N3onHub.SavedStates.throwActive, function(v)
        _G.N3onHub.SavedStates.throwActive = v
        throwActive = v
        if v then StartThrowLoop() else StopThrowLoop() end
    end)
    
    _G.N3onHub.Slider("Intervalo Throw (ms)", 100, 3000, _G.N3onHub.SavedStates.throwInterval, function(v)
        _G.N3onHub.SavedStates.throwInterval = v
    end)

    -- AUTO SELL (NORMAL)
    Sep("💰  AUTO SELL (TIMER)")
    Info("  Envia evento 'Sell' a cada X ms | Tecla [V]")
    
    _G.N3onHub.Checkbox("Auto Sell (Timer)", _G.N3onHub.SavedStates.sellActive, function(v)
        _G.N3onHub.SavedStates.sellActive = v
        sellActive = v
        if v then
            -- Desativa Smart Sell se ativo
            if smartSellActive then
                smartSellActive = false
                _G.N3onHub.SavedStates.smartSellActive = false
                StopSmartSell()
            end
            StartSellLoop()
        else
            StopSellLoop()
        end
    end)
    
    _G.N3onHub.Slider("Intervalo Sell (ms)", 1000, 60000, _G.N3onHub.SavedStates.sellInterval, function(v)
        _G.N3onHub.SavedStates.sellInterval = v
    end)

    -- SMART SELL
    Sep("🧠  SMART SELL (ProgressBar)")
    Info("  Detecta PlayerGui.ScreenGui.Sell.ProgressBar")
    Info("  Vende automaticamente quando a barra enche")
    
    _G.N3onHub.Checkbox("Smart Sell", _G.N3onHub.SavedStates.smartSellActive, function(v)
        _G.N3onHub.SavedStates.smartSellActive = v
        smartSellActive = v
        if v then
            -- Desativa Sell normal se ativo
            if sellActive then
                sellActive = false
                _G.N3onHub.SavedStates.sellActive = false
                StopSellLoop()
            end
            StartSmartSell()
        else
            StopSmartSell()
        end
    end)
    
    _G.N3onHub.Slider("Threshold (%)", 50, 100, _G.N3onHub.SavedStates.smartSellThreshold * 100, function(v)
        _G.N3onHub.SavedStates.smartSellThreshold = v / 100
    end)

    -- WALK
    Sep("🚶  AUTO WALK ALEATÓRIO")
    Info("  Raycast avançado: evita paredes e buracos")
    
    _G.N3onHub.Checkbox("Auto Walk", _G.N3onHub.SavedStates.walkActive, function(v)
        _G.N3onHub.SavedStates.walkActive = v
        walkActive = v
        if v then StartWalkLoop() else StopWalkLoop() end
    end)

    -- TELEPORT
    Sep("🌀  AUTO TELEPORT")
    Info("  Busca chão via raycast")
    
    _G.N3onHub.Checkbox("Auto Teleport", _G.N3onHub.SavedStates.teleActive, function(v)
        _G.N3onHub.SavedStates.teleActive = v
        teleActive = v
        if v then StartTeleLoop() else StopTeleLoop() end
    end)
    
    _G.N3onHub.Slider("Intervalo Tele (s)", 1, 120, _G.N3onHub.SavedStates.teleInterval, function(v)
        _G.N3onHub.SavedStates.teleInterval = v
    end)
    _G.N3onHub.Slider("Raio Tele (studs)", 50, 4096, _G.N3onHub.SavedStates.teleRadius, function(v)
        _G.N3onHub.SavedStates.teleRadius = v
    end)
end

----------------------------------------------------------------
-- TAB: MISC
----------------------------------------------------------------
local function LoadMiscTab()
    _G.N3onHub.GUI.Clear()
    local SC = _G.N3onHub.GUI.ScrollContent

    local function Sep(label)
        local f = Instance.new("Frame", SC)
        f.Size = UDim2.new(1,0,0,24); f.BackgroundTransparency = 1; f.BorderSizePixel = 0
        local line = Instance.new("Frame", f)
        line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,.5,0)
        line.BackgroundColor3 = Color3.fromRGB(45, 18, 75); line.BorderSizePixel = 0
        if label and label ~= "" then
            local t = Instance.new("TextLabel", f)
            t.Size = UDim2.new(0,150,1,0); t.Position = UDim2.new(.5,-75,0,0)
            t.BackgroundColor3 = Color3.fromRGB(18, 6, 35); t.BorderSizePixel = 0
            t.Text = "  "..label.."  "; t.Font = Enum.Font.GothamBold
            t.TextScaled = true; t.TextColor3 = Color3.fromRGB(160, 130, 200)
        end
        _G.N3onHub.GUI.UpdateCanvasSize()
    end

    local function Info(txt)
        local l = Instance.new("TextLabel", SC)
        l.Size = UDim2.new(1,0,0,20); l.BackgroundTransparency = 1
        l.Text = txt; l.Font = Enum.Font.Gotham; l.TextScaled = true
        l.TextColor3 = Color3.fromRGB(160, 130, 200); l.TextXAlignment = Enum.TextXAlignment.Left
        _G.N3onHub.GUI.UpdateCanvasSize()
    end

    local function Btn(txt, color, callback)
        local b = Instance.new("TextButton", SC)
        b.Size = UDim2.new(1,0,0,36); b.BackgroundColor3 = color or Color3.fromRGB(140, 0, 255)
        b.BorderSizePixel = 0; b.Text = txt; b.Font = Enum.Font.GothamBold
        b.TextScaled = true; b.TextColor3 = Color3.new(1,1,1); b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
        b.MouseButton1Click:Connect(callback)
        _G.N3onHub.GUI.UpdateCanvasSize()
    end

    Sep("🛡️  UTILIDADES")
    _G.N3onHub.Checkbox("Noclip", _G.N3onHub.SavedStates.noclip, function(v)
        _G.N3onHub.SavedStates.noclip = v; noclip = v
    end)
    _G.N3onHub.Checkbox("Infinite Jump", _G.N3onHub.SavedStates.infjump, function(v)
        _G.N3onHub.SavedStates.infjump = v; infjump = v
    end)
    _G.N3onHub.Checkbox("Anti Knockback", _G.N3onHub.SavedStates.antiKnock, function(v)
        _G.N3onHub.SavedStates.antiKnock = v; antiKnock = v
    end)

    Sep("🔧  AÇÕES RÁPIDAS")
    Btn("🔄 Respawn manual", Color3.fromRGB(45, 18, 75), function() Player:LoadCharacter() end)
    Btn("🏠 TP para origem (0,0,0)", Color3.fromRGB(45, 18, 75), function()
        local hrp = GetHRP()
        if hrp then
            local ground = FindGround(Vector3.new(0,600,0))
            hrp.CFrame = CFrame.new(ground or Vector3.new(0,5,0))
        end
    end)
    
    Sep("📋  TECLAS & SMART SELL")
    Info("  [G] Grab  |  [E] Eat  |  [T] Throw")
    Info("  [V] Alterna Sell / Smart Sell")
    Info("  Smart Sell: detecta ProgressBar cheia")
    Info("  Caminho: PlayerGui.ScreenGui.Sell.ProgressBar")
end

----------------------------------------------------------------
-- REGISTRAR TABS
----------------------------------------------------------------
_G.N3onHub.Tab("Auto Farm", "🌾", 0, LoadFarmTab)
_G.N3onHub.Tab("Misc",      "⚙️", 0, LoadMiscTab)

print("[ETW Module v3] ✓ Eat The World carregado!")
print("  Eventos: Grab [G] | Eat [E] | Throw [T] | Sell [V]")
print("  Smart Sell: detecta ProgressBar em PlayerGui.ScreenGui.Sell")
