-- N3on Hub - Blox Fruits Module
-- Funcionalidades exclusivas para Blox Fruits

if not _G.N3onHub then
	warn("[Blox Fruits Module] Base hub not loaded! Please load the base first.")
	return
end

local TweenService = game:GetService("TweenService")
local Player = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

warn("[Blox Fruits Module] Loading...")

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
	warn("[Auto Chest] Started!")
	while autoChestActive do
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")

		if not hrp then
			warn("[Auto Chest] No HRP, waiting...")
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
			
			warn("[Auto Chest] No chests found, waiting...")
			task.wait(2)
			continue
		end

		warn("[Auto Chest] Teleporting to chest...")
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
		warn("[Auto Chest] Chest collected! Total: " .. chestsCollectedThisSession)
		task.wait(1)
	end
	warn("[Auto Chest] Stopped!")
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
-- AUTO FARM LEVEL SYSTEM (COM QUEST)
----------------------------------------------------------------

local autoFarmActive = false
local autoFarmTween = nil
local currentTarget = nil
local mobsKilledThisSession = 0
local farmConnection = nil
local currentQuest = nil

_G.N3onHub.SavedStates.autoFarm = false
_G.N3onHub.SavedStates.farmSpeed = 1
_G.N3onHub.SavedStates.bringMobs = false

-- Lista de Quests por nível
local QUESTS = {
	-- Kingdom of Rose - Area 1 (700-850)
	{Name = "RaiderQuest1", Level = 700, QuestGiver = "Area 1 Quest Giver", MobName = "Raider"},
	{Name = "MercenaryQuest1", Level = 725, QuestGiver = "Area 1 Quest Giver", MobName = "Mercenary"},
	{Name = "DiamonQuest", Level = 750, QuestGiver = "Area 1 Quest Giver", MobName = "Diamond"}, -- Boss
	
	-- Kingdom of Rose - Area 2 (775-850)
	{Name = "SwanPirateQuest1", Level = 775, QuestGiver = "Area 2 Quest Giver", MobName = "Swan Pirate"},
	{Name = "FactoryStaffQuest", Level = 800, QuestGiver = "Area 2 Quest Giver", MobName = "Factory Staff"},
	{Name = "JeremyQuest", Level = 850, QuestGiver = "Area 2 Quest Giver", MobName = "Jeremy"}, -- Boss
	
	-- Green Zone (875-925)
	{Name = "MarineQuest3", Level = 875, QuestGiver = "Marine Quest Giver", MobName = "Marine Lieutenant"},
	{Name = "MarineCaptainQuest2", Level = 900, QuestGiver = "Marine Quest Giver", MobName = "Marine Captain"},
	{Name = "OrbitusQuest", Level = 925, QuestGiver = "Marine Quest Giver", MobName = "Orbitus"}, -- Boss
	
	-- Graveyard Island (950-975)
	{Name = "ZombieQuest", Level = 950, QuestGiver = "Graveyard Quest Giver", MobName = "Zombie"},
	{Name = "VampireQuest", Level = 975, QuestGiver = "Graveyard Quest Giver", MobName = "Vampire"},
	
	-- Snow Mountain (1000-1050)
	{Name = "SnowMountainQuest", Level = 1000, QuestGiver = "Snow Quest Giver", MobName = "Snow Trooper"},
	{Name = "WinterWarriorQuest", Level = 1050, QuestGiver = "Snow Quest Giver", MobName = "Winter Warrior"},
	
	-- Hot and Cold - Ice Side (1100-1150)
	{Name = "IceSideQuest1", Level = 1100, QuestGiver = "Ice Quest Giver", MobName = "Lab Subordinate"},
	{Name = "IceSideQuest2", Level = 1125, QuestGiver = "Ice Quest Giver", MobName = "Horned Warrior"},
	{Name = "SmokeAdmiralQuest", Level = 1150, QuestGiver = "Ice Quest Giver", MobName = "Smoke Admiral"}, -- Boss
	
	-- Hot and Cold - Fire Side (1175-1200)
	{Name = "FireSideQuest1", Level = 1175, QuestGiver = "Fire Quest Giver", MobName = "Magma Ninja"},
	{Name = "FireSideQuest2", Level = 1200, QuestGiver = "Fire Quest Giver", MobName = "Lava Pirate"},
	
	-- Cursed Ship - Rear (1250-1275)
	{Name = "CursedShipQuest1", Level = 1250, QuestGiver = "Rear Crew Quest Giver", MobName = "Ship Deckhand"},
	{Name = "CursedShipQuest2", Level = 1275, QuestGiver = "Rear Crew Quest Giver", MobName = "Ship Engineer"},
	
	-- Cursed Ship - Front (1300-1325)
	{Name = "ShipStewardQuest", Level = 1300, QuestGiver = "Front Crew Quest Giver", MobName = "Ship Steward"},
	{Name = "ShipOfficerQuest", Level = 1325, QuestGiver = "Front Crew Quest Giver", MobName = "Ship Officer"},
	
	-- Ice Castle (1350-1400)
	{Name = "FrostQuest1", Level = 1350, QuestGiver = "Frost Quest Giver", MobName = "Arctic Warrior"},
	{Name = "FrostQuest2", Level = 1375, QuestGiver = "Frost Quest Giver", MobName = "Snow Lurker"},
	{Name = "AwakenedIceAdmiralQuest", Level = 1400, QuestGiver = "Frost Quest Giver", MobName = "Awakened Ice Admiral"}, -- Boss
	
	-- Forgotten Island (1425-1475)
	{Name = "ForgottenQuest", Level = 1425, QuestGiver = "Forgotten Quest Giver", MobName = "Sea Soldier"},
	{Name = "ForgottenQuest2", Level = 1450, QuestGiver = "Forgotten Quest Giver", MobName = "Water Fighter"},
	{Name = "TideKeeperQuest", Level = 1475, QuestGiver = "Forgotten Quest Giver", MobName = "Tide Keeper"}, -- Boss
}

