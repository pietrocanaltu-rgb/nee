-- N3on Hub - Build a Boat for Treasure Module
-- Refeito do zero com features funcionais

if not _G.N3onHub then
	warn("[Build a Boat Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

print("[Build a Boat Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------

_G.N3onHub.SavedStates.walkOnWater = false
_G.N3onHub.SavedStates.autoFarmGold = false
_G.N3onHub.SavedStates.autoCollectStages = false
_G.N3onHub.SavedStates.removeObstacles = false
_G.N3onHub.SavedStates.godMode = false

local antiWaterParts = {}
local autoFarmActive = false
local autoStagesActive = false
local godModeActive = false

----------------------------------------------------------------
-- ANTI WATER (WALK ON WATER)
----------------------------------------------------------------

local function CreateAntiWater()
	for _, part in pairs(antiWaterParts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	antiWaterParts = {}

	local centerX = 68
	local centerY = -12.6
	local centerZ = 352
	local GRID_SIZE = 2048
	local TOTAL_PARTS_PER_SIDE = 15
	local HALF = math.floor(TOTAL_PARTS_PER_SIDE / 2)

	for i = -HALF, HALF do
		for j = -HALF, HALF do
			local part = Instance.new("Part")
			part.Size = Vector3.new(GRID_SIZE, 0.25, GRID_SIZE)
			part.Anchored = true
			part.CanCollide = true
			part.Transparency = 0.7
			part.Name = "AntiWaterGrid"
			part.CFrame = CFrame.new(centerX + i * GRID_SIZE, centerY, centerZ + j * GRID_SIZE)
			part.Parent = Workspace
			table.insert(antiWaterParts, part)
		end
	end
end

local function RemoveAntiWater()
	for _, part in pairs(antiWaterParts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	antiWaterParts = {}
end

----------------------------------------------------------------
-- AUTO FARM GOLD (FAST & WORKING)
----------------------------------------------------------------

local function AutoFarmGold()
	while autoFarmActive do
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		
		if hrp then
			-- Desabilitar colisão
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
			
			-- Teleportar para o início
			hrp.CFrame = CFrame.new(10, 50, 363)
			task.wait(0.5)
			
			-- Teleportar direto para o final (chest)
			hrp.CFrame = CFrame.new(-56, -300, 9497)
			task.wait(1)
			
			-- Esperar pegar o chest
			task.wait(2)
			
			-- Voltar para o spawn
			hrp.CFrame = CFrame.new(10, 50, 363)
			task.wait(3)
		else
			task.wait(1)
		end
	end
end

----------------------------------------------------------------
-- AUTO COLLECT STAGES (PEGAR TODOS OS PORTAIS)
----------------------------------------------------------------

local function AutoCollectStages()
	while autoStagesActive do
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		
		if hrp then
			-- Procurar stages
			local boatStages = Workspace:FindFirstChild("BoatStages")
			if boatStages then
				local normalStages = boatStages:FindFirstChild("NormalStages")
				if normalStages then
					-- Ir para cada stage
					for i = 1, 10 do
						local stageName = "CaveStage" .. i
						local stage = normalStages:FindFirstChild(stageName)
						
						if stage then
							local darknessPart = stage:FindFirstChild("DarknessPart")
							if darknessPart and darknessPart:IsA("BasePart") then
								-- Teleportar para o portal
								hrp.CFrame = darknessPart.CFrame
								task.wait(0.3)
							end
						end
					end
				end
			end
		end
		
		task.wait(1)
	end
end

----------------------------------------------------------------
-- REMOVE OBSTACLES (REMOVE ROCKS E OBSTÁCULOS)
----------------------------------------------------------------

local removedObstacles = {}

local function RemoveObstacles()
	-- Remover pedras e obstáculos
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") then
			if obj.Name:lower():find("rock") or obj.Name:lower():find("obstacle") or obj.Name:lower():find("wall") then
				table.insert(removedObstacles, obj)
				obj.Parent = nil
			end
		elseif obj:IsA("Part") then
			if obj.Name:lower():find("rock") or obj.Name:lower():find("kill") or obj.Name:lower():find("lava") then
				table.insert(removedObstacles, obj)
				obj.CanCollide = false
				obj.Transparency = 1
			end
		end
	end
end

local function RestoreObstacles()
	for _, obj in pairs(removedObstacles) do
		if obj:IsA("Model") then
			obj.Parent = Workspace
		elseif obj:IsA("Part") then
			obj.CanCollide = true
			obj.Transparency = 0
		end
	end
	removedObstacles = {}
end

----------------------------------------------------------------
-- GOD MODE (NO DAMAGE)
----------------------------------------------------------------

local godModeConnection

local function StartGodMode()
	godModeActive = true
	
	godModeConnection = RunService.Heartbeat:Connect(function()
		if godModeActive and Player.Character then
			local humanoid = Player.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Health = humanoid.MaxHealth
			end
		end
	end)
end

local function StopGodMode()
	godModeActive = false
	if godModeConnection then
		godModeConnection:Disconnect()
		godModeConnection = nil
	end
end

----------------------------------------------------------------
-- TELEPORTS
----------------------------------------------------------------

local function TeleportToStart()
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(10, 50, 363)
	end
end

local function TeleportToEnd()
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(-56, -300, 9497)
	end
end

local function TeleportToStage(stageNumber)
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		local boatStages = Workspace:FindFirstChild("BoatStages")
		if boatStages then
			local normalStages = boatStages:FindFirstChild("NormalStages")
			if normalStages then
				local stage = normalStages:FindFirstChild("CaveStage" .. stageNumber)
				if stage then
					local darknessPart = stage:FindFirstChild("DarknessPart")
					if darknessPart then
						Player.Character.HumanoidRootPart.CFrame = darknessPart.CFrame + Vector3.new(0, 10, 0)
					end
				end
			end
		end
	end
end

----------------------------------------------------------------
-- INSTANT RESPAWN
----------------------------------------------------------------

local function InstantRespawn()
	if Player.Character then
		Player.Character:BreakJoints()
		task.wait(0.1)
		Player.CharacterAdded:Wait()
	end
end

----------------------------------------------------------------
-- LOAD BUILD A BOAT FARM TAB
----------------------------------------------------------------

local function LoadBuildABoatFarm()
	_G.N3onHub.GUI.Clear()

	local ScrollContent = _G.N3onHub.GUI.ScrollContent
	local UpdateCanvasSize = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", ScrollContent)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "🚀 Farm - Build a Boat"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 100)

	local infoLabel = Instance.new("TextLabel", ScrollContent)
	infoLabel.Size = UDim2.new(1, 0, 0, 70)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Auto Farm teleports you straight to the chest!\nAuto Stages collects all portals."
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextWrapped = true

	-- Auto Farm Section
	local farmTitle = Instance.new("TextLabel", ScrollContent)
	farmTitle.Size = UDim2.new(1, 0, 0, 35)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "💰 Auto Farm"
	farmTitle.Font = Enum.Font.GothamBold
	farmTitle.TextSize = 16
	farmTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
	farmTitle.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Farm Gold", _G.N3onHub.SavedStates.autoFarmGold, function(v)
		_G.N3onHub.SavedStates.autoFarmGold = v
		autoFarmActive = v
		if v then
			spawn(function()
				AutoFarmGold()
			end)
		end
	end)

	_G.N3onHub.Checkbox("Auto Collect Stages", _G.N3onHub.SavedStates.autoCollectStages, function(v)
		_G.N3onHub.SavedStates.autoCollectStages = v
		autoStagesActive = v
		if v then
			spawn(function()
				AutoCollectStages()
			end)
		end
	end)

	-- Utilities Section
	local utilTitle = Instance.new("TextLabel", ScrollContent)
	utilTitle.Size = UDim2.new(1, 0, 0, 35)
	utilTitle.BackgroundTransparency = 1
	utilTitle.Text = "🛠️ Utilities"
	utilTitle.Font = Enum.Font.GothamBold
	utilTitle.TextSize = 16
	utilTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
	utilTitle.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Remove Obstacles", _G.N3onHub.SavedStates.removeObstacles, function(v)
		_G.N3onHub.SavedStates.removeObstacles = v
		if v then
			RemoveObstacles()
		else
			RestoreObstacles()
		end
	end)

	_G.N3onHub.Checkbox("God Mode", _G.N3onHub.SavedStates.godMode, function(v)
		_G.N3onHub.SavedStates.godMode = v
		if v then
			StartGodMode()
		else
			StopGodMode()
		end
	end)

	-- Teleports Section
	local tpTitle = Instance.new("TextLabel", ScrollContent)
	tpTitle.Size = UDim2.new(1, 0, 0, 35)
	tpTitle.BackgroundTransparency = 1
	tpTitle.Text = "📍 Teleports"
	tpTitle.Font = Enum.Font.GothamBold
	tpTitle.TextSize = 16
	tpTitle.TextColor3 = Color3.fromRGB(255, 255, 100)
	tpTitle.TextXAlignment = Enum.TextXAlignment.Left

	local tpStartBtn = Instance.new("TextButton", ScrollContent)
	tpStartBtn.Size = UDim2.new(1, 0, 0, 40)
	tpStartBtn.Text = "🏁 TP to Start"
	tpStartBtn.Font = Enum.Font.GothamBold
	tpStartBtn.TextSize = 14
	tpStartBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
	tpStartBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpStartBtn)
	tpStartBtn.MouseButton1Click:Connect(TeleportToStart)

	local tpEndBtn = Instance.new("TextButton", ScrollContent)
	tpEndBtn.Size = UDim2.new(1, 0, 0, 40)
	tpEndBtn.Text = "🎯 TP to End (Chest)"
	tpEndBtn.Font = Enum.Font.GothamBold
	tpEndBtn.TextSize = 14
	tpEndBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 180)
	tpEndBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpEndBtn)
	tpEndBtn.MouseButton1Click:Connect(TeleportToEnd)

	local respawnBtn = Instance.new("TextButton", ScrollContent)
	respawnBtn.Size = UDim2.new(1, 0, 0, 40)
	respawnBtn.Text = "🔄 Instant Respawn"
	respawnBtn.Font = Enum.Font.GothamBold
	respawnBtn.TextSize = 14
	respawnBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
	respawnBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", respawnBtn)
	respawnBtn.MouseButton1Click:Connect(InstantRespawn)

	-- Stage Teleports
	local stageTitle = Instance.new("TextLabel", ScrollContent)
	stageTitle.Size = UDim2.new(1, 0, 0, 30)
	stageTitle.BackgroundTransparency = 1
	stageTitle.Text = "TP to Stages (1-10):"
	stageTitle.Font = Enum.Font.Gotham
	stageTitle.TextSize = 12
	stageTitle.TextColor3 = Color3.new(1, 1, 1)
	stageTitle.TextXAlignment = Enum.TextXAlignment.Left

	for i = 1, 10 do
		local stageBtn = Instance.new("TextButton", ScrollContent)
		stageBtn.Size = UDim2.new(1, 0, 0, 35)
		stageBtn.Text = "Stage " .. i
		stageBtn.Font = Enum.Font.Gotham
		stageBtn.TextSize = 12
		stageBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
		stageBtn.TextColor3 = Color3.new(1, 1, 1)
		Instance.new("UICorner", stageBtn)
		
		stageBtn.MouseButton1Click:Connect(function()
			TeleportToStage(i)
		end)
	end

	UpdateCanvasSize()
