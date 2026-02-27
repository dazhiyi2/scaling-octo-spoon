--[[
    EXTREME COMBAT SUITE - 稳定回滚版
    功能：
    - 自瞄 (Aimbot): 侧键绑定、平滑度调节
    - 模拟静默 (Flick Trigger): 稳定一帧拉枪模式（已回滚至好用版本）
    - 扳机 (Trigger Bot): 自动检测准星/Flick射击
    - 团队检测 (Team Check): 修复后的全局过滤
    - 视觉 (Visuals): FOV圆圈与ESP透视
    - 现代 UI: 简约暗黑风格，支持拖动
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SETTINGS = {
    AimbotEnabled = true,
    SilentAim = false,
    TriggerEnabled = false,
    FlickTrigger = false,
    TriggerDelay = 0.05,
    WallCheck = true,
    AimbotKey = Enum.UserInputType.MouseButton2,
    Smoothness = 0.2,
    FOV = 150,
    ShowFOV = true,
    ESPEnabled = true,
    TeamCheck = true,
    TargetPart = "Head",
    MenuKey = Enum.KeyCode.Insert
}

-- --- FOV 预览圆圈 ---
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 100
FOVCircle.Radius = SETTINGS.FOV
FOVCircle.Filled = false
FOVCircle.Visible = SETTINGS.ShowFOV
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 0.5

-- --- 现代 UI 组件库 ---
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernCombatGui"
ScreenGui.Parent = (gethui and gethui()) or CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 520)
MainFrame.ClipsDescendants = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.BorderSizePixel = 0
Title.Text = "  YYJ的器灵 (回滚稳定版)"
Title.TextColor3 = Color3.fromRGB(230, 230, 230)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold

-- 拖动支持逻辑
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local Content = Instance.new("ScrollingFrame")
Content.Name = "Content"
Content.Parent = MainFrame
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 10, 0, 50)
Content.Size = UDim2.new(1, -20, 1, -60)
Content.ScrollBarThickness = 2
Content.CanvasSize = UDim2.new(0, 0, 0, 800)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Content
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -5, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    btn.MouseButton1Click:Connect(callback)
    btn.Parent = Content
    return btn
end

local function createSlider(name, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -5, 0, 45)
    container.BackgroundTransparency = 1
    container.Parent = Content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 0, 6)
    bg.Position = UDim2.new(0, 0, 0, 25)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.BorderSizePixel = 0
    bg.Parent = container
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = bg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bg
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 3)
    corner2.Parent = fill

    local function update(input)
        local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * pos
        if max > 1 then val = math.floor(val) end
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = name .. ": " .. (max <= 1 and string.format("%.2f", val) or tostring(val))
        callback(val)
    end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
            end)
            update(input)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then connection:Disconnect() end
            end)
        end
    end)
end

-- --- 按钮生成 ---
local aimBtn = createButton("自瞄: 开启", function() SETTINGS.AimbotEnabled = not SETTINGS.AimbotEnabled end)
local silentAimBtn = createButton("静默自瞄: 关闭", function() SETTINGS.SilentAim = not SETTINGS.SilentAim end)
local flickBtn = createButton("模拟静默 (Flick): 关闭", function() SETTINGS.FlickTrigger = not SETTINGS.FlickTrigger end)
local triggerBtn = createButton("扳机: 关闭", function() SETTINGS.TriggerEnabled = not SETTINGS.TriggerEnabled end)
local wallCheckBtn = createButton("掩体检测: 开启", function() SETTINGS.WallCheck = not SETTINGS.WallCheck end)
local teamBtn = createButton("团队检测: 开启", function() SETTINGS.TeamCheck = not SETTINGS.TeamCheck end)

local partList = {"Head", "UpperTorso", "HumanoidRootPart"}
local partDisplay = {["Head"] = "头部", ["UpperTorso"] = "躯干", ["HumanoidRootPart"] = "重心"}
local currentPartIdx = 1

local partBtn = createButton("自瞄部位: 头部", function()
    currentPartIdx = currentPartIdx + 1
    if currentPartIdx > #partList then currentPartIdx = 1 end
    SETTINGS.TargetPart = partList[currentPartIdx]
end)

local bindBtn = createButton("自瞄热键: " .. SETTINGS.AimbotKey.Name, function() end)

createSlider("自瞄强度 (平滑)", 0.01, 1, SETTINGS.Smoothness, function(v) SETTINGS.Smoothness = v end)
createSlider("扳机延迟", 0, 1, SETTINGS.TriggerDelay, function(v) SETTINGS.TriggerDelay = v end)
createSlider("FOV 范围", 10, 800, SETTINGS.FOV, function(v) SETTINGS.FOV = v end)

local espBtn = createButton("透视: 开启", function() SETTINGS.ESPEnabled = not SETTINGS.ESPEnabled end)
local fovToggleBtn = createButton("显示 FOV 圆圈: 开启", function() SETTINGS.ShowFOV = not SETTINGS.ShowFOV end)

-- 热键绑定
local binding = false
bindBtn.MouseButton1Click:Connect(function()
    binding = true
    bindBtn.Text = "...按下按键/侧键..."
end)

UserInputService.InputBegan:Connect(function(input)
    if binding then
        binding = false
        if input.UserInputType == Enum.UserInputType.Keyboard then
            SETTINGS.AimbotKey = input.KeyCode
            bindBtn.Text = "自瞄热键: " .. input.KeyCode.Name
        else
            SETTINGS.AimbotKey = input.UserInputType
            bindBtn.Text = "自瞄热键: " .. input.UserInputType.Name
        end
    elseif input.KeyCode == SETTINGS.MenuKey then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- --- 核心逻辑 ---

local function isVisible(part)
    if not SETTINGS.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {lp.Character, part.Parent}
    local result = workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, params)
    return not result
