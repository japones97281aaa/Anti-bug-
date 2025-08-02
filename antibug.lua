-- Anti-Exploit Protection Script (Versão Agressiva)
-- Use como LocalScript em StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Desabilitar completamente o RemoteEvent problemático
local function disableExploitRemote()
    local remote = ReplicatedStorage:WaitForChild("RE", 5)
    if remote then
        local targetRemote = remote:FindFirstChild("1Gu1n")
        if targetRemote then
            -- Método 1: Substituir a função FireServer
            local originalFire = targetRemote.FireServer
            targetRemote.FireServer = function(self, ...)
                local args = {...}
                
                -- Verificar se está tentando afetar o jogador local
                for i, arg in pairs(args) do
                    if typeof(arg) == "Instance" then
                        local character = LocalPlayer.Character
                        if character and (arg == character.HumanoidRootPart or 
                           arg.Parent == character or 
                           arg:IsDescendantOf(character)) then
                            warn("BLOQUEADO: Tentativa de exploit contra você!")
                            return -- Bloquear completamente
                        end
                    end
                    
                    -- Bloquear vetores extremos
                    if typeof(arg) == "Vector3" and arg.Magnitude > 1000 then
                        warn("BLOQUEADO: Vetor suspeito detectado!")
                        return
                    end
                end
                
                -- Se não está afetando você, permitir (para não quebrar o jogo)
                return originalFire(self, ...)
            end
            
            print("Proteção ativada contra RemoteEvent 1Gu1n")
        end
    end
end

-- Proteção direta do HumanoidRootPart
local function protectHumanoidRootPart()
    local function setupProtection(character)
        local hrp = character:WaitForChild("HumanoidRootPart", 10)
        if not hrp then return end
        
        local originalCFrame = hrp.CFrame
        local lastSafePosition = hrp.Position
        local teleportCount = 0
        
        -- Monitorar mudanças de posição
        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not hrp.Parent then
                connection:Disconnect()
                return
            end
            
            local currentPos = hrp.Position
            local distance = (currentPos - lastSafePosition).Magnitude
            
            -- Detectar teletransporte extremo
            if distance > 1000 or 
               math.abs(currentPos.X) > 1e6 or 
               math.abs(currentPos.Y) > 1e6 or 
               math.abs(currentPos.Z) > 1e6 then
                
                teleportCount = teleportCount + 1
                warn("PROTEÇÃO: Teletransporte suspeito detectado! Contador:", teleportCount)
                
                -- Retornar para posição segura
                pcall(function()
                    hrp.CFrame = CFrame.new(lastSafePosition + Vector3.new(0, 5, 0))
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    hrp.AngularVelocity = Vector3.new(0, 0, 0)
                end)
                
            else
                -- Atualizar posição segura se movimento normal
                if distance < 100 then
                    lastSafePosition = currentPos
                    teleportCount = math.max(0, teleportCount - 0.1)
                end
            end
        end)
        
        -- Proteger contra mudanças de velocidade extremas
        hrp:GetPropertyChangedSignal("Velocity"):Connect(function()
            local vel = hrp.Velocity
            if vel.Magnitude > 500 or 
               math.abs(vel.X) > 1e6 or 
               math.abs(vel.Y) > 1e6 or 
               math.abs(vel.Z) > 1e6 then
                
                warn("PROTEÇÃO: Velocidade anômala detectada!")
                pcall(function()
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    hrp.AngularVelocity = Vector3.new(0, 0, 0)
                end)
            end
        end)
        
        -- Proteger contra mudanças de CFrame extremas
        hrp:GetPropertyChangedSignal("CFrame"):Connect(function()
            local pos = hrp.Position
            if math.abs(pos.X) > 1e10 or 
               math.abs(pos.Y) > 1e10 or 
               math.abs(pos.Z) > 1e10 then
                
                warn("PROTEÇÃO: Posição extrema detectada!")
                pcall(function()
                    hrp.CFrame = CFrame.new(lastSafePosition + Vector3.new(0, 5, 0))
                end)
            end
        end)
    end
    
    -- Aplicar proteção no personagem atual
    if LocalPlayer.Character then
        setupProtection(LocalPlayer.Character)
    end
    
    -- Aplicar proteção quando spawnar
    LocalPlayer.CharacterAdded:Connect(setupProtection)
end

-- Hook mais agressivo para interceptar TODOS os FireServer
local function hookAllRemoteEvents()
    local originalFireServer = game.ReplicatedStorage.RemoteEvent.FireServer
    
    -- Interceptar todos os RemoteEvents
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    
    setreadonly(mt, false)
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" and self.Name == "1Gu1n" then
            -- Verificar se algum argumento se refere ao jogador local
            for i, arg in pairs(args) do
                if typeof(arg) == "Instance" and LocalPlayer.Character then
                    if arg == LocalPlayer.Character.HumanoidRootPart or
                       arg:IsDescendantOf(LocalPlayer.Character) then
                        warn("BLOQUEADO: Exploit interceptado!")
                        return -- Bloquear completamente
                    end
                end
                
                if typeof(arg) == "Vector3" and arg.Magnitude > 1e6 then
                    warn("BLOQUEADO: Vetor extremo interceptado!")
                    return
                end
            end
        end
        
        return oldNamecall(self, ...)
    end
    setreadonly(mt, true)
    
    print("Hook de RemoteEvents ativado!")
end

-- Função para destruir/desabilitar o remote completamente
local function destroyExploitRemote()
    spawn(function()
        while wait(1) do
            local remote = ReplicatedStorage:FindFirstChild("RE")
            if remote then
                local targetRemote = remote:FindFirstChild("1Gu1n")
                if targetRemote then
                    -- Tentar destruir ou desabilitar
                    pcall(function()
                        targetRemote.Parent = nil
                    end)
                    pcall(function()
                        targetRemote:Destroy()
                    end)
                end
            end
        end
    end)
end

-- Inicializar todas as proteções
local function init()
    print("🛡️ Iniciando proteção anti-exploit...")
    
    -- Aguardar game carregar
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    wait(2) -- Aguardar um pouco mais
    
    -- Ativar todas as proteções
    pcall(disableExploitRemote)
    pcall(protectHumanoidRootPart)
    pcall(hookAllRemoteEvents)
    pcall(destroyExploitRemote)
    
    print("✅ Proteção anti-exploit ativada!")
    
    -- Reativar proteções periodicamente
    spawn(function()
        while wait(30) do
            pcall(disableExploitRemote)
            pcall(hookAllRemoteEvents)
        end
    end)
end

-- Executar
init()

-- Reativar quando respawnar
LocalPlayer.CharacterAdded:Connect(function()
    wait(3)
    init()
end)