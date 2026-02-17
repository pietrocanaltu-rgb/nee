-- ═══════════════════════════════════════════════════════════════
--  N3on Hub — Slap Battles Module
--  Blacklist · Hotkeys · Close=StopAll · AntiVoid · Tween Farm
-- ═══════════════════════════════════════════════════════════════

local tries = 0
repeat task.wait(0.5); tries += 1 until (_G.N3onHub and _G.N3onHub._loaded) or tries >= 20
if not (_G.N3onHub and _G.N3onHub._loaded) then
    warn("[Slap Battles] Base Hub nao carregado!"); return
end

local TS     = game:GetService("TweenService")
local RS     = game:GetService("RunService")
local PLS    = game:GetService("Players")
local VIM    = game:GetService("VirtualInputManager")
local UIS    = game:GetService("UserInputService")
local Player = PLS.LocalPlayer

print("[Slap Battles] Carregando...")

-- ALIASES
local GUI      = _G.N3onHub.GUI
local SC       = GUI.ScrollContent
local Clear    = GUI.Clear
local UCS      = GUI.UpdateCanvasSize
local Slider   = _G.N3onHub.Slider
local Checkbox = _G.N3onHub.Checkbox
local Tab      = _G.N3onHub.Tab
local HubGui   = GUI.Hub
local F1       = GUI.F1

-- SAVED STATES
local SS = _G.N3onHub.SavedStates
local function def(k,v) if SS[k] == nil then SS[k] = v end end
def("autoFarm",false) def("farmSpeed",30) def("farmDistance",15) def("farmRange",100)
def("auraEnabled",false) def("auraSize",20)
def("espEnabled",false) def("espBoxEnabled",false) def("espNameEnabled",false) def("espDistEnabled",false)
def("antiKnockback",false) def("flingEnabled",false) def("flingPower",500)
def("autoRespawn",false) def("clickTpEnabled",false)
def("keyFarm","RightControl") def("keyGUI","RightShift")

-- FLAGS
local autoFarmActive=false; local auraActive=false; local espActive=false
local antiKnockActive=false; local flingActive=false
local autoRespawnActive=false; local clickTpActive=false
local activeTween=nil; local farmConn=nil
local espObjects={}; local clickTpConn=nil
local capturingKey=nil; local farmKeyLbl=nil; local guiKeyLbl=nil
local blacklist={}; local blPanelRef=nil

local AutoFarmLoop; local RebuildBL; local StopAll

-- UTIL
local function GetHRP() local c=Player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c=Player.Character; return c and c:FindFirstChild("Humanoid") end
local function IsBlacklisted(plr) return blacklist[plr.Name]==true end

-- ════════════════════════════════════════════════════════════════
-- SAFE ZONE
-- ════════════════════════════════════════════════════════════════
local safeZone = workspace:FindFirstChild("N3onSafeZone")
if not safeZone then
    safeZone=Instance.new("Part"); safeZone.Name="N3onSafeZone"
    safeZone.Size=Vector3.new(30,1,30); safeZone.Anchored=true; safeZone.CanCollide=true
    safeZone.BrickColor=BrickColor.new("Bright green"); safeZone.Material=Enum.Material.SmoothPlastic
    safeZone.Transparency=0.4; safeZone.CFrame=CFrame.new(0,500,99999); safeZone.Parent=workspace
    local bb=Instance.new("BillboardGui",safeZone); bb.Size=UDim2.fromOffset(200,40)
    bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true
    local lb=Instance.new("TextLabel",bb); lb.Size=UDim2.new(1,0,1,0)
    lb.BackgroundTransparency=1; lb.Text="SAFE ZONE"; lb.Font=Enum.Font.GothamBold
    lb.TextSize=18; lb.TextColor3=Color3.new(0,1,0); lb.TextStrokeTransparency=0.3
end
local function TpSafe() local h=GetHRP(); if h then h.CFrame=safeZone.CFrame+Vector3.new(0,4,0) end end

