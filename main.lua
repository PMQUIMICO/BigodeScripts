-- BigodeScripts - Aimbot V2 + ESP
-- Versão Simplificada
-- Modificado por: BigodeScripts

--// Configurações Iniciais
if getgenv().BigodeScripts then 
    warn("[BigodeScripts] Script já está carregado!")
    return 
end

getgenv().BigodeScripts = true
getgenv().BigodeScriptsVersion = "2.5"

--// Serviços
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Verificar se Drawing está disponível
local DrawingLib = (drawing or Drawing)
if not DrawingLib then
    warn("[BigodeScripts] Drawing não está disponível!")
    return
end

--// Cores Roxas Personalizadas
local PurpleTheme = {
    Primary = Color3.fromRGB(170, 0, 255),     -- Roxo principal
    Secondary = Color3.fromRGB(130, 0, 200),   -- Roxo secundário
    Light = Color3.fromRGB(200, 100, 255),     -- Roxo claro
    Dark = Color3.fromRGB(100, 0, 150),        -- Roxo escuro
    Accent = Color3.fromRGB(255, 50, 200),     -- Rosa para destaques
    Team = Color3.fromRGB(100, 50, 255),       -- Roxo azulado para aliados
    Enemy = Color3.fromRGB(200, 0, 255)        -- Roxo vivo para inimigos
}

--// Carregar Aimbot
local aimbotSuccess, aimbotError = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/Aimbot-V2/main/Resources/Scripts/Raw%20Main.lua"))()
end)

if aimbotSuccess then
    print("[BigodeScripts] Aimbot carregado com sucesso!")
    
    -- Aplicar tema roxo no FOV do aimbot
    local Aimbot = getgenv().Aimbot
    if Aimbot then
        Aimbot.FOVSettings.Color = PurpleTheme.Primary
        Aimbot.FOVSettings.LockedColor = PurpleTheme.Enemy
        print("[BigodeScripts] Tema roxo aplicado ao Aimbot!")
    end
else
    warn("[BigodeScripts] Erro ao carregar Aimbot: " .. tostring(aimbotError))
    print("[BigodeScripts] Continuando apenas com ESP...")
end

--// Configurações do ESP com tema roxo
local ESPConfig = {
    Enabled = true,
    Boxes = true,
    BoxColor = PurpleTheme.Light,           -- Roxo claro para aliados
    BoxColorEnemy = PurpleTheme.Enemy,      -- Roxo vivo para inimigos
    BoxColorTeam = PurpleTheme.Team,        -- Roxo azulado para time
    Names = true,
    Health = true,
    Distance = true,
    Tracers = false,
    MaxDistance = 1000,
    TeamCheck = true,
    HealthBar = true,
    Outline = true,
    Font = 2, -- 1=UI, 2=System, 3=Plex, 4=Monospace
    TextSize = 13,
    TextOutline = true,
    
    -- Novas cores personalizadas
    NameColor = PurpleTheme.Light,
    HealthColor = Color3.fromRGB(255, 50, 255),  -- Rosa para vida
    DistanceColor = PurpleTheme.Secondary,
    TracerColor = PurpleTheme.Primary,
    
    -- Atalhos
    ToggleKey = Enum.KeyCode.F1,
    TracersKey = Enum.KeyCode.F2,
    BoxesKey = Enum.KeyCode.F3,
    NamesKey = Enum.KeyCode.F4,
    HealthKey = Enum.KeyCode.F5
}

--// Sistema de ESP
local ESP = {
    Players = {},
    Drawings = {},
    Connections = {},
    Enabled = ESPConfig.Enabled
}

--// Funções de Utilidade
local function IsTeamMate(player)
    if not ESPConfig.TeamCheck or not LocalPlayer.Team then
        return false
    end
    return player.Team == LocalPlayer.Team
end

local function IsVisible(part)
    local origin = Camera.CFrame.Position
    local target = part.Position
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    
    local raycastResult = Workspace:Raycast(origin, target - origin, raycastParams)
    
    if raycastResult then
        return raycastResult.Instance:IsDescendantOf(part.Parent)
    end
    
    return true
end

