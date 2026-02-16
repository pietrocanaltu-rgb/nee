-- N3on Hub - Blox Fruits Module
-- Funcionalidades exclusivas para Blox Fruits

if not _G.N3onHub then
	warn("[Blox Fruits Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer

print("[Blox Fruits Module] Loading...")

----------------------------------------------------------------
-- CHEST SYSTEM
----------------------------------------------------------------

local ignoredChests = {}
local chestsCollectedThisSession = 0
local chestConnections = {}
local autoChestActive = false
local autoChestTween = nil

_G.N3onHub.SavedStates.autoChest = false
_G.N3onHub.SavedStates.tweenSpeed = 1
_G.N3onHub.SavedStates.hitboxExpander = false
_G.N3onHub.SavedStates.hitboxSize = 50

local modifiedEnemies = {}
local originalSizes = {}
local hitboxConnection = nil

local function IsChestIgnored(chest)
	if ignoredChests[chest] then
		if chest and chest.Parent then
			return true
		else
			ignoredChests[chest] = nil
			if chestConnections[chest] then
				chestConnections[chest]:Disconnect()
				chestConnections[chest] = nil
			end
			return false
		end
	end
	return false
end

local function MarkChestAsCollected(chest)
	if not chest then return end
	
	ignoredChests[chest] = true
	chestsCollectedThisSession = chestsCollectedThisSession + 1
	
	if not chestConnections[chest] then
		chestConnections[chest] = chest.AncestryChanged:Connect(function(_, parent)
			if not parent then
				task.wait(1)
				ignoredChests[chest] = nil
				if chestConnections[chest] then
					chestConnections[chest]:Disconnect()
					chestConnections[chest] = nil
				end
			end
		end)
	end
end

local function GetClosestChest()
	local closest = nil
	local closestDist = math.huge
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if not hrp then return nil end

	local chestsFolder = workspace:FindFirstChild("ChestModels")
	if chestsFolder then
		for _, chest in ipairs(chestsFolder:GetChildren()) do
			if chest:IsA("Model") and chest.PrimaryPart then
				if not IsChestIgnored(chest.PrimaryPart) then
					local dist = (hrp.Position - chest.PrimaryPart.Position).Magnitude
					if dist < closestDist then
						closest = chest.PrimaryPart
						closestDist = dist
					end
				end
			end
		end
	end

	return closest
end

local function StartAutoChest()
	while autoChestActive do
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if not hrp then
			task.wait(0.5)
			continue
		end

		local chest = GetClosestChest()
		if not chest then
			local toRemove = {}
			for c, _ in pairs(ignoredChests) do
				if not c or not c.Parent then
					table.insert(toRemove, c)
				end
			end
			for _, c in ipairs(toRemove) do
				ignoredChests[c] = nil
				if chestConnections[c] then
					chestConnections[c]:Disconnect()
					chestConnections[c] = nil
				end
			end
			
			task.wait(2)
			continue
		end

		local targetCFrame = chest.CFrame
		local distance = (hrp.Position - targetCFrame.Position).Magnitude
		local speed = _G.N3onHub.SavedStates.tweenSpeed or 1
		local duration = distance / (speed * 50)

		autoChestTween = TweenService:Create(
			hrp,
			TweenInfo.new(duration, Enum.EasingStyle.Linear),
			{CFrame = targetCFrame + Vector3.new(0, 3, 0)}
		)

		autoChestTween:Play()
		autoChestTween.Completed:Wait()

		MarkChestAsCollected(chest)
		task.wait(1)
	end
end

local function StopAutoChest()
	autoChestActive = false

	if autoChestTween then
		autoChestTween:Cancel()
		autoChestTween = nil
	end
	
	for chest, connection in pairs(chestConnections) do
		if connection then
			connection:Disconnect()
		end
	end
	chestConnections = {}
end

----------------------------------------------------------------
-- HITBOX EXPANDER SYSTEM
----------------------------------------------------------------

local function ExpandEnemyHitbox(enemy)
	if not enemy or not enemy:IsA("Model") then return end
	if modifiedEnemies[enemy] then return end
	
	local torso = enemy:FindFirstChild("Torso") or enemy:FindFirstChild("UpperTorso")
	if not torso or not torso:IsA("BasePart") then return end
	
	-- Salvar tamanho original
	if not originalSizes[enemy] then
		originalSizes[enemy] = {}
	end
	
	originalSizes[enemy][torso] = torso.Size
	
	-- Expandir hitbox do torso
	local hitboxSize = _G.N3onHub.SavedStates.hitboxSize or 50
	torso.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
	torso.Transparency = 1
	torso.CanCollide = false
	
	modifiedEnemies[enemy] = true
end

local function RestoreEnemyHitbox(enemy)
	if not enemy or not originalSizes[enemy] then return end
	
	for part, originalSize in pairs(originalSizes[enemy]) do
		if part and part.Parent then
			part.Size = originalSize
			part.Transparency = 0
			part.CanCollide = true
		end
	end
	
	originalSizes[enemy] = nil
	modifiedEnemies[enemy] = nil
end

local function RestoreAllHitboxes()
	for enemy, _ in pairs(modifiedEnemies) do
		RestoreEnemyHitbox(enemy)
	end
	modifiedEnemies = {}
	originalSizes = {}
end

local function StartHitboxExpander()
	hitboxConnection = RunService.Heartbeat:Connect(function()
		if _G.N3onHub.SavedStates.hitboxExpander then
			local enemiesFolder = workspace:FindFirstChild("Enemies")
			if enemiesFolder then
				for _, enemy in ipairs(enemiesFolder:GetChildren()) do
					if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") then
						local humanoid = enemy.Humanoid
						if humanoid.Health > 0 then
							ExpandEnemyHitbox(enemy)
						end
					end
				end
			end
		end
	end)
end

local function StopHitboxExpander()
	if hitboxConnection then
		hitboxConnection:Disconnect()
		hitboxConnection = nil
	end
	RestoreAllHitboxes()
end

----------------------------------------------------------------
-- LOAD BLOX FRUITS FARM TAB
----------------------------------------------------------------

local function LoadBloxFruitsFarm()
	_G.N3onHub.GUI.Clear()

	local ScrollContent = _G.N3onHub.GUI.ScrollContent
	local UpdateCanvasSize = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", ScrollContent)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "🎁 Auto Farm - Blox Fruits"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 100)

	local infoLabel = Instance.new("TextLabel", ScrollContent)
	infoLabel.Size = UDim2.new(1, 0, 0, 90)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Auto Chest teleports you to chests.\nChests won't be revisited until they respawn.\nCounter shows total collected this session!"
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextWrapped = true

	-- Chest Status
	local statusLabel = Instance.new("TextLabel", ScrollContent)
	statusLabel.Size = UDim2.new(1, 0, 0, 50)
	statusLabel.BackgroundColor3 = Color3.fromRGB(40, 20, 70)
	statusLabel.BackgroundTransparency = 0.3
	statusLabel.Text = "📦 Session Total: " .. chestsCollectedThisSession
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextScaled = true
	statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	Instance.new("UICorner", statusLabel)
	Instance.new("UIStroke", statusLabel).Color = Color3.fromRGB(140, 0, 255)

	spawn(function()
		while statusLabel and statusLabel.Parent do
			statusLabel.Text = "📦 Session Total: " .. chestsCollectedThisSession
			task.wait(0.5)
		end
	end)

	local resetBtn = Instance.new("TextButton", ScrollContent)
	resetBtn.Size = UDim2.new(1, 0, 0, 40)
	resetBtn.Text = "🔄 Reset Counter"
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.TextScaled = true
	resetBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
	resetBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", resetBtn)

	resetBtn.MouseButton1Click:Connect(function()
		chestsCollectedThisSession = 0
		statusLabel.Text = "📦 Session Total: 0"
	end)

	local clearBtn = Instance.new("TextButton", ScrollContent)
	clearBtn.Size = UDim2.new(1, 0, 0, 40)
	clearBtn.Text = "🗑️ Clear Ignored Chests"
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextScaled = true
	clearBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 60)
	clearBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", clearBtn)

	clearBtn.MouseButton1Click:Connect(function()
		for chest, connection in pairs(chestConnections) do
			if connection then
				connection:Disconnect()
			end
		end
		chestConnections = {}
		ignoredChests = {}
	end)

	-- Auto Collect Chests
	_G.N3onHub.Checkbox("Auto Collect Chests", _G.N3onHub.SavedStates.autoChest or false, function(v)
		_G.N3onHub.SavedStates.autoChest = v
		autoChestActive = v

		if v then
			spawn(function()
				StartAutoChest()
			end)
		else
			StopAutoChest()
		end
	end)

	_G.N3onHub.Slider("Tween Speed for Chests", 1, 10, _G.N3onHub.SavedStates.tweenSpeed, function(v)
		_G.N3onHub.SavedStates.tweenSpeed = v
	end)

	-- Hitbox Expander Section
	local hitboxTitle = Instance.new("TextLabel", ScrollContent)
	hitboxTitle.Size = UDim2.new(1, 0, 0, 40)
	hitboxTitle.BackgroundTransparency = 1
	hitboxTitle.Text = "⚔️ Hitbox Expander"
	hitboxTitle.Font = Enum.Font.GothamBold
	hitboxTitle.TextScaled = true
	hitboxTitle.TextColor3 = Color3.fromRGB(255, 100, 100)

	local hitboxInfo = Instance.new("TextLabel", ScrollContent)
	hitboxInfo.Size = UDim2.new(1, 0, 0, 60)
	hitboxInfo.BackgroundTransparency = 1
	hitboxInfo.Text = "Expands enemy torso hitbox, making them easier to hit.\nEnemies become invisible and have no collision."
	hitboxInfo.Font = Enum.Font.Gotham
	hitboxInfo.TextScaled = true
	hitboxInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	hitboxInfo.TextXAlignment = Enum.TextXAlignment.Left
	hitboxInfo.TextWrapped = true

	_G.N3onHub.Checkbox("Enable Hitbox Expander", _G.N3onHub.SavedStates.hitboxExpander or false, function(v)
		_G.N3onHub.SavedStates.hitboxExpander = v

		if v then
			StartHitboxExpander()
		else
			StopHitboxExpander()
		end
	end)

	_G.N3onHub.Slider("Hitbox Size", 0, 100, _G.N3onHub.SavedStates.hitboxSize or 50, function(v)
		_G.N3onHub.SavedStates.hitboxSize = v
		
		-- Atualizar hitboxes já expandidos
		if _G.N3onHub.SavedStates.hitboxExpander then
			for enemy, _ in pairs(modifiedEnemies) do
				local torso = enemy:FindFirstChild("Torso") or enemy:FindFirstChild("UpperTorso")
				if torso and torso:IsA("BasePart") then
					torso.Size = Vector3.new(v, v, v)
				end
			end
		end
	end)

	UpdateCanvasSize()
end

----------------------------------------------------------------
-- REGISTER TAB
----------------------------------------------------------------

_G.N3onHub.Tab("Farm","🎁",160, LoadBloxFruitsFarm)

-- Iniciar hitbox expander se estava ativo
if _G.N3onHub.SavedStates.hitboxExpander then
	StartHitboxExpander()
end

print("[Blox Fruits Module] Loaded successfully!")
print("[Blox Fruits Module] Features:")
print("- Auto Chest system")
print("- Hitbox Expander (0-100)")
