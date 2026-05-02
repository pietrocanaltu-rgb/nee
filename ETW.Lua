-- N3on Hub - Auto Farm Module
-- Cole este script APÓS o script base do N3on Hub ter sido executado

-- Aguarda o Hub base carregar
local timeout = 10
local elapsed = 0
repeat task.wait(0.1); elapsed += 0.1 until (_G.N3onHub and _G.N3onHub._loaded) or elapsed >= timeout
if not (_G.N3onHub and _G.N3onHub._loaded) then
	warn("[AutoFarm] N3on Hub base não encontrado! Execute o script base primeiro.")
	return
end

----------------------------------------------------------------
-- REFERÊNCIAS DO HUB BASE
----------------------------------------------------------------

local Hub          = _G.N3onHub.GUI.Hub
local F2           = _G.N3onHub.GUI.F2
local ScrollContent = _G.N3onHub.GUI.ScrollContent
local Clear        = _G.N3onHub.GUI.Clear
local UpdateCanvas = _G.N3onHub.GUI.UpdateCanvasSize
local Slider       = _G.N3onHub.Slider
local Checkbox     = _G.N3onHub.Checkbox
local Tab          = _G.N3onHub.Tab

local Player       = game.Players.LocalPlayer
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

----------------------------------------------------------------
-- ESTADO DO AUTO FARM
----------------------------------------------------------------

local AF = {
	-- Auto Grab
	grabActive    = false,
	grabInterval  = 500,   -- ms
	grabThread    = nil,

	-- Teleport
	teleportActive   = false,
	teleportInterval = 5,    -- segundos
	teleportRadius   = 4096, -- studs
	teleportThread   = nil,

	-- Auto Sell
	sellActive    = false,
	sellInterval  = 10,    -- segundos
	sellThread    = nil,

	-- Posições de clique (centro da tela por padrão)
	grabClickPos  = nil,   -- nil = centro da tela
	sellClickPos  = nil,   -- nil = centro da tela
}

----------------------------------------------------------------
-- UTILITÁRIOS
----------------------------------------------------------------

-- Simula clique do mouse em uma posição da tela
local function SimulateClick(pos)
	-- pos: Vector2 em pixels na tela, ou nil pra usar centro
	local vp  = workspace.CurrentCamera.ViewportSize
	local target = pos or Vector2.new(vp.X / 2, vp.Y / 2)

	-- Cria um evento de input fake via VirtualInputManager (client-side)
	local vim = game:GetService("VirtualInputManager")
	vim:SendMouseButtonEvent(target.X, target.Y, 0, true,  game, 1)
	task.wait(0.05)
	vim:SendMouseButtonEvent(target.X, target.Y, 0, false, game, 1)
end

-- Busca chão válido abaixo de uma posição (raycast)
local function FindGround(origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	-- Exclui o próprio personagem
	local char = Player.Character
	if char then
		rayParams.FilterDescendantsInstances = {char}
	end

	local result = workspace:Raycast(origin, Vector3.new(0, -500, 0), rayParams)
	if result then
		-- Pousa 3 studs acima do chão pra não ficar preso
		return result.Position + Vector3.new(0, 3, 0)
	end
	return nil
end

-- Teleporta o personagem para uma posição aleatória dentro do raio
local function TeleportRandom()
	local char = Player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local origin = hrp.Position
	local attempts = 0
	local landPos  = nil

	-- Tenta até 20 posições aleatórias até achar uma com chão
	repeat
		attempts += 1
		local angle = math.random() * 2 * math.pi
		local dist  = math.random(10, AF.teleportRadius)
		local rx    = math.cos(angle) * dist
		local rz    = math.sin(angle) * dist

		-- Começa o raycast de cima (500 studs acima do ponto aleatório)
		local testOrigin = Vector3.new(origin.X + rx, origin.Y + 500, origin.Z + rz)
		landPos = FindGround(testOrigin)
	until landPos or attempts >= 20

	if landPos then
		hrp.CFrame = CFrame.new(landPos)
	else
		warn("[AutoFarm] Não encontrou chão válido para teleportar!")
	end
end

-- Indicador de status na tela
local StatusLabel = nil

local function CreateStatusLabel()
	if StatusLabel then return end
	StatusLabel = Instance.new("TextLabel", Hub)
	StatusLabel.Size = UDim2.fromOffset(320, 28)
	StatusLabel.Position = UDim2.new(0, 10, 1, -36)
	StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 5, 35)
	StatusLabel.BackgroundTransparency = 0.2
	StatusLabel.BorderSizePixel = 0
	StatusLabel.TextColor3 = Color3.new(1, 1, 1)
	StatusLabel.Font = Enum.Font.GothamBold
	StatusLabel.TextScaled = true
	StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	StatusLabel.ZIndex = 5
	Instance.new("UICorner", StatusLabel).CornerRadius = UDim.new(0, 8)
	Instance.new("UIPadding", StatusLabel).PaddingLeft = UDim.new(0, 8)
