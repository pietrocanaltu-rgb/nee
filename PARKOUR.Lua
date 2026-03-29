-- N3on Hub - Parkour Legacy Module
-- Execute DEPOIS do script base (N3on Hub Base)

local Player      = game.Players.LocalPlayer
local UIS         = game:GetService("UserInputService")
local RunService  = game:GetService("RunService")
local TweenService= game:GetService("TweenService")

----------------------------------------------------------------
-- AGUARDA O BASE CARREGAR
----------------------------------------------------------------

local timeout = 10
local elapsed = 0
repeat task.wait(0.1); elapsed += 0.1 until _G.N3onHub or elapsed >= timeout

if not _G.N3onHub or not _G.N3onHub._loaded then
	warn("[N3on Hub] Base não carregado! Execute o script base primeiro.")
	return
end

local Hub      = _G.N3onHub.GUI
local Slider   = _G.N3onHub.Slider
local Checkbox = _G.N3onHub.Checkbox
local GetHum   = _G.N3onHub.GetHum
local Tab      = _G.N3onHub.Tab

----------------------------------------------------------------
-- ESTADOS DO MÓDULO
----------------------------------------------------------------

local PK = {
	-- Long Jump Boost
	longJumpEnabled  = false,
	longJumpForce    = 80,      -- força do BodyVelocity (slider)
	longJumpMinSpeed = 25,      -- speed mínima pra ativar

	-- Slide Boost (Shift)
	slideEnabled     = false,
	slideSpeed       = 100,     -- velocidade do slide (slider)
	slideCooldown    = false,

	-- Wall Boost
	wallBoostEnabled = false,
	wallBoostForce   = 60,

	-- Anti-Ragdoll
	antiRagdoll      = false,

	-- Auto Vault (pulo automático ao encostar em objeto)
	autoVault        = false,
}

----------------------------------------------------------------
-- UTILITÁRIOS
----------------------------------------------------------------

local function GetChar()
	return Player.Character
end

local function GetHRP()
	local c = GetChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local c = GetChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

-- Aplica um impulso de BodyVelocity temporário no HRP
local function ApplyImpulse(velocity, duration)
	local hrp = GetHRP()
	if not hrp then return end

	-- Remove BV antiga se ainda existir
	local old = hrp:FindFirstChild("N3onPK_BV")
	if old then old:Destroy() end

	local bv = Instance.new("BodyVelocity")
	bv.Name       = "N3onPK_BV"
	bv.MaxForce   = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity   = velocity
	bv.Parent     = hrp

	task.delay(duration or 0.18, function()
		if bv and bv.Parent then bv:Destroy() end
	end)
end

-- Verifica se há parede à frente do player (raycast)
local function WallAhead()
	local hrp = GetHRP()
	if not hrp then return false end
	local origin = hrp.Position
	local dir    = hrp.CFrame.LookVector * 3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {GetChar()}
	local result = workspace:Raycast(origin, dir, params)
	return result ~= nil
end

----------------------------------------------------------------
-- LONG JUMP BOOST
-- Quando speed > longJumpMinSpeed e o player pula →
-- aplica BodyVelocity na direção que ele está olhando
----------------------------------------------------------------

UIS.JumpRequest:Connect(function()
	if not PK.longJumpEnabled then return end
	local hum = GetHumanoid()
	if not hum then return end
	if hum.WalkSpeed <= PK.longJumpMinSpeed then return end
	if hum.FloorMaterial == Enum.Material.Air then return end -- já no ar

	local hrp = GetHRP()
	if not hrp then return end

	local lookDir = hrp.CFrame.LookVector
	-- Combina força horizontal com um impulso vertical suave
	local impulse = (lookDir * PK.longJumpForce) + Vector3.new(0, PK.longJumpForce * 0.3, 0)
	ApplyImpulse(impulse, 0.2)
end)

----------------------------------------------------------------
-- SLIDE BOOST (LeftShift)
-- Enquanto Shift estiver pressionado → WalkSpeed muito alto
-- Ao soltar → volta ao speed normal salvo
----------------------------------------------------------------

local slideConn = nil

local function StartSlide()
	if slideConn then return end
	local hum = GetHumanoid()
	if not hum then return end

	-- Efeito de "agachar" (reduz altura do character, opcional)
	-- hum.HipHeight pode ser alterado, mas depende do rig do game

	slideConn = RunService.Heartbeat:Connect(function()
		if not PK.slideEnabled then
			if slideConn then slideConn:Disconnect(); slideConn = nil end
			local h = GetHumanoid()
			if h then h.WalkSpeed = _G.N3onHub.SavedStates.speed end
			return
		end
		local h = GetHumanoid()
		if not h then return end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			h.WalkSpeed = PK.slideSpeed
		else
			h.WalkSpeed = _G.N3onHub.SavedStates.speed
			if slideConn then slideConn:Disconnect(); slideConn = nil end
		end
	end)
end

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.LeftShift and PK.slideEnabled then
		StartSlide()
	end
end)

----------------------------------------------------------------
-- WALL BOOST
-- Detecta parede na frente e, ao pular perto dela,
-- propulsiona o player pra cima + frente (mimetiza wall jump)
----------------------------------------------------------------

UIS.JumpRequest:Connect(function()
	if not PK.wallBoostEnabled then return end
	if not WallAhead() then return end

	local hrp = GetHRP()
	if not hrp then return end
	local look = hrp.CFrame.LookVector
	local impulse = (look * PK.wallBoostForce * 0.5) + Vector3.new(0, PK.wallBoostForce, 0)
	ApplyImpulse(impulse, 0.25)
end)

----------------------------------------------------------------
-- ANTI-RAGDOLL
-- Parkour Legacy usa ragdoll em quedas altas –
-- desabilita isso zerando o dano de queda
----------------------------------------------------------------

