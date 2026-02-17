-- ╔══════════════════════════════════════════════════════════════╗
--   N3on Hub  ·  Slap Battles  ·  v4
--   Design: deep-space dark · neon accent · card-based layout
-- ╚══════════════════════════════════════════════════════════════╝

-- ╔══════════════════════════════════════╗
--   WAIT HUB LOAD (robusto)
-- ╚══════════════════════════════════════╝

local function WaitHub()

    local timeout = 15
    local t0 = tick()

    repeat
        task.wait()

        if _G.N3onHub
        and _G.N3onHub._loaded
        and _G.N3onHub.GUI
        and _G.N3onHub.GUI.Hub
        and _G.N3onHub.GUI.ScrollContent
        and _G.N3onHub.Tab
        and _G.N3onHub.Slider
        and _G.N3onHub.Checkbox then

            return true
        end

    until tick() - t0 > timeout

    return false
end

if not WaitHub() then
    warn("[N3on·Slap] Base Hub nao carregou corretamente!")
    return
end

local TS     = game:GetService("TweenService")
local RS     = game:GetService("RunService")
local PLS    = game:GetService("Players")
local VIM    = game:GetService("VirtualInputManager")
local UIS    = game:GetService("UserInputService")
local Player = PLS.LocalPlayer

print("[N3on·Slap] v4 carregando...")

-- aliases
local GUI      = _G.N3onHub.GUI
local SC       = GUI.ScrollContent
local Clear    = GUI.Clear
local UCS      = GUI.UpdateCanvasSize
local Slider   = _G.N3onHub.Slider
local Checkbox = _G.N3onHub.Checkbox
local Tab      = _G.N3onHub.Tab
local HubGui   = GUI.Hub
local F1       = GUI.F1

-- ── palette ────────────────────────────────────────────────────
local C = {
    bg0    = Color3.fromRGB( 10,  6, 22),  -- fundo profundo
    bg1    = Color3.fromRGB( 18, 12, 36),  -- card base
    bg2    = Color3.fromRGB( 28, 18, 54),  -- card elevado
    acc    = Color3.fromRGB(130,  0,255),  -- roxo neon
    acc2   = Color3.fromRGB(200, 80,255),  -- lilás brilhante
    cyan   = Color3.fromRGB( 60,220,255),  -- destaque ciano
    green  = Color3.fromRGB( 60,255,130),  -- status on
    red    = Color3.fromRGB(255, 60, 90),  -- status off / perigo
    orange = Color3.fromRGB(255,160, 40),  -- aviso
    gold   = Color3.fromRGB(255,210, 80),  -- títulos farm
    white  = Color3.fromRGB(235,225,255),  -- texto principal
    muted  = Color3.fromRGB(130,115,160),  -- texto secundário
    sep    = Color3.fromRGB( 55, 35, 90),  -- separador
}

-- ── saved states ────────────────────────────────────────────────
local SS = _G.N3onHub.SavedStates
local function def(k,v) if SS[k]==nil then SS[k]=v end end
def("autoFarm",false) def("farmSpeed",30) def("farmDistance",15) def("farmRange",100)
def("auraEnabled",false) def("auraSize",20)
def("espEnabled",false) def("espBoxEnabled",false) def("espNameEnabled",false) def("espDistEnabled",false)
def("antiKnockback",false) def("flingEnabled",false) def("flingPower",500)
def("autoRespawn",false) def("clickTpEnabled",false)
def("keyFarm","RightControl") def("keyGUI","RightShift")

-- ── flags ───────────────────────────────────────────────────────
local autoFarmActive=false; local auraActive=false; local espActive=false
local antiKnockActive=false; local flingActive=false
local autoRespawnActive=false; local clickTpActive=false
local activeTween=nil; local farmConn=nil
local espObjects={}; local clickTpConn=nil
local capturingKey=nil
local farmKeyLbl=nil; local guiKeyLbl=nil
local blacklist={}
local blPanelRef=nil; local tpListRef=nil

local AutoFarmLoop; local RebuildBL; local RebuildTPList; local StopAll

-- ── util ────────────────────────────────────────────────────────
local function GetHRP() local c=Player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum() local c=Player.Character; return c and c:FindFirstChild("Humanoid") end
local function IsBlacklisted(plr) return blacklist[plr.Name]==true end

-- ── dangerous tool detection ────────────────────────────────────
-- Verifica BACKPACK e CHARACTER, totalmente case-insensitive + trim
local DANGER = {"overkill","error","the flex"}
local function HasDangerTool(plr)
    local function match(name)
        local s = name:lower():match("^%s*(.-)%s*$")
        for _,d in ipairs(DANGER) do if s==d then return true end end
        return false
    end
    if plr.Character then
        for _,o in ipairs(plr.Character:GetChildren()) do
            if o:IsA("Tool") and match(o.Name) then return true end
        end
    end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _,o in ipairs(bp:GetChildren()) do
            if o:IsA("Tool") and match(o.Name) then return true end
        end
    end
    return false
end
local function GetDangerToolName(plr)
    local function match(name)
        local s = name:lower():match("^%s*(.-)%s*$")
        for _,d in ipairs(DANGER) do if s==d then return name end end
        return nil
    end
    if plr.Character then
        for _,o in ipairs(plr.Character:GetChildren()) do
            if o:IsA("Tool") then local n=match(o.Name); if n then return n end end
        end
    end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _,o in ipairs(bp:GetChildren()) do
            if o:IsA("Tool") then local n=match(o.Name); if n then return n end end
        end
    end
    return nil