local function GetPlayerLevel()
	local stats = Player:FindFirstChild("Data")
	if stats then
		local level = stats:FindFirstChild("Level")
		if level then
			return level.Value
		end
	end
	warn("[Auto Farm] Could not find player level!")
	return 700 -- Default para 2nd sea
end

local function GetBestQuestForLevel()
	local playerLevel = GetPlayerLevel()
	warn("[Auto Farm] Player level: " .. playerLevel)
	local bestQuest = QUESTS[1]
	
	for _, quest in ipairs(QUESTS) do
		if quest.Level <= playerLevel then
			bestQuest = quest
		else
			break
		end
	end
	
	return bestQuest
end

local function HasQuest()
	local questFolder = Player:FindFirstChild("QuestFolder")
	if questFolder then
		local quest = questFolder:FindFirstChild("Quest")
		return quest ~= nil
	end
	return false
end

local function TakeQuest(questData)
	if HasQuest() then
		warn("[Auto Farm] Already has quest active!")
		return true
	end
	
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	
	if not hrp then 
		warn("[Auto Farm] No HRP found!")
		return false 
	end
	
	-- Procura o NPC da quest
	local npcs = workspace:FindFirstChild("NPCs")
	if not npcs then 
		warn("[Auto Farm] NPCs folder not found in workspace!")
		return false 
	end
	
	local questGiver = npcs:FindFirstChild(questData.QuestGiver)
	if not questGiver then
		warn("[Auto Farm] Quest Giver not found: " .. questData.QuestGiver)
		warn("[Auto Farm] Available NPCs:")
		for _, npc in ipairs(npcs:GetChildren()) do
			warn("  - " .. npc.Name)
		end
		return false
	end
	
	if not questGiver.PrimaryPart then
		warn("[Auto Farm] Quest Giver has no PrimaryPart!")
		return false
	end
	
	-- Teleporta para o NPC
	warn("[Auto Farm] Teleporting to Quest Giver: " .. questData.QuestGiver)
	local npcPos = questGiver.PrimaryPart.CFrame
	hrp.CFrame = npcPos * CFrame.new(0, 3, 0)
	task.wait(0.5)
	
	-- Tenta pegar a quest via Remote
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		warn("[Auto Farm] Remotes folder not found!")
		return false
	end
	
	local questRemote = remotes:FindFirstChild("CommF_")
	if not questRemote then
		warn("[Auto Farm] CommF_ remote not found!")
		return false
	end
	
	warn("[Auto Farm] Calling StartQuest: " .. questData.Name)
	local success, result = pcall(function()
		return questRemote:InvokeServer("StartQuest", questData.Name, 1)
	end)
	
	if not success then
		warn("[Auto Farm] Error calling StartQuest: " .. tostring(result))
		return false
	end
	
	task.wait(0.5)
	local hasQ = HasQuest()
	warn("[Auto Farm] Quest taken successfully: " .. tostring(hasQ))
	return hasQ
