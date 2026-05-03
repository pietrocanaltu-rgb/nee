-- ============================================================
--  N3on Hub - Eat The World Module (ETW.Lua) COMPLETO
--  Auto Farm, Auto Eat, Auto Throw, Auto Sell, Teleport, etc.
-- ============================================================

if not _G.N3onHub then
    warn("[ETW Module] Base hub not loaded!")
    return
end

-- Services
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

-- ============================================================
--  CONFIG
-- ============================================================

local Config = {
    AutoFarm = false,
    AutoEat = false,
    AutoThrow = false,
    AutoSell = false,
    AutoWalk = false,
    TeleportToBest = false,
    SmartSell = false,
    EatRange = 50,
    ThrowRange = 80,
    FarmRange = 150,
    SellInterval = 30,
}

-- ============================================================
--  ANTI-STUCK
-- ============================================================

local AntiStuck = {
    Enabled = true,
    CheckInterval = 3,
    MinDistance = 5,
    StuckLimit = 4,
    PauseDuration = 5,
    _lastPosition = nil,
    _stuckCount = 0,
    _isPaused = false,
}

function AntiStuck:_getHRP()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function AntiStuck:_cancelGrab()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        for _, name in ipairs({"Grab", "GrabRelease", "ReleaseGrab", "Drop", "LetGo"}) do
            local remote = remotes:FindFirstChild(name)
            if remote then
                pcall(function() remote:FireServer() end)
            end
        end
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, nil)
    end)
end

function AntiStuck:_tryJump()
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Jump = true end
end

function AntiStuck:_walkRandom()
    local char = Player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        local dirs = {Vector3.new(20,0,0), Vector3.new(-20,0,0), Vector3.new(0,0,20), Vector3.new(0,0,-20)}
        local dir = dirs[math.random(1, #dirs)]
        hum:Move(dir, true)
        task.delay(0.8, function() if hum then hum:Move(Vector3.new(0,0,0), true) end end)
    end
end

function AntiStuck:_teleportUp()
    local hrp = self:_getHRP()
    if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, 15, 0) end
end

function AntiStuck:_teleportRandom()
    local hrp = self:_getHRP()
    if hrp then
        hrp.CFrame = hrp.CFrame + Vector3.new(math.random(-30,30), 10, math.random(-30,30))
    end
end

function AntiStuck:Start()
    self.Enabled = true
    self._stuckCount = 0
    self._lastPosition = nil
    self._isPaused = false
    print("🛡️ Anti-Stuck ATIVADO!")
end

function AntiStuck:Stop()
    self.Enabled = false
    print("🛡️ Anti-Stuck DESATIVADO!")
end

function AntiStuck:IsPaused()
    return self._isPaused
end

-- Loop do Anti-Stuck
task.spawn(function()
    while true do
        task.wait(AntiStuck.CheckInterval)
        if not AntiStuck.Enabled or AntiStuck._isPaused then continue end
        
        local hrp = AntiStuck:_getHRP()
        if not hrp then
            AntiStuck._lastPosition = nil
            AntiStuck._stuckCount = 0
            continue
        end
        
        local pos = hrp.Position
        if AntiStuck._lastPosition then
            local dist = (pos - AntiStuck._lastPosition).Magnitude
            if dist < AntiStuck.MinDistance then
                AntiStuck._stuckCount += 1
                if AntiStuck._stuckCount >= AntiStuck.StuckLimit then
                    print("⚠️ [ANTI-STUCK] Liberando...")
                    AntiStuck:_cancelGrab()
                    task.wait(0.2)
                    AntiStuck:_tryJump()
                    task.wait(0.2)
                    AntiStuck:_walkRandom()
                    task.wait(0.3)
                    AntiStuck:_cancelGrab()
                    task.wait(0.2)
                    AntiStuck:_teleportUp()
                    task.wait(0.3)
                    local newHrp = AntiStuck:_getHRP()
                    if newHrp and (newHrp.Position - AntiStuck._lastPosition).Magnitude < 5 then
                        AntiStuck:_teleportRandom()
                    end
                    AntiStuck._isPaused = true
                    task.delay(AntiStuck.PauseDuration, function()
                        AntiStuck._isPaused = false
                        AntiStuck:_cancelGrab()
                    end)
                    AntiStuck._stuckCount = 0
                    AntiStuck._lastPosition = nil
                end
            else
                AntiStuck._stuckCount = 0
            end
        end
        AntiStuck._lastPosition = pos
    end
end)

-- ============================================================
--  FUNÇÕES AUXILIARES
-- ============================================================

local function getHRP()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = Player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function findNearestThing(folderNames, range)
    local hrp = getHRP()
    if not hrp then return nil end
    
    local nearest = nil
    local minDist = range or 100
    
    for _, folderName in ipairs(folderNames) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in ipairs(folder:GetChildren()) do
                if obj:IsA("Model") then
                    local objHRP = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                    if objHRP then
                        local dist = (hrp.Position - objHRP.Position).Magnitude
                        if dist < minDist then
                            nearest = obj
                            minDist = dist
                        end
                    end
                elseif obj:IsA("BasePart") then
                    local dist = (hrp.Position - obj.Position).Magnitude
                    if dist < minDist then
                        nearest = obj
                        minDist = dist
                    end
                end
            end
        end
    end
    
    return nearest
end

local function teleportTo(target)
    local hrp = getHRP()
    if not hrp or not target then return end
    
    local targetPos
    if target:IsA("Model") then
        local targetHRP = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
        if targetHRP then targetPos = targetHRP.Position end
    elseif target:IsA("BasePart") then
        targetPos = target.Position
    end
    
    if targetPos then
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    end
end

local function fireRemote(remoteName, ...)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return end
    local remote = remotes:FindFirstChild(remoteName)
    if remote then
        pcall(function() remote:FireServer(...) end)
    end
end

-- ============================================================
--  AUTO EAT (Comer inimigos)
-- ============================================================

local AutoEatConnection = nil

local function startAutoEat()
    if AutoEatConnection then return end
    print("🍖 Auto Eat ATIVADO!")
    
    AutoEatConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoEat then return end
        if AntiStuck._isPaused then return end
        
        local target = findNearestThing({"Enemies", "Mobs", "NPCs", "Food", "Edible"}, Config.EatRange)
        if target then
            teleportTo(target)
            fireRemote("Eat", target)
            fireRemote("Grab", target)
        end
        task.wait(0.3)
    end)
