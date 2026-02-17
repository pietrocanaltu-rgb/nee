-- N3on Hub - Slap Battles Module (FULL)

if not _G.N3onHub then
	warn("[Slap Battles Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local Players        = game:GetService("Players")
local VIM            = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Workspace      = game:GetService("Workspace")
local Player         = Players.LocalPlayer

print("[Slap Battles Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------

_G.N3onHub.SavedStates.autoFarm        = false
_G.N3onHub.SavedStates.farmSpeed       = 30
_G.N3onHub.SavedStates.farmDistance    = 15      -- Y offset abaixo do alvo
_G.N3onHub.SavedStates.farmRange       = 100     -- distância máxima pra considerar alvo
_G.N3onHub.SavedStates.hitboxEnabled   = false
_G.N3onHub.SavedStates.hitboxSize      = 15
_G.N3onHub.SavedStates.hitboxTrans     = 0.9
_G.N3onHub.SavedStates.auraEnabled     = false
_G.N3onHub.SavedStates.auraSize        = 20
_G.N3onHub.SavedStates.espEnabled      = false
_G.N3onHub.SavedStates.espBoxEnabled   = false
_G.N3onHub.SavedStates.espNameEnabled  = false
_G.N3onHub.SavedStates.espDistEnabled  = false
_G.N3onHub.SavedStates.antiKnockback   = false
_G.N3onHub.SavedStates.flingEnabled    = false
_G.N3onHub.SavedStates.flingPower      = 500
_G.N3onHub.SavedStates.noclipEnabled   = false
_G.N3onHub.SavedStates.speedEnabled    = false
_G.N3onHub.SavedStates.speedValue      = 16
_G.N3onHub.SavedStates.jumpEnabled     = false
_G.N3onHub.SavedStates.jumpValue       = 50
_G.N3onHub.SavedStates.infiniteJump    = false
_G.N3onHub.SavedStates.ghostEnabled    = false
_G.N3onHub.SavedStates.autoRespawn     = false
_G.N3onHub.SavedStates.clickTpEnabled  = false

----------------------------------------------------------------
-- LOCAL FLAGS
----------------------------------------------------------------

local autoFarmActive   = false
local hitboxActive     = false
local auraActive       = false
local espActive        = false
local antiKnockActive  = false
local flingActive      = false
local noclipActive     = false
local speedActive      = false
local jumpActive       = false
local infJumpActive    = false
local ghostActive      = false
local autoRespawnActive= false
local clickTpActive    = false

local activeTween      = nil
local espObjects       = {}
local auraObjects      = {}

----------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------

local function GetHRP()
	local c = Player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
	local c = Player.Character
	return c and c:FindFirstChild("Humanoid")
end

local function GetChar()
	return Player.Character
end

----------------------------------------------------------------
-- SAFE ZONE (CRIADA AUTOMATICAMENTE AO CARREGAR)
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
bb.Size        = UDim2.fromOffset(200, 40)
bb.StudsOffset = Vector3.new(0, 4, 0)
bb.AlwaysOnTop = true

local bbLabel = Instance.new("TextLabel", bb)
bbLabel.Size                   = UDim2.new(1, 0, 1, 0)
bbLabel.BackgroundTransparency = 1
bbLabel.Text                   = "🟢 SAFE ZONE"
bbLabel.Font                   = Enum.Font.GothamBold
bbLabel.TextSize               = 18
bbLabel.TextColor3             = Color3.new(0, 1, 0)
bbLabel.TextStrokeTransparency = 0.3

local function TeleportToSafeZone()
	local hrp = GetHRP()
	if hrp then
		hrp.CFrame = safeZone.CFrame + Vector3.new(0, 4, 0)
	end
end

----------------------------------------------------------------
-- HITBOX EXPANDER
----------------------------------------------------------------

RunService.RenderStepped:Connect(function()
	for _, v in next, Players:GetPlayers() do
		if v.Name ~= Player.Name then
			pcall(function()
				local hrp = v.Character.HumanoidRootPart
				if hitboxActive then
					hrp.Size         = Vector3.new(_G.N3onHub.SavedStates.hitboxSize, _G.N3onHub.SavedStates.hitboxSize, _G.N3onHub.SavedStates.hitboxSize)
					hrp.Transparency = _G.N3onHub.SavedStates.hitboxTrans
					hrp.BrickColor   = BrickColor.new("Really black")
					hrp.Material     = "Neon"
					hrp.CanCollide   = false
				else
					hrp.Size         = Vector3.new(2, 2, 1)
					hrp.Transparency = 1
					hrp.BrickColor   = BrickColor.new("Medium stone grey")
					hrp.Material     = "Plastic"
					hrp.CanCollide   = false
				end
			end)
		end
	end
end)

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------

local function CreateESPBox(plr)
	if espObjects[plr.Name] then return end

	local folder = Instance.new("Folder")
	folder.Name = "ESP_" .. plr.Name
	folder.Parent = workspace

	local highlight = Instance.new("Highlight")
	highlight.Name          = "ESPHighlight"
	highlight.FillColor     = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor  = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency   = 0.5
	highlight.OutlineTransparency = 0

	local billboard = Instance.new("BillboardGui")
	billboard.Name        = "ESPBillboard"
	billboard.Size        = UDim2.fromOffset(150, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true

	local nameLabel = Instance.new("TextLabel", billboard)
	nameLabel.Name                   = "NameLabel"
	nameLabel.Size                   = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font                   = Enum.Font.GothamBold
	nameLabel.TextSize               = 14
	nameLabel.TextColor3             = Color3.fromRGB(255, 80, 80)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Text                   = plr.Name

	local distLabel = Instance.new("TextLabel", billboard)
	distLabel.Name                   = "DistLabel"
	distLabel.Size                   = UDim2.new(1, 0, 0.5, 0)
	distLabel.Position               = UDim2.new(0, 0, 0.5, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.Font                   = Enum.Font.Gotham
	distLabel.TextSize               = 12
	distLabel.TextColor3             = Color3.fromRGB(255, 255, 100)
	distLabel.TextStrokeTransparency = 0
	distLabel.Text                   = "..."

	espObjects[plr.Name] = {
		folder    = folder,
		highlight = highlight,
		billboard = billboard,
		nameLabel = nameLabel,
		distLabel = distLabel,
	}
end

local function RemoveESP(plrName)
	if espObjects[plrName] then
		pcall(function() espObjects[plrName].folder:Destroy() end)
		pcall(function() espObjects[plrName].highlight:Destroy() end)
		pcall(function() espObjects[plrName].billboard:Destroy() end)
		espObjects[plrName] = nil
	end
end

local function ClearAllESP()
	for name, _ in pairs(espObjects) do
		RemoveESP(name)
	end
end

RunService.RenderStepped:Connect(function()
	if not espActive then
		ClearAllESP()
		return
	end

	local hrp = GetHRP()

	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local char = plr.Character
			if not char then RemoveESP(plr.Name) return end
			local tHRP = char:FindFirstChild("HumanoidRootPart")
			if not tHRP then RemoveESP(plr.Name) return end

			if not espObjects[plr.Name] then
				CreateESPBox(plr)
			end

			local obj = espObjects[plr.Name]

			-- Highlight (box)
			if _G.N3onHub.SavedStates.espBoxEnabled then
				obj.highlight.Adornee = char
				obj.highlight.Parent  = char
			else
				obj.highlight.Parent = nil
			end

			-- Billboard
			obj.billboard.Adornee = tHRP
			obj.billboard.Parent  = tHRP

			-- Name
			obj.nameLabel.Visible = _G.N3onHub.SavedStates.espNameEnabled
			obj.nameLabel.Text    = plr.Name

			-- Distance
			obj.distLabel.Visible = _G.N3onHub.SavedStates.espDistEnabled
			if hrp then
				local dist = math.floor((hrp.Position - tHRP.Position).Magnitude)
				obj.distLabel.Text = dist .. " studs"
			end
		end)
	end

	-- Limpa jogadores que saíram
	for name, _ in pairs(espObjects) do
		if not Players:FindFirstChild(name) then
			RemoveESP(name)
		end
	end
end)

----------------------------------------------------------------
-- AURA (KILL AURA)
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	if not auraActive then return end
	local hrp = GetHRP()
	if not hrp then return end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			local dist = (hrp.Position - tHRP.Position).Magnitude
			if dist <= _G.N3onHub.SavedStates.auraSize then
				-- simula clique na direção do alvo
				VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
				task.wait(0.01)
				VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
			end
		end)
	end
end)

----------------------------------------------------------------
-- ANTI KNOCKBACK
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	if not antiKnockActive then return end
	local hrp = GetHRP()
	if not hrp then return end
	pcall(function()
		hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
	end)
end)

