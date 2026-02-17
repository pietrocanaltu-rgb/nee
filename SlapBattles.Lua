-- N3on Hub - Slap Battles Module (FULL)

if not _G.N3onHub then
	warn("[Slap Battles Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local VIM              = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local Player           = Players.LocalPlayer

print("[Slap Battles Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
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

----------------------------------------------------------------
-- LOCAL FLAGS
----------------------------------------------------------------

local autoFarmActive    = false
local auraActive        = false
local espActive         = false
local antiKnockActive   = false
local flingActive       = false
local autoRespawnActive = false
local clickTpActive     = false

local activeTween = nil
local espObjects  = {}
local clickTpConn = nil

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

local function TeleportToSafeZone()
	local hrp = GetHRP()
	if hrp then hrp.CFrame = safeZone.CFrame + Vector3.new(0, 4, 0) end
end

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------

local function CreateESP(plr)
	if espObjects[plr.Name] then return end
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(150, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true

	local nameLabel = Instance.new("TextLabel", billboard)
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Text = plr.Name

	local distLabel = Instance.new("TextLabel", billboard)
	distLabel.Name = "DistLabel"
	distLabel.Size = UDim2.new(1, 0, 0.5, 0)
	distLabel.Position = UDim2.new(0, 0, 0.5, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 12
	distLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	distLabel.TextStrokeTransparency = 0
	distLabel.Text = "..."

	espObjects[plr.Name] = {highlight = highlight, billboard = billboard, nameLabel = nameLabel, distLabel = distLabel}
end

local function RemoveESP(name)
	if espObjects[name] then
		pcall(function() espObjects[name].highlight:Destroy() end)
		pcall(function() espObjects[name].billboard:Destroy() end)
		espObjects[name] = nil
	end
end

local function ClearAllESP()
	for name in pairs(espObjects) do RemoveESP(name) end
end

RunService.RenderStepped:Connect(function()
	if not espActive then ClearAllESP() return end
	local hrp = GetHRP()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local char = plr.Character
			if not char then RemoveESP(plr.Name) return end
			local tHRP = char:FindFirstChild("HumanoidRootPart")
			if not tHRP then RemoveESP(plr.Name) return end
			if not espObjects[plr.Name] then CreateESP(plr) end
			local obj = espObjects[plr.Name]

			if _G.N3onHub.SavedStates.espBoxEnabled then
				obj.highlight.Adornee = char
				obj.highlight.Parent = char
			else
				obj.highlight.Parent = nil
			end

			obj.billboard.Adornee = tHRP
			obj.billboard.Parent = tHRP
			obj.nameLabel.Visible = _G.N3onHub.SavedStates.espNameEnabled
			obj.nameLabel.Text = plr.Name
			obj.distLabel.Visible = _G.N3onHub.SavedStates.espDistEnabled
			if hrp then
				obj.distLabel.Text = math.floor((hrp.Position - tHRP.Position).Magnitude) .. " studs"
			end
		end)
	end
	for name in pairs(espObjects) do
		if not Players:FindFirstChild(name) then RemoveESP(name) end
	end
end)

----------------------------------------------------------------
-- KILL AURA
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	if not auraActive then return end
	local hrp = GetHRP()
	if not hrp then return end
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			if (hrp.Position - tHRP.Position).Magnitude <= _G.N3onHub.SavedStates.auraSize then
				VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
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
	pcall(function() hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0) end)
end)

----------------------------------------------------------------
-- FLING
----------------------------------------------------------------

local function GetClosestPlayer()
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

local function FlingTarget(target)
	if not target or not target.Character then return end
	local hrp = GetHRP()
	local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not tHRP then return end
	pcall(function()
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = (tHRP.Position - hrp.Position).Unit * _G.N3onHub.SavedStates.flingPower
		bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bv.P = 1e9
		bv.Parent = tHRP
		task.delay(0.1, function() bv:Destroy() end)
	end)
end

RunService.Heartbeat:Connect(function()
	if not flingActive then return end
	local target = GetClosestPlayer()
	if target then FlingTarget(target) end
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
-- CLICK TP
----------------------------------------------------------------

local function EnableClickTP()
	if clickTpConn then clickTpConn:Disconnect() end
	clickTpConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local hrp = GetHRP()
			if not hrp then return end
			local unitRay = workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
			local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000)
			if result then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
		end
	end)
end

local function DisableClickTP()
	if clickTpConn then clickTpConn:Disconnect(); clickTpConn = nil end
end

----------------------------------------------------------------
-- AUTO CLICK + AUTO FARM
----------------------------------------------------------------

local function Click()
	VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
	task.wait(0.01)
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
			end
		end
	end
	return nil
end

local function GetClosestInRange()
	local hrp = GetHRP()
	if not hrp then return nil end
	local closest, best = nil, math.huge
	local range = _G.N3onHub.SavedStates.farmRange

	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			local tHum = plr.Character.Humanoid
			-- ignora players dentro do Lobby
			if IsInsideLobby(tHRP.Position) then return end
			if tHum.Health > 0 then
				local d = (hrp.Position - tHRP.Position).Magnitude
				if d < best and d <= range then closest = plr; best = d end
			end
		end)
	end
	return closest
end

-- Tween contínuo: recria o tween sempre apontando pra posição atual do alvo
local farmConn = nil

