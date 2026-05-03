-- ============================================================
--  N3on Hub - Eat The World Module (ETW.Lua)
--  Com Anti-Stuck que cancela Grab travado
-- ============================================================

if not _G.N3onHub then
    warn("[ETW Module] Base hub not loaded! Please load the base first.")
    return
end

-- ============================================================
--  SERVICES
-- ============================================================

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- ============================================================
--  ANTI-STUCK COM CANCELAMENTO DE GRAB
-- ============================================================

local AntiStuck = {
    Enabled = false,
    CheckInterval = 3,
    MinDistance = 5,
    StuckLimit = 4,
    PauseDuration = 5,
    _lastPosition = nil,
    _stuckCount = 0,
    _isPaused = false,
    _connections = {},
}

function AntiStuck:_getCharacter()
    return Player.Character
end

function AntiStuck:_getHRP()
    local char = self:_getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

function AntiStuck:_getHumanoid()
    local char = self:_getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- Cancela o Grab (solta o que estiver segurando)
function AntiStuck:_cancelGrab()
    print("🖐️ [ANTI-STUCK] Cancelando Grab...")
    
    -- Método 1: Tenta usar o Remote de Grab/Soltar
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        -- Tenta vários nomes comuns de Remote de Grab
        local grabRemotes = {
            remotes:FindFirstChild("Grab"),
            remotes:FindFirstChild("GrabRelease"),
            remotes:FindFirstChild("ReleaseGrab"),
            remotes:FindFirstChild("Drop"),
            remotes:FindFirstChild("LetGo"),
        }
        
        for _, remote in ipairs(grabRemotes) do
            if remote then
                pcall(function()
                    remote:FireServer()
                end)
                print("  ✅ Remote disparado: " .. remote.Name)
            end
        end
    end
    
    -- Método 2: Simula tecla G (soltar)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, nil)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, nil)
    end)
    
    -- Método 3: Simula clique direito (soltar)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, 0, 0, 0, false, nil, 0, false)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, 0, 0, 0, true, nil, 0, false)
    end)
end

function AntiStuck:_tryJump()
    local hum = self:_getHumanoid()
    if hum then
        hum.Jump = true
    end
end

