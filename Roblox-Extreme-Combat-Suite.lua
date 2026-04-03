-- --- LUA.OS - V23.0 FINAL FULL EDITION (VISUAL BLACKLIST & SELECTOR) ---
-- [+] ADDED: Visual Player Selector UI (Use < > arrows to select easily)
-- [+] ADDED: Visual Blacklist Tags (Red warning above blacklisted players)
-- [+] ENHANCED: Blacklisted targets get custom Black/Red Chams priority
-- [+] RETAINED: Auto-Bone Engine (Smart visible part targeting / "漏打")
-- [+] RETAINED: V16 Classic Camera Flick Logic & Default OFF settings

if getgenv().LUA_OS_LOADED then
    local oldGui = game:GetService("CoreGui"):FindFirstChild("LUA_OS_GUI")
    if oldGui then oldGui:Destroy() end
end
getgenv().LUA_OS_LOADED = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- --- 全局设置 (全关默认) ---
getgenv().SETTINGS = {
    -- 战斗 
    AimbotEnabled = false,
    SilentAim = false,           
    IgnoreFOV = false,           
    AutoBone = false,            
    Blacklist = {},              -- V23: 黑名单列表
    FlickTrigger = false,   
    TriggerBot = false,          
    Smoothness = 15,
    FOV = 150,
    WallCheck = false,
    ShowFOV = false,
    TeamCheck = false,
    -- 视觉 
    ChamsEnabled = false,
    RainbowChams = false,                        
    VisibleColor = Color3.fromRGB(255, 0, 0),    
    HiddenColor = Color3.fromRGB(255, 255, 255),  
    TargetColor = Color3.fromRGB(255, 150, 200),  
    -- 杂项 
    ThirdPerson = false,                         
    Spinbot = false,                             
    SpinSpeed = 25,                              
    SteadyView = false,
    WalkSpeedEnabled = false,    
    WalkSpeed = 16,              
    JumpPowerEnabled = false,    
    JumpPower = 50,              
    
    TargetPart = "Head",
    AimbotKey = Enum.UserInputType.MouseButton2,
    MenuKey = Enum.KeyCode.Insert
}

local OriginalCFrame = nil 
local IsFlicking = false
local IsBinding = false
local BindingTarget = nil 
local CurrentTarget = nil 
local triggerBotCooldown = false

-- --- 核心工具函数 ---
local function GetKeyName(enum)
    if not enum then return "NONE" end
    local s = tostring(enum):split(".")
    return s[#s] or "UNKNOWN"
end

local function SmoothTween(obj, goal, t)
    local info = TweenInfo.new(t or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(obj, info, goal)
    tween:Play()
    return tween
end

-- 智能部位回退系统
local function GetTargetPart(character, preferredPartName)
    if not character then return nil end
    local part = character:FindFirstChild(preferredPartName)
    if part then return part end
    
    local fallbacks = {"HeadBox", "Hitbox", "UpperTorso", "Torso", "HumanoidRootPart"}
    for _, name in ipairs(fallbacks) do
        part = character:FindFirstChild(name)
        if part then return part end
    end
    
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

-- 强制存活检测 
local function IsAlive(player)
    local char = player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then return hum.Health > 0 end
    return GetTargetPart(char, "Head") ~= nil
end

local function IsVisible(part, targetCharacter)
    local ignoreList = {camera, lp.Character, targetCharacter}
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignoreList
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

-- --- FOV 渲染 ---
local FOVCircle = nil
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1; FOVCircle.Filled = false; FOVCircle.Transparency = 1; FOVCircle.Color = Color3.new(1, 1, 1)
end)

-- --- UI 构建 ---
local ScreenGui = Instance.new("ScreenGui")
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = lp:WaitForChild("PlayerGui") end
ScreenGui.Name = "LUA_OS_GUI"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 620, 0, 520)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.new(1,1,1); Stroke.Transparency = 0.9

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)

