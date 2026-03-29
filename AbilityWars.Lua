-- N3on Hub - Ability Wars Module (FIXED v2)

if not _G.N3onHub then
	warn("[Ability Wars Module] Base hub not loaded!")
	return
end

local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local VIM               = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player            = Players.LocalPlayer
local Mouse             = Player:GetMouse()

print("[Ability Wars v2] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------
_G.N3onHub.SavedStates.autoFarm        = false
_G.N3onHub.SavedStates.farmSpeed       = 40
_G.N3onHub.SavedStates.farmRange       = 80
_G.N3onHub.SavedStates.safeBackEnabled = false
_G.N3onHub.SavedStates.safeHitEnabled  = false
_G.N3onHub.SavedStates.auraEnabled     = false
_G.N3onHub.SavedStates.auraSize        = 12
_G.N3onHub.SavedStates.espEnabled      = false
_G.N3onHub.SavedStates.espBoxEnabled   = false
_G.N3onHub.SavedStates.espNameEnabled  = false
_G.N3onHub.SavedStates.espDistEnabled  = false
_G.N3onHub.SavedStates.antiKnockback   = false
_G.N3onHub.SavedStates.autoRespawn     = false
_G.N3onHub.SavedStates.clickTpEnabled  = false
_G.N3onHub.SavedStates.flingEnabled    = false
_G.N3onHub.SavedStates.flingPower      = 500
_G.N3onHub.SavedStates.punchDelay      = 15   -- ms entre punches

----------------------------------------------------------------
-- FLAGS
----------------------------------------------------------------
local autoFarmActive  = false
local auraActive      = false
local espActive       = false
local antiKnockActive = false
local autoRespawnAct  = false
local clickTpActive   = false
local flingActive     = false

local activeTween  = nil
local farmConn     = nil
local espObjects   = {}
local clickTpConn  = nil
local safePlayers  = {}
local targetFarm   = nil

----------------------------------------------------------------
-- SAFE ZONE
----------------------------------------------------------------
local safeZoneCF = CFrame.new(0, 600, 99999)
local safeZonePart = Instance.new("Part")
safeZonePart.Name         = "N3onSafeAW"
safeZonePart.Size         = Vector3.new(40, 1, 40)
safeZonePart.Anchored     = true
safeZonePart.CanCollide   = true
safeZonePart.BrickColor   = BrickColor.new("Cyan")
safeZonePart.Material     = Enum.Material.SmoothPlastic
safeZonePart.Transparency = 0.3
safeZonePart.CFrame       = safeZoneCF
safeZonePart.Parent       = workspace

local bb = Instance.new("BillboardGui", safeZonePart)
bb.Size = UDim2.fromOffset(220, 36)
bb.StudsOffset = Vector3.new(0, 5, 0)
bb.AlwaysOnTop = true
local bbl = Instance.new("TextLabel", bb)
bbl.Size = UDim2.new(1,0,1,0)
bbl.BackgroundTransparency = 1
bbl.Text = "🔵 N3on SAFE ZONE"
bbl.Font = Enum.Font.GothamBold
bbl.TextSize = 16
bbl.TextColor3 = Color3.fromRGB(50, 220, 255)
bbl.TextStrokeTransparency = 0.3

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
	local h = GetHum()
	return h and h.Health > 0
end

local function TpSafe()
	local hrp = GetHRP()
	if hrp then hrp.CFrame = safeZoneCF + Vector3.new(0, 5, 0) end
end

local function IsInSafe()
	local hrp = GetHRP()
	if not hrp then return false end
	return (hrp.Position - safeZonePart.Position).Magnitude < 35
end

----------------------------------------------------------------
-- PUNCH — 3 métodos em cascata
--
-- Método 1: VIM simula Left Click na tela (mais universal)
-- Método 2: Tool:Activate() se tiver tool equipada
-- Método 3: FireServer em qualquer RemoteEvent que pareça punch
----------------------------------------------------------------

-- Cache do remote encontrado (evita buscar toda frame)
local cachedRemote = nil

local function FindPunchRemote()
	if cachedRemote and cachedRemote.Parent then return cachedRemote end
	cachedRemote = nil

	local keywords = {"punch", "hit", "attack", "slap", "damage", "swing"}

	local function checkRemote(obj)
		if not (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then return false end
		local lower = obj.Name:lower()
		for _, kw in ipairs(keywords) do
			if lower:find(kw) then return true end
		end
		return false
	end

	-- Procura no ReplicatedStorage e workspace
	for _, container in ipairs({ReplicatedStorage, workspace}) do
		for _, obj in ipairs(container:GetDescendants()) do
			if checkRemote(obj) then
				cachedRemote = obj
				print("[AW] Remote encontrado:", obj:GetFullName())
				return cachedRemote
			end
		end
	end
	return nil
end

local function DoPunch()
	-- Método 1: VIM (simula clique esquerdo no centro da tela)
	pcall(function()
		local cam = workspace.CurrentCamera
		local vp = cam.ViewportSize
		local cx, cy = vp.X / 2, vp.Y / 2
		VIM:SendMouseButtonEvent(cx, cy, 0, true,  game, 1)
		task.wait(0.03)
		VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
	end)

	-- Método 2: Tool
	pcall(function()
		local char = Player.Character
		if not char then return end
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			tool:Activate()
			task.wait(0.03)
			tool:Deactivate()
		end
	end)

	-- Método 3: Remote
	pcall(function()
		local rem = FindPunchRemote()
		if not rem then return end
		if rem:IsA("RemoteEvent") then
			rem:FireServer()
		elseif rem:IsA("RemoteFunction") then
			rem:InvokeServer()
		end
	end)
end

----------------------------------------------------------------
-- MOVIMENTO — tween no HRP + MoveTo como fallback
----------------------------------------------------------------
local function MoveToPos(goalPos, lookPos)
	local hrp = GetHRP()
	if not hrp then return end

	local goalCF
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

	local dist = (hrp.Position - goalPos).Magnitude
	local dur  = math.max(dist / (_G.N3onHub.SavedStates.farmSpeed * 10), 0.05)

	if activeTween then activeTween:Cancel() end
	activeTween = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = goalCF})
	activeTween:Play()

	-- fallback: MoveTo caso tween não mova (jogos com anti-tween)
	pcall(function()
		local hum = GetHum()
		if hum then hum:MoveTo(goalPos) end
	end)
