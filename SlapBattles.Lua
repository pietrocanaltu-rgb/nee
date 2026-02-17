-- N3on Hub - Slap Battles Module (ADAPTADO ao Base)

-- Aguarda o Base Hub carregar (até 10s)
local tries = 0
repeat task.wait(0.5); tries += 1 until _G.N3onHub or tries >= 20

if not _G.N3onHub or not _G.N3onHub._loaded then
	warn("[Slap Battles Module] Base hub não carregado! Execute o Base Hub primeiro.")
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

	espObjects[plr.Name] = {
		highlight = highlight,
		billboard = billboard,
		nameLabel = nameLabel,
		distLabel = distLabel
	}
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

			if SS.espBoxEnabled then
				obj.highlight.Adornee = char
				obj.highlight.Parent = char
			else
				obj.highlight.Parent = nil
			end

			obj.billboard.Adornee = tHRP
			obj.billboard.Parent = tHRP
			obj.nameLabel.Visible = SS.espNameEnabled
			obj.nameLabel.Text = plr.Name
			obj.distLabel.Visible = SS.espDistEnabled
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
			if (hrp.Position - tHRP.Position).Magnitude <= SS.auraSize then
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
		bv.Velocity = (tHRP.Position - hrp.Position).Unit * SS.flingPower
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
-- AUTO FARM
----------------------------------------------------------------

local function Click()
	VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
	task.wait(0.01)
	VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function IsInsideLobby(pos)
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then return false end
	local ok, bbCF, bbSize = pcall(function() return lobby:GetBoundingBox() end)
	if not ok then return false end
	local localPos = bbCF:PointToObjectSpace(pos)
	local half = bbSize / 2
	return math.abs(localPos.X) <= half.X
		and math.abs(localPos.Y) <= half.Y
		and math.abs(localPos.Z) <= half.Z
end

local function GetLobbyTeleport()
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then return nil end
	local tp = lobby:FindFirstChild("Teleport1")
	if not tp then return nil end
	if tp:IsA("BasePart") then
		return tp.Position + Vector3.new(0, 3, 0)
	elseif tp:IsA("Model") then
		if tp.PrimaryPart then
			return tp.PrimaryPart.Position + Vector3.new(0, 3, 0)
		else
			for _, v in pairs(tp:GetDescendants()) do
				if v:IsA("BasePart") then return v.Position + Vector3.new(0, 3, 0) end
			end
		end
	end
	return nil
end

local DANGEROUS_TOOLS = {"overkill", "error", "the flex"}

local function HasDangerousTool(plr)
	local function checkName(name)
		local lower = name:lower()
		for _, t in ipairs(DANGEROUS_TOOLS) do
			if lower == t then return true end
		end
		return false
	end
	if plr.Character then
		for _, obj in pairs(plr.Character:GetChildren()) do
			if obj:IsA("Tool") and checkName(obj.Name) then return true end
		end
	end
	local bp = plr:FindFirstChild("Backpack")
	if bp then
		for _, obj in pairs(bp:GetChildren()) do
			if obj:IsA("Tool") and checkName(obj.Name) then return true end
		end
	end
	return false
end

local function GetClosestInRange()
	local hrp = GetHRP()
	if not hrp then return nil end
	local closest, best = nil, math.huge
	local range = SS.farmRange
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			local tHum = plr.Character.Humanoid
			if IsInsideLobby(tHRP.Position) then return end
			if HasDangerousTool(plr) then return end
			if tHum.Health > 0 then
				local d = (hrp.Position - tHRP.Position).Magnitude
				if d < best and d <= range then closest = plr; best = d end
			end
		end)
	end
	return closest
end

local farmConn = nil

local function StartContinuousTween(goalGetter, lookAtGetter)
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

		if lookAtGetter then
			local lookPos = lookAtGetter()
			if lookPos then
				local dir = (lookPos - hrp.Position) * Vector3.new(1, 0, 1)
				if dir.Magnitude > 0.1 then
					hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
				end
			end
		end

		if not activeTween or activeTween.PlaybackState ~= Enum.PlaybackState.Playing then
			local dist = (hrp.Position - goalPos).Magnitude
			local dur = math.max(dist / (SS.farmSpeed * 10), 0.05)
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
	local farmTimer = tick()
	local onPause   = false

	while autoFarmActive do
		if not onPause and tick() - farmTimer >= 3 then
			onPause = true
			StopContinuousTween()
			local hrpPause = GetHRP()
			if hrpPause then hrpPause.Anchored = true end
			task.wait(3)
			local hrpResume = GetHRP()
			if hrpResume then hrpResume.Anchored = false end
			onPause   = false
			farmTimer = tick()
			continue
		end

		local hrp = GetHRP()
		local hum = GetHum()
		if not hrp or not hum or hum.Health <= 0 then
			StopContinuousTween()
			task.wait(0.5)
			continue
		end

		if IsInsideLobby(hrp.Position) then
			local tpPos = GetLobbyTeleport()
			if tpPos then
				local distToTp = (hrp.Position - tpPos).Magnitude
				if distToTp > 5 then
					StartContinuousTween(function() return tpPos end, nil)
					task.wait(0.2)
				else
					StopContinuousTween()
					task.wait(3)
					farmTimer = tick()
				end
			else
				StopContinuousTween()
				task.wait(0.2)
			end
			continue
		end

		local target = GetClosestInRange()
		if target and target.Character then
			local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
			if tHRP then
				StartContinuousTween(
					function()
						local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
						if t then return t.Position + Vector3.new(0, -SS.farmDistance, 0) end
						return nil
					end,
					function()
						local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
						if t then return t.Position end
						return nil
					end
				)
				local t0 = tick()
				while autoFarmActive and tick() - t0 < 0.5 do
					Click()
					task.wait(0.05)
				end
				continue
			end
		end

		StopContinuousTween()
		Click()
		task.wait(0.1)
	end

	StopContinuousTween()
