-- N3on Hub - Prison Life Module
-- Funcionalidades exclusivas para Prison Life

if not _G.N3onHub then
	warn("[Prison Life Module] Base hub not loaded! Please load the base first.")
	return
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

print("[Prison Life Module] Loading...")

----------------------------------------------------------------
-- SAVED STATES
----------------------------------------------------------------

_G.N3onHub.SavedStates.killAll = false
_G.N3onHub.SavedStates.killAura = false
_G.N3onHub.SavedStates.bringGuns = false
_G.N3onHub.SavedStates.modGuns = false
_G.N3onHub.SavedStates.espPlayers = false
_G.N3onHub.SavedStates.noclip = false
_G.N3onHub.SavedStates.walkSpeed = 16
_G.N3onHub.SavedStates.jumpPower = 50
_G.N3onHub.SavedStates.infiniteAmmo = false

local killAllActive = false
local killAuraActive = false
local bringGunsActive = false
local espActive = false
local noclipActive = false
local espConnections = {}
local noclipConnection = nil

----------------------------------------------------------------
-- UTILITY FUNCTIONS
----------------------------------------------------------------

local function GetGun()
	local char = Player.Character
	if not char then return nil end
	
	for _, tool in pairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
			return tool
		end
	end
	
	return nil
end

----------------------------------------------------------------
-- GUN MOD
----------------------------------------------------------------

local function ModGun(gun)
	if not gun or not gun:IsA("Tool") then return end
	
	-- Modificar settings da arma
	local settings = gun:FindFirstChild("Settings")
	if settings then
		-- Aumentar dano
		local damage = settings:FindFirstChild("Damage")
		if damage and damage:IsA("NumberValue") then
			damage.Value = 100
		end
		
		-- Aumentar alcance
		local range = settings:FindFirstChild("Range")
		if range and range:IsA("NumberValue") then
			range.Value = 500
		end
		
		-- Aumentar velocidade de tiro
		local fireRate = settings:FindFirstChild("FireRate")
		if fireRate and fireRate:IsA("NumberValue") then
			fireRate.Value = 0.01
		end
		
		-- Remover recoil
		local recoil = settings:FindFirstChild("Recoil")
		if recoil and recoil:IsA("NumberValue") then
			recoil.Value = 0
		end
		
		-- Auto
		local auto = settings:FindFirstChild("Auto")
		if auto and auto:IsA("BoolValue") then
			auto.Value = true
		end
		
		-- Aumentar ammo
		local maxAmmo = settings:FindFirstChild("MaxAmmo")
		if maxAmmo and maxAmmo:IsA("NumberValue") then
			maxAmmo.Value = 999
		end
		
		local ammo = settings:FindFirstChild("Ammo")
		if ammo and ammo:IsA("NumberValue") then
			ammo.Value = 999
		end
	end
	
	-- Modificar ammo diretamente
	local ammo = gun:FindFirstChild("Ammo")
	if ammo and ammo:IsA("NumberValue") then
		ammo.Value = 999
	end
	
	local maxAmmo = gun:FindFirstChild("MaxAmmo")
	if maxAmmo and maxAmmo:IsA("NumberValue") then
		maxAmmo.Value = 999
	end
end

