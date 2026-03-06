-- LUA.OS - FPS EXTREME SUITE (V12.3 TARGET FOCUS EDITION)
-- Fixed Flick rollback, added permanent pink highlight for target focus and embedded UI user panel.

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

-- --- Global Settings ---
getgenv().SETTINGS = {
    AimbotEnabled = true,
    FlickTrigger = false,   
    TriggerBot = false,     
    Smoothness = 15,
    FOV = 150,
    WallCheck = true,
    ShowFOV = true,
    TeamCheck = true,
    ChamsEnabled = true,
    VisibleColor = Color3.fromRGB(255, 0, 0), -- Visible enemy color
    HiddenColor = Color3.fromRGB(255, 255, 255), -- Occluded enemy color
    TargetColor = Color3.fromRGB(255, 150, 200), -- Target focus color (Pink)
    TargetPart = "Head",
    AimbotKey = Enum.UserInputType.MouseButton2,
    MenuKey = Enum.KeyCode.Insert
}

local OriginalCFrame = nil 
local IsFlicking = false
local IsBinding = false
local BindingTarget = nil 
local CurrentTarget = nil -- Tracks the closest player in FOV in real-time

-- --- Utility Functions ---
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

-- --- Drawing Initialization ---
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Transparency = 1
FOVCircle.Color = Color3.new(1, 1, 1)

-- --- UI Construction ---
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "LUA_OS_GUI"
ScreenGui.ResetOnSpawn = false

-- Main Container
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 620, 0, 520)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.new(1,1,1); Stroke.Transparency = 0.9

-- Sidebar
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Sidebar.BorderSizePixel = 0
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 16)

-- User Information Panel (Embedded in Sidebar)
local UserPanel = Instance.new("Frame", Sidebar)
UserPanel.Size = UDim2.new(1, -20, 0, 60)
UserPanel.Position = UDim2.new(0, 10, 1, -70)
UserPanel.BackgroundTransparency = 1

local AvatarImg = Instance.new("ImageLabel", UserPanel)
AvatarImg.Size = UDim2.new(0, 40, 0, 40)
AvatarImg.Position = UDim2.new(0, 5, 0.5, -20)
AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. lp.UserId .. "&w=150&h=150"
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

local DisplayName = Instance.new("TextLabel", UserPanel)
DisplayName.Size = UDim2.new(1, -55, 0, 18); DisplayName.Position = UDim2.new(0, 55, 0.5, -18)
DisplayName.Text = lp.DisplayName; DisplayName.Font = Enum.Font.GothamBold; DisplayName.TextColor3 = Color3.new(1, 1, 1); DisplayName.TextSize = 13; DisplayName.TextXAlignment = Enum.TextXAlignment.Left; DisplayName.BackgroundTransparency = 1

local UserName = Instance.new("TextLabel", UserPanel)
UserName.Size = UDim2.new(1, -55, 0, 15); UserName.Position = UDim2.new(0, 55, 0.5, 2)
UserName.Text = "@" .. lp.Name; UserName.Font = Enum.Font.GothamMedium; UserName.TextColor3 = Color3.new(0.5, 0.5, 0.5); UserName.TextSize = 11; UserName.TextXAlignment = Enum.TextXAlignment.Left; UserName.BackgroundTransparency = 1

local Logo = Instance.new("TextLabel", Sidebar)
Logo.Text = "LUA.OS"
Logo.Font = Enum.Font.GothamBold
Logo.TextColor3 = Color3.new(1, 1, 1); Logo.TextSize = 22
Logo.Size = UDim2.new(1, 0, 0, 80); Logo.BackgroundTransparency = 1

-- Content Area
local Content = Instance.new("Frame", MainFrame)
Content.Position = UDim2.new(0, 180, 0, 0)
Content.Size = UDim2.new(1, -180, 1, 0)
Content.BackgroundTransparency = 1