----------------------------------------------------------------
-- FLING (CLICA NO MAIS PRÓXIMO COM FORÇA EXTRA)
----------------------------------------------------------------

local function FlingTarget(target)
	if not target or not target.Character then return end
	local hrp  = GetHRP()
	local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not tHRP then return end

	pcall(function()
		local bv = Instance.new("BodyVelocity")
		bv.Velocity      = (tHRP.Position - hrp.Position).Unit * _G.N3onHub.SavedStates.flingPower
		bv.MaxForce      = Vector3.new(1e9, 1e9, 1e9)
		bv.P             = 1e9
		bv.Parent        = tHRP
		task.delay(0.1, function() bv:Destroy() end)
	end)
end

local function GetClosestFling()
	local hrp = GetHRP()
	if not hrp then return nil end
	local closest, best = nil, math.huge
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			local d = (hrp.Position - tHRP.Position).Magnitude
			if d < best then closest = plr; best = d end
		end)
	end
	return closest
end

RunService.Heartbeat:Connect(function()
	if not flingActive then return end
	local target = GetClosestFling()
	if target then FlingTarget(target) end
end)

----------------------------------------------------------------
-- NOCLIP
----------------------------------------------------------------

RunService.Stepped:Connect(function()
	if not noclipActive then return end
	local char = GetChar()
	if not char then return end
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			part.CanCollide = false
		end
	end
end)