end

local function StopMove()
	if activeTween then activeTween:Cancel(); activeTween = nil end
	if farmConn then farmConn:Disconnect(); farmConn = nil end
end

----------------------------------------------------------------
-- TARGETS
----------------------------------------------------------------
local function GetTargets()
	local hrp = GetHRP()
	if not hrp then return {} end

	if targetFarm then
		local tp = Players:FindFirstChild(targetFarm)
		if tp and tp ~= Player and tp.Character then
			local th = tp.Character:FindFirstChild("HumanoidRootPart")
			local tHum = tp.Character:FindFirstChild("Humanoid")
			if th and tHum and tHum.Health > 0 then return {tp} end
		end
		return {}
	end

	local list = {}
	local range = _G.N3onHub.SavedStates.farmRange
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		if safePlayers[plr.Name] then continue end
		pcall(function()
			local th   = plr.Character.HumanoidRootPart
			local tHum = plr.Character.Humanoid
			if tHum.Health > 0 then
				local d = (hrp.Position - th.Position).Magnitude
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

local function GetClosestPlayer()
	local targets = GetTargets()
	return targets[1]
end

----------------------------------------------------------------
-- ESPERAR CHEGAR PERTO
----------------------------------------------------------------
local function WaitArrive(target, maxDist, timeout)
	maxDist = maxDist or 6
	timeout = timeout or 2.5
	local t0 = tick()
	while autoFarmActive and tick() - t0 < timeout do
		local hrp = GetHRP()
		local th  = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if hrp and th and (hrp.Position - th.Position).Magnitude <= maxDist then return true end
		task.wait(0.05)
	end
	return false
end

----------------------------------------------------------------
-- AUTO FARM LOOP
----------------------------------------------------------------
local function AutoFarmLoop()
	local idx    = 1
	local clicks = 0
	local timer  = tick()

	while autoFarmActive do

		-- pausa anti-kick
		if tick() - timer >= 5 then
			StopMove()
			local h = GetHRP()
			if h then h.Anchored = true end
			task.wait(1.2)
			h = GetHRP()
			if h then h.Anchored = false end
			timer = tick()
			continue
		end

		if not IsAlive() then StopMove(); task.wait(0.5); continue end

		local hrp = GetHRP()
		if not hrp then task.wait(0.1); continue end

		----------------------------------------------------------------
		-- MODO SAFE HIT (TP → bate → TP, o mais rápido)
		----------------------------------------------------------------
		if _G.N3onHub.SavedStates.safeHitEnabled then
			local targets = GetTargets()
			if #targets == 0 then TpSafe(); task.wait(0.5); continue end

			local target = targets[1]
			local th = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			if not th then task.wait(0.1); continue end

			-- TP perto do target (atrás)
			local behind = (th.CFrame * CFrame.new(0, 0, 2.5)).Position
			hrp.CFrame = CFrame.new(Vector3.new(behind.X, th.Position.Y, behind.Z))
				* CFrame.Angles(0, math.pi, 0)  -- olha pro target
			task.wait(0.03)

			DoPunch()
			clicks = clicks + 1
			task.wait(_G.N3onHub.SavedStates.punchDelay / 1000)

			TpSafe()
			task.wait(math.random(10, 25) / 100)
			continue
		end

		----------------------------------------------------------------
		-- MODO SAFE BACK (tween até target → bate → TP)
		----------------------------------------------------------------
		if _G.N3onHub.SavedStates.safeBackEnabled then
			local targets = GetTargets()
			if #targets == 0 then StopMove(); task.wait(0.2); continue end
			if idx > #targets then idx = 1 end

			local target = targets[idx]
			local th = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			if not th then task.wait(0.1); continue end

			local behind = (th.CFrame * CFrame.new(0, 0, 3)).Position
			MoveToPos(
				Vector3.new(behind.X, th.Position.Y, behind.Z),
				th.Position
			)

			WaitArrive(target, 6, 2.5)
			StopMove()
			task.wait(0.05)

			DoPunch()
			clicks = clicks + 1
			task.wait(_G.N3onHub.SavedStates.punchDelay / 1000)

			TpSafe()
			task.wait(math.random(15, 30) / 100)

			idx = (idx % #targets) + 1
			continue
		end

		----------------------------------------------------------------
		-- MODO NORMAL (tween contínuo + bate)
		----------------------------------------------------------------
		local targets = GetTargets()
		if #targets == 0 then StopMove(); idx = 1; task.wait(0.1); continue end
		if idx > #targets then idx = 1 end

		local target = targets[idx]
		local th = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if not th then task.wait(0.1); continue end

		local behind = (th.CFrame * CFrame.new(0, 0, 3)).Position
		MoveToPos(
			Vector3.new(behind.X, th.Position.Y, behind.Z),
			th.Position
		)

		WaitArrive(target, 5, 2)
		task.wait(math.random(5, 12) / 100)

		DoPunch()
		clicks = clicks + 1
		task.wait(_G.N3onHub.SavedStates.punchDelay / 1000)

		-- a cada 5 clicks pausa 0.8s (anti-kick leve)
		if clicks % 5 == 0 then StopMove(); task.wait(0.8) end

		idx = (idx % #targets) + 1
	end

	StopMove()
end

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
			local th = plr.Character.HumanoidRootPart
			if (hrp.Position - th.Position).Magnitude <= _G.N3onHub.SavedStates.auraSize then
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
	if not autoRespawnAct then return end
	local hum = GetHum()
	if hum and hum.Health <= 0 then
		task.wait(0.4)
		Players.LocalPlayer:LoadCharacter()
	end
end)

----------------------------------------------------------------
-- FLING
----------------------------------------------------------------
local function FlingTarget(target)
	if not target or not target.Character then return end
	local hrp  = GetHRP()
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
	clickTpConn = UserInputService.InputBegan:Connect(function(inp, gpe)
		if gpe then return end
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			local hrp = GetHRP()
			if not hrp then return end
			local ray = workspace.CurrentCamera:ScreenPointToRay(inp.Position.X, inp.Position.Y)
			local res = workspace:Raycast(ray.Origin, ray.Direction * 1000)
			if res then hrp.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0)) end
		end
	end)
