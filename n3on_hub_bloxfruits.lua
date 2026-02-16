-- N3on Hub - Blox Fruits Module
-- Sistema completo de Auto Farm com Quest

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
-- QUEST DATABASE - SECOND SEA
----------------------------------------------------------------

local QUESTS = {
	-- Kingdom of Rose
	{Name = "RaiderQuest1", Level = 700, NPCName = "Raider", QuestGiver = "Quest Giver (Lv. 700)"},
	{Name = "MercenaryQuest1", Level = 725, NPCName = "Mercenary", QuestGiver = "Quest Giver (Lv. 725)"},
	{Name = "SwanPirateQuest1", Level = 775, NPCName = "Swan Pirate", QuestGiver = "Quest Giver (Lv. 775)"},
	{Name = "FactoryStaffQuest", Level = 800, NPCName = "Factory Staff", QuestGiver = "Quest Giver (Lv. 800)"},
	
	-- Green Zone
	{Name = "MarineQuest3", Level = 875, NPCName = "Marine Lieutenant", QuestGiver = "Quest Giver (Lv. 875)"},
	{Name = "MarineCaptainQuest2", Level = 900, NPCName = "Marine Captain", QuestGiver = "Quest Giver (Lv. 900)"},
	
	-- Graveyard
	{Name = "ZombieQuest", Level = 950, NPCName = "Zombie", QuestGiver = "Quest Giver (Lv. 950)"},
	{Name = "VampireQuest", Level = 975, NPCName = "Vampire", QuestGiver = "Quest Giver (Lv. 975)"},
	
	-- Snow Mountain
	{Name = "SnowMountainQuest", Level = 1000, NPCName = "Snow Trooper", QuestGiver = "Quest Giver (Lv. 1000)"},
	{Name = "WinterWarriorQuest", Level = 1050, NPCName = "Winter Warrior", QuestGiver = "Quest Giver (Lv. 1050)"},
	
	-- Hot and Cold
	{Name = "IceSideQuest1", Level = 1100, NPCName = "Lab Subordinate", QuestGiver = "Quest Giver (Lv. 1100)"},
	{Name = "IceSideQuest2", Level = 1125, NPCName = "Horned Warrior", QuestGiver = "Quest Giver (Lv. 1125)"},
	{Name = "FireSideQuest1", Level = 1175, NPCName = "Magma Ninja", QuestGiver = "Quest Giver (Lv. 1175)"},
	{Name = "FireSideQuest2", Level = 1200, NPCName = "Lava Pirate", QuestGiver = "Quest Giver (Lv. 1200)"},
	
	-- Cursed Ship
	{Name = "CursedShipQuest1", Level = 1250, NPCName = "Ship Deckhand", QuestGiver = "Quest Giver (Lv. 1250)"},
	{Name = "CursedShipQuest2", Level = 1275, NPCName = "Ship Engineer", QuestGiver = "Quest Giver (Lv. 1275)"},
	{Name = "ShipStewardQuest", Level = 1300, NPCName = "Ship Steward", QuestGiver = "Quest Giver (Lv. 1300)"},
	{Name = "ShipOfficerQuest", Level = 1325, NPCName = "Ship Officer", QuestGiver = "Quest Giver (Lv. 1325)"},
	
	-- Ice Castle
	{Name = "FrostQuest1", Level = 1350, NPCName = "Arctic Warrior", QuestGiver = "Quest Giver (Lv. 1350)"},
	{Name = "FrostQuest2", Level = 1375, NPCName = "Snow Lurker", QuestGiver = "Quest Giver (Lv. 1375)"},
	
	-- Forgotten Island
	{Name = "ForgottenQuest", Level = 1425, NPCName = "Sea Soldier", QuestGiver = "Quest Giver (Lv. 1425)"},
	{Name = "ForgottenQuest2", Level = 1450, NPCName = "Water Fighter", QuestGiver = "Quest Giver (Lv. 1450)"},
}

----------------------------------------------------------------
-- SISTEMA DE AUTO FARM
----------------------------------------------------------------

