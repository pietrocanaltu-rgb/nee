-- N3on Hub - Ability Wars Module (FULL)

if not _G.N3onHub then
	warn("[Ability Wars Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player           = Players.LocalPlayer

print("[Ability Wars Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------

_G.N3onHub.SavedStates.autoFarm        = false
_G.N3onHub.SavedStates.farmSpeed       = 30
_G.N3onHub.SavedStates.farmRange       = 80
_G.N3onHub.SavedStates.safeBackEnabled = false   -- vai pra safe após bater
_G.N3onHub.SavedStates.safeHitEnabled  = false   -- sai da safe, bate, volta
_G.N3onHub.SavedStates.auraEnabled     = false
_G.N3onHub.SavedStates.auraSize        = 15
_G.N3onHub.SavedStates.espEnabled      = false
_G.N3onHub.SavedStates.espBoxEnabled   = false
_G.N3onHub.SavedStates.espNameEnabled  = false
_G.N3onHub.SavedStates.espDistEnabled  = false
_G.N3onHub.SavedStates.antiKnockback   = false
_G.N3onHub.SavedStates.autoRespawn     = false
_G.N3onHub.SavedStates.clickTpEnabled  = false
_G.N3onHub.SavedStates.autoCollect     = false   -- coleta orbes/itens no chão
_G.N3onHub.SavedStates.flingEnabled    = false
_G.N3onHub.SavedStates.flingPower      = 500

----------------------------------------------------------------
-- LOCAL FLAGS
----------------------------------------------------------------

local autoFarmActive    = false
local auraActive        = false
local espActive         = false
local antiKnockActive   = false
local autoRespawnActive = false
local clickTpActive     = false
local autoCollectActive = false
local flingActive       = false

local activeTween  = nil
local farmConn     = nil
local espObjects   = {}
local clickTpConn  = nil

-- Safe Players e Target
local safePlayers      = {}
local targetFarmPlayer = nil

-- Safe Zone (plataforma criada pelo script)
local safeZonePart = nil
local safeZoneCF   = CFrame.new(0, 600, 99999)

-- Posição salva antes de sair da safe (SafeHit)
local preHitPosition = nil

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

local function IsAlive()
	local hum = GetHum()
	return hum and hum.Health > 0
end

----------------------------------------------------------------
-- REMOVER INFINITE JUMP (segurança)
----------------------------------------------------------------

if _G.InfiniteJump ~= nil then _G.InfiniteJump = false end
if _G.N3onHub and _G.N3onHub.SavedStates and _G.N3onHub.SavedStates.infiniteJump ~= nil then
	_G.N3onHub.SavedStates.infiniteJump = false
end

UserInputService.JumpRequest:Connect(function()
	local hum = GetHum()
	if hum then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		task.wait(0.05)
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
end)

----------------------------------------------------------------
-- SAFE ZONE (plataforma invisível no mapa)
----------------------------------------------------------------

local function CriarSafeZone()
	if safeZonePart then pcall(function() safeZonePart:Destroy() end) end

	safeZonePart = Instance.new("Part")
	safeZonePart.Name         = "N3onSafeZoneAW"
	safeZonePart.Size         = Vector3.new(40, 1, 40)
	safeZonePart.Anchored     = true
	safeZonePart.CanCollide   = true
	safeZonePart.BrickColor   = BrickColor.new("Cyan")
	safeZonePart.Material     = Enum.Material.SmoothPlastic
	safeZonePart.Transparency = 0.3
	safeZonePart.CFrame       = safeZoneCF
	safeZonePart.Parent       = workspace

	local bb = Instance.new("BillboardGui", safeZonePart)
	bb.Size = UDim2.fromOffset(220, 40)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true
	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "🔵 SAFE ZONE — N3onHub"
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 16
	lbl.TextColor3 = Color3.fromRGB(50, 220, 255)
	lbl.TextStrokeTransparency = 0.3
end

CriarSafeZone()

local function TeleportToSafeZone()
	local hrp = GetHRP()
	if hrp then hrp.CFrame = safeZoneCF + Vector3.new(0, 5, 0) end
end

local function IsInSafeZone()
	local hrp = GetHRP()
	if not hrp or not safeZonePart then return false end
	local dist = (hrp.Position - safeZonePart.Position).Magnitude
	return dist < 30
end

----------------------------------------------------------------
-- DETECT SAFE ZONE DO JOGO (Lobby / Starting Area)
-- Em Ability Wars existe uma área de spawn/lobby.
-- Detectamos por nome de área conhecida ou posição do spawn.
----------------------------------------------------------------

local function IsInsideGameSafe(pos)
	-- Tenta encontrar o lobby/safe zone do próprio jogo
	for _, name in ipairs({"Lobby", "SafeZone", "StartingArea", "Hub", "Safe"}) do
		local obj = workspace:FindFirstChild(name, true)
		if obj then
			local ok, bbCF, bbSize = pcall(function()
				if obj:IsA("Model") then
					return obj:GetBoundingBox()
				end
				return obj.CFrame, obj.Size
			end)
			if ok and bbCF and bbSize then
				local localPos = bbCF:PointToObjectSpace(pos)
				local half = bbSize / 2
				if math.abs(localPos.X) <= half.X
				and math.abs(localPos.Y) <= half.Y
				and math.abs(localPos.Z) <= half.Z then
					return true
				end
			end
		end
	end
	return false
end

----------------------------------------------------------------
-- CLICAR (Punch)
-- Em Ability Wars o punch é feito via Tool:Activate()
-- ou via RemoteEvent "Punch" / "Hit"
----------------------------------------------------------------

local function DoPunch()
	local char = Player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	-- Tenta via Tool equipada
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		pcall(function() tool:Activate() end)
		task.wait(0.05)
		pcall(function() tool:Deactivate() end)
		return
	end

	-- Tenta via RemoteEvent (Ability Wars usa RemoteEvents para punch)
	local remotes = {
		ReplicatedStorage:FindFirstChild("Punch"),
		ReplicatedStorage:FindFirstChild("Hit"),
		ReplicatedStorage:FindFirstChild("Attack"),
		ReplicatedStorage:FindFirstChild("Slap"),
	}
	for _, rem in ipairs(remotes) do
		if rem and rem:IsA("RemoteEvent") then
			pcall(function() rem:FireServer() end)
			return
		end
	end

	-- Fallback: procura RemoteEvent em subpastas
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		if obj:IsA("RemoteEvent") then
			local lower = obj.Name:lower()
			if lower:find("punch") or lower:find("hit") or lower:find("attack") or lower:find("slap") then
				pcall(function() obj:FireServer() end)
				return
			end
		end
	end
end

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------

local function CreateESP(plr)
	if espObjects[plr.Name] then return end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(0, 180, 255)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(160, 55)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true

	local nameLabel = Instance.new("TextLabel", billboard)
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Color3.fromRGB(50, 200, 255)
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
		distLabel = distLabel,
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

			if _G.N3onHub.SavedStates.espBoxEnabled then
				obj.highlight.Adornee = char
				obj.highlight.Parent  = char
			else
				obj.highlight.Parent = nil
			end

			obj.billboard.Adornee = tHRP
			obj.billboard.Parent  = tHRP
			obj.nameLabel.Visible = _G.N3onHub.SavedStates.espNameEnabled
			obj.nameLabel.Text    = plr.Name
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
			local dist = (hrp.Position - tHRP.Position).Magnitude
			if dist <= _G.N3onHub.SavedStates.auraSize then
				DoPunch()
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
		bv.Velocity  = (tHRP.Position - hrp.Position).Unit * _G.N3onHub.SavedStates.flingPower
		bv.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
		bv.P         = 1e9
		bv.Parent    = tHRP
		task.delay(0.1, function() bv:Destroy() end)
	end)
end

RunService.Heartbeat:Connect(function()
	if not flingActive then return end
	FlingTarget(GetClosestPlayer())
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
			local ray = workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
			local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
			if result then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
		end
	end)
end

local function DisableClickTP()
	if clickTpConn then clickTpConn:Disconnect(); clickTpConn = nil end
end

----------------------------------------------------------------
-- AUTO COLLECT (orbes / power-ups no chão)
----------------------------------------------------------------

RunService.Heartbeat:Connect(function()
	if not autoCollectActive then return end
	local hrp = GetHRP()
	if not hrp then return end

	local keywords = {"orb", "powerup", "power_up", "collect", "pickup",
	                  "gem", "shard", "point", "boost", "coin", "token"}

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") or obj:IsA("Model") then
			local lower = obj.Name:lower()
			for _, kw in ipairs(keywords) do
				if lower:find(kw) then
					pcall(function()
						local pos = obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position or obj.Position
						if pos and (hrp.Position - pos).Magnitude < 60 then
							hrp.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
						end
					end)
					break
				end
			end
		end
	end
end)

----------------------------------------------------------------
-- TARGETS
----------------------------------------------------------------

local function GetTargets()
	local hrp = GetHRP()
	if not hrp then return {} end
	local range = _G.N3onHub.SavedStates.farmRange

	-- Modo Target Farm
	if targetFarmPlayer then
		local tPlr = Players:FindFirstChild(targetFarmPlayer)
		if tPlr and tPlr ~= Player and tPlr.Character then
			local tHRP = tPlr.Character:FindFirstChild("HumanoidRootPart")
			local tHum = tPlr.Character:FindFirstChild("Humanoid")
			if tHRP and tHum and tHum.Health > 0 then
				return {tPlr}
			end
		end
		return {}
	end

	-- Modo Normal
	local list = {}
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		if safePlayers[plr.Name] then continue end
		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			local tHum = plr.Character.Humanoid
			if IsInsideGameSafe(tHRP.Position) then return end
			if tHum.Health > 0 then
				local d = (hrp.Position - tHRP.Position).Magnitude
				if d <= range then
					table.insert(list, {plr = plr, dist = d})
				end
			end
		end)
	end

	table.sort(list, function(a, b) return a.dist < b.dist end)
	local result = {}
	for _, e in ipairs(list) do table.insert(result, e.plr) end
	return result