local UserPanel = Instance.new("Frame", Sidebar)
UserPanel.Size = UDim2.new(1, -20, 0, 60); UserPanel.Position = UDim2.new(0, 10, 1, -70); UserPanel.BackgroundTransparency = 1
local AvatarImg = Instance.new("ImageLabel", UserPanel)
AvatarImg.Size = UDim2.new(0, 40, 0, 40); AvatarImg.Position = UDim2.new(0, 5, 0.5, -20); AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. lp.UserId .. "&w=150&h=150"
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)
local DisplayName = Instance.new("TextLabel", UserPanel)
DisplayName.Size = UDim2.new(1, -55, 0, 18); DisplayName.Position = UDim2.new(0, 55, 0.5, -18); DisplayName.Text = lp.DisplayName; DisplayName.Font = Enum.Font.GothamBold; DisplayName.TextColor3 = Color3.new(1, 1, 1); DisplayName.TextSize = 13; DisplayName.TextXAlignment = Enum.TextXAlignment.Left; DisplayName.BackgroundTransparency = 1

local UserName = Instance.new("TextLabel", UserPanel)
UserName.Size = UDim2.new(1, -55, 0, 15); UserName.Position = UDim2.new(0, 55, 0.5, 2)
UserName.Text = "@" .. lp.Name; UserName.Font = Enum.Font.GothamMedium; UserName.TextColor3 = Color3.new(0.5, 0.5, 0.5); UserName.TextSize = 11; UserName.TextXAlignment = Enum.TextXAlignment.Left; UserName.BackgroundTransparency = 1

local Logo = Instance.new("TextLabel", Sidebar)
Logo.Text = "LUA.OS V23"
Logo.Font = Enum.Font.GothamBold
Logo.TextColor3 = Color3.new(1, 1, 1); Logo.TextSize = 22
Logo.Size = UDim2.new(1, 0, 0, 80); Logo.BackgroundTransparency = 1

local Content = Instance.new("Frame", MainFrame)
Content.Position = UDim2.new(0, 180, 0, 0); Content.Size = UDim2.new(1, -180, 1, 0); Content.BackgroundTransparency = 1
local TabTitle = Instance.new("TextLabel", Content)
TabTitle.Size = UDim2.new(1, -60, 0, 60); TabTitle.Position = UDim2.new(0, 30, 0, 10); TabTitle.Text = "战斗增强"; TabTitle.Font = Enum.Font.GothamBold; TabTitle.TextColor3 = Color3.new(0.6, 0.6, 0.6); TabTitle.TextSize = 12; TabTitle.TextXAlignment = Enum.TextXAlignment.Left; TabTitle.BackgroundTransparency = 1
local Scroll = Instance.new("ScrollingFrame", Content)
Scroll.Size = UDim2.new(1, -40, 1, -80); Scroll.Position = UDim2.new(0, 20, 0, 70); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 0; Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local Layout = Instance.new("UIListLayout", Scroll); Layout.Padding = UDim.new(0, 8)

-- --- UI 组件构建器 ---
local function CreateToggle(name, setting, parent)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 55); Frame.BackgroundColor3 = Color3.new(1, 1, 1); Frame.BackgroundTransparency = 0.97
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0.7, 0, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0); Label.Text = name; Label.Font = Enum.Font.GothamMedium; Label.TextColor3 = Color3.new(1, 1, 1); Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.BackgroundTransparency = 1
    local Switch = Instance.new("TextButton", Frame)
    Switch.Size = UDim2.new(0, 40, 0, 20); Switch.Position = UDim2.new(1, -55, 0.5, -10); Switch.Text = ""; Switch.AutoButtonColor = false
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
    local Dot = Instance.new("Frame", Switch)
    Dot.Size = UDim2.new(0, 14, 0, 14); Dot.Position = UDim2.new(0, 3, 0.5, -7); Dot.BackgroundColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    local function Refresh()
        local active = getgenv().SETTINGS[setting]
        SmoothTween(Switch, {BackgroundColor3 = active and Color3.new(1, 1, 1) or Color3.fromRGB(45, 45, 45)})
        SmoothTween(Dot, {
            Position = active and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = active and Color3.new(0, 0, 0) or Color3.new(0.6, 0.6, 0.6)
        })
    end
    Switch.MouseButton1Click:Connect(function() getgenv().SETTINGS[setting] = not getgenv().SETTINGS[setting]; Refresh() end)
    Refresh()