--// Funções do ESP
function ESP:Init()
    self.Drawings = {}
    
    -- Conectar evento para novos jogadores
    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        self:AddPlayer(player)
    end)
    
    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayer(player)
    end)
    
    -- Adicionar jogadores existentes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:AddPlayer(player)
        end
    end
    
    -- Loop de renderização
    self.Connections.RenderStep = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        
        for player, drawings in pairs(self.Drawings) do
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local character = player.Character
                local rootPart = character.HumanoidRootPart
                
                -- Calcular posição na tela
                local position, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
                
                if onScreen and distance <= ESPConfig.MaxDistance then
                    local teamMate = IsTeamMate(player)
                    local visible = IsVisible(rootPart)
                    local boxColor = teamMate and ESPConfig.BoxColorTeam or ESPConfig.BoxColorEnemy
                    
                    if not visible then
                        boxColor = Color3.fromRGB(150, 100, 200) -- Roxo desbotado se não visível
                    end
                    
                    -- Atualizar box
                    if drawings.Box and ESPConfig.Boxes then
                        local scale = 2000 / distance
                        local size = Vector2.new(scale * 2, scale * 3)
                        
                        drawings.Box.Visible = true
                        drawings.Box.Color = boxColor
                        drawings.Box.Size = size
                        drawings.Box.Position = Vector2.new(position.X - size.X / 2, position.Y - size.Y / 2)
                        drawings.Box.Transparency = 0.3
                        drawings.Box.Filled = false
                        drawings.Box.Thickness = 2
                        
                        -- Adicionar outline roxo
                        if drawings.BoxOutline then
                            drawings.BoxOutline.Visible = true
                            drawings.BoxOutline.Color = PurpleTheme.Primary
                            drawings.BoxOutline.Size = Vector2.new(size.X + 4, size.Y + 4)
                            drawings.BoxOutline.Position = Vector2.new(position.X - (size.X + 4) / 2, position.Y - (size.Y + 4) / 2)
                            drawings.BoxOutline.Transparency = 0.7
                            drawings.BoxOutline.Thickness = 1
                        end
                    else
                        if drawings.Box then drawings.Box.Visible = false end
                        if drawings.BoxOutline then drawings.BoxOutline.Visible = false end
                    end
                    
                    -- Atualizar nome
                    if drawings.Name and ESPConfig.Names then
                        drawings.Name.Visible = true
                        drawings.Name.Text = player.Name
                        drawings.Name.Color = ESPConfig.NameColor
                        drawings.Name.Position = Vector2.new(position.X, position.Y - (2000 / distance * 3) / 2 - 20)
                        drawings.Name.Size = ESPConfig.TextSize
                        drawings.Name.Center = true
                        drawings.Name.Outline = ESPConfig.TextOutline
                    else
                        if drawings.Name then drawings.Name.Visible = false end
                    end
                    
                    -- Atualizar health
                    if drawings.Health and ESPConfig.Health then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local healthPercent = humanoid.Health / humanoid.MaxHealth
                            
                            drawings.Health.Visible = true
                            drawings.Health.Text = tostring(math.floor(humanoid.Health)) .. " HP"
                            drawings.Health.Color = ESPConfig.HealthColor
                            drawings.Health.Position = Vector2.new(position.X, position.Y + (2000 / distance * 3) / 2 + 5)
                            drawings.Health.Size = ESPConfig.TextSize
                            drawings.Health.Center = true
                            drawings.Health.Outline = ESPConfig.TextOutline
                        end
                    else
                        if drawings.Health then drawings.Health.Visible = false end
                    end
                    
                    -- Atualizar distance
                    if drawings.Distance and ESPConfig.Distance then
                        drawings.Distance.Visible = true
                        drawings.Distance.Text = tostring(math.floor(distance)) .. " studs"
                        drawings.Distance.Color = ESPConfig.DistanceColor
                        drawings.Distance.Position = Vector2.new(position.X, position.Y + (2000 / distance * 3) / 2 + 25)
                        drawings.Distance.Size = ESPConfig.TextSize - 2
                        drawings.Distance.Center = true
                        drawings.Distance.Outline = ESPConfig.TextOutline
                    else
                        if drawings.Distance then drawings.Distance.Visible = false end
                    end
                    
                    -- Atualizar tracer
                    if drawings.Tracer and ESPConfig.Tracers then
                        drawings.Tracer.Visible = true
                        drawings.Tracer.Color = ESPConfig.TracerColor
                        drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        drawings.Tracer.To = Vector2.new(position.X, position.Y)
                        drawings.Tracer.Thickness = 2
                    else
                        if drawings.Tracer then drawings.Tracer.Visible = false end
                    end
                    
                    -- Atualizar health bar
                    if drawings.HealthBar and ESPConfig.HealthBar then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            local healthPercent = humanoid.Health / humanoid.MaxHealth
                            local barHeight = (2000 / distance * 3) * healthPercent
                            
                            drawings.HealthBar.Visible = true
                            drawings.HealthBar.Color = Color3.fromRGB(
                                255 * (1 - healthPercent) + 100,
                                50,
                                255 * healthPercent + 100
                            )
                            drawings.HealthBar.Size = Vector2.new(4, (2000 / distance * 3))
                            drawings.HealthBar.Position = Vector2.new(
                                position.X - (2000 / distance * 2) / 2 - 10,
                                position.Y - (2000 / distance * 3) / 2 + (2000 / distance * 3) * (1 - healthPercent)
                            )
                            drawings.HealthBar.Filled = true
                            drawings.HealthBar.Transparency = 0.8
                        end
                    else
                        if drawings.HealthBar then drawings.HealthBar.Visible = false end
                    end
                else
                    -- Esconder tudo se não estiver na tela
                    for _, drawing in pairs(drawings) do
                        if drawing then drawing.Visible = false end
                    end
                end
            else
                -- Esconder se o jogador não tiver character
                for _, drawing in pairs(drawings) do
                    if drawing then drawing.Visible = false end
                end
            end
        end
    end)
