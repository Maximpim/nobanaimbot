local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local aimbotEnabled = false
local target = nil
local enemyColor = Color3.fromRGB(255, 0, 0)
local friendColor = Color3.fromRGB(0, 150, 255)
local targetedColor = Color3.fromRGB(255, 165, 0)

local AIM_RANDOMIZATION = 2
local SMOOTHNESS = 0.3
local currentRandomOffset = Vector3.new(0, 0, 0)
local targetRandomOffset = Vector3.new(0, 0, 0)

local rainbowEnabled = false
local rainbowConnection = nil
local currentWeapon = nil
local partData = {}

function isFriend(otherPlayer)
    local success, isFriendResult = pcall(function()
        return player:IsFriendsWith(otherPlayer.UserId)
    end)
    
    if success and isFriendResult then
        return true
    end
    
    return false
end

local function updateSmoothRandomOffset()
    currentRandomOffset = currentRandomOffset:Lerp(targetRandomOffset, SMOOTHNESS)
    
    if (currentRandomOffset - targetRandomOffset).Magnitude < 0.1 then
        targetRandomOffset = Vector3.new(
            (math.random() - 0.5) * 2 * AIM_RANDOMIZATION,
            (math.random() - 0.5) * 2 * AIM_RANDOMIZATION, 
            (math.random() - 0.5) * 2 * AIM_RANDOMIZATION
        )
    end
end

local function getAimPositionWithSmoothSpread(targetHead)
    if not targetHead then return nil end
    
    local basePosition = targetHead.Position
    local spreadPosition = basePosition + currentRandomOffset
    
    return spreadPosition
end

