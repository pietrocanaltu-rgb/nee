-- N3on Hub - Loader Principal
-- Detecta o jogo e carrega os módulos apropriados

print("[N3on Hub Loader] Starting...")

-- SEUS LINKS AQUI (substitua pelo seu GitHub)
local BASE_URL = "https://raw.githubusercontent.com/SEU_USER/n3on-hub/main/"
local LINKS = {
	base = BASE_URL .. "n3on_hub_base.lua",
	bloxfruits = BASE_URL .. "n3on_hub_bloxfruits.lua",
	buildaboat = BASE_URL .. "n3on_hub_buildaboat.lua"
}

-- Detectar qual jogo está sendo executado
local gameId = game.PlaceId
local gameName = ""
local moduleUrl = ""

-- IDs dos jogos
local GAMES = {
	BUILD_A_BOAT = {537413528},
	BLOX_FRUITS = {2753915549, 4442272183, 7449423635}
}

-- Detecta o jogo
local function detectGame()
	for _, id in ipairs(GAMES.BUILD_A_BOAT) do
		if gameId == id then
			return "Build a boat for treasure", "buildaboat"
		end
	end
	
	for _, id in ipairs(GAMES.BLOX_FRUITS) do
		if gameId == id then
			return "Blox Fruits", "bloxfruits"
		end
	end
	
	return "Universal", nil
end

gameName, moduleUrl = detectGame()

print("[N3on Hub Loader] Detected game: " .. gameName)
print("[N3on Hub Loader] Game ID: " .. gameId)

-- Carrega o hub base primeiro
print("[N3on Hub Loader] Loading base hub...")

if not _G.N3onHub then
	local success, err = pcall(function()
		loadstring(game:HttpGet(LINKS.base))()
	end)
	
	if not success then
		error("[N3on Hub Loader] Failed to load base: " .. tostring(err))
		return
	end
	
	-- Espera o base carregar
	local timeout = 0
	while not _G.N3onHub and timeout < 50 do
		task.wait(0.1)
		timeout = timeout + 1
	end
	
	if not _G.N3onHub then
		error("[N3on Hub Loader] Failed to load base hub!")
		return
	end
end

print("[N3on Hub Loader] Base hub loaded!")

-- Carrega o módulo específico do jogo (se existir)
if moduleUrl == "buildaboat" then
	print("[N3on Hub Loader] Loading Build a Boat module...")
	local success, err = pcall(function()
		loadstring(game:HttpGet(LINKS.buildaboat))()
	end)
	
	if success then
		print("[N3on Hub Loader] Build a Boat module loaded!")
	else
		warn("[N3on Hub Loader] Failed to load Build a Boat module: " .. tostring(err))
	end
	
elseif moduleUrl == "bloxfruits" then
	print("[N3on Hub Loader] Loading Blox Fruits module...")
	local success, err = pcall(function()
		loadstring(game:HttpGet(LINKS.bloxfruits))()
	end)
	
	if success then
		print("[N3on Hub Loader] Blox Fruits module loaded!")
	else
		warn("[N3on Hub Loader] Failed to load Blox Fruits module: " .. tostring(err))
	end
	
else
	print("[N3on Hub Loader] No specific module for this game. Using universal features only.")
end

print("[N3on Hub Loader] ✅ All systems loaded successfully!")
print("[N3on Hub Loader] Welcome to N3on Hub for " .. gameName .. "!")
