-- Аимбот с подсветкой игроков и HP индикатором
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Настройки
local aimbotEnabled = false
local target = nil
local highlightColor = Color3.fromRGB(255, 0, 0) -- Красный для обычных игроков
local targetedColor = Color3.fromRGB(255, 165, 0) -- Оранжево-черный для цели

-- НАСТРОЙКИ ПЛАВНОГО РАЗБРОСА
local AIM_RANDOMIZATION = 2 -- Сила разброса
local SMOOTHNESS = 0.3 -- Плавность разброса (0.1 - резкий, 0.5 - плавный)
local currentRandomOffset = Vector3.new(0, 0, 0)
local targetRandomOffset = Vector3.new(0, 0, 0)

-- Функция для обновления плавного случайного смещения
local function updateSmoothRandomOffset()
    -- Плавно интерполируем к целевому смещению
    currentRandomOffset = currentRandomOffset:Lerp(targetRandomOffset, SMOOTHNESS)
    
    -- Если мы достаточно близко к целевому смещению, генерируем новое
    if (currentRandomOffset - targetRandomOffset).Magnitude < 0.1 then
        targetRandomOffset = Vector3.new(
            (math.random() - 0.5) * 2 * AIM_RANDOMIZATION, -- X: от -AIM_RANDOMIZATION до +AIM_RANDOMIZATION
            (math.random() - 0.5) * 2 * AIM_RANDOMIZATION, -- Y: от -AIM_RANDOMIZATION до +AIM_RANDOMIZATION  
            (math.random() - 0.5) * 2 * AIM_RANDOMIZATION  -- Z: от -AIM_RANDOMIZATION до +AIM_RANDOMIZATION
        )
    end
end

-- Функция для получения позиции цели с плавным разбросом
local function getAimPositionWithSmoothSpread(targetHead)
    if not targetHead then return nil end
    
    -- Базовая позиция головы
    local basePosition = targetHead.Position
    
    -- Добавляем плавный разброс
    local spreadPosition = basePosition + currentRandomOffset
    
    return spreadPosition
end

-- Функция для поиска ближайшего игрока
function findNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local currentCharacter = player.Character
    
    if not currentCharacter then return nil end
    
    local currentHead = currentCharacter:FindFirstChild("Head")
    if not currentHead then return nil end
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local character = otherPlayer.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local distance = (currentHead.Position - head.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = otherPlayer
                end
            end
        end
    end
    
    return nearestPlayer
end

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- Основной фрейм для кнопки и HP бара
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 100, 0, 110)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

