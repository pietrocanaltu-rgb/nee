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

local antiWaterParts = {}
local boatFlying = false
local boatFlySpeed = 50
local autoWinActive = false
local currentTween = nil
local boatFlyConnection = nil

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
-- AUTO WIN
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

	local function restoreGravity()
		workspace.Gravity = originalGravity
	end

	local died = false
	local deathConnection
	deathConnection = Humanoid.Died:Connect(function()
		died = true
		deathConnection:Disconnect()
	end)

	for _, part in ipairs(Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local pos1 = Vector3.new(-58, 90, 304)
	local pos2 = Vector3.new(-57, 90, 8631)
	local pos3 = Vector3.new(-56, -359, 9497)

	HRP.CFrame = CFrame.new(pos1)
	task.wait(0.5)
	if not autoWinActive then 
		restoreGravity()
		return 
	end

	local function SafePlay(tween)
		tween:Play()
		while tween.PlaybackState == Enum.PlaybackState.Playing do
			if not autoWinActive then
				tween:Cancel()
				restoreGravity()
				return false
			end
			if died then
				tween:Cancel()
				restoreGravity()
				return false
			end
			task.wait()
		end
		return true
	end

	local speed = 500
	local segmentDistance = 1000

	local direction = (pos2 - HRP.Position).Unit
	local totalDistance = (pos2 - HRP.Position).Magnitude
	local traveled = 0

	while traveled < totalDistance do
		if not autoWinActive then 
			restoreGravity()
			return 
		end

		if died then
			restoreGravity()
			return
		end

		local moveDist = math.min(segmentDistance, totalDistance - traveled)
		local nextPos = HRP.Position + direction * moveDist
		local duration = moveDist / speed

		local tween = TweenService:Create(
			HRP,
			TweenInfo.new(duration, Enum.EasingStyle.Linear),
			{CFrame = CFrame.new(nextPos)}
		)

		if not SafePlay(tween) then
			restoreGravity()
			return 
		end

		traveled = traveled + moveDist

		HRP.Anchored = true
		local t = 0
		while t < 0.5 do
			if not autoWinActive then
				HRP.Anchored = false
				restoreGravity()
				return
			end
			if died then
				HRP.Anchored = false
				restoreGravity()
				return
			end
			t = t + task.wait()
		end
		HRP.Anchored = false
	end

	local distance3 = (HRP.Position - pos3).Magnitude
	local duration3 = distance3 / 200

	local finalTween = TweenService:Create(
		HRP,
		TweenInfo.new(duration3, Enum.EasingStyle.Linear),
		{CFrame = CFrame.new(pos3)}
	)

	if not SafePlay(finalTween) then
		restoreGravity()
		return
	end

	HRP.Anchored = true
	restoreGravity()

	if deathConnection then
		deathConnection:Disconnect()
	end
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
	infoLabel.Text = "Auto Win will tween you to the end chest.\nAuto-respawns when you die!"
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

print("[Build a Boat Module] Loaded successfully! Auto Win, Boat Fly, and Walk on Water ready.")
