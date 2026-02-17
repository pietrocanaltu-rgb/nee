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

-- Safe Players: set de nomes que o farm vai ignorar
local safePlayers  = {}  -- { [name] = true }

-- Target Farm: se definido, farm foca só nesse player
local targetFarmPlayer = nil  -- string (nome) ou nil

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
			local char = plr.Character
			if not char then return end
			local tHRP = char:FindFirstChild("HumanoidRootPart")
			if not tHRP then return end
			local dist = (hrp.Position - tHRP.Position).Magnitude
			if dist > _G.N3onHub.SavedStates.auraSize then return end
			local myChar = Player.Character
			if not myChar then return end
			local tool = myChar:FindFirstChildOfClass("Tool")
			if not tool then return end
			pcall(function() tool:Activate() end)
			task.wait(0.02)
			pcall(function() tool:Deactivate() end)
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
-- CLICK CORRIGIDO (SEM VIM / SEM BUG DE GUI)
----------------------------------------------------------------

local ClickDelay = 0.08
local HoldTime   = 0.02
local lastClick  = 0

local function Click()
	if tick() - lastClick < ClickDelay then return end
	lastClick = tick()

	local char = Player.Character
	if not char then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return end

	pcall(function() tool:Activate() end)
	if HoldTime > 0 then task.wait(HoldTime) end
	pcall(function() tool:Deactivate() end)
end

----------------------------------------------------------------
-- Verifica se uma posição está dentro do bounding box do Lobby
----------------------------------------------------------------

local function IsInsideLobby(pos)
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then return false end

	local ref = lobby.PrimaryPart
	if not ref then
		for _, v in pairs(lobby:GetDescendants()) do
			if v:IsA("BasePart") then ref = v break end
		end
	end
	if not ref then return false end

	local ok, bbCF, bbSize = pcall(function()
		return lobby:GetBoundingBox()
	end)
	if not ok then return false end

	local localPos = bbCF:PointToObjectSpace(pos)
	local half = bbSize / 2

	return math.abs(localPos.X) <= half.X
		and math.abs(localPos.Y) <= half.Y
		and math.abs(localPos.Z) <= half.Z
end

----------------------------------------------------------------
-- TELEPORT
----------------------------------------------------------------

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
				if v:IsA("BasePart") then
					return v.Position + Vector3.new(0, 3, 0)
				end
			end
		end
	end
	return nil
end

----------------------------------------------------------------
-- DANGEROUS TOOLS
----------------------------------------------------------------

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

----------------------------------------------------------------
-- TARGET — modos: target farm, normal (com safe players)
----------------------------------------------------------------