end

-- ── safe zone ───────────────────────────────────────────────────
local safeZone = workspace:FindFirstChild("N3onSafeZone")
if not safeZone then
    safeZone=Instance.new("Part"); safeZone.Name="N3onSafeZone"
    safeZone.Size=Vector3.new(30,1,30); safeZone.Anchored=true; safeZone.CanCollide=true
    safeZone.BrickColor=BrickColor.new("Bright green"); safeZone.Material=Enum.Material.SmoothPlastic
    safeZone.Transparency=0.4; safeZone.CFrame=CFrame.new(0,500,99999); safeZone.Parent=workspace
    local bb=Instance.new("BillboardGui",safeZone)
    bb.Size=UDim2.fromOffset(200,36); bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true
    local lb=Instance.new("TextLabel",bb); lb.Size=UDim2.new(1,0,1,0)
    lb.BackgroundTransparency=1; lb.Text="N3on · SAFE ZONE"; lb.Font=Enum.Font.GothamBold
    lb.TextSize=14; lb.TextColor3=Color3.fromRGB(60,255,130); lb.TextStrokeTransparency=0.4
end
local function TpSafe() local h=GetHRP(); if h then h.CFrame=safeZone.CFrame+Vector3.new(0,4,0) end end

-- ── anti void ───────────────────────────────────────────────────
local antiVoidPart=workspace:FindFirstChild("N3onAntiVoid")
local function CreateAntiVoid()
    if antiVoidPart then pcall(function() antiVoidPart:Destroy() end); antiVoidPart=nil end
    pcall(function()
        local arena=workspace:FindFirstChild("Arena")
        local island=arena and arena:FindFirstChild("main island")
        local grass=island and island:FindFirstChild("Grass")
        if grass and grass:IsA("BasePart") then
            antiVoidPart=Instance.new("Part")
            antiVoidPart.Name="N3onAntiVoid"
            antiVoidPart.Size=Vector3.new(99999,0.1,99999)
            antiVoidPart.CFrame=CFrame.new(0,grass.Position.Y,0)
            antiVoidPart.Anchored=true; antiVoidPart.CanCollide=true
            antiVoidPart.Transparency=1; antiVoidPart.CanQuery=false
            antiVoidPart.CanTouch=false; antiVoidPart.Locked=true
            antiVoidPart.Parent=workspace
            print("[N3on·Slap] AntiVoid criado Y=",grass.Position.Y)
        else
            warn("[N3on·Slap] Grass nao encontrada!")
        end
    end)
end
if not antiVoidPart then CreateAntiVoid() end

-- ── HUD ─────────────────────────────────────────────────────────
local PlayerGui = Player:WaitForChild("PlayerGui")
if PlayerGui:FindFirstChild("N3onHUD") then PlayerGui:FindFirstChild("N3onHUD"):Destroy() end
local hudSG = Instance.new("ScreenGui",PlayerGui)
hudSG.Name="N3onHUD"; hudSG.ResetOnSpawn=false; hudSG.DisplayOrder=999

local hudF = Instance.new("Frame",hudSG)
hudF.Size=UDim2.fromOffset(230,32); hudF.Position=UDim2.new(0,12,0,12)
hudF.BackgroundColor3=C.bg0; hudF.BackgroundTransparency=0.1
Instance.new("UICorner",hudF).CornerRadius=UDim.new(0,8)
local hs=Instance.new("UIStroke",hudF); hs.Color=C.acc; hs.Thickness=1.5

-- dot de status
local hudDot=Instance.new("Frame",hudF)
hudDot.Size=UDim2.fromOffset(8,8); hudDot.Position=UDim2.new(0,10,0.5,-4)
hudDot.BackgroundColor3=C.red; Instance.new("UICorner",hudDot).CornerRadius=UDim.new(1,0)

local hudLbl=Instance.new("TextLabel",hudF)
hudLbl.Size=UDim2.new(1,-26,1,0); hudLbl.Position=UDim2.fromOffset(24,0)
hudLbl.BackgroundTransparency=1; hudLbl.Font=Enum.Font.GothamBold; hudLbl.TextSize=12
hudLbl.TextXAlignment=Enum.TextXAlignment.Left; hudLbl.TextColor3=C.muted
hudLbl.Text="Farm OFF  ·  "..SS.keyFarm

local function UpdateHUD()
    if autoFarmActive then
        hudDot.BackgroundColor3=C.green; hudLbl.TextColor3=C.green
        hudLbl.Text="Farm ON  ·  "..SS.keyFarm.." p/toggle"
        hs.Color=C.green
    else
        hudDot.BackgroundColor3=C.red; hudLbl.TextColor3=C.muted
        hudLbl.Text="Farm OFF  ·  "..SS.keyFarm.." p/toggle"
        hs.Color=C.acc
    end
end

-- ── stop all ────────────────────────────────────────────────────
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