-- ════════════════════════════════════════════════════════════════
-- ANTI VOID
-- Localiza workspace.Arena["main island"].Grass (BasePart)
-- Cria uma Part gigante no mesmo Y com Height=0.1 que age como chao
-- ════════════════════════════════════════════════════════════════
local antiVoidPart = workspace:FindFirstChild("N3onAntiVoid")
if not antiVoidPart then
    pcall(function()
        local arena = workspace:FindFirstChild("Arena")
        local island = arena and arena:FindFirstChild("main island")
        local grass = island and island:FindFirstChild("Grass")
        if grass and grass:IsA("BasePart") then
            local floorY = grass.Position.Y
            antiVoidPart = Instance.new("Part")
            antiVoidPart.Name = "N3onAntiVoid"
            antiVoidPart.Size = Vector3.new(99999, 0.1, 99999)
            antiVoidPart.CFrame = CFrame.new(0, floorY, 0)
            antiVoidPart.Anchored = true
            antiVoidPart.CanCollide = true
            antiVoidPart.Transparency = 1
            antiVoidPart.CanQuery = false
            antiVoidPart.CanTouch = false
            antiVoidPart.Locked = true
            antiVoidPart.Parent = workspace
            print("[Slap Battles] AntiVoid criado em Y =", floorY)
        else
            warn("[Slap Battles] AntiVoid: workspace.Arena['main island'].Grass nao encontrado")
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
-- HUD — visível mesmo com GUI escondida
-- ════════════════════════════════════════════════════════════════
local PlayerGui = Player:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("N3onFarmHUD") then PlayerGui:FindFirstChild("N3onFarmHUD"):Destroy() end
local hudGui = Instance.new("ScreenGui",PlayerGui)
hudGui.Name="N3onFarmHUD"; hudGui.ResetOnSpawn=false; hudGui.DisplayOrder=999
local hudFrame = Instance.new("Frame",hudGui)
hudFrame.Size=UDim2.fromOffset(210,28); hudFrame.Position=UDim2.new(0,10,0,10)
hudFrame.BackgroundColor3=Color3.fromRGB(15,8,30); hudFrame.BackgroundTransparency=0.15
Instance.new("UICorner",hudFrame).CornerRadius=UDim.new(0,6)
local hudStroke=Instance.new("UIStroke",hudFrame); hudStroke.Color=Color3.fromRGB(100,0,200); hudStroke.Thickness=1.5
local hudLbl=Instance.new("TextLabel",hudFrame)
hudLbl.Size=UDim2.new(1,-8,1,0); hudLbl.Position=UDim2.fromOffset(6,0)
hudLbl.BackgroundTransparency=1; hudLbl.Font=Enum.Font.GothamBold; hudLbl.TextSize=12
hudLbl.TextXAlignment=Enum.TextXAlignment.Left
hudLbl.Text="  Farm: OFF"; hudLbl.TextColor3=Color3.fromRGB(255,80,80)
local function UpdateHUD()
    if autoFarmActive then
        hudLbl.Text="  Farm: ON  |  "..SS.keyFarm.." p/ toggle"
        hudLbl.TextColor3=Color3.fromRGB(80,255,100)
        hudFrame.BackgroundColor3=Color3.fromRGB(8,28,8)
    else
        hudLbl.Text="  Farm: OFF  |  "..SS.keyFarm.." p/ toggle"
        hudLbl.TextColor3=Color3.fromRGB(255,80,80)
        hudFrame.BackgroundColor3=Color3.fromRGB(15,8,30)
    end
end

-- ════════════════════════════════════════════════════════════════
-- STOP ALL — para tudo de uma vez
-- ════════════════════════════════════════════════════════════════
StopAll = function()
    autoFarmActive=false; auraActive=false; espActive=false
    antiKnockActive=false; flingActive=false; autoRespawnActive=false; clickTpActive=false
    SS.autoFarm=false; SS.auraEnabled=false; SS.espEnabled=false
    SS.antiKnockback=false; SS.flingEnabled=false; SS.autoRespawn=false; SS.clickTpEnabled=false
    if activeTween then activeTween:Cancel(); activeTween=nil end
    if farmConn then farmConn:Disconnect(); farmConn=nil end
    if clickTpConn then clickTpConn:Disconnect(); clickTpConn=nil end
    local hrp=GetHRP(); if hrp then pcall(function() hrp.Anchored=false end) end
    UpdateHUD()
end

-- ════════════════════════════════════════════════════════════════
-- POPUP DE FECHAMENTO (intercepta o botão X do Base Hub)
-- Avisa que vai parar tudo e pede confirmação
-- ════════════════════════════════════════════════════════════════
task.defer(function()
    if not F1 then return end
    local closeBtn
    for _,v in ipairs(F1:GetDescendants()) do
        if v:IsA("TextButton") and v.Text=="X" then closeBtn=v; break end
    end
    if not closeBtn then return end

    -- Clona para desconectar connects antigos
    local newBtn = closeBtn:Clone()
    newBtn.Parent = closeBtn.Parent
    closeBtn:Destroy()

    newBtn.MouseButton1Click:Connect(function()
        -- Overlay escuro
        local overlay=Instance.new("Frame",HubGui)
        overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.fromRGB(0,0,0)
        overlay.BackgroundTransparency=1; overlay.ZIndex=20
        TS:Create(overlay,TweenInfo.new(0.2),{BackgroundTransparency=0.55}):Play()

        -- Popup
        local pop=Instance.new("Frame",overlay)
        pop.Size=UDim2.fromOffset(0,0); pop.Position=UDim2.fromScale(0.5,0.5)
        pop.AnchorPoint=Vector2.new(0.5,0.5); pop.BackgroundColor3=Color3.fromRGB(30,10,50)
        pop.ZIndex=21; Instance.new("UICorner",pop)
        local ps=Instance.new("UIStroke",pop); ps.Color=Color3.fromRGB(200,0,80); ps.Thickness=2
        TS:Create(pop,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Size=UDim2.fromOffset(340,190)}):Play()

        -- Barra de aviso vermelha no topo
        local wBar=Instance.new("Frame",pop)
        wBar.Size=UDim2.new(1,0,0,30); wBar.BackgroundColor3=Color3.fromRGB(160,20,20); wBar.ZIndex=22
        local wc=Instance.new("UICorner",wBar); wc.CornerRadius=UDim.new(0,10)
        local wLbl=Instance.new("TextLabel",wBar)
        wLbl.Size=UDim2.new(1,0,1,0); wLbl.BackgroundTransparency=1
        wLbl.Font=Enum.Font.GothamBold; wLbl.TextSize=12; wLbl.ZIndex=23
        wLbl.TextColor3=Color3.new(1,1,1)
        wLbl.Text="  ⚠️  TODOS OS RECURSOS SERAO DESATIVADOS!"

        -- Texto
        local txt=Instance.new("TextLabel",pop)
        txt.Size=UDim2.new(1,-20,0,80); txt.Position=UDim2.fromOffset(10,36)
        txt.BackgroundTransparency=1; txt.Font=Enum.Font.Gotham; txt.TextSize=13
        txt.TextWrapped=true; txt.TextColor3=Color3.fromRGB(230,210,255); txt.ZIndex=22
        txt.Text="Tem certeza que quer fechar o N3on Hub?\n\nFarm, ESP, Aura, Fling e TUDO mais serao\ndesativados imediatamente."

        -- Botoes
        local function mkBtn(label,bg,xPct)
            local b=Instance.new("TextButton",pop)
            b.Size=UDim2.fromOffset(120,32); b.Position=UDim2.new(xPct,-60,1,-44)
            b.Text=label; b.Font=Enum.Font.GothamBold; b.TextSize=13
            b.BackgroundColor3=bg; b.TextColor3=Color3.new(1,1,1)
            b.AutoButtonColor=false; b.ZIndex=22; Instance.new("UICorner",b)
            return b
        end
        local yesBtn=mkBtn("✅  Fechar",Color3.fromRGB(140,25,25),0.32)
        local noBtn =mkBtn("❌  Cancelar",Color3.fromRGB(25,100,35),0.72)

        local function closePopup()
            TS:Create(overlay,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
            local t2=TS:Create(pop,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,0)})
            t2:Play(); t2.Completed:Connect(function() overlay:Destroy() end)
        end

        noBtn.MouseButton1Click:Connect(closePopup)
        yesBtn.MouseButton1Click:Connect(function()
            StopAll()
            overlay:Destroy()
            TS:Create(F1,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
                {Size=UDim2.fromOffset(660,390), BackgroundTransparency=0.8}):Play()
            task.wait(0.22)
            HubGui:Destroy()
            hudGui:Destroy()
        end)
    end)
