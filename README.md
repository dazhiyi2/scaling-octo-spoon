local ui = loadstring(game:HttpGet("https://pastebin.com/raw/S4bCk6GT"))()

local uiName = "Car Factory Tycoon! 作者:dazhiyi2";
local themes = {
[1] = "Serpent",
[2] = "Synapse",
[3] = "Sentinel",
[4] = "Midnight",
[5] = "Ocean",
[6] = "GrapeTheme",
[7] = "BloodTheme",
[8] = "LightTheme",
[9] = "DarkTheme",
}

local main = ui.CreateLib(uiName, themes[7]); 
local tab = main:NewTab("传送带一");
local tab2 = main:NewTab("传送带二");
local tab3 = main:NewTab("传送带三");
local tab4 = main:NewTab("选项四");


local sec = tab:NewSection('合集脚本', false);

sec:NewButton("放金属","按钮说明", function()
    local args = {
    [1] = "Metal"
}
game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Collect:InvokeServer(unpack(args))local args = {
    [1] = workspace.Tycoons.Yellow.Model.Lines.Conveyor1
}
game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Drop:InvokeServer(unpack(args))
end)


sec:NewButton("放玻璃","按钮说明", function()
    
    local args = {
    [1] = "Glass"
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Collect:InvokeServer(unpack(args))local args = {
    [1] = workspace.Tycoons.Yellow.Model.Lines.Conveyor1
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Drop:InvokeServer(unpack(args))
end)


local sec = tab2:NewSection('合集脚本', false);

sec:NewButton("放金属","按钮说明", function()
     local args = {
    [1] = "Metal"
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Collect:InvokeServer(unpack(args))local args = {
    [1] = workspace.Tycoons.Yellow.Model.Lines.Conveyor2
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Drop:InvokeServer(unpack(args))
end)

sec:NewButton("放玻璃","按钮说明", function()
      local args = {
    [1] = "Glass"
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Collect:InvokeServer(unpack(args))local args = {
    [1] = workspace.Tycoons.Yellow.Model.Lines.Conveyor2
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Drop:InvokeServer(unpack(args))
end)


local sec = tab3:NewSection('合集脚本', false);

sec:NewButton("放金属","按钮说明", function()
    local args = {
    [1] = "Metal"
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Collect:InvokeServer(unpack(args))
     local args = {
    [1] = workspace.Tycoons.Red.Model.Lines.Conveyor3
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Drop:InvokeServer(unpack(args))
end)

sec:NewButton("放玻璃","按钮说明", function()
     local args = {
    [1] = "Glass"
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Collect:InvokeServer(unpack(args))
     local args = {
    [1] = workspace.Tycoons.Red.Model.Lines.Conveyor3
}

game:GetService("ReplicatedStorage").Packages.Knit.Services.MaterialService.RF.Drop:InvokeServer(unpack(args))
end)