----------------------------------------------------------------
-- SPEED
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	local hum = GetHum()
	if not hum then return end
	if speedActive then
		hum.WalkSpeed = _G.N3onHub.SavedStates.speedValue
	else
		if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
	end
end)

----------------------------------------------------------------
-- JUMP POWER
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	local hum = GetHum()
	if not hum then return end
	if jumpActive then
		hum.JumpPower = _G.N3onHub.SavedStates.jumpValue
	else
		if hum.JumpPower ~= 50 then hum.JumpPower = 50 end
	end
end)

----------------------------------------------------------------
-- INFINITE JUMP
----------------------------------------------------------------

UserInputService.JumpRequest:Connect(function()
	if not infJumpActive then return end
	local hum = GetHum()
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

----------------------------------------------------------------
-- GHOST MODE (invisível pra outros)
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	if not ghostActive then return end
	local char = GetChar()
	if not char then return end
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			pcall(function() part.LocalTransparencyModifier = 1 end)
		end
	end
end)

----------------------------------------------------------------
-- AUTO RESPAWN
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	if not autoRespawnActive then return end
	local hum = GetHum()
	if hum and hum.Health <= 0 then
		task.wait(0.5)
		Players.LocalPlayer:LoadCharacter()
	end
end)

----------------------------------------------------------------
-- CLICK TP (teleporta pro cursor)
----------------------------------------------------------------

local clickTpConn = nil

local function EnableClickTP()
	if clickTpConn then clickTpConn:Disconnect() end
	clickTpConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local hrp = GetHRP()
			if not hrp then return end
			local unitRay = workspace.CurrentCamera:ScreenPointToRay(
				input.Position.X, input.Position.Y
			)
			local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000)
			if result then
				hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
			end
		end
	end)
end

local function DisableClickTP()
	if clickTpConn then
		clickTpConn:Disconnect()
		clickTpConn = nil
	end
end

----------------------------------------------------------------
-- AUTO CLICK
----------------------------------------------------------------

local function Click()
	VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
	task.wait(0.01)
	VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

----------------------------------------------------------------
-- AUTO FARM
----------------------------------------------------------------

local function GetClosest()
	local hrp = GetHRP()
	if not hrp then return nil end

	local closest, best = nil, math.huge
	local range = _G.N3onHub.SavedStates.farmRange

	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			local tHum = plr.Character.Humanoid
			if tHum.Health > 0 then
				local d = (hrp.Position - tHRP.Position).Magnitude
				if d < best and d <= range then
					closest = plr
					best    = d
				end
			end
		end)
	end

	return closest
end

