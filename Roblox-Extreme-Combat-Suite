--[[
    EXTREME COMBAT SUITE - 现代简约暗黑版 (Pro+)
    功能：
    - 自瞄 (Aimbot): 支持侧键绑定、强度调节、FOV 调节、锁定部位切换
    - 静默自瞄 (Silent Aim): 视角不转动但逻辑锁定
    - 掩体检测 (Wall Check): 防止隔墙锁定
    - 视觉 (Visuals): 实时 FOV 圆圈显示、敌人透视 (Highlight)
    - 团队检测: 可选过滤队友
    - 现代 UI: 简约深色风格，支持拖动
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SETTINGS = {
    AimbotEnabled = true,
    SilentAim = false, -- 新增：静默自瞄
    WallCheck = true,  -- 新增：掩体检测
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
MainFrame.Size = UDim2.new(0, 220, 0, 500) -- 增加高度以容纳新功能
MainFrame.ClipsDescendants = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.BorderSizePixel = 0
Title.Text = "  YYJ的器灵"
Title.TextColor3 = Color3.fromRGB(230, 230, 230)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold

-- 拖动支持
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
Content.CanvasSize = UDim2.new(0, 0, 0, 650)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Content
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- 辅助函数：创建按钮
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

-- 辅助函数：创建滑块
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
        local val = math.floor(min + (max - min) * pos)
        if max <= 1 then val = min + (max - min) * pos end
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

-- UI 元素生成
local aimBtn = createButton("自瞄: 开启", function() SETTINGS.AimbotEnabled = not SETTINGS.AimbotEnabled end)
local silentAimBtn = createButton("静默自瞄: 关闭", function() SETTINGS.SilentAim = not SETTINGS.SilentAim end)
local wallCheckBtn = createButton("掩体检测: 开启", function() SETTINGS.WallCheck = not SETTINGS.WallCheck end)
local teamBtn = createButton("团队检测: 开启", function() SETTINGS.TeamCheck = not SETTINGS.TeamCheck end)

-- 部位切换逻辑
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
createSlider("FOV 范围", 10, 800, SETTINGS.FOV, function(v) SETTINGS.FOV = v end)

local espBtn = createButton("透视: 开启", function() SETTINGS.ESPEnabled = not SETTINGS.ESPEnabled end)
local fovToggleBtn = createButton("显示 FOV 圆圈: 开启", function() SETTINGS.ShowFOV = not SETTINGS.ShowFOV end)

-- 热键绑定逻辑
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

-- --- 核心逻辑函数 ---

-- 掩体检测
local function isVisible(part)
    if not SETTINGS.WallCheck then return true end
    local castPoints = {camera.CFrame.Position, part.Position}
    local ignoreList = {lp.Character, part.Parent}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList
    
    local result = workspace:Raycast(castPoints[1], castPoints[2] - castPoints[1], params)
    return not result
end

local function getClosestPlayer()
    local target, dist = nil, math.huge
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= lp and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local partName = SETTINGS.TargetPart
            if not v.Character:FindFirstChild(partName) then
                partName = v.Character:FindFirstChild("Torso") and "Torso" or "Head"
            end

            if SETTINGS.TeamCheck and v.Team == lp.Team then continue end
            
            local targetPart = v.Character:FindFirstChild(partName)
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

RunService.RenderStepped:Connect(function()
    -- 更新按钮状态颜色
    aimBtn.TextColor3 = SETTINGS.AimbotEnabled and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 80, 80)
    aimBtn.Text = "自瞄: " .. (SETTINGS.AimbotEnabled and "开启" or "关闭")
    
    silentAimBtn.TextColor3 = SETTINGS.SilentAim and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(200, 80, 80)
    silentAimBtn.Text = "静默自瞄: " .. (SETTINGS.SilentAim and "开启" or "关闭")
    
    wallCheckBtn.Text = "掩体检测: " .. (SETTINGS.WallCheck and "开启" or "关闭")
    teamBtn.Text = "团队检测: " .. (SETTINGS.TeamCheck and "开启" or "关闭")
    espBtn.Text = "透视: " .. (SETTINGS.ESPEnabled and "开启" or "关闭")
    fovToggleBtn.Text = "显示 FOV 圆圈: " .. (SETTINGS.ShowFOV and "开启" or "关闭")
    
    local dispName = partDisplay[SETTINGS.TargetPart] or "头部"
    partBtn.Text = "自瞄部位: " .. dispName

    -- 更新 FOV 圆圈
    FOVCircle.Visible = SETTINGS.ShowFOV and MainFrame.Visible
    FOVCircle.Radius = SETTINGS.FOV
    FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    -- 执行自瞄
    local isPressed = (SETTINGS.AimbotKey.EnumType == Enum.UserInputType) and UserInputService:IsMouseButtonPressed(SETTINGS.AimbotKey) or UserInputService:IsKeyDown(SETTINGS.AimbotKey)
    
    if SETTINGS.AimbotEnabled and isPressed then
        local targetPart = getClosestPlayer()
        if targetPart then
            if SETTINGS.SilentAim then
                -- 静默自瞄通常需要修改网络包或攻击逻辑，这里作为UI演示预留
            else
                camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, targetPart.Position), SETTINGS.Smoothness)
            end
        end
    end
end)

-- 透视逻辑
local function applyESP(player)
    if player == lp then return end
    local function createESP()
        if not player.Character then return end
        local h = player.Character:FindFirstChild("ExtremeESP") or Instance.new("Highlight")
        h.Name = "ExtremeESP"
        h.Parent = player.Character
        h.Enabled = SETTINGS.ESPEnabled
        h.FillColor = (player.Team == lp.Team) and Color3.new(0, 1, 0) or Color3.new(1, 0.2, 0.2)
        h.OutlineColor = Color3.new(1, 1, 1)
        h.FillTransparency = 0.5
    end
    player.CharacterAdded:Connect(function() task.wait(0.5); createESP() end)
    createESP()
    RunService.Heartbeat:Connect(function()
        if player.Character then
            local h = player.Character:FindFirstChild("ExtremeESP")
            if h then 
                h.Enabled = SETTINGS.ESPEnabled 
                h.FillColor = (player.Team == lp.Team) and Color3.new(0, 1, 0) or Color3.new(1, 0.2, 0.2)
            end
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

warn("Modern Dark GUI Pro+ Loaded! [Insert] 键切换菜单。")
