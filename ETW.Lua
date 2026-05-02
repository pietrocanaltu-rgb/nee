-- ╔══════════════════════════════════════════════╗
-- ║     N3on Hub — Eat The World Module          ║
-- ╚══════════════════════════════════════════════╝
--
-- USO:
--   local Hub = require(game.ReplicatedStorage.N3onHubModule)
--   require(game.ReplicatedStorage.EatTheWorldModule)(Hub)

return function(Hub)

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local Players      = game:GetService("Players")
local Player       = Players.LocalPlayer
local C            = Hub.Colors

print("[Eat The World] Carregando...")

----------------------------------------------------------------
-- ESTADO
----------------------------------------------------------------
local ST = {
    grabActive    = false,
    grabInterval  = 500,   -- ms
    grabPos       = nil,   -- Vector2 ou nil = centro da tela

    walkActive    = false,
    walkSpeed     = 14,    -- studs/s do MoveTo

    teleActive    = false,
    teleInterval  = 6,     -- segundos
    teleRadius    = 2048,  -- studs

    sellActive    = false,
    sellInterval  = 12,    -- segundos
    sellPos       = nil,   -- Vector2 ou nil = centro

    antiKnock     = false,
    noclip        = false,
    infjump       = false,
}

-- Gerações para parar loops de forma segura (sem task.cancel)
local grabGen = 0
local walkGen = 0
local teleGen = 0
local sellGen = 0

-- APIs dos toggles (para sincronizar keybind [G])
local grabToggleAPI = nil
local walkToggleAPI = nil
local teleToggleAPI = nil

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function GetHRP()
    local c = Player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local c = Player.Character
    return c and c:FindFirstChild("Humanoid")
end

local function Click(pos)
    local vp = workspace.CurrentCamera.ViewportSize
    local px = pos and pos.X or vp.X / 2
    local py = pos and pos.Y or vp.Y / 2
    VIM:SendMouseButtonEvent(px, py, 0, true,  game, 1)
    task.wait(0.04)
    VIM:SendMouseButtonEvent(px, py, 0, false, game, 1)
end

-- Raycast para achar chão em qualquer ponto XZ
local function FindGround(origin)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    if Player.Character then
        rp.FilterDescendantsInstances = {Player.Character}
    end
    local hit = workspace:Raycast(origin, Vector3.new(0, -800, 0), rp)
    return hit and (hit.Position + Vector3.new(0, 3.5, 0)) or nil
end

-- Acha posição aleatória caminhável no raio
local function RandomWalkablePos(origin, radius)
    for _ = 1, 20 do
        local ang  = math.random() * 2 * math.pi
        local dist = math.random(10, radius)
        local testO = Vector3.new(
            origin.X + math.cos(ang) * dist,
            origin.Y + 600,
            origin.Z + math.sin(ang) * dist
        )
        local land = FindGround(testO)
        if land then return land end
    end
    return nil
end

