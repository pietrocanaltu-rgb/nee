-- N3on Hub - Loader Principal
-- Detecta o jogo e carrega os módulos

warn("[N3on Hub Loader] Iniciando...")

-- SEUS LINKS RAW DO GITHUB AQUI
local LINKS = {
	base = "COLE_O_LINK_RAW_DO_n3on_hub_base.lua_AQUI",
	bloxfruits = "COLE_O_LINK_RAW_DO_n3on_hub_bloxfruits.lua_AQUI",
}

-- IDs dos jogos
local GAMES = {
	BLOX_FRUITS = {2753915549, 4442272183, 7449423635}
}

-- Detecta o jogo
local gameId = game.PlaceId
local gameName = "Desconhecido"
local moduleUrl = nil

for _, id in ipairs(GAMES.BLOX_FRUITS) do
	if gameId == id then
		gameName = "Blox Fruits"
		moduleUrl = "bloxfruits"
		break
	end
end

warn("[N3on Hub Loader] Jogo detectado: " .. gameName)
warn("[N3on Hub Loader] Game ID: " .. gameId)

-- Carrega o HUB BASE
warn("[N3on Hub Loader] Carregando base...")

local success, err = pcall(function()
	loadstring(game:HttpGet(LINKS.base))()
end)

if not success then
	error("[N3on Hub Loader] ERRO ao carregar base: " .. tostring(err))
	return
end

-- Aguarda o base carregar
local timeout = 0
while not _G.N3onHub and timeout < 50 do
	task.wait(0.1)
	timeout = timeout + 1
end

if not _G.N3onHub then
	error("[N3on Hub Loader] Base não carregou!")
	return
end

warn("[N3on Hub Loader] Base carregada com sucesso!")

-- Carrega o módulo específico do jogo
if moduleUrl == "bloxfruits" then
	warn("[N3on Hub Loader] Carregando módulo Blox Fruits...")
	
	local success, err = pcall(function()
		loadstring(game:HttpGet(LINKS.bloxfruits))()
	end)
	
	if success then
		warn("[N3on Hub Loader] Módulo Blox Fruits carregado!")
	else
		warn("[N3on Hub Loader] ERRO ao carregar módulo: " .. tostring(err))
	end
else
	warn("[N3on Hub Loader] Nenhum módulo específico para este jogo.")
	warn("[N3on Hub Loader] Usando apenas funcionalidades universais.")
end

warn("[N3on Hub Loader] ✅ Tudo carregado com sucesso!")
warn("[N3on Hub Loader] Bem-vindo ao N3on Hub!")
