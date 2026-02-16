-- N3on Hub - Build a Boat for Treasure Module
-- Funcionalidades exclusivas para Build a Boat

if not _G.N3onHub then
	warn("[Build a Boat Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer

print("[Build a Boat Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------

_G.N3onHub.SavedStates.walkOnWater = false
_G.N3onHub.SavedStates.autoWin = false
_G.N3onHub.SavedStates.boatFly = false
_G.N3onHub.SavedStates.boatFlySpeed = 50
_G.N3onHub.SavedStates.removeObstacles = false

local antiWaterParts = {}
local boatFlying = false
local boatFlySpeed = 50
local autoWinActive = false
local currentTween = nil
local boatFlyConnection = nil
local removedObstacles = {}

----------------------------------------------------------------
-- ANTI WATER
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

	local function CreatePart(x, z)
		local part = Instance.new("Part")
		part.Size = Vector3.new(GRID_SIZE, 0.25, GRID_SIZE)
		part.Anchored = true
		part.CanCollide = true
		part.Transparency = 0.7
		part.Name = "AntiWaterGrid"
		part.CFrame = CFrame.new(x, centerY, z)
		part.Parent = workspace

		table.insert(antiWaterParts, part)
	end

	for i = -HALF, HALF do
		for j = -HALF, HALF do
			local xPos = centerX + i * GRID_SIZE
			local zPos = centerZ + j * GRID_SIZE
			CreatePart(xPos, zPos)
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
-- REMOVE OBSTACLES
----------------------------------------------------------------

local function RemoveObstacles()
	-- Remover pedras, obstáculos e partes de kill
	for _, obj in pairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			if obj.Name:lower():find("rock") or obj.Name:lower():find("obstacle") or obj.Name:lower():find("wall") then
				table.insert(removedObstacles, {obj = obj, parent = obj.Parent})
				obj.Parent = nil
			end
		elseif obj:IsA("Part") then
			if obj.Name:lower():find("rock") or obj.Name:lower():find("kill") or obj.Name:lower():find("lava") or obj.Name:lower():find("damage") then
				table.insert(removedObstacles, {obj = obj, cancollide = obj.CanCollide, transparency = obj.Transparency})
				obj.CanCollide = false
				obj.Transparency = 1
			end
		end
	end
end

local function RestoreObstacles()
	for _, data in pairs(removedObstacles) do
		if data.obj then
			if data.parent then
				data.obj.Parent = data.parent
			elseif data.cancollide ~= nil then
				data.obj.CanCollide = data.cancollide
				data.obj.Transparency = data.transparency
			end
		end
	end
	removedObstacles = {}
end

----------------------------------------------------------------
-- BOAT FLY
----------------------------------------------------------------

local function StartBoatFly()
	if boatFlyConnection then return end

	boatFlying = true

	boatFlyConnection = RunService.Heartbeat:Connect(function()
		if not boatFlying then
			if boatFlyConnection then
				boatFlyConnection:Disconnect()
				boatFlyConnection = nil
			end
			return
		end

		local char = Player.Character
		if not char then return end

		local boat = nil
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj.Name == "VehicleSeat" and obj:IsA("VehicleSeat") and obj.Occupant == char:FindFirstChild("Humanoid") then
				boat = obj.Parent
				break
			end
		end

		if not boat then return end

		local camera = workspace.CurrentCamera
		local moveDirection = Vector3.new(0, 0, 0)

		if UIS:IsKeyDown(Enum.KeyCode.W) then
			moveDirection = moveDirection + (camera.CFrame.LookVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then
			moveDirection = moveDirection - (camera.CFrame.LookVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then
			moveDirection = moveDirection - (camera.CFrame.RightVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) then
			moveDirection = moveDirection + (camera.CFrame.RightVector)
		end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			moveDirection = moveDirection + Vector3.new(0, 1, 0)
		end
		if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
			moveDirection = moveDirection - Vector3.new(0, 1, 0)
		end

		for _, part in pairs(boat:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Velocity = moveDirection.Unit * boatFlySpeed
				part.RotVelocity = Vector3.new(0, 0, 0)
			end
		end
	end)
end

local function StopBoatFly()
	boatFlying = false
	if boatFlyConnection then
		boatFlyConnection:Disconnect()
		boatFlyConnection = nil
	end
end

----------------------------------------------------------------
-- AUTO WIN (SEM PARADAS)
----------------------------------------------------------------

local function AutoWin()
	if not autoWinActive then return end
	if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local Character = Player.Character
	local HRP = Character.HumanoidRootPart
	local Humanoid = Character:FindFirstChild("Humanoid")

	local originalGravity = workspace.Gravity
	workspace.Gravity = 0

	local died = false
	Humanoid.Died:Connect(function()
		died = true
	end)

	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local pos1 = Vector3.new(-58, 90, 304)
	local pos2 = Vector3.new(-57, 90, 8631)
	local pos3 = Vector3.new(-56, -359, 9497)

	-- Teleportar para o início
	HRP.CFrame = CFrame.new(pos1)
	task.wait(0.3)

	if not autoWinActive or died then
		workspace.Gravity = originalGravity
		return
	end

	-- Tween direto para pos2 SEM PARADAS
	local distance1 = (pos2 - HRP.Position).Magnitude
	local duration1 = distance1 / 500

	local tween1 = TweenService:Create(
		HRP,
		TweenInfo.new(duration1, Enum.EasingStyle.Linear),
		{CFrame = CFrame.new(pos2)}
	)

	tween1:Play()
	tween1.Completed:Wait()

	if not autoWinActive or died then
		workspace.Gravity = originalGravity
		return
	end

	task.wait(0.3)

	-- Tween final para o chest
	local distance2 = (pos3 - HRP.Position).Magnitude
	local duration2 = distance2 / 200

	local tween2 = TweenService:Create(
		HRP,
		TweenInfo.new(duration2, Enum.EasingStyle.Linear),
		{CFrame = CFrame.new(pos3)}
	)

	tween2:Play()
	tween2.Completed:Wait()

	HRP.Anchored = true
	workspace.Gravity = originalGravity
end

Player.CharacterAdded:Connect(function()
	if autoWinActive then
		task.wait(0.5)
		if autoWinActive then
			spawn(function()
				AutoWin()
			end)
		end
	end
end)

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
	title.Text = "🚀 Auto Farm - Build a Boat"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 100)

	local infoLabel = Instance.new("TextLabel", ScrollContent)
	infoLabel.Size = UDim2.new(1, 0, 0, 70)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Auto Win goes straight to the end!\nNo stops, fast and smooth."
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Win", _G.N3onHub.SavedStates.autoWin, function(v)
		_G.N3onHub.SavedStates.autoWin = v
		autoWinActive = v
		if v then
			spawn(function()
				AutoWin()
			end)
		else
			if currentTween then
				currentTween:Cancel()
			end
		end
	end)

	_G.N3onHub.Checkbox("Remove Obstacles", _G.N3onHub.SavedStates.removeObstacles, function(v)
		_G.N3onHub.SavedStates.removeObstacles = v
		if v then
			RemoveObstacles()
		else
			RestoreObstacles()
		end
	end)

	_G.N3onHub.Checkbox("Boat Fly", _G.N3onHub.SavedStates.boatFly or false, function(v)
		_G.N3onHub.SavedStates.boatFly = v
		if v then
			StartBoatFly()
		else
			StopBoatFly()
		end
	end)

	_G.N3onHub.Slider("Boat Fly Speed", 10, 200, _G.N3onHub.SavedStates.boatFlySpeed, function(v)
		_G.N3onHub.SavedStates.boatFlySpeed = v
		boatFlySpeed = v
	end)

	UpdateCanvasSize()
end

----------------------------------------------------------------
-- LOAD PLAYER TAB (WITH WALK ON WATER)
----------------------------------------------------------------

local originalLoadPlayer = _G.N3onHub.LoadPlayer

local function LoadPlayerBuildABoat()
	originalLoadPlayer()
	
	_G.N3onHub.Checkbox("Walk on water", _G.N3onHub.SavedStates.walkOnWater, function(v)
		_G.N3onHub.SavedStates.walkOnWater = v
		if v then
			CreateAntiWater()
		else
			RemoveAntiWater()
		end
	end)
end

-- Sobrescreve a função Player com a versão Build a Boat
_G.N3onHub.LoadPlayer = LoadPlayerBuildABoat

-- Atualiza o botão Player se já existir
for _, btn in pairs(_G.N3onHub.GUI.F2:GetChildren()) do
	if btn:IsA("TextButton") and btn.Text:find("Player") then
		btn.MouseButton1Click:Connect(function()
			LoadPlayerBuildABoat()
		end)
	end
end

----------------------------------------------------------------
-- REGISTER TAB
----------------------------------------------------------------

_G.N3onHub.Tab("Farm","🚀",160, LoadBuildABoatFarm)

print("[Build a Boat Module] Loaded successfully!")
print("[Build a Boat Module] Auto Win (no stops), Remove Obstacles, Boat Fly, Walk on Water ready!")