-- ── close popup ─────────────────────────────────────────────────
task.defer(function()
    if not F1 then return end
    local cb; for _,v in ipairs(F1:GetDescendants()) do
        if v:IsA("TextButton") and v.Text=="X" then cb=v; break end
    end
    if not cb then return end
    local nb=cb:Clone(); nb.Parent=cb.Parent; cb:Destroy()

    nb.MouseButton1Click:Connect(function()
        local ov=Instance.new("Frame",HubGui)
        ov.Size=UDim2.fromScale(1,1); ov.BackgroundColor3=Color3.new(0,0,0)
        ov.BackgroundTransparency=1; ov.ZIndex=30
        TS:Create(ov,TweenInfo.new(0.2),{BackgroundTransparency=0.6}):Play()

        local pop=Instance.new("Frame",ov)
        pop.Size=UDim2.fromOffset(0,0); pop.Position=UDim2.fromScale(0.5,0.5)
        pop.AnchorPoint=Vector2.new(0.5,0.5); pop.BackgroundColor3=C.bg1
        pop.ZIndex=31; Instance.new("UICorner",pop).CornerRadius=UDim.new(0,14)
        local ps=Instance.new("UIStroke",pop); ps.Color=C.red; ps.Thickness=2

        TS:Create(pop,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
            {Size=UDim2.fromOffset(360,200)}):Play()

        -- topo vermelho
        local topBar=Instance.new("Frame",pop)
        topBar.Size=UDim2.new(1,0,0,38); topBar.BackgroundColor3=Color3.fromRGB(140,20,40); topBar.ZIndex=32
        local tc=Instance.new("UICorner",topBar); tc.CornerRadius=UDim.new(0,12)
        -- cobre canto inferior do topBar
        local tfix=Instance.new("Frame",topBar); tfix.Size=UDim2.new(1,0,0,14)
        tfix.Position=UDim2.new(0,0,1,-14); tfix.BackgroundColor3=Color3.fromRGB(140,20,40); tfix.ZIndex=32
        local wl=Instance.new("TextLabel",topBar)
        wl.Size=UDim2.new(1,0,1,0); wl.BackgroundTransparency=1; wl.ZIndex=33
        wl.Font=Enum.Font.GothamBold; wl.TextSize=13; wl.TextColor3=Color3.new(1,1,1)
        wl.Text="  ⚠  TODOS OS RECURSOS SERÃO DESATIVADOS"

        local body=Instance.new("TextLabel",pop)
        body.Size=UDim2.new(1,-24,0,80); body.Position=UDim2.fromOffset(12,46)
        body.BackgroundTransparency=1; body.Font=Enum.Font.Gotham; body.TextSize=13
        body.TextWrapped=true; body.TextColor3=C.white; body.ZIndex=32
        body.Text="Fechar o N3on Hub vai parar o Auto Farm, ESP, Kill Aura, Fling e tudo mais de forma imediata.

Tem certeza?"

        local function mkBtn(lbl,bg,xPct)
            local b=Instance.new("TextButton",pop)
            b.Size=UDim2.fromOffset(130,34); b.Position=UDim2.new(xPct,-65,1,-48)
            b.Text=lbl; b.Font=Enum.Font.GothamBold; b.TextSize=13
            b.BackgroundColor3=bg; b.TextColor3=Color3.new(1,1,1)
            b.AutoButtonColor=false; b.ZIndex=32; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
            return b
        end
        local yBtn=mkBtn("Fechar hub",Color3.fromRGB(160,25,45),0.3)
        local nBtn=mkBtn("Cancelar",Color3.fromRGB(30,110,50),0.75)

        local function closePopup()
            TS:Create(ov,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
            local t2=TS:Create(pop,TweenInfo.new(0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,0)})
            t2:Play(); t2.Completed:Connect(function() ov:Destroy() end)
        end
        nBtn.MouseButton1Click:Connect(closePopup)
        yBtn.MouseButton1Click:Connect(function()
            StopAll(); ov:Destroy()
            TS:Create(F1,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),
                {Size=UDim2.fromOffset(660,390),BackgroundTransparency=0.8}):Play()
            task.wait(0.22); HubGui:Destroy(); hudSG:Destroy()
        end)
    end)
end)

-- ── hotkeys ─────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(input,gpe)
    if input.UserInputType~=Enum.UserInputType.Keyboard then return end
    local key=input.KeyCode
    if capturingKey then
        local slot=capturingKey; capturingKey=nil; local name=key.Name
        if slot=="farm" then
            SS.keyFarm=name
            if farmKeyLbl then farmKeyLbl.Text=name; farmKeyLbl.TextColor3=C.green end
        elseif slot=="gui" then
            SS.keyGUI=name
            if guiKeyLbl then guiKeyLbl.Text=name; guiKeyLbl.TextColor3=C.green end
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

-- ── ESP ─────────────────────────────────────────────────────────
local function CreateESP(plr)
    if espObjects[plr.Name] then return end
    local hl=Instance.new("Highlight")
    hl.FillColor=Color3.fromRGB(255,0,0); hl.OutlineColor=C.cyan
    hl.FillTransparency=0.5; hl.OutlineTransparency=0
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.fromOffset(150,50); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true
    local nl=Instance.new("TextLabel",bb); nl.Name="NL"
    nl.Size=UDim2.new(1,0,0.5,0); nl.BackgroundTransparency=1
    nl.Font=Enum.Font.GothamBold; nl.TextSize=14
    nl.TextColor3=C.cyan; nl.TextStrokeTransparency=0; nl.Text=plr.Name
    local dl=Instance.new("TextLabel",bb); dl.Name="DL"
    dl.Size=UDim2.new(1,0,0.5,0); dl.Position=UDim2.new(0,0,0.5,0)
    dl.BackgroundTransparency=1; dl.Font=Enum.Font.Gotham; dl.TextSize=12
    dl.TextColor3=C.gold; dl.TextStrokeTransparency=0; dl.Text="..."
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