end)

-- ════════════════════════════════════════════════════════════════
-- HOTKEYS — toggle farm / toggle GUI
-- ════════════════════════════════════════════════════════════════
UIS.InputBegan:Connect(function(input,gpe)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local key = input.KeyCode

    if capturingKey then
        local slot=capturingKey; capturingKey=nil
        local name=key.Name
        if slot=="farm" then
            SS.keyFarm=name
            if farmKeyLbl then farmKeyLbl.Text="Tecla Farm: ["..name.."]  (clique p/ mudar)"; farmKeyLbl.TextColor3=Color3.fromRGB(80,255,130) end
        elseif slot=="gui" then
            SS.keyGUI=name
            if guiKeyLbl then guiKeyLbl.Text="Tecla GUI: ["..name.."]  (clique p/ mudar)"; guiKeyLbl.TextColor3=Color3.fromRGB(80,255,130) end
        end
        UpdateHUD(); return
    end

    if key==Enum.KeyCode[SS.keyFarm] then
        autoFarmActive=not autoFarmActive; SS.autoFarm=autoFarmActive
        if autoFarmActive then task.spawn(AutoFarmLoop) end
        UpdateHUD()
    end
    if key==Enum.KeyCode[SS.keyGUI] then
        if HubGui then HubGui.Enabled=not HubGui.Enabled end
    end
end)

-- ════════════════════════════════════════════════════════════════
-- ESP
-- ════════════════════════════════════════════════════════════════
local function CreateESP(plr)
    if espObjects[plr.Name] then return end
    local hl=Instance.new("Highlight")
    hl.FillColor=Color3.fromRGB(255,0,0); hl.OutlineColor=Color3.fromRGB(255,255,255)
    hl.FillTransparency=0.5; hl.OutlineTransparency=0
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.fromOffset(150,50); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
    local nl=Instance.new("TextLabel",bb); nl.Name="NL"
    nl.Size=UDim2.new(1,0,0.5,0); nl.BackgroundTransparency=1
    nl.Font=Enum.Font.GothamBold; nl.TextSize=14
    nl.TextColor3=Color3.fromRGB(255,80,80); nl.TextStrokeTransparency=0; nl.Text=plr.Name
    local dl=Instance.new("TextLabel",bb); dl.Name="DL"
    dl.Size=UDim2.new(1,0,0.5,0); dl.Position=UDim2.new(0,0,0.5,0)
    dl.BackgroundTransparency=1; dl.Font=Enum.Font.Gotham; dl.TextSize=12
    dl.TextColor3=Color3.fromRGB(255,255,100); dl.TextStrokeTransparency=0; dl.Text="..."
    espObjects[plr.Name]={hl=hl,bb=bb,nl=nl,dl=dl}