end

local function getClosestPlayer()
    local target, dist = nil, math.huge
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= lp and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            if SETTINGS.TeamCheck and v.Team == lp.Team then continue end
            
            local targetPart = v.Character:FindFirstChild(SETTINGS.TargetPart) or v.Character:FindFirstChild("HumanoidRootPart")
            if targetPart and isVisible(targetPart) then
                local pos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < dist and mag < SETTINGS.FOV then
                        target = targetPart; dist = mag
                    end
                end
            end
        end
    end
    return target
end

-- 稳定一帧延迟扳机模式
local lastTriggerTime = 0
local function executeTrigger()
    if not SETTINGS.TriggerEnabled then return end
    
    if SETTINGS.FlickTrigger then
        local target = getClosestPlayer()
        if target then
            local originalCF = camera.CFrame
            -- 1. 拉枪
            camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
            
            -- 2. 开火判定
            if tick() - lastTriggerTime > SETTINGS.TriggerDelay then
                if mouse1click then mouse1click() elseif mouseclick then mouseclick() end
                lastTriggerTime = tick()
            end
            
            -- 3. 稳定回滚的关键：等待下一帧再还原视角，确保游戏捕捉到准星停留
            RunService.RenderStepped:Wait() 
            camera.CFrame = originalCF
        end
    else
        -- 普通模式
        local mousePos = UserInputService:GetMouseLocation()
        local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {lp.Character}
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, params)
        
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            local p = model and Players:GetPlayerFromCharacter(model)
            if p and p ~= lp then
                if SETTINGS.TeamCheck and p.Team == lp.Team then return end
                if tick() - lastTriggerTime > SETTINGS.TriggerDelay then
                    if mouse1click then mouse1click() elseif mouseclick then mouseclick() end
                    lastTriggerTime = tick()
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    -- UI 状态同步
    aimBtn.Text = "自瞄: " .. (SETTINGS.AimbotEnabled and "开启" or "关闭")
    aimBtn.TextColor3 = SETTINGS.AimbotEnabled and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 80, 80)
    silentAimBtn.Text = "静默自瞄: " .. (SETTINGS.SilentAim and "开启" or "关闭")
    silentAimBtn.TextColor3 = SETTINGS.SilentAim and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 80, 80)
    flickBtn.Text = "模拟静默 (Flick): " .. (SETTINGS.FlickTrigger and "开启" or "关闭")
    flickBtn.TextColor3 = SETTINGS.FlickTrigger and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 80, 80)
    triggerBtn.Text = "扳机: " .. (SETTINGS.TriggerEnabled and "开启" or "关闭")
    triggerBtn.TextColor3 = SETTINGS.TriggerEnabled and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 80, 80)
    
    wallCheckBtn.Text = "掩体检测: " .. (SETTINGS.WallCheck and "开启" or "关闭")
    teamBtn.Text = "团队检测: " .. (SETTINGS.TeamCheck and "开启" or "关闭")
    espBtn.Text = "透视: " .. (SETTINGS.ESPEnabled and "开启" or "关闭")
    fovToggleBtn.Text = "显示 FOV 圆圈: " .. (SETTINGS.ShowFOV and "开启" or "关闭")
    partBtn.Text = "自瞄部位: " .. (partDisplay[SETTINGS.TargetPart] or "头部")

    -- FOV 渲染
    FOVCircle.Visible = SETTINGS.ShowFOV and MainFrame.Visible
    FOVCircle.Radius = SETTINGS.FOV
    FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    -- 常规自瞄逻辑
    if not SETTINGS.FlickTrigger then
        local isPressed = (SETTINGS.AimbotKey.EnumType == Enum.UserInputType) and UserInputService:IsMouseButtonPressed(SETTINGS.AimbotKey) or UserInputService:IsKeyDown(SETTINGS.AimbotKey)
        if SETTINGS.AimbotEnabled and isPressed then
            local targetPart = getClosestPlayer()
            if targetPart and not SETTINGS.SilentAim then
                camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, targetPart.Position), SETTINGS.Smoothness)
            end
        end
    end
    
    executeTrigger()
end)

-- --- ESP 透视模块 ---
local function applyESP(player)
    if player == lp then return end
    local function updateESP()
        if not player.Character then return end
        local h = player.Character:FindFirstChild("ExtremeESP")
        local shouldShow = SETTINGS.ESPEnabled
        if SETTINGS.TeamCheck and player.Team == lp.Team then shouldShow = false end
        
        if shouldShow then
            if not h then
                h = Instance.new("Highlight")
                h.Name = "ExtremeESP"
                h.Parent = player.Character
                h.OutlineColor = Color3.new(1, 1, 1)
                h.FillTransparency = 0.5
            end
            h.Enabled = true
            h.FillColor = (player.Team == lp.Team) and Color3.new(0, 1, 0) or Color3.new(1, 0.2, 0.2)
        else
            if h then h.Enabled = false end
        end
    end
    player.CharacterAdded:Connect(function() task.wait(0.5); updateESP() end)
    RunService.Heartbeat:Connect(updateESP)
end

for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

warn("稳定回滚版已加载。模拟静默功能已恢复一帧等待逻辑，以确保命中判定。")