local TabTitle = Instance.new("TextLabel", Content)
TabTitle.Size = UDim2.new(1, -60, 0, 60); TabTitle.Position = UDim2.new(0, 30, 0, 10)
TabTitle.Text = "COMBAT"; TabTitle.Font = Enum.Font.GothamBold; TabTitle.TextColor3 = Color3.new(0.6, 0.6, 0.6); TabTitle.TextSize = 12; TabTitle.TextXAlignment = Enum.TextXAlignment.Left; TabTitle.BackgroundTransparency = 1

local Scroll = Instance.new("ScrollingFrame", Content)
Scroll.Size = UDim2.new(1, -40, 1, -80); Scroll.Position = UDim2.new(0, 20, 0, 70)
Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 0; Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local Layout = Instance.new("UIListLayout", Scroll); Layout.Padding = UDim.new(0, 8)

-- --- UI Components ---
local function CreateToggle(name, setting, parent)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 55); Frame.BackgroundColor3 = Color3.new(1, 1, 1); Frame.BackgroundTransparency = 0.97
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0.7, 0, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0)
    Label.Text = name; Label.Font = Enum.Font.GothamMedium; Label.TextColor3 = Color3.new(1, 1, 1); Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.BackgroundTransparency = 1
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

local function CreateSlider(name, setting, min, max, parent)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 65); Frame.BackgroundColor3 = Color3.new(1,1,1); Frame.BackgroundTransparency = 0.97
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -20, 0, 30); Label.Position = UDim2.new(0, 15, 0, 5)
    Label.Text = name .. ": " .. tostring(getgenv().SETTINGS[setting]); Label.Font = Enum.Font.GothamMedium; Label.TextColor3 = Color3.new(1,1,1); Label.TextSize = 12; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.BackgroundTransparency = 1
    local Track = Instance.new("Frame", Frame)
    Track.Size = UDim2.new(1, -30, 0, 4); Track.Position = UDim2.new(0, 15, 0, 45); Track.BackgroundColor3 = Color3.new(1, 1, 1); Track.BackgroundTransparency = 0.9
    Instance.new("UICorner", Track)
    local Fill = Instance.new("Frame", Track)
    Fill.Size = UDim2.new((getgenv().SETTINGS[setting] - min) / (max - min), 0, 1, 0); Fill.BackgroundColor3 = Color3.new(1, 1, 1); Instance.new("UICorner", Fill)
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local move = UserInputService.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement then
                    local pos = math.clamp((m.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    local val = math.floor(min + (max - min) * pos)
                    getgenv().SETTINGS[setting] = val
                    Fill.Size = UDim2.new(pos, 0, 1, 0); Label.Text = name .. ": " .. tostring(val)
                end
            end)
            local endcon; endcon = UserInputService.InputEnded:Connect(function(e)
                if e.UserInputType == Enum.UserInputType.MouseButton1 then move:Disconnect(); endcon:Disconnect() end
            end)
        end
    end)
end

local function CreateKeybind(name, parent, setting)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 55); Frame.BackgroundColor3 = Color3.new(1,1,1); Frame.BackgroundTransparency = 0.97
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(1, -120, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0); Label.Text = name; Label.Font = Enum.Font.GothamMedium; Label.TextColor3 = Color3.new(1, 1, 1); Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.BackgroundTransparency = 1
    local BindBtn = Instance.new("TextButton", Frame)
    BindBtn.Size = UDim2.new(0, 95, 0, 30); BindBtn.Position = UDim2.new(1, -110, 0.5, -15)
    BindBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); BindBtn.Text = GetKeyName(getgenv().SETTINGS[setting]); BindBtn.Font = Enum.Font.GothamBold; BindBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8); BindBtn.TextSize = 11
    Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 6)
    BindBtn.MouseButton1Click:Connect(function()
        if IsBinding then return end
        IsBinding = true; BindingTarget = setting; BindBtn.Text = "..."; BindBtn.TextColor3 = Color3.new(1, 1, 0)
    end)
    RunService.Heartbeat:Connect(function()
        if not IsBinding or BindingTarget ~= setting then
            BindBtn.Text = GetKeyName(getgenv().SETTINGS[setting])
            BindBtn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
        end
    end)