end

local activeSlider = nil
local function CreateSlider(name, setting, min, max, parent)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 65); Frame.BackgroundColor3 = Color3.new(1,1,1); Frame.BackgroundTransparency = 0.97
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -20, 0, 30); Label.Position = UDim2.new(0, 15, 0, 5); Label.Text = name .. ": " .. tostring(getgenv().SETTINGS[setting]); Label.Font = Enum.Font.GothamMedium; Label.TextColor3 = Color3.new(1,1,1); Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.BackgroundTransparency = 1
    local Track = Instance.new("Frame", Frame)
    Track.Size = UDim2.new(1, -30, 0, 6); Track.Position = UDim2.new(0, 15, 0, 42); Track.BackgroundColor3 = Color3.new(1, 1, 1); Track.BackgroundTransparency = 0.92
    Instance.new("UICorner", Track)
    local Fill = Instance.new("Frame", Track)
    Fill.Size = UDim2.new((getgenv().SETTINGS[setting] - min) / (max - min), 0, 1, 0); Fill.BackgroundColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", Fill)
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        getgenv().SETTINGS[setting] = val
        Fill.Size = UDim2.new(pos, 0, 1, 0); Label.Text = name .. ": " .. tostring(val)
    end
    Track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then activeSlider = UpdateSlider; UpdateSlider(input) end end)
end

local function CreateKeybind(name, setting, parent)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 55); Frame.BackgroundColor3 = Color3.new(1,1,1); Frame.BackgroundTransparency = 0.97
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -120, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0); Label.Text = name; Label.Font = Enum.Font.GothamMedium; Label.TextColor3 = Color3.new(1, 1, 1); Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.BackgroundTransparency = 1
    local BindBtn = Instance.new("TextButton", Frame)
    BindBtn.Size = UDim2.new(0, 95, 0, 30); BindBtn.Position = UDim2.new(1, -110, 0.5, -15); BindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); BindBtn.Text = GetKeyName(getgenv().SETTINGS[setting]); BindBtn.Font = Enum.Font.GothamBold; BindBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8); BindBtn.TextSize = 11
    Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 6)
    BindBtn.MouseButton1Click:Connect(function() if not IsBinding then IsBinding = true; BindingTarget = setting; BindBtn.Text = "..."; end end)
    RunService.Heartbeat:Connect(function() if not IsBinding or BindingTarget ~= setting then BindBtn.Text = GetKeyName(getgenv().SETTINGS[setting]) end end)
end

