-- N3on Hub - Slap Battles Module (FULL)
-- N3on Hub - Slap Battles Module (ADAPTADO ao Base)

if not _G.N3onHub then
	warn("[Slap Battles Module] Base hub not loaded! Please load the base first.")
-- Aguarda o Base Hub carregar (até 10s)
local tries = 0
repeat task.wait(0.5); tries += 1 until _G.N3onHub or tries >= 20

if not _G.N3onHub or not _G.N3onHub._loaded then
	warn("[Slap Battles Module] Base hub não carregado! Execute o Base Hub primeiro.")
return
end

@@ -15,24 +19,37 @@ local Player           = Players.LocalPlayer
print("[Slap Battles Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
-- ALIASES para a estrutura do Base Hub
----------------------------------------------------------------

local GUI     = _G.N3onHub.GUI          -- { Hub, F1, F2, ScrollContent, Clear, UpdateCanvasSize }
local SC      = GUI.ScrollContent
local Clear   = GUI.Clear
local UCS     = GUI.UpdateCanvasSize
local Slider  = _G.N3onHub.Slider
local Checkbox = _G.N3onHub.Checkbox
local Tab     = _G.N3onHub.Tab

----------------------------------------------------------------
-- SAVED STATES (mesclados no _G.N3onHub.SavedStates do Base)
----------------------------------------------------------------

_G.N3onHub.SavedStates.autoFarm       = false
_G.N3onHub.SavedStates.farmSpeed      = 30
_G.N3onHub.SavedStates.farmDistance   = 15
_G.N3onHub.SavedStates.farmRange      = 100
_G.N3onHub.SavedStates.auraEnabled    = false
_G.N3onHub.SavedStates.auraSize       = 20
_G.N3onHub.SavedStates.espEnabled     = false
_G.N3onHub.SavedStates.espBoxEnabled  = false
_G.N3onHub.SavedStates.espNameEnabled = false
_G.N3onHub.SavedStates.espDistEnabled = false
_G.N3onHub.SavedStates.antiKnockback  = false
_G.N3onHub.SavedStates.flingEnabled   = false
_G.N3onHub.SavedStates.flingPower     = 500
_G.N3onHub.SavedStates.autoRespawn    = false
_G.N3onHub.SavedStates.clickTpEnabled = false
local SS = _G.N3onHub.SavedStates
SS.autoFarm       = SS.autoFarm       or false
SS.farmSpeed      = SS.farmSpeed      or 30
SS.farmDistance   = SS.farmDistance   or 15
SS.farmRange      = SS.farmRange      or 100
SS.auraEnabled    = SS.auraEnabled    or false
SS.auraSize       = SS.auraSize       or 20
SS.espEnabled     = SS.espEnabled     or false
SS.espBoxEnabled  = SS.espBoxEnabled  or false
SS.espNameEnabled = SS.espNameEnabled or false
SS.espDistEnabled = SS.espDistEnabled or false
SS.antiKnockback  = SS.antiKnockback  or false
SS.flingEnabled   = SS.flingEnabled   or false
SS.flingPower     = SS.flingPower     or 500
SS.autoRespawn    = SS.autoRespawn    or false
SS.clickTpEnabled = SS.clickTpEnabled or false

----------------------------------------------------------------
-- LOCAL FLAGS
@@ -68,35 +85,79 @@ end
-- SAFE ZONE
----------------------------------------------------------------

local safeZone = Instance.new("Part")
safeZone.Name         = "N3onSafeZone"
safeZone.Size         = Vector3.new(30, 1, 30)
safeZone.Anchored     = true
safeZone.CanCollide   = true
safeZone.BrickColor   = BrickColor.new("Bright green")
safeZone.Material     = Enum.Material.SmoothPlastic
safeZone.Transparency = 0.4
safeZone.CFrame       = CFrame.new(0, 500, 99999)
safeZone.Parent       = workspace

local bb = Instance.new("BillboardGui", safeZone)
bb.Size = UDim2.fromOffset(200, 40)
bb.StudsOffset = Vector3.new(0, 4, 0)
bb.AlwaysOnTop = true
local bbLabel = Instance.new("TextLabel", bb)
bbLabel.Size = UDim2.new(1, 0, 1, 0)
bbLabel.BackgroundTransparency = 1
bbLabel.Text = "🟢 SAFE ZONE"
bbLabel.Font = Enum.Font.GothamBold
bbLabel.TextSize = 18
bbLabel.TextColor3 = Color3.new(0, 1, 0)
bbLabel.TextStrokeTransparency = 0.3
local safeZone = workspace:FindFirstChild("N3onSafeZone")
if not safeZone then
	safeZone = Instance.new("Part")
	safeZone.Name         = "N3onSafeZone"
	safeZone.Size         = Vector3.new(30, 1, 30)
	safeZone.Anchored     = true
	safeZone.CanCollide   = true
	safeZone.BrickColor   = BrickColor.new("Bright green")
	safeZone.Material     = Enum.Material.SmoothPlastic
	safeZone.Transparency = 0.4
	safeZone.CFrame       = CFrame.new(0, 500, 99999)
	safeZone.Parent       = workspace

	local bb = Instance.new("BillboardGui", safeZone)
	bb.Size = UDim2.fromOffset(200, 40)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	local bbLabel = Instance.new("TextLabel", bb)
	bbLabel.Size = UDim2.new(1, 0, 1, 0)
	bbLabel.BackgroundTransparency = 1
	bbLabel.Text = "🟢 SAFE ZONE"
	bbLabel.Font = Enum.Font.GothamBold
	bbLabel.TextSize = 18
	bbLabel.TextColor3 = Color3.new(0, 1, 0)
	bbLabel.TextStrokeTransparency = 0.3
end

local function TeleportToSafeZone()
local hrp = GetHRP()
if hrp then hrp.CFrame = safeZone.CFrame + Vector3.new(0, 4, 0) end
end

----------------------------------------------------------------
-- HELPER: cria um TextLabel de seção dentro do ScrollContent
----------------------------------------------------------------

local function SectionLabel(text, color)
	local lbl = Instance.new("TextLabel", SC)
	lbl.Size = UDim2.new(1, 0, 0, 28)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 15
	lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local function TitleLabel(text, color)
	local lbl = Instance.new("TextLabel", SC)
	lbl.Size = UDim2.new(1, 0, 0, 40)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	return lbl
end

local function ActionButton(text, bgColor, callback)
	local btn = Instance.new("TextButton", SC)
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.BackgroundColor3 = bgColor
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn)
	btn.MouseButton1Click:Connect(callback)
	return btn