-- Кнопка включения/выключения
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(1, 0, 0, 80)
toggleButton.Position = UDim2.new(0, 0, 0, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
toggleButton.Text = "AIMBOT\nOFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 3
toggleButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Parent = mainFrame

-- HP бар
local hpBarBackground = Instance.new("Frame")
hpBarBackground.Name = "HPBarBackground"
hpBarBackground.Size = UDim2.new(1, 0, 0, 20)
hpBarBackground.Position = UDim2.new(0, 0, 0, 85)
hpBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
hpBarBackground.BorderSizePixel = 2
hpBarBackground.BorderColor3 = Color3.fromRGB(255, 255, 255)
hpBarBackground.Parent = mainFrame

local hpBar = Instance.new("Frame")
hpBar.Name = "HPBar"
hpBar.Size = UDim2.new(0, 0, 1, 0)
hpBar.Position = UDim2.new(0, 0, 0, 0)
hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
hpBar.BorderSizePixel = 0
hpBar.Parent = hpBarBackground

local hpText = Instance.new("TextLabel")
hpText.Name = "HPText"
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.Position = UDim2.new(0, 0, 0, 0)
hpText.BackgroundTransparency = 1
hpText.Text = "HP: 0/100"
hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
hpText.TextScaled = true
hpText.Font = Enum.Font.GothamBold
hpText.Parent = hpBarBackground

-- Функция для создания подсветки
function createHighlight(targetPlayer, isTargeted)
    if not targetPlayer or not targetPlayer.Character then return nil end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "AimbotHighlight"
    highlight.Adornee = targetPlayer.Character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    if isTargeted then
        -- Оранжево-черный для цели (чередование цветов)
        highlight.FillColor = targetedColor
        highlight.FillTransparency = 0.2
        highlight.OutlineColor = Color3.new(0, 0, 0) -- Черный контур
        highlight.OutlineTransparency = 0
    else
        -- Красный для обычных игроков
        highlight.FillColor = highlightColor
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = highlightColor
        highlight.OutlineTransparency = 0
    end
    
    highlight.Parent = targetPlayer.Character
    
    return highlight
end

-- Функция для удаления всех подсветок
function clearHighlights()
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer.Character then
            local existingHighlight = otherPlayer.Character:FindFirstChild("AimbotHighlight")
            if existingHighlight then
                existingHighlight:Destroy()
            end
        end
    end
end

-- Функция для обновления подсветок
function updateHighlights()
    clearHighlights()
    
    if not aimbotEnabled then return end
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                createHighlight(otherPlayer, otherPlayer == target)
            end
        end
    end
end

-- Функция для обновления HP бара
function updateHPBar()
    if aimbotEnabled and target and target.Character then
        local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local currentHP = humanoid.Health
            local maxHP = humanoid.MaxHealth
            local hpPercentage = currentHP / maxHP
            
            hpBar.Size = UDim2.new(hpPercentage, 0, 1, 0)
            
            -- Изменение цвета в зависимости от HP
            if hpPercentage > 0.5 then
                hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Зеленый
            elseif hpPercentage > 0.25 then
                hpBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Желтый
            else
                hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Красный
            end
            
            hpText.Text = string.format("HP: %d/%d", math.floor(currentHP), math.floor(maxHP))
            return
        end
    end
    
    -- Если аимбот выключен или нет цели
    hpBar.Size = UDim2.new(0, 0, 1, 0)
    hpText.Text = "HP: 0/100"
end

-- Функция для поворота персонажа вместе с камерой
function rotateCharacterToCamera()
    if not aimbotEnabled or not target then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    -- Получаем направление от персонажа к цели
    local targetHead = target.Character and target.Character:FindFirstChild("Head")
    if not targetHead then return end
    
    local characterRoot = character:FindFirstChild("HumanoidRootPart")
    if not characterRoot then return end
    
    -- Вычисляем направление к цели
    local lookVector = (targetHead.Position - characterRoot.Position).Unit
    
    -- Создаем CFrame для поворота персонажа
    local lookCFrame = CFrame.new(characterRoot.Position, characterRoot.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
    
    -- Применяем поворот к корневой части персонажа
    characterRoot.CFrame = CFrame.new(characterRoot.Position, characterRoot.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
end

-- Основной цикл аимбота
RunService.RenderStepped:Connect(function()
    -- Обновляем плавный разброс
    updateSmoothRandomOffset()
    
    if aimbotEnabled then
        local newTarget = findNearestPlayer()
        
        if target ~= newTarget then
            target = newTarget
            updateHighlights()
        end
        
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                -- Получаем позицию с плавным разбросом
                local aimPosition = getAimPositionWithSmoothSpread(head)
                
                -- Наведение камеры на позицию с разбросом
                local camera = workspace.CurrentCamera
                if camera then
                    camera.CFrame = CFrame.new(camera.CFrame.Position, aimPosition)
                end
                
                -- Поворот персонажа
                rotateCharacterToCamera()
            end
        end
    else
        if target then
            target = nil
            clearHighlights()
        end
    end
    
    -- Обновление HP бара каждый кадр
    updateHPBar()
end)

-- Обработчик нажатия кнопки
toggleButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    
    if aimbotEnabled then
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        toggleButton.Text = "AIMBOT\nON"
        updateHighlights()
    else
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        toggleButton.Text = "AIMBOT\nOFF"
        clearHighlights()
        updateHPBar() -- Обновляем HP бар при выключении
    end
end)

-- Обработка смерти/возрождения игроков
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == target then
        target = nil
        updateHighlights()
        updateHPBar()
    end
end)

-- Обновление подсветок при появлении новых игроков
Players.PlayerAdded:Connect(function(newPlayer)
    newPlayer.CharacterAdded:Connect(function()
        if aimbotEnabled then
            updateHighlights()
        end
    end)
    
    newPlayer.CharacterRemoving:Connect(function()
        if aimbotEnabled then
            updateHighlights()
        end
    end)
end)

-- Обновление HP при изменении здоровья цели
local function onTargetHealthChanged()
    if aimbotEnabled and target then
        updateHPBar()
    end
end

-- Инициализация для уже существующих игроков
for _, otherPlayer in pairs(Players:GetPlayers()) do
    if otherPlayer ~= player then
        otherPlayer.CharacterAdded:Connect(function(character)
            if aimbotEnabled then
                updateHighlights()
                local humanoid = character:WaitForChild("Humanoid")
                humanoid.HealthChanged:Connect(onTargetHealthChanged)
            end
        end)
    end
end

print("Aimbot loaded! Use the toggle button to enable/disable.")
