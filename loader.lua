-- BigodeScripts Loader Protegido

if getgenv().BigodeLoader then
    warn("[BigodeScripts] Loader já executado!")
    return
end
getgenv().BigodeLoader = true

-- Aguarda o jogo carregar
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Configurações do loader
local CONFIG = {
    Name = "BigodeScripts",
    Version = "2.5",
    AllowedPlaces = { 
        -- coloque PlaceIds aqui se quiser travar
        -- exemplo: 123456789
    },
    MainScript = "https://raw.githubusercontent.com/PMQUIMICO/BigodeScripts/main/main.lua"
}

-- Verificar PlaceId (opcional)
if #CONFIG.AllowedPlaces > 0 then
    local allowed = false
    for _, id in ipairs(CONFIG.AllowedPlaces) do
        if game.PlaceId == id then
            allowed = true
            break
        end
    end
    if not allowed then
        return warn("[BigodeScripts] Jogo não autorizado!")
    end
end

-- Banner
print("===================================")
print(CONFIG.Name .. " Loader")
print("Versão: " .. CONFIG.Version)
print("Carregando script principal...")
print("===================================")

-- Carregar script principal
local success, err = pcall(function()
    loadstring(game:HttpGet(CONFIG.MainScript))()
end)

if success then
    print("[BigodeScripts] Script carregado com sucesso!")
else
    warn("[BigodeScripts] Erro ao carregar script:")
    warn(err)
end