end

local function GetQuestMobs(mobName)
	local mobs = {}
	local enemies = workspace:FindFirstChild("Enemies")
	
	if not enemies then
		warn("[Auto Farm] Enemies folder not found!")
		return mobs
	end
	
	for _, mob in ipairs(enemies:GetChildren()) do
		if mob:IsA("Model") and mob.Name == mobName then
			if mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
				local hum = mob.Humanoid
				if hum.Health > 0 then
					table.insert(mobs, mob)
				end
			end
		end
	end
	
	return mobs
end

local function GetClosestQuestMob(mobName)
	local closest = nil
	local closestDist = math.huge
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	
	if not hrp then return nil end
	
	local mobs = GetQuestMobs(mobName)
	
	for _, mob in ipairs(mobs) do
		local mobHRP = mob:FindFirstChild("HumanoidRootPart")
		if mobHRP then
			local dist = (hrp.Position - mobHRP.Position).Magnitude
			if dist < closestDist then
				closest = mob
				closestDist = dist
			end
		end
	end
	
	return closest
end

local function BringMobs(mobName)
	if not _G.N3onHub.SavedStates.bringMobs then return end
	
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	
	if not hrp then return end
	
	local mobs = GetQuestMobs(mobName)
	
	for _, mob in ipairs(mobs) do
		local mobHRP = mob:FindFirstChild("HumanoidRootPart")
		local mobHum = mob:FindFirstChild("Humanoid")
		
		if mobHRP and mobHum and mobHum.Health > 0 then
			pcall(function()
				mobHRP.CanCollide = false
				mobHRP.Size = Vector3.new(50, 50, 50)
				mobHRP.Transparency = 1
				mobHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -10)
				mobHRP.Velocity = Vector3.new(0, 0, 0)
				
				for _, part in ipairs(mob:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						part.Velocity = Vector3.new(0, 0, 0)
						part.RotVelocity = Vector3.new(0, 0, 0)
					end
				end
				
				mobHum.WalkSpeed = 0
				mobHum.JumpPower = 0
			end)
		end
	end
end

local function EquipWeapon()
	local char = Player.Character
	if not char then return false end
	
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then return true end
	
	for _, item in ipairs(Player.Backpack:GetChildren()) do
		if item:IsA("Tool") then
			char.Humanoid:EquipTool(item)
			warn("[Auto Farm] Equipped weapon: " .. item.Name)
			return true
		end
	end
	
	warn("[Auto Farm] No weapon found in backpack!")
	return false
end

local function AttackMob()
	local char = Player.Character
	if not char then return end
	
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		tool:Activate()
	end
	
	pcall(function()
		local combat = ReplicatedStorage:FindFirstChild("Remotes")
		if combat then
			local attackRemote = combat:FindFirstChild("CommF_")
			if attackRemote then
				attackRemote:InvokeServer("Attack")
			end
		end
	end)
end

