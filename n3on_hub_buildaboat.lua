-- N3on Hub - Build a Boat for Treasure Module
-- Funcionalidades exclusivas para Build a Boat

if not _G.N3onHub then
	warn("[Build a Boat Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer

print("[Build a Boat Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------

_G.N3onHub.SavedStates.walkOnWater = false
_G.N3onHub.SavedStates.autoWin = false
_G.N3onHub.SavedStates.autoCollectPortals = false
_G.N3onHub.SavedStates.infiniteJetpack = false
_G.N3onHub.SavedStates.instantBuild = false
_G.N3onHub.SavedStates.noClip = false

local antiWaterParts = {}
local autoWinActive = false
local autoCollectActive = false
local infiniteJetpackActive = false
local instantBuildActive = false
local noClipActive = false

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
-- AUTO COLLECT PORTALS
----------------------------------------------------------------

local function AutoCollectPortals()
	while autoCollectActive do
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		
		if hrp then
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj.Name == "Portal" or obj.Name == "DarknessPart" or (obj:IsA("Part") and obj.BrickColor == BrickColor.new("Dark indigo")) then
					if obj:IsA("BasePart") then
						hrp.CFrame = obj.CFrame
						task.wait(0.1)
					end
				end
			end
		end
		
		task.wait(0.5)
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

	HRP.CFrame = CFrame.new(pos1)
	task.wait(0.3)

	if not autoWinActive or died then
		workspace.Gravity = originalGravity
		return
	end

	-- Tween direto sem paradas
	local distance = (pos2 - HRP.Position).Magnitude
	local duration = distance / 500

	local tween1 = TweenService:Create(
		HRP,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{CFrame = CFrame.new(pos2)}
	)

	tween1:Play()
	tween1.Completed:Wait()

	if not autoWinActive or died then
		workspace.Gravity = originalGravity
		return
	end

	task.wait(0.3)

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
		spawn(AutoWin)
	end
end)

----------------------------------------------------------------
-- INFINITE JETPACK
----------------------------------------------------------------

local function StartInfiniteJetpack()
	infiniteJetpackActive = true
	
	spawn(function()
		while infiniteJetpackActive do
			local char = Player.Character
			if char then
				local jetpack = char:FindFirstChild("Jetpack")
				if jetpack then
					local fuel = jetpack:FindFirstChild("Fuel")
					if fuel and fuel:IsA("NumberValue") then
						fuel.Value = 100
					end
				end
			end
			task.wait(0.1)
		end
	end)
end

----------------------------------------------------------------
-- INSTANT BUILD
----------------------------------------------------------------

local function StartInstantBuild()
	instantBuildActive = true
	
	spawn(function()
		while instantBuildActive do
			local buildTime = game:GetService("ReplicatedStorage"):FindFirstChild("BuildTime")
			if buildTime and buildTime:IsA("NumberValue") then
				buildTime.Value = 0
			end
			task.wait(0.5)
		end
	end)
end

----------------------------------------------------------------
-- NO CLIP
----------------------------------------------------------------

local noClipConnection

local function StartNoClip()
	noClipActive = true
	
	noClipConnection = RunService.Stepped:Connect(function()
		if noClipActive and Player.Character then
			for _, part in pairs(Player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)
end

local function StopNoClip()
	noClipActive = false
	if noClipConnection then
		noClipConnection:Disconnect()
		noClipConnection = nil
	end
end

----------------------------------------------------------------
-- TELEPORTS
----------------------------------------------------------------

local function TeleportToStart()
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(10, 20, 363)
	end
end

local function TeleportToEnd()
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(-56, -359, 9497)
	end
end

local function TeleportToStage()
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		local stages = workspace:FindFirstChild("Stages")
		if stages then
			for _, stage in pairs(stages:GetChildren()) do
				if stage:IsA("Model") and stage:FindFirstChild("DarknessPart") then
					Player.Character.HumanoidRootPart.CFrame = stage.DarknessPart.CFrame + Vector3.new(0, 10, 0)
					break
				end
			end
		end
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
	title.Text = "🚀 Auto Farm - Build a Boat"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 100)

	local infoLabel = Instance.new("TextLabel", ScrollContent)
	infoLabel.Size = UDim2.new(1, 0, 0, 70)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Auto Win goes straight to end!\nAuto Collect gets all portals."
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextWrapped = true

	local farmTitle = Instance.new("TextLabel", ScrollContent)
	farmTitle.Size = UDim2.new(1, 0, 0, 35)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "⚡ Auto Farm"
	farmTitle.Font = Enum.Font.GothamBold
	farmTitle.TextSize = 16
	farmTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
	farmTitle.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Auto Win", _G.N3onHub.SavedStates.autoWin, function(v)
		_G.N3onHub.SavedStates.autoWin = v
		autoWinActive = v
		if v then spawn(AutoWin) end
	end)

	_G.N3onHub.Checkbox("Auto Collect Portals", _G.N3onHub.SavedStates.autoCollectPortals, function(v)
		_G.N3onHub.SavedStates.autoCollectPortals = v
		autoCollectActive = v
		if v then spawn(AutoCollectPortals) end
	end)

	local boostTitle = Instance.new("TextLabel", ScrollContent)
	boostTitle.Size = UDim2.new(1, 0, 0, 35)
	boostTitle.BackgroundTransparency = 1
	boostTitle.Text = "🚀 Boosts"
	boostTitle.Font = Enum.Font.GothamBold
	boostTitle.TextSize = 16
	boostTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
	boostTitle.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Infinite Jetpack", _G.N3onHub.SavedStates.infiniteJetpack, function(v)
		_G.N3onHub.SavedStates.infiniteJetpack = v
		if v then StartInfiniteJetpack() else infiniteJetpackActive = false end
	end)

	_G.N3onHub.Checkbox("Instant Build", _G.N3onHub.SavedStates.instantBuild, function(v)
		_G.N3onHub.SavedStates.instantBuild = v
		if v then StartInstantBuild() else instantBuildActive = false end
	end)

	_G.N3onHub.Checkbox("No Clip", _G.N3onHub.SavedStates.noClip, function(v)
		_G.N3onHub.SavedStates.noClip = v
		if v then StartNoClip() else StopNoClip() end
	end)

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
	tpEndBtn.Text = "🎯 TP to End"
	tpEndBtn.Font = Enum.Font.GothamBold
	tpEndBtn.TextSize = 14
	tpEndBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 180)
	tpEndBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpEndBtn)
	tpEndBtn.MouseButton1Click:Connect(TeleportToEnd)

	local tpStageBtn = Instance.new("TextButton", ScrollContent)
	tpStageBtn.Size = UDim2.new(1, 0, 0, 40)
	tpStageBtn.Text = "🌟 TP to Current Stage"
	tpStageBtn.Font = Enum.Font.GothamBold
	tpStageBtn.TextSize = 14
	tpStageBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
	tpStageBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpStageBtn)
	tpStageBtn.MouseButton1Click:Connect(TeleportToStage)

	UpdateCanvasSize()
end

----------------------------------------------------------------
-- LOAD PLAYER TAB
----------------------------------------------------------------

local originalLoadPlayer = _G.N3onHub.LoadPlayer

local function LoadPlayerBuildABoat()
	originalLoadPlayer()
	
	_G.N3onHub.Slider("Fly Speed", 10, 500, _G.N3onHub.SavedStates.flySpeed or 50, function(v)
		_G.N3onHub.SavedStates.flySpeed = v
	end)
	
	_G.N3onHub.Checkbox("Walk on Water", _G.N3onHub.SavedStates.walkOnWater, function(v)
		_G.N3onHub.SavedStates.walkOnWater = v
		if v then CreateAntiWater() else RemoveAntiWater() end
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
print("Features: Auto Win, Auto Portals, Infinite Jetpack, Instant Build, No Clip, Super Fly (500 speed)")