----------------------------------------------------------------
-- NOCLIP
----------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    if not ST.noclip or not Player.Character then return end
    for _, p in ipairs(Player.Character:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- Inf Jump
UIS.JumpRequest:Connect(function()
    if ST.infjump then
        local h = GetHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti Knockback
RunService.Heartbeat:Connect(function()
    if not ST.antiKnock then return end
    local hrp = GetHRP()
    if hrp then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
        end)
    end
end)

----------------------------------------------------------------
-- AUTO GRAB LOOP
----------------------------------------------------------------
local function StartGrabLoop()
    grabGen += 1
    local myGen = grabGen
    task.spawn(function()
        while ST.grabActive and grabGen == myGen do
            Click(ST.grabPos)
            task.wait(math.max(0.05, ST.grabInterval / 1000))
        end
    end)
end

local function StopGrabLoop()
    ST.grabActive = false
    grabGen += 1
end

local function ToggleGrab(state)
    ST.grabActive = state
    if state then StartGrabLoop() else StopGrabLoop() end
    if grabToggleAPI then grabToggleAPI:SetState(state) end
end

----------------------------------------------------------------
-- AUTO WALK ALEATÓRIO COM RAYCAST AVANÇADO
----------------------------------------------------------------
local function CastWalkable(origin, dir, maxDist)
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    if Player.Character then
        rp.FilterDescendantsInstances = {Player.Character}
    end
    return workspace:Raycast(origin, dir * maxDist, rp)
end

local function FindWalkTarget(hrp)
    local origin = hrp.Position

    for _ = 1, 16 do
        local angle   = math.random() * 2 * math.pi
        local stepDist = math.random(8, 32)
        local dir      = Vector3.new(math.cos(angle), 0, math.sin(angle))

        -- 1) Checa parede horizontal
        local wallHit = CastWalkable(
            origin + Vector3.new(0, 1.2, 0),
            dir,
            stepDist
        )
        if wallHit then continue end

        -- 2) Checa chão no destino
        local destXZ  = origin + dir * stepDist
        local groundHit = CastWalkable(
            Vector3.new(destXZ.X, origin.Y + 60, destXZ.Z),
            Vector3.new(0, -1, 0),
            200
        )
        if not groundHit then continue end

        -- 3) Checa desnível aceitável (não mais que 12 studs pra cima)
        local deltaY = groundHit.Position.Y - origin.Y
        if deltaY > 12 then continue end

        return groundHit.Position + Vector3.new(0, 3.2, 0)
    end

    -- fallback: posição aleatória simples
    return RandomWalkablePos(origin, 60)
end

local function StartWalkLoop()
    walkGen += 1
    local myGen = walkGen
    task.spawn(function()
        while ST.walkActive and walkGen == myGen do
            local hrp = GetHRP()
            local hum = GetHum()
            if hrp and hum and hum.Health > 0 then
                local target = FindWalkTarget(hrp)
                if target then
                    -- Move via humanoid para usar pathfinding nativo
                    hum:MoveTo(target)

                    -- Espera chegar ou timeout (2.5s)
                    local t0 = tick()
                    local arrived = false
                    repeat
                        task.wait(0.08)
                        local h = GetHRP()
                        if h and (h.Position - target).Magnitude < 4 then
                            arrived = true
                        end
                    until arrived or tick() - t0 > 2.5
                        or not ST.walkActive or walkGen ~= myGen

                    -- Pausa curta entre destinos
                    task.wait(math.random(20, 60) / 100)
                else
                    task.wait(0.5)
                end
            else
                task.wait(0.3)
            end
        end

        -- Garante que o personagem pare quando o loop encerrar
        local hum = GetHum()
        local hrp = GetHRP()
        if hum and hrp then hum:MoveTo(hrp.Position) end
    end)
end

local function StopWalkLoop()
    ST.walkActive = false
    walkGen += 1
    local hum = GetHum()
    local hrp = GetHRP()
    if hum and hrp then hum:MoveTo(hrp.Position) end
end

----------------------------------------------------------------
-- AUTO TELEPORT LOOP
----------------------------------------------------------------
local function StartTeleLoop()
    teleGen += 1
    local myGen = teleGen
    task.spawn(function()
        while ST.teleActive and teleGen == myGen do
            task.wait(ST.teleInterval)
            if not ST.teleActive or teleGen ~= myGen then break end
            local hrp = GetHRP()
            if hrp then
                local dest = RandomWalkablePos(hrp.Position, ST.teleRadius)
                if dest then hrp.CFrame = CFrame.new(dest) end
            end
        end
    end)
end

local function StopTeleLoop()
    ST.teleActive = false
    teleGen += 1
end

----------------------------------------------------------------
-- AUTO SELL LOOP
----------------------------------------------------------------
local function StartSellLoop()
    sellGen += 1
    local myGen = sellGen
    task.spawn(function()
        while ST.sellActive and sellGen == myGen do
            task.wait(ST.sellInterval)
            if not ST.sellActive or sellGen ~= myGen then break end
            Click(ST.sellPos)
        end
    end)
end

local function StopSellLoop()
    ST.sellActive = false
    sellGen += 1
end

----------------------------------------------------------------
-- KEYBIND [G] — toggle grab
----------------------------------------------------------------
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then
        ToggleGrab(not ST.grabActive)
    end