-- ── kill aura ───────────────────────────────────────────────────
RS.Heartbeat:Connect(function()
    if not auraActive then return end
    local hrp=GetHRP(); if not hrp then return end
    for _,plr in pairs(PLS:GetPlayers()) do
        if plr==Player then continue end
        pcall(function()
            if IsBlacklisted(plr) or HasDangerTool(plr) then return end
            local tHRP=plr.Character.HumanoidRootPart
            if (hrp.Position-tHRP.Position).Magnitude<=SS.auraSize then
                VIM:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.01)
                VIM:SendMouseButtonEvent(0,0,0,false,game,1)
            end
        end)
    end
end)

-- ── anti knockback ──────────────────────────────────────────────
RS.Heartbeat:Connect(function()
    if not antiKnockActive then return end
    local hrp=GetHRP(); if not hrp then return end
    pcall(function() hrp.Velocity=Vector3.new(0,hrp.Velocity.Y,0) end)
end)

-- ── fling ───────────────────────────────────────────────────────
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
    local hrp=GetHRP(); local tHRP=t.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    pcall(function()
        local bv=Instance.new("BodyVelocity")
        bv.Velocity=(tHRP.Position-hrp.Position).Unit*SS.flingPower
        bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.P=1e9; bv.Parent=tHRP
        task.delay(0.1,function() bv:Destroy() end)
    end)
end)

-- ── auto respawn ────────────────────────────────────────────────
RS.Heartbeat:Connect(function()
    if not autoRespawnActive then return end
    local hum=GetHum()
    if hum and hum.Health<=0 then task.wait(0.5); PLS.LocalPlayer:LoadCharacter() end
end)

-- ── click tp ────────────────────────────────────────────────────
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

-- ── farm helpers ────────────────────────────────────────────────
local function Click()
    VIM:SendMouseButtonEvent(0,0,0,true,game,1); task.wait(0.01)
    VIM:SendMouseButtonEvent(0,0,0,false,game,1)
end
local function IsInLobby(pos)
    local lobby=workspace:FindFirstChild("Lobby"); if not lobby then return false end
    local ok,cf,sz=pcall(function() return lobby:GetBoundingBox() end)
    if not ok then return false end
    local lp=cf:PointToObjectSpace(pos); local h=sz/2
    return math.abs(lp.X)<=h.X and math.abs(lp.Y)<=h.Y and math.abs(lp.Z)<=h.Z
end
local function GetLobbyTP()
    local lobby=workspace:FindFirstChild("Lobby"); if not lobby then return nil end
    local tp=lobby:FindFirstChild("Teleport1"); if not tp then return nil end
    if tp:IsA("BasePart") then return tp.Position+Vector3.new(0,3,0) end
    if tp:IsA("Model") then
        local ref=tp.PrimaryPart
        if not ref then for _,v in pairs(tp:GetDescendants()) do if v:IsA("BasePart") then ref=v; break end end end
        if ref then return ref.Position+Vector3.new(0,3,0) end
    end
    return nil
end
local function GetTarget()
    local hrp=GetHRP(); if not hrp then return nil end
    local best,closest=math.huge,nil
    for _,plr in pairs(PLS:GetPlayers()) do
        if plr==Player then continue end
        pcall(function()
            local tHRP=plr.Character.HumanoidRootPart
            local tHum=plr.Character.Humanoid
            if IsInLobby(tHRP.Position) then return end
            if HasDangerTool(plr) then return end
            if IsBlacklisted(plr) then return end
            if tHum.Health>0 then
                local d=(hrp.Position-tHRP.Position).Magnitude
                if d<best and d<=SS.farmRange then closest=plr; best=d end
            end
        end)
    end
    return closest
end

-- ── tween contínuo ──────────────────────────────────────────────
local function StopTween()
    if farmConn then farmConn:Disconnect(); farmConn=nil end
    if activeTween then activeTween:Cancel(); activeTween=nil end
end
local function StartTween(goalFn,lookFn)
    StopTween()
    farmConn=RS.Heartbeat:Connect(function()
        if not autoFarmActive then StopTween(); return end
        local hrp=GetHRP(); if not hrp then return end
        local goal=goalFn(); if not goal then return end
        if lookFn then
            local lp=lookFn()
            if lp then
                local dir=(lp-hrp.Position)*Vector3.new(1,0,1)
                if dir.Magnitude>0.1 then hrp.CFrame=CFrame.new(hrp.Position,hrp.Position+dir) end
            end
        end
        if not activeTween or activeTween.PlaybackState~=Enum.PlaybackState.Playing then
            local dist=(hrp.Position-goal).Magnitude
            local dur=math.max(dist/(SS.farmSpeed*10),0.05)
            activeTween=TS:Create(hrp,TweenInfo.new(dur,Enum.EasingStyle.Linear),{CFrame=CFrame.new(goal)})
            activeTween:Play()
        end
    end)
end