local function StartAutoFarm()
	warn("[Auto Farm] STARTING AUTO FARM!")
	autoFarmActive = true
	
	currentQuest = GetBestQuestForLevel()
	warn("[Auto Farm] Selected Quest: " .. currentQuest.Name .. " (Level " .. currentQuest.Level .. ") - Mob: " .. currentQuest.MobName)
	
	if _G.N3onHub.SavedStates.bringMobs then
		warn("[Auto Farm] Bring Mobs is ACTIVE!")
		farmConnection = RunService.Heartbeat:Connect(function()
			if autoFarmActive and currentQuest then
				BringMobs(currentQuest.MobName)
			end
		end)
	end
	
	while autoFarmActive do
		warn("[Auto Farm] === NEW FARM CYCLE ===")
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		
		if not hrp then
			warn("[Auto Farm] No HRP, waiting...")
			task.wait(0.5)
			continue
		end
		
		if not HasQuest() then
			warn("[Auto Farm] No quest active, taking quest...")
			local success = TakeQuest(currentQuest)
			
			if not success then
				warn("[Auto Farm] FAILED TO TAKE QUEST! Waiting 5s...")
				task.wait(5)
				continue
			end
		else
			warn("[Auto Farm] Quest already active!")
		end
		
		EquipWeapon()
		
		local mob = GetClosestQuestMob(currentQuest.MobName)
		
		if not mob then
			warn("[Auto Farm] NO MOBS FOUND for: " .. currentQuest.MobName)
			task.wait(2)
			continue
		end
		
		warn("[Auto Farm] Found mob: " .. mob.Name)
		currentTarget = mob
		local mobHRP = mob:FindFirstChild("HumanoidRootPart")
		local mobHum = mob:FindFirstChild("Humanoid")
		
		if not mobHRP or not mobHum or mobHum.Health <= 0 then
			warn("[Auto Farm] Mob invalid or dead!")
			currentTarget = nil
			task.wait(0.5)
			continue
		end
		
		warn("[Auto Farm] Teleporting to mob...")
		local targetPos = mobHRP.CFrame
		
		if _G.N3onHub.SavedStates.bringMobs then
			hrp.CFrame = targetPos * CFrame.new(0, 10, 0)
		else
			local distance = (hrp.Position - targetPos.Position).Magnitude
			local speed = _G.N3onHub.SavedStates.farmSpeed or 1
			local duration = distance / (speed * 100)
			
			if duration > 0.1 then
				autoFarmTween = TweenService:Create(
					hrp,
					TweenInfo.new(duration, Enum.EasingStyle.Linear),
					{CFrame = targetPos * CFrame.new(0, 10, 0)}
				)
				autoFarmTween:Play()
				autoFarmTween.Completed:Wait()
			else
				hrp.CFrame = targetPos * CFrame.new(0, 10, 0)
			end
		end
		
		warn("[Auto Farm] Attacking mob...")
		while autoFarmActive and mob.Parent and mobHum.Health > 0 do
			AttackMob()
			
			if _G.N3onHub.SavedStates.bringMobs then
				BringMobs(currentQuest.MobName)
			else
				hrp.CFrame = mobHRP.CFrame * CFrame.new(0, 10, 0)
			end
			
			task.wait(0.05)
		end
		
		if mobHum.Health <= 0 then
			mobsKilledThisSession = mobsKilledThisSession + 1
			warn("[Auto Farm] Mob killed! Total: " .. mobsKilledThisSession)
		end
		
		currentTarget = nil
		task.wait(0.3)
	end
	warn("[Auto Farm] AUTO FARM STOPPED!")
end

local function StopAutoFarm()
	warn("[Auto Farm] Stopping...")
	autoFarmActive = false
	currentTarget = nil
	currentQuest = nil
	
	if autoFarmTween then
		autoFarmTween:Cancel()
		autoFarmTween = nil
	end
	
	if farmConnection then
		farmConnection:Disconnect()
		farmConnection = nil
	end
end

----------------------------------------------------------------
-- LOAD BLOX FRUITS FARM TAB
----------------------------------------------------------------