end

local function UpdateStatus()
	if not StatusLabel then CreateStatusLabel() end
	local g = AF.grabActive    and "✅" or "⏹"
	local t = AF.teleportActive and "✅" or "⏹"
	local s = AF.sellActive    and "✅" or "⏹"
	StatusLabel.Text = g.." Grab  "..t.." Tele  "..s.." Sell"
end

----------------------------------------------------------------
-- LOOPS DE AUTO FARM
----------------------------------------------------------------

-- AUTO GRAB
local function StartGrab()
	if AF.grabThread then return end
	AF.grabActive = true
	AF.grabThread = task.spawn(function()
		while AF.grabActive do
			SimulateClick(AF.grabClickPos)
			task.wait(AF.grabInterval / 1000)
		end
	end)
	UpdateStatus()
end

local function StopGrab()
	AF.grabActive = false
	if AF.grabThread then
		task.cancel(AF.grabThread)
		AF.grabThread = nil
	end
	UpdateStatus()
end

-- TELEPORT ALEATÓRIO
local function StartTeleport()
	if AF.teleportThread then return end
	AF.teleportActive = true
	AF.teleportThread = task.spawn(function()
		while AF.teleportActive do
			task.wait(AF.teleportInterval)
			if AF.teleportActive then
				TeleportRandom()
			end
		end
	end)
	UpdateStatus()
end

local function StopTeleport()
	AF.teleportActive = false
	if AF.teleportThread then
		task.cancel(AF.teleportThread)
		AF.teleportThread = nil
	end
	UpdateStatus()
end

-- AUTO SELL
local function StartSell()
	if AF.sellThread then return end
	AF.sellActive = true
	AF.sellThread = task.spawn(function()
		while AF.sellActive do
			task.wait(AF.sellInterval)
			if AF.sellActive then
				SimulateClick(AF.sellClickPos)
			end
		end
	end)
	UpdateStatus()
end

local function StopSell()
	AF.sellActive = false
	if AF.sellThread then
		task.cancel(AF.sellThread)
		AF.sellThread = nil
	end
	UpdateStatus()
end

-- Liga/desliga Grab + Teleport juntos (via keybind ou checkbox)
local function ToggleGrab(state)
	if state then
		StartGrab()
		StartTeleport()
	else
		StopGrab()
		StopTeleport()
	end
end

----------------------------------------------------------------
-- KEYBIND [G] — ATIVA/DESATIVA AUTO GRAB + TELEPORT
----------------------------------------------------------------

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.G then
		local newState = not AF.grabActive
		ToggleGrab(newState)

		-- Feedback visual rápido no hub (pisca o status)
		if StatusLabel then
			local original = StatusLabel.BackgroundColor3
			StatusLabel.BackgroundColor3 = newState
				and Color3.fromRGB(40, 10, 70)
				or  Color3.fromRGB(60, 0, 0)
			task.delay(0.3, function()
				if StatusLabel then
					StatusLabel.BackgroundColor3 = Color3.fromRGB(20, 5, 35)
				end
			end)
		end

		-- Sincroniza checkbox se a aba estiver aberta
		if _G.N3onHub._grabCheckRef then
			_G.N3onHub._grabCheckRef(newState)
		end
	end
