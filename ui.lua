local Library = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

function Library:Create(cfg)
    local config = cfg or {}
    local windowname = config.Name or "UI Library"
    local togglekey = config.ToggleKey or Enum.KeyCode.RightShift
    local configname = config.ConfigName or "UILib_Config.json"
    
    if getgenv().UI_Loaded then
        getgenv().UI_Loaded:Destroy()
    end
    
    local ui = {}
    ui.modules = {}
    ui.activemodules = {}
    ui.themeobjects = {}
    ui.connections = {}
    ui.open = true
    ui.categories = {}
    
    ui.settings = {
        themecolor = config.ThemeColor or Color3.fromRGB(255, 0, 0),
        rgb = config.RGB or {R = 255, G = 0, B = 0},
        arraylistenabled = true,
        rainbowarray = true,
        blurenabled = false,
        blursize = 15,
        arrayscale = 1.0,
        arraypos = {ScaleX = 1, OffsetX = -10, ScaleY = 0, OffsetY = 45},
        watermarkpos = {ScaleX = 1, OffsetX = -10, ScaleY = 0, OffsetY = 10},
        categorypos = {}
    }
    
    ui.savedconfig = {}
    
    local function loadconfig()
        pcall(function()
            if isfile and isfile(configname) then
                ui.savedconfig = HttpService:JSONDecode(readfile(configname))
                if ui.savedconfig.Theme then
                    ui.settings.rgb = ui.savedconfig.Theme.RGB or ui.settings.rgb
                    ui.settings.themecolor = Color3.fromRGB(ui.settings.rgb.R, ui.settings.rgb.G, ui.settings.rgb.B)
                    ui.settings.arraylistenabled = ui.savedconfig.Theme.ArrayListEnabled ~= false
                    ui.settings.blurenabled = ui.savedconfig.Theme.BlurEnabled or false
                    ui.settings.blursize = ui.savedconfig.Theme.BlurSize or 15
                    ui.settings.arrayscale = ui.savedconfig.Theme.ArrayScale or 1.0
                    if ui.savedconfig.Theme.ArrayPos then ui.settings.arraypos = ui.savedconfig.Theme.ArrayPos end
                    if ui.savedconfig.Theme.WatermarkPos then ui.settings.watermarkpos = ui.savedconfig.Theme.WatermarkPos end
                    if ui.savedconfig.Theme.CategoryPos then ui.settings.categorypos = ui.savedconfig.Theme.CategoryPos end
                end
            end
        end)
        ui.settings.rainbowarray = true
    end
    
    local function saveconfig()
        pcall(function()
            if writefile then
                ui.savedconfig.Theme = {
                    RGB = ui.settings.rgb,
                    ArrayListEnabled = ui.settings.arraylistenabled,
                    BlurEnabled = ui.settings.blurenabled,
                    BlurSize = ui.settings.blursize,
                    ArrayScale = ui.settings.arrayscale,
                    ArrayPos = ui.settings.arraypos,
                    WatermarkPos = ui.settings.watermarkpos,
                    CategoryPos = ui.settings.categorypos
                }
                writefile(configname, HttpService:JSONEncode(ui.savedconfig))
            end
        end)
    end
    
    loadconfig()
    
    local function trackconn(conn)
        table.insert(ui.connections, conn)
        return conn
    end
    
    local function registertheme(obj, prop)
        table.insert(ui.themeobjects, {Object = obj, Property = prop})
        obj[prop] = ui.settings.themecolor
    end
    
    local function updatetheme()
        ui.settings.themecolor = Color3.fromRGB(ui.settings.rgb.R, ui.settings.rgb.G, ui.settings.rgb.B)
        for _, item in pairs(ui.themeobjects) do
            if item.Object and item.Object.Parent then
                item.Object[item.Property] = ui.settings.themecolor
            end
        end
        saveconfig()
    end
    
    local screengui = Instance.new("ScreenGui")
    screengui.Name = windowname
    screengui.Parent = CoreGui
    screengui.ResetOnSpawn = false
    screengui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.gui = screengui
    
    local blur = Instance.new("BlurEffect")
    blur.Name = "UIBlur"
    blur.Size = 0
    blur.Parent = Lighting
    blur.Enabled = false
    ui.blur = blur
    
    local function updateblur()
        if ui.settings.blurenabled and ui.open then
            blur.Enabled = true
            blur.Size = ui.settings.blursize
        else
            blur.Enabled = false
        end
    end
    
    local notifcontainer = Instance.new("Frame")
    notifcontainer.Name = "Notifications"
    notifcontainer.Parent = screengui
    notifcontainer.BackgroundTransparency = 1
    notifcontainer.Position = UDim2.new(1, -220, 1, -20)
    notifcontainer.Size = UDim2.new(0, 200, 1, 0)
    notifcontainer.AnchorPoint = Vector2.new(0, 1)
    notifcontainer.ZIndex = 100
    
    local notiflayout = Instance.new("UIListLayout")
    notiflayout.Parent = notifcontainer
    notiflayout.SortOrder = Enum.SortOrder.LayoutOrder
    notiflayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notiflayout.Padding = UDim.new(0, 5)
    
    function ui:Notify(title, text, duration)
        local notif = Instance.new("Frame")
        notif.Parent = notifcontainer
        notif.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        notif.BorderSizePixel = 0
        notif.Size = UDim2.new(1, 0, 0, 50)
        notif.BackgroundTransparency = 0.1
        
        local line = Instance.new("Frame")
        line.Parent = notif
        line.BackgroundColor3 = ui.settings.themecolor
        line.BorderSizePixel = 0
        line.Size = UDim2.new(0, 2, 1, 0)
        registertheme(line, "BackgroundColor3")
        
        local titlelbl = Instance.new("TextLabel")
        titlelbl.Parent = notif
        titlelbl.BackgroundTransparency = 1
        titlelbl.Position = UDim2.new(0, 10, 0, 5)
        titlelbl.Size = UDim2.new(1, -10, 0, 20)
        titlelbl.Font = Enum.Font.GothamBold
        titlelbl.Text = title
        titlelbl.TextColor3 = ui.settings.themecolor
        titlelbl.TextSize = 14
        titlelbl.TextXAlignment = Enum.TextXAlignment.Left
        registertheme(titlelbl, "TextColor3")
        
        local textlbl = Instance.new("TextLabel")
        textlbl.Parent = notif
        textlbl.BackgroundTransparency = 1
        textlbl.Position = UDim2.new(0, 10, 0, 25)
        textlbl.Size = UDim2.new(1, -10, 0, 20)
        textlbl.Font = Enum.Font.Gotham
        textlbl.Text = text
        textlbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        textlbl.TextSize = 12
        textlbl.TextXAlignment = Enum.TextXAlignment.Left
        
        notif.Position = UDim2.new(1, 0, 0, 0)
        TweenService:Create(notif, TweenInfo.new(0.3), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        
        task.delay(duration or 3, function()
            if notif and notif.Parent then
                TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
                TweenService:Create(titlelbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                TweenService:Create(textlbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
                TweenService:Create(line, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
                task.wait(0.3)
                if notif and notif.Parent then notif:Destroy() end
            end
        end)
    end
    
    local function makedraggable(frame, settingkey)
        local dragging, dragstart, startpos, draginput = false
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragstart = input.Position
                startpos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if settingkey then
                            local pos = frame.Position
                            ui.settings[settingkey] = {ScaleX = pos.X.Scale, OffsetX = pos.X.Offset, ScaleY = pos.Y.Scale, OffsetY = pos.Y.Offset}
                            saveconfig()
                        end
                    end
                end)
            end
        end)
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then draginput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == draginput and dragging then
                local delta = input.Position - dragstart
                frame.Position = UDim2.new(startpos.X.Scale, startpos.X.Offset + delta.X, startpos.Y.Scale, startpos.Y.Offset + delta.Y)
            end
        end)
    end
    
    local function makecategorydraggable(frame, catname)
        local dragging, dragstart, startpos, draginput = false
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragstart = input.Position
                startpos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        local pos = frame.Position
                        ui.settings.categorypos[catname] = {ScaleX = pos.X.Scale, OffsetX = pos.X.Offset, ScaleY = pos.Y.Scale, OffsetY = pos.Y.Offset}
                        saveconfig()
                    end
                end)
            end
        end)
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then draginput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == draginput and dragging then
                local delta = input.Position - dragstart
                frame.Position = UDim2.new(startpos.X.Scale, startpos.X.Offset + delta.X, startpos.Y.Scale, startpos.Y.Offset + delta.Y)
            end
        end)
    end
    
    local wmpos = ui.settings.watermarkpos
    local watermark = Instance.new("TextLabel")
    watermark.Name = "Watermark"
    watermark.Parent = screengui
    watermark.BackgroundTransparency = 1
    watermark.Position = UDim2.new(wmpos.ScaleX, wmpos.OffsetX, wmpos.ScaleY, wmpos.OffsetY)
    watermark.Size = UDim2.new(0, 200, 0, 30)
    watermark.AnchorPoint = Vector2.new(1, 0)
    watermark.Font = Enum.Font.GothamBold
    watermark.Text = windowname
    watermark.TextSize = 24 * ui.settings.arrayscale
    watermark.TextStrokeTransparency = 0.5
    watermark.TextXAlignment = Enum.TextXAlignment.Right
    watermark.ZIndex = 10
    watermark.Active = true
    registertheme(watermark, "TextColor3")
    makedraggable(watermark, "watermarkpos")
    ui.watermark = watermark
    
    local arrpos = ui.settings.arraypos
    local arrayframe = Instance.new("Frame")
    arrayframe.Name = "ArrayList"
    arrayframe.Parent = screengui
    arrayframe.BackgroundTransparency = 1
    arrayframe.Position = UDim2.new(arrpos.ScaleX, arrpos.OffsetX, arrpos.ScaleY, arrpos.OffsetY)
    arrayframe.Size = UDim2.new(0, 200 * ui.settings.arrayscale, 1, 0)
    arrayframe.AnchorPoint = Vector2.new(1, 0)
    arrayframe.ZIndex = 1
    arrayframe.Active = true
    
    local arraylayout = Instance.new("UIListLayout")
    arraylayout.Parent = arrayframe
    arraylayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    arraylayout.SortOrder = Enum.SortOrder.LayoutOrder
    arraylayout.Padding = UDim.new(0, 2)
    makedraggable(arrayframe, "arraypos")
    
    local function updatearray()
        if not ui.settings.arraylistenabled then
            for _, v in pairs(arrayframe:GetChildren()) do
                if v:IsA("Frame") then v:Destroy() end
            end
            return
        end
        local scale = ui.settings.arrayscale or 1.0
        arrayframe.Size = UDim2.new(0, 200 * scale, 1, 0)
        watermark.TextSize = 24 * scale
        table.sort(ui.activemodules, function(a, b)
            local ta = a.Name .. (a.Suffix and " ["..a.Suffix.."]" or "")
            local tb = b.Name .. (b.Suffix and " ["..b.Suffix.."]" or "")
            if #ta == #tb then return ta < tb end
            return #ta > #tb
        end)
        local existing = {}
        for _, c in pairs(arrayframe:GetChildren()) do
            if c:IsA("Frame") then existing[c.Name] = c end
        end
        for i, mod in ipairs(ui.activemodules) do
            local txt = mod.Name .. (mod.Suffix and " ["..mod.Suffix.."]" or "")
            local frame = existing[mod.Name]
            if frame then
                frame.LayoutOrder = i
                local s = frame:FindFirstChild("Shadow")
                local m = frame:FindFirstChild("Main")
                if s then s.Text = txt; s.TextSize = 18 * scale end
                if m then m.Text = txt; m.TextSize = 18 * scale end
                existing[mod.Name] = nil
            else
                local container = Instance.new("Frame")
                container.Name = mod.Name
                container.Parent = arrayframe
                container.BackgroundTransparency = 1
                container.LayoutOrder = i
                container.Size = UDim2.new(1, 0, 0, 0)
                local shadow = Instance.new("TextLabel")
                shadow.Name = "Shadow"
                shadow.Parent = container
                shadow.BackgroundTransparency = 1
                shadow.Font = Enum.Font.GothamBold
                shadow.Text = txt
                shadow.TextSize = 18 * scale
                shadow.TextColor3 = Color3.new(0, 0, 0)
                shadow.TextTransparency = 1
                shadow.Size = UDim2.new(1, 0, 1, 0)
                shadow.Position = UDim2.new(0, 1 * scale, 0, 1 * scale)
                shadow.TextXAlignment = Enum.TextXAlignment.Right
                shadow.ZIndex = 10
                local main = Instance.new("TextLabel")
                main.Name = "Main"
                main.Parent = container
                main.BackgroundTransparency = 1
                main.Font = Enum.Font.GothamBold
                main.Text = txt
                main.TextSize = 18 * scale
                main.TextColor3 = ui.settings.themecolor
                main.TextTransparency = 1
                main.Size = UDim2.new(1, 0, 1, 0)
                main.TextXAlignment = Enum.TextXAlignment.Right
                main.ZIndex = 11
                local bar = Instance.new("Frame")
                bar.Name = "Bar"
                bar.Parent = container
                bar.BackgroundColor3 = ui.settings.themecolor
                bar.BackgroundTransparency = 1
                bar.BorderSizePixel = 0
                bar.Size = UDim2.new(0, 2 * scale, 1, 0)
                bar.Position = UDim2.new(1, 2 * scale, 0, 0)
                bar.ZIndex = 12
                local tweeninfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                TweenService:Create(container, tweeninfo, {Size = UDim2.new(1, 0, 0, 20 * scale)}):Play()
                TweenService:Create(shadow, tweeninfo, {TextTransparency = 0.5}):Play()
                TweenService:Create(main, tweeninfo, {TextTransparency = 0}):Play()
                TweenService:Create(bar, tweeninfo, {BackgroundTransparency = 0}):Play()
            end
        end
        for name, frame in pairs(existing) do
            frame.Name = frame.Name .. "_Removing"
            local s = frame:FindFirstChild("Shadow")
            local m = frame:FindFirstChild("Main")
            local b = frame:FindFirstChild("Bar")
            local tweeninfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            if s then TweenService:Create(s, tweeninfo, {TextTransparency = 1}):Play() end
            if m then TweenService:Create(m, tweeninfo, {TextTransparency = 1}):Play() end
            if b then TweenService:Create(b, tweeninfo, {BackgroundTransparency = 1}):Play() end
            local t = TweenService:Create(frame, tweeninfo, {Size = UDim2.new(1, 0, 0, 0)})
            t:Play()
            t.Completed:Connect(function() if frame and frame.Parent then frame:Destroy() end end)
        end
    end
    
    trackconn(RunService.RenderStepped:Connect(function()
        if not ui.settings.arraylistenabled then return end
        local h, s, v = ui.settings.themecolor:ToHSV()
        local frames = {}
        for _, c in pairs(arrayframe:GetChildren()) do
            if c:IsA("Frame") and not c.Name:find("_Removing") then table.insert(frames, c) end
        end
        table.sort(frames, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
        for i, container in ipairs(frames) do
            local main = container:FindFirstChild("Main")
            local bar = container:FindFirstChild("Bar")
            if main and bar then
                local brightnessdecrease = (i - 1) * 0.05
                local newv = math.clamp(v - brightnessdecrease, 0.3, 1)
                local color = Color3.fromHSV(h, s, newv)
                main.TextColor3 = color
                bar.BackgroundColor3 = color
            end
        end
    end))
    
    function ui:CreateCategory(name, x)
        local savedpos = ui.settings.categorypos[name]
        local frame = Instance.new("Frame")
        frame.Name = name .. "_Category"
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BorderSizePixel = 0
        if savedpos then
            frame.Position = UDim2.new(savedpos.ScaleX, savedpos.OffsetX, savedpos.ScaleY, savedpos.OffsetY)
        else
            frame.Position = UDim2.new(0, x, 0, 50)
        end
        frame.Size = UDim2.new(0, 130, 0, 30)
        frame.Parent = screengui
        frame.ZIndex = 1
        frame.Active = true
        local headerline = Instance.new("Frame")
        headerline.Name = "HeaderLine"
        headerline.Size = UDim2.new(1, 0, 0, 2)
        headerline.Position = UDim2.new(0, 0, 0, 0)
        headerline.BorderSizePixel = 0
        headerline.Parent = frame
        headerline.ZIndex = 2
        registertheme(headerline, "BackgroundColor3")
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Text = name
        title.Size = UDim2.new(1, 0, 1, 0)
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.Parent = frame
        title.ZIndex = 5
        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Position = UDim2.new(0, 0, 1, 0)
        container.Size = UDim2.new(1, 0, 0, 0)
        container.BackgroundTransparency = 1
        container.Parent = frame
        local layout = Instance.new("UIListLayout")
        layout.Parent = container
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        makecategorydraggable(frame, name)
        local cat = {frame = frame, container = container}
        ui.categories[name] = cat
        return cat
    end
    
    function ui:CreateModule(category, name, callback, defaultkey, isbutton)
        local parent = category.container
        if isbutton then
            local btn = Instance.new("TextButton")
            btn.Text = name
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.BorderSizePixel = 0
            btn.Parent = parent
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
                btn.BackgroundColor3 = ui.settings.themecolor
                task.wait(0.1)
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            end)
            return nil
        end
        local moduledata = {Enabled = false, Key = defaultkey, Name = name, Suffix = nil}
        if ui.savedconfig[name] then
            moduledata.Enabled = ui.savedconfig[name].Enabled or false
            if ui.savedconfig[name].Key then
                pcall(function() moduledata.Key = Enum.KeyCode[ui.savedconfig[name].Key] end)
            end
        end
        local btn = Instance.new("TextButton")
        btn.Text = name
        btn.BackgroundColor3 = moduledata.Enabled and ui.settings.themecolor or Color3.fromRGB(35, 35, 35)
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.TextColor3 = moduledata.Enabled and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.Parent = parent
        btn.ZIndex = 2
        local settingsframe = Instance.new("Frame")
        settingsframe.Name = name .. "_Settings"
        settingsframe.Parent = parent
        settingsframe.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        settingsframe.BorderSizePixel = 0
        settingsframe.Size = UDim2.new(1, 0, 0, 0)
        settingsframe.Visible = false
        settingsframe.ClipsDescendants = true
        settingsframe.ZIndex = 3
        local settingslayout = Instance.new("UIListLayout")
        settingslayout.Parent = settingsframe
        settingslayout.SortOrder = Enum.SortOrder.LayoutOrder
        local function updateheight()
            if not settingsframe.Visible then return end
            local h = 0
            for _, c in pairs(settingsframe:GetChildren()) do
                if c:IsA("GuiObject") then h = h + c.Size.Y.Offset end
            end
            settingsframe.Size = UDim2.new(1, 0, 0, h)
        end
        local bindbtn = Instance.new("TextButton")
        bindbtn.Parent = settingsframe
        bindbtn.Size = UDim2.new(1, 0, 0, 20)
        bindbtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        bindbtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        bindbtn.Font = Enum.Font.Gotham
        bindbtn.TextSize = 12
        bindbtn.Text = "Keybind: " .. (moduledata.Key and moduledata.Key.Name or "None")
        bindbtn.BorderSizePixel = 0
        bindbtn.ZIndex = 3
        local binding = false
        bindbtn.MouseButton1Click:Connect(function()
            if binding then return end
            binding = true
            bindbtn.Text = "Press any key..."
            local inputconn
            inputconn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    moduledata.Key = input.KeyCode
                    binding = false
                    bindbtn.Text = "Keybind: " .. input.KeyCode.Name
                    ui.savedconfig[name] = ui.savedconfig[name] or {}
                    ui.savedconfig[name].Key = input.KeyCode.Name
                    saveconfig()
                    inputconn:Disconnect()
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    binding = false
                    bindbtn.Text = "Keybind: " .. (moduledata.Key and moduledata.Key.Name or "None")
                    inputconn:Disconnect()
                end
            end)
        end)
        function moduledata:CreateSlider(sname, min, max, default, slidercallback)
            local savedval = default
            if ui.savedconfig[name] and ui.savedconfig[name].Sliders and ui.savedconfig[name].Sliders[sname] then
                savedval = ui.savedconfig[name].Sliders[sname]
            end
            local sliderframe = Instance.new("Frame")
            sliderframe.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            sliderframe.Size = UDim2.new(1, 0, 0, 35)
            sliderframe.BorderSizePixel = 0
            sliderframe.Parent = settingsframe
            sliderframe.ZIndex = 3
            local label = Instance.new("TextLabel")
            label.Text = sname .. ": " .. savedval
            label.Size = UDim2.new(1, 0, 0, 15)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.Font = Enum.Font.Gotham
            label.TextSize = 12
            label.Parent = sliderframe
            label.ZIndex = 3
            local slidebg = Instance.new("TextButton")
            slidebg.Text = ""
            slidebg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            slidebg.Size = UDim2.new(0.9, 0, 0, 6)
            slidebg.Position = UDim2.new(0.05, 0, 0.6, 0)
            slidebg.BorderSizePixel = 0
            slidebg.Parent = sliderframe
            slidebg.ZIndex = 4
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((savedval - min) / (max - min), 0, 1, 0)
            fill.BorderSizePixel = 0
            fill.Parent = slidebg
            fill.ZIndex = 5
            registertheme(fill, "BackgroundColor3")
            if slidercallback then slidercallback(savedval) end
            local dragging = false
            local function updateslider(input)
                local pos = math.clamp((input.Position.X - slidebg.AbsolutePosition.X) / slidebg.AbsoluteSize.X, 0, 1)
                local val = math.floor(min + (max - min) * pos * 10) / 10
                fill.Size = UDim2.new(pos, 0, 1, 0)
                label.Text = sname .. ": " .. val
                ui.savedconfig[name] = ui.savedconfig[name] or {}
                ui.savedconfig[name].Sliders = ui.savedconfig[name].Sliders or {}
                ui.savedconfig[name].Sliders[sname] = val
                saveconfig()
                if slidercallback then slidercallback(val) end
            end
            slidebg.MouseButton1Down:Connect(function() dragging = true end)
            trackconn(UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end))
            trackconn(UserInputService.InputChanged:Connect(function(i)
                if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then updateslider(i) end
            end))
            updateheight()
        end
        function moduledata:CreateToggle(tname, options, defaultidx, togglecallback)
            local savedidx = defaultidx
            if ui.savedconfig[name] and ui.savedconfig[name].Toggles and ui.savedconfig[name].Toggles[tname] then
                savedidx = ui.savedconfig[name].Toggles[tname]
            end
            local togglebtn = Instance.new("TextButton")
            togglebtn.Parent = settingsframe
            togglebtn.Size = UDim2.new(1, 0, 0, 20)
            togglebtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            togglebtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            togglebtn.Font = Enum.Font.Gotham
            togglebtn.TextSize = 12
            togglebtn.BorderSizePixel = 0
            togglebtn.ZIndex = 3
            local currentidx = savedidx or 1
            local function updatetext()
                togglebtn.Text = tname .. ": " .. options[currentidx]
                ui.savedconfig[name] = ui.savedconfig[name] or {}
                ui.savedconfig[name].Toggles = ui.savedconfig[name].Toggles or {}
                ui.savedconfig[name].Toggles[tname] = currentidx
                saveconfig()
                if togglecallback then
                    togglecallback(options[currentidx])
                    moduledata.Suffix = options[currentidx]
                    if moduledata.Enabled then updatearray() end
                end
            end
            updatetext()
            togglebtn.MouseButton1Click:Connect(function()
                currentidx = currentidx + 1
                if currentidx > #options then currentidx = 1 end
                updatetext()
            end)
            updateheight()
        end
        btn.MouseButton2Click:Connect(function()
            settingsframe.Visible = not settingsframe.Visible
            if settingsframe.Visible then updateheight() else settingsframe.Size = UDim2.new(1, 0, 0, 0) end
        end)
        function moduledata:Toggle(state)
            if state == nil then state = not moduledata.Enabled end
            moduledata.Enabled = state
            ui.savedconfig[name] = ui.savedconfig[name] or {}
            ui.savedconfig[name].Enabled = state
            saveconfig()
            if state then
                btn.BackgroundColor3 = ui.settings.themecolor
                btn.TextColor3 = Color3.new(1, 1, 1)
                local found = false
                for _, obj in pairs(ui.themeobjects) do if obj.Object == btn then found = true break end end
                if not found then table.insert(ui.themeobjects, {Object = btn, Property = "BackgroundColor3"}) end
                if not table.find(ui.activemodules, moduledata) then table.insert(ui.activemodules, moduledata) end
            else
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                for i, obj in pairs(ui.themeobjects) do if obj.Object == btn then table.remove(ui.themeobjects, i) break end end
                for i, v in ipairs(ui.activemodules) do if v == moduledata then table.remove(ui.activemodules, i) break end end
            end
            updatearray()
            if callback then callback(state) end
        end
        if moduledata.Enabled then
            local found = false
            for _, obj in pairs(ui.themeobjects) do if obj.Object == btn then found = true break end end
            if not found then table.insert(ui.themeobjects, {Object = btn, Property = "BackgroundColor3"}) end
            if not table.find(ui.activemodules, moduledata) then table.insert(ui.activemodules, moduledata) end
            updatearray()
            if callback then task.spawn(function() callback(true) end) end
        end
        btn.MouseButton1Click:Connect(function() moduledata:Toggle() end)
        trackconn(UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and moduledata.Key and input.KeyCode == moduledata.Key and not binding then moduledata:Toggle() end
        end))
        ui.modules[name] = moduledata
        return moduledata
    end
    
    function ui:SetTheme(r, g, b)
        ui.settings.rgb = {R = r, G = g, B = b}
        updatetheme()
    end
    
    function ui:ToggleArrayList(state)
        ui.settings.arraylistenabled = state
        updatearray()
        saveconfig()
    end
    
    function ui:SetScale(scale)
        ui.settings.arrayscale = scale
        updatearray()
        saveconfig()
    end
    
    function ui:ResetPositions()
        ui.settings.arraypos = {ScaleX = 1, OffsetX = -10, ScaleY = 0, OffsetY = 45}
        ui.settings.watermarkpos = {ScaleX = 1, OffsetX = -10, ScaleY = 0, OffsetY = 10}
        ui.settings.categorypos = {}
        arrayframe.Position = UDim2.new(1, -10, 0, 45)
        watermark.Position = UDim2.new(1, -10, 0, 10)
        local xpos = 50
        for name, cat in pairs(ui.categories) do
            cat.frame.Position = UDim2.new(0, xpos, 0, 50)
            xpos = xpos + 140
        end
        saveconfig()
    end
    
    function ui:Destroy()
        for _, conn in pairs(ui.connections) do if conn then pcall(function() conn:Disconnect() end) end end
        if blur then blur:Destroy() end
        if screengui then screengui:Destroy() end
        getgenv().UI_Loaded = nil
    end
    
    trackconn(UserInputService.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == togglekey then
            ui.open = not ui.open
            for _, cat in pairs(ui.categories) do cat.frame.Visible = ui.open end
            updateblur()
        end
    end))
    
    getgenv().UI_Loaded = ui
    return ui
end

return Library
