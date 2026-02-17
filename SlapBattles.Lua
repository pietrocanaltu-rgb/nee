-- N3on Hub - Slap Battles Module
-- Funcionalidades exclusivas para Slap Battles

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

_G.N3onHub.SavedStates.autoFarm = false
_G.N3onHub.SavedStates.farmSpeed = 30
_G.N3onHub.SavedStates.hitboxEnabled = false
_G.N3onHub.SavedStates.hitboxSize = 15
_G.N3onHub.SavedStates.hitboxTransparency = 0.9
_G.N3onHub.SavedStates.teamCheck = false

local autoFarmActive = false
local hitboxActive = false
local safeZonePart = nil
local activeTween = nil
local hitboxConnection = nil

----------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------

local function GetHRP()
	local char = Player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
	local char = Player.Character
	return char and char:FindFirstChild("Humanoid")
end

----------------------------------------------------------------
-- HITBOX EXPANDER (IGUAL AO SCRIPT REFERÊNCIA)
----------------------------------------------------------------

local function StartHitbox()
	hitboxConnection = RunService.RenderStepped:Connect(function()
		if not hitboxActive then return end

		for _, plr in pairs(Players:GetPlayers()) do
			if plr == Player then continue end

			-- Team check
			if _G.N3onHub.SavedStates.teamCheck then
				if Player.Team == plr.Team then continue end
			end

			pcall(function()
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local s = _G.N3onHub.SavedStates.hitboxSize
					hrp.Size = Vector3.new(s, s, s)
					hrp.Transparency = _G.N3onHub.SavedStates.hitboxTransparency
					hrp.BrickColor = BrickColor.new("Really black")
					hrp.Material = Enum.Material.Neon
					hrp.CanCollide = false
				end
			end)
		end
	end)
end

local function StopHitbox()
	if hitboxConnection then
		hitboxConnection:Disconnect()
		hitboxConnection = nil
	end

	-- Restaurar HRPs
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.Size = Vector3.new(2, 2, 1)
				hrp.Transparency = 1
				hrp.BrickColor = BrickColor.new("Medium stone grey")
				hrp.Material = Enum.Material.Plastic
				hrp.CanCollide = false
			end
		end)
	end
end

----------------------------------------------------------------
-- AUTO CLICK
----------------------------------------------------------------

local function SimulateClick()
	VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
	task.wait(0.01)
	VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

----------------------------------------------------------------
-- AUTO FARM (TWEEN + AUTO CLICK)
----------------------------------------------------------------

local function GetClosestPlayer()
	local hrp = GetHRP()
	if not hrp then return nil end

	local closest, closestDist = nil, math.huge

	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end

		pcall(function()
			local tHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local tHum = plr.Character and plr.Character:FindFirstChild("Humanoid")

			if tHRP and tHum and tHum.Health > 0 then
				local dist = (hrp.Position - tHRP.Position).Magnitude
				if dist < closestDist then
					closest = plr
					closestDist = dist
				end
			end
		end)
	end

	return closest
end

local function TweenToTarget(target)
	local hrp = GetHRP()
	if not hrp or not target or not target.Character then return false end

	local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
	if not tHRP then return false end

	-- Posição: mesma X/Z do target, mas Y = target.Y - 15 (embaixo)
	local targetPos = tHRP.Position + Vector3.new(0, -15, 0)
	local dist = (hrp.Position - targetPos).Magnitude
	local duration = dist / (_G.N3onHub.SavedStates.farmSpeed * 10)

	activeTween = TweenService:Create(
		hrp,
		TweenInfo.new(math.max(duration, 0.05), Enum.EasingStyle.Linear),
		{CFrame = CFrame.new(targetPos)}
	)

	activeTween:Play()
	activeTween.Completed:Wait()
	return true
end

local function AutoFarmLoop()
	while autoFarmActive do
		local hrp = GetHRP()
		local hum = GetHum()

		if not hrp or not hum or hum.Health <= 0 then
			task.wait(0.5)
			continue
		end

		local target = GetClosestPlayer()

		if target then
			-- Tween até o target (Y -15)
			TweenToTarget(target)

			-- Auto click rápido enquanto está perto
			local startTime = tick()
			while autoFarmActive and tick() - startTime < 0.8 do
				SimulateClick()
				task.wait(0.01)
			end
		else
			-- Sem targets, só clica
			SimulateClick()
			task.wait(0.1)
		end
	end
end

----------------------------------------------------------------
-- SAFE ZONE
----------------------------------------------------------------