local antiRagdollConn = nil

local function ToggleAntiRagdoll(state)
	PK.antiRagdoll = state
	if antiRagdollConn then antiRagdollConn:Disconnect(); antiRagdollConn = nil end
	if not state then return end

	antiRagdollConn = RunService.Heartbeat:Connect(function()
		local hum = GetHumanoid()
		if not hum then return end
		-- Zera velocidade de queda ao encostar no chão, evitando dano/ragdoll
		if hum.FloorMaterial ~= Enum.Material.Air then
			local hrp = GetHRP()
			if hrp then
				local vel = hrp.AssemblyLinearVelocity
				if vel.Y < -30 then
					hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
				end
			end
		end
	end)
end

----------------------------------------------------------------
-- AUTO VAULT
-- Ao se aproximar de objeto baixo na frente enquanto corre,
-- pula automaticamente para simulhar vault
----------------------------------------------------------------

local vaultConn = nil
local lastVault = 0

local function ToggleAutoVault(state)
	PK.autoVault = state
	if vaultConn then vaultConn:Disconnect(); vaultConn = nil end
	if not state then return end

	vaultConn = RunService.Heartbeat:Connect(function()
		if tick() - lastVault < 0.6 then return end
		local hum = GetHumanoid()
		local hrp = GetHRP()
		if not hum or not hrp then return end
		if hum.WalkSpeed < 10 then return end

		-- Raycast à frente, altura de joelho (detecta objeto baixo)
		local origin = hrp.Position + Vector3.new(0, -1.5, 0)
		local dir    = hrp.CFrame.LookVector * 2.5
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {GetChar()}
		local hit = workspace:Raycast(origin, dir, params)

		if hit then
			-- Se o obstáculo é baixo (altura relativa < 4 studs), vault
			local objTopY = hit.Instance.Position.Y + (hit.Instance.Size.Y / 2)
			local diff    = objTopY - (hrp.Position.Y - 2.5)
			if diff > 0.2 and diff < 4 then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				ApplyImpulse(hrp.CFrame.LookVector * 30 + Vector3.new(0, 15, 0), 0.15)
				lastVault = tick()
			end
		end
	end)
end

----------------------------------------------------------------
-- RESPAWN: re-aplica estados após respawn
----------------------------------------------------------------

Player.CharacterAdded:Connect(function()
	task.wait(0.8)
	if PK.antiRagdoll then ToggleAntiRagdoll(true) end
	if PK.autoVault   then ToggleAutoVault(true)   end
	-- slideConn e longJump dependem de input, não precisam reconexão
end)

----------------------------------------------------------------
-- INTERFACE - ABA PARKOUR LEGACY
----------------------------------------------------------------

local function LoadParkour()
	_G.N3onHub.GUI.Clear()

	-- SEÇÃO: MOVEMENT HACKS
	local header1 = Instance.new("TextLabel", _G.N3onHub.GUI.ScrollContent)
	header1.Size = UDim2.new(1, 0, 0, 25)
	header1.BackgroundTransparency = 1
	header1.Text = "⚡ Movement Hacks"
	header1.Font = Enum.Font.GothamBold
	header1.TextScaled = true
	header1.TextColor3 = Color3.fromRGB(200, 140, 255)
	header1.TextXAlignment = Enum.TextXAlignment.Left

	-- Long Jump
	Checkbox("Long Jump Boost  [Speed > 25 + Jump]", PK.longJumpEnabled, function(v)
		PK.longJumpEnabled = v
	end)

	Slider("Long Jump Force", 20, 250, PK.longJumpForce, function(v)
		PK.longJumpForce = v
	end)

	-- Slide Boost
	Checkbox("Slide Boost  [Hold LeftShift]", PK.slideEnabled, function(v)
		PK.slideEnabled = v
		if not v then
			-- garante reset de speed
			local hum = GetHumanoid()
			if hum then hum.WalkSpeed = _G.N3onHub.SavedStates.speed end
		end
	end)

	Slider("Slide Speed", 30, 300, PK.slideSpeed, function(v)
		PK.slideSpeed = v
	end)

	-- Wall Boost
	Checkbox("Wall Boost  [Pular perto de parede]", PK.wallBoostEnabled, function(v)
		PK.wallBoostEnabled = v
	end)

	Slider("Wall Boost Force", 20, 200, PK.wallBoostForce, function(v)
		PK.wallBoostForce = v
	end)

	-- SEÇÃO: UTILITY
	local spacer = Instance.new("Frame", _G.N3onHub.GUI.ScrollContent)
	spacer.Size = UDim2.new(1, 0, 0, 6)
	spacer.BackgroundTransparency = 1

	local header2 = Instance.new("TextLabel", _G.N3onHub.GUI.ScrollContent)
	header2.Size = UDim2.new(1, 0, 0, 25)
	header2.BackgroundTransparency = 1
	header2.Text = "🛡️ Utility"
	header2.Font = Enum.Font.GothamBold
	header2.TextScaled = true
	header2.TextColor3 = Color3.fromRGB(200, 140, 255)
	header2.TextXAlignment = Enum.TextXAlignment.Left

	Checkbox("Anti-Ragdoll  [Cancela queda alta]", PK.antiRagdoll, function(v)
		ToggleAntiRagdoll(v)
	end)

	Checkbox("Auto Vault  [Pula obstáculos baixos auto]", PK.autoVault, function(v)
		ToggleAutoVault(v)
	end)

	_G.N3onHub.GUI.UpdateCanvasSize()
end

----------------------------------------------------------------
-- REGISTRA ABA NA SIDEBAR
----------------------------------------------------------------

Tab("Parkour", "🏃", 0, LoadParkour)

print("[N3on Hub] Parkour Legacy Module loaded!")