end
local function RemoveESP(name)
    if espObjects[name] then
        pcall(function() espObjects[name].hl:Destroy() end)
        pcall(function() espObjects[name].bb:Destroy() end)
        espObjects[name]=nil
    end
end
local function ClearESP() for n in pairs(espObjects) do RemoveESP(n) end end

RS.RenderStepped:Connect(function()
    if not espActive then ClearESP(); return end
    local hrp=GetHRP()
    for _,plr in pairs(PLS:GetPlayers()) do
        if plr==Player then continue end
        pcall(function()
            local char=plr.Character; if not char then RemoveESP(plr.Name); return end
            local tHRP=char:FindFirstChild("HumanoidRootPart"); if not tHRP then RemoveESP(plr.Name); return end
            if not espObjects[plr.Name] then CreateESP(plr) end
            local o=espObjects[plr.Name]
            if SS.espBoxEnabled then o.hl.Adornee=char; o.hl.Parent=char else o.hl.Parent=nil end
            o.bb.Adornee=tHRP; o.bb.Parent=tHRP
            o.nl.Visible=SS.espNameEnabled; o.nl.Text=plr.Name
            o.dl.Visible=SS.espDistEnabled
            if hrp then o.dl.Text=math.floor((hrp.Position-tHRP.Position).Magnitude).." studs" end
        end)
    end
    for n in pairs(espObjects) do if not PLS:FindFirstChild(n) then RemoveESP(n) end end
end)

-- ════════════════════════════════════════════════════════════════
-- KILL AURA
-- ════════════════════════════════════════════════════════════════
RS.Heartbeat:Connect(function()
    if not auraActive then return end
    local hrp=GetHRP(); if not hrp then return end
    for _,plr in pairs(PLS:GetPlayers()) do
        if plr==Player then continue end
        pcall(function()
            if IsBlacklisted(plr) then return end
            local tHRP=plr.Character.HumanoidRootPart
            if (hrp.Position-tHRP.Position).Magnitude<=SS.auraSize then
                VIM:SendMouseButtonEvent(0,0,0,true,game,1)
                task.wait(0.01)
                VIM:SendMouseButtonEvent(0,0,0,false,game,1)
            end
        end)
    end
end)

-- ════════════════════════════════════════════════════════════════
-- ANTI KNOCKBACK
-- ════════════════════════════════════════════════════════════════
RS.Heartbeat:Connect(function()
    if not antiKnockActive then return end
    local hrp=GetHRP(); if not hrp then return end
    pcall(function() hrp.Velocity=Vector3.new(0,hrp.Velocity.Y,0) end)
end)

-- ════════════════════════════════════════════════════════════════
-- FLING
-- ════════════════════════════════════════════════════════════════
local function GetClosestAny()
    local hrp=GetHRP(); if not hrp then return nil end
    local best,closest=math.huge,nil
    for _,plr in pairs(PLS:GetPlayers()) do
        if plr==Player then continue end
        pcall(function()
            local tHRP=plr.Character.HumanoidRootPart
            local d=(hrp.Position-tHRP.Position).Magnitude
            if d<best then closest=plr; best=d end
        end)
    end
    return closest
end
RS.Heartbeat:Connect(function()
    if not flingActive then return end
    local t=GetClosestAny(); if not t or not t.Character then return end
    local hrp=GetHRP()
    local tHRP=t.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    pcall(function()
        local bv=Instance.new("BodyVelocity")
        bv.Velocity=(tHRP.Position-hrp.Position).Unit*SS.flingPower
        bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.P=1e9; bv.Parent=tHRP
        task.delay(0.1,function() bv:Destroy() end)
    end)
end)

-- ════════════════════════════════════════════════════════════════
-- AUTO RESPAWN
-- ════════════════════════════════════════════════════════════════
RS.Heartbeat:Connect(function()
    if not autoRespawnActive then return end
    local hum=GetHum()
    if hum and hum.Health<=0 then task.wait(0.5); PLS.LocalPlayer:LoadCharacter() end
end)

-- ════════════════════════════════════════════════════════════════
-- CLICK TP
-- ════════════════════════════════════════════════════════════════
local function EnableClickTP()
    if clickTpConn then clickTpConn:Disconnect() end
    clickTpConn=UIS.InputBegan:Connect(function(input,gpe)
        if gpe then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            local hrp=GetHRP(); if not hrp then return end
            local ray=workspace.CurrentCamera:ScreenPointToRay(input.Position.X,input.Position.Y)
            local res=workspace:Raycast(ray.Origin,ray.Direction*1000)
            if res then hrp.CFrame=CFrame.new(res.Position+Vector3.new(0,3,0)) end
        end
    end)
end
local function DisableClickTP()
    if clickTpConn then clickTpConn:Disconnect(); clickTpConn=nil end
end