-- Tween one-shot para TP manual (sem loop de farm)
local function TweenToPlayer(plr)
    if not plr or not plr.Character then return end
    local hrp=GetHRP(); local tHRP=plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHRP then return end
    local dist=(hrp.Position-tHRP.Position).Magnitude
    local dur=math.max(dist/(SS.farmSpeed*10),0.3)
    if activeTween then activeTween:Cancel(); activeTween=nil end
    activeTween=TS:Create(hrp,TweenInfo.new(dur,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
        {CFrame=tHRP.CFrame+Vector3.new(0,3,0)})
    activeTween:Play()
end

-- ── auto farm loop ──────────────────────────────────────────────
AutoFarmLoop = function()
    local pTimer=tick(); local onPause=false
    while autoFarmActive do
        if not onPause and tick()-pTimer>=3 then
            onPause=true; StopTween()
            local hrp=GetHRP(); if hrp then hrp.Anchored=true end
            task.wait(3)
            local hrp2=GetHRP(); if hrp2 then hrp2.Anchored=false end
            onPause=false; pTimer=tick(); continue
        end
        local hrp=GetHRP(); local hum=GetHum()
        if not hrp or not hum or hum.Health<=0 then StopTween(); task.wait(0.5); continue end
        if IsInLobby(hrp.Position) then
            local tpPos=GetLobbyTP()
            if tpPos then
                if (hrp.Position-tpPos).Magnitude>5 then
                    StartTween(function() return tpPos end,nil); task.wait(0.2)
                else
                    StopTween(); task.wait(3); pTimer=tick()
                end
            else StopTween(); task.wait(0.2) end
            continue
        end
        local target=GetTarget()
        if target and target.Character then
            local tHRP=target.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                StartTween(
                    function()
                        local t=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                        return t and (t.Position+Vector3.new(0,-SS.farmDistance,0)) or nil
                    end,
                    function()
                        local t=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                        return t and t.Position or nil
                    end
                )
                local t0=tick()
                while autoFarmActive and tick()-t0<0.5 do Click(); task.wait(0.05) end
                continue
            end
        end
        StopTween(); Click(); task.wait(0.1)
    end
    StopTween(); UpdateHUD()
end

-- ════════════════════════════════════════════════════════════════
-- UI HELPERS — sistema de cards bonitos para o ScrollContent
-- ════════════════════════════════════════════════════════════════

-- Separador decorativo
local function Divider(color)
    local f=Instance.new("Frame",SC)
    f.Size=UDim2.new(1,0,0,1); f.BackgroundColor3=color or C.sep
    f.BackgroundTransparency=0.3; return f
end

-- Título de seção com linha lateral colorida
local function SecHeader(text,color)
    local wrap=Instance.new("Frame",SC)
    wrap.Size=UDim2.new(1,0,0,30); wrap.BackgroundTransparency=1

    local bar=Instance.new("Frame",wrap)
    bar.Size=UDim2.fromOffset(3,22); bar.Position=UDim2.new(0,0,0.5,-11)
    bar.BackgroundColor3=color or C.acc; Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)

    local lbl=Instance.new("TextLabel",wrap)
    lbl.Size=UDim2.new(1,-12,1,0); lbl.Position=UDim2.fromOffset(10,0)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13
    lbl.TextColor3=color or C.acc; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=text
    return wrap
end

-- Texto pequeno de dica
local function Hint(text)
    local l=Instance.new("TextLabel",SC)
    l.Size=UDim2.new(1,0,0,16); l.BackgroundTransparency=1
    l.Font=Enum.Font.Gotham; l.TextSize=11; l.TextColor3=C.muted
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true
    l.Text="  "..text; return l
end

-- Título da tab
local function TabTitle(text,color)
    local f=Instance.new("Frame",SC)
    f.Size=UDim2.new(1,0,0,48); f.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",f)
    lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=22
    lbl.TextColor3=color or C.white; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=text
    -- linha embaixo
    local ln=Instance.new("Frame",f); ln.Size=UDim2.new(1,0,0,2)
    ln.Position=UDim2.new(0,0,1,-2); ln.BackgroundColor3=color or C.acc
    ln.BackgroundTransparency=0.6; Instance.new("UICorner",ln).CornerRadius=UDim.new(1,0)
    return f
end

-- Botão de ação (card completo)
local function ActBtn(text,color,cb)
    local btn=Instance.new("TextButton",SC)
    btn.Size=UDim2.new(1,0,0,40)
    btn.BackgroundColor3=color; btn.BackgroundTransparency=0.15
    btn.Font=Enum.Font.GothamBold; btn.TextSize=13
    btn.TextColor3=C.white; btn.AutoButtonColor=false
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    local stroke=Instance.new("UIStroke",btn); stroke.Color=color; stroke.Thickness=1.2; stroke.Transparency=0.6
    -- hover
    btn.MouseEnter:Connect(function()
        TS:Create(btn,TweenInfo.new(0.12),{BackgroundTransparency=0}):Play()
        TS:Create(stroke,TweenInfo.new(0.12),{Transparency=0}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btn,TweenInfo.new(0.12),{BackgroundTransparency=0.15}):Play()
        TS:Create(stroke,TweenInfo.new(0.12),{Transparency=0.6}):Play()
    end)
    btn.MouseButton1Click:Connect(cb)
    btn.Text=text; return btn
end

