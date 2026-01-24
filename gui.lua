--[[
    CyberLib - Compact GUI Library
    
    local CyberLib = loadstring(...)()
    local Window = CyberLib:CreateWindow({ Title = "Hub", ConfigFolder = "MyScript", SaveConfig = true })
    local Tab = Window:AddTab({ Name = "Main", Icon = "home" })
    Tab:AddToggle({ Name = "Speed", Default = false, Flag = "SpeedHack", Callback = function(v) end })
    Tab:AddSlider({ Name = "WalkSpeed", Min = 16, Max = 500, Default = 16, Flag = "Speed", Callback = function(v) end })
    Window:SetTheme("Neon")
    
    Themes: Neon, Ice, Gold, Lava, Forest, CleanBlue
]]

local CyberLib = {}
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled

local function GetGuiParent()
    local ok, r = pcall(function() return gethui and gethui() or CoreGui end)
    return ok and r or CoreGui
end

local function RandName()
    local c, r = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", ""
    for _ = 1, math.random(12, 18) do r = r .. c:sub(math.random(1, #c), math.random(1, #c)) end
    return r
end

local Themes = {
    Neon = { Primary = Color3.fromRGB(12,12,18), Secondary = Color3.fromRGB(24,24,36), Tertiary = Color3.fromRGB(36,36,54), Accent = Color3.fromRGB(0,255,180), Danger = Color3.fromRGB(255,90,120), Warning = Color3.fromRGB(255,220,120), Text = Color3.fromRGB(255,255,255), TextDim = Color3.fromRGB(190,200,210), TextMuted = Color3.fromRGB(120,140,150), Border = Color3.fromRGB(70,90,95) },
    Ice = { Primary = Color3.fromRGB(235,245,255), Secondary = Color3.fromRGB(215,230,245), Tertiary = Color3.fromRGB(195,215,235), Accent = Color3.fromRGB(90,170,255), Danger = Color3.fromRGB(255,120,120), Warning = Color3.fromRGB(255,200,120), Text = Color3.fromRGB(25,35,50), TextDim = Color3.fromRGB(70,90,120), TextMuted = Color3.fromRGB(130,150,170), Border = Color3.fromRGB(170,195,220) },
    Gold = { Primary = Color3.fromRGB(28,24,18), Secondary = Color3.fromRGB(45,38,28), Tertiary = Color3.fromRGB(65,55,40), Accent = Color3.fromRGB(255,200,80), Danger = Color3.fromRGB(255,110,110), Warning = Color3.fromRGB(255,230,150), Text = Color3.fromRGB(255,255,245), TextDim = Color3.fromRGB(220,210,180), TextMuted = Color3.fromRGB(170,160,130), Border = Color3.fromRGB(110,95,70) },
    Lava = { Primary = Color3.fromRGB(25,12,10), Secondary = Color3.fromRGB(45,20,15), Tertiary = Color3.fromRGB(70,30,22), Accent = Color3.fromRGB(255,120,50), Danger = Color3.fromRGB(255,80,80), Warning = Color3.fromRGB(255,200,100), Text = Color3.fromRGB(255,245,240), TextDim = Color3.fromRGB(220,190,180), TextMuted = Color3.fromRGB(170,140,130), Border = Color3.fromRGB(120,60,50) },
    Forest = { Primary = Color3.fromRGB(14,20,16), Secondary = Color3.fromRGB(24,38,30), Tertiary = Color3.fromRGB(38,60,48), Accent = Color3.fromRGB(120,220,150), Danger = Color3.fromRGB(255,110,110), Warning = Color3.fromRGB(255,230,120), Text = Color3.fromRGB(245,255,250), TextDim = Color3.fromRGB(190,220,205), TextMuted = Color3.fromRGB(140,170,155), Border = Color3.fromRGB(70,110,90) },
    CleanBlue = { Primary = Color3.fromRGB(245,248,252), Secondary = Color3.fromRGB(225,232,242), Tertiary = Color3.fromRGB(205,218,235), Accent = Color3.fromRGB(60,130,255), Danger = Color3.fromRGB(220,80,80), Warning = Color3.fromRGB(220,180,90), Text = Color3.fromRGB(20,30,45), TextDim = Color3.fromRGB(70,90,120), TextMuted = Color3.fromRGB(130,150,175), Border = Color3.fromRGB(185,200,220) },
}

local Theme, ThemeName = Themes.Neon, "Neon"
local Icons = { home = "rbxassetid://7733960981", settings = "rbxassetid://7734053495" }
local function GetIcon(n) return Icons[n] or Icons.home end

local SizeScales = { [1] = 0.5, [2] = 0.75, [3] = 1 }
local CurrentScale = 1.0
local function S(v) return math.floor(v * CurrentScale) end

local function Create(c, p, ch)
    local i = Instance.new(c)
    for k, v in pairs(p or {}) do if k ~= "Parent" then i[k] = v end end
    for _, x in ipairs(ch or {}) do x.Parent = i end
    if p and p.Parent then i.Parent = p.Parent end
    return i
end

local function Tween(i, p, d, easingStyle)
    if not i or not p then return end
    local style = easingStyle or Enum.EasingStyle.Quad
    local validProps = {}
    for k, v in pairs(p) do
        if i[k] ~= nil then
            validProps[k] = v
        end
    end
    if next(validProps) then
        return TweenService:Create(i, TweenInfo.new(d or 0.15, style, Enum.EasingDirection.Out), validProps)
    end
end
local function Corner(p, r) return Create("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p }) end
local function Stroke(p, c, t, tr) return Create("UIStroke", { Color = c or Theme.Border, Thickness = t or 1, Transparency = tr or 0, Parent = p }) end
local function Pad(p, l, r, t, b) return Create("UIPadding", { PaddingLeft = UDim.new(0, l or 8), PaddingRight = UDim.new(0, r or 8), PaddingTop = UDim.new(0, t or 8), PaddingBottom = UDim.new(0, b or 8), Parent = p }) end

local function Drag(f, h, cb)
    local d, di, ds, sp
    h.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            d = true; ds = i.Position; sp = f.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false; if cb then cb() end end end)
        end
    end)
    h.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then di = i end end)
    UIS.InputChanged:Connect(function(i) if i == di and d then local x = i.Position - ds; f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + x.X, sp.Y.Scale, sp.Y.Offset + x.Y) end end)