function findNearestEnemy()
    local nearestEnemy = nil
    local shortestDistance = math.huge
    local currentCharacter = player.Character
    
    if not currentCharacter then return nil end
    
    local currentHead = currentCharacter:FindFirstChild("Head")
    if not currentHead then return nil end
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character then
            if isFriend(otherPlayer) then
                continue
            end
            
            local character = otherPlayer.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and head then
                local distance = (currentHead.Position - head.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestEnemy = otherPlayer
                end
            end
        end
    end
    
    return nearestEnemy
end

local function findFirstPersonObject()
    local workspace = game:GetService("Workspace")
    
    local possiblePaths = {
        workspace,
        workspace:FindFirstChild("MpMaximPim"),
        workspace:FindFirstChild(player.Name),
    }
    
    for _, path in ipairs(possiblePaths) do
        if path then
            if path:FindFirstChild("ViewModels") then
                local viewModels = path.ViewModels
                if viewModels:FindFirstChild("FirstPerson") then
                    local firstPerson = viewModels.FirstPerson
                    for _, weapon in ipairs(firstPerson:GetChildren()) do
                        if weapon:IsA("Model") or weapon:IsA("Tool") or weapon:IsA("Part") then
                            return weapon
                        end
                    end
                end
            end
        end
    end
    
    local function recursiveSearch(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "FirstPerson" then
                for _, weapon in ipairs(child:GetChildren()) do
                    if weapon:IsA("Model") or weapon:IsA("Tool") or weapon:IsA("Part") then
                        return weapon
                    end
                end
            end
            local result = recursiveSearch(child)
            if result then return result end
        end
        return nil
    end
    
    return recursiveSearch(workspace)
end

local function collectWeaponParts(weapon)
    partData = {}
    
    if weapon:IsA("BasePart") then
        partData[weapon] = {
            hue = 0,
            speed = 0.8 + math.random() * 0.4
        }
    elseif weapon:IsA("Model") then
        for _, part in ipairs(weapon:GetDescendants()) do
            if part:IsA("BasePart") then
                partData[part] = {
                    hue = math.random(),
                    speed = 0.8 + math.random() * 0.4
                }
            end
        end
    end
end

local function applyIndividualRainbow(deltaTime)
    for part, data in pairs(partData) do
        if part and part.Parent then
            data.hue = (data.hue + data.speed * deltaTime) % 1
            local color = Color3.fromHSV(data.hue, 1, 1)
            part.Color = color
        end
    end
end

local function stopRainbowEffect()
    if rainbowConnection then
        rainbowConnection:Disconnect()
        rainbowConnection = nil
    end
    
    for part, _ in pairs(partData) do
        if part and part.Parent then
            part.Color = Color3.fromRGB(255, 255, 255)
        end
    end
    partData = {}
end

local function startRainbowEffect()
    currentWeapon = findFirstPersonObject()
    if not currentWeapon then
        return false
    end
    
    collectWeaponParts(currentWeapon)
    
    if next(partData) == nil then
        return false
    end
    
    stopRainbowEffect()
    
    local lastWeaponCheck = 0
    rainbowConnection = RunService.RenderStepped:Connect(function(deltaTime)
        lastWeaponCheck = lastWeaponCheck + deltaTime
        if lastWeaponCheck > 0.1 then
            local newWeapon = findFirstPersonObject()
            if newWeapon and newWeapon ~= currentWeapon then
                currentWeapon = newWeapon
                collectWeaponParts(currentWeapon)
            end
            lastWeaponCheck = 0
        end
        
        if not currentWeapon or not currentWeapon.Parent then
            stopRainbowEffect()
            rainbowEnabled = false
            updateRainbowCheckbox()
            return
        end
        
        applyIndividualRainbow(deltaTime)
    end)
    
    return true
end

local function toggleRainbowEffect()
    if rainbowEnabled then
        stopRainbowEffect()
        rainbowEnabled = false
    else
        local success = startRainbowEffect()
        if success then
            rainbowEnabled = true
        else
            rainbowEnabled = false
        end
    end
    updateRainbowCheckbox()
end

local function copyToClipboard()
    local text = "https://funpay.com/users/14330849/"
    
    local success, result = pcall(function()
        if setclipboard then
            setclipboard(text)
            return true
        end
        return false
    end)
    
    if success and result then
    else
        local screenGui = Instance.new("ScreenGui")
        local textBox = Instance.new("TextBox")
        screenGui.Parent = player.PlayerGui
        textBox.Parent = screenGui
        textBox.Text = text
        textBox:CaptureFocus()
        textBox:SelectAll()
        textBox:ReleaseFocus()
        screenGui:Destroy()
    end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 100, 0, 150)
mainFrame.Position = UDim2.new(0, 20, 0, 20)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = screenGui

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

local bottomFrame = Instance.new("Frame")
bottomFrame.Name = "BottomFrame"
bottomFrame.Size = UDim2.new(1, 0, 0, 25)
bottomFrame.Position = UDim2.new(0, 0, 0, 110)
bottomFrame.BackgroundTransparency = 1
bottomFrame.Parent = mainFrame

local rainbowCheckbox = Instance.new("TextButton")
rainbowCheckbox.Name = "RainbowCheckbox"
rainbowCheckbox.Size = UDim2.new(0, 25, 0, 25)
rainbowCheckbox.Position = UDim2.new(0, 0, 0, 0)
rainbowCheckbox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
rainbowCheckbox.BorderSizePixel = 2
rainbowCheckbox.BorderColor3 = Color3.fromRGB(255, 255, 255)
rainbowCheckbox.Text = ""
rainbowCheckbox.Parent = bottomFrame

local funpayButton = Instance.new("TextButton")
funpayButton.Name = "FunpayButton"
funpayButton.Size = UDim2.new(0, 25, 0, 25)
funpayButton.Position = UDim2.new(0, 30, 0, 0)
funpayButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
funpayButton.BorderSizePixel = 2
funpayButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
funpayButton.Text = "F"
funpayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
funpayButton.TextScaled = true
funpayButton.Font = Enum.Font.GothamBold
funpayButton.Parent = bottomFrame

local function updateRainbowCheckbox()
    if rainbowEnabled then
        rainbowCheckbox.BackgroundColor3 = Color3.fromHSV((tick() % 3) / 3, 1, 1)
        rainbowCheckbox.Text = "✓"
        rainbowCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    else
        rainbowCheckbox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        rainbowCheckbox.Text = ""
    end
end

function createHighlight(targetPlayer, isTargeted)
    if not targetPlayer or not targetPlayer.Character then return nil end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "AimbotHighlight"
    highlight.Adornee = targetPlayer.Character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    if isTargeted then
        highlight.FillColor = targetedColor
        highlight.FillTransparency = 0.2
        highlight.OutlineColor = Color3.new(0, 0, 0)
        highlight.OutlineTransparency = 0
    else
        if isFriend(targetPlayer) then
            highlight.FillColor = friendColor
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = friendColor
            highlight.OutlineTransparency = 0
        else
            highlight.FillColor = enemyColor
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = enemyColor
            highlight.OutlineTransparency = 0
        end
    end
    
    highlight.Parent = targetPlayer.Character
    
    return highlight
end

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

function updateHPBar()
    if aimbotEnabled and target and target.Character then
        local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local currentHP = humanoid.Health
            local maxHP = humanoid.MaxHealth
            local hpPercentage = currentHP / maxHP
            
            hpBar.Size = UDim2.new(hpPercentage, 0, 1, 0)
            
            if hpPercentage > 0.5 then
                hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            elseif hpPercentage > 0.25 then
                hpBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
            else
                hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            end
            
            hpText.Text = string.format("HP: %d/%d", math.floor(currentHP), math.floor(maxHP))
            return
        end
    end
    
    hpBar.Size = UDim2.new(0, 0, 1, 0)
    hpText.Text = "HP: 0/100"
end

function rotateCharacterToCamera()
    if not aimbotEnabled or not target then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local targetHead = target.Character and target.Character:FindFirstChild("Head")
    if not targetHead then return end
    
    local characterRoot = character:FindFirstChild("HumanoidRootPart")
    if not characterRoot then return end
    
    local lookVector = (targetHead.Position - characterRoot.Position).Unit
    
    characterRoot.CFrame = CFrame.new(characterRoot.Position, characterRoot.Position + Vector3.new(lookVector.X, 0, lookVector.Z))
end

RunService.RenderStepped:Connect(function()
    updateSmoothRandomOffset()
    
    if rainbowEnabled then
        updateRainbowCheckbox()
    end
    
    if aimbotEnabled then
        local newTarget = findNearestEnemy()
        
        if target ~= newTarget then
            target = newTarget
            updateHighlights()
        end
        
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                local aimPosition = getAimPositionWithSmoothSpread(head)
                
                local camera = workspace.CurrentCamera
                if camera then
                    camera.CFrame = CFrame.new(camera.CFrame.Position, aimPosition)
                end
                
                rotateCharacterToCamera()
            end
        end
    else
        if target then
            target = nil
            clearHighlights()
        end
    end
    
    updateHPBar()
end)

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
        updateHPBar()
    end
end)

rainbowCheckbox.MouseButton1Click:Connect(function()
    toggleRainbowEffect()
end)

funpayButton.MouseButton1Click:Connect(function()
    copyToClipboard()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == target then
        target = nil
        updateHighlights()
        updateHPBar()
    end
end)

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

local function onTargetHealthChanged()
    if aimbotEnabled and target then
        updateHPBar()
    end
end

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

game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        stopRainbowEffect()
    end
end)