local function GetAllInRange()
	local hrp = GetHRP()
	if not hrp then return {} end
	local range = _G.N3onHub.SavedStates.farmRange

	-- MODO TARGET FARM: foca só num player, ignora tudo
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

	-- MODO NORMAL: respeita safe players, dangerous tools e lobby
	local list = {}
	for _, plr in pairs(Players:GetPlayers()) do
		if plr == Player then continue end
		if safePlayers[plr.Name] then continue end  -- pula safe players
		pcall(function()
			local tHRP = plr.Character.HumanoidRootPart
			local tHum = plr.Character.Humanoid
			if IsInsideLobby(tHRP.Position) then return end
			if HasDangerousTool(plr) then return end
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
	for _, entry in ipairs(list) do
		table.insert(result, entry.plr)
	end
	return result
end

----------------------------------------------------------------
-- TWEEN — move e olha para o target com CFrame.lookAt
----------------------------------------------------------------

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

		if not activeTween or activeTween.PlaybackState ~= Enum.PlaybackState.Playing then
			local dist = (hrp.Position - goalPos).Magnitude
			local dur = math.max(dist / (_G.N3onHub.SavedStates.farmSpeed * 10), 0.05)

			local goalCFrame
			if lookAtGetter then
				local lookPos = lookAtGetter()
				if lookPos then
					local flatLook = Vector3.new(lookPos.X, goalPos.Y, lookPos.Z)
					if (flatLook - goalPos).Magnitude > 0.01 then
						goalCFrame = CFrame.lookAt(goalPos, flatLook)
					else
						goalCFrame = CFrame.new(goalPos)
					end
				else
					goalCFrame = CFrame.new(goalPos)
				end
			else
				goalCFrame = CFrame.new(goalPos)
			end

			activeTween = TweenService:Create(
				hrp,
				TweenInfo.new(dur, Enum.EasingStyle.Linear),
				{CFrame = goalCFrame}
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
-- AttackTarget — 2 studs X, lookAt, pausa 3s a cada 5 slaps
----------------------------------------------------------------

local CLICKS_PER_TARGET = 8

local function AttackTarget(target)
	if not target or not target.Character then return end

	local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
	local tHum = target.Character:FindFirstChild("Humanoid")
	if not tHRP or not tHum or tHum.Health <= 0 then return end

	StartContinuousTween(
		function()
			local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			if t then return t.Position + Vector3.new(2, 0, 0) end
		end,
		function()
			local t = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			if t then return t.Position end
		end
	)

	local clicks = 0
	while autoFarmActive and clicks < CLICKS_PER_TARGET do
		if not target.Character then break end
		local h = target.Character:FindFirstChild("Humanoid")
		if not h or h.Health <= 0 then break end

		Click()
		clicks = clicks + 1

		if clicks % 5 == 0 then
			task.wait(3)
		else
			task.wait(0.05)
		end
	end
end

----------------------------------------------------------------
-- AUTO FARM LOOP
----------------------------------------------------------------

local function AutoFarmLoop()
	local farmTimer  = tick()
	local onPause    = false
	local farmIndex  = 1  -- índice atual na lista de targets (alterna entre players)

	while autoFarmActive do

		if not onPause and tick() - farmTimer >= 5 then
			onPause = true
			StopContinuousTween()
			local hrpPause = GetHRP()
			if hrpPause then hrpPause.Anchored = true end
			task.wait(1.5)
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

		local targets = GetAllInRange()

		if #targets > 0 then
			-- garante que o índice é válido para o tamanho atual da lista
			if farmIndex > #targets then farmIndex = 1 end

			local target = targets[farmIndex]

			-- avança pro próximo player antes de atacar (alterna no próximo tick)
			farmIndex = (farmIndex % #targets) + 1

			if not autoFarmActive then break end
			if tick() - farmTimer >= 5 then continue end

			AttackTarget(target)
			task.wait(0.05)
		else
			farmIndex = 1  -- reseta quando não há targets
			StopContinuousTween()
			Click()
			task.wait(0.1)
		end
	end

	StopContinuousTween()
end

----------------------------------------------------------------
-- HELPER: cria um dropdown de players no ScrollContent
--
--   label        = texto do botão principal
--   color        = Color3 do header
--   onSelect(name, isChecked)  → callback quando um item é toggled
--   getChecked(name)           → retorna bool do estado atual
--   refreshSignal              = se true, o dropdown se atualiza ao abrir
----------------------------------------------------------------

local function CreatePlayerDropdown(parent, label, color, getChecked, onSelect)
	-- container que vai crescer/encolher
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, 0, 0, 36)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BorderSizePixel = 0
	Instance.new("UICorner", container)

	-- header / botão principal
	local header = Instance.new("TextButton", container)
	header.Size = UDim2.new(1, 0, 0, 36)
	header.BackgroundColor3 = color
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Text = "▼  " .. label
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.AutoButtonColor = false
	local hc = Instance.new("UICorner", header)
	hc.CornerRadius = UDim.new(0, 6)
	local hp = Instance.new("UIPadding", header)
	hp.PaddingLeft = UDim.new(0, 10)

	-- scroll interno para os itens
	local itemList = Instance.new("Frame", container)
	itemList.Name = "ItemList"
	itemList.Size = UDim2.new(1, 0, 0, 0)
	itemList.Position = UDim2.new(0, 0, 0, 36)
	itemList.BackgroundTransparency = 1
	itemList.ClipsDescendants = true

	local listLayout = Instance.new("UIListLayout", itemList)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)

	local isOpen = false

	local function RebuildList()
		-- limpa itens antigos
		for _, ch in ipairs(itemList:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end

		local playerList = Players:GetPlayers()
		table.sort(playerList, function(a, b) return a.Name < b.Name end)

		for _, plr in ipairs(playerList) do
			if plr == Player then continue end

			local row = Instance.new("TextButton", itemList)
			row.Size = UDim2.new(1, -4, 0, 30)
			row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
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
			row.BackgroundColor3 = checked
				and Color3.fromRGB(50, 90, 50)
				or  Color3.fromRGB(40, 40, 40)

			row.MouseButton1Click:Connect(function()
				onSelect(plr.Name, not getChecked(plr.Name))
				-- atualiza só essa linha
				local nowChecked = getChecked(plr.Name)
				row.Text = (nowChecked and "☑  " or "☐  ") .. plr.Name
				row.BackgroundColor3 = nowChecked
					and Color3.fromRGB(50, 90, 50)
					or  Color3.fromRGB(40, 40, 40)
			end)
		end

		-- ajusta altura do itemList
		local count = #itemList:GetChildren() - 1  -- desconta UIListLayout
		local h = math.max(count * 32, 0)
		itemList.Size = UDim2.new(1, 0, 0, h)
		container.Size = UDim2.new(1, 0, 0, 36 + (isOpen and h or 0))
	end

	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		if isOpen then
			RebuildList()  -- atualiza lista ao abrir
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
-- HELPER: dropdown de seleção única (Target Farm)
-- Seleciona um player por vez; clica de novo para desselecionar
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

	local function UpdateHeaderText()
		local sel = getSelected()
		header.Text = "▼  " .. label .. (sel and (":  " .. sel) or "")
	end
	UpdateHeaderText()

	local itemList = Instance.new("Frame", container)
	itemList.Name = "ItemList"
	itemList.Size = UDim2.new(1, 0, 0, 0)
	itemList.Position = UDim2.new(0, 0, 0, 36)
	itemList.BackgroundTransparency = 1
	itemList.ClipsDescendants = true
	Instance.new("UIListLayout", itemList).Padding = UDim.new(0, 2)

	local isOpen = false

	local function RebuildList()
		for _, ch in ipairs(itemList:GetChildren()) do
			if ch:IsA("GuiObject") then ch:Destroy() end
		end

		-- opção "Nenhum" para deselecionar
		local noneRow = Instance.new("TextButton", itemList)
		noneRow.Size = UDim2.new(1, -4, 0, 30)
		noneRow.BackgroundColor3 = getSelected() == nil
			and Color3.fromRGB(80, 40, 40)
			or  Color3.fromRGB(40, 40, 40)
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
			onSelect(nil)
			UpdateHeaderText()
			RebuildList()
		end)

		local playerList = Players:GetPlayers()
		table.sort(playerList, function(a, b) return a.Name < b.Name end)

		for _, plr in ipairs(playerList) do
			if plr == Player then continue end
			local row = Instance.new("TextButton", itemList)
			row.Size = UDim2.new(1, -4, 0, 30)
			local isSel = getSelected() == plr.Name
			row.BackgroundColor3 = isSel
				and Color3.fromRGB(50, 80, 110)
				or  Color3.fromRGB(40, 40, 40)
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
				-- toggle: clicou no mesmo = deseleciona
				if getSelected() == plr.Name then
					onSelect(nil)
				else
					onSelect(plr.Name)
				end
				UpdateHeaderText()
				RebuildList()
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
			RebuildList()
			header.Text = "▲  " .. label .. (getSelected() and (":  " .. getSelected()) or "")
		else
			UpdateHeaderText()
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

	-- SAFE PLAYERS
	local lSafe = Instance.new("TextLabel", SC)
	lSafe.Size = UDim2.new(1, 0, 0, 28)
	lSafe.BackgroundTransparency = 1
	lSafe.Text = "🛡️ Safe Players"
	lSafe.Font = Enum.Font.GothamBold
	lSafe.TextSize = 15
	lSafe.TextColor3 = Color3.fromRGB(100, 220, 255)
	lSafe.TextXAlignment = Enum.TextXAlignment.Left

	local safeDesc = Instance.new("TextLabel", SC)
	safeDesc.Size = UDim2.new(1, 0, 0, 22)
	safeDesc.BackgroundTransparency = 1
	safeDesc.Text = "Players marcados NÃO serão atacados pelo farm."
	safeDesc.Font = Enum.Font.Gotham
	safeDesc.TextSize = 11
	safeDesc.TextColor3 = Color3.fromRGB(160, 160, 160)
	safeDesc.TextXAlignment = Enum.TextXAlignment.Left
	safeDesc.TextWrapped = true

	CreatePlayerDropdown(
		SC,
		"Safe Players",
		Color3.fromRGB(30, 90, 130),
		function(name) return safePlayers[name] == true end,
		function(name, checked)
			safePlayers[name] = checked or nil
		end
	)

	-- TARGET FARM
	local lTarget = Instance.new("TextLabel", SC)
	lTarget.Size = UDim2.new(1, 0, 0, 28)
	lTarget.BackgroundTransparency = 1
	lTarget.Text = "🎯 Target Farm"
	lTarget.Font = Enum.Font.GothamBold
	lTarget.TextSize = 15
	lTarget.TextColor3 = Color3.fromRGB(255, 140, 50)
	lTarget.TextXAlignment = Enum.TextXAlignment.Left

	local targetDesc = Instance.new("TextLabel", SC)
	targetDesc.Size = UDim2.new(1, 0, 0, 22)
	targetDesc.BackgroundTransparency = 1
	targetDesc.Text = "Foca apenas neste player, ignora dangerous tools e safe players."
	targetDesc.Font = Enum.Font.Gotham
	targetDesc.TextSize = 11
	targetDesc.TextColor3 = Color3.fromRGB(160, 160, 160)
	targetDesc.TextXAlignment = Enum.TextXAlignment.Left
	targetDesc.TextWrapped = true

	CreateSingleSelectDropdown(
		SC,
		"Target Farm",
		Color3.fromRGB(110, 55, 20),
		function() return targetFarmPlayer end,
		function(name)
			targetFarmPlayer = name
		end
	)

	-- separador
	local sep = Instance.new("Frame", SC)
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	sep.BorderSizePixel = 0

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
----------------------------------------------------------------

_G.N3onHub.Tab("Farm", "👏", 0, LoadFarmTab)
_G.N3onHub.Tab("ESP",  "👁️", 0, LoadESPTab)
_G.N3onHub.Tab("Misc", "⚙️", 0, LoadMiscTab)

print("[Slap Battles Module] Loaded!")