end
local function DisableClickTP()
	if clickTpConn then clickTpConn:Disconnect(); clickTpConn = nil end
end

----------------------------------------------------------------
-- ESP
----------------------------------------------------------------
local function CreateESP(plr)
	if espObjects[plr.Name] then return end
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(0, 180, 255)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.5
	hl.OutlineTransparency = 0

	local bbd = Instance.new("BillboardGui")
	bbd.Size = UDim2.fromOffset(160, 55)
	bbd.StudsOffset = Vector3.new(0, 3.5, 0)
	bbd.AlwaysOnTop = true

	local nl = Instance.new("TextLabel", bbd)
	nl.Name = "NameLabel"
	nl.Size = UDim2.new(1,0,0.5,0)
	nl.BackgroundTransparency = 1
	nl.Font = Enum.Font.GothamBold
	nl.TextSize = 14
	nl.TextColor3 = Color3.fromRGB(50, 200, 255)
	nl.TextStrokeTransparency = 0
	nl.Text = plr.Name

	local dl = Instance.new("TextLabel", bbd)
	dl.Name = "DistLabel"
	dl.Size = UDim2.new(1,0,0.5,0)
	dl.Position = UDim2.new(0,0,0.5,0)
	dl.BackgroundTransparency = 1
	dl.Font = Enum.Font.Gotham
	dl.TextSize = 12
	dl.TextColor3 = Color3.fromRGB(255, 255, 100)
	dl.TextStrokeTransparency = 0
	dl.Text = "..."

	espObjects[plr.Name] = {highlight = hl, billboard = bbd, nameLabel = nl, distLabel = dl}
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
	if not espActive then ClearAllESP(); return end
	local hrp = GetHRP()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		pcall(function()
			local char = plr.Character
			if not char then RemoveESP(plr.Name); return end
			local th = char:FindFirstChild("HumanoidRootPart")
			if not th then RemoveESP(plr.Name); return end
			if not espObjects[plr.Name] then CreateESP(plr) end
			local obj = espObjects[plr.Name]
			if _G.N3onHub.SavedStates.espBoxEnabled then
				obj.highlight.Adornee = char; obj.highlight.Parent = char
			else
				obj.highlight.Parent = nil
			end
			obj.billboard.Adornee = th; obj.billboard.Parent = th
			obj.nameLabel.Visible = _G.N3onHub.SavedStates.espNameEnabled
			obj.distLabel.Visible = _G.N3onHub.SavedStates.espDistEnabled
			if hrp then
				obj.distLabel.Text = math.floor((hrp.Position - th.Position).Magnitude) .. " studs"
			end
		end)
	end
	for name in pairs(espObjects) do
		if not Players:FindFirstChild(name) then RemoveESP(name) end
	end