-- ════════════════════════════════════════════════════════════════
-- AUTO FARM — helpers
-- ════════════════════════════════════════════════════════════════
local function Click()
    VIM:SendMouseButtonEvent(0,0,0,true,game,1)
    task.wait(0.01)
    VIM:SendMouseButtonEvent(0,0,0,false,game,1)
end

-- Verifica se uma posição está dentro do bounding box do Lobby
local function IsInLobby(pos)
    local lobby=workspace:FindFirstChild("Lobby"); if not lobby then return false end
    local ok,cf,sz=pcall(function() return lobby:GetBoundingBox() end)
    if not ok then return false end
    local lp=cf:PointToObjectSpace(pos); local h=sz/2
    return math.abs(lp.X)<=h.X and math.abs(lp.Y)<=h.Y and math.abs(lp.Z)<=h.Z
end

-- Posição do Teleport1 dentro do Lobby
local function GetLobbyTP()
    local lobby=workspace:FindFirstChild("Lobby"); if not lobby then return nil end
    local tp=lobby:FindFirstChild("Teleport1"); if not tp then return nil end
    if tp:IsA("BasePart") then return tp.Position+Vector3.new(0,3,0)
    elseif tp:IsA("Model") then
        local ref=tp.PrimaryPart
        if not ref then
            for _,v in pairs(tp:GetDescendants()) do if v:IsA("BasePart") then ref=v; break end end
        end
        if ref then return ref.Position+Vector3.new(0,3,0) end
    end
    return nil
end

local DANGER={"overkill","error","the flex"}
local function HasDanger(plr)
    local function bad(n)
        local lo=n:lower()
        for _,t in ipairs(DANGER) do if lo==t then return true end end
        return false
    end
    if plr.Character then
        for _,o in pairs(plr.Character:GetChildren()) do if o:IsA("Tool") and bad(o.Name) then return true end end
    end
    local bp=plr:FindFirstChild("Backpack")
    if bp then for _,o in pairs(bp:GetChildren()) do if o:IsA("Tool") and bad(o.Name) then return true end end end
    return false
end

-- Pega alvo mais próximo respeitando blacklist / lobby / tools perigosas
local function GetTarget()
    local hrp=GetHRP(); if not hrp then return nil end
    local best,closest=math.huge,nil
    for _,plr in pairs(PLS:GetPlayers()) do
        if plr==Player then continue end
        pcall(function()
            local tHRP=plr.Character.HumanoidRootPart
            local tHum=plr.Character.Humanoid
            if IsInLobby(tHRP.Position) then return end
            if HasDanger(plr) then return end
            if IsBlacklisted(plr) then return end
            if tHum.Health>0 then
                local d=(hrp.Position-tHRP.Position).Magnitude
                if d<best and d<=SS.farmRange then closest=plr; best=d end
            end
        end)
    end
    return closest
end

-- ════════════════════════════════════════════════════════════════
-- TWEEN CONTÍNUO
-- goalFn  → função que retorna Vector3 destino (atualizado a cada frame)
-- lookFn  → função que retorna Vector3 para onde olhar (opcional)
-- Recria o tween sempre que o anterior termina, seguindo o alvo em tempo real
-- ════════════════════════════════════════════════════════════════
local function StopTween()
    if farmConn then farmConn:Disconnect(); farmConn=nil end
    if activeTween then activeTween:Cancel(); activeTween=nil end
end

local function StartTween(goalFn, lookFn)
    StopTween()
    farmConn=RS.Heartbeat:Connect(function()
        if not autoFarmActive then StopTween(); return end
        local hrp=GetHRP(); if not hrp then return end
        local goal=goalFn(); if not goal then return end

        -- Gira para olhar o alvo no plano horizontal
        if lookFn then
            local lp=lookFn()
            if lp then
                local dir=(lp-hrp.Position)*Vector3.new(1,0,1)
                if dir.Magnitude>0.1 then
                    hrp.CFrame=CFrame.new(hrp.Position, hrp.Position+dir)
                end
            end
        end

        -- Recria tween apenas quando o anterior terminou
        if not activeTween or activeTween.PlaybackState~=Enum.PlaybackState.Playing then
            local dist=(hrp.Position-goal).Magnitude
            local dur=math.max(dist/(SS.farmSpeed*10), 0.05)
            activeTween=TS:Create(hrp, TweenInfo.new(dur,Enum.EasingStyle.Linear), {CFrame=CFrame.new(goal)})
            activeTween:Play()
        end
    end)
end