end)

----------------------------------------------------------------
-- CAPTURA DE POSIÇÃO DE CLIQUE (modo de configuração)
----------------------------------------------------------------

local capturingGrab = false
local capturingSell = false
local captureConn   = nil

local function StopCapture()
	capturingGrab = false
	capturingSell = false
	if captureConn then captureConn:Disconnect(); captureConn = nil end
end

local function StartCapture(forGrab, onDone)
	StopCapture()
	if forGrab then capturingGrab = true else capturingSell = true end

	captureConn = UIS.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local pos = Vector2.new(input.Position.X, input.Position.Y)
			if capturingGrab then AF.grabClickPos = pos end
			if capturingSell then AF.sellClickPos = pos end
			StopCapture()
			if onDone then onDone(pos) end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			StopCapture()
			if onDone then onDone(nil) end
		end
	end)
end

----------------------------------------------------------------
-- WIDGET EXTRA: BOTÃO DE CAPTURA DE POSIÇÃO
----------------------------------------------------------------

local function CaptureButton(label, onCapture)
	local frame = Instance.new("Frame", ScrollContent)
	frame.Size = UDim2.new(1, 0, 0, 40)
	frame.BackgroundTransparency = 0.5
	frame.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
	Instance.new("UICorner", frame)

	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(1, -140, 1, 0)
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label .. " : Centro da tela"
	lbl.Font = Enum.Font.Gotham
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(200, 180, 255)
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.fromOffset(120, 26)
	btn.Position = UDim2.new(1, -130, 0.5, -13)
	btn.Text = "📍 Capturar"
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.BackgroundColor3 = Color3.fromRGB(110, 30, 170)
	btn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", btn)

	btn.MouseButton1Click:Connect(function()
		btn.Text = "🎯 Clique na tela..."
		btn.BackgroundColor3 = Color3.fromRGB(170, 80, 0)
		onCapture(function(pos)
			if pos then
				lbl.Text = label .. string.format(" : (%.0f, %.0f)", pos.X, pos.Y)
				btn.Text = "📍 Reconfigurar"
			else
				btn.Text = "📍 Capturar"
			end
			btn.BackgroundColor3 = Color3.fromRGB(110, 30, 170)
		end)
	end)

	UpdateCanvas()
	return frame
end

----------------------------------------------------------------
-- SEPARADOR VISUAL
----------------------------------------------------------------

local function Separator(label)
	local frame = Instance.new("Frame", ScrollContent)
	frame.Size = UDim2.new(1, 0, 0, 28)
	frame.BackgroundTransparency = 1

	local line = Instance.new("Frame", frame)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.Position = UDim2.new(0, 0, 0.5, 0)
	line.BackgroundColor3 = Color3.fromRGB(100, 40, 150)
	line.BorderSizePixel = 0

	if label and label ~= "" then
		local txt = Instance.new("TextLabel", frame)
		txt.Size = UDim2.new(0, 120, 1, 0)
		txt.Position = UDim2.new(0.5, -60, 0, 0)
		txt.BackgroundColor3 = Color3.fromRGB(35, 15, 60)
		txt.BorderSizePixel = 0
		txt.Text = label
		txt.Font = Enum.Font.GothamBold
		txt.TextScaled = true
		txt.TextColor3 = Color3.fromRGB(180, 120, 255)
	end

	UpdateCanvas()
	return frame
end

----------------------------------------------------------------
-- INFO LABEL
----------------------------------------------------------------

local function InfoLabel(text)
	local lbl = Instance.new("TextLabel", ScrollContent)
	lbl.Size = UDim2.new(1, 0, 0, 24)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.Gotham
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(160, 130, 200)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	UpdateCanvas()
	return lbl