-- V23 新增：可视化玩家选择器 (替代难用的文本框)
local function CreatePlayerSelector(parent)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 85)
    Frame.BackgroundColor3 = Color3.new(1, 1, 1)
    Frame.BackgroundTransparency = 0.97
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)

    local TitleLabel = Instance.new("TextLabel", Frame)
    TitleLabel.Size = UDim2.new(1, -20, 0, 20)
    TitleLabel.Position = UDim2.new(0, 15, 0, 5)
    TitleLabel.Text = "黑名单目标选择器"; TitleLabel.Font = Enum.Font.GothamMedium; TitleLabel.TextColor3 = Color3.new(1, 1, 1); TitleLabel.TextSize = 13; TitleLabel.TextXAlignment = Enum.TextXAlignment.Left; TitleLabel.BackgroundTransparency = 1

    local NameDisplay = Instance.new("TextLabel", Frame)
    NameDisplay.Size = UDim2.new(1, -90, 0, 25)
    NameDisplay.Position = UDim2.new(0, 45, 0, 25)
    NameDisplay.Text = "加载中..."; NameDisplay.Font = Enum.Font.GothamBold; NameDisplay.TextColor3 = Color3.fromRGB(255, 170, 0); NameDisplay.TextSize = 12; NameDisplay.BackgroundTransparency = 1

    local BtnPrev = Instance.new("TextButton", Frame)
    BtnPrev.Size = UDim2.new(0, 25, 0, 25); BtnPrev.Position = UDim2.new(0, 15, 0, 25)
    BtnPrev.BackgroundColor3 = Color3.fromRGB(30, 30, 30); BtnPrev.Text = "<"; BtnPrev.TextColor3 = Color3.new(1,1,1); BtnPrev.Font = Enum.Font.GothamBold
    Instance.new("UICorner", BtnPrev).CornerRadius = UDim.new(0, 6)

    local BtnNext = Instance.new("TextButton", Frame)
    BtnNext.Size = UDim2.new(0, 25, 0, 25); BtnNext.Position = UDim2.new(1, -40, 0, 25)
    BtnNext.BackgroundColor3 = Color3.fromRGB(30, 30, 30); BtnNext.Text = ">"; BtnNext.TextColor3 = Color3.new(1,1,1); BtnNext.Font = Enum.Font.GothamBold
    Instance.new("UICorner", BtnNext).CornerRadius = UDim.new(0, 6)

    local ActionBtn = Instance.new("TextButton", Frame)
    ActionBtn.Size = UDim2.new(1, -30, 0, 25); ActionBtn.Position = UDim2.new(0, 15, 0, 55)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); ActionBtn.Text = "添加 / 移除"; ActionBtn.TextColor3 = Color3.new(1,1,1); ActionBtn.Font = Enum.Font.GothamBold; ActionBtn.TextSize = 12
    Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 6)

    local currentIdx = 1
    local pList = {}

    local function refreshUI()
        pList = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then table.insert(pList, p) end
        end
        
        if #pList == 0 then
            NameDisplay.Text = "房间内无其他玩家"
            NameDisplay.TextColor3 = Color3.fromRGB(150, 150, 150)
            ActionBtn.Text = "无法操作"
            ActionBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            return
        end
        
        if currentIdx > #pList then currentIdx = 1 end
        if currentIdx < 1 then currentIdx = #pList end
        
        local targetPlayer = pList[currentIdx]
        NameDisplay.Text = targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")"
        
        if table.find(getgenv().SETTINGS.Blacklist, targetPlayer.Name) then
            ActionBtn.Text = "已在黑名单 - 点击移除"
            ActionBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            NameDisplay.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            ActionBtn.Text = "一键加入黑名单"
            ActionBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            NameDisplay.TextColor3 = Color3.fromRGB(255, 170, 0)
        end
    end

    BtnPrev.MouseButton1Click:Connect(function() currentIdx = currentIdx - 1; refreshUI() end)
    BtnNext.MouseButton1Click:Connect(function() currentIdx = currentIdx + 1; refreshUI() end)
    ActionBtn.MouseButton1Click:Connect(function()
        if #pList == 0 then return end
        local targetPlayer = pList[currentIdx]
        local idx = table.find(getgenv().SETTINGS.Blacklist, targetPlayer.Name)
        if idx then
            table.remove(getgenv().SETTINGS.Blacklist, idx)
        else
            table.insert(getgenv().SETTINGS.Blacklist, targetPlayer.Name)
        end
        refreshUI()
    end)
    
    -- 定时自动刷新，防止玩家退出导致索引报错
    task.spawn(function()
        while Frame.Parent do
            refreshUI()
            task.wait(1)
        end
    end)
    
    refreshUI()
end