local autoFarmActive = false
local currentQuest = nil
local mobsKilled = 0
local farmConnection = nil
local bringConnection = nil

_G.N3onHub.SavedStates = _G.N3onHub.SavedStates or {}
_G.N3onHub.SavedStates.autoFarm = false
_G.N3onHub.SavedStates.bringMobs = false
_G.N3onHub.SavedStates.farmSpeed = 300

-- Pega o nível do player
local function GetPlayerLevel()
	local data = Player:FindFirstChild("Data")
	if data then
		local level = data:FindFirstChild("Level")
		if level then
			return level.Value
		end
	end
	return 700
end

-- Verifica se tem quest ativa
local function HasQuest()
	local gui = Player.PlayerGui:FindFirstChild("Main")
	if gui then
		local questUI = gui:FindFirstChild("Quest")
		if questUI and questUI.Visible then
			return true
		end
	end
	return false
end

-- Pega a melhor quest pro nível
local function GetBestQuest()
	local level = GetPlayerLevel()
	local best = QUESTS[1]
	
	for _, quest in ipairs(QUESTS) do
		if quest.Level <= level then
			best = quest
		else
			break
		end
	end
	
	return best
end

-- CommF_ Remote
local function CallRemote(...)
	local remote = ReplicatedStorage.Remotes:FindFirstChild("CommF_")
	if remote then
		return remote:InvokeServer(...)
	end
	return nil
end

-- Pega a quest
local function TakeQuest(questData)
	if HasQuest() then
		return true
	end
	
	warn("[Auto Farm] Pegando quest: " .. questData.Name)
	
	-- Tenta pegar via remote
	local success, result = pcall(function()
		return CallRemote("StartQuest", questData.Name, 1)
	end)
	
	if success then
		wait(0.5)
		return HasQuest()
	end
	
	return false
end

-- Pega todos os mobs da quest
local function GetQuestMobs()
	if not currentQuest then return {} end
	
	local mobs = {}
	local enemies = workspace:FindFirstChild("Enemies")
	
	if enemies then
		for _, mob in pairs(enemies:GetChildren()) do
			if mob.Name == currentQuest.NPCName and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
				if mob.Humanoid.Health > 0 then
					table.insert(mobs, mob)
				end
			end
		end
	end
	
	return mobs
end

-- Pega o mob mais próximo
local function GetClosestMob()
	local char = Player.Character
	if not char then return nil end
	
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	
	local mobs = GetQuestMobs()
	local closest = nil
	local closestDist = math.huge
	
	for _, mob in pairs(mobs) do
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

-- Bring Mobs
local function BringMobs()
	if not _G.N3onHub.SavedStates.bringMobs then return end
	if not currentQuest then return end
	
	local char = Player.Character
	if not char then return end
	
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local mobs = GetQuestMobs()
	
	for _, mob in pairs(mobs) do
		local mobHRP = mob:FindFirstChild("HumanoidRootPart")
		local mobHum = mob:FindFirstChild("Humanoid")
		
		if mobHRP and mobHum and mobHum.Health > 0 then
			pcall(function()
				-- Aumenta o tamanho e teleporta
				mobHRP.Size = Vector3.new(60, 60, 60)
				mobHRP.Transparency = 1
				mobHRP.CanCollide = false
				mobHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -15)
				mobHRP.Velocity = Vector3.zero
				mobHRP.RotVelocity = Vector3.zero
				
				-- Congela todas as partes
				for _, part in pairs(mob:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						part.Velocity = Vector3.zero
						part.RotVelocity = Vector3.zero
					end
				end
				
				-- Desativa IA
				mobHum.WalkSpeed = 0
				mobHum.JumpPower = 0
			end)
		end
	end
end