end

function ESP:AddPlayer(player)
    if self.Drawings[player] then return end
    
    self.Drawings[player] = {
        Box = DrawingLib.new("Square"),
        BoxOutline = DrawingLib.new("Square"),
        Name = DrawingLib.new("Text"),
        Health = DrawingLib.new("Text"),
        Distance = DrawingLib.new("Text"),
        Tracer = DrawingLib.new("Line"),
        HealthBar = DrawingLib.new("Square")
    }
    
    -- Configurar box
    self.Drawings[player].Box.Visible = false
    self.Drawings[player].Box.Thickness = 2
    self.Drawings[player].Box.Filled = false
    
    -- Configurar outline da box
    self.Drawings[player].BoxOutline.Visible = false
    self.Drawings[player].BoxOutline.Thickness = 1
    self.Drawings[player].BoxOutline.Filled = false
    
    -- Configurar textos
    for _, text in pairs({"Name", "Health", "Distance"}) do
        if self.Drawings[player][text] then
            self.Drawings[player][text].Visible = false
            self.Drawings[player][text].Center = true
            self.Drawings[player][text].Outline = true
            self.Drawings[player][text].Font = ESPConfig.Font
        end
    end
    
    -- Configurar tracer
    self.Drawings[player].Tracer.Visible = false
    self.Drawings[player].Tracer.Thickness = 2
    
    -- Configurar health bar
    self.Drawings[player].HealthBar.Visible = false
    self.Drawings[player].HealthBar.Filled = true
    self.Drawings[player].HealthBar.Transparency = 0.8
end

function ESP:RemovePlayer(player)
    if self.Drawings[player] then
        for _, drawing in pairs(self.Drawings[player]) do
            if drawing then
                drawing:Remove()
            end
        end
        self.Drawings[player] = nil
    end
end

function ESP:Toggle(state)
    self.Enabled = state
    for player, drawings in pairs(self.Drawings) do
        for _, drawing in pairs(drawings) do
            if drawing then
                drawing.Visible = state
            end
        end
    end
end