end

local function stopAutoEat()
    Config.AutoEat = false
    if AutoEatConnection then
        AutoEatConnection:Disconnect()
        AutoEatConnection = nil
    end
    print("🍖 Auto Eat DESATIVADO!")
end

-- ============================================================
--  AUTO THROW (Arremessar)
-- ============================================================

local AutoThrowConnection = nil

local function startAutoThrow()
    if AutoThrowConnection then return end
    print("💨 Auto Throw ATIVADO!")
    
    AutoThrowConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoThrow then return end
        if AntiStuck._isPaused then return end
        
        -- Tenta arremessar o que estiver segurando
        fireRemote("Throw")
        fireRemote("Release")
        task.wait(0.5)
    end)
end

local function stopAutoThrow()
    Config.AutoThrow = false
    if AutoThrowConnection then
        AutoThrowConnection:Disconnect()
        AutoThrowConnection = nil
    end
    print("💨 Auto Throw DESATIVADO!")
end

-- ============================================================
--  AUTO FARM (Atacar inimigos)
-- ============================================================

local AutoFarmConnection = nil

local function startAutoFarm()
    if AutoFarmConnection then return end
    print("🌾 Auto Farm ATIVADO!")
    
    AutoFarmConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoFarm then return end
        if AntiStuck._isPaused then return end
        
        local target = findNearestThing({"Enemies", "Mobs", "NPCs", "Bosses"}, Config.FarmRange)
        if target then
            teleportTo(target)
            task.wait(0.2)
            fireRemote("Combat", "M1", target)
            fireRemote("Attack", target)
        end
        task.wait(0.5)
    end)
end

local function stopAutoFarm()
    Config.AutoFarm = false
    if AutoFarmConnection then
        AutoFarmConnection:Disconnect()
        AutoFarmConnection = nil
    end
    print("🌾 Auto Farm DESATIVADO!")
end

-- ============================================================
--  AUTO WALK (Andar automaticamente)
-- ============================================================

local AutoWalkConnection = nil

local function startAutoWalk()
    if AutoWalkConnection then return end
    print("🚶 Auto Walk ATIVADO!")
    
    AutoWalkConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoWalk then return end
        if AntiStuck._isPaused then return end
        
        local hum = getHumanoid()
        if hum then
            hum:Move(Vector3.new(0, 0, -50), true) -- Anda pra frente
        end
        task.wait(0.1)
    end)
end

local function stopAutoWalk()
    Config.AutoWalk = false
    if AutoWalkConnection then
        AutoWalkConnection:Disconnect()
        AutoWalkConnection = nil
    end
    local hum = getHumanoid()
    if hum then hum:Move(Vector3.new(0,0,0), true) end
    print("🚶 Auto Walk DESATIVADO!")
end

-- ============================================================
--  AUTO SELL (Vender itens)
-- ============================================================

local AutoSellConnection = nil

local function sellItems()
    print("💰 Vendendo itens...")
    fireRemote("Sell")
    fireRemote("SellAll")
    fireRemote("SellItems")
end

local function smartSell()
    print("🧠 Smart Sell: vendendo itens ruins...")
    -- Tenta vender apenas itens comuns
    fireRemote("SellCommon")
    fireRemote("SellTrash")
end

local function startAutoSell()
    if AutoSellConnection then return end
    print("💰 Auto Sell ATIVADO! (a cada " .. Config.SellInterval .. "s)")
    
    AutoSellConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoSell then return end
        -- Vende a cada X segundos
        if not AutoSellConnection._lastSell or tick() - AutoSellConnection._lastSell > Config.SellInterval then
            AutoSellConnection._lastSell = tick()
            if Config.SmartSell then
                smartSell()
            else
                sellItems()
            end
        end
    end)