end

----------------------------------------------------------------
-- TAB: FARM
-- Usa Clear() e recria widgets direto no SC do Base Hub
----------------------------------------------------------------

local function LoadFarmTab()
	Clear()

	TitleLabel("👏 Farm - Slap Battles", Color3.fromRGB(255, 200, 100))

	SectionLabel("⚡ Auto Farm", Color3.fromRGB(255, 200, 100))

	Checkbox("Auto Farm (Tween + Click)", SS.autoFarm, function(v)
		SS.autoFarm = v
		autoFarmActive = v
		if v then
			spawn(AutoFarmLoop)
		else
			if activeTween then activeTween:Cancel(); activeTween = nil end
		end
	end)

	Slider("Tween Speed", 5, 100, SS.farmSpeed, function(v)
		SS.farmSpeed = v
	end)

	Slider("Farm Distance (Y offset)", 1, 50, SS.farmDistance, function(v)
		SS.farmDistance = v
	end)

	Slider("Farm Range (studs)", 10, 500, SS.farmRange, function(v)
		SS.farmRange = v
	end)

	SectionLabel("🎯 Hitbox Expander", Color3.fromRGB(255, 100, 100))

	local hitboxLoaded = false
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
				loadstring(game:HttpGet(
					"https://gist.githubusercontent.com/stellar-4242/430ef3087d8d87eb306ca03e728ffbb8/raw/798429dd908b1f4471a1fa569ff62c5e5a93ec61/SLAP.LUA"
				))()
			end)
			hitboxBtn.Text = "✅ Hitbox Carregado!"
			hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
		end)
	end)

	SectionLabel("💥 Kill Aura", Color3.fromRGB(255, 80, 80))

	Checkbox("Kill Aura", SS.auraEnabled, function(v)
		SS.auraEnabled = v
		auraActive = v
	end)

	Slider("Aura Range (studs)", 5, 100, SS.auraSize, function(v)
		SS.auraSize = v
	end)

	SectionLabel("🚀 Fling", Color3.fromRGB(255, 150, 50))

	Checkbox("Enable Fling", SS.flingEnabled, function(v)
		SS.flingEnabled = v
		flingActive = v
	end)

	Slider("Fling Power", 100, 2000, SS.flingPower, function(v)
		SS.flingPower = v
	end)

	UCS()
end

----------------------------------------------------------------
-- TAB: ESP
----------------------------------------------------------------

local function LoadESPTab()
	Clear()

	TitleLabel("👁️ ESP - Slap Battles", Color3.fromRGB(100, 200, 255))

	Checkbox("ESP Ativo", SS.espEnabled, function(v)
		SS.espEnabled = v
		espActive = v
		if not v then ClearAllESP() end
	end)

	Checkbox("ESP Box (Highlight)", SS.espBoxEnabled, function(v)
		SS.espBoxEnabled = v
	end)

	Checkbox("ESP Nome", SS.espNameEnabled, function(v)
		SS.espNameEnabled = v
	end)

	Checkbox("ESP Distância", SS.espDistEnabled, function(v)
		SS.espDistEnabled = v
	end)

	UCS()
end

----------------------------------------------------------------
-- TAB: MISC
----------------------------------------------------------------

local function LoadMiscTab()
	Clear()

	TitleLabel("⚙️ Misc - Slap Battles", Color3.fromRGB(200, 200, 200))

	SectionLabel("🛡️ Anti Knockback", Color3.fromRGB(100, 255, 100))

	Checkbox("Anti Knockback", SS.antiKnockback, function(v)
		SS.antiKnockback = v
		antiKnockActive = v
	end)

	SectionLabel("🔄 Auto Respawn", Color3.fromRGB(255, 200, 100))

	Checkbox("Auto Respawn (ao morrer)", SS.autoRespawn, function(v)
		SS.autoRespawn = v
		autoRespawnActive = v
	end)

	SectionLabel("🖱️ Click TP", Color3.fromRGB(255, 200, 50))

	Checkbox("Click TP (clique no chão)", SS.clickTpEnabled, function(v)
		SS.clickTpEnabled = v
		clickTpActive = v
		if v then EnableClickTP() else DisableClickTP() end
	end)

	SectionLabel("🟢 Safe Zone", Color3.fromRGB(100, 255, 100))

	local safeInfo = Instance.new("TextLabel", SC)
	safeInfo.Size = UDim2.new(1, 0, 0, 35)
	safeInfo.BackgroundTransparency = 1
	safeInfo.Text = "Plataforma em Y=500, Z=99999. Ninguém alcança lá."
	safeInfo.Font = Enum.Font.Gotham
	safeInfo.TextScaled = true
	safeInfo.TextColor3 = Color3.fromRGB(160, 160, 160)
	safeInfo.TextXAlignment = Enum.TextXAlignment.Left
	safeInfo.TextWrapped = true

	ActionButton("🟢 TP to Safe Zone", Color3.fromRGB(30, 130, 30), TeleportToSafeZone)

	ActionButton("🎯 TP to Closest Player", Color3.fromRGB(30, 80, 160), function()
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
-- REGISTRAR TABS na sidebar (F2) do Base Hub
----------------------------------------------------------------

Tab("Farm", "👏", 0, LoadFarmTab)
Tab("ESP",  "👁️", 0, LoadESPTab)
Tab("Misc", "⚙️", 0, LoadMiscTab)

print("[Slap Battles Module] Loaded!")