local function TweenTo(target)
	local hrp = GetHRP()
	if not hrp or not target or not target.Character then return end

	local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
	if not tHRP then return end

	local yOffset = _G.N3onHub.SavedStates.farmDistance
	local goalPos = tHRP.Position + Vector3.new(0, -yOffset, 0)
	local dist    = (hrp.Position - goalPos).Magnitude
	local dur     = math.max(dist / (_G.N3onHub.SavedStates.farmSpeed * 10), 0.05)

	activeTween = TweenService:Create(
		hrp,
		TweenInfo.new(dur, Enum.EasingStyle.Linear),
		{CFrame = CFrame.new(goalPos)}
	)
	activeTween:Play()
	activeTween.Completed:Wait()
end

local function AutoFarmLoop()
	while autoFarmActive do
		local hrp = GetHRP()
		local hum = GetHum()

		if not hrp or not hum or hum.Health <= 0 then
			task.wait(0.5)
			continue
		end

		local target = GetClosest()

		if target then
			TweenTo(target)
			local t0 = tick()
			while autoFarmActive and tick() - t0 < 0.8 do
				Click()
				task.wait(0.01)
			end
		else
			Click()
			task.wait(0.1)
		end
	end
end

----------------------------------------------------------------
-- GUI TABS
----------------------------------------------------------------

-- ======================== TAB: FARM ========================

local function LoadFarmTab()
	_G.N3onHub.GUI.Clear()
	local SC  = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size               = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text               = "👏 Farm - Slap Battles"
	title.Font               = Enum.Font.GothamBold
	title.TextScaled         = true
	title.TextColor3         = Color3.fromRGB(255, 200, 100)

	local info = Instance.new("TextLabel", SC)
	info.Size                = UDim2.new(1, 0, 0, 50)
	info.BackgroundTransparency = 1
	info.Text                = "Tween vai abaixo dos players.\nAuto Click bate automaticamente."
	info.Font                = Enum.Font.Gotham
	info.TextScaled          = true
	info.TextColor3          = Color3.fromRGB(180, 180, 180)
	info.TextXAlignment      = Enum.TextXAlignment.Left
	info.TextWrapped         = true

	-- AUTO FARM
	local lFarm = Instance.new("TextLabel", SC)
	lFarm.Size               = UDim2.new(1, 0, 0, 28)
	lFarm.BackgroundTransparency = 1
	lFarm.Text               = "⚡ Auto Farm"
	lFarm.Font               = Enum.Font.GothamBold
	lFarm.TextSize           = 15
	lFarm.TextColor3         = Color3.fromRGB(255, 200, 100)
	lFarm.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Farm (Tween + Click)", _G.N3onHub.SavedStates.autoFarm, function(v)
		_G.N3onHub.SavedStates.autoFarm = v
		autoFarmActive = v
		if v then
			spawn(AutoFarmLoop)
		else
			if activeTween then activeTween:Cancel(); activeTween = nil end
		end
	end)

	_G.N3onHub.Slider("Tween Speed", 5, 100, _G.N3onHub.SavedStates.farmSpeed, function(v)
		_G.N3onHub.SavedStates.farmSpeed = v
	end)

	_G.N3onHub.Slider("Farm Distance (Y offset)", 0, 50, _G.N3onHub.SavedStates.farmDistance, function(v)
		_G.N3onHub.SavedStates.farmDistance = v
	end)

	_G.N3onHub.Slider("Farm Range (studs)", 10, 500, _G.N3onHub.SavedStates.farmRange, function(v)
		_G.N3onHub.SavedStates.farmRange = v
	end)

	-- HITBOX EXPANDER
	local lHitbox = Instance.new("TextLabel", SC)
	lHitbox.Size               = UDim2.new(1, 0, 0, 28)
	lHitbox.BackgroundTransparency = 1
	lHitbox.Text               = "🎯 Hitbox Expander"
	lHitbox.Font               = Enum.Font.GothamBold
	lHitbox.TextSize           = 15
	lHitbox.TextColor3         = Color3.fromRGB(255, 100, 100)
	lHitbox.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Enable Hitbox", _G.N3onHub.SavedStates.hitboxEnabled, function(v)
		_G.N3onHub.SavedStates.hitboxEnabled = v
		hitboxActive = v
	end)

	_G.N3onHub.Slider("Hitbox Size", 5, 60, _G.N3onHub.SavedStates.hitboxSize, function(v)
		_G.N3onHub.SavedStates.hitboxSize = v
	end)

	_G.N3onHub.Slider("Hitbox Transparency (x10)", 1, 10, math.floor(_G.N3onHub.SavedStates.hitboxTrans * 10), function(v)
		_G.N3onHub.SavedStates.hitboxTrans = v / 10
	end)

	-- KILL AURA
	local lAura = Instance.new("TextLabel", SC)
	lAura.Size               = UDim2.new(1, 0, 0, 28)
	lAura.BackgroundTransparency = 1
	lAura.Text               = "💥 Kill Aura"
	lAura.Font               = Enum.Font.GothamBold
	lAura.TextSize           = 15
	lAura.TextColor3         = Color3.fromRGB(255, 80, 80)
	lAura.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Kill Aura", _G.N3onHub.SavedStates.auraEnabled, function(v)
		_G.N3onHub.SavedStates.auraEnabled = v
		auraActive = v
	end)

	_G.N3onHub.Slider("Aura Range (studs)", 5, 100, _G.N3onHub.SavedStates.auraSize, function(v)
		_G.N3onHub.SavedStates.auraSize = v
	end)

	-- FLING
	local lFling = Instance.new("TextLabel", SC)
	lFling.Size               = UDim2.new(1, 0, 0, 28)
	lFling.BackgroundTransparency = 1
	lFling.Text               = "🚀 Fling"
	lFling.Font               = Enum.Font.GothamBold
	lFling.TextSize           = 15
	lFling.TextColor3         = Color3.fromRGB(255, 150, 50)
	lFling.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Enable Fling", _G.N3onHub.SavedStates.flingEnabled, function(v)
		_G.N3onHub.SavedStates.flingEnabled = v
		flingActive = v
	end)

	_G.N3onHub.Slider("Fling Power", 100, 2000, _G.N3onHub.SavedStates.flingPower, function(v)
		_G.N3onHub.SavedStates.flingPower = v
	end)

	UCS()