end

----------------------------------------------------------------
-- TWEEN CONTÍNUO
----------------------------------------------------------------

local function StartContinuousTween(goalGetter, lookGetter)
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

		if not activeTween or activeTween.PlaybackState ~= Enum.PlaybackState.Playing then
			local dist = (hrp.Position - goalPos).Magnitude
			local dur  = math.max(dist / (_G.N3onHub.SavedStates.farmSpeed * 10), 0.05)

			local goalCF
			if lookGetter then
				local lookPos = lookGetter()
				if lookPos then
					local flat = Vector3.new(lookPos.X, goalPos.Y, lookPos.Z)
					if (flat - goalPos).Magnitude > 0.01 then
						goalCF = CFrame.lookAt(goalPos, flat)
					else
						goalCF = CFrame.new(goalPos)
					end
				else
					goalCF = CFrame.new(goalPos)
				end
			else
				goalCF = CFrame.new(goalPos)
			end

			activeTween = TweenService:Create(
				hrp,
				TweenInfo.new(dur, Enum.EasingStyle.Linear),
				{CFrame = goalCF}
			)
			activeTween:Play()
		end
	end)
end

local function StopContinuousTween()
	if farmConn then farmConn:Disconnect(); farmConn = nil end
	if activeTween then activeTween:Cancel(); activeTween = nil end