end)

----------------------------------------------------------------
-- CAPTURA DE POSIÇÃO NA TELA
-- fecha hub → usuário clica em qualquer lugar → captura Vector2
----------------------------------------------------------------
local capConn = nil
local function CaptureScreenPos(callback)
    if capConn then capConn:Disconnect(); capConn = nil end
    capConn = UIS.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            capConn:Disconnect(); capConn = nil
            callback(Vector2.new(i.Position.X, i.Position.Y))
        elseif i.KeyCode == Enum.KeyCode.Escape then
            capConn:Disconnect(); capConn = nil
            callback(nil)
        end
    end)
end

----------------------------------------------------------------
-- STATUS BAR FLUTUANTE (sobrepõe qualquer aba)
----------------------------------------------------------------
local statusLabel = Instance.new("TextLabel", Hub.Hub)
statusLabel.Size               = UDim2.fromOffset(340, 26)
statusLabel.Position           = UDim2.new(0, 10, 1, -38)
statusLabel.BackgroundColor3   = C.bg2
statusLabel.BackgroundTransparency = 0.1
statusLabel.BorderSizePixel    = 0
statusLabel.TextColor3         = C.text
statusLabel.Font               = Enum.Font.GothamBold
statusLabel.TextScaled         = true
statusLabel.TextXAlignment     = Enum.TextXAlignment.Left
statusLabel.ZIndex             = 20
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 8)
local sp = Instance.new("UIPadding", statusLabel)
sp.PaddingLeft = UDim.new(0, 8)

RunService.Heartbeat:Connect(function()
    if not statusLabel or not statusLabel.Parent then return end
    local g = ST.grabActive  and "✅ Grab" or "⏹ Grab"
    local w = ST.walkActive  and "✅ Walk" or "⏹ Walk"
    local t = ST.teleActive  and "✅ Tele" or "⏹ Tele"
    local s = ST.sellActive  and "✅ Sell" or "⏹ Sell"
    statusLabel.Text = g .. "  " .. w .. "  " .. t .. "  " .. s .. "   [G]"
end)