-- Equipa arma
local function EquipWeapon()
	local char = Player.Character
	if not char then return false end
	
	if char:FindFirstChildOfClass("Tool") then
		return true
	end
	
	for _, tool in pairs(Player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			local hum = char:FindFirstChild("Humanoid")
			if hum then
				hum:EquipTool(tool)
				return true
			end
		end
	end
	
	return false
end

-- Ataca mob
local function AttackMob()
	local char = Player.Character
	if not char then return end
	
	-- Ativa a arma
	local tool = char:FindFirstChildOfClass("Tool")
	if tool then
		tool:Activate()
	end
	
	-- Chama Click
	pcall(function()
		game:GetService("VirtualUser"):CaptureController()
		game:GetService("VirtualUser"):ClickButton1(Vector2.new(0,0))
	end)
end

-- Loop principal do farm
local function FarmLoop()
	autoFarmActive = true
	currentQuest = GetBestQuest()
	
	warn("[Auto Farm] Iniciando farm!")
	warn("[Auto Farm] Quest selecionada: " .. currentQuest.Name .. " (Level " .. currentQuest.Level .. ")")
	warn("[Auto Farm] Mob: " .. currentQuest.NPCName)
	
	-- Bring mobs connection
	if _G.N3onHub.SavedStates.bringMobs then
		warn("[Auto Farm] Bring Mobs ATIVADO!")
		bringConnection = RunService.Heartbeat:Connect(BringMobs)
	end
	
	while autoFarmActive do
		local char = Player.Character
		if not char then
			wait(1)
			continue
		end
		
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			wait(1)
			continue
		end
		
		-- Verifica quest
		if not HasQuest() then
			warn("[Auto Farm] Pegando quest...")
			local success = TakeQuest(currentQuest)
			
			if not success then
				warn("[Auto Farm] ERRO ao pegar quest! Tentando novamente em 5s...")
				wait(5)
				continue
			end
			
			warn("[Auto Farm] Quest obtida com sucesso!")
		end
		
		-- Equipa arma
		EquipWeapon()
		
		-- Pega mob
		local mob = GetClosestMob()
		
		if not mob then
			warn("[Auto Farm] Nenhum mob encontrado! Aguardando...")
			wait(2)
			continue
		end
		
		local mobHRP = mob:FindFirstChild("HumanoidRootPart")
		local mobHum = mob:FindFirstChild("Humanoid")
		
		if not mobHRP or not mobHum or mobHum.Health <= 0 then
			wait(0.5)
			continue
		end
		
		-- Teleporta pro mob
		if _G.N3onHub.SavedStates.bringMobs then
			-- Se bring está ativo, só fica perto
			hrp.CFrame = mobHRP.CFrame * CFrame.new(0, 15, 0)
		else
			-- Senão tweena
			local distance = (hrp.Position - mobHRP.Position).Magnitude
			local speed = _G.N3onHub.SavedStates.farmSpeed or 300
			local time = distance / speed
			
			if time > 0.5 then
				local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {
					CFrame = mobHRP.CFrame * CFrame.new(0, 15, 0)
				})
				tween:Play()
				tween.Completed:Wait()
			else
				hrp.CFrame = mobHRP.CFrame * CFrame.new(0, 15, 0)
			end
		end
		
		-- Ataca o mob
		while autoFarmActive and mob.Parent and mobHum.Health > 0 do
			AttackMob()
			
			if not _G.N3onHub.SavedStates.bringMobs then
				pcall(function()
					hrp.CFrame = mobHRP.CFrame * CFrame.new(0, 15, 0)
				end)
			end
			
			wait(0.1)
		end
		
		-- Mob morreu
		if mobHum.Health <= 0 then
			mobsKilled = mobsKilled + 1
			warn("[Auto Farm] Mob eliminado! Total: " .. mobsKilled)
		end
		
		wait(0.3)
	end
	
	warn("[Auto Farm] Farm parado!")
end

-- Para o farm
local function StopFarm()
	autoFarmActive = false
	
	if bringConnection then
		bringConnection:Disconnect()
		bringConnection = nil
	end
	
	if farmConnection then
		farmConnection:Disconnect()
		farmConnection = nil
	end
end

----------------------------------------------------------------
-- UI DO FARM TAB
----------------------------------------------------------------

