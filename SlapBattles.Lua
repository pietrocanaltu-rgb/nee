-- N3on Hub - Slap Battles Module

if not _G.N3onHub then
	warn("[Slap Battles Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local Player = Players.LocalPlayer

print("[Slap Battles Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------

_G.N3onHub.SavedStates.autoFarm      = false
_G.N3onHub.SavedStates.farmSpeed     = 30
_G.N3onHub.SavedStates.hitboxEnabled = false
_G.N3onHub.SavedStates.hitboxSize    = 15
_G.N3onHub.SavedStates.hitboxTrans   = 0.9

local autoFarmActive  = false
local hitboxActive    = false
local activeTween     = nil
local hitboxConn      = nil

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

----------------------------------------------------------------
-- SAFE ZONE (CRIADA AUTOMATICAMENTE AO CARREGAR)
----------------------------------------------------------------

local safeZone = Instance.new("Part")
safeZone.Name        = "N3onSafeZone"
safeZone.Size        = Vector3.new(30, 1, 30)
safeZone.Anchored    = true
safeZone.CanCollide  = true
safeZone.BrickColor  = BrickColor.new("Bright green")
safeZone.Material    = Enum.Material.SmoothPlastic
safeZone.Transparency = 0.4
safeZone.CFrame      = CFrame.new(0, 500, 99999)
safeZone.Parent      = workspace

local bb = Instance.new("BillboardGui", safeZone)
bb.Size         = UDim2.fromOffset(200, 40)
bb.StudsOffset  = Vector3.new(0, 4, 0)
bb.AlwaysOnTop  = true

local bbLabel = Instance.new("TextLabel", bb)
bbLabel.Size                 = UDim2.new(1, 0, 1, 0)
bbLabel.BackgroundTransparency = 1
bbLabel.Text                 = "🟢 SAFE ZONE"
bbLabel.Font                 = Enum.Font.GothamBold
bbLabel.TextSize             = 18
bbLabel.TextColor3           = Color3.new(0, 1, 0)
bbLabel.TextStrokeTransparency = 0.3

local function TeleportToSafeZone()
	local hrp = GetHRP()
	if hrp then
		hrp.CFrame = safeZone.CFrame + Vector3.new(0, 4, 0)
	end
end

----------------------------------------------------------------
-- HITBOX EXPANDER (IGUAL AO SCRIPT REFERÊNCIA)
----------------------------------------------------------------

-- RenderStepped sempre rodando, checa hitboxActive igual o original checa HitboxStatus
RunService.RenderStepped:Connect(function()
	if hitboxActive then
		for i, v in next, Players:GetPlayers() do
			if v.Name ~= Player.Name then
				pcall(function()
					v.Character.HumanoidRootPart.Size = Vector3.new(_G.N3onHub.SavedStates.hitboxSize, _G.N3onHub.SavedStates.hitboxSize, _G.N3onHub.SavedStates.hitboxSize)
					v.Character.HumanoidRootPart.Transparency = _G.N3onHub.SavedStates.hitboxTrans
					v.Character.HumanoidRootPart.BrickColor = BrickColor.new("Really black")
					v.Character.HumanoidRootPart.Material = "Neon"
					v.Character.HumanoidRootPart.CanCollide = false
				end)
			end
		end
	else
		for i, v in next, Players:GetPlayers() do
			if v.Name ~= Player.Name then
				pcall(function()
					v.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
					v.Character.HumanoidRootPart.Transparency = 1
					v.Character.HumanoidRootPart.BrickColor = BrickColor.new("Medium stone grey")
					v.Character.HumanoidRootPart.Material = "Plastic"
					v.Character.HumanoidRootPart.CanCollide = false
				end)
			end
		end
	end
end)

local function StartHitbox() hitboxActive = true end
local function StopHitbox()  hitboxActive = false end

----------------------------------------------------------------
-- AUTO CLICK
----------------------------------------------------------------

local function Click()
	VIM:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
	task.wait(0.01)
	VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

----------------------------------------------------------------
-- AUTO FARM (TWEEN Y-15 + AUTO CLICK)
----------------------------------------------------------------

local function GetClosest()
	local hrp = GetHRP()
	if not hrp then return nil end

	local closest, best = nil, math.huge

	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end

		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			local tHum = plr.Character.Humanoid

			if tHum.Health > 0 then
				local d = (hrp.Position - tHRP.Position).Magnitude
				if d < best then
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

	local goalPos = tHRP.Position + Vector3.new(0, -15, 0)
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
-- GUI TAB
----------------------------------------------------------------

local function LoadSlapBattlesFarm()
	_G.N3onHub.GUI.Clear()

	local SC  = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	-- Título
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
	info.Text                = "Tween vai Y-15 abaixo dos players.\nAuto Click bate automaticamente."
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
			if activeTween then activeTween:Cancel() activeTween = nil end
		end
	end)

	_G.N3onHub.Slider("Tween Speed", 5, 100, _G.N3onHub.SavedStates.farmSpeed, function(v)
		_G.N3onHub.SavedStates.farmSpeed = v
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
		if v then StartHitbox() else StopHitbox() end
	end)

	_G.N3onHub.Slider("Hitbox Size", 5, 60, _G.N3onHub.SavedStates.hitboxSize, function(v)
		_G.N3onHub.SavedStates.hitboxSize = v
	end)

	-- Transparency slider: 1-10 mapeado para 0.1-1.0
	_G.N3onHub.Slider("Hitbox Transparency (x10)", 1, 10, math.floor(_G.N3onHub.SavedStates.hitboxTrans * 10), function(v)
		_G.N3onHub.SavedStates.hitboxTrans = v / 10
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

	UCS()
end

----------------------------------------------------------------
-- REGISTER
----------------------------------------------------------------

_G.N3onHub.Tab("Farm", "👏", 160, LoadSlapBattlesFarm)

print("[Slap Battles Module] Loaded! Safe Zone criada automaticamente.")