-- TextBox para input de tecla (bonita, com label e box)
local function KeyBox(labelText, currentKey, slot)
    local card=Instance.new("Frame",SC)
    card.Size=UDim2.new(1,0,0,52); card.BackgroundColor3=C.bg2
    card.BackgroundTransparency=0.2
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
    local cs=Instance.new("UIStroke",card); cs.Color=C.acc; cs.Thickness=1; cs.Transparency=0.7

    local lbl=Instance.new("TextLabel",card)
    lbl.Size=UDim2.new(0.55,0,1,0); lbl.Position=UDim2.fromOffset(12,0)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12
    lbl.TextColor3=C.white; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=labelText

    -- box clicável que mostra a tecla
    local box=Instance.new("TextButton",card)
    box.Size=UDim2.fromOffset(120,30); box.Position=UDim2.new(1,-130,0.5,-15)
    box.BackgroundColor3=C.bg0; box.Font=Enum.Font.GothamBold; box.TextSize=12
    box.TextColor3=C.acc2; box.AutoButtonColor=false
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,6)
    local bs=Instance.new("UIStroke",box); bs.Color=C.acc; bs.Thickness=1.5
    box.Text=currentKey

    -- quando clica, entra em modo captura
    box.MouseButton1Click:Connect(function()
        capturingKey=slot
        box.Text="[ pressione... ]"; box.TextColor3=C.gold
        TS:Create(bs,TweenInfo.new(0.1),{Color=C.gold}):Play()
    end)

    -- atualiza quando a tecla for capturada
    if slot=="farm" then farmKeyLbl=box
    elseif slot=="gui" then guiKeyLbl=box end

    -- hover
    box.MouseEnter:Connect(function() TS:Create(box,TweenInfo.new(0.1),{BackgroundColor3=C.bg2}):Play() end)
    box.MouseLeave:Connect(function() TS:Create(box,TweenInfo.new(0.1),{BackgroundColor3=C.bg0}):Play() end)

    return card
end

-- ── blacklist builder ───────────────────────────────────────────
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
        local danger=HasDangerTool(plr)
        local dangerName=GetDangerToolName(plr)

        local row=Instance.new("Frame",blPanelRef)
        row.Size=UDim2.new(1,0,0,44)
        row.BackgroundColor3=danger and Color3.fromRGB(50,15,15)
                          or blocked and Color3.fromRGB(55,15,15)
                          or C.bg2
        row.BackgroundTransparency=0.25
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
        local rs=Instance.new("UIStroke",row)
        rs.Thickness=1
        rs.Color=danger and C.red
               or blocked and Color3.fromRGB(200,50,50)
               or C.sep

        -- avatar placeholder (quadrado colorido com inicial)
        local av=Instance.new("Frame",row)
        av.Size=UDim2.fromOffset(32,32); av.Position=UDim2.new(0,6,0.5,-16)
        av.BackgroundColor3=danger and C.red or blocked and Color3.fromRGB(200,50,50) or C.acc
        av.BackgroundTransparency=0.5
        Instance.new("UICorner",av).CornerRadius=UDim.new(0,6)
        local avLbl=Instance.new("TextLabel",av)
        avLbl.Size=UDim2.new(1,0,1,0); avLbl.BackgroundTransparency=1
        avLbl.Font=Enum.Font.GothamBold; avLbl.TextSize=14; avLbl.TextColor3=C.white
        avLbl.Text=plr.Name:sub(1,1):upper()

        -- nome + status
        local nameCol=Instance.new("Frame",row)
        nameCol.Size=UDim2.new(1,-150,1,0); nameCol.Position=UDim2.fromOffset(44,0)
        nameCol.BackgroundTransparency=1

        local nameLbl=Instance.new("TextLabel",nameCol)
        nameLbl.Size=UDim2.new(1,0,0.55,0); nameLbl.BackgroundTransparency=1
        nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=13
        nameLbl.TextColor3=C.white; nameLbl.TextXAlignment=Enum.TextXAlignment.Left
        nameLbl.Text=plr.Name

        local statusLbl=Instance.new("TextLabel",nameCol)
        statusLbl.Size=UDim2.new(1,0,0.45,0); statusLbl.Position=UDim2.new(0,0,0.55,0)
        statusLbl.BackgroundTransparency=1; statusLbl.Font=Enum.Font.Gotham; statusLbl.TextSize=10
        statusLbl.TextXAlignment=Enum.TextXAlignment.Left
        if danger then
            statusLbl.Text="PERIGO: "..dangerName; statusLbl.TextColor3=C.red
        elseif blocked then
            statusLbl.Text="ignorado manualmente"; statusLbl.TextColor3=Color3.fromRGB(200,80,80)
        else
            statusLbl.Text="no farm"; statusLbl.TextColor3=C.muted
        end

        if not danger then
            local btn=Instance.new("TextButton",row)
            btn.Size=UDim2.fromOffset(72,26); btn.Position=UDim2.new(1,-80,0.5,-13)
            btn.Font=Enum.Font.GothamBold; btn.TextSize=11
            btn.TextColor3=C.white; btn.AutoButtonColor=false
            Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
            btn.Text=blocked and "Incluir" or "Ignorar"
            btn.BackgroundColor3=blocked and Color3.fromRGB(25,120,40) or Color3.fromRGB(160,25,40)
            local cap=plr.Name
            btn.MouseButton1Click:Connect(function()
                if blacklist[cap] then blacklist[cap]=nil else blacklist[cap]=true end
                RebuildBL()
            end)
        else
            local badge=Instance.new("TextLabel",row)
            badge.Size=UDim2.fromOffset(72,26); badge.Position=UDim2.new(1,-80,0.5,-13)
            badge.BackgroundColor3=Color3.fromRGB(100,10,10); badge.BackgroundTransparency=0.3
            badge.Font=Enum.Font.GothamBold; badge.TextSize=10; badge.TextColor3=C.red
            badge.Text="AUTO-SKIP"; Instance.new("UICorner",badge).CornerRadius=UDim.new(0,6)
        end
    end
    if count==0 then
        local empty=Instance.new("TextLabel",blPanelRef)
        empty.Size=UDim2.new(1,0,0,36); empty.BackgroundTransparency=1
        empty.Font=Enum.Font.Gotham; empty.TextSize=12; empty.TextColor3=C.muted
        empty.Text="  Nenhum player no servidor no momento."; count=1
    end
    blPanelRef.Size=UDim2.new(1,0,0,math.max(count*48,36))
    UCS()