local function LoadBloxFruitsFarm()
	warn("[Blox Fruits Module] Loading Farm Tab...")
	_G.N3onHub.GUI.Clear()

	local ScrollContent = _G.N3onHub.GUI.ScrollContent
	local UpdateCanvasSize = _G.N3onHub.GUI.UpdateCanvasSize

	-- SEÇÃO AUTO FARM LEVEL
	local farmTitle = Instance.new("TextLabel", ScrollContent)
	farmTitle.Size = UDim2.new(1, 0, 0, 40)
	farmTitle.BackgroundTransparency = 1
	farmTitle.Text = "⚔️ Auto Farm Level (Quest)"
	farmTitle.Font = Enum.Font.GothamBold
	farmTitle.TextScaled = true
	farmTitle.TextColor3 = Color3.fromRGB(255, 100, 100)

	local farmInfo = Instance.new("TextLabel", ScrollContent)
	farmInfo.Size = UDim2.new(1, 0, 0, 90)
	farmInfo.BackgroundTransparency = 1
	farmInfo.Text = "Automatically takes quests and farms mobs!\nBring Mobs stacks all enemies together.\nMake sure you have a weapon equipped!"
	farmInfo.Font = Enum.Font.Gotham
	farmInfo.TextScaled = true
	farmInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	farmInfo.TextXAlignment = Enum.TextXAlignment.Left
	farmInfo.TextWrapped = true

	local farmStatus = Instance.new("TextLabel", ScrollContent)
	farmStatus.Size = UDim2.new(1, 0, 0, 60)
	farmStatus.BackgroundColor3 = Color3.fromRGB(70, 20, 20)
	farmStatus.BackgroundTransparency = 0.3
	farmStatus.Text = "💀 Mobs Killed: " .. mobsKilledThisSession
	farmStatus.Font = Enum.Font.GothamBold
	farmStatus.TextScaled = true
	farmStatus.TextColor3 = Color3.fromRGB(255, 150, 150)
	Instance.new("UICorner", farmStatus)
	Instance.new("UIStroke", farmStatus).Color = Color3.fromRGB(255, 0, 0)

	spawn(function()
		while farmStatus and farmStatus.Parent do
			if currentTarget and currentQuest then
				local mobHealth = currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health or 0
				farmStatus.Text = "🎯 Quest: " .. currentQuest.Name .. "\nTarget HP: " .. math.floor(mobHealth) .. " | Killed: " .. mobsKilledThisSession
			elseif currentQuest then
				farmStatus.Text = "📋 Current Quest: " .. currentQuest.Name .. "\n💀 Killed: " .. mobsKilledThisSession
			else
				farmStatus.Text = "💀 Mobs Killed: " .. mobsKilledThisSession .. "\n⚔️ Level: " .. GetPlayerLevel()
			end
			task.wait(0.3)
		end
	end)

	local resetFarmBtn = Instance.new("TextButton", ScrollContent)
	resetFarmBtn.Size = UDim2.new(1, 0, 0, 40)
	resetFarmBtn.Text = "🔄 Reset Kill Counter"
	resetFarmBtn.Font = Enum.Font.GothamBold
	resetFarmBtn.TextScaled = true
	resetFarmBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	resetFarmBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", resetFarmBtn)

	resetFarmBtn.MouseButton1Click:Connect(function()
		mobsKilledThisSession = 0
		warn("[Auto Farm] Kill counter reset!")
	end)

	_G.N3onHub.Checkbox("Auto Farm Quest", _G.N3onHub.SavedStates.autoFarm or false, function(v)
		warn("[Auto Farm] Checkbox toggled: " .. tostring(v))
		_G.N3onHub.SavedStates.autoFarm = v
		
		if v then
			spawn(function()
				StartAutoFarm()
			end)
		else
			StopAutoFarm()
		end
	end)

	_G.N3onHub.Checkbox("Bring Mobs (Stack)", _G.N3onHub.SavedStates.bringMobs or false, function(v)
		warn("[Auto Farm] Bring Mobs toggled: " .. tostring(v))
		_G.N3onHub.SavedStates.bringMobs = v
		
		if v and autoFarmActive then
			farmConnection = RunService.Heartbeat:Connect(function()
				if autoFarmActive and currentQuest then
					BringMobs(currentQuest.MobName)
				end
			end)
		elseif farmConnection then
			farmConnection:Disconnect()
			farmConnection = nil
		end
	end)

	_G.N3onHub.Slider("Farm Speed", 1, 10, _G.N3onHub.SavedStates.farmSpeed, function(v)
		_G.N3onHub.SavedStates.farmSpeed = v
		warn("[Auto Farm] Farm speed set to: " .. v)
	end)

	-- SEÇÃO AUTO CHEST
	local title = Instance.new("TextLabel", ScrollContent)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "🎁 Auto Collect Chests"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 100)

	local infoLabel = Instance.new("TextLabel", ScrollContent)
	infoLabel.Size = UDim2.new(1, 0, 0, 70)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Auto Chest teleports you to chests.\nChests won't be revisited until they respawn."
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextWrapped = true

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

	_G.N3onHub.Checkbox("Auto Collect Chests", _G.N3onHub.SavedStates.autoChest or false, function(v)
		warn("[Auto Chest] Checkbox toggled: " .. tostring(v))
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

	UpdateCanvasSize()
	warn("[Blox Fruits Module] Farm Tab loaded!")
end

----------------------------------------------------------------
-- REGISTER TAB
----------------------------------------------------------------

_G.N3onHub.Tab("Farm","🎁",160, LoadBloxFruitsFarm)

warn("[Blox Fruits Module] Loaded successfully! Auto Quest Farm + Chest system ready.")