local function CreateSafeZone()
	-- Remove parte antiga se existir
	if safeZonePart and safeZonePart.Parent then
		safeZonePart:Destroy()
	end

	-- Criar parte longe do spawn
	local part = Instance.new("Part")
	part.Size = Vector3.new(20, 1, 20)
	part.Anchored = true
	part.CanCollide = true
	part.BrickColor = BrickColor.new("Bright green")
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 0.5
	part.Name = "N3onSafeZone"
	-- Posição bem longe do mapa principal
	part.CFrame = CFrame.new(0, 100, 9999)
	part.Parent = workspace

	-- Placa
	local billboard = Instance.new("BillboardGui", part)
	billboard.Size = UDim2.fromOffset(200, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel", billboard)
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "🟢 SAFE ZONE"
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.new(0, 1, 0)
	label.TextStrokeTransparency = 0.3

	safeZonePart = part
end

local function TeleportToSafeZone()
	local hrp = GetHRP()
	if not hrp then return end

	-- Criar safe zone se não existir
	if not safeZonePart or not safeZonePart.Parent then
		CreateSafeZone()
	end

	hrp.CFrame = safeZonePart.CFrame + Vector3.new(0, 3, 0)
end

----------------------------------------------------------------
-- LOAD SLAP BATTLES FARM TAB
----------------------------------------------------------------

local function LoadSlapBattlesFarm()
	_G.N3onHub.GUI.Clear()

	local ScrollContent = _G.N3onHub.GUI.ScrollContent
	local UpdateCanvasSize = _G.N3onHub.GUI.UpdateCanvasSize

	-- Título
	local title = Instance.new("TextLabel", ScrollContent)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "👏 Farm - Slap Battles"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 100)

	-- Info
	local info = Instance.new("TextLabel", ScrollContent)
	info.Size = UDim2.new(1, 0, 0, 60)
	info.BackgroundTransparency = 1
	info.Text = "Tween vai até os players (Y -15).\nAuto Click bate neles automaticamente."
	info.Font = Enum.Font.Gotham
	info.TextScaled = true
	info.TextColor3 = Color3.fromRGB(200, 200, 200)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextWrapped = true

	-- === AUTO FARM ===
	local farmTitle = Instance.new("TextLabel", ScrollContent)
	farmTitle.Size = UDim2.new(1, 0, 0, 30)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "⚡ Auto Farm"
	farmTitle.Font = Enum.Font.GothamBold
	farmTitle.TextSize = 15
	farmTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
	farmTitle.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Farm (Tween + Click)", _G.N3onHub.SavedStates.autoFarm, function(v)
		_G.N3onHub.SavedStates.autoFarm = v
		autoFarmActive = v
		if v then
			spawn(function()
				AutoFarmLoop()
			end)
		else
			if activeTween then
				activeTween:Cancel()
				activeTween = nil
			end
		end
	end)

	_G.N3onHub.Slider("Tween Speed", 5, 100, _G.N3onHub.SavedStates.farmSpeed, function(v)
		_G.N3onHub.SavedStates.farmSpeed = v
	end)

	-- === HITBOX EXPANDER ===
	local hitboxTitle = Instance.new("TextLabel", ScrollContent)
	hitboxTitle.Size = UDim2.new(1, 0, 0, 30)
	hitboxTitle.BackgroundTransparency = 1
	hitboxTitle.Text = "🎯 Hitbox Expander"
	hitboxTitle.Font = Enum.Font.GothamBold
	hitboxTitle.TextSize = 15
	hitboxTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
	hitboxTitle.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Enable Hitbox", _G.N3onHub.SavedStates.hitboxEnabled, function(v)
		_G.N3onHub.SavedStates.hitboxEnabled = v
		hitboxActive = v
		if v then
			StartHitbox()
		else
			StopHitbox()
		end
	end)

	_G.N3onHub.Checkbox("Team Check", _G.N3onHub.SavedStates.teamCheck, function(v)
		_G.N3onHub.SavedStates.teamCheck = v
	end)

	_G.N3onHub.Slider("Hitbox Size", 5, 60, _G.N3onHub.SavedStates.hitboxSize, function(v)
		_G.N3onHub.SavedStates.hitboxSize = v
	end)

	_G.N3onHub.Slider("Hitbox Transparency", 1, 10, math.floor(_G.N3onHub.SavedStates.hitboxTransparency * 10), function(v)
		_G.N3onHub.SavedStates.hitboxTransparency = v / 10
	end)

	-- === SAFE ZONE ===
	local safeTitle = Instance.new("TextLabel", ScrollContent)
	safeTitle.Size = UDim2.new(1, 0, 0, 30)
	safeTitle.BackgroundTransparency = 1
	safeTitle.Text = "🟢 Safe Zone"
	safeTitle.Font = Enum.Font.GothamBold
	safeTitle.TextSize = 15
	safeTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
	safeTitle.TextXAlignment = Enum.TextXAlignment.Left

	local safeInfo = Instance.new("TextLabel", ScrollContent)
	safeInfo.Size = UDim2.new(1, 0, 0, 40)
	safeInfo.BackgroundTransparency = 1
	safeInfo.Text = "Cria uma plataforma longe do mapa.\nNinguém consegue te alcançar lá."
	safeInfo.Font = Enum.Font.Gotham
	safeInfo.TextScaled = true
	safeInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
	safeInfo.TextXAlignment = Enum.TextXAlignment.Left
	safeInfo.TextWrapped = true

	local createBtn = Instance.new("TextButton", ScrollContent)
	createBtn.Size = UDim2.new(1, 0, 0, 40)
	createBtn.Text = "🔨 Create Safe Zone"
	createBtn.Font = Enum.Font.GothamBold
	createBtn.TextSize = 14
	createBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
	createBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", createBtn)

	createBtn.MouseButton1Click:Connect(function()
		CreateSafeZone()
		createBtn.Text = "✅ Safe Zone Created!"
		task.wait(2)
		createBtn.Text = "🔨 Create Safe Zone"
	end)

	local tpBtn = Instance.new("TextButton", ScrollContent)
	tpBtn.Size = UDim2.new(1, 0, 0, 40)
	tpBtn.Text = "🟢 TP to Safe Zone"
	tpBtn.Font = Enum.Font.GothamBold
	tpBtn.TextSize = 14
	tpBtn.BackgroundColor3 = Color3.fromRGB(30, 130, 30)
	tpBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpBtn)

	tpBtn.MouseButton1Click:Connect(TeleportToSafeZone)

	UpdateCanvasSize()
end

----------------------------------------------------------------
-- REGISTER TAB
----------------------------------------------------------------

_G.N3onHub.Tab("Farm", "👏", 160, LoadSlapBattlesFarm)

print("[Slap Battles Module] Loaded!")
print("Features: Auto Farm (Tween + AutoClick), Hitbox Expander, Safe Zone")