end

-- ── tp list builder ─────────────────────────────────────────────
-- Lista todos os players com botão de tween TP
RebuildTPList = function()
    if not tpListRef or not tpListRef.Parent then return end
    for _,v in pairs(tpListRef:GetChildren()) do
        if not v:IsA("UIListLayout") then v:Destroy() end
    end
    local count=0
    for _,plr in ipairs(PLS:GetPlayers()) do
        if plr==Player then continue end
        count+=1

        local row=Instance.new("Frame",tpListRef)
        row.Size=UDim2.new(1,0,0,44); row.BackgroundColor3=C.bg2
        row.BackgroundTransparency=0.25
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
        Instance.new("UIStroke",row).Color=C.sep

        -- inicial
        local av=Instance.new("Frame",row)
        av.Size=UDim2.fromOffset(32,32); av.Position=UDim2.new(0,6,0.5,-16)
        av.BackgroundColor3=C.cyan; av.BackgroundTransparency=0.5
        Instance.new("UICorner",av).CornerRadius=UDim.new(0,6)
        local avL=Instance.new("TextLabel",av); avL.Size=UDim2.new(1,0,1,0)
        avL.BackgroundTransparency=1; avL.Font=Enum.Font.GothamBold; avL.TextSize=14
        avL.TextColor3=C.white; avL.Text=plr.Name:sub(1,1):upper()

        local nLbl=Instance.new("TextLabel",row)
        nLbl.Size=UDim2.new(1,-160,1,0); nLbl.Position=UDim2.fromOffset(44,0)
        nLbl.BackgroundTransparency=1; nLbl.Font=Enum.Font.GothamBold; nLbl.TextSize=13
        nLbl.TextColor3=C.white; nLbl.TextXAlignment=Enum.TextXAlignment.Left
        nLbl.Text=plr.Name

        -- botão tween tp
        local tpBtn=Instance.new("TextButton",row)
        tpBtn.Size=UDim2.fromOffset(90,28); tpBtn.Position=UDim2.new(1,-98,0.5,-14)
        tpBtn.Font=Enum.Font.GothamBold; tpBtn.TextSize=11
        tpBtn.TextColor3=C.white; tpBtn.AutoButtonColor=false
        Instance.new("UICorner",tpBtn).CornerRadius=UDim.new(0,6)
        tpBtn.BackgroundColor3=C.cyan; tpBtn.BackgroundTransparency=0.25
        Instance.new("UIStroke",tpBtn).Color=C.cyan
        tpBtn.Text="Tween TP"
        tpBtn.MouseEnter:Connect(function() TS:Create(tpBtn,TweenInfo.new(0.1),{BackgroundTransparency=0}):Play() end)
        tpBtn.MouseLeave:Connect(function() TS:Create(tpBtn,TweenInfo.new(0.1),{BackgroundTransparency=0.25}):Play() end)
        local cap=plr.Name
        tpBtn.MouseButton1Click:Connect(function()
            local p=PLS:FindFirstChild(cap)
            if p then
                tpBtn.Text="indo..."; tpBtn.BackgroundColor3=C.gold
                task.spawn(function()
                    TweenToPlayer(p)
                    task.wait(2); tpBtn.Text="Tween TP"; tpBtn.BackgroundColor3=C.cyan
                end)
            end
        end)
    end
    if count==0 then
        local empty=Instance.new("TextLabel",tpListRef)
        empty.Size=UDim2.new(1,0,0,36); empty.BackgroundTransparency=1
        empty.Font=Enum.Font.Gotham; empty.TextSize=12; empty.TextColor3=C.muted
        empty.Text="  Nenhum player para teleportar."; count=1
    end
    tpListRef.Size=UDim2.new(1,0,0,math.max(count*48,36))
    UCS()
end

PLS.PlayerAdded:Connect(function() task.wait(0.5); RebuildBL(); RebuildTPList() end)
PLS.PlayerRemoving:Connect(function(plr)
    blacklist[plr.Name]=nil; RebuildBL(); RebuildTPList()
end)