-- --- 核心索敌算法 (智能漏打 + 黑名单优先引擎) ---
local function GetClosestTarget()
    local target = nil
    local minDist = math.huge
    local isTargetBlacklisted = false
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and IsAlive(player) then
            if getgenv().SETTINGS.TeamCheck and player.Team == lp.Team then continue end
            
            local p = nil
            
            -- V22/V23 智能漏打逻辑
            if getgenv().SETTINGS.AutoBone then
                -- 遍历全身重要部件，找到第一个露出掩体的部位
                local partsToCheck = {"Head", "HeadBox", "Hitbox", "UpperTorso", "LowerTorso", "Torso", "HumanoidRootPart", "RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg"}
                for _, partName in ipairs(partsToCheck) do
                    local tempPart = player.Character:FindFirstChild(partName)
                    if tempPart and IsVisible(tempPart, player.Character) then
                        p = tempPart
                        break
                    end
                end
            else
                p = GetTargetPart(player.Character, getgenv().SETTINGS.TargetPart)
                if p and getgenv().SETTINGS.WallCheck and not IsVisible(p, player.Character) then 
                    p = nil 
                end
            end
            
            if p then
                local dist = math.huge
                if getgenv().SETTINGS.IgnoreFOV then
                    dist = (camera.CFrame.Position - p.Position).Magnitude
                else
                    local pos, onScreen = camera:WorldToViewportPoint(p.Position)
                    if onScreen then
                        local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if mag < getgenv().SETTINGS.FOV then
                            dist = mag
                        end
                    end
                end
                
                -- 黑名单权重引擎
                if dist ~= math.huge then
                    local isPBlacklisted = table.find(getgenv().SETTINGS.Blacklist, player.Name) ~= nil
                    
                    if isPBlacklisted and not isTargetBlacklisted then
                        -- 发现黑名单玩家且当前目标不是黑名单，立刻强制覆盖(无视距离)
                        target = p
                        minDist = dist
                        isTargetBlacklisted = true
                    elseif isPBlacklisted == isTargetBlacklisted then
                        -- 两人同属黑名单，或两人同属白名单，此时比较谁距离更近
                        if dist < minDist then
                            target = p
                            minDist = dist
                        end
                    end
                end
            end
        end
    end
    return target
end

-- --- 核心主循环 ---
RunService.PreRender:Connect(function()
    if FOVCircle then
        FOVCircle.Visible = getgenv().SETTINGS.ShowFOV and not getgenv().SETTINGS.IgnoreFOV
        FOVCircle.Radius = getgenv().SETTINGS.FOV
        FOVCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    end

    local aimKey = getgenv().SETTINGS.AimbotKey
    local isPressed = (tostring(aimKey):find("MouseButton") and UserInputService:IsMouseButtonPressed(aimKey)) or UserInputService:IsKeyDown(aimKey)

    local closestTarget = GetClosestTarget()
    CurrentTarget = closestTarget and closestTarget.Parent or nil

    -- 自动扳机 (TriggerBot)
    if getgenv().SETTINGS.TriggerBot and not triggerBotCooldown then
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {lp.Character, camera}
        local ray = camera:ViewportPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
        
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local p = Players:GetPlayerFromCharacter(model)
                if p and IsAlive(p) and not (getgenv().SETTINGS.TeamCheck and p.Team == lp.Team) then
                    triggerBotCooldown = true
                    task.spawn(function()
                        pcall(function() mouse1press() end)
                        task.wait(0.01)
                        pcall(function() mouse1release() end)
                        task.wait(0.1) 
                        triggerBotCooldown = false
                    end)
                end
            end
        end
    end

    -- 陀螺旋转逻辑 (Spinbot)
    if getgenv().SETTINGS.Spinbot and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = lp.Character.HumanoidRootPart
        local oldCamCF = camera.CFrame 
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(getgenv().SETTINGS.SpinSpeed), 0)
        
        if getgenv().SETTINGS.SteadyView then
            if (camera.Focus.p - camera.CFrame.p).Magnitude < 0.6 or not getgenv().SETTINGS.ThirdPerson then
                camera.CFrame = oldCamCF
            end
        end
    end

    -- 经典 Flick 与 Silent Aim 还原逻辑
    if isPressed and closestTarget then
        if getgenv().SETTINGS.SilentAim or getgenv().SETTINGS.FlickTrigger then
            if not IsFlicking then
                IsFlicking = true
                OriginalCFrame = camera.CFrame 
                
                -- 瞬间转向目标
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, closestTarget.Position)
                
                pcall(function() if mouse1press then mouse1press() end end)
                task.wait(0.01)
                pcall(function() if mouse1release then mouse1release() end end)
                
                -- 等待渲染后强行回正
                RunService.RenderStepped:Wait() 
                camera.CFrame = OriginalCFrame
                
                task.delay(0.1, function() IsFlicking = false end)
            end
            return
        elseif getgenv().SETTINGS.AimbotEnabled then
            -- 平滑自瞄
            local s = 1 - (getgenv().SETTINGS.Smoothness / 105)
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, closestTarget.Position), s)
        end
    end
end)