end

local function stopAutoSell()
    Config.AutoSell = false
    if AutoSellConnection then
        AutoSellConnection:Disconnect()
        AutoSellConnection = nil
    end
    print("💰 Auto Sell DESATIVADO!")
end

-- ============================================================
--  TELEPORT TO BEST AREA
-- ============================================================

local function teleportToBestArea()
    print("🌍 Teleportando para melhor área...")
    -- Tenta achar áreas no jogo
    local areas = {"BestArea", "FarmZone", "MainIsland", "Spawn"}
    for _, areaName in ipairs(areas) do
        local area = Workspace:FindFirstChild(areaName, true)
        if area then
            local hrp = getHRP()
            if hrp then
                if area:IsA("BasePart") then
                    hrp.CFrame = area.CFrame + Vector3.new(0, 5, 0)
                elseif area:IsA("Model") and area.PrimaryPart then
                    hrp.CFrame = area.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
                end
                print("✅ Teleportado para: " .. areaName)
                return
            end
        end
    end
    print("❌ Nenhuma área encontrada!")
end

-- ============================================================
--  CARREGAR ABA DO ETW
-- ============================================================

local function LoadETWTab()
    _G.N3onHub.GUI.Clear()
    local ScrollContent = _G.N3onHub.GUI.ScrollContent
    _G.N3onHub.GUI.TabTitle.Text = "🌍 Eat The World"
    
    -- Status
    local statusLabel = Instance.new("TextLabel", ScrollContent)
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Auto Farm
    _G.N3onHub.Checkbox("🌾 Auto Farm", Config.AutoFarm, function(v)
        Config.AutoFarm = v
        if v then startAutoFarm() else stopAutoFarm() end
        statusLabel.Text = v and "Status: Farming" or "Status: Idle"
    end)
    
    -- Auto Eat
    _G.N3onHub.Checkbox("🍖 Auto Eat", Config.AutoEat, function(v)
        Config.AutoEat = v
        if v then startAutoEat() else stopAutoEat() end
    end)
    
    -- Auto Throw
    _G.N3onHub.Checkbox("💨 Auto Throw", Config.AutoThrow, function(v)
        Config.AutoThrow = v
        if v then startAutoThrow() else stopAutoThrow() end
    end)
    
    -- Auto Walk
    _G.N3onHub.Checkbox("🚶 Auto Walk", Config.AutoWalk, function(v)
        Config.AutoWalk = v
        if v then startAutoWalk() else stopAutoWalk() end
    end)
    
    -- Auto Sell
    _G.N3onHub.Checkbox("💰 Auto Sell", Config.AutoSell, function(v)
        Config.AutoSell = v
        if v then startAutoSell() else stopAutoSell() end
    end)
    
    -- Smart Sell
    _G.N3onHub.Checkbox("🧠 Smart Sell", Config.SmartSell, function(v)
        Config.SmartSell = v
    end)
    
    -- Anti-Stuck
    _G.N3onHub.Checkbox("🛡️ Anti-Stuck", AntiStuck.Enabled, function(v)
        if v then AntiStuck:Start() else AntiStuck:Stop() end
    end)
    
    -- Botão Teleport
    _G.N3onHub.Button("🌍 Teleport to Best Area", function()
        teleportToBestArea()
    end)
    
    -- Botão Sell Now
    _G.N3onHub.Button("💰 Sell Items Now", function()
        sellItems()
    end)
    
    -- Botão Cancel Grab
    _G.N3onHub.Button("🖐️ Cancel Grab", function()
        AntiStuck:_cancelGrab()
    end)
    
    -- Sliders de Range
    _G.N3onHub.Slider("Eat Range", 10, 200, Config.EatRange, function(v) Config.EatRange = v end)
    _G.N3onHub.Slider("Throw Range", 10, 200, Config.ThrowRange, function(v) Config.ThrowRange = v end)
    _G.N3onHub.Slider("Farm Range", 10, 300, Config.FarmRange, function(v) Config.FarmRange = v end)
    _G.N3onHub.Slider("Sell Interval (s)", 10, 120, Config.SellInterval, function(v) Config.SellInterval = v end)
    
    _G.N3onHub.GUI.UpdateCanvasSize()
end

-- ============================================================
--  REGISTRAR
-- ============================================================

_G.N3onHub.Tab("Eat The World", "🌍", 0, LoadETWTab)
AntiStuck:Start()

print("✅ [ETW] Módulo COMPLETO carregado!")
print("   🌾 Auto Farm")
print("   🍖 Auto Eat")
print("   💨 Auto Throw")
print("   🚶 Auto Walk")
print("   💰 Auto Sell")
print("   🧠 Smart Sell")
print("   🌍 Teleport")
print("   🛡️ Anti-Stuck")