end

----------------------------------------------------------------
-- LOAD AUTO FARM TAB
----------------------------------------------------------------

local function LoadAutoFarm()
	Clear()

	-- ══════════════════════════════
	--  AUTO GRAB
	-- ══════════════════════════════
	Separator("🖱️  AUTO GRAB")
	InfoLabel("  Keybind: [G] — Ativa/Desativa Grab + Teleport")

	-- Checkbox com referência global pra sincronizar com o keybind
	local grabCheckbox = Checkbox("Auto Grab", AF.grabActive, function(v)
		ToggleGrab(v)
	end)
	-- Guarda referência pra o keybind poder sincronizar visualmente
	-- (só atualiza o estado interno, não o visual do checkbox por limitação do widget)
	_G.N3onHub._grabCheckRef = function(state)
		AF.grabActive = state  -- o loop já foi iniciado pelo ToggleGrab
	end

	Slider("Intervalo de Grab (ms)", 100, 3000, AF.grabInterval, function(v)
		AF.grabInterval = v
	end)

	CaptureButton("📌 Pos. de Grab", function(callback)
		StartCapture(true, callback)
	end)

	-- ══════════════════════════════
	--  TELEPORTE ALEATÓRIO
	-- ══════════════════════════════
	Separator("🌀  TELEPORTE ALEATÓRIO")
	InfoLabel("  Ativa automaticamente com o Auto Grab")
	InfoLabel("  Raio máximo: 4096 studs · Busca chão válido")

	Slider("Intervalo entre Teleports (s)", 1, 60, AF.teleportInterval, function(v)
		AF.teleportInterval = v
	end)

	Slider("Raio máximo (studs)", 50, 4096, AF.teleportRadius, function(v)
		AF.teleportRadius = v
	end)

	-- ══════════════════════════════
	--  AUTO SELL
	-- ══════════════════════════════
	Separator("💰  AUTO SELL")

	Checkbox("Auto Sell", AF.sellActive, function(v)
		if v then StartSell() else StopSell() end
	end)

	Slider("Intervalo de Venda (s)", 1, 120, AF.sellInterval, function(v)
		AF.sellInterval = v
	end)

	CaptureButton("📌 Pos. de Sell", function(callback)
		StartCapture(false, callback)
	end)

	-- ══════════════════════════════
	--  STATUS GERAL
	-- ══════════════════════════════
	Separator("")
	InfoLabel("  Status atual:")
	local statusLine = Instance.new("TextLabel", ScrollContent)
	statusLine.Size = UDim2.new(1, 0, 0, 30)
	statusLine.BackgroundColor3 = Color3.fromRGB(25, 8, 45)
	statusLine.BackgroundTransparency = 0.2
	statusLine.Text = ""
	statusLine.Font = Enum.Font.GothamBold
	statusLine.TextScaled = true
	statusLine.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", statusLine)
	Instance.new("UIPadding", statusLine).PaddingLeft = UDim.new(0, 8)

	-- Atualiza a linha de status em tempo real
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not statusLine or not statusLine.Parent then
			conn:Disconnect(); return
		end
		local g = AF.grabActive    and "✅ Grab" or "⏹ Grab"
		local t = AF.teleportActive and "✅ Tele" or "⏹ Tele"
		local s = AF.sellActive    and "✅ Sell" or "⏹ Sell"
		statusLine.Text = "  "..g.."   "..t.."   "..s
	end)

	UpdateCanvas()
end

----------------------------------------------------------------
-- REGISTRA A ABA NO SIDEBAR
----------------------------------------------------------------

Tab("Auto Farm", "🌾", 0, LoadAutoFarm)

----------------------------------------------------------------
-- STATUS LABEL PERSISTENTE (canto da tela)
----------------------------------------------------------------

CreateStatusLabel()
UpdateStatus()

print("[N3on Hub] Módulo Auto Farm carregado! Keybind: [G]")