-- --- 第三人称与移动控制循环 ---
local wasThirdPerson = false
RunService.RenderStepped:Connect(function()
    if getgenv().SETTINGS.ThirdPerson then
        lp.CameraMode = Enum.CameraMode.Classic
        lp.CameraMinZoomDistance = 12; lp.CameraMaxZoomDistance = 12
        wasThirdPerson = true
    elseif wasThirdPerson then
        lp.CameraMinZoomDistance = 0.5; lp.CameraMaxZoomDistance = 400
        wasThirdPerson = false
    end

    if lp.Character and lp.Character:FindFirstChild("Humanoid") then
        local hum = lp.Character.Humanoid
        if getgenv().SETTINGS.WalkSpeedEnabled then
            hum.WalkSpeed = getgenv().SETTINGS.WalkSpeed
        end
        if getgenv().SETTINGS.JumpPowerEnabled then
            hum.UseJumpPower = true 
            hum.JumpPower = getgenv().SETTINGS.JumpPower
        end
    end
end)

-- --- 视觉渲染系统 (V23 黑名单警告强化) ---
RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player == lp or not IsAlive(player) then continue end
        local isEnemy = not (getgenv().SETTINGS.TeamCheck and player.Team == lp.Team)
        local h = player.Character:FindFirstChild("LUA_Chams")
        local isBlacklisted = table.find(getgenv().SETTINGS.Blacklist, player.Name) ~= nil
        
        -- 处理人物热能
        if getgenv().SETTINGS.ChamsEnabled and isEnemy then
            if not h then
                h = Instance.new("Highlight", player.Character); h.Name = "LUA_Chams"
                h.FillTransparency = 0.5; h.OutlineTransparency = 0
            end
            
            local targetPart = GetTargetPart(player.Character, getgenv().SETTINGS.TargetPart)
            if targetPart then
                local visible = IsVisible(targetPart, player.Character)
                
                if isBlacklisted then
                    -- 黑名单强制极高危颜色
                    h.FillColor = Color3.fromRGB(15, 15, 15)
                    h.OutlineColor = Color3.fromRGB(255, 0, 0)
                elseif getgenv().SETTINGS.RainbowChams then
                    local rainbowColor = Color3.fromHSV((tick() % 5) / 5, 1, 1)
                    h.FillColor = rainbowColor; h.OutlineColor = rainbowColor
                else
                    if CurrentTarget and CurrentTarget == player.Character then
                        h.FillColor = getgenv().SETTINGS.TargetColor; h.OutlineColor = Color3.new(1,1,1)
                    elseif visible then
                        h.FillColor = getgenv().SETTINGS.VisibleColor; h.OutlineColor = getgenv().SETTINGS.VisibleColor
                    else
                        h.FillColor = getgenv().SETTINGS.HiddenColor; h.OutlineColor = getgenv().SETTINGS.HiddenColor
                    end
                end
            end
            h.Enabled = true
        elseif h then 
            h.Enabled = false 
        end
        
        -- 处理黑名单头顶红色浮空文字警告
        local tag = player.Character:FindFirstChild("YYJ_BlacklistTag")
        if isBlacklisted then
            if not tag then
                tag = Instance.new("BillboardGui", player.Character)
                tag.Name = "YYJ_BlacklistTag"
                tag.Size = UDim2.new(0, 100, 0, 40)
                tag.StudsOffset = Vector3.new(0, 3.5, 0)
                tag.AlwaysOnTop = true
                local txt = Instance.new("TextLabel", tag)
                txt.Size = UDim2.new(1, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.Text = "⚠️ 黑名单目标 ⚠️"
                txt.TextColor3 = Color3.fromRGB(255, 50, 50)
                txt.TextStrokeTransparency = 0
                txt.Font = Enum.Font.GothamBold
                txt.TextSize = 14
            end
        else
            if tag then tag:Destroy() end
        end
    end
end)