-- ════════════════════════════════════════════════════════════════
-- LOOP PRINCIPAL DO FARM
-- ════════════════════════════════════════════════════════════════
AutoFarmLoop = function()
    local pTimer=tick(); local onPause=false

    while autoFarmActive do
        -- Pausa 3s a cada 3s ativo (anti-ban básico)
        if not onPause and tick()-pTimer>=3 then
            onPause=true; StopTween()
            local hrp=GetHRP(); if hrp then hrp.Anchored=true end
            task.wait(3)
            local hrp2=GetHRP(); if hrp2 then hrp2.Anchored=false end
            onPause=false; pTimer=tick(); continue
        end

        local hrp=GetHRP(); local hum=GetHum()
        if not hrp or not hum or hum.Health<=0 then StopTween(); task.wait(0.5); continue end

        -- ── Estou no Lobby? → vai pro Teleport1 ──────────────
        if IsInLobby(hrp.Position) then
            local tpPos=GetLobbyTP()
            if tpPos then
                if (hrp.Position-tpPos).Magnitude>5 then
                    -- Tween suave até o portal, sem olhar para ninguém
                    StartTween(function() return tpPos end, nil)
                    task.wait(0.2)
                else
                    -- Chegou no portal, para e espera carregar a arena
                    StopTween(); task.wait(3); pTimer=tick()
                end
            else
                StopTween(); task.wait(0.2)
            end
            continue
        end

        -- ── Fora do Lobby → persegue alvo e clica ────────────
        local target=GetTarget()
        if target and target.Character then
            local tHRP=target.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                StartTween(
                    function()
                        -- Fica um pouco abaixo do HRP do alvo (Y offset)
                        local t=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                        return t and (t.Position+Vector3.new(0,-SS.farmDistance,0)) or nil
                    end,
                    function()
                        local t=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                        return t and t.Position or nil
                    end
                )
                local t0=tick()
                while autoFarmActive and tick()-t0<0.5 do
                    Click(); task.wait(0.05)
                end
                continue
            end
        end

        -- Sem alvo → só clica
        StopTween(); Click(); task.wait(0.1)
    end

    StopTween(); UpdateHUD()
end

-- ════════════════════════════════════════════════════════════════
-- BLACKLIST — lista de players para o farm ignorar
-- ════════════════════════════════════════════════════════════════
RebuildBL = function()
    if not blPanelRef or not blPanelRef.Parent then return end
    for _,v in pairs(blPanelRef:GetChildren()) do
        if not v:IsA("UIListLayout") then v:Destroy() end
    end
    local count=0
    for _,plr in ipairs(PLS:GetPlayers()) do
        if plr==Player then continue end
        count+=1
        local blocked=blacklist[plr.Name]==true

        local row=Instance.new("Frame",blPanelRef)
        row.Size=UDim2.new(1,0,0,38)
        row.BackgroundColor3=blocked and Color3.fromRGB(70,15,15) or Color3.fromRGB(18,44,18)
        row.BackgroundTransparency=0.2
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)
        local rs=Instance.new("UIStroke",row)
        rs.Color=blocked and Color3.fromRGB(180,30,30) or Color3.fromRGB(30,130,30); rs.Thickness=1

        -- Nome do player
        local nLbl=Instance.new("TextLabel",row)
        nLbl.Size=UDim2.new(1,-100,1,0); nLbl.Position=UDim2.fromOffset(8,0)
        nLbl.BackgroundTransparency=1; nLbl.Font=Enum.Font.GothamBold
        nLbl.TextSize=13; nLbl.TextColor3=Color3.new(1,1,1)
        nLbl.TextXAlignment=Enum.TextXAlignment.Left; nLbl.Text=plr.Name

        -- Ícone de status
        local icon=Instance.new("TextLabel",row)
        icon.Size=UDim2.fromOffset(22,22); icon.Position=UDim2.new(1,-98,0.5,-11)
        icon.BackgroundTransparency=1; icon.Font=Enum.Font.GothamBold; icon.TextSize=15
        icon.Text=blocked and "X" or "OK"
        icon.TextColor3=blocked and Color3.fromRGB(255,80,80) or Color3.fromRGB(80,255,100)

        -- Botão toggle
        local btn=Instance.new("TextButton",row)
        btn.Size=UDim2.fromOffset(68,26); btn.Position=UDim2.new(1,-72,0.5,-13)
        btn.Font=Enum.Font.GothamBold; btn.TextSize=11
        btn.TextColor3=Color3.new(1,1,1); btn.AutoButtonColor=false
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
        btn.Text=blocked and "Incluir" or "Ignorar"
        btn.BackgroundColor3=blocked and Color3.fromRGB(25,110,25) or Color3.fromRGB(150,25,25)
        local cap=plr.Name
        btn.MouseButton1Click:Connect(function()
            if blacklist[cap] then blacklist[cap]=nil else blacklist[cap]=true end
            RebuildBL()
        end)
    end

    if count==0 then
        local empty=Instance.new("TextLabel",blPanelRef)
        empty.Size=UDim2.new(1,0,0,34); empty.BackgroundTransparency=1
        empty.Font=Enum.Font.Gotham; empty.TextSize=12
        empty.TextColor3=Color3.fromRGB(120,120,120); empty.Text="Nenhum outro player no servidor."
        count=1
    end

    blPanelRef.Size=UDim2.new(1,0,0,count*42)
    UCS()
end

PLS.PlayerAdded:Connect(function() task.wait(0.5); RebuildBL() end)
PLS.PlayerRemoving:Connect(function(plr) blacklist[plr.Name]=nil; RebuildBL() end)

