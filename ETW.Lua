-- N3on Hub - Parkour Legacy Module v2
-- Execute DEPOIS do script base

repeat task.wait(0.1) until _G.N3onHub and _G.N3onHub._loaded

local Player   = game.Players.LocalPlayer
local UIS      = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Slider   = _G.N3onHub.Slider
local Checkbox = _G.N3onHub.Checkbox
local Tab      = _G.N3onHub.Tab

----------------------------------------------------------------
-- ESTADOS
----------------------------------------------------------------

local PK = {
	slideEnabled     = false,
	slideSpeed       = 80,

	longJumpEnabled  = false,
	longJumpForce    = 80,

	wallBoostEnabled = false,
	wallBoostForce   = 60,

	antiRagdoll      = false,
	autoVault        = false,
}

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------

local function Char() return Player.Character end
local function HRP()  local c=Char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum()  local c=Char(); return c and c:FindFirstChildOfClass("Humanoid") end

local function Impulse(vel, t)
	local hrp = HRP(); if not hrp then return end
	local old = hrp:FindFirstChild("N3_BV"); if old then old:Destroy() end
	local bv = Instance.new("BodyVelocity")
	bv.Name = "N3_BV"
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity = vel
	bv.Parent = hrp
	task.delay(t or 0.18, function() if bv.Parent then bv:Destroy() end end)
end

local function WallAhead()
	local hrp = HRP(); if not hrp then return false end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {Char()}
	return workspace:Raycast(hrp.Position, hrp.CFrame.LookVector * 3, rp) ~= nil
end

----------------------------------------------------------------
-- LOOP PRINCIPAL
-- Toda frame (Heartbeat) verifica as features ativas
-- e seta a propriedade diretamente — igual ao loopwalkspeed
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	local hum = Hum()
	local hrp = HRP()
	if not hum or not hrp then return end

	-- SLIDE: enquanto Shift segurado → força WalkSpeed toda frame
	if PK.slideEnabled and UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
		hum.WalkSpeed = PK.slideSpeed
	end

	-- ANTI-RAGDOLL: ao tocar chão com queda muito rápida → zera Y
	if PK.antiRagdoll and hum.FloorMaterial ~= Enum.Material.Air then
		local vel = hrp.AssemblyLinearVelocity
		if vel.Y < -35 then
			hrp.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
		end
	end
end)

----------------------------------------------------------------
-- LONG JUMP + WALL BOOST (no JumpRequest)
----------------------------------------------------------------

UIS.JumpRequest:Connect(function()
	local hum = Hum(); local hrp = HRP()
	if not hum or not hrp then return end

	if PK.longJumpEnabled
		and hum.WalkSpeed > 25
		and hum.FloorMaterial ~= Enum.Material.Air then
		local d = hrp.CFrame.LookVector
		Impulse(d * PK.longJumpForce + Vector3.new(0, PK.longJumpForce * 0.25, 0), 0.2)
	end

	if PK.wallBoostEnabled and WallAhead() then
		local d = hrp.CFrame.LookVector
		Impulse(d * PK.wallBoostForce * 0.4 + Vector3.new(0, PK.wallBoostForce, 0), 0.25)
	end
end)

----------------------------------------------------------------
-- AUTO VAULT
----------------------------------------------------------------

local lastVault = 0

RunService.Heartbeat:Connect(function()
	if not PK.autoVault then return end
	if tick() - lastVault < 0.7 then return end
	local hum = Hum(); local hrp = HRP()
	if not hum or not hrp then return end
	if hum.WalkSpeed < 10 or hum.FloorMaterial == Enum.Material.Air then return end

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {Char()}
	local hit = workspace:Raycast(hrp.Position + Vector3.new(0,-1.5,0), hrp.CFrame.LookVector*2.5, rp)
	if hit then
		local top  = hit.Instance.Position.Y + hit.Instance.Size.Y / 2
		local diff = top - (hrp.Position.Y - 2.5)
		if diff > 0.2 and diff < 4 then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			Impulse(hrp.CFrame.LookVector*28 + Vector3.new(0,14,0), 0.15)
			lastVault = tick()
		end
	end
end)

----------------------------------------------------------------
-- RESPAWN
----------------------------------------------------------------

Player.CharacterAdded:Connect(function()
	task.wait(0.8)
	lastVault = 0
	-- slide: se ativo, o Heartbeat já retoma sozinho
	-- ao respawnar, garante que speed volta ao normal
	local hum = Hum()
	if hum then hum.WalkSpeed = _G.N3onHub.SavedStates.speed end
end)

----------------------------------------------------------------
-- INTERFACE
----------------------------------------------------------------

local function Label(txt, color)
	local l = Instance.new("TextLabel", _G.N3onHub.GUI.ScrollContent)
	l.Size = UDim2.new(1,0,0,22)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextColor3 = color or Color3.fromRGB(200,140,255)
	l.TextXAlignment = Enum.TextXAlignment.Left
end

local function LoadParkour()
	_G.N3onHub.GUI.Clear()

	Label("⚡  Movement")

	Checkbox("Slide Boost  [Hold LeftShift]", PK.slideEnabled, function(v)
		PK.slideEnabled = v
		if not v then
			local hum = Hum()
			if hum then hum.WalkSpeed = _G.N3onHub.SavedStates.speed end
		end
	end)
	Slider("Slide Speed", 30, 350, PK.slideSpeed, function(v) PK.slideSpeed = v end)

	Checkbox("Long Jump  [Speed > 25 + Pular]", PK.longJumpEnabled, function(v) PK.longJumpEnabled = v end)
	Slider("Long Jump Force", 20, 300, PK.longJumpForce, function(v) PK.longJumpForce = v end)

	Checkbox("Wall Boost  [Pular perto de parede]", PK.wallBoostEnabled, function(v) PK.wallBoostEnabled = v end)
	Slider("Wall Boost Force", 20, 200, PK.wallBoostForce, function(v) PK.wallBoostForce = v end)

	-- spacer
	local sp = Instance.new("Frame", _G.N3onHub.GUI.ScrollContent)
	sp.Size = UDim2.new(1,0,0,4); sp.BackgroundTransparency = 1

	Label("🛡️  Utility")

	Checkbox("Anti-Ragdoll  [Cancela ragdoll de queda]", PK.antiRagdoll, function(v) PK.antiRagdoll = v end)
	Checkbox("Auto Vault  [Pula obstáculos baixos auto]", PK.autoVault, function(v) PK.autoVault = v end)

	_G.N3onHub.GUI.UpdateCanvasSize()
end

Tab("Parkour", "🏃", 0, LoadParkour)

print("[N3on Hub] Parkour Legacy Module v2 loaded!")