function ESP:Destroy()
    for _, connection in pairs(self.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    for player, drawings in pairs(self.Drawings) do
        for _, drawing in pairs(drawings) do
            if drawing then
                drawing:Remove()
            end
        end
    end
    
    self.Drawings = {}
    self.Connections = {}
end

--// Atalhos de Teclado
local function SetupKeybinds()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        -- F1: Ativar/Desativar ESP
        if input.KeyCode == ESPConfig.ToggleKey then
            ESPConfig.Enabled = not ESPConfig.Enabled
            ESP:Toggle(ESPConfig.Enabled)
            print("[BigodeScripts] ESP: " .. (ESPConfig.Enabled and "ATIVADO" or "DESATIVADO"))
        
        -- F2: Ativar/Desativar Tracers
        elseif input.KeyCode == ESPConfig.TracersKey then
            ESPConfig.Tracers = not ESPConfig.Tracers
            print("[BigodeScripts] Tracers: " .. (ESPConfig.Tracers and "ATIVADO" or "DESATIVADO"))
        
        -- F3: Ativar/Desativar Boxes
        elseif input.KeyCode == ESPConfig.BoxesKey then
            ESPConfig.Boxes = not ESPConfig.Boxes
            print("[BigodeScripts] Boxes: " .. (ESPConfig.Boxes and "ATIVADO" or "DESATIVADO"))
        
        -- F4: Ativar/Desativar Nomes
        elseif input.KeyCode == ESPConfig.NamesKey then
            ESPConfig.Names = not ESPConfig.Names
            print("[BigodeScripts] Nomes: " .. (ESPConfig.Names and "ATIVADO" or "DESATIVADO"))
        
        -- F5: Ativar/Desativar Health
        elseif input.KeyCode == ESPConfig.HealthKey then
            ESPConfig.Health = not ESPConfig.Health
            print("[BigodeScripts] Vida: " .. (ESPConfig.Health and "ATIVADO" or "DESATIVADO"))
        end
    end)
end

--// Sistema de Notificações Simples
local Notifications = {
    Active = {},
    MaxNotifications = 3
}

function Notifications:Add(text, duration)
    duration = duration or 3
    
    local notification = DrawingLib.new("Text")
    notification.Visible = true
    notification.Text = "• " .. text
    notification.Color = PurpleTheme.Light
    notification.Size = 16
    notification.Font = 2
    notification.Outline = true
    notification.Center = true
    notification.Position = Vector2.new(Camera.ViewportSize.X / 2, 100 + (#self.Active * 30))
    
    table.insert(self.Active, {
        Drawing = notification,
        Time = tick(),
        Duration = duration,
        Position = #self.Active + 1
    })
    
    spawn(function()
        wait(duration)
        notification:Remove()
        for i, v in ipairs(self.Active) do
            if v.Drawing == notification then
                table.remove(self.Active, i)
                break
            end
        end
        self:UpdatePositions()
    end)
end

function Notifications:UpdatePositions()
    for i, notification in ipairs(self.Active) do
        notification.Drawing.Position = Vector2.new(Camera.ViewportSize.X / 2, 100 + ((i - 1) * 30))
    end
end

--// Inicialização
print("\n" .. string.rep("=", 50))
print("BigodeScripts - Aimbot V2 + ESP")
print("Versão: " .. getgenv().BigodeScriptsVersion)
print("Aimbot: Exunys API")
print("ESP: Personalizado (Tema Roxo)")
print(string.rep("=", 50))
print("Atalhos:")
print("F1: Ativar/Desativar ESP")
print("F2: Ativar/Desativar Tracers")
print("F3: Ativar/Desativar Boxes")
print("F4: Ativar/Desativar Nomes")
print("F5: Ativar/Desativar Vida")
print(string.rep("=", 50) .. "\n")

-- Inicializar ESP
ESP:Init()

-- Configurar atalhos
SetupKeybinds()

-- Ativar ESP
ESP:Toggle(ESPConfig.Enabled)

-- Adicionar notificação inicial
if DrawingLib then
    Notifications:Add("BigodeScripts Inicializado!", 3)
    Notifications:Add("ESP ATIVADO (F1)", 3)
    Notifications:Add("Tema Roxo Aplicado", 3)
end

print("[BigodeScripts] Script inicializado com sucesso!")
print("[BigodeScripts] ESP está ATIVADO com tema roxo")
print("[BigodeScripts] Use F1-F5 para controlar o ESP")

-- Limpeza quando o script for desativado
local function Cleanup()
    ESP:Destroy()
    getgenv().BigodeScripts = false
    print("[BigodeScripts] Script desativado!")
end

-- Conectar para limpeza quando o jogo fechar
game:BindToClose(Cleanup)

-- Função para desativar manualmente (útil para debugging)
getgenv().DisableBigodeScripts = Cleanup

-- Função para recarregar o ESP
getgenv().ReloadBigodeScripts = function()
    Cleanup()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/seu-usuario/BigodeScripts/main/main.lua"))()
end