----------------------------------------------------------------
-- TAB: AUTO FARM
----------------------------------------------------------------
local function LoadFarmTab()
    Hub:Clear()

    -- ── AUTO GRAB ──────────────────────────────────────────
    Hub:Sep("🖱️  AUTO GRAB")
    Hub:Info("  [G] ativa / desativa o Grab a qualquer momento")

    local _, gAPI = Hub:Toggle("Auto Grab", ST.grabActive, function(v)
        ToggleGrab(v)
    end)
    grabToggleAPI = gAPI

    Hub:Slider("Intervalo de clique (ms)", 100, 3000, ST.grabInterval, function(v)
        ST.grabInterval = v
    end)

    -- botão captura posição Grab
    local grabPosLbl = ST.grabPos
        and string.format("📍 Grab: (%.0f, %.0f)  —  Reconfigurar", ST.grabPos.X, ST.grabPos.Y)
        or  "📍 Capturar posição de Grab  (centro da tela se vazio)"

    local grabPosBtn = Hub:Btn(grabPosLbl, C.bg3, function()
        Hub:HideHub(function()
            task.wait(0.35)
            CaptureScreenPos(function(pos)
                Hub:ShowHub()
                if pos then
                    ST.grabPos = pos
                    grabPosBtn.Text = string.format("📍 Grab: (%.0f, %.0f)  —  Reconfigurar", pos.X, pos.Y)
                end
            end)
        end)
    end)

    Hub:Btn("🔄 Resetar posição Grab (→ centro)", C.bg3, function()
        ST.grabPos = nil
        grabPosBtn.Text = "📍 Capturar posição de Grab  (centro da tela se vazio)"
    end)

    -- ── AUTO WALK ──────────────────────────────────────────
    Hub:Sep("🚶  AUTO WALK ALEATÓRIO")
    Hub:Info("  Raycast avançado: evita paredes e buracos")

    local _, wAPI = Hub:Toggle("Auto Walk", ST.walkActive, function(v)
        ST.walkActive = v
        if v then StartWalkLoop() else StopWalkLoop() end
    end)
    walkToggleAPI = wAPI

    -- ── AUTO TELEPORT ──────────────────────────────────────
    Hub:Sep("🌀  AUTO TELEPORT")
    Hub:Info("  Independente do Grab · Busca chão via raycast")

    local _, tAPI = Hub:Toggle("Auto Teleport", ST.teleActive, function(v)
        ST.teleActive = v
        if v then StartTeleLoop() else StopTeleLoop() end
    end)
    teleToggleAPI = tAPI

    Hub:Slider("Intervalo entre teleports (s)", 1, 120, ST.teleInterval, function(v)
        ST.teleInterval = v
    end)
    Hub:Slider("Raio máximo (studs)", 50, 4096, ST.teleRadius, function(v)
        ST.teleRadius = v
    end)

    -- ── AUTO SELL ──────────────────────────────────────────
    Hub:Sep("💰  AUTO SELL")

    local _, sAPI = Hub:Toggle("Auto Sell", ST.sellActive, function(v)
        ST.sellActive = v
        if v then StartSellLoop() else StopSellLoop() end
    end)

    Hub:Slider("Intervalo de venda (s)", 1, 180, ST.sellInterval, function(v)
        ST.sellInterval = v
    end)

    local sellPosLbl = ST.sellPos
        and string.format("📍 Sell: (%.0f, %.0f)  —  Reconfigurar", ST.sellPos.X, ST.sellPos.Y)
        or  "📍 Capturar posição de Sell  (centro da tela se vazio)"

    local sellPosBtn = Hub:Btn(sellPosLbl, C.bg3, function()
        Hub:HideHub(function()
            task.wait(0.35)
            CaptureScreenPos(function(pos)
                Hub:ShowHub()
                if pos then
                    ST.sellPos = pos
                    sellPosBtn.Text = string.format("📍 Sell: (%.0f, %.0f)  —  Reconfigurar", pos.X, pos.Y)
                end
            end)
        end)
    end)

    Hub:Btn("🔄 Resetar posição Sell (→ centro)", C.bg3, function()
        ST.sellPos = nil
        sellPosBtn.Text = "📍 Capturar posição de Sell  (centro da tela se vazio)"
    end)
end

----------------------------------------------------------------
-- TAB: MISC
----------------------------------------------------------------
local function LoadMiscTab()
    Hub:Clear()

    Hub:Sep("🛡️  UTILIDADES")

    Hub:Toggle("Noclip", ST.noclip, function(v)
        ST.noclip = v
    end)

    Hub:Toggle("Infinite Jump", ST.infjump, function(v)
        ST.infjump = v
    end)

    Hub:Toggle("Anti Knockback", ST.antiKnock, function(v)
        ST.antiKnock = v
    end)

    Hub:Sep("🔧  AÇÕES RÁPIDAS")

    Hub:Btn("🔄 Respawn manual", C.bg3, function()
        Player:LoadCharacter()
    end)

    Hub:Btn("🏠 Teleportar para origem (0,0,0)", C.bg3, function()
        local hrp = GetHRP()
        if hrp then
            local ground = FindGround(Vector3.new(0, 600, 0))
            hrp.CFrame = CFrame.new(ground or Vector3.new(0, 5, 0))
        end
    end)

    Hub:Sep("📋  INFO")
    Hub:Info("  Módulo: Eat The World")
    Hub:Info("  [G]  →  toggle Auto Grab")
    Hub:Info("  Walk usa raycast avançado (sem cair, sem entrar em paredes)")
end

----------------------------------------------------------------
-- REGISTRA ABAS
----------------------------------------------------------------
local farmBtn = Hub:Tab("Auto Farm", "🌾", LoadFarmTab)
local miscBtn = Hub:Tab("Misc",      "⚙️",  LoadMiscTab)

-- Abre a primeira aba automaticamente
task.defer(function() farmBtn.MouseButton1Click:Fire() end)

print("[Eat The World] ✓ Módulo carregado! [G] = toggle Grab")

end -- fim do return function(Hub)