-- ════════════════════════════════════════════════════════════════
-- TAB: FARM
-- ════════════════════════════════════════════════════════════════
local function LoadFarm()
    Clear(); blPanelRef=nil

    TabTitle("Farm",C.gold)

    -- hotkeys
    SecHeader("Teclas de Atalho",C.acc2)
    Hint("Clique na caixa da tecla e pressione a tecla desejada.")

    KeyBox("Toggle Auto Farm", SS.keyFarm, "farm")
    KeyBox("Mostrar/Esconder GUI", SS.keyGUI, "gui")

    Divider()

    -- auto farm
    SecHeader("Auto Farm",C.gold)
    Hint("Persegue e clica automaticamente. Detecta Lobby e vai ao Teleport1.")
    Hint("Ignora players com Overkill, Error ou The Flex automaticamente.")

    Checkbox("Ativar Auto Farm",SS.autoFarm,function(v)
        SS.autoFarm=v; autoFarmActive=v
        if v then task.spawn(AutoFarmLoop) end
        UpdateHUD()
    end)
    Slider("Velocidade do Tween",5,100,SS.farmSpeed,function(v) SS.farmSpeed=v end)
    Slider("Distancia do alvo (Y)",1,50,SS.farmDistance,function(v) SS.farmDistance=v end)
    Slider("Alcance do Farm (studs)",10,500,SS.farmRange,function(v) SS.farmRange=v end)

    Divider()

    -- blacklist
    SecHeader("Ignorar Players",C.red)
    Hint("Players com tools perigosas são marcados como AUTO-SKIP automaticamente.")
    Hint("Use o botao Ignorar para excluir outros players manualmente.")

    local blPanel=Instance.new("Frame",SC)
    blPanel.Size=UDim2.new(1,0,0,44); blPanel.BackgroundTransparency=1
    local bll=Instance.new("UIListLayout",blPanel)
    bll.Padding=UDim.new(0,6); bll.SortOrder=Enum.SortOrder.LayoutOrder
    blPanelRef=blPanel; RebuildBL()

    Divider()

    -- hitbox
    SecHeader("Hitbox Expander",C.orange)
    local hLoaded=false
    local hBtn=ActBtn("Carregar Hitbox Expander",C.orange,function() end)
    hBtn.MouseButton1Click:Connect(function()
        if hLoaded then return end; hLoaded=true
        hBtn.Text="Carregando..."; hBtn.BackgroundColor3=C.muted
        task.spawn(function()
            pcall(function()
                loadstring(game:HttpGet(
                    "https://gist.githubusercontent.com/stellar-4242/430ef3087d8d87eb306ca03e728ffbb8/raw/798429dd908b1f4471a1fa569ff62c5e5a93ec61/SLAP.LUA"
                ))()
            end)
            hBtn.Text="Hitbox Carregado!"; hBtn.BackgroundColor3=C.green
        end)
    end)

    Divider()

    -- kill aura
    SecHeader("Kill Aura",C.red)
    Checkbox("Ativar Kill Aura",SS.auraEnabled,function(v) SS.auraEnabled=v; auraActive=v end)
    Slider("Aura Range (studs)",5,100,SS.auraSize,function(v) SS.auraSize=v end)

    Divider()

    -- fling
    SecHeader("Fling",C.orange)
    Checkbox("Ativar Fling",SS.flingEnabled,function(v) SS.flingEnabled=v; flingActive=v end)
    Slider("Fling Power",100,2000,SS.flingPower,function(v) SS.flingPower=v end)

    UCS()
end

-- ════════════════════════════════════════════════════════════════
-- TAB: TELE — tween TP para qualquer player
-- ════════════════════════════════════════════════════════════════
local function LoadTele()
    Clear(); tpListRef=nil

    TabTitle("Teleporte",C.cyan)

    SecHeader("Tween até Player",C.cyan)
    Hint("Clique em Tween TP para se mover suavemente até o player.")
    Hint("A velocidade usa o mesmo slider do Farm.")

    ActBtn("Atualizar lista",C.acc,function() RebuildTPList() end)

    local tpPanel=Instance.new("Frame",SC)
    tpPanel.Size=UDim2.new(1,0,0,44); tpPanel.BackgroundTransparency=1
    local tpl=Instance.new("UIListLayout",tpPanel)
    tpl.Padding=UDim.new(0,6); tpl.SortOrder=Enum.SortOrder.LayoutOrder
    tpListRef=tpPanel; RebuildTPList()

    Divider()

    SecHeader("Safe Zone",C.green)
    Hint("Plataforma invisivel em Y=500, Z=99999. Ninguem te alcanca la.")
    ActBtn("TP para Safe Zone",C.green,TpSafe)

    UCS()
end

-- ════════════════════════════════════════════════════════════════
-- TAB: ESP
-- ════════════════════════════════════════════════════════════════
local function LoadESP()
    Clear()
    TabTitle("ESP",C.cyan)
    SecHeader("Configuracoes",C.cyan)
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
    TabTitle("Misc",C.muted)

    SecHeader("Anti Knockback",C.green)
    Checkbox("Anti Knockback",SS.antiKnockback,function(v) SS.antiKnockback=v; antiKnockActive=v end)

    Divider()

    SecHeader("Auto Respawn",C.gold)
    Checkbox("Auto Respawn (ao morrer)",SS.autoRespawn,function(v) SS.autoRespawn=v; autoRespawnActive=v end)

    Divider()

    SecHeader("Click TP",C.gold)
    Hint("Clique no chao para teleportar ate aquele ponto.")
    Checkbox("Click TP",SS.clickTpEnabled,function(v)
        SS.clickTpEnabled=v; clickTpActive=v
        if v then EnableClickTP() else DisableClickTP() end
    end)

    Divider()

    SecHeader("Anti Void",C.cyan)
    Hint("Part gigante no nivel da Grass do Arena. Impede cair no void.")
    ActBtn("Recriar Anti Void",C.cyan,function()
        CreateAntiVoid()
    end)

    UCS()
end

-- ── registrar tabs ──────────────────────────────────────────────
Tab("Farm",   "Farm",  0, LoadFarm)
Tab("Tele",   "Tele",  0, LoadTele)
Tab("ESP",    "ESP",   0, LoadESP)
Tab("Misc",   "Misc",  0, LoadMisc)

print("[N3on·Slap] v4 carregado!")