local function StartContinuousTween(goalGetter)
	if activeTween then activeTween:Cancel(); activeTween = nil end
	if farmConn then farmConn:Disconnect(); farmConn = nil end

	farmConn = RunService.Heartbeat:Connect(function()
		if not autoFarmActive then
			if activeTween then activeTween:Cancel(); activeTween = nil end
			farmConn:Disconnect(); farmConn = nil
			return
		end

		local hrp = GetHRP()
		if not hrp then return end

		local goalPos = goalGetter()
		if not goalPos then return end

		-- Só recria o tween se não tiver um rodando ou se o alvo mudou de posição
		if not activeTween or activeTween.PlaybackState ~= Enum.PlaybackState.Playing then
			local dist = (hrp.Position - goalPos).Magnitude
			local dur = math.max(dist / (_G.N3onHub.SavedStates.farmSpeed * 10), 0.05)
			activeTween = TweenService:Create(
				hrp,
				TweenInfo.new(dur, Enum.EasingStyle.Linear),
				{CFrame = CFrame.new(goalPos)}
			)
			activeTween:Play()
		end
	end)
end

local function StopContinuousTween()
	if farmConn then farmConn:Disconnect(); farmConn = nil end
	if activeTween then activeTween:Cancel(); activeTween = nil end
end

local function AutoFarmLoop()
	local farmTimer  = tick()  -- conta os 10s ativos
	local onPause    = false

	while autoFarmActive do
		-- pausa de 3s a cada 10s
		if not onPause and tick() - farmTimer >= 10 then
			onPause = true
			StopContinuousTween()
			task.wait(3)
			onPause    = false
			farmTimer  = tick()
			continue
		end

		local hrp = GetHRP()
		local hum = GetHum()
		if not hrp or not hum or hum.Health <= 0 then
			StopContinuousTween()
			task.wait(0.5)
			continue
		end

		-- Verifica se EU estou no Lobby → vai pro Teleport1
		if IsInsideLobby(hrp.Position) then
			StopContinuousTween()
			local tpPos = GetLobbyTeleport()
			if tpPos then
				StartContinuousTween(function() return tpPos end)
			end
			task.wait(0.2)
			continue
		end

		-- Fora do lobby → persegue o player mais próximo
		local target = GetClosestInRange()
		if target and target.Character then
			local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
			if tHRP then
				StartContinuousTween(function()
					local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
					if t then
						return t.Position + Vector3.new(0, -_G.N3onHub.SavedStates.farmDistance, 0)
					end
					return nil
				end)
				local t0 = tick()
				while autoFarmActive and tick() - t0 < 0.5 do
					Click()
					task.wait(0.05)
				end
				continue
			end
		end

		-- Sem alvo → só clica
		StopContinuousTween()
		Click()
		task.wait(0.1)
	end

	StopContinuousTween()
end

----------------------------------------------------------------
-- TAB: FARM
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

	-- HITBOX via loadstring
	local lHitbox = Instance.new("TextLabel", SC)
	lHitbox.Size = UDim2.new(1, 0, 0, 28)
	lHitbox.BackgroundTransparency = 1
	lHitbox.Text = "🎯 Hitbox Expander"
	lHitbox.Font = Enum.Font.GothamBold
	lHitbox.TextSize = 15
	lHitbox.TextColor3 = Color3.fromRGB(255, 100, 100)
	lHitbox.TextXAlignment = Enum.TextXAlignment.Left

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

	hitboxBtn.MouseButton1Click:Connect(function()
		if hitboxLoaded then return end
		hitboxLoaded = true
		hitboxBtn.Text = "⏳ Carregando..."
		hitboxBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 30)
		task.spawn(function()
			pcall(function()
				loadstring(game:HttpGet("https://gist.githubusercontent.com/stellar-4242/430ef3087d8d87eb306ca03e728ffbb8/raw/798429dd908b1f4471a1fa569ff62c5e5a93ec61/SLAP.LUA"))()
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
		auraActive = v
	end)

	_G.N3onHub.Slider("Aura Range (studs)", 5, 100, _G.N3onHub.SavedStates.auraSize, function(v)
		_G.N3onHub.SavedStates.auraSize = v
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
		flingActive = v
	end)

	_G.N3onHub.Slider("Fling Power", 100, 2000, _G.N3onHub.SavedStates.flingPower, function(v)
		_G.N3onHub.SavedStates.flingPower = v
	end)

	UCS()
end

----------------------------------------------------------------
-- TAB: ESP
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

----------------------------------------------------------------
-- TAB: MISC
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

	local safeInfo = Instance.new("TextLabel", SC)
	safeInfo.Size = UDim2.new(1, 0, 0, 35)
	safeInfo.BackgroundTransparency = 1
	safeInfo.Text = "Plataforma criada em Y=500, Z=99999.\nNinguém consegue te alcançar lá."
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
		local target = GetClosestPlayer()
		if target and target.Character then
			local hrp = GetHRP()
			local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
			if hrp and tHRP then hrp.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0) end
		end
	end)

	UCS()
end

----------------------------------------------------------------
-- REGISTRAR TABS
-- O 3º argumento é ignorado pelo base (Y automático)
----------------------------------------------------------------

_G.N3onHub.Tab("Farm", "👏", 0, LoadFarmTab)
_G.N3onHub.Tab("ESP",  "👁️", 0, LoadESPTab)
_G.N3onHub.Tab("Misc", "⚙️", 0, LoadMiscTab)

print("[Slap Battles Module] Loaded!")