end)

----------------------------------------------------------------
-- DROPDOWN HELPERS
----------------------------------------------------------------
local function CreatePlayerDropdown(parent, label, color, getChecked, onSelect)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1,0,0,36)
	container.BackgroundColor3 = Color3.fromRGB(30,30,30)
	container.BorderSizePixel = 0
	Instance.new("UICorner", container)
	local header = Instance.new("TextButton", container)
	header.Size = UDim2.new(1,0,0,36)
	header.BackgroundColor3 = color
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextColor3 = Color3.new(1,1,1)
	header.Text = "▼  " .. label
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.AutoButtonColor = false
	Instance.new("UICorner", header)
	local hp = Instance.new("UIPadding", header); hp.PaddingLeft = UDim.new(0,10)
	local itemList = Instance.new("Frame", container)
	itemList.Size = UDim2.new(1,0,0,0)
	itemList.Position = UDim2.new(0,0,0,36)
	itemList.BackgroundTransparency = 1
	itemList.ClipsDescendants = true
	local ll = Instance.new("UIListLayout", itemList)
	ll.SortOrder = Enum.SortOrder.LayoutOrder
	ll.Padding = UDim.new(0,2)
	local isOpen = false
	local function Rebuild()
		for _, ch in ipairs(itemList:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local plrs = Players:GetPlayers()
		table.sort(plrs, function(a,b) return a.Name < b.Name end)
		for _, plr in ipairs(plrs) do
			if plr == Player then continue end
			local row = Instance.new("TextButton", itemList)
			row.Size = UDim2.new(1,-4,0,30)
			row.Font = Enum.Font.Gotham; row.TextSize = 13
			row.TextColor3 = Color3.new(1,1,1)
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.AutoButtonColor = false
			Instance.new("UICorner", row)
			local rp = Instance.new("UIPadding", row); rp.PaddingLeft = UDim.new(0,10)
			local checked = getChecked(plr.Name)
			row.Text = (checked and "☑  " or "☐  ") .. plr.Name
			row.BackgroundColor3 = checked and Color3.fromRGB(40,80,50) or Color3.fromRGB(40,40,40)
			row.MouseButton1Click:Connect(function()
				onSelect(plr.Name, not getChecked(plr.Name))
				local nc = getChecked(plr.Name)
				row.Text = (nc and "☑  " or "☐  ") .. plr.Name
				row.BackgroundColor3 = nc and Color3.fromRGB(40,80,50) or Color3.fromRGB(40,40,40)
			end)
		end
		local count = #itemList:GetChildren() - 1
		local h = math.max(count * 32, 0)
		itemList.Size = UDim2.new(1,0,0,h)
		container.Size = UDim2.new(1,0,0,36 + (isOpen and h or 0))
	end
	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then Rebuild(); header.Text = "▲  " .. label
		else header.Text = "▼  " .. label; itemList.Size = UDim2.new(1,0,0,0); container.Size = UDim2.new(1,0,0,36)
		end
	end)
	return container