end

-- ======================== TAB: ESP ========================

local function LoadESPTab()
	_G.N3onHub.GUI.Clear()
	local SC  = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size               = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text               = "👁️ ESP - Slap Battles"
	title.Font               = Enum.Font.GothamBold
	title.TextScaled         = true
	title.TextColor3         = Color3.fromRGB(100, 200, 255)

	_G.N3onHub.Checkbox("ESP Ativo", _G.N3onHub.SavedStates.espEnabled, function(v)
		_G.N3onHub.SavedStates.espEnabled = v
		espActive = v
		if not v then ClearAllESP() end
	end)

	_G.N3onHub.Checkbox("ESP Box (Highlight)", _G.N3onHub.SavedStates.espBoxEnabled, function(v)
		_G.N3onHub.SavedStates.espBoxEnabled = v
	end)

	_G.N3onHub.Checkbox("ESP Nome", _G.N3onHub.SavedStates.espNameEnabled, function(v)
		_G.N3onHub.SavedStates.espNameEnabled = v
	end)

	_G.N3onHub.Checkbox("ESP Distância", _G.N3onHub.SavedStates.espDistEnabled, function(v)
		_G.N3onHub.SavedStates.espDistEnabled = v
	end)

	UCS()
end

-- ======================== TAB: PLAYER ========================