local function ModAllGuns()
	-- Modificar armas no personagem
	if Player.Character then
		for _, tool in pairs(Player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				ModGun(tool)
			end
		end
	end
	
	-- Modificar armas no backpack
	for _, tool in pairs(Player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			ModGun(tool)
		end
	end
end

----------------------------------------------------------------
-- BRING GUNS
----------------------------------------------------------------

local function BringAllGuns()
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Pegar armas do armory e warehouse
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
			local handle = obj.Handle
			if handle:IsA("BasePart") then
				handle.CFrame = hrp.CFrame
				task.wait(0.1)
			end
		end
	end
end

----------------------------------------------------------------
-- KILL AURA
----------------------------------------------------------------

local function KillAura()
	local gun = GetGun()
	if not gun then return end
	
	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= Player and plr.Character then
			local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
			local targetHead = plr.Character:FindFirstChild("Head")
			local targetHumanoid = plr.Character:FindFirstChild("Humanoid")
			
			if targetHead and targetHumanoid and targetHumanoid.Health > 0 then
				local distance = (hrp.Position - targetHead.Position).Magnitude
				
				if distance <= 50 then
					-- Disparar
					local args = {
						[1] = {
							["Hit"] = targetHead,
							["Distance"] = distance,
							["Cframe"] = targetHead.CFrame,
							["RayObject"] = Ray.new(Vector3.new(), Vector3.new())
						}
					}
					
					local event = gun:FindFirstChild("GunController") and gun.GunController:FindFirstChild("RemoteEvent")
					if event then
						event:FireServer(unpack(args))
					end
				end
			end
		end
	end
end

----------------------------------------------------------------
-- KILL ALL
----------------------------------------------------------------

local function KillAllPlayers()
	while killAllActive do
		local gun = GetGun()
		if not gun then
			task.wait(1)
			continue
		end
		
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			task.wait(0.5)
			continue
		end
		
		local oldPos = hrp.CFrame
		
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= Player and plr.Character then
				local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
				local targetHead = plr.Character:FindFirstChild("Head")
				local targetHumanoid = plr.Character:FindFirstChild("Humanoid")
				
				if targetHead and targetHumanoid and targetHumanoid.Health > 0 then
					-- Teleportar para perto do alvo
					hrp.CFrame = targetHead.CFrame * CFrame.new(0, 0, 5)
					task.wait(0.2)
					
					-- Disparar várias vezes
					for i = 1, 10 do
						local args = {
							[1] = {
								["Hit"] = targetHead,
								["Distance"] = 5,
								["Cframe"] = targetHead.CFrame,
								["RayObject"] = Ray.new(Vector3.new(), Vector3.new())
							}
						}
						
						local event = gun:FindFirstChild("GunController") and gun.GunController:FindFirstChild("RemoteEvent")
						if event then
							event:FireServer(unpack(args))
						end
						task.wait(0.05)
					end
					
					task.wait(0.2)
				end
			end
		end
		
		-- Voltar para posição original
		hrp.CFrame = oldPos
		task.wait(2)
	end
end

----------------------------------------------------------------
-- ESP PLAYERS
----------------------------------------------------------------

local function CreateESP(player)
	if espConnections[player] then return end
	
	local function updateESP()
		if not espActive or not player.Character then return end
		
		local char = player.Character
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")
		
		if not hrp or not head then return end
		
		-- Criar highlight
		local highlight = char:FindFirstChild("N3onESP")
		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "N3onESP"
			highlight.Adornee = char
			highlight.FillColor = Color3.fromRGB(255, 0, 0)
			highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
			highlight.FillTransparency = 0.5
			highlight.OutlineTransparency = 0
			highlight.Parent = char
		end
		
		-- Nome e distância
		local billboard = head:FindFirstChild("N3onNameTag")
		if not billboard then
			billboard = Instance.new("BillboardGui")
			billboard.Name = "N3onNameTag"
			billboard.Size = UDim2.new(0, 200, 0, 50)
			billboard.StudsOffset = Vector3.new(0, 3, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = head
			
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.Font = Enum.Font.GothamBold
			textLabel.TextSize = 14
			textLabel.TextColor3 = Color3.new(1, 1, 1)
			textLabel.TextStrokeTransparency = 0.5
			textLabel.Parent = billboard
		end
		
		if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (Player.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
			billboard.TextLabel.Text = player.Name .. "\n[" .. math.floor(distance) .. " studs]"
		end
	end
	
	local connection = RunService.Heartbeat:Connect(updateESP)
	espConnections[player] = connection
	
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		updateESP()
	end)
end

local function RemoveESP(player)
	if espConnections[player] then
		espConnections[player]:Disconnect()
		espConnections[player] = nil
	end
	
	if player.Character then
		local highlight = player.Character:FindFirstChild("N3onESP")
		if highlight then highlight:Destroy() end
		
		local head = player.Character:FindFirstChild("Head")
		if head then
			local billboard = head:FindFirstChild("N3onNameTag")
			if billboard then billboard:Destroy() end
		end
	end
end

local function StartESP()
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= Player then
			CreateESP(player)
		end
	end
	
	Players.PlayerAdded:Connect(function(player)
		if espActive then
			CreateESP(player)
		end
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		RemoveESP(player)
	end)
end

local function StopESP()
	for player, _ in pairs(espConnections) do
		RemoveESP(player)
	end
end

----------------------------------------------------------------
-- NOCLIP
----------------------------------------------------------------

local function StartNoclip()
	noclipConnection = RunService.Stepped:Connect(function()
		if noclipActive and Player.Character then
			for _, part in pairs(Player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end)
end

local function StopNoclip()
	if noclipConnection then
		noclipConnection:Disconnect()
		noclipConnection = nil
	end
	
	if Player.Character then
		for _, part in pairs(Player.Character:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.CanCollide = true
			end
		end
	end
end

----------------------------------------------------------------
-- TELEPORTS
----------------------------------------------------------------

local function TeleportToCriminalBase()
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(-943, 95, 2063)
	end
end

local function TeleportToYard()
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(780, 98, 2458)
	end
end

local function TeleportToArmory()
	if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(791, 100, 2255)
	end
end

----------------------------------------------------------------
-- LOAD PRISON LIFE FARM TAB
----------------------------------------------------------------

local function LoadPrisonLifeFarm()
	_G.N3onHub.GUI.Clear()

	local ScrollContent = _G.N3onHub.GUI.ScrollContent
	local UpdateCanvasSize = _G.N3onHub.GUI.UpdateCanvasSize

	local title = Instance.new("TextLabel", ScrollContent)
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "🔫 Farm - Prison Life"
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 200, 100)

	local infoLabel = Instance.new("TextLabel", ScrollContent)
	infoLabel.Size = UDim2.new(1, 0, 0, 70)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = "Kill features require a gun equipped!\nUse 'Bring All Guns' or teleport to get weapons."
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextScaled = true
	infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.TextWrapped = true

	-- Combat Section
	local combatTitle = Instance.new("TextLabel", ScrollContent)
	combatTitle.Size = UDim2.new(1, 0, 0, 35)
	combatTitle.BackgroundTransparency = 1
	combatTitle.Text = "⚔️ Combat"
	combatTitle.Font = Enum.Font.GothamBold
	combatTitle.TextSize = 16
	combatTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
	combatTitle.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("Kill All", _G.N3onHub.SavedStates.killAll, function(v)
		_G.N3onHub.SavedStates.killAll = v
		killAllActive = v
		if v then
			spawn(function()
				KillAllPlayers()
			end)
		end
	end)

	_G.N3onHub.Checkbox("Kill Aura", _G.N3onHub.SavedStates.killAura, function(v)
		_G.N3onHub.SavedStates.killAura = v
		killAuraActive = v
		if v then
			RunService.Heartbeat:Connect(function()
				if killAuraActive then
					KillAura()
				end
			end)
		end
	end)

	-- Gun Section
	local gunTitle = Instance.new("TextLabel", ScrollContent)
	gunTitle.Size = UDim2.new(1, 0, 0, 35)
	gunTitle.BackgroundTransparency = 1
	gunTitle.Text = "🔫 Guns"
	gunTitle.Font = Enum.Font.GothamBold
	gunTitle.TextSize = 16
	gunTitle.TextColor3 = Color3.fromRGB(100, 255, 100)
	gunTitle.TextXAlignment = Enum.TextXAlignment.Left

	local bringGunsBtn = Instance.new("TextButton", ScrollContent)
	bringGunsBtn.Size = UDim2.new(1, 0, 0, 40)
	bringGunsBtn.Text = "🔫 Bring All Guns"
	bringGunsBtn.Font = Enum.Font.GothamBold
	bringGunsBtn.TextSize = 14
	bringGunsBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 120)
	bringGunsBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", bringGunsBtn)
	
	bringGunsBtn.MouseButton1Click:Connect(function()
		BringAllGuns()
	end)

	local modGunsBtn = Instance.new("TextButton", ScrollContent)
	modGunsBtn.Size = UDim2.new(1, 0, 0, 40)
	modGunsBtn.Text = "⚡ Mod All Guns"
	modGunsBtn.Font = Enum.Font.GothamBold
	modGunsBtn.TextSize = 14
	modGunsBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 180)
	modGunsBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", modGunsBtn)
	
	modGunsBtn.MouseButton1Click:Connect(function()
		ModAllGuns()
	end)

	-- Visual Section
	local visualTitle = Instance.new("TextLabel", ScrollContent)
	visualTitle.Size = UDim2.new(1, 0, 0, 35)
	visualTitle.BackgroundTransparency = 1
	visualTitle.Text = "👁️ Visual"
	visualTitle.Font = Enum.Font.GothamBold
	visualTitle.TextSize = 16
	visualTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
	visualTitle.TextXAlignment = Enum.TextXAlignment.Left

	_G.N3onHub.Checkbox("ESP Players", _G.N3onHub.SavedStates.espPlayers, function(v)
		_G.N3onHub.SavedStates.espPlayers = v
		espActive = v
		if v then
			StartESP()
		else
			StopESP()
		end
	end)

	-- Teleport Section
	local teleportTitle = Instance.new("TextLabel", ScrollContent)
	teleportTitle.Size = UDim2.new(1, 0, 0, 35)
	teleportTitle.BackgroundTransparency = 1
	teleportTitle.Text = "📍 Teleports"
	teleportTitle.Font = Enum.Font.GothamBold
	teleportTitle.TextSize = 16
	teleportTitle.TextColor3 = Color3.fromRGB(255, 255, 100)
	teleportTitle.TextXAlignment = Enum.TextXAlignment.Left

	local tpCrimBtn = Instance.new("TextButton", ScrollContent)
	tpCrimBtn.Size = UDim2.new(1, 0, 0, 40)
	tpCrimBtn.Text = "🏴 TP to Criminal Base"
	tpCrimBtn.Font = Enum.Font.GothamBold
	tpCrimBtn.TextSize = 14
	tpCrimBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 50)
	tpCrimBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpCrimBtn)
	
	tpCrimBtn.MouseButton1Click:Connect(TeleportToCriminalBase)

	local tpYardBtn = Instance.new("TextButton", ScrollContent)
	tpYardBtn.Size = UDim2.new(1, 0, 0, 40)
	tpYardBtn.Text = "🏃 TP to Yard"
	tpYardBtn.Font = Enum.Font.GothamBold
	tpYardBtn.TextSize = 14
	tpYardBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
	tpYardBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpYardBtn)
	
	tpYardBtn.MouseButton1Click:Connect(TeleportToYard)

	local tpArmoryBtn = Instance.new("TextButton", ScrollContent)
	tpArmoryBtn.Size = UDim2.new(1, 0, 0, 40)
	tpArmoryBtn.Text = "🔫 TP to Armory"
	tpArmoryBtn.Font = Enum.Font.GothamBold
	tpArmoryBtn.TextSize = 14
	tpArmoryBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
	tpArmoryBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", tpArmoryBtn)
	
	tpArmoryBtn.MouseButton1Click:Connect(TeleportToArmory)

	UpdateCanvasSize()