local function LoadFarmTab()
	warn("[Blox Fruits] Carregando Farm Tab...")
	_G.N3onHub.GUI.Clear()
	
	local ScrollContent = _G.N3onHub.GUI.ScrollContent
	local UpdateCanvasSize = _G.N3onHub.GUI.UpdateCanvasSize
	
	-- Título
	local title = Instance.new("TextLabel", ScrollContent)
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "⚔️ Auto Farm Level"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 100, 100)
	
	-- Info
	local info = Instance.new("TextLabel", ScrollContent)
	info.Size = UDim2.new(1, 0, 0, 80)
	info.BackgroundTransparency = 1
	info.Text = "Pega quests automaticamente e farma!\nBring Mobs traz todos os inimigos.\nEquipe uma arma antes de começar!"
	info.Font = Enum.Font.Gotham
	info.TextScaled = true
	info.TextColor3 = Color3.fromRGB(200, 200, 200)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextWrapped = true
	
	-- Status
	local status = Instance.new("TextLabel", ScrollContent)
	status.Size = UDim2.new(1, 0, 0, 60)
	status.BackgroundColor3 = Color3.fromRGB(70, 20, 20)
	status.BackgroundTransparency = 0.3
	status.Text = "💀 Mobs Mortos: 0\n⚔️ Level: " .. GetPlayerLevel()
	status.Font = Enum.Font.GothamBold
	status.TextScaled = true
	status.TextColor3 = Color3.fromRGB(255, 150, 150)
	Instance.new("UICorner", status)
	Instance.new("UIStroke", status).Color = Color3.fromRGB(255, 0, 0)
	
	-- Atualiza status
	spawn(function()
		while status and status.Parent do
			if currentQuest then
				status.Text = "📋 Quest: " .. currentQuest.NPCName .. "\n💀 Mortos: " .. mobsKilled
			else
				status.Text = "💀 Mobs Mortos: " .. mobsKilled .. "\n⚔️ Level: " .. GetPlayerLevel()
			end
			wait(0.5)
		end
	end)
	
	-- Reset
	local resetBtn = Instance.new("TextButton", ScrollContent)
	resetBtn.Size = UDim2.new(1, 0, 0, 40)
	resetBtn.Text = "🔄 Resetar Contador"
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.TextScaled = true
	resetBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	resetBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", resetBtn)
	
	resetBtn.MouseButton1Click:Connect(function()
		mobsKilled = 0
		warn("[Auto Farm] Contador resetado!")
	end)
	
	-- Auto Farm toggle
	_G.N3onHub.Checkbox("Auto Farm Quest", _G.N3onHub.SavedStates.autoFarm or false, function(v)
		warn("[Auto Farm] Toggled: " .. tostring(v))
		_G.N3onHub.SavedStates.autoFarm = v
		
		if v then
			farmConnection = spawn(FarmLoop)
		else
			StopFarm()
		end
	end)
	
	-- Bring Mobs toggle
	_G.N3onHub.Checkbox("Bring Mobs", _G.N3onHub.SavedStates.bringMobs or false, function(v)
		warn("[Auto Farm] Bring Mobs: " .. tostring(v))
		_G.N3onHub.SavedStates.bringMobs = v
		
		if v and autoFarmActive then
			bringConnection = RunService.Heartbeat:Connect(BringMobs)
		elseif bringConnection then
			bringConnection:Disconnect()
			bringConnection = nil
		end
	end)
	
	-- Farm Speed
	_G.N3onHub.Slider("Velocidade de Farm", 100, 500, _G.N3onHub.SavedStates.farmSpeed, function(v)
		_G.N3onHub.SavedStates.farmSpeed = v
	end)
	
	UpdateCanvasSize()
	warn("[Blox Fruits] Farm Tab carregado!")
end

----------------------------------------------------------------
-- REGISTRAR TAB
----------------------------------------------------------------

_G.N3onHub.Tab("Farm", "⚔️", 160, LoadFarmTab)

warn("[Blox Fruits Module] Carregado com sucesso!")