local function LoadPlayerTab()
	_G.N3onHub.GUI.Clear()
	local SC  = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size               = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text               = "🧍 Player Mods"
	title.Font               = Enum.Font.GothamBold
	title.TextScaled         = true
	title.TextColor3         = Color3.fromRGB(100, 255, 200)

	-- SPEED
	local lSpeed = Instance.new("TextLabel", SC)
	lSpeed.Size               = UDim2.new(1, 0, 0, 28)
	lSpeed.BackgroundTransparency = 1
	lSpeed.Text               = "⚡ Speed"
	lSpeed.Font               = Enum.Font.GothamBold
	lSpeed.TextSize           = 15
	lSpeed.TextColor3         = Color3.fromRGB(255, 255, 100)
	lSpeed.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Speed Hack", _G.N3onHub.SavedStates.speedEnabled, function(v)
		_G.N3onHub.SavedStates.speedEnabled = v
		speedActive = v
	end)

	_G.N3onHub.Slider("WalkSpeed", 5, 200, _G.N3onHub.SavedStates.speedValue, function(v)
		_G.N3onHub.SavedStates.speedValue = v
	end)

	-- JUMP
	local lJump = Instance.new("TextLabel", SC)
	lJump.Size               = UDim2.new(1, 0, 0, 28)
	lJump.BackgroundTransparency = 1
	lJump.Text               = "🦘 Jump"
	lJump.Font               = Enum.Font.GothamBold
	lJump.TextSize           = 15
	lJump.TextColor3         = Color3.fromRGB(100, 200, 255)
	lJump.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Jump Hack", _G.N3onHub.SavedStates.jumpEnabled, function(v)
		_G.N3onHub.SavedStates.jumpEnabled = v
		jumpActive = v
	end)

	_G.N3onHub.Slider("JumpPower", 10, 300, _G.N3onHub.SavedStates.jumpValue, function(v)
		_G.N3onHub.SavedStates.jumpValue = v
	end)

	_G.N3onHub.Checkbox("Infinite Jump", _G.N3onHub.SavedStates.infiniteJump, function(v)
		_G.N3onHub.SavedStates.infiniteJump = v
		infJumpActive = v
	end)

	-- NOCLIP
	local lNoclip = Instance.new("TextLabel", SC)
	lNoclip.Size               = UDim2.new(1, 0, 0, 28)
	lNoclip.BackgroundTransparency = 1
	lNoclip.Text               = "👻 No Clip / Ghost"
	lNoclip.Font               = Enum.Font.GothamBold
	lNoclip.TextSize           = 15
	lNoclip.TextColor3         = Color3.fromRGB(200, 100, 255)
	lNoclip.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("No Clip", _G.N3onHub.SavedStates.noclipEnabled, function(v)
		_G.N3onHub.SavedStates.noclipEnabled = v
		noclipActive = v
	end)

	_G.N3onHub.Checkbox("Ghost Mode (invisível)", _G.N3onHub.SavedStates.ghostEnabled, function(v)
		_G.N3onHub.SavedStates.ghostEnabled = v
		ghostActive = v
		if not v then
			local char = GetChar()
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						pcall(function() part.LocalTransparencyModifier = 0 end)
					end
				end
			end
		end
	end)

	-- ANTI KNOCKBACK
	local lAnti = Instance.new("TextLabel", SC)
	lAnti.Size               = UDim2.new(1, 0, 0, 28)
	lAnti.BackgroundTransparency = 1
	lAnti.Text               = "🛡️ Anti Knockback"
	lAnti.Font               = Enum.Font.GothamBold
	lAnti.TextSize           = 15
	lAnti.TextColor3         = Color3.fromRGB(100, 255, 100)
	lAnti.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Anti Knockback", _G.N3onHub.SavedStates.antiKnockback, function(v)
		_G.N3onHub.SavedStates.antiKnockback = v
		antiKnockActive = v
	end)

	-- AUTO RESPAWN
	local lRespawn = Instance.new("TextLabel", SC)
	lRespawn.Size               = UDim2.new(1, 0, 0, 28)
	lRespawn.BackgroundTransparency = 1
	lRespawn.Text               = "🔄 Auto Respawn"
	lRespawn.Font               = Enum.Font.GothamBold
	lRespawn.TextSize           = 15
	lRespawn.TextColor3         = Color3.fromRGB(255, 200, 100)
	lRespawn.TextXAlignment     = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Respawn (ao morrer)", _G.N3onHub.SavedStates.autoRespawn, function(v)
		_G.N3onHub.SavedStates.autoRespawn = v
		autoRespawnActive = v
	end)

	UCS()
end

-- ======================== TAB: MISC ========================