function AntiStuck:_walkRandomDirection()
    local hum = self:_getHumanoid()
    if hum then
        local directions = {
            Vector3.new(20, 0, 0),
            Vector3.new(-20, 0, 0),
            Vector3.new(0, 0, 20),
            Vector3.new(0, 0, -20),
        }
        local randomDir = directions[math.random(1, #directions)]
        hum:Move(randomDir, true)
        task.delay(0.8, function()
            if hum then
                hum:Move(Vector3.new(0, 0, 0), true)
            end
        end)
    end
end

function AntiStuck:_teleportUp()
    local hrp = self:_getHRP()
    if hrp then
        hrp.CFrame = hrp.CFrame + Vector3.new(0, 15, 0)
    end
end

function AntiStuck:_teleportRandom()
    local hrp = self:_getHRP()
    if hrp then
        local randomOffset = Vector3.new(
            math.random(-30, 30),
            10,
            math.random(-30, 30)
        )
        hrp.CFrame = hrp.CFrame + randomOffset
    end
end

function AntiStuck:_check()
    if not self.Enabled then return end
    if self._isPaused then return end
    
    local hrp = self:_getHRP()
    if not hrp then
        self._lastPosition = nil
        self._stuckCount = 0
        return
    end
    
    local currentPos = hrp.Position
    
    if self._lastPosition then
        local distance = (currentPos - self._lastPosition).Magnitude
        
        if distance < self.MinDistance then
            self._stuckCount += 1
            
            if self._stuckCount >= self.StuckLimit then
                print("⚠️ [ANTI-STUCK] Player travado! Executando sequência de libertação...")
                
                -- ═══════════════════════════════════
                -- SEQUÊNCIA DE LIBERTAÇÃO
                -- ═══════════════════════════════════
                
                -- 1. PRIMEIRO: Cancela o Grab!
                self:_cancelGrab()
                task.wait(0.3)
                
                -- 2. Tenta pular
                self:_tryJump()
                task.wait(0.2)
                
                -- 3. Anda em direção aleatória
                self:_walkRandomDirection()
                task.wait(0.5)
                
                -- 4. Cancela Grab de novo (segurança)
                self:_cancelGrab()
                task.wait(0.2)
                
                -- 5. Teleporta pra cima (desprende de qualquer colisão)
                self:_teleportUp()
                task.wait(0.3)
                
                -- 6. Se ainda tiver no mesmo lugar, teleporta pra longe
                if hrp and self._lastPosition then
                    local newDist = (hrp.Position - self._lastPosition).Magnitude
                    if newDist < 5 then
                        print("  🔄 Ainda preso! Teleportando pra longe...")
                        self:_teleportRandom()
                    end
                end
                
                -- Pausa o farm
                self._isPaused = true
                print("⏸️ [ANTI-STUCK] Farm pausado por " .. self.PauseDuration .. "s")
                
                task.delay(self.PauseDuration, function()
                    self._isPaused = false
                    self:_cancelGrab() -- Cancela grab de novo ao retomar
                    print("▶️ [ANTI-STUCK] Farm retomado!")
                end)
                
                self._stuckCount = 0
                self._lastPosition = nil
            end
        else
            self._stuckCount = 0
        end
    end
    
    self._lastPosition = currentPos
end

function AntiStuck:Start()
    self.Enabled = true
    self._stuckCount = 0
    self._lastPosition = nil
    self._isPaused = false
    
    if self._connections.check then
        self._connections.check:Disconnect()
    end
    
    self._connections.check = RunService.Heartbeat:Connect(function()
        if not self._nextCheck or tick() > self._nextCheck then
            self._nextCheck = tick() + self.CheckInterval
            self:_check()
        end
    end)
    
    print("🛡️ Anti-Stuck ATIVADO (com cancelamento de Grab)!")
end

function AntiStuck:Stop()
    self.Enabled = false
    self._stuckCount = 0
    self._lastPosition = nil
    self._isPaused = false
    
    if self._connections.check then
        self._connections.check:Disconnect()
        self._connections.check = nil
    end
    
    print("🛡️ Anti-Stuck DESATIVADO!")
end

function AntiStuck:IsPaused()
    return self._isPaused
end

-- ============================================================
--  AUTO FARM SYSTEM
-- ============================================================

local Farm = {
    Active = false,
    Method = "Nearest",
    Range = 150,
    _connection = nil,
    _target = nil,
}

function Farm:_getHRP()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

function Farm:_findNearestEnemy()
    local hrp = self:_getHRP()
    if not hrp then return nil end
    
    local nearest = nil
    local minDist = self.Range
    
    local foldersToCheck = {"Enemies", "Mobs", "NPCs", "Bosses"}
    
    for _, folderName in ipairs(foldersToCheck) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, enemy in ipairs(folder:GetChildren()) do
                if enemy:IsA("Model") then
                    local humanoid = enemy:FindFirstChild("Humanoid")
                    local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and enemyHRP then
                        local dist = (hrp.Position - enemyHRP.Position).Magnitude
                        if dist < minDist then
                            nearest = enemy
                            minDist = dist
                        end
                    end
                end
            end
        end
    end
    
    -- Procura também solto no Workspace
    if not nearest then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj ~= Player.Character then
                local humanoid = obj:FindFirstChild("Humanoid")
                local enemyHRP = obj:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and enemyHRP then
                    local dist = (hrp.Position - enemyHRP.Position).Magnitude
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

function Farm:_attackTarget(target)
    if not target then return end
    
    local combatEvent = ReplicatedStorage:FindFirstChild("Remotes") 
                        and ReplicatedStorage.Remotes:FindFirstChild("Combat")
    if combatEvent then
        pcall(function()
            combatEvent:FireServer("M1", target)
        end)
    end
end

function Farm:_teleportToTarget(target)
    local hrp = self:_getHRP()
    local targetHRP = target and target:FindFirstChild("HumanoidRootPart")
    
    if hrp and targetHRP then
        hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 5)
    end
end

function Farm:Start()
    if self.Active then return end
    self.Active = true
    
    print("🌾 Auto Farm ATIVADO!")
    
    self._connection = RunService.Heartbeat:Connect(function()
        if not self.Active then return end
        if AntiStuck:IsPaused() then return end
        
        local target = self:_findNearestEnemy()
        if target then
            self._target = target
            self:_teleportToTarget(target)
            task.wait(0.3)
            self:_attackTarget(target)
        end
        task.wait(0.5)
    end)
end

function Farm:Stop()
    self.Active = false
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    self._target = nil
    print("🌾 Auto Farm DESATIVADO!")
end

-- ============================================================
--  AUTO EQUIP BEST WEAPON
-- ============================================================

local function equipBestWeapon()
    local char = Player.Character
    if not char then return end
    
    local bestWeapon = nil
    local highestDamage = 0
    
    for _, tool in ipairs(Player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local config = tool:FindFirstChild("Configuration")
            if config and config:FindFirstChild("Damage") then
                local damage = config.Damage.Value
                if damage > highestDamage then
                    highestDamage = damage
                    bestWeapon = tool
                end
            end
        end
    end
    
    if bestWeapon then
        bestWeapon.Parent = char
        print("⚔️ Equipada: " .. bestWeapon.Name)
    end
end

-- ============================================================
--  MANUAL GRAB CANCEL (Botão)
-- ============================================================

local function manualCancelGrab()
    print("🖐️ Cancelando Grab manualmente...")
    AntiStuck:_cancelGrab()
end

-- ============================================================
--  CARREGAR ABA DO ETW NO HUB
-- ============================================================

local function LoadETWTab()
    _G.N3onHub.GUI.Clear()
    
    local ScrollContent = _G.N3onHub.GUI.ScrollContent
    local UpdateCanvasSize = _G.N3onHub.GUI.UpdateCanvasSize
    
    -- Título
    local title = Instance.new("TextLabel", ScrollContent)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🌍 Eat The World"
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    -- Status
    local statusLabel = Instance.new("TextLabel", ScrollContent)
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: Idle"
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextScaled = true
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Status do Anti-Stuck
    local stuckStatus = Instance.new("TextLabel", ScrollContent)
    stuckStatus.Size = UDim2.new(1, 0, 0, 30)
    stuckStatus.BackgroundTransparency = 1
    stuckStatus.Text = "🛡️ Anti-Stuck: ATIVO"
    stuckStatus.Font = Enum.Font.Gotham
    stuckStatus.TextScaled = true
    stuckStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
    stuckStatus.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Auto Farm
    _G.N3onHub.Checkbox("Auto Farm", false, function(v)
        if v then
            Farm:Start()
            statusLabel.Text = "Status: Farming"
        else
            Farm:Stop()
            statusLabel.Text = "Status: Idle"
        end
    end)
    
    -- Anti-Stuck
    _G.N3onHub.Checkbox("Anti-Stuck", true, function(v)
        if v then
            AntiStuck:Start()
            stuckStatus.Text = "🛡️ Anti-Stuck: ATIVO"
            stuckStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            AntiStuck:Stop()
            stuckStatus.Text = "🛡️ Anti-Stuck: DESATIVADO"
            stuckStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
    
    -- Botão Manual Cancelar Grab
    local cancelGrabBtn = Instance.new("TextButton", ScrollContent)
    cancelGrabBtn.Size = UDim2.new(1, 0, 0, 40)
    cancelGrabBtn.Text = "🖐️ Cancelar Grab (Manual)"
    cancelGrabBtn.Font = Enum.Font.GothamBold
    cancelGrabBtn.TextScaled = true
    cancelGrabBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    cancelGrabBtn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", cancelGrabBtn)
    
    cancelGrabBtn.MouseButton1Click:Connect(function()
        manualCancelGrab()
    end)
    
    -- Auto Equip Best Weapon
    _G.N3onHub.Checkbox("Auto Equip Best Weapon", false, function(v)
        if v then
            equipBestWeapon()
        end
    end)
    
    -- Config Anti-Stuck
    local configTitle = Instance.new("TextLabel", ScrollContent)
    configTitle.Size = UDim2.new(1, 0, 0, 30)
    configTitle.BackgroundTransparency = 1
    configTitle.Text = "⚙️ Config Anti-Stuck"
    configTitle.Font = Enum.Font.GothamBold
    configTitle.TextScaled = true
    configTitle.TextColor3 = Color3.fromRGB(255, 255, 150)
    configTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    _G.N3onHub.Slider("Check Interval (s)", 1, 10, AntiStuck.CheckInterval, function(v)
        AntiStuck.CheckInterval = v
    end)
    
    _G.N3onHub.Slider("Min Distance (studs)", 1, 20, AntiStuck.MinDistance, function(v)
        AntiStuck.MinDistance = v
    end)
    
    _G.N3onHub.Slider("Stuck Limit (checks)", 2, 10, AntiStuck.StuckLimit, function(v)
        AntiStuck.StuckLimit = v
    end)
    
    _G.N3onHub.Slider("Pause Duration (s)", 1, 15, AntiStuck.PauseDuration, function(v)
        AntiStuck.PauseDuration = v
    end)
    
    UpdateCanvasSize()
end

-- ============================================================
--  REGISTRAR ABA NO HUB
-- ============================================================

_G.N3onHub.Tab("Eat The World", "🌍", 0, LoadETWTab)

-- Iniciar Anti-Stuck por padrão
AntiStuck:Start()

print("✅ [ETW Module] Carregado com Anti-Stuck + Cancel Grab!")
print("🛡️ Anti-Stuck já está ativo!")
print("🖐️ Grab será cancelado automaticamente ao detectar stuck!")