-- ════════════════════════════════════════════════════════════════
-- HELPERS DE UI GENÉRICOS
-- ════════════════════════════════════════════════════════════════
local function TitLbl(text,color)
    local l=Instance.new("TextLabel",SC); l.Size=UDim2.new(1,0,0,42)
    l.BackgroundTransparency=1; l.Text=text; l.Font=Enum.Font.GothamBold
    l.TextScaled=true; l.TextColor3=color or Color3.new(1,1,1); return l
end
local function SecLbl(text,color)
    local l=Instance.new("TextLabel",SC); l.Size=UDim2.new(1,0,0,26)
    l.BackgroundTransparency=1; l.Text=text; l.Font=Enum.Font.GothamBold
    l.TextSize=14; l.TextColor3=color or Color3.new(1,1,1)
    l.TextXAlignment=Enum.TextXAlignment.Left; return l
end
local function SmallLbl(text)
    local l=Instance.new("TextLabel",SC); l.Size=UDim2.new(1,0,0,18)
    l.BackgroundTransparency=1; l.Text=text; l.Font=Enum.Font.Gotham
    l.TextSize=11; l.TextColor3=Color3.fromRGB(140,140,160)
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true; return l
end
local function ActBtn(text,bg,cb)
    local b=Instance.new("TextButton",SC); b.Size=UDim2.new(1,0,0,38)
    b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=13
    b.BackgroundColor3=bg; b.TextColor3=Color3.new(1,1,1)
    b.AutoButtonColor=false; Instance.new("UICorner",b); b.MouseButton1Click:Connect(cb); return b
end
local function KeyBindBtn(text,slot)
    local b=Instance.new("TextButton",SC); b.Size=UDim2.new(1,0,0,34)
    b.Font=Enum.Font.GothamBold; b.TextSize=12
    b.BackgroundColor3=Color3.fromRGB(40,22,66); b.BackgroundTransparency=0.25
    b.TextColor3=Color3.fromRGB(200,180,255); b.AutoButtonColor=false; b.Text=text
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",b).Color=Color3.fromRGB(100,0,200)
    b.MouseButton1Click:Connect(function()
        capturingKey=slot
        b.Text="Pressione qualquer tecla..."
        b.TextColor3=Color3.fromRGB(255,220,50)
    end)
    return b
end

-- ════════════════════════════════════════════════════════════════
-- TAB: FARM
-- ════════════════════════════════════════════════════════════════
local function LoadFarm()
    Clear(); blPanelRef=nil

    TitLbl("Farm  —  Slap Battles", Color3.fromRGB(255,200,100))

    -- Teclas de atalho
    SecLbl("Teclas de Atalho", Color3.fromRGB(180,180,255))
    SmallLbl("  Clique no botao e pressione a tecla desejada.")
    farmKeyLbl=KeyBindBtn("Tecla Farm: ["..SS.keyFarm.."]  (clique p/ mudar)","farm")
    guiKeyLbl =KeyBindBtn("Tecla GUI:  ["..SS.keyGUI.."]  (clique p/ mudar)","gui")
    SmallLbl("  A tecla GUI mostra/esconde a janela a qualquer momento.")

    -- Auto Farm
    SecLbl("Auto Farm", Color3.fromRGB(255,200,100))
    SmallLbl("  Persegue o player mais proximo com Tween e clica automaticamente.")
    SmallLbl("  Detecta Lobby e vai ao Teleport1 quando necessario.")
    Checkbox("Ativar Auto Farm", SS.autoFarm, function(v)
        SS.autoFarm=v; autoFarmActive=v
        if v then task.spawn(AutoFarmLoop) end
        UpdateHUD()
    end)
    Slider("Velocidade do Tween",5,100,SS.farmSpeed,function(v) SS.farmSpeed=v end)
    Slider("Distancia do alvo (Y)",1,50,SS.farmDistance,function(v) SS.farmDistance=v end)
    Slider("Alcance do Farm (studs)",10,500,SS.farmRange,function(v) SS.farmRange=v end)

    -- Blacklist
    SecLbl("Ignorar Players no Farm", Color3.fromRGB(255,120,120))
    SmallLbl("  Players marcados serao pulados pelo farm e pela Kill Aura.")

    local blPanel=Instance.new("Frame",SC)
    blPanel.Size=UDim2.new(1,0,0,38); blPanel.BackgroundTransparency=1
    local bll=Instance.new("UIListLayout",blPanel)
    bll.Padding=UDim.new(0,4); bll.SortOrder=Enum.SortOrder.LayoutOrder
    blPanelRef=blPanel; RebuildBL()

    -- Hitbox Expander
    SecLbl("Hitbox Expander", Color3.fromRGB(255,100,100))
    local hLoaded=false
    local hBtn=ActBtn("Carregar Hitbox Expander",Color3.fromRGB(110,25,25),function() end)
    hBtn.MouseButton1Click:Connect(function()
        if hLoaded then return end; hLoaded=true
        hBtn.Text="Carregando..."; hBtn.BackgroundColor3=Color3.fromRGB(80,80,20)
        task.spawn(function()
            pcall(function()
                loadstring(game:HttpGet(
                    "https://gist.githubusercontent.com/stellar-4242/430ef3087d8d87eb306ca03e728ffbb8/raw/798429dd908b1f4471a1fa569ff62c5e5a93ec61/SLAP.LUA"
                ))()
            end)
            hBtn.Text="Hitbox Carregado!"; hBtn.BackgroundColor3=Color3.fromRGB(25,100,25)
        end)
    end)

    -- Kill Aura
    SecLbl("Kill Aura", Color3.fromRGB(255,80,80))
    Checkbox("Ativar Kill Aura",SS.auraEnabled,function(v) SS.auraEnabled=v; auraActive=v end)
    Slider("Aura Range (studs)",5,100,SS.auraSize,function(v) SS.auraSize=v end)

    -- Fling
    SecLbl("Fling", Color3.fromRGB(255,150,50))
    Checkbox("Ativar Fling",SS.flingEnabled,function(v) SS.flingEnabled=v; flingActive=v end)
    Slider("Fling Power",100,2000,SS.flingPower,function(v) SS.flingPower=v end)

    UCS()