end

local function CreateSelector(name, setting, options, parent)
    local Frame = Instance.new("Frame", parent)
    Frame.Size = UDim2.new(1, 0, 0, 55); Frame.BackgroundColor3 = Color3.new(1, 1, 1); Frame.BackgroundTransparency = 0.97
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size = UDim2.new(0.6, 0, 1, 0); Label.Position = UDim2.new(0, 15, 0, 0)
    Label.Text = name; Label.Font = Enum.Font.GothamMedium; Label.TextColor3 = Color3.new(1, 1, 1); Label.TextSize = 13; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.BackgroundTransparency = 1
    local Btn = Instance.new("TextButton", Frame)
    Btn.Size = UDim2.new(0, 110, 0, 30); Btn.Position = UDim2.new(1, -125, 0.5, -15)
    Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); Btn.Text = tostring(getgenv().SETTINGS[setting]); Btn.Font = Enum.Font.GothamBold; Btn.TextColor3 = Color3.new(1, 1, 1); Btn.TextSize = 11
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local currentIndex = 1
    for i, v in ipairs(options) do if v == getgenv().SETTINGS[setting] then currentIndex = i end end
    Btn.MouseButton1Click:Connect(function()
        currentIndex = (currentIndex % #options) + 1
        getgenv().SETTINGS[setting] = options[currentIndex]
        Btn.Text = tostring(options[currentIndex])
    end)
end

-- --- Core Features (Visibility & Targeting) ---
local function IsVisible(part, targetCharacter)
    local ignoreList = {camera, lp.Character, targetCharacter}
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = ignoreList
    rayParams.IgnoreWater = true
    local origin = camera.CFrame.Position
    local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

local function GetClosestTarget()
    local target, dist = nil, math.huge
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if getgenv().SETTINGS.TeamCheck and player.Team == lp.Team then continue end
            local p = player.Character:FindFirstChild(getgenv().SETTINGS.TargetPart)
            if p then
                local pos, onScreen = camera:WorldToViewportPoint(p.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if mag < getgenv().SETTINGS.FOV then
                        if getgenv().SETTINGS.WallCheck and not IsVisible(p, player.Character) then continue end
                        if mag < dist then target = p; dist = mag end
                    end
                end
            end
        end
    end
    return target
end

-- --- Flick Engine & Aimbot Loop ---
RunService.PreRender:Connect(function()
    FOVCircle.Visible = getgenv().SETTINGS.ShowFOV
    FOVCircle.Radius = getgenv().SETTINGS.FOV
    FOVCircle.Position = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

    local aimKey = getgenv().SETTINGS.AimbotKey
    local isPressed = (tostring(aimKey):find("MouseButton") and UserInputService:IsMouseButtonPressed(aimKey)) or UserInputService:IsKeyDown(aimKey)

    -- Real-time targeting (Highlighting without keypress)
    local closestTarget = GetClosestTarget()
    CurrentTarget = closestTarget and closestTarget.Parent or nil

    -- Flick Logic
    if getgenv().SETTINGS.FlickTrigger and isPressed then
        if not IsFlicking then
            if closestTarget then
                IsFlicking = true
                OriginalCFrame = camera.CFrame
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, closestTarget.Position)
                mouse1press()
                task.wait(0.01)
                mouse1release()
                camera.CFrame = OriginalCFrame
                task.delay(0.1, function() IsFlicking = false end)
            end
        end
        return
    end

    -- Regular Aimbot Logic
    if getgenv().SETTINGS.AimbotEnabled and isPressed and not IsFlicking then
        if closestTarget then
            local smooth = 1 - (getgenv().SETTINGS.Smoothness / 105)
            camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(camera.CFrame.Position, closestTarget.Position), smooth)
            
            if getgenv().SETTINGS.TriggerBot then
                local mouseRay = camera:ViewportPointToRay(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                local result = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000)
                if result and result.Instance:IsDescendantOf(closestTarget.Parent) then
                    mouse1press()
                    task.wait(0.01)
                    mouse1release()
                end
            end
        end
    end
end)