end

local function CreateSingleSelectDropdown(parent, label, color, getSelected, onSelect)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1,0,0,36)
	container.BackgroundColor3 = Color3.fromRGB(30,30,30)
	container.BorderSizePixel = 0
	Instance.new("UICorner", container)
	local header = Instance.new("TextButton", container)
	header.Size = UDim2.new(1,0,0,36)
	header.BackgroundColor3 = color
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextColor3 = Color3.new(1,1,1)
	header.AutoButtonColor = false
	Instance.new("UICorner", header)
	local hp = Instance.new("UIPadding", header); hp.PaddingLeft = UDim.new(0,10)
	local function UpdateHeader()
		local s = getSelected()
		header.Text = "▼  " .. label .. (s and (": " .. s) or "")
	end
	UpdateHeader()
	local itemList = Instance.new("Frame", container)
	itemList.Size = UDim2.new(1,0,0,0)
	itemList.Position = UDim2.new(0,0,0,36)
	itemList.BackgroundTransparency = 1
	itemList.ClipsDescendants = true
	Instance.new("UIListLayout", itemList).Padding = UDim.new(0,2)
	local isOpen = false
	local function Rebuild()
		for _, ch in ipairs(itemList:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end
		local noneRow = Instance.new("TextButton", itemList)
		noneRow.Size = UDim2.new(1,-4,0,30)
		noneRow.BackgroundColor3 = getSelected() == nil and Color3.fromRGB(80,30,30) or Color3.fromRGB(40,40,40)
		noneRow.Font = Enum.Font.GothamBold; noneRow.TextSize = 13
		noneRow.TextColor3 = Color3.fromRGB(255,120,120)
		noneRow.Text = "✕  Nenhum"
		noneRow.TextXAlignment = Enum.TextXAlignment.Left
		noneRow.AutoButtonColor = false
		Instance.new("UICorner", noneRow)
		local np = Instance.new("UIPadding", noneRow); np.PaddingLeft = UDim.new(0,10)
		noneRow.MouseButton1Click:Connect(function() onSelect(nil); UpdateHeader(); Rebuild() end)
		local plrs = Players:GetPlayers()
		table.sort(plrs, function(a,b) return a.Name < b.Name end)
		for _, plr in ipairs(plrs) do
			if plr == Player then continue end
			local isSel = getSelected() == plr.Name
			local row = Instance.new("TextButton", itemList)
			row.Size = UDim2.new(1,-4,0,30)
			row.BackgroundColor3 = isSel and Color3.fromRGB(40,70,110) or Color3.fromRGB(40,40,40)
			row.Font = Enum.Font.Gotham; row.TextSize = 13
			row.TextColor3 = Color3.new(1,1,1)
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.AutoButtonColor = false
			Instance.new("UICorner", row)
			local rp = Instance.new("UIPadding", row); rp.PaddingLeft = UDim.new(0,10)
			row.Text = (isSel and "◉  " or "○  ") .. plr.Name
			row.MouseButton1Click:Connect(function()
				onSelect(getSelected() == plr.Name and nil or plr.Name)
				UpdateHeader(); Rebuild()
			end)
		end
		local count = #itemList:GetChildren() - 1
		local h = math.max(count * 32, 0)
		itemList.Size = UDim2.new(1,0,0,h)
		container.Size = UDim2.new(1,0,0,36 + (isOpen and h or 0))
	end
	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then Rebuild(); header.Text = "▲  " .. label .. (getSelected() and (": " .. getSelected()) or "")
		else UpdateHeader(); itemList.Size = UDim2.new(1,0,0,0); container.Size = UDim2.new(1,0,0,36)
		end
	end)
	return container
end

