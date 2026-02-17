--   Design: deep-space dark · neon accent · card-based layout
-- ╚══════════════════════════════════════════════════════════════╝

local tries = 0
repeat task.wait(0.5); tries += 1 until (_G.N3onHub and _G.N3onHub._loaded) or tries >= 20
if not (_G.N3onHub and _G.N3onHub._loaded) then
    warn("[N3on·Slap] Base Hub nao carregado!"); return
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