-- --- Dynamic Visuals (Pink Focus Highlight) ---
RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player == lp or not player.Character then continue end
        local isEnemy = not (getgenv().SETTINGS.TeamCheck and player.Team == lp.Team)
        local h = player.Character:FindFirstChild("LUA_Chams")
        
        if getgenv().SETTINGS.ChamsEnabled and isEnemy and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if not h then
                h = Instance.new("Highlight", player.Character); h.Name = "LUA_Chams"
                h.FillTransparency = 0.5; h.OutlineTransparency = 0
            end
            
            local head = player.Character:FindFirstChild("Head")
            if head then
                local visible = IsVisible(head, player.Character)
                local baseCol = visible and getgenv().SETTINGS.VisibleColor or getgenv().SETTINGS.HiddenColor
                
                -- Target Focus logic: If player is the closest in FOV, color them Pink permanently
                if CurrentTarget and CurrentTarget == player.Character then
                    h.FillColor = getgenv().SETTINGS.TargetColor
                    h.OutlineColor = getgenv().SETTINGS.TargetColor
                else
                    h.FillColor = baseCol
                    h.OutlineColor = baseCol
                end
            end
            h.Enabled = true
        elseif h then 
            h.Enabled = false 
        end
    end
end)

-- --- Menu Management ---
local function LoadTab(id)
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    TabTitle.Text = id:upper()
    if id == "Combat" then
        CreateToggle("开启自瞄 (AIMBOT)", "AimbotEnabled", Scroll)
        CreateSelector("锁定部位 (TARGET)", "TargetPart", {"Head", "HumanoidRootPart"}, Scroll)
        CreateToggle("掩体检查 (WALL CHECK)", "WallCheck", Scroll)
        CreateToggle("模拟静默甩枪 (FLICK)", "FlickTrigger", Scroll)
        CreateToggle("自动扳机 (TRIGGER)", "TriggerBot", Scroll)
        CreateSlider("自瞄范围 (FOV)", "FOV", 30, 800, Scroll)
        CreateSlider("平滑速度 (SMOOTH)", "Smoothness", 0, 100, Scroll)
        CreateKeybind("自瞄热键", Scroll, "AimbotKey")
        CreateKeybind("菜单热键", Scroll, "MenuKey")
    elseif id == "Visuals" then
        CreateToggle("显示自瞄圈 (FOV)", "ShowFOV", Scroll)
        CreateToggle("智能热能 (DYNAMIC CHAMS)", "ChamsEnabled", Scroll)
        CreateToggle("团队检查 (TEAM)", "TeamCheck", Scroll)
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

SidebarBtn("战斗增强", "Combat", 100); SidebarBtn("视觉增强", "Visuals", 150)
LoadTab("Combat")

-- Global Input Listeners
UserInputService.InputBegan:Connect(function(input)
    if IsBinding then
        local key = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode) or input.UserInputType
        if key ~= Enum.KeyCode.Unknown and key ~= Enum.UserInputType.MouseMovement then
            getgenv().SETTINGS[BindingTarget] = key; IsBinding = false; BindingTarget = nil
        end
    elseif input.KeyCode == getgenv().SETTINGS.MenuKey then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Drag Support
local drag, dStart, sPos
MainFrame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true; dStart = i.Position; sPos = MainFrame.Position end end)
UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
    local delta = i.Position - dStart
    MainFrame.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)

print("LUA.OS V12.3 READY: ALWAYS-ON TARGET PREVIEW ACTIVE.")