-- --- UI 逻辑 ---
local function LoadTab(id)
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    TabTitle.Text = id == "Combat" and "战斗增强" or (id == "Visuals" and "视觉增强" or "杂项设定")
    
    if id == "Combat" then
        CreateToggle("开启自瞄 (AIMBOT)", "AimbotEnabled", Scroll)
        CreateToggle("智能漏打 (AUTO BONE)", "AutoBone", Scroll) 
        CreateToggle("自动扳机 (TRIGGERBOT)", "TriggerBot", Scroll)
        CreateToggle("静默自瞄/瞬间拉枪 (SILENT AIM)", "SilentAim", Scroll)
        CreateToggle("360全方位锁定 (IGNORE FOV)", "IgnoreFOV", Scroll)
        CreateToggle("掩体检查 (WALL CHECK)", "WallCheck", Scroll)
        CreateSlider("自瞄范围 (FOV)", "FOV", 30, 800, Scroll)
        CreateSlider("平滑速度 (SMOOTH)", "Smoothness", 0, 100, Scroll)
        
        -- V23: 加入全新的视觉玩家选择器
        CreatePlayerSelector(Scroll)
        
        CreateKeybind("自瞄热键", "AimbotKey", Scroll)
    elseif id == "Visuals" then
        CreateToggle("显示自瞄圈 (SHOW FOV)", "ShowFOV", Scroll)
        CreateToggle("人物热能 (CHAMS)", "ChamsEnabled", Scroll)
        CreateToggle("彩虹热能 (RAINBOW)", "RainbowChams", Scroll)
        CreateToggle("团队检查 (TEAM)", "TeamCheck", Scroll)
    elseif id == "Misc" then
        CreateToggle("强制第三人称 (THIRD PERSON)", "ThirdPerson", Scroll)
        CreateToggle("视角稳定 (STEADY VIEW)", "SteadyView", Scroll)
        CreateToggle("伪陀螺旋转 (SPINBOT)", "Spinbot", Scroll)
        CreateSlider("旋转速度 (SPIN SPEED)", "SpinSpeed", 5, 100, Scroll)
        
        CreateToggle("移速修改 (WALKSPEED)", "WalkSpeedEnabled", Scroll)
        CreateSlider("移动速度 (SPEED)", "WalkSpeed", 16, 250, Scroll)
        CreateToggle("跳跃修改 (JUMP POWER)", "JumpPowerEnabled", Scroll)
        CreateSlider("跳跃高度 (POWER)", "JumpPower", 50, 300, Scroll)
        CreateKeybind("菜单热键", "MenuKey", Scroll)
    end
end

local function SidebarBtn(name, id, y)
    local B = Instance.new("TextButton", Sidebar)
    B.Size = UDim2.new(1, -20, 0, 40); B.Position = UDim2.new(0, 10, 0, y); B.BackgroundTransparency = 1; B.Text = name; B.Font = Enum.Font.GothamMedium; B.TextColor3 = Color3.new(0.6, 0.6, 0.6); B.TextSize = 13
    B.MouseButton1Click:Connect(function()
        for _, x in pairs(Sidebar:GetChildren()) do if x:IsA("TextButton") then x.TextColor3 = Color3.new(0.6,0.6,0.6) end end
        B.TextColor3 = Color3.new(1,1,1); LoadTab(id)
    end)
end

SidebarBtn("战斗增强", "Combat", 100); SidebarBtn("视觉增强", "Visuals", 150); SidebarBtn("杂项设定", "Misc", 200)
LoadTab("Combat")

-- 事件监听与 UI 拖拽
UserInputService.InputBegan:Connect(function(input)
    if IsBinding then
        local key = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode) or input.UserInputType
        if key ~= Enum.KeyCode.Unknown and key ~= Enum.UserInputType.MouseMovement then
            getgenv().SETTINGS[BindingTarget] = key; IsBinding = false; BindingTarget = nil
        end
    elseif input.KeyCode == getgenv().SETTINGS.MenuKey then MainFrame.Visible = not MainFrame.Visible end
end)

local drag, dStart, sPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dStart = input.Position; sPos = MainFrame.Position end
end)
UserInputService.InputChanged:Connect(function(input)
    if activeSlider and input.UserInputType == Enum.UserInputType.MouseMovement then activeSlider(input) end
    if drag and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dStart
        MainFrame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then activeSlider = nil; drag = false end
end)

print("LUA.OS V23.0 注入成功。已加载可视化黑名单选择器与高危透视标记！")