end

----------------------------------------------------------------
-- LOAD PLAYER TAB (WITH SUPER FLY)
----------------------------------------------------------------

local originalLoadPlayer = _G.N3onHub.LoadPlayer

local function LoadPlayerBuildABoat()
	originalLoadPlayer()
	
	-- Super Fly Speed (até 500)
	_G.N3onHub.Slider("Fly Speed", 10, 500, _G.N3onHub.SavedStates.flySpeed or 50, function(v)
		_G.N3onHub.SavedStates.flySpeed = v
	end)
	
	_G.N3onHub.Checkbox("Walk on Water", _G.N3onHub.SavedStates.walkOnWater, function(v)
		_G.N3onHub.SavedStates.walkOnWater = v
		if v then
			CreateAntiWater()
		else
			RemoveAntiWater()
		end
	end)
end

_G.N3onHub.LoadPlayer = LoadPlayerBuildABoat

for _, btn in pairs(_G.N3onHub.GUI.F2:GetChildren()) do
	if btn:IsA("TextButton") and btn.Text:find("Player") then
		btn.MouseButton1Click:Connect(LoadPlayerBuildABoat)
	end
end

----------------------------------------------------------------
-- REGISTER TAB
----------------------------------------------------------------

_G.N3onHub.Tab("Farm","🚀",160, LoadBuildABoatFarm)

print("[Build a Boat Module] Loaded!")
print("Features: Auto Farm Gold, Auto Collect Stages, Remove Obstacles, God Mode, Super Fly")