local function LoadMiscTab()
	_G.N3onHub.GUI.Clear()
	local SC  = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size               = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text               = "⚙️ Misc"
	title.Font               = Enum.Font.GothamBold
	title.TextScaled         = true
	title.TextColor3         = Color3.fromRGB(200, 200, 200)

	-- CLICK TP
	local lCTP = Instance.new("TextLabel", SC)
	lCTP.Size               = UDim2.new(1, 0, 0, 28)
	lCTP.BackgroundTransparency = 1
	lCTP.Text               = "🖱️ Click TP"
	lCTP.Font               = Enum.Font.GothamBold
	lCTP.TextSize           = 15
	lCTP.TextColor3         = Color3.fromRGB(255, 200, 50)
	lCTP.TextXAlignment     = Enum.TextXAlignment.Left

	local ctpInfo = Instance.new("TextLabel", SC)
	ctpInfo.Size               = UDim2.new(1, 0, 0, 35)
	ctpInfo.BackgroundTransparency = 1
	ctpInfo.Text               = "Clique no chão pra teleportar pra posição."
	ctpInfo.Font               = Enum.Font.Gotham
	ctpInfo.TextScaled         = true
	ctpInfo.TextColor3         = Color3.fromRGB(160, 160, 160)
	ctpInfo.TextXAlignment     = Enum.TextXAlignment.Left
	ctpInfo.TextWrapped        = true

	_G.N3onHub.Checkbox("Click TP", _G.N3onHub.SavedStates.clickTpEnabled, function(v)
		_G.N3onHub.SavedStates.clickTpEnabled = v
		clickTpActive = v
		if v then EnableClickTP() else DisableClickTP() end
	end)

	-- SAFE ZONE
	local lSafe = Instance.new("TextLabel", SC)
	lSafe.Size               = UDim2.new(1, 0, 0, 28)
	lSafe.BackgroundTransparency = 1
	lSafe.Text               = "🟢 Safe Zone"
	lSafe.Font               = Enum.Font.GothamBold
	lSafe.TextSize           = 15
	lSafe.TextColor3         = Color3.fromRGB(100, 255, 100)
	lSafe.TextXAlignment     = Enum.TextXAlignment.Left

	local safeInfo2 = Instance.new("TextLabel", SC)
	safeInfo2.Size               = UDim2.new(1, 0, 0, 35)
	safeInfo2.BackgroundTransparency = 1
	safeInfo2.Text               = "Plataforma criada em Y=500, Z=99999.\nNinguém consegue te alcançar lá."
	safeInfo2.Font               = Enum.Font.Gotham
	safeInfo2.TextScaled         = true
	safeInfo2.TextColor3         = Color3.fromRGB(160, 160, 160)
	safeInfo2.TextXAlignment     = Enum.TextXAlignment.Left
	safeInfo2.TextWrapped        = true

	local tpBtn = Instance.new("TextButton", SC)
	tpBtn.Size             = UDim2.new(1, 0, 0, 40)
	tpBtn.Text             = "🟢 TP to Safe Zone"
	tpBtn.Font             = Enum.Font.GothamBold
	tpBtn.TextSize         = 14
	tpBtn.BackgroundColor3 = Color3.fromRGB(30, 130, 30)
	tpBtn.TextColor3       = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpBtn)
	tpBtn.MouseButton1Click:Connect(TeleportToSafeZone)

	-- TP para jogador
	local lTPPlr = Instance.new("TextLabel", SC)
	lTPPlr.Size               = UDim2.new(1, 0, 0, 28)
	lTPPlr.BackgroundTransparency = 1
	lTPPlr.Text               = "🎯 TP para jogador mais próximo"
	lTPPlr.Font               = Enum.Font.GothamBold
	lTPPlr.TextSize           = 15
	lTPPlr.TextColor3         = Color3.fromRGB(100, 180, 255)
	lTPPlr.TextXAlignment     = Enum.TextXAlignment.Left

	local tpPlrBtn = Instance.new("TextButton", SC)
	tpPlrBtn.Size             = UDim2.new(1, 0, 0, 40)
	tpPlrBtn.Text             = "🎯 TP to Closest Player"
	tpPlrBtn.Font             = Enum.Font.GothamBold
	tpPlrBtn.TextSize         = 14
	tpPlrBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 160)
	tpPlrBtn.TextColor3       = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpPlrBtn)
	tpPlrBtn.MouseButton1Click:Connect(function()
		local target = GetClosestFling()
		if target and target.Character then
			local hrp  = GetHRP()
			local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
			if hrp and tHRP then
				hrp.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0)
			end
		end
	end)

	UCS()
end

----------------------------------------------------------------
-- REGISTER TABS
----------------------------------------------------------------

_G.N3onHub.Tab("Farm",   "👏", 160, LoadFarmTab)
_G.N3onHub.Tab("ESP",    "👁️",  160, LoadESPTab)
_G.N3onHub.Tab("Player", "🧍", 160, LoadPlayerTab)
_G.N3onHub.Tab("Misc",   "⚙️",  160, LoadMiscTab)

print("[Slap Battles Module] Loaded! Todas as features ativas.")