end

----------------------------------------------------------------
-- AUTO FARM LOOP (com Safe Back opcional)
--
-- MODO SAFE BACK: bate no target → tp de volta pra safe zone
-- MODO SAFE HIT:  sai da safe → bate → volta pra safe
-- MODO NORMAL:    segue e bate nos targets normalmente
----------------------------------------------------------------

local function AutoFarmLoop()
	local farmTimer   = tick()
	local farmIndex   = 1
	local totalClicks = 0
	local onPause     = false

	while autoFarmActive do

		-- pausa anti-kick a cada 5s
		if not onPause and tick() - farmTimer >= 5 then
			onPause = true
			StopContinuousTween()
			local h = GetHRP()
			if h then h.Anchored = true end
			task.wait(1.5)
			local h2 = GetHRP()
			if h2 then h2.Anchored = false end
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

		-- ── MODO SAFE HIT ──────────────────────────────────────
		-- Sai da safe, bate em alguém, volta
		if _G.N3onHub.SavedStates.safeHitEnabled then
			-- verifica se tem alguém pra bater
			local targets = GetTargets()
			if #targets == 0 then
				TeleportToSafeZone()
				task.wait(1)
				continue
			end

			local target = targets[1]
			local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			if not tHRP then task.wait(0.1) continue end

			-- sai da safe (tp perto do target)
			local behind = (tHRP.CFrame * CFrame.new(0, 0, 3)).Position
			hrp.CFrame = CFrame.new(Vector3.new(behind.X, tHRP.Position.Y, behind.Z))
			task.wait(0.05)

			-- bate
			DoPunch()
			totalClicks = totalClicks + 1
			task.wait(math.random(8, 15) / 100)

			-- volta pra safe
			TeleportToSafeZone()
			task.wait(math.random(15, 30) / 100)
			continue
		end

		-- ── MODO SAFE BACK ─────────────────────────────────────
		-- Move até o target, bate, tp pra safe
		if _G.N3onHub.SavedStates.safeBackEnabled then
			local targets = GetTargets()
			if #targets == 0 then
				StopContinuousTween()
				task.wait(0.1)
				continue
			end

			if farmIndex > #targets then farmIndex = 1 end
			local target = targets[farmIndex]

			-- tween até o target
			StartContinuousTween(
				function()
					local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
					if t then
						local behind = (t.CFrame * CFrame.new(0, 0, 3)).Position
						return Vector3.new(behind.X, t.Position.Y, behind.Z)
					end
				end,
				function()
					local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
					if t then return t.Position end
				end
			)

			-- espera chegar
			local arrive = tick()
			while autoFarmActive and tick() - arrive < 2 do
				local h2 = GetHRP()
				local t  = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				if h2 and t and (h2.Position - t.Position).Magnitude < 6 then break end
				task.wait(0.05)
			end

			StopContinuousTween()
			task.wait(math.random(5, 12) / 100)

			-- bate
			DoPunch()
			totalClicks = totalClicks + 1
			task.wait(math.random(5, 12) / 100)

			-- tp de volta pra safe
			TeleportToSafeZone()
			task.wait(math.random(20, 40) / 100)

			farmIndex = (farmIndex % #targets) + 1
			continue
		end

		-- ── MODO NORMAL ────────────────────────────────────────
		local targets = GetTargets()

		if #targets == 0 then
			farmIndex = 1
			StopContinuousTween()
			task.wait(0.1)
			continue
		end

		if farmIndex > #targets then farmIndex = 1 end
		local target = targets[farmIndex]

		StartContinuousTween(
			function()
				local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				if t then
					local behind = (t.CFrame * CFrame.new(0, 0, 3)).Position
					return Vector3.new(behind.X, t.Position.Y, behind.Z)
				end
			end,
			function()
				local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
				if t then return t.Position end
			end
		)

		local arrive = tick()
		while autoFarmActive and tick() - arrive < 2 do
			local h2 = GetHRP()
			local t  = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			if h2 and t and (h2.Position - t.Position).Magnitude < 5 then break end
			task.wait(0.05)
		end

		task.wait(math.random(8, 20) / 100)
		DoPunch()
		totalClicks = totalClicks + 1
		task.wait(math.random(8, 20) / 100)

		if totalClicks % 5 == 0 then
			StopContinuousTween()
			task.wait(0.8)
		end

		farmIndex = (farmIndex % #targets) + 1
	end

	StopContinuousTween()
end

----------------------------------------------------------------
-- HELPER: dropdown multi-select (Safe Players)
----------------------------------------------------------------

local function CreatePlayerDropdown(parent, label, color, getChecked, onSelect)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, 0, 0, 36)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BorderSizePixel = 0
	Instance.new("UICorner", container)

	local header = Instance.new("TextButton", container)
	header.Size = UDim2.new(1, 0, 0, 36)
	header.BackgroundColor3 = color
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Text = "▼  " .. label
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.AutoButtonColor = false
	Instance.new("UICorner", header)
	local hp = Instance.new("UIPadding", header)
	hp.PaddingLeft = UDim.new(0, 10)

	local itemList = Instance.new("Frame", container)
	itemList.Size = UDim2.new(1, 0, 0, 0)
	itemList.Position = UDim2.new(0, 0, 0, 36)
	itemList.BackgroundTransparency = 1
	itemList.ClipsDescendants = true
	local ll = Instance.new("UIListLayout", itemList)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Padding = UDim.new(0, 2)

	local isOpen = false

	local function Rebuild()
		for _, ch in ipairs(itemList:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local plrs = Players:GetPlayers()
		table.sort(plrs, function(a, b) return a.Name < b.Name end)
		for _, plr in ipairs(plrs) do
			if plr == Player then continue end
			local row = Instance.new("TextButton", itemList)
			row.Size = UDim2.new(1, -4, 0, 30)
			row.Font = Enum.Font.Gotham
			row.TextSize = 13
			row.TextColor3 = Color3.new(1, 1, 1)
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.AutoButtonColor = false
			Instance.new("UICorner", row)
			local rp = Instance.new("UIPadding", row)
			rp.PaddingLeft = UDim.new(0, 10)
			local checked = getChecked(plr.Name)
			row.Text = (checked and "☑  " or "☐  ") .. plr.Name
			row.BackgroundColor3 = checked and Color3.fromRGB(40, 80, 50) or Color3.fromRGB(40, 40, 40)
			row.MouseButton1Click:Connect(function()
				onSelect(plr.Name, not getChecked(plr.Name))
				local nc = getChecked(plr.Name)
				row.Text = (nc and "☑  " or "☐  ") .. plr.Name
				row.BackgroundColor3 = nc and Color3.fromRGB(40, 80, 50) or Color3.fromRGB(40, 40, 40)
			end)
		end
		local count = #itemList:GetChildren() - 1
		local h = math.max(count * 32, 0)
		itemList.Size = UDim2.new(1, 0, 0, h)
		container.Size = UDim2.new(1, 0, 0, 36 + (isOpen and h or 0))
	end

	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			Rebuild()
			header.Text = "▲  " .. label
		else
			header.Text = "▼  " .. label
			itemList.Size = UDim2.new(1, 0, 0, 0)
			container.Size = UDim2.new(1, 0, 0, 36)
		end
	end)

	return container
end

----------------------------------------------------------------
-- HELPER: dropdown single-select (Target Farm)
----------------------------------------------------------------

local function CreateSingleSelectDropdown(parent, label, color, getSelected, onSelect)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, 0, 0, 36)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BorderSizePixel = 0
	Instance.new("UICorner", container)

	local header = Instance.new("TextButton", container)
	header.Size = UDim2.new(1, 0, 0, 36)
	header.BackgroundColor3 = color
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextColor3 = Color3.new(1, 1, 1)
	header.AutoButtonColor = false
	Instance.new("UICorner", header)
	local hp = Instance.new("UIPadding", header)
	hp.PaddingLeft = UDim.new(0, 10)

	local function UpdateHeader()
		local sel = getSelected()
		header.Text = "▼  " .. label .. (sel and (": " .. sel) or "")
	end
	UpdateHeader()

	local itemList = Instance.new("Frame", container)
	itemList.Size = UDim2.new(1, 0, 0, 0)
	itemList.Position = UDim2.new(0, 0, 0, 36)
	itemList.BackgroundTransparency = 1
	itemList.ClipsDescendants = true
	local ll = Instance.new("UIListLayout", itemList)
	ll.Padding = UDim.new(0, 2)

	local isOpen = false

	local function Rebuild()
		for _, ch in ipairs(itemList:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end

		local noneRow = Instance.new("TextButton", itemList)
		noneRow.Size = UDim2.new(1, -4, 0, 30)
		noneRow.BackgroundColor3 = getSelected() == nil and Color3.fromRGB(80, 30, 30) or Color3.fromRGB(40, 40, 40)
		noneRow.Font = Enum.Font.GothamBold
		noneRow.TextSize = 13
		noneRow.TextColor3 = Color3.fromRGB(255, 120, 120)
		noneRow.Text = "✕  Nenhum (desativar)"
		noneRow.TextXAlignment = Enum.TextXAlignment.Left
		noneRow.AutoButtonColor = false
		Instance.new("UICorner", noneRow)
		local np = Instance.new("UIPadding", noneRow)
		np.PaddingLeft = UDim.new(0, 10)
		noneRow.MouseButton1Click:Connect(function()
			onSelect(nil); UpdateHeader(); Rebuild()
		end)

		local plrs = Players:GetPlayers()
		table.sort(plrs, function(a, b) return a.Name < b.Name end)
		for _, plr in ipairs(plrs) do
			if plr == Player then continue end
			local isSel = getSelected() == plr.Name
			local row = Instance.new("TextButton", itemList)
			row.Size = UDim2.new(1, -4, 0, 30)
			row.BackgroundColor3 = isSel and Color3.fromRGB(40, 70, 110) or Color3.fromRGB(40, 40, 40)
			row.Font = Enum.Font.Gotham
			row.TextSize = 13
			row.TextColor3 = Color3.new(1, 1, 1)
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.AutoButtonColor = false
			Instance.new("UICorner", row)
			local rp = Instance.new("UIPadding", row)
			rp.PaddingLeft = UDim.new(0, 10)
			row.Text = (isSel and "◉  " or "○  ") .. plr.Name
			row.MouseButton1Click:Connect(function()
				onSelect(getSelected() == plr.Name and nil or plr.Name)
				UpdateHeader(); Rebuild()
			end)
		end

		local count = #itemList:GetChildren() - 1
		local h = math.max(count * 32, 0)
		itemList.Size = UDim2.new(1, 0, 0, h)
		container.Size = UDim2.new(1, 0, 0, 36 + (isOpen and h or 0))
	end

	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			Rebuild()
			header.Text = "▲  " .. label .. (getSelected() and (": " .. getSelected()) or "")
		else
			UpdateHeader()
			itemList.Size = UDim2.new(1, 0, 0, 0)
			container.Size = UDim2.new(1, 0, 0, 36)
		end
	end)

	return container
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
	title.Text = "👊 Farm - Ability Wars"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(50, 200, 255)

	-- AUTO FARM
	local lFarm = Instance.new("TextLabel", SC)
	lFarm.Size = UDim2.new(1, 0, 0, 28)
	lFarm.BackgroundTransparency = 1
	lFarm.Text = "⚡ Auto Farm (Punches)"
	lFarm.Font = Enum.Font.GothamBold
	lFarm.TextSize = 15
	lFarm.TextColor3 = Color3.fromRGB(50, 200, 255)
	lFarm.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Farm", _G.N3onHub.SavedStates.autoFarm, function(v)
		_G.N3onHub.SavedStates.autoFarm = v
		autoFarmActive = v
		if v then
			spawn(AutoFarmLoop)
		else
			StopContinuousTween()
		end
	end)

	_G.N3onHub.Slider("Tween Speed", 5, 100, _G.N3onHub.SavedStates.farmSpeed, function(v)
		_G.N3onHub.SavedStates.farmSpeed = v
	end)

	_G.N3onHub.Slider("Farm Range (studs)", 10, 200, _G.N3onHub.SavedStates.farmRange, function(v)
		_G.N3onHub.SavedStates.farmRange = v
	end)

	-- MODOS SAFE
	local lSafeMode = Instance.new("TextLabel", SC)
	lSafeMode.Size = UDim2.new(1, 0, 0, 28)
	lSafeMode.BackgroundTransparency = 1
	lSafeMode.Text = "🔵 Modos Safe Zone"
	lSafeMode.Font = Enum.Font.GothamBold
	lSafeMode.TextSize = 15
	lSafeMode.TextColor3 = Color3.fromRGB(50, 220, 255)
	lSafeMode.TextXAlignment = Enum.TextXAlignment.Left

	local safeDesc1 = Instance.new("TextLabel", SC)
	safeDesc1.Size = UDim2.new(1, 0, 0, 34)
	safeDesc1.BackgroundTransparency = 1
	safeDesc1.Text = "Safe Back: vai até o player, bate e TPA de volta pra safe."
	safeDesc1.Font = Enum.Font.Gotham
	safeDesc1.TextSize = 11
	safeDesc1.TextColor3 = Color3.fromRGB(160, 160, 160)
	safeDesc1.TextXAlignment = Enum.TextXAlignment.Left
	safeDesc1.TextWrapped = true

	_G.N3onHub.Checkbox("Safe Back (bate → volta pra safe)", _G.N3onHub.SavedStates.safeBackEnabled, function(v)
		_G.N3onHub.SavedStates.safeBackEnabled = v
		if v then _G.N3onHub.SavedStates.safeHitEnabled = false end  -- mutuamente exclusivos
	end)

	local safeDesc2 = Instance.new("TextLabel", SC)
	safeDesc2.Size = UDim2.new(1, 0, 0, 34)
	safeDesc2.BackgroundTransparency = 1
	safeDesc2.Text = "Safe Hit: TPA até o player, bate, TPA de volta (mais rápido, sem tween)."
	safeDesc2.Font = Enum.Font.Gotham
	safeDesc2.TextSize = 11
	safeDesc2.TextColor3 = Color3.fromRGB(160, 160, 160)
	safeDesc2.TextXAlignment = Enum.TextXAlignment.Left
	safeDesc2.TextWrapped = true

	_G.N3onHub.Checkbox("Safe Hit (TP → bate → TP)", _G.N3onHub.SavedStates.safeHitEnabled, function(v)
		_G.N3onHub.SavedStates.safeHitEnabled = v
		if v then _G.N3onHub.SavedStates.safeBackEnabled = false end  -- mutuamente exclusivos
	end)

	-- SAFE PLAYERS
	local lSafe = Instance.new("TextLabel", SC)
	lSafe.Size = UDim2.new(1, 0, 0, 28)
	lSafe.BackgroundTransparency = 1
	lSafe.Text = "🛡️ Safe Players"
	lSafe.Font = Enum.Font.GothamBold
	lSafe.TextSize = 15
	lSafe.TextColor3 = Color3.fromRGB(100, 255, 130)
	lSafe.TextXAlignment = Enum.TextXAlignment.Left

	local safeInfo = Instance.new("TextLabel", SC)
	safeInfo.Size = UDim2.new(1, 0, 0, 22)
	safeInfo.BackgroundTransparency = 1
	safeInfo.Text = "Players marcados NÃO serão atacados."
	safeInfo.Font = Enum.Font.Gotham
	safeInfo.TextSize = 11
	safeInfo.TextColor3 = Color3.fromRGB(160, 160, 160)
	safeInfo.TextXAlignment = Enum.TextXAlignment.Left
	safeInfo.TextWrapped = true

	CreatePlayerDropdown(
		SC, "Safe Players", Color3.fromRGB(30, 90, 50),
		function(name) return safePlayers[name] == true end,
		function(name, checked) safePlayers[name] = checked or nil end
	)

	-- TARGET FARM
	local lTarget = Instance.new("TextLabel", SC)
	lTarget.Size = UDim2.new(1, 0, 0, 28)
	lTarget.BackgroundTransparency = 1
	lTarget.Text = "🎯 Target Farm"
	lTarget.Font = Enum.Font.GothamBold
	lTarget.TextSize = 15
	lTarget.TextColor3 = Color3.fromRGB(255, 150, 50)
	lTarget.TextXAlignment = Enum.TextXAlignment.Left

	local targetInfo = Instance.new("TextLabel", SC)
	targetInfo.Size = UDim2.new(1, 0, 0, 22)
	targetInfo.BackgroundTransparency = 1
	targetInfo.Text = "Foca apenas neste player, ignora safe players."
	targetInfo.Font = Enum.Font.Gotham
	targetInfo.TextSize = 11
	targetInfo.TextColor3 = Color3.fromRGB(160, 160, 160)
	targetInfo.TextXAlignment = Enum.TextXAlignment.Left
	targetInfo.TextWrapped = true

	CreateSingleSelectDropdown(
		SC, "Target Farm", Color3.fromRGB(100, 55, 20),
		function() return targetFarmPlayer end,
		function(name) targetFarmPlayer = name end
	)

	-- AUTO COLLECT
	local sep1 = Instance.new("Frame", SC)
	sep1.Size = UDim2.new(1, 0, 0, 1)
	sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	sep1.BorderSizePixel = 0

	local lCollect = Instance.new("TextLabel", SC)
	lCollect.Size = UDim2.new(1, 0, 0, 28)
	lCollect.BackgroundTransparency = 1
	lCollect.Text = "💎 Auto Collect (Orbes / Power-ups)"
	lCollect.Font = Enum.Font.GothamBold
	lCollect.TextSize = 15
	lCollect.TextColor3 = Color3.fromRGB(255, 220, 50)
	lCollect.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Collect", _G.N3onHub.SavedStates.autoCollect, function(v)
		_G.N3onHub.SavedStates.autoCollect = v
		autoCollectActive = v
	end)

	-- KILL AURA
	local sep2 = Instance.new("Frame", SC)
	sep2.Size = UDim2.new(1, 0, 0, 1)
	sep2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	sep2.BorderSizePixel = 0

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

	_G.N3onHub.Slider("Aura Range (studs)", 3, 60, _G.N3onHub.SavedStates.auraSize, function(v)
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

	_G.N3onHub.Slider("Fling Power", 100, 3000, _G.N3onHub.SavedStates.flingPower, function(v)
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
	title.Text = "👁️ ESP - Ability Wars"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(50, 200, 255)

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
	title.Text = "⚙️ Misc - Ability Wars"
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

	_G.N3onHub.Checkbox("Auto Respawn", _G.N3onHub.SavedStates.autoRespawn, function(v)
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
	local sep1 = Instance.new("Frame", SC)
	sep1.Size = UDim2.new(1, 0, 0, 1)
	sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	sep1.BorderSizePixel = 0

	local lSafe = Instance.new("TextLabel", SC)
	lSafe.Size = UDim2.new(1, 0, 0, 28)
	lSafe.BackgroundTransparency = 1
	lSafe.Text = "🔵 Safe Zone"
	lSafe.Font = Enum.Font.GothamBold
	lSafe.TextSize = 15
	lSafe.TextColor3 = Color3.fromRGB(50, 220, 255)
	lSafe.TextXAlignment = Enum.TextXAlignment.Left

	local safeInfo = Instance.new("TextLabel", SC)
	safeInfo.Size = UDim2.new(1, 0, 0, 42)
	safeInfo.BackgroundTransparency = 1
	safeInfo.Text = "Plataforma criada em Y=600, Z=99999.\nNinguém consegue te alcançar lá.\nAtive Safe Hit ou Safe Back na aba Farm!"
	safeInfo.Font = Enum.Font.Gotham
	safeInfo.TextSize = 11
	safeInfo.TextColor3 = Color3.fromRGB(160, 160, 160)
	safeInfo.TextXAlignment = Enum.TextXAlignment.Left
	safeInfo.TextWrapped = true

	local tpSafeBtn = Instance.new("TextButton", SC)
	tpSafeBtn.Size = UDim2.new(1, 0, 0, 40)
	tpSafeBtn.Text = "🔵 TP to Safe Zone"
	tpSafeBtn.Font = Enum.Font.GothamBold
	tpSafeBtn.TextSize = 14
	tpSafeBtn.BackgroundColor3 = Color3.fromRGB(20, 100, 140)
	tpSafeBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpSafeBtn)
	tpSafeBtn.MouseButton1Click:Connect(TeleportToSafeZone)

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
			if hrp and tHRP then
				hrp.CFrame = tHRP.CFrame + Vector3.new(0, 3, 0)
			end
		end
	end)

	-- BOTÃO PUNCH MANUAL
	local sep2 = Instance.new("Frame", SC)
	sep2.Size = UDim2.new(1, 0, 0, 1)
	sep2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	sep2.BorderSizePixel = 0

	local lManual = Instance.new("TextLabel", SC)
	lManual.Size = UDim2.new(1, 0, 0, 28)
	lManual.BackgroundTransparency = 1
	lManual.Text = "👊 Punch Manual"
	lManual.Font = Enum.Font.GothamBold
	lManual.TextSize = 15
	lManual.TextColor3 = Color3.fromRGB(255, 150, 50)
	lManual.TextXAlignment = Enum.TextXAlignment.Left

	local punchBtn = Instance.new("TextButton", SC)
	punchBtn.Size = UDim2.new(1, 0, 0, 40)
	punchBtn.Text = "👊 Punch Agora"
	punchBtn.Font = Enum.Font.GothamBold
	punchBtn.TextSize = 14
	punchBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 20)
	punchBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", punchBtn)
	punchBtn.MouseButton1Click:Connect(function()
		DoPunch()
	end)

	UCS()
end

----------------------------------------------------------------
-- REGISTRAR TABS
----------------------------------------------------------------

_G.N3onHub.Tab("Farm",  "👊", 0, LoadFarmTab)
_G.N3onHub.Tab("ESP",   "👁️", 0, LoadESPTab)
_G.N3onHub.Tab("Misc",  "⚙️", 0, LoadMiscTab)

print("[Ability Wars Module] Loaded!")