end

-- ════════════════════════════════════════════════════════════════
-- TAB: ESP
-- ════════════════════════════════════════════════════════════════
local function LoadESP()
    Clear()
    TitLbl("ESP  —  Slap Battles", Color3.fromRGB(100,200,255))
    Checkbox("ESP Ativo",SS.espEnabled,function(v) SS.espEnabled=v; espActive=v; if not v then ClearESP() end end)
    Checkbox("ESP Box (Highlight)",SS.espBoxEnabled,function(v) SS.espBoxEnabled=v end)
    Checkbox("ESP Nome",SS.espNameEnabled,function(v) SS.espNameEnabled=v end)
    Checkbox("ESP Distancia",SS.espDistEnabled,function(v) SS.espDistEnabled=v end)
    UCS()
end

-- ════════════════════════════════════════════════════════════════
-- TAB: MISC
-- ════════════════════════════════════════════════════════════════
local function LoadMisc()
    Clear()
    TitLbl("Misc  —  Slap Battles", Color3.fromRGB(200,200,200))

    SecLbl("Anti Knockback", Color3.fromRGB(100,255,100))
    Checkbox("Anti Knockback",SS.antiKnockback,function(v) SS.antiKnockback=v; antiKnockActive=v end)

    SecLbl("Auto Respawn", Color3.fromRGB(255,200,100))
    Checkbox("Auto Respawn (ao morrer)",SS.autoRespawn,function(v) SS.autoRespawn=v; autoRespawnActive=v end)

    SecLbl("Click TP", Color3.fromRGB(255,200,50))
    SmallLbl("  Clique no chao para teleportar até aquele ponto.")
    Checkbox("Click TP",SS.clickTpEnabled,function(v)
        SS.clickTpEnabled=v; clickTpActive=v
        if v then EnableClickTP() else DisableClickTP() end
    end)

    SecLbl("Safe Zone", Color3.fromRGB(100,255,100))
    SmallLbl("  Plataforma invisivel em Y=500, Z=99999. Ninguem alcanca.")
    ActBtn("TP para Safe Zone",Color3.fromRGB(25,120,25),TpSafe)

    SecLbl("Anti Void", Color3.fromRGB(100,200,255))
    SmallLbl("  Part gigante no nivel da Grass do Arena. Impede cair no void.")
    ActBtn("Recriar Anti Void",Color3.fromRGB(25,60,130),function()
        if antiVoidPart then pcall(function() antiVoidPart:Destroy() end); antiVoidPart=nil end
        pcall(function()
            local arena=workspace:FindFirstChild("Arena")
            local island=arena and arena:FindFirstChild("main island")
            local grass=island and island:FindFirstChild("Grass")
            if grass and grass:IsA("BasePart") then
                local floorY=grass.Position.Y
                antiVoidPart=Instance.new("Part")
                antiVoidPart.Name="N3onAntiVoid"
                antiVoidPart.Size=Vector3.new(99999,0.1,99999)
                antiVoidPart.CFrame=CFrame.new(0,floorY,0)
                antiVoidPart.Anchored=true; antiVoidPart.CanCollide=true
                antiVoidPart.Transparency=1; antiVoidPart.CanQuery=false
                antiVoidPart.CanTouch=false; antiVoidPart.Locked=true
                antiVoidPart.Parent=workspace
            end
        end)
    end)

    ActBtn("TP para Closest Player",Color3.fromRGB(25,70,160),function()
        local t=GetClosestAny()
        if t and t.Character then
            local hrp=GetHRP(); local tHRP=t.Character:FindFirstChild("HumanoidRootPart")
            if hrp and tHRP then hrp.CFrame=tHRP.CFrame+Vector3.new(0,3,0) end
        end
    end)

    UCS()
end

-- ════════════════════════════════════════════════════════════════
-- REGISTRA TABS
-- ════════════════════════════════════════════════════════════════
Tab("Farm", "Farm", 0, LoadFarm)
Tab("ESP",  "ESP",  0, LoadESP)
Tab("Misc", "Misc", 0, LoadMisc)

print("[Slap Battles] Modulo carregado!")