end

----------------------------------------------------------------
-- LOAD PLAYER TAB
----------------------------------------------------------------

local originalLoadPlayer = _G.N3onHub.LoadPlayer

local function LoadPlayerPrisonLife()
	originalLoadPlayer()
	
	_G.N3onHub.Checkbox("Noclip", _G.N3onHub.SavedStates.noclip, function(v)
		_G.N3onHub.SavedStates.noclip = v
		noclipActive = v
		if v then
			StartNoclip()
		else
			StopNoclip()
		end
	end)
	
	_G.N3onHub.Slider("Walk Speed", 16, 200, _G.N3onHub.SavedStates.walkSpeed, function(v)
		_G.N3onHub.SavedStates.walkSpeed = v
		if Player.Character and Player.Character:FindFirstChild("Humanoid") then
			Player.Character.Humanoid.WalkSpeed = v
		end
	end)
	
	_G.N3onHub.Slider("Jump Power", 50, 300, _G.N3onHub.SavedStates.jumpPower, function(v)
		_G.N3onHub.SavedStates.jumpPower = v
		if Player.Character and Player.Character:FindFirstChild("Humanoid") then
			Player.Character.Humanoid.JumpPower = v
		end
	end)
end

_G.N3onHub.LoadPlayer = LoadPlayerPrisonLife

for _, btn in pairs(_G.N3onHub.GUI.F2:GetChildren()) do
	if btn:IsA("TextButton") and btn.Text:find("Player") then
		btn.MouseButton1Click:Connect(function()
			LoadPlayerPrisonLife()
		end)
	end
end

Player.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.WalkSpeed = _G.N3onHub.SavedStates.walkSpeed
	humanoid.JumpPower = _G.N3onHub.SavedStates.jumpPower
end)

----------------------------------------------------------------
-- REGISTER TAB
----------------------------------------------------------------

_G.N3onHub.Tab("Farm","🔫",160, LoadPrisonLifeFarm)

print("[Prison Life Module] Loaded successfully!")
print("[Prison Life Module] Features:")
print("- Kill All & Kill Aura")
print("- Bring All Guns & Mod Guns")
print("- ESP Players")
print("- Teleports")
print("- Noclip, Walk Speed & Jump Power")