end

function CyberLib:CreateWindow(cfg)
    cfg = cfg or {}
    cfg.Title = cfg.Title or "CyberLib"
    cfg.Size = cfg.Size or (IS_MOBILE and UDim2.new(0, 300, 0, 420) or UDim2.new(0, 400, 0, 520))
    cfg.Position = cfg.Position or UDim2.new(1, -420, 0, 20)
    cfg.ConfigFolder = cfg.ConfigFolder or "CyberLib"
    cfg.SaveConfig = cfg.SaveConfig or false
    
    local W = {}
    local Tabs, CurTab, Exp, Flags = {}, nil, true, {}
    local TObj, DynUpdaters = {}, {}
    local CfgPath = cfg.ConfigFolder .. "/config.json"
    local ElementOrder = 0
    local SavedConfig = nil
    
    local CurrentSizeOption = 2
    
    if cfg.SaveConfig then
        pcall(function()
            if isfile(CfgPath) then
                SavedConfig = HttpService:JSONDecode(readfile(CfgPath))
                if SavedConfig.pos then
                    cfg.Position = UDim2.new(SavedConfig.pos.xs or 1, SavedConfig.pos.xo or -420, SavedConfig.pos.ys or 0, SavedConfig.pos.yo or 20)
                end
                if SavedConfig.theme and Themes[SavedConfig.theme] then
                    Theme = Themes[SavedConfig.theme]; ThemeName = SavedConfig.theme
                end
                if SavedConfig.sizeOption then
                    CurrentSizeOption = SavedConfig.sizeOption
                    CurrentScale = SizeScales[CurrentSizeOption] or 1.0
                end
            end
        end)
    end
    
    local function Save()
        if not cfg.SaveConfig then return end
        local d = { theme = ThemeName, minimized = not Exp, sizeOption = CurrentSizeOption, flags = {} }
        for f, o in pairs(Flags) do if o.Get then local v = o:Get(); d.flags[f] = typeof(v) == "EnumItem" and { t = "k", v = v.Name } or v end end
        local p = W.Main and W.Main.Position
        if p then d.pos = { xs = p.X.Scale, xo = p.X.Offset, ys = p.Y.Scale, yo = p.Y.Offset } end
        pcall(function() if not isfolder(cfg.ConfigFolder) then makefolder(cfg.ConfigFolder) end; writefile(CfgPath, HttpService:JSONEncode(d)) end)
    end
    
    local function Load()
        if not cfg.SaveConfig or not SavedConfig then return end
        if SavedConfig.flags then
            for f, v in pairs(SavedConfig.flags) do
                if Flags[f] and Flags[f].Set then
                    if typeof(v) == "table" and v.t == "k" then
                        pcall(function() Flags[f]:Set(Enum.KeyCode[v.v]) end)
                    else
                        Flags[f]:Set(v)
                    end
                end
            end
        end
    end
    
    local function UpdTheme()
        for _, o in ipairs(TObj) do pcall(function() o.I[o.P] = Theme[o.K] end) end
        for _, fn in ipairs(DynUpdaters) do pcall(fn) end
    end
    
    local function Track(i, p, k) table.insert(TObj, { I = i, P = p, K = k }) end
    local function AddDynamic(fn) table.insert(DynUpdaters, fn) end
    
    local function NextOrder() ElementOrder = ElementOrder + 1; return ElementOrder end
    
    local Gui = Create("ScreenGui", { Name = RandName(), Parent = GetGuiParent(), ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false })
    
    local Main = Create("Frame", { Size = cfg.Size, Position = cfg.Position, BackgroundColor3 = Theme.Primary, Parent = Gui })
    Corner(Main, 12); local MS = Stroke(Main, Theme.Border, 1, 0.2)
    Track(Main, "BackgroundColor3", "Primary"); Track(MS, "Color", "Border")
    W.Main = Main
    
    local UIScale = Create("UIScale", { Scale = CurrentScale, Parent = Main })
    
    local HH = IS_MOBILE and 48 or 56
    local Head = Create("Frame", { Size = UDim2.new(1, 0, 0, HH), BackgroundColor3 = Theme.Secondary, Parent = Main })
    Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Head })
    local HeadFill = Create("Frame", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -16), BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0, Parent = Head })
    Track(Head, "BackgroundColor3", "Secondary"); Track(HeadFill, "BackgroundColor3", "Secondary")
    
    local TW = IS_MOBILE and 52 or 60
    
    -- Status indicator no header, alinhado com a sidebar (cores fixas)
    local SS = IS_MOBILE and 10 or 12
    local StatusColors = { connected = Color3.fromRGB(80, 255, 120), disconnected = Color3.fromRGB(255, 80, 80), connecting = Color3.fromRGB(255, 180, 50), idle = Color3.fromRGB(120, 120, 120) }
    local Stat = Create("Frame", { Size = UDim2.new(0, SS, 0, SS), Position = UDim2.new(0, 6 + TW/2 - SS/2, 0.5, -SS/2), BackgroundColor3 = StatusColors.connected, Parent = Head })
    Corner(Stat, SS); local SG = Stroke(Stat, StatusColors.connected, 2, 0.4)
    
    -- Título centralizado no header (depois da sidebar)
    local Title = Create("TextLabel", { Size = UDim2.new(1, -TW - 60, 1, 0), Position = UDim2.new(0, TW + 10, 0, 0), BackgroundTransparency = 1, Text = cfg.Title, TextColor3 = Theme.Text, TextSize = IS_MOBILE and 18 or 20, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Center, Parent = Head })
    Track(Title, "TextColor3", "Text")
    
    local MinB = Create("TextButton", { Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(1, -46, 0.5, -18), BackgroundColor3 = Theme.Tertiary, Text = "", AutoButtonColor = false, Parent = Head })
    Corner(MinB, 8); Track(MinB, "BackgroundColor3", "Tertiary")
    local MinL = Create("Frame", { Size = UDim2.new(0, 16, 0, 2), Position = UDim2.new(0.5, -8, 0.5, -1), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = MinB }); Corner(MinL, 1)
    local MinV = Create("Frame", { Size = UDim2.new(0, 2, 0, 0), Position = UDim2.new(0.5, -1, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = MinB }); Corner(MinV, 1)
    Track(MinL, "BackgroundColor3", "Text"); Track(MinV, "BackgroundColor3", "Text")
    
    -- Sidebar com tabs
    local TabsC = Create("ScrollingFrame", { Size = UDim2.new(0, TW, 1, -HH - 10), Position = UDim2.new(0, 5, 0, HH + 5), BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.3, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Main })
    Corner(TabsC, 8); Track(TabsC, "BackgroundColor3", "Secondary")
    Create("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabsC })
    Pad(TabsC, 5, 5, 5, 5)
    
    local Cont = Create("Frame", { Size = UDim2.new(1, -TW - 15, 1, -HH - 10), Position = UDim2.new(0, TW + 10, 0, HH + 5), BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.2, Parent = Main })
    Corner(Cont, 8); Track(Cont, "BackgroundColor3", "Secondary")
    
    Drag(Main, Head, Save)
    
    local OSize = cfg.Size
    
    local function SetMinimized(min)
        Exp = not min
        if Exp then
            HeadFill.Visible = true
            Tween(Main, {Size = OSize}, 0.2):Play()
            Tween(MinV, {Size = UDim2.new(0, 2, 0, 0)}, 0.1):Play()
            TabsC.Visible = true; Cont.Visible = true
        else
            HeadFill.Visible = false
            Tween(Main, {Size = UDim2.new(0, cfg.Size.X.Offset, 0, HH)}, 0.2):Play()
            Tween(MinV, {Size = UDim2.new(0, 2, 0, 16)}, 0.1):Play()
            task.delay(0.08, function() if not Exp then TabsC.Visible = false; Cont.Visible = false end end)
        end
        Save()
    end
    
    MinB.MouseButton1Click:Connect(function() SetMinimized(Exp) end)
    
    -- Aplicar estado minimizado salvo
    if SavedConfig and SavedConfig.minimized then
        Exp = false
        Main.Size = UDim2.new(0, cfg.Size.X.Offset, 0, HH)
        MinV.Size = UDim2.new(0, 2, 0, 16)
        HeadFill.Visible = false
        TabsC.Visible = false; Cont.Visible = false
    end
    
    function W:SetTheme(n) if Themes[n] then Theme = Themes[n]; ThemeName = n; UpdTheme(); Save() end end
    function W:SetSize(opt)
        opt = tonumber(opt) or 2
        if opt < 1 then opt = 1 elseif opt > 3 then opt = 3 end
        CurrentSizeOption = opt
        CurrentScale = SizeScales[opt] or 1.0
        UIScale.Scale = CurrentScale
        Save()
    end
    function W:GetSizeOption() return CurrentSizeOption end
    function W:SaveConfig() Save() end
    function W:LoadConfig() Load() end
    function W:GetFlag(f) return Flags[f] end
    
    local TabOrder = 0
    function W:AddTab(tc)
        tc = tc or {}; tc.Name = tc.Name or "Tab"; tc.Icon = tc.Icon or "home"
        local Tab = {}
        local TS = IS_MOBILE and 42 or 50
        TabOrder = TabOrder + 1
        local TB = Create("TextButton", { Size = UDim2.new(0, TS, 0, TS), BackgroundColor3 = Theme.Tertiary, BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false, LayoutOrder = TabOrder, Parent = TabsC })
        Corner(TB, 8); local TSt = Stroke(TB, Theme.Border, 1, 0.5)
        local TI = Create("ImageLabel", { Size = UDim2.new(0, IS_MOBILE and 22 or 26, 0, IS_MOBILE and 22 or 26), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = GetIcon(tc.Icon), ImageColor3 = Theme.TextDim, Parent = TB })
        Track(TB, "BackgroundColor3", "Tertiary"); Track(TSt, "Color", "Border"); Track(TI, "ImageColor3", "TextDim")
        
        local TC = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = Cont })
        Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TC })
        Pad(TC, 8, 8, 8, 8)
        Track(TC, "ScrollBarImageColor3", "Accent")
        
        local ElemOrder = 0
        local function GetOrder() ElemOrder = ElemOrder + 1; return ElemOrder end
        
        local function Sel()
            for _, t in ipairs(Tabs) do t.B.BackgroundTransparency = 0.7; t.S.Color = Theme.Border; t.S.Transparency = 0.5; t.I.ImageColor3 = Theme.TextDim; t.C.Visible = false end
            TB.BackgroundTransparency = 0.2; TSt.Color = Theme.Accent; TSt.Transparency = 0; TI.ImageColor3 = Theme.Accent; TC.Visible = true; CurTab = Tab
        end
        
        TB.MouseButton1Click:Connect(Sel)
        TB.MouseEnter:Connect(function() if CurTab ~= Tab then Tween(TB, {BackgroundTransparency = 0.4}, 0.1):Play() end end)
        TB.MouseLeave:Connect(function() if CurTab ~= Tab then Tween(TB, {BackgroundTransparency = 0.7}, 0.1):Play() end end)
        
        table.insert(Tabs, { B = TB, S = TSt, I = TI, C = TC, Tab = Tab })
        if #Tabs == 1 then Sel() end
        
        function Tab:AddSection(name)
            local F = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = GetOrder(), Parent = TC })
            local L = Create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = (name or "Section"):upper(), TextColor3 = Theme.Accent, TextSize = IS_MOBILE and 12 or 14, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = F })
            Track(L, "TextColor3", "Accent")
            return F
        end
        
        function Tab:AddLabel(text)
            local F = Create("Frame", { Size = UDim2.new(1, 0, 0, IS_MOBILE and 24 or 28), BackgroundTransparency = 1, LayoutOrder = GetOrder(), Parent = TC })
            local L = Create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = text or "Label", TextColor3 = Theme.TextDim, TextSize = IS_MOBILE and 13 or 15, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = F })
            Track(L, "TextColor3", "TextDim")
            return { Set = function(_, t) L.Text = t end }
        end
        
        function Tab:AddParagraph(title, content)
            local F = Create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Tertiary, LayoutOrder = GetOrder(), Parent = TC })
            Corner(F, 8); Pad(F, 12, 12, 10, 10); Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = F })
            Track(F, "BackgroundColor3", "Tertiary")
            local TL = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = title or "Title", TextColor3 = Theme.Text, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = F })
            local CL = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = content or "Content", TextColor3 = Theme.TextDim, TextSize = IS_MOBILE and 12 or 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = F })
            Track(TL, "TextColor3", "Text"); Track(CL, "TextColor3", "TextDim")
            return { Set = function(_, t, c) TL.Text = t or TL.Text; CL.Text = c or CL.Text end }
        end
        
        function Tab:AddButton(c)
            c = c or {}
            local H = IS_MOBILE and 40 or 46
            local B = Create("TextButton", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = Theme.Tertiary, Text = c.Name or "Button", TextColor3 = Theme.Text, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamBold, AutoButtonColor = false, LayoutOrder = GetOrder(), Parent = TC })
            Corner(B, 8); local S = Stroke(B, Theme.Border, 1, 0.3)
            Track(B, "BackgroundColor3", "Tertiary"); Track(B, "TextColor3", "Text"); Track(S, "Color", "Border")
            B.MouseEnter:Connect(function() Tween(B, {BackgroundColor3 = Theme.Secondary}, 0.1):Play(); Tween(S, {Color = Theme.Accent, Transparency = 0}, 0.1):Play() end)
            B.MouseLeave:Connect(function() Tween(B, {BackgroundColor3 = Theme.Tertiary}, 0.1):Play(); Tween(S, {Color = Theme.Border, Transparency = 0.3}, 0.1):Play() end)
            B.MouseButton1Click:Connect(function() Tween(B, {BackgroundColor3 = Theme.Accent}, 0.05):Play(); task.wait(0.05); Tween(B, {BackgroundColor3 = Theme.Tertiary}, 0.1):Play(); if c.Callback then c.Callback() end end)
            return B
        end
        
        function Tab:AddToggle(c)
            c = c or {}
            local En = c.Default or false
            local H = IS_MOBILE and 44 or 50
            local KW, KH = IS_MOBILE and 48 or 54, IS_MOBILE and 24 or 28
            local KS = KH - 6
            
            local F = Create("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = Theme.Tertiary, LayoutOrder = GetOrder(), Parent = TC })
            Corner(F, 8); local FS = Stroke(F, Theme.Border, 1, 0.3)
            Track(F, "BackgroundColor3", "Tertiary"); Track(FS, "Color", "Border")
            
            local L = Create("TextLabel", { Size = UDim2.new(1, -KW - 20, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = c.Name or "Toggle", TextColor3 = Theme.Text, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = F })
            
            local TBg = Create("Frame", { Size = UDim2.new(0, KW, 0, KH), Position = UDim2.new(1, -KW - 10, 0.5, -KH/2), BackgroundColor3 = Theme.Secondary, Parent = F })
            Corner(TBg, KH/2); local TSt = Stroke(TBg, Theme.Border, 2, 0)
            
            local Knob = Create("Frame", { Size = UDim2.new(0, KS, 0, KS), Position = UDim2.new(0, 3, 0.5, -KS/2), BackgroundColor3 = Theme.TextMuted, Parent = TBg })
            Corner(Knob, KS/2)
            
            local TB = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = TBg })
            
            local function Upd()
                if En then
                    TBg.BackgroundColor3 = Theme.Accent; TSt.Color = Theme.Accent
                    Knob.Position = UDim2.new(1, -KS - 3, 0.5, -KS/2); Knob.BackgroundColor3 = Color3.new(1,1,1)
                    L.TextColor3 = Theme.Accent
                else
                    TBg.BackgroundColor3 = Theme.Secondary; TSt.Color = Theme.Border
                    Knob.Position = UDim2.new(0, 3, 0.5, -KS/2); Knob.BackgroundColor3 = Theme.TextMuted
                    L.TextColor3 = Theme.Text
                end
            end
            
            AddDynamic(Upd)
            
            local function Tog() 
                En = not En
                if En then
                    Tween(TBg, {BackgroundColor3 = Theme.Accent}, 0.15):Play()
                    Tween(TSt, {Color = Theme.Accent}, 0.15):Play()
                    Tween(Knob, {Position = UDim2.new(1, -KS - 3, 0.5, -KS/2), BackgroundColor3 = Color3.new(1,1,1)}, 0.15):Play()
                    L.TextColor3 = Theme.Accent
                else
                    Tween(TBg, {BackgroundColor3 = Theme.Secondary}, 0.15):Play()
                    Tween(TSt, {Color = Theme.Border}, 0.15):Play()
                    Tween(Knob, {Position = UDim2.new(0, 3, 0.5, -KS/2), BackgroundColor3 = Theme.TextMuted}, 0.15):Play()
                    L.TextColor3 = Theme.Text
                end
                if c.Callback then c.Callback(En) end; Save() 
            end
            TB.MouseButton1Click:Connect(Tog)
            Create("TextButton", { Size = UDim2.new(1, -KW - 20, 1, 0), BackgroundTransparency = 1, Text = "", Parent = F }).MouseButton1Click:Connect(Tog)
            Upd()
            
            local obj = { Set = function(_, v) En = v; Upd(); if c.Callback then c.Callback(En) end end, Get = function() return En end }
            if c.Flag then Flags[c.Flag] = obj end
            return obj
        end
        
        function Tab:AddSlider(c)
            c = c or {}
            local Val = c.Default or c.Min or 0
            local H = IS_MOBILE and 56 or 64
            local BH = IS_MOBILE and 6 or 8
            
            local F = Create("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = Theme.Tertiary, LayoutOrder = GetOrder(), Parent = TC })
            Corner(F, 8); local FS = Stroke(F, Theme.Border, 1, 0.3)
            Track(F, "BackgroundColor3", "Tertiary"); Track(FS, "Color", "Border")
            
            local NL = Create("TextLabel", { Size = UDim2.new(1, -60, 0, 22), Position = UDim2.new(0, 14, 0, 6), BackgroundTransparency = 1, Text = c.Name or "Slider", TextColor3 = Theme.Text, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = F })
            local VL = Create("TextLabel", { Size = UDim2.new(0, 55, 0, 22), Position = UDim2.new(1, -60, 0, 6), BackgroundTransparency = 1, Text = tostring(Val), TextColor3 = Theme.Accent, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = F })
            Track(NL, "TextColor3", "Text"); Track(VL, "TextColor3", "Accent")
            
            local Bar = Create("Frame", { Size = UDim2.new(1, -28, 0, BH), Position = UDim2.new(0, 14, 0, H - BH - 12), BackgroundColor3 = Theme.Secondary, Parent = F })
            Corner(Bar, BH/2); Track(Bar, "BackgroundColor3", "Secondary")
            
            local Fill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = Bar })
            Corner(Fill, BH/2); Track(Fill, "BackgroundColor3", "Accent")
            
            local KS = BH + 6
            local Knob = Create("Frame", { Size = UDim2.new(0, KS, 0, KS), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1,1,1), Parent = Bar })
            Corner(Knob, KS/2); local KSt = Stroke(Knob, Theme.Accent, 2, 0)
            Track(KSt, "Color", "Accent")
            
            local function UpdS(pct, sv)
                pct = math.clamp(pct, 0, 1)
                local rng = (c.Max or 100) - (c.Min or 0)
                local raw = (c.Min or 0) + (rng * pct)
                local steps = math.floor((raw - (c.Min or 0)) / (c.Increment or 1) + 0.5)
                Val = math.clamp((c.Min or 0) + (steps * (c.Increment or 1)), c.Min or 0, c.Max or 100)
                local dp = (Val - (c.Min or 0)) / rng
                Fill.Size = UDim2.new(dp, 0, 1, 0)
                Knob.Position = UDim2.new(dp, 0, 0.5, 0)
                VL.Text = tostring(Val)
                if c.Callback then c.Callback(Val) end
                if sv then Save() end
            end
            
            local ip = (Val - (c.Min or 0)) / ((c.Max or 100) - (c.Min or 0))
            Fill.Size = UDim2.new(ip, 0, 1, 0); Knob.Position = UDim2.new(ip, 0, 0.5, 0)
            
            local Dr = false
            Bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then Dr = true; UpdS((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, false) end end)
            UIS.InputChanged:Connect(function(i) if Dr and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then UpdS((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, false) end end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then if Dr then Save() end; Dr = false end end)
            
            local obj = { Set = function(_, v) UpdS((v - (c.Min or 0)) / ((c.Max or 100) - (c.Min or 0)), false) end, Get = function() return Val end }
            if c.Flag then Flags[c.Flag] = obj end
            return obj
        end
        
        function Tab:AddTextbox(c)
            c = c or {}
            local H = IS_MOBILE and 68 or 76
            local IH = IS_MOBILE and 30 or 36
            
            local F = Create("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = Theme.Tertiary, LayoutOrder = GetOrder(), Parent = TC })
            Corner(F, 8); local FS = Stroke(F, Theme.Border, 1, 0.3)
            Track(F, "BackgroundColor3", "Tertiary"); Track(FS, "Color", "Border")
            
            local NL = Create("TextLabel", { Size = UDim2.new(1, -18, 0, 22), Position = UDim2.new(0, 14, 0, 6), BackgroundTransparency = 1, Text = c.Name or "Textbox", TextColor3 = Theme.Text, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = F })
            Track(NL, "TextColor3", "Text")
            
            local IC = Create("Frame", { Size = UDim2.new(1, -28, 0, IH), Position = UDim2.new(0, 14, 0, H - IH - 10), BackgroundColor3 = Theme.Secondary, ClipsDescendants = true, Parent = F })
            Corner(IC, 6); local ISt = Stroke(IC, Theme.Border, 1, 0)
            Track(IC, "BackgroundColor3", "Secondary"); Track(ISt, "Color", "Border")
            
            local Inp = Create("TextBox", { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = c.Default or "", PlaceholderText = c.Placeholder or "Type...", PlaceholderColor3 = Theme.TextMuted, TextColor3 = Theme.Text, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamSemibold, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = IC })
            Track(Inp, "TextColor3", "Text"); Track(Inp, "PlaceholderColor3", "TextMuted")
            
            Inp.Focused:Connect(function() Tween(ISt, {Color = Theme.Accent}, 0.1):Play(); Tween(IC, {BackgroundColor3 = Theme.Tertiary}, 0.1):Play() end)
            Inp.FocusLost:Connect(function() Tween(ISt, {Color = Theme.Border}, 0.1):Play(); Tween(IC, {BackgroundColor3 = Theme.Secondary}, 0.1):Play(); if c.Callback then c.Callback(Inp.Text) end; Save() end)
            
            local obj = { Set = function(_, t) Inp.Text = t end, Get = function() return Inp.Text end }
            if c.Flag then Flags[c.Flag] = obj end
            return obj
        end
        
        function Tab:AddDropdown(c)
            c = c or {}
            local Sel = c.Default or (c.Options and c.Options[1] or "")
            local Op = false
            local DH = IS_MOBILE and 44 or 50
            local OH = IS_MOBILE and 34 or 40
            local OptBtns = {}
            
            local F = Create("Frame", { Size = UDim2.new(1, 0, 0, DH), BackgroundColor3 = Theme.Tertiary, ClipsDescendants = true, LayoutOrder = GetOrder(), Parent = TC })
            Corner(F, 8); local FS = Stroke(F, Theme.Border, 1, 0.3)
            Track(F, "BackgroundColor3", "Tertiary"); Track(FS, "Color", "Border")
            
            local Head = Create("TextButton", { Size = UDim2.new(1, 0, 0, DH), BackgroundTransparency = 1, Text = "", Parent = F })
            local NL = Create("TextLabel", { Size = UDim2.new(0.5, -8, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = c.Name or "Dropdown", TextColor3 = Theme.Text, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = Head })
            local SL = Create("TextLabel", { Size = UDim2.new(0.5, -36, 1, 0), Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 1, Text = Sel, TextColor3 = Theme.Accent, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = Head })
            Track(NL, "TextColor3", "Text"); Track(SL, "TextColor3", "Accent")
            
            local AC = Create("Frame", { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -28, 0.5, -9), BackgroundTransparency = 1, Rotation = 0, Parent = Head })
            local A1 = Create("Frame", { Size = UDim2.new(0, 9, 0, 2), Position = UDim2.new(0.5, -6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Rotation = 45, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = AC }); Corner(A1, 1)
            local A2 = Create("Frame", { Size = UDim2.new(0, 9, 0, 2), Position = UDim2.new(0.5, -3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Rotation = -45, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = AC }); Corner(A2, 1)
            Track(A1, "BackgroundColor3", "Accent"); Track(A2, "BackgroundColor3", "Accent")
            
            local Opts = Create("Frame", { Size = UDim2.new(1, -14, 0, 0), Position = UDim2.new(0, 7, 0, DH), BackgroundTransparency = 1, Parent = F })
            Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = Opts })
            
            local function UpdateOptColors()
                for _, btn in ipairs(OptBtns) do
                    if btn and btn.Parent then
                        btn.BackgroundColor3 = Theme.Secondary
                        btn.TextColor3 = btn.Text == Sel and Theme.Accent or Theme.Text
                    end
                end
            end
            
            AddDynamic(UpdateOptColors)
            
            local function MkOpt(txt)
                local O = Create("TextButton", { Size = UDim2.new(1, 0, 0, OH), BackgroundColor3 = Theme.Secondary, Text = txt, TextColor3 = txt == Sel and Theme.Accent or Theme.Text, TextSize = IS_MOBILE and 13 or 15, Font = Enum.Font.GothamSemibold, AutoButtonColor = false, Parent = Opts })
                Corner(O, 6)
                table.insert(OptBtns, O)
                O.MouseEnter:Connect(function() Tween(O, {BackgroundColor3 = Theme.Tertiary}, 0.08):Play() end)
                O.MouseLeave:Connect(function() Tween(O, {BackgroundColor3 = Theme.Secondary}, 0.08):Play() end)
                O.MouseButton1Click:Connect(function()
                    Sel = txt; SL.Text = txt
                    UpdateOptColors()
                    if c.Callback then c.Callback(Sel) end
                    Op = false; Tween(F, {Size = UDim2.new(1, 0, 0, DH)}, 0.15):Play(); Tween(AC, {Rotation = 0}, 0.15):Play(); Save()
                end)
                return O
            end
            for _, o in ipairs(c.Options or {}) do MkOpt(o) end
            
            Head.MouseButton1Click:Connect(function()
                Op = not Op
                local th = Op and (DH + (#(c.Options or {}) * (OH + 4)) + 6) or DH
                Tween(F, {Size = UDim2.new(1, 0, 0, th)}, 0.15):Play()
                Tween(AC, {Rotation = Op and 180 or 0}, 0.15):Play()
            end)
            
            local obj = {
                Set = function(_, v) Sel = v; SL.Text = v; UpdateOptColors() end,
                Get = function() return Sel end,
                Refresh = function(_, no, nd) 
                    for _, x in ipairs(Opts:GetChildren()) do if x:IsA("TextButton") then x:Destroy() end end
                    OptBtns = {}
                    c.Options = no; Sel = nd or no[1] or ""; SL.Text = Sel
                    for _, o in ipairs(no) do MkOpt(o) end
                end
            }
            if c.Flag then Flags[c.Flag] = obj end
            return obj
        end
        
        function Tab:AddKeybind(c)
            c = c or {}
            local CKey = c.Default
            local List = false
            local H = IS_MOBILE and 44 or 50
            
            local F = Create("Frame", { Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = Theme.Tertiary, LayoutOrder = GetOrder(), Parent = TC })
            Corner(F, 8); local FS = Stroke(F, Theme.Border, 1, 0.3)
            Track(F, "BackgroundColor3", "Tertiary"); Track(FS, "Color", "Border")
            
            local NL = Create("TextLabel", { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = c.Name or "Keybind", TextColor3 = Theme.Text, TextSize = IS_MOBILE and 14 or 16, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, Parent = F })
            Track(NL, "TextColor3", "Text")
            
            local KH = IS_MOBILE and 28 or 32
            local KB = Create("TextButton", { Size = UDim2.new(0, IS_MOBILE and 65 or 75, 0, KH), Position = UDim2.new(1, -(IS_MOBILE and 75 or 85), 0.5, -KH/2), BackgroundColor3 = Theme.Secondary, Text = CKey and CKey.Name or "None", TextColor3 = Theme.Accent, TextSize = IS_MOBILE and 13 or 15, Font = Enum.Font.GothamBold, AutoButtonColor = false, Parent = F })
            Corner(KB, 6); local KS = Stroke(KB, Theme.Border, 1, 0)
            Track(KB, "BackgroundColor3", "Secondary"); Track(KB, "TextColor3", "Accent"); Track(KS, "Color", "Border")
            
            KB.MouseButton1Click:Connect(function() List = true; KB.Text = "..."; Tween(KS, {Color = Theme.Warning}, 0.1):Play() end)
            UIS.InputBegan:Connect(function(i, g)
                if g then return end
                if List then
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        CKey = i.KeyCode; KB.Text = CKey.Name; List = false
                        Tween(KS, {Color = Theme.Border}, 0.1):Play()
                        if c.ChangedCallback then c.ChangedCallback(CKey) end; Save()
                    end
                else if CKey and i.KeyCode == CKey then if c.Callback then c.Callback() end end end
            end)
            
            local obj = { Set = function(_, k) CKey = k; KB.Text = k and k.Name or "None" end, Get = function() return CKey end }
            if c.Flag then Flags[c.Flag] = obj end
            return obj
        end
        
        return Tab
    end
    
    local NC = Create("Frame", { Size = UDim2.new(0, IS_MOBILE and 300 or 380, 1, 0), Position = UDim2.new(0.5, IS_MOBILE and -150 or -190, 0, 12), BackgroundTransparency = 1, Parent = Gui })
    Create("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = NC })
    
    function W:Notify(c)
        c = c or {}
        local TypeColors = { info = Theme.Accent, success = Theme.Accent, warning = Theme.Warning, error = Theme.Danger }
        local AC = TypeColors[c.Type or "info"] or Theme.Accent
        local NH = IS_MOBILE and 68 or 78
        
        local N = Create("Frame", { Size = UDim2.new(1, 0, 0, NH), BackgroundColor3 = Theme.Primary, Parent = NC })
        Corner(N, 8); Stroke(N, AC, 2, 0.2)
        Create("Frame", { Size = UDim2.new(0, 5, 1, -12), Position = UDim2.new(0, 6, 0, 6), BackgroundColor3 = AC, Parent = N }, {Create("UICorner", {CornerRadius = UDim.new(0, 3)})})
        Create("TextLabel", { Size = UDim2.new(1, -24, 0, 24), Position = UDim2.new(0, 18, 0, 8), BackgroundTransparency = 1, Text = c.Title or "Notification", TextColor3 = AC, TextSize = IS_MOBILE and 15 or 17, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = N })
        Create("TextLabel", { Size = UDim2.new(1, -24, 0, NH - 38), Position = UDim2.new(0, 18, 0, 32), BackgroundTransparency = 1, Text = c.Content or "", TextColor3 = Theme.TextDim, TextSize = IS_MOBILE and 13 or 15, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = N })
        
        if c.Sound then
            local snd = Create("Sound", { SoundId = "rbxassetid://" .. tostring(c.Sound), Volume = 1, Parent = N })
            snd:Play()
            snd.Ended:Connect(function() snd:Destroy() end)
        end
        
        local closed = false
        local function closeNotify()
            if closed then return end
            closed = true
            Tween(N, {Position = UDim2.new(0, 400, 0, 0), BackgroundTransparency = 1}, 0.25):Play()
            task.wait(0.3); N:Destroy()
        end
        
        if c.Callback then
            local btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Text = "", ZIndex = 10, Parent = N })
            btn.MouseButton1Click:Connect(function()
                if c.Callback then c.Callback(c.Data) end
                closeNotify()
            end)
            btn.MouseEnter:Connect(function() Tween(N, {BackgroundColor3 = Theme.Secondary}, 0.1):Play() end)
            btn.MouseLeave:Connect(function() Tween(N, {BackgroundColor3 = Theme.Primary}, 0.1):Play() end)
        end
        
        N.Position = UDim2.new(0, -400, 0, 0)
        Tween(N, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back):Play()
        task.delay(c.Duration or 4, closeNotify)
    end
    
    function W:NotifyBrainrot(c)
        c = c or {}
        local dur = c.Duration or 10
        local NH = IS_MOBILE and 58 or 68
        local AccentColor = Theme.Accent
        
        local N = Create("Frame", { Size = UDim2.new(1, 0, 0, NH), BackgroundColor3 = Theme.Primary, Parent = NC })
        Corner(N, 8); Stroke(N, AccentColor, 2, 0.3)
        Create("Frame", { Size = UDim2.new(0, 4, 1, -12), Position = UDim2.new(0, 6, 0, 6), BackgroundColor3 = AccentColor, Parent = N }, {Create("UICorner", {CornerRadius = UDim.new(0, 2)})})
        
        Create("TextLabel", { Size = UDim2.new(1, -70, 0, IS_MOBILE and 22 or 26), Position = UDim2.new(0, 16, 0, IS_MOBILE and 6 or 8), BackgroundTransparency = 1, Text = c.Name or "Brainrot", TextColor3 = Theme.Text, TextSize = IS_MOBILE and 16 or 20, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = N })
        Create("TextLabel", { Size = UDim2.new(1, -40, 0, IS_MOBILE and 18 or 22), Position = UDim2.new(0, 16, 0, IS_MOBILE and 30 or 36), BackgroundTransparency = 1, Text = c.Generation or "$0/s", TextColor3 = AccentColor, TextSize = IS_MOBILE and 14 or 17, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = N })
        
        local timerLabel = Create("TextLabel", { Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -48, 0, 6), BackgroundTransparency = 1, Text = tostring(dur) .. "s", TextColor3 = Theme.TextMuted, TextSize = IS_MOBILE and 12 or 14, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Right, Parent = N })
        
        if c.Sound then
            local snd = Create("Sound", { SoundId = "rbxassetid://" .. tostring(c.Sound), Volume = 1, Parent = N })
            snd:Play()
            snd.Ended:Connect(function() snd:Destroy() end)
        end
        
        local closed = false
        local timeLeft = dur
        
        local function closeNotify()
            if closed then return end
            closed = true
            Tween(N, {Position = UDim2.new(0, 400, 0, 0), BackgroundTransparency = 1}, 0.25):Play()
            task.wait(0.3); N:Destroy()
        end
        
        task.spawn(function()
            while timeLeft > 0 and not closed do
                task.wait(1)
                timeLeft = timeLeft - 1
                if not closed then timerLabel.Text = tostring(timeLeft) .. "s" end
            end
            closeNotify()
        end)
        
        if c.Callback then
            local btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Text = "", ZIndex = 10, Parent = N })
            btn.MouseButton1Click:Connect(function()
                if c.Callback then c.Callback(c.Data) end
                closeNotify()
            end)
            btn.MouseEnter:Connect(function() Tween(N, {BackgroundColor3 = Theme.Secondary}, 0.1):Play() end)
            btn.MouseLeave:Connect(function() Tween(N, {BackgroundColor3 = Theme.Primary}, 0.1):Play() end)
        end
        
        N.Position = UDim2.new(0, -400, 0, 0)
        Tween(N, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back):Play()
    end
    
    function W:SetStatus(s)
        local c = StatusColors[s] or StatusColors.idle
        Stat.BackgroundColor3 = c; SG.Color = c
    end
    
    function W:Destroy() Gui:Destroy() end
    
    task.delay(0.1, Load)
    
    return W
end

return CyberLib