----------------------------------------------------------------
-- TAB: FARM
----------------------------------------------------------------
local function LoadFarmTab()
	_G.N3onHub.GUI.Clear()
	local SC = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size = UDim2.new(1,0,0,40)
	title.BackgroundTransparency = 1
	title.Text = "👊 Farm - Ability Wars"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(50,200,255)

	-- DEBUG REMOTE
	local debugBtn = Instance.new("TextButton", SC)
	debugBtn.Size = UDim2.new(1,0,0,36)
	debugBtn.Text = "🔍 Debug: Listar RemoteEvents no Output"
	debugBtn.Font = Enum.Font.GothamBold
	debugBtn.TextSize = 13
	debugBtn.BackgroundColor3 = Color3.fromRGB(60,40,100)
	debugBtn.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", debugBtn)
	debugBtn.MouseButton1Click:Connect(function()
		print("=== REMOTES EM ReplicatedStorage ===")
		for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
				print(obj.ClassName, obj:GetFullName())
			end
		end
		print("=== REMOTES EM workspace ===")
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
				print(obj.ClassName, obj:GetFullName())
			end
		end
		print("=== FIM ===")
	end)

	-- AUTO FARM
	local l1 = Instance.new("TextLabel", SC)
	l1.Size = UDim2.new(1,0,0,28); l1.BackgroundTransparency = 1
	l1.Text = "⚡ Auto Farm"; l1.Font = Enum.Font.GothamBold
	l1.TextSize = 15; l1.TextColor3 = Color3.fromRGB(50,200,255)
	l1.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Farm (Tween + Punch)", _G.N3onHub.SavedStates.autoFarm, function(v)
		_G.N3onHub.SavedStates.autoFarm = v
		autoFarmActive = v
		if v then spawn(AutoFarmLoop) else StopMove() end
	end)

	_G.N3onHub.Slider("Tween Speed", 5, 100, _G.N3onHub.SavedStates.farmSpeed, function(v)
		_G.N3onHub.SavedStates.farmSpeed = v
	end)

	_G.N3onHub.Slider("Farm Range (studs)", 10, 200, _G.N3onHub.SavedStates.farmRange, function(v)
		_G.N3onHub.SavedStates.farmRange = v
	end)

	_G.N3onHub.Slider("Punch Delay (ms)", 5, 200, _G.N3onHub.SavedStates.punchDelay, function(v)
		_G.N3onHub.SavedStates.punchDelay = v
	end)

	-- MODOS SAFE
	local l2 = Instance.new("TextLabel", SC)
	l2.Size = UDim2.new(1,0,0,28); l2.BackgroundTransparency = 1
	l2.Text = "🔵 Modos Safe Zone"; l2.Font = Enum.Font.GothamBold
	l2.TextSize = 15; l2.TextColor3 = Color3.fromRGB(50,220,255)
	l2.TextXAlignment = Enum.TextXAlignment.Left

	local d1 = Instance.new("TextLabel", SC)
	d1.Size = UDim2.new(1,0,0,30); d1.BackgroundTransparency = 1
	d1.Text = "Safe Back: tween até player → bate → TPA pra safe."
	d1.Font = Enum.Font.Gotham; d1.TextSize = 11
	d1.TextColor3 = Color3.fromRGB(150,150,150); d1.TextXAlignment = Enum.TextXAlignment.Left; d1.TextWrapped = true

	_G.N3onHub.Checkbox("Safe Back", _G.N3onHub.SavedStates.safeBackEnabled, function(v)
		_G.N3onHub.SavedStates.safeBackEnabled = v
		if v then _G.N3onHub.SavedStates.safeHitEnabled = false end
	end)

	local d2 = Instance.new("TextLabel", SC)
	d2.Size = UDim2.new(1,0,0,30); d2.BackgroundTransparency = 1
	d2.Text = "Safe Hit: TPA instantâneo → bate → TPA de volta (mais rápido)."
	d2.Font = Enum.Font.Gotham; d2.TextSize = 11
	d2.TextColor3 = Color3.fromRGB(150,150,150); d2.TextXAlignment = Enum.TextXAlignment.Left; d2.TextWrapped = true

	_G.N3onHub.Checkbox("Safe Hit (TP instantâneo)", _G.N3onHub.SavedStates.safeHitEnabled, function(v)
		_G.N3onHub.SavedStates.safeHitEnabled = v
		if v then _G.N3onHub.SavedStates.safeBackEnabled = false end
	end)

	-- SAFE PLAYERS
	local l3 = Instance.new("TextLabel", SC)
	l3.Size = UDim2.new(1,0,0,28); l3.BackgroundTransparency = 1
	l3.Text = "🛡️ Safe Players"; l3.Font = Enum.Font.GothamBold
	l3.TextSize = 15; l3.TextColor3 = Color3.fromRGB(100,255,130)
	l3.TextXAlignment = Enum.TextXAlignment.Left

	CreatePlayerDropdown(SC, "Safe Players", Color3.fromRGB(30,90,50),
		function(name) return safePlayers[name] == true end,
		function(name, v) safePlayers[name] = v or nil end
	)

	-- TARGET FARM
	local l4 = Instance.new("TextLabel", SC)
	l4.Size = UDim2.new(1,0,0,28); l4.BackgroundTransparency = 1
	l4.Text = "🎯 Target Farm"; l4.Font = Enum.Font.GothamBold
	l4.TextSize = 15; l4.TextColor3 = Color3.fromRGB(255,150,50)
	l4.TextXAlignment = Enum.TextXAlignment.Left

	CreateSingleSelectDropdown(SC, "Target Farm", Color3.fromRGB(100,55,20),
		function() return targetFarm end,
		function(name) targetFarm = name end
	)

	-- KILL AURA
	Instance.new("Frame", SC).Size = UDim2.new(1,0,0,1)
	local l5 = Instance.new("TextLabel", SC)
	l5.Size = UDim2.new(1,0,0,28); l5.BackgroundTransparency = 1
	l5.Text = "💥 Kill Aura"; l5.Font = Enum.Font.GothamBold
	l5.TextSize = 15; l5.TextColor3 = Color3.fromRGB(255,80,80)
	l5.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Kill Aura", _G.N3onHub.SavedStates.auraEnabled, function(v)
		_G.N3onHub.SavedStates.auraEnabled = v; auraActive = v
	end)
	_G.N3onHub.Slider("Aura Range (studs)", 3, 60, _G.N3onHub.SavedStates.auraSize, function(v)
		_G.N3onHub.SavedStates.auraSize = v
	end)

	-- FLING
	local l6 = Instance.new("TextLabel", SC)
	l6.Size = UDim2.new(1,0,0,28); l6.BackgroundTransparency = 1
	l6.Text = "🚀 Fling"; l6.Font = Enum.Font.GothamBold
	l6.TextSize = 15; l6.TextColor3 = Color3.fromRGB(255,150,50)
	l6.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Enable Fling", _G.N3onHub.SavedStates.flingEnabled, function(v)
		_G.N3onHub.SavedStates.flingEnabled = v; flingActive = v
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
	local SC = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size = UDim2.new(1,0,0,40); title.BackgroundTransparency = 1
	title.Text = "👁️ ESP - Ability Wars"; title.Font = Enum.Font.GothamBold
	title.TextScaled = true; title.TextColor3 = Color3.fromRGB(50,200,255)

	_G.N3onHub.Checkbox("ESP Ativo", _G.N3onHub.SavedStates.espEnabled, function(v)
		_G.N3onHub.SavedStates.espEnabled = v; espActive = v
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
	local SC = _G.N3onHub.GUI.ScrollContent
	local UCS = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", SC)
	title.Size = UDim2.new(1,0,0,40); title.BackgroundTransparency = 1
	title.Text = "⚙️ Misc - Ability Wars"; title.Font = Enum.Font.GothamBold
	title.TextScaled = true; title.TextColor3 = Color3.fromRGB(200,200,200)

	-- ANTI KNOCKBACK
	local l1 = Instance.new("TextLabel", SC)
	l1.Size = UDim2.new(1,0,0,28); l1.BackgroundTransparency = 1
	l1.Text = "🛡️ Anti Knockback"; l1.Font = Enum.Font.GothamBold
	l1.TextSize = 15; l1.TextColor3 = Color3.fromRGB(100,255,100)
	l1.TextXAlignment = Enum.TextXAlignment.Left
	_G.N3onHub.Checkbox("Anti Knockback", _G.N3onHub.SavedStates.antiKnockback, function(v)
		_G.N3onHub.SavedStates.antiKnockback = v; antiKnockActive = v
	end)

	-- AUTO RESPAWN
	local l2 = Instance.new("TextLabel", SC)
	l2.Size = UDim2.new(1,0,0,28); l2.BackgroundTransparency = 1
	l2.Text = "🔄 Auto Respawn"; l2.Font = Enum.Font.GothamBold
	l2.TextSize = 15; l2.TextColor3 = Color3.fromRGB(255,200,100)
	l2.TextXAlignment = Enum.TextXAlignment.Left
	_G.N3onHub.Checkbox("Auto Respawn", _G.N3onHub.SavedStates.autoRespawn, function(v)
		_G.N3onHub.SavedStates.autoRespawn = v; autoRespawnAct = v
	end)

	-- CLICK TP
	local l3 = Instance.new("TextLabel", SC)
	l3.Size = UDim2.new(1,0,0,28); l3.BackgroundTransparency = 1
	l3.Text = "🖱️ Click TP"; l3.Font = Enum.Font.GothamBold
	l3.TextSize = 15; l3.TextColor3 = Color3.fromRGB(255,200,50)
	l3.TextXAlignment = Enum.TextXAlignment.Left
	_G.N3onHub.Checkbox("Click TP", _G.N3onHub.SavedStates.clickTpEnabled, function(v)
		_G.N3onHub.SavedStates.clickTpEnabled = v; clickTpActive = v
		if v then EnableClickTP() else DisableClickTP() end
	end)

	-- SAFE ZONE
	Instance.new("Frame", SC).Size = UDim2.new(1,0,0,1)
	local l4 = Instance.new("TextLabel", SC)
	l4.Size = UDim2.new(1,0,0,28); l4.BackgroundTransparency = 1
	l4.Text = "🔵 Safe Zone"; l4.Font = Enum.Font.GothamBold
	l4.TextSize = 15; l4.TextColor3 = Color3.fromRGB(50,220,255)
	l4.TextXAlignment = Enum.TextXAlignment.Left

	local tpSafe = Instance.new("TextButton", SC)
	tpSafe.Size = UDim2.new(1,0,0,40)
	tpSafe.Text = "🔵 TP to Safe Zone"
	tpSafe.Font = Enum.Font.GothamBold; tpSafe.TextSize = 14
	tpSafe.BackgroundColor3 = Color3.fromRGB(20,100,140)
	tpSafe.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", tpSafe)
	tpSafe.MouseButton1Click:Connect(TpSafe)

	local tpClosest = Instance.new("TextButton", SC)
	tpClosest.Size = UDim2.new(1,0,0,40)
	tpClosest.Text = "🎯 TP to Closest Player"
	tpClosest.Font = Enum.Font.GothamBold; tpClosest.TextSize = 14
	tpClosest.BackgroundColor3 = Color3.fromRGB(30,80,160)
	tpClosest.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", tpClosest)
	tpClosest.MouseButton1Click:Connect(function()
		local t = GetClosestPlayer()
		if t and t.Character then
			local hrp = GetHRP()
			local th  = t.Character:FindFirstChild("HumanoidRootPart")
			if hrp and th then hrp.CFrame = th.CFrame + Vector3.new(0,3,0) end
		end
	end)

	-- PUNCH MANUAL
	Instance.new("Frame", SC).Size = UDim2.new(1,0,0,1)
	local l5 = Instance.new("TextLabel", SC)
	l5.Size = UDim2.new(1,0,0,28); l5.BackgroundTransparency = 1
	l5.Text = "👊 Punch Manual"; l5.Font = Enum.Font.GothamBold
	l5.TextSize = 15; l5.TextColor3 = Color3.fromRGB(255,150,50)
	l5.TextXAlignment = Enum.TextXAlignment.Left

	local punchBtn = Instance.new("TextButton", SC)
	punchBtn.Size = UDim2.new(1,0,0,40)
	punchBtn.Text = "👊 Punch Agora (teste)"
	punchBtn.Font = Enum.Font.GothamBold; punchBtn.TextSize = 14
	punchBtn.BackgroundColor3 = Color3.fromRGB(140,60,20)
	punchBtn.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", punchBtn)
	punchBtn.MouseButton1Click:Connect(DoPunch)

	UCS()
end

----------------------------------------------------------------
-- REGISTRAR TABS
----------------------------------------------------------------
_G.N3onHub.Tab("Farm",  "👊", 0, LoadFarmTab)
_G.N3onHub.Tab("ESP",   "👁️", 0, LoadESPTab)
_G.N3onHub.Tab("Misc",  "⚙️", 0, LoadMiscTab)

print("[Ability Wars v2] Loaded! Use o botão 🔍 Debug pra listar RemoteEvents no Output.")