end

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------
@@ -135,7 +196,12 @@ local function CreateESP(plr)
distLabel.TextStrokeTransparency = 0
distLabel.Text = "..."

	espObjects[plr.Name] = {highlight = highlight, billboard = billboard, nameLabel = nameLabel, distLabel = distLabel}
	espObjects[plr.Name] = {
		highlight = highlight,
		billboard = billboard,
		nameLabel = nameLabel,
		distLabel = distLabel
	}
end

local function RemoveESP(name)
@@ -163,7 +229,7 @@ RunService.RenderStepped:Connect(function()
if not espObjects[plr.Name] then CreateESP(plr) end
local obj = espObjects[plr.Name]

			if _G.N3onHub.SavedStates.espBoxEnabled then
			if SS.espBoxEnabled then
obj.highlight.Adornee = char
obj.highlight.Parent = char
else
@@ -172,9 +238,9 @@ RunService.RenderStepped:Connect(function()

obj.billboard.Adornee = tHRP
obj.billboard.Parent = tHRP
			obj.nameLabel.Visible = _G.N3onHub.SavedStates.espNameEnabled
			obj.nameLabel.Visible = SS.espNameEnabled
obj.nameLabel.Text = plr.Name
			obj.distLabel.Visible = _G.N3onHub.SavedStates.espDistEnabled
			obj.distLabel.Visible = SS.espDistEnabled
if hrp then
obj.distLabel.Text = math.floor((hrp.Position - tHRP.Position).Magnitude) .. " studs"
end
@@ -197,7 +263,7 @@ RunService.Heartbeat:Connect(function()
if plr == Player then continue end
pcall(function()
local tHRP = plr.Character.HumanoidRootPart
			if (hrp.Position - tHRP.Position).Magnitude <= _G.N3onHub.SavedStates.auraSize then
			if (hrp.Position - tHRP.Position).Magnitude <= SS.auraSize then
VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
task.wait(0.01)
VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
@@ -243,7 +309,7 @@ local function FlingTarget(target)
if not hrp or not tHRP then return end
pcall(function()
local bv = Instance.new("BodyVelocity")
		bv.Velocity = (tHRP.Position - hrp.Position).Unit * _G.N3onHub.SavedStates.flingPower
		bv.Velocity = (tHRP.Position - hrp.Position).Unit * SS.flingPower
bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
bv.P = 1e9
bv.Parent = tHRP
@@ -293,7 +359,7 @@ local function DisableClickTP()
end

----------------------------------------------------------------
-- AUTO CLICK + AUTO FARM
-- AUTO FARM
----------------------------------------------------------------

local function Click()
@@ -302,59 +368,37 @@ local function Click()
VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

-- Verifica se uma posição está dentro do bounding box do Lobby
local function IsInsideLobby(pos)
local lobby = workspace:FindFirstChild("Lobby")
if not lobby then return false end

	-- Tenta usar PrimaryPart, senão procura qualquer BasePart como referência
	local ref = lobby.PrimaryPart
	if not ref then
		for _, v in pairs(lobby:GetDescendants()) do
			if v:IsA("BasePart") then ref = v break end
		end
	end
	if not ref then return false end

	-- Calcula o bounding box do modelo inteiro
	local ok, bbCF, bbSize = pcall(function()
		return lobby:GetBoundingBox()
	end)
	local ok, bbCF, bbSize = pcall(function() return lobby:GetBoundingBox() end)
if not ok then return false end

	-- Transforma a posição para o espaço local do bounding box
local localPos = bbCF:PointToObjectSpace(pos)
local half = bbSize / 2

return math.abs(localPos.X) <= half.X
and math.abs(localPos.Y) <= half.Y
and math.abs(localPos.Z) <= half.Z
end

-- Pega o ponto do Teleport1 dentro do Lobby
local function GetLobbyTeleport()
local lobby = workspace:FindFirstChild("Lobby")
if not lobby then return nil end
local tp = lobby:FindFirstChild("Teleport1")
if not tp then return nil end
	-- aceita BasePart ou Model
if tp:IsA("BasePart") then
return tp.Position + Vector3.new(0, 3, 0)
elseif tp:IsA("Model") then
if tp.PrimaryPart then
return tp.PrimaryPart.Position + Vector3.new(0, 3, 0)
else
for _, v in pairs(tp:GetDescendants()) do
				if v:IsA("BasePart") then
					return v.Position + Vector3.new(0, 3, 0)
				end
				if v:IsA("BasePart") then return v.Position + Vector3.new(0, 3, 0) end
end
end
end
return nil
end

-- Tools perigosas — ignora quem tiver qualquer uma delas (case insensitive)
local DANGEROUS_TOOLS = {"overkill", "error", "the flex"}

local function HasDangerousTool(plr)
@@ -365,13 +409,11 @@ local function HasDangerousTool(plr)
end
return false
end
	-- verifica no Character (tool equipada)
if plr.Character then
for _, obj in pairs(plr.Character:GetChildren()) do
if obj:IsA("Tool") and checkName(obj.Name) then return true end
end
end
	-- verifica na Backpack
local bp = plr:FindFirstChild("Backpack")
if bp then
for _, obj in pairs(bp:GetChildren()) do
@@ -385,16 +427,13 @@ local function GetClosestInRange()
local hrp = GetHRP()
if not hrp then return nil end
local closest, best = nil, math.huge
	local range = _G.N3onHub.SavedStates.farmRange

	local range = SS.farmRange
for _, plr in pairs(Players:GetPlayers()) do
if plr == Player then continue end
pcall(function()
local tHRP = plr.Character.HumanoidRootPart
local tHum = plr.Character.Humanoid
			-- ignora players dentro do Lobby
if IsInsideLobby(tHRP.Position) then return end
			-- ignora players com tools perigosas
if HasDangerousTool(plr) then return end
if tHum.Health > 0 then
local d = (hrp.Position - tHRP.Position).Magnitude
@@ -405,8 +444,6 @@ local function GetClosestInRange()
return closest
end

-- Tween contínuo: recria o tween sempre apontando pra posição atual do alvo
-- lookAtGetter: função opcional que retorna a posição pra olhar
local farmConn = nil

local function StartContinuousTween(goalGetter, lookAtGetter)
@@ -419,28 +456,24 @@ local function StartContinuousTween(goalGetter, lookAtGetter)
farmConn:Disconnect(); farmConn = nil
return
end

local hrp = GetHRP()
if not hrp then return end

local goalPos = goalGetter()
if not goalPos then return end

		-- Olha pro alvo enquanto se move
if lookAtGetter then
local lookPos = lookAtGetter()
if lookPos then
				local dir = (lookPos - hrp.Position) * Vector3.new(1, 0, 1) -- só no plano horizontal
				local dir = (lookPos - hrp.Position) * Vector3.new(1, 0, 1)
if dir.Magnitude > 0.1 then
					hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir) * CFrame.Angles(0, 0, 0)
					hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
end
end
end

		-- Só recria o tween se não tiver um rodando
if not activeTween or activeTween.PlaybackState ~= Enum.PlaybackState.Playing then
local dist = (hrp.Position - goalPos).Magnitude
			local dur = math.max(dist / (_G.N3onHub.SavedStates.farmSpeed * 10), 0.05)
			local dur = math.max(dist / (SS.farmSpeed * 10), 0.05)
activeTween = TweenService:Create(
hrp,
TweenInfo.new(dur, Enum.EasingStyle.Linear),
@@ -457,25 +490,18 @@ local function StopContinuousTween()
end

local function AutoFarmLoop()
	local farmTimer  = tick()  -- conta os 3s ativos
	local onPause    = false
	local farmTimer = tick()
	local onPause   = false

while autoFarmActive do
		-- a cada 3s de farm, pausa por 3s (para tudo e ancora o HRP)
if not onPause and tick() - farmTimer >= 3 then
onPause = true
StopContinuousTween()

			-- ancora o HRP pra ficar parado no lugar
local hrpPause = GetHRP()
if hrpPause then hrpPause.Anchored = true end

task.wait(3)

			-- desancora antes de continuar
local hrpResume = GetHRP()
if hrpResume then hrpResume.Anchored = false end

onPause   = false
farmTimer = tick()
continue
@@ -489,20 +515,17 @@ local function AutoFarmLoop()
continue
end

		-- Verifica se EU estou no Lobby → vai pro Teleport1
if IsInsideLobby(hrp.Position) then
local tpPos = GetLobbyTeleport()
if tpPos then
local distToTp = (hrp.Position - tpPos).Magnitude
if distToTp > 5 then
					-- ainda longe do portal, vai até ele sem olhar pra ninguém
StartContinuousTween(function() return tpPos end, nil)
task.wait(0.2)
else
					-- chegou no portal! para tudo, espera 3s SEM ancorar e continua
StopContinuousTween()
task.wait(3)
					farmTimer = tick() -- reseta o timer pra não pausar logo depois
					farmTimer = tick()
end
else
StopContinuousTween()
@@ -511,16 +534,14 @@ local function AutoFarmLoop()
continue
end

		-- Fora do lobby → persegue o player mais próximo
local target = GetClosestInRange()
if target and target.Character then
local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
if tHRP then
				-- passa o goalGetter E o lookAtGetter (posição do rosto/HRP do alvo)
StartContinuousTween(
function()
local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
						if t then return t.Position + Vector3.new(0, -_G.N3onHub.SavedStates.farmDistance, 0) end
						if t then return t.Position + Vector3.new(0, -SS.farmDistance, 0) end
return nil
end,
function()
@@ -538,7 +559,6 @@ local function AutoFarmLoop()
end
end

		-- Sem alvo → só clica
StopContinuousTween()
Click()
task.wait(0.1)
@@ -549,33 +569,18 @@ end

----------------------------------------------------------------
-- TAB: FARM
-- Usa Clear() e recria widgets direto no SC do Base Hub
----------------------------------------------------------------

local function LoadFarmTab()
	_G.N3onHub.GUI.Clear()
	local SC  = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "👏 Farm - Slap Battles"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 100)

	-- AUTO FARM
	local lFarm = Instance.new("TextLabel", SC)
	lFarm.Size = UDim2.new(1, 0, 0, 28)
	lFarm.BackgroundTransparency = 1
	lFarm.Text = "⚡ Auto Farm"
	lFarm.Font = Enum.Font.GothamBold
	lFarm.TextSize = 15
	lFarm.TextColor3 = Color3.fromRGB(255, 200, 100)
	lFarm.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Farm (Tween + Click)", _G.N3onHub.SavedStates.autoFarm, function(v)
		_G.N3onHub.SavedStates.autoFarm = v
	Clear()

	TitleLabel("👏 Farm - Slap Battles", Color3.fromRGB(255, 200, 100))

	SectionLabel("⚡ Auto Farm", Color3.fromRGB(255, 200, 100))

	Checkbox("Auto Farm (Tween + Click)", SS.autoFarm, function(v)
		SS.autoFarm = v
autoFarmActive = v
if v then
spawn(AutoFarmLoop)
@@ -584,89 +589,62 @@ local function LoadFarmTab()
end
end)

	_G.N3onHub.Slider("Tween Speed", 5, 100, _G.N3onHub.SavedStates.farmSpeed, function(v)
		_G.N3onHub.SavedStates.farmSpeed = v
	Slider("Tween Speed", 5, 100, SS.farmSpeed, function(v)
		SS.farmSpeed = v
end)

	_G.N3onHub.Slider("Farm Distance (Y offset)", 0, 50, _G.N3onHub.SavedStates.farmDistance, function(v)
		_G.N3onHub.SavedStates.farmDistance = v
	Slider("Farm Distance (Y offset)", 1, 50, SS.farmDistance, function(v)
		SS.farmDistance = v
end)

	_G.N3onHub.Slider("Farm Range (studs)", 10, 500, _G.N3onHub.SavedStates.farmRange, function(v)
		_G.N3onHub.SavedStates.farmRange = v
	Slider("Farm Range (studs)", 10, 500, SS.farmRange, function(v)
		SS.farmRange = v
end)

	-- HITBOX via loadstring
	local lHitbox = Instance.new("TextLabel", SC)
	lHitbox.Size = UDim2.new(1, 0, 0, 28)
	lHitbox.BackgroundTransparency = 1
	lHitbox.Text = "🎯 Hitbox Expander"
	lHitbox.Font = Enum.Font.GothamBold
	lHitbox.TextSize = 15
	lHitbox.TextColor3 = Color3.fromRGB(255, 100, 100)
	lHitbox.TextXAlignment = Enum.TextXAlignment.Left
	SectionLabel("🎯 Hitbox Expander", Color3.fromRGB(255, 100, 100))

local hitboxLoaded = false
	local hitboxBtn = Instance.new("TextButton", SC)
	hitboxBtn.Size = UDim2.new(1, 0, 0, 40)
	hitboxBtn.Text = "🎯 Carregar Hitbox Expander"
	hitboxBtn.Font = Enum.Font.GothamBold
	hitboxBtn.TextSize = 14
	hitboxBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
	hitboxBtn.TextColor3 = Color3.new(1, 1, 1)
	hitboxBtn.AutoButtonColor = false
	Instance.new("UICorner", hitboxBtn)
	local hitboxBtn = ActionButton("🎯 Carregar Hitbox Expander", Color3.fromRGB(120, 30, 30), function()
		-- callback vazio; lógica abaixo com referência ao botão
	end)

	-- Sobrescreve o connect pra ter acesso ao próprio botão
hitboxBtn.MouseButton1Click:Connect(function()
if hitboxLoaded then return end
hitboxLoaded = true
hitboxBtn.Text = "⏳ Carregando..."
hitboxBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 30)
task.spawn(function()
pcall(function()
				loadstring(game:HttpGet("https://gist.githubusercontent.com/stellar-4242/430ef3087d8d87eb306ca03e728ffbb8/raw/798429dd908b1f4471a1fa569ff62c5e5a93ec61/SLAP.LUA"))()
				loadstring(game:HttpGet(
					"https://gist.githubusercontent.com/stellar-4242/430ef3087d8d87eb306ca03e728ffbb8/raw/798429dd908b1f4471a1fa569ff62c5e5a93ec61/SLAP.LUA"
				))()
end)
hitboxBtn.Text = "✅ Hitbox Carregado!"
hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
end)
end)

	-- KILL AURA
	local lAura = Instance.new("TextLabel", SC)
	lAura.Size = UDim2.new(1, 0, 0, 28)
	lAura.BackgroundTransparency = 1
	lAura.Text = "💥 Kill Aura"
	lAura.Font = Enum.Font.GothamBold
	lAura.TextSize = 15
	lAura.TextColor3 = Color3.fromRGB(255, 80, 80)
	lAura.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Kill Aura", _G.N3onHub.SavedStates.auraEnabled, function(v)
		_G.N3onHub.SavedStates.auraEnabled = v
	SectionLabel("💥 Kill Aura", Color3.fromRGB(255, 80, 80))

	Checkbox("Kill Aura", SS.auraEnabled, function(v)
		SS.auraEnabled = v
auraActive = v
end)

	_G.N3onHub.Slider("Aura Range (studs)", 5, 100, _G.N3onHub.SavedStates.auraSize, function(v)
		_G.N3onHub.SavedStates.auraSize = v
	Slider("Aura Range (studs)", 5, 100, SS.auraSize, function(v)
		SS.auraSize = v
end)

	-- FLING
	local lFling = Instance.new("TextLabel", SC)
	lFling.Size = UDim2.new(1, 0, 0, 28)
	lFling.BackgroundTransparency = 1
	lFling.Text = "🚀 Fling"
	lFling.Font = Enum.Font.GothamBold
	lFling.TextSize = 15
	lFling.TextColor3 = Color3.fromRGB(255, 150, 50)
	lFling.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Enable Fling", _G.N3onHub.SavedStates.flingEnabled, function(v)
		_G.N3onHub.SavedStates.flingEnabled = v
	SectionLabel("🚀 Fling", Color3.fromRGB(255, 150, 50))

	Checkbox("Enable Fling", SS.flingEnabled, function(v)
		SS.flingEnabled = v
flingActive = v
end)

	_G.N3onHub.Slider("Fling Power", 100, 2000, _G.N3onHub.SavedStates.flingPower, function(v)
		_G.N3onHub.SavedStates.flingPower = v
	Slider("Fling Power", 100, 2000, SS.flingPower, function(v)
		SS.flingPower = v
end)

UCS()
@@ -677,31 +655,26 @@ end
----------------------------------------------------------------

local function LoadESPTab()
	_G.N3onHub.GUI.Clear()
	local SC  = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "👁️ ESP - Slap Battles"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(100, 200, 255)

	_G.N3onHub.Checkbox("ESP Ativo", _G.N3onHub.SavedStates.espEnabled, function(v)
		_G.N3onHub.SavedStates.espEnabled = v
	Clear()

	TitleLabel("👁️ ESP - Slap Battles", Color3.fromRGB(100, 200, 255))

	Checkbox("ESP Ativo", SS.espEnabled, function(v)
		SS.espEnabled = v
espActive = v
if not v then ClearAllESP() end
end)
	_G.N3onHub.Checkbox("ESP Box (Highlight)", _G.N3onHub.SavedStates.espBoxEnabled, function(v)
		_G.N3onHub.SavedStates.espBoxEnabled = v

	Checkbox("ESP Box (Highlight)", SS.espBoxEnabled, function(v)
		SS.espBoxEnabled = v
end)
	_G.N3onHub.Checkbox("ESP Nome", _G.N3onHub.SavedStates.espNameEnabled, function(v)
		_G.N3onHub.SavedStates.espNameEnabled = v

	Checkbox("ESP Nome", SS.espNameEnabled, function(v)
		SS.espNameEnabled = v
end)
	_G.N3onHub.Checkbox("ESP Distância", _G.N3onHub.SavedStates.espDistEnabled, function(v)
		_G.N3onHub.SavedStates.espDistEnabled = v

	Checkbox("ESP Distância", SS.espDistEnabled, function(v)
		SS.espDistEnabled = v
end)

UCS()
@@ -712,103 +685,47 @@ end
----------------------------------------------------------------

local function LoadMiscTab()
	_G.N3onHub.GUI.Clear()
	local SC  = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "⚙️ Misc - Slap Battles"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(200, 200, 200)

	-- ANTI KNOCKBACK
	local lAnti = Instance.new("TextLabel", SC)
	lAnti.Size = UDim2.new(1, 0, 0, 28)
	lAnti.BackgroundTransparency = 1
	lAnti.Text = "🛡️ Anti Knockback"
	lAnti.Font = Enum.Font.GothamBold
	lAnti.TextSize = 15
	lAnti.TextColor3 = Color3.fromRGB(100, 255, 100)
	lAnti.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Anti Knockback", _G.N3onHub.SavedStates.antiKnockback, function(v)
		_G.N3onHub.SavedStates.antiKnockback = v
	Clear()

	TitleLabel("⚙️ Misc - Slap Battles", Color3.fromRGB(200, 200, 200))

	SectionLabel("🛡️ Anti Knockback", Color3.fromRGB(100, 255, 100))

	Checkbox("Anti Knockback", SS.antiKnockback, function(v)
		SS.antiKnockback = v
antiKnockActive = v
end)

	-- AUTO RESPAWN
	local lRespawn = Instance.new("TextLabel", SC)
	lRespawn.Size = UDim2.new(1, 0, 0, 28)
	lRespawn.BackgroundTransparency = 1
	lRespawn.Text = "🔄 Auto Respawn"
	lRespawn.Font = Enum.Font.GothamBold
	lRespawn.TextSize = 15
	lRespawn.TextColor3 = Color3.fromRGB(255, 200, 100)
	lRespawn.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Respawn (ao morrer)", _G.N3onHub.SavedStates.autoRespawn, function(v)
		_G.N3onHub.SavedStates.autoRespawn = v
	SectionLabel("🔄 Auto Respawn", Color3.fromRGB(255, 200, 100))

	Checkbox("Auto Respawn (ao morrer)", SS.autoRespawn, function(v)
		SS.autoRespawn = v
autoRespawnActive = v
end)

	-- CLICK TP
	local lCTP = Instance.new("TextLabel", SC)
	lCTP.Size = UDim2.new(1, 0, 0, 28)
	lCTP.BackgroundTransparency = 1
	lCTP.Text = "🖱️ Click TP"
	lCTP.Font = Enum.Font.GothamBold
	lCTP.TextSize = 15
	lCTP.TextColor3 = Color3.fromRGB(255, 200, 50)
	lCTP.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Click TP (clique no chão)", _G.N3onHub.SavedStates.clickTpEnabled, function(v)
		_G.N3onHub.SavedStates.clickTpEnabled = v
	SectionLabel("🖱️ Click TP", Color3.fromRGB(255, 200, 50))

	Checkbox("Click TP (clique no chão)", SS.clickTpEnabled, function(v)
		SS.clickTpEnabled = v
clickTpActive = v
if v then EnableClickTP() else DisableClickTP() end
end)

	-- SAFE ZONE
	local lSafe = Instance.new("TextLabel", SC)
	lSafe.Size = UDim2.new(1, 0, 0, 28)
	lSafe.BackgroundTransparency = 1
	lSafe.Text = "🟢 Safe Zone"
	lSafe.Font = Enum.Font.GothamBold
	lSafe.TextSize = 15
	lSafe.TextColor3 = Color3.fromRGB(100, 255, 100)
	lSafe.TextXAlignment = Enum.TextXAlignment.Left
	SectionLabel("🟢 Safe Zone", Color3.fromRGB(100, 255, 100))

local safeInfo = Instance.new("TextLabel", SC)
safeInfo.Size = UDim2.new(1, 0, 0, 35)
safeInfo.BackgroundTransparency = 1
	safeInfo.Text = "Plataforma criada em Y=500, Z=99999.\nNinguém consegue te alcançar lá."
	safeInfo.Text = "Plataforma em Y=500, Z=99999. Ninguém alcança lá."
safeInfo.Font = Enum.Font.Gotham
safeInfo.TextScaled = true
safeInfo.TextColor3 = Color3.fromRGB(160, 160, 160)
safeInfo.TextXAlignment = Enum.TextXAlignment.Left
safeInfo.TextWrapped = true

	local tpBtn = Instance.new("TextButton", SC)
	tpBtn.Size = UDim2.new(1, 0, 0, 40)
	tpBtn.Text = "🟢 TP to Safe Zone"
	tpBtn.Font = Enum.Font.GothamBold
	tpBtn.TextSize = 14
	tpBtn.BackgroundColor3 = Color3.fromRGB(30, 130, 30)
	tpBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpBtn)
	tpBtn.MouseButton1Click:Connect(TeleportToSafeZone)

	local tpPlrBtn = Instance.new("TextButton", SC)
	tpPlrBtn.Size = UDim2.new(1, 0, 0, 40)
	tpPlrBtn.Text = "🎯 TP to Closest Player"
	tpPlrBtn.Font = Enum.Font.GothamBold
	tpPlrBtn.TextSize = 14
	tpPlrBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 160)
	tpPlrBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpPlrBtn)
	tpPlrBtn.MouseButton1Click:Connect(function()
	ActionButton("🟢 TP to Safe Zone", Color3.fromRGB(30, 130, 30), TeleportToSafeZone)

	ActionButton("🎯 TP to Closest Player", Color3.fromRGB(30, 80, 160), function()
local target = GetClosestPlayer()
if target and target.Character then
local hrp = GetHRP()
@@ -821,12 +738,11 @@ local function LoadMiscTab()
end

----------------------------------------------------------------
-- REGISTRAR TABS
-- O 3º argumento é ignorado pelo base (Y automático)
-- REGISTRAR TABS na sidebar (F2) do Base Hub
----------------------------------------------------------------

_G.N3onHub.Tab("Farm", "👏", 0, LoadFarmTab)
_G.N3onHub.Tab("ESP",  "👁️", 0, LoadESPTab)
_G.N3onHub.Tab("Misc", "⚙️", 0, LoadMiscTab)
Tab("Farm", "👏", 0, LoadFarmTab)
Tab("ESP",  "👁️", 0, LoadESPTab)
Tab("Misc", "⚙️", 0, LoadMiscTab)

print("[Slap Battles Module] Loaded!")
