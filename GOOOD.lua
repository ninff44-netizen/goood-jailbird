--[[
    GOOOD BY DISCORD.GG/GOOOD  —  v2
    Jailbird / Roblox FPS build.
    Menu key: RIGHT SHIFT

    v2 adds: Buff barricades, No outside detection, Fullbright.
    Requires Luau injection (executor). Official Windows client runs Hyperion/Byfron.

    Known limits from the game's own changelog:
      - server hit detection since Beta 11.6  -> hitbox expander is cosmetic
      - speed hack patches (13.1, 14.1)       -> walkspeed is the riskiest option here
      - camera synced raycast (11.3)          -> silent CAMERA is the path that fits
]]

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local Http       = game:GetService("HttpService")
local Workspace  = game:GetService("Workspace")
local Lighting   = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
do
    local waited = 0
    while not Camera and waited < 5 do
        task.wait(0.1)
        waited += 0.1
        Camera = Workspace.CurrentCamera
    end
end
if not Camera then return end

local DRAW         = Drawing
local MOUSEMOVEREL = mousemoverel
local HOOKMETHOD   = hookmetamethod
local GETNAME      = getnamecallmethod

-- ============================================================
-- theme
-- ============================================================
local T = {
    Bg     = Color3.fromRGB(12, 12, 16),
    Panel  = Color3.fromRGB(18, 18, 24),
    Row    = Color3.fromRGB(25, 25, 33),
    RowAlt = Color3.fromRGB(30, 30, 40),
    Off    = Color3.fromRGB(48, 48, 60),
    Accent = Color3.fromRGB(255, 45, 85),
    Text   = Color3.fromRGB(238, 238, 245),
    Dim    = Color3.fromRGB(148, 148, 164),
}

-- ============================================================
-- helpers
-- ============================================================
local function inst(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then o[k] = v end
    end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = o
    return c
end

local function stroke(o, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or T.Off
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function matchAny(name, list)
    local n = string.lower(tostring(name or ""))
    for _, p in ipairs(list) do
        if string.find(n, p, 1, true) then return true end
    end
    return false
end

local Connections = {}
local function track(c) table.insert(Connections, c) return c end

local F = {}
local Rows = {}
local Tabs = {}
local ActiveTab = "Combat"
local orderSeq = 0
local function nextOrder()
    orderSeq += 1
    return orderSeq
end

-- ============================================================
-- gui root
-- ============================================================
local guiParent
if gethui then
    local ok, h = pcall(gethui)
    if ok and h then guiParent = h end
end
if not guiParent then
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then guiParent = cg end
end
if not guiParent then guiParent = LP:WaitForChild("PlayerGui") end

local Menu = inst("ScreenGui", {
    Name = "GOOOD_Menu",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local Main = inst("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(560, 400),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = T.Bg,
    BorderSizePixel = 0,
}, Menu)
corner(Main, 10)
stroke(Main, T.Accent, 1, 0.55)

local Header = inst("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
}, Main)
corner(Header, 10)

inst("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 1, -12),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
}, Header)

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, T.Accent),
    ColorSequenceKeypoint.new(1, T.Panel),
})
grad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.35),
    NumberSequenceKeypoint.new(1, 1),
})
grad.Parent = Header

local HeaderImage = inst("ImageLabel", {
    Size = UDim2.fromOffset(26, 26),
    Position = UDim2.new(1, -92, 0, 6),
    BackgroundTransparency = 1,
    Visible = false,
    Image = "",
}, Header)

inst("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -160, 1, 0),
    Font = Enum.Font.GothamBlack,
    TextSize = 13,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "GOOOD BY DISCORD.GG/GOOOD",
}, Header)

local CloseBtn = inst("TextButton", {
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.new(1, -28, 0, 8),
    BackgroundColor3 = T.Row,
    Text = "x",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = T.Dim,
    AutoButtonColor = false,
    BorderSizePixel = 0,
}, Header)
corner(CloseBtn, 5)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local Body = inst("Frame", {
    Size = UDim2.new(1, 0, 1, -38),
    Position = UDim2.new(0, 0, 0, 38),
    BackgroundTransparency = 1,
}, Main)

local Sidebar = inst("Frame", {
    Size = UDim2.new(0, 116, 1, -16),
    Position = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = T.Panel,
    BorderSizePixel = 0,
}, Body)
corner(Sidebar, 8)
inst("UIListLayout", {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, Sidebar)
inst("UIPadding", {
    PaddingTop = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
}, Sidebar)

local SearchBox = inst("TextBox", {
    Size = UDim2.new(1, -140, 0, 26),
    Position = UDim2.new(0, 132, 0, 8),
    BackgroundColor3 = T.Panel,
    PlaceholderText = "search...",
    PlaceholderColor3 = T.Dim,
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextColor3 = T.Text,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    BorderSizePixel = 0,
}, Body)
corner(SearchBox, 6)
inst("UIPadding", { PaddingLeft = UDim.new(0, 10) }, SearchBox)

local Content = inst("Frame", {
    Size = UDim2.new(1, -140, 1, -48),
    Position = UDim2.new(0, 132, 0, 40),
    BackgroundTransparency = 1,
}, Body)

local function addTab(name)
    local btn = inst("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = T.Panel,
        Text = name,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = T.Dim,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(),
    }, Sidebar)
    corner(btn, 5)

    local frame = inst("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, Content)
    inst("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, frame)
    inst("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 10),
    }, frame)

    Tabs[name] = { Button = btn, Frame = frame }
    btn.MouseButton1Click:Connect(function()
        ActiveTab = name
        for n, t in pairs(Tabs) do
            t.Frame.Visible = (n == name)
            t.Button.TextColor3 = (n == name) and T.Text or T.Dim
            t.Button.BackgroundColor3 = (n == name) and T.RowAlt or T.Panel
        end
    end)
end

addTab("Combat")
addTab("Visuals")
addTab("Game")
addTab("Player")
addTab("Setup")

-- ============================================================
-- row factories
-- ============================================================
local function newRow(tabName, label, height)
    local row = inst("Frame", {
        Size = UDim2.new(1, -6, 0, height),
        BackgroundColor3 = T.Row,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(),
    }, Tabs[tabName].Frame)
    corner(row, 5)

    local lbl = inst("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -78, 1, 0),
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = label,
    }, row)

    table.insert(Rows, { Frame = row, Label = string.lower(label), Tab = tabName })
    return row, lbl
end

local function makeToggle(tabName, label, initial, onChange)
    local row = newRow(tabName, label, 30)
    local pill = inst("TextButton", {
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = T.Off,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, row)
    corner(pill, 10)

    local knob = inst("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(242, 242, 248),
        BorderSizePixel = 0,
    }, pill)
    corner(knob, 8)

    local value = initial and true or false
    local handle = {}
    local function render()
        Tween:Create(knob, TweenInfo.new(0.12), {
            Position = value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        }):Play()
        Tween:Create(pill, TweenInfo.new(0.12), {
            BackgroundColor3 = value and T.Accent or T.Off,
        }):Play()
    end

    local function set(v)
        value = v and true or false
        render()
        if onChange then onChange(value) end
    end

    pill.MouseButton1Click:Connect(function() set(not value) end)
    handle.Get = function() return value end
    handle.Set = set
    render()
    return handle
end

local function makeSlider(tabName, label, min, max, initial, decimals, onChange)
    local row, lbl = newRow(tabName, label, 42)
    lbl.Position = UDim2.new(0, 8, 0, 4)
    lbl.Size = UDim2.new(1, -78, 0, 16)

    local val = inst("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -78, 0, 4),
        Size = UDim2.fromOffset(70, 16),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = T.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
    }, row)

    local bar = inst("Frame", {
        Size = UDim2.new(1, -16, 0, 6),
        Position = UDim2.new(0, 8, 0, 30),
        BackgroundColor3 = T.Off,
        BorderSizePixel = 0,
    }, row)
    corner(bar, 3)

    local fill = inst("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
    }, bar)
    corner(fill, 3)

    local hit = inst("TextButton", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = "",
    }, bar)

    local mult = 10 ^ (decimals or 0)
    local value = initial
    local dragging = false

    local function fmt(v)
        if (decimals or 0) == 0 then
            return string.format("%d", math.floor(v + 0.5))
        end
        return string.format("%." .. tostring(decimals) .. "f", v)
    end

    local function set(v, fire)
        value = math.clamp(math.floor(v * mult + 0.5) / mult, min, max)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        val.Text = fmt(value)
        if fire and onChange then onChange(value) end
    end

    local function update()
        local m = UIS:GetMouseLocation()
        local alpha = math.clamp((m.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        set(min + (max - min) * alpha, true)
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update()
        end
    end)
    track(UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update()
        end
    end))
    track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    set(initial, false)
    return {
        Get = function() return value end,
        Set = function(v) set(v, true) end,
    }
end

local function makeCycle(tabName, label, options, initial, onChange)
    local row = newRow(tabName, label, 30)
    local btn = inst("TextButton", {
        Size = UDim2.fromOffset(120, 20),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = T.Off,
        Text = "",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = T.Text,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, row)
    corner(btn, 4)

    local index = 1
    for i, o in ipairs(options) do
        if o == initial then index = i end
    end

    local function render()
        btn.Text = options[index]
    end

    local function setValue(v)
        for i, o in ipairs(options) do
            if o == v then
                index = i
                break
            end
        end
        render()
        if onChange then onChange(options[index]) end
    end

    btn.MouseButton1Click:Connect(function()
        index = (index % #options) + 1
        render()
        if onChange then onChange(options[index]) end
    end)

    render()
    return {
        Get = function() return options[index] end,
        Set = setValue,
    }
end

local function makeText(tabName, label, initial, placeholder, onChange)
    local row = newRow(tabName, label, 30)
    local box = inst("TextBox", {
        Size = UDim2.new(0, 150, 0, 20),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = T.Off,
        Text = initial or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = T.Dim,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
    }, row)
    corner(box, 4)
    inst("UIPadding", { PaddingLeft = UDim.new(0, 6) }, box)

    box.FocusLost:Connect(function()
        if onChange then onChange(box.Text) end
    end)

    return {
        Get = function() return box.Text end,
        Set = function(v) box.Text = v end,
    }
end

local function makeButton(tabName, label, onClick)
    local row = newRow(tabName, label, 30)
    local lbl = row:FindFirstChildOfClass("TextLabel")
    if lbl then lbl.Text = "" end

    local btn = inst("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = T.RowAlt,
        Text = label,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = T.Text,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, row)
    corner(btn, 5)
    btn.MouseButton1Click:Connect(function()
        local ok, err = pcall(onClick)
        if not ok then warn("[GOOOD] " .. tostring(err)) end
    end)
end

-- ============================================================
-- shared target / visibility math
-- ============================================================
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function sameTeam(plr)
    local a, b = plr.Team, LP.Team
    if a and b then return a == b end
    return false
end

local function canSee(part, char)
    rayParams.FilterDescendantsInstances = { LP.Character, char }
    local origin = Camera.CFrame.Position
    local hit = Workspace:Raycast(origin, part.Position - origin, rayParams)
    return hit == nil
end

local function candidateParts(char)
    local pref = F.AimPart and F.AimPart:Get() or "Head"
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local parts = {}
    if pref == "HumanoidRootPart" then
        if hrp then table.insert(parts, hrp) end
        if head then table.insert(parts, head) end
    else
        if head then table.insert(parts, head) end
        if hrp then table.insert(parts, hrp) end
    end
    return parts
end

local function findTarget(fov, wallCheck, teamCheck)
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
    local best, bestScore = nil, fov

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and not (teamCheck and sameTeam(plr)) then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local parts = candidateParts(char)
                for i = 1, #parts do
                    local part = parts[i]
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        local score = d + (i - 1) * 12
                        if score < bestScore then
                            if not wallCheck or canSee(part, char) then
                                best, bestScore = part, score
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

-- ============================================================
-- humanoid / hitbox / lighting state
-- ============================================================
local humanoidOriginals = setmetatable({}, { __mode = "k" })
local hitboxOriginals = setmetatable({}, { __mode = "k" })

local function applyHumanoid()
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if not humanoidOriginals[hum] then
        humanoidOriginals[hum] = {
            WalkSpeed = hum.WalkSpeed,
            JumpPower = hum.JumpPower,
            UseJumpPower = hum.UseJumpPower,
        }
    end
    hum.WalkSpeed = F.Speed:Get()
    hum.UseJumpPower = true
    hum.JumpPower = F.Jump:Get()
end

local function restoreHumanoid()
    for hum, orig in pairs(humanoidOriginals) do
        if hum and hum.Parent then
            hum.WalkSpeed = orig.WalkSpeed
            hum.JumpPower = orig.JumpPower
            hum.UseJumpPower = orig.UseJumpPower
        end
    end
    table.clear(humanoidOriginals)
end

local function applyHitbox()
    if not F.Hitbox or not F.Hitbox:Get() then return end
    local mult = F.HitboxSize:Get()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not hitboxOriginals[hrp] then
                    hitboxOriginals[hrp] = {
                        Size = hrp.Size,
                        Transparency = hrp.Transparency,
                        CanCollide = hrp.CanCollide,
                    }
                end
                local base = hitboxOriginals[hrp].Size
                hrp.Size = Vector3.new(base.X * mult, base.Y * mult, base.Z * mult)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            end
        end
    end
end

local function restoreHitbox()
    for part, orig in pairs(hitboxOriginals) do
        if part and part.Parent then
            part.Size = orig.Size
            part.Transparency = orig.Transparency
            part.CanCollide = orig.CanCollide
        end
    end
    table.clear(hitboxOriginals)
end

local lightingOriginals
local function setFullbright(on)
    if on then
        if not lightingOriginals then
            lightingOriginals = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
            }
        end
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(190, 190, 190)
        Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    elseif lightingOriginals then
        Lighting.Brightness = lightingOriginals.Brightness
        Lighting.ClockTime = lightingOriginals.ClockTime
        Lighting.Ambient = lightingOriginals.Ambient
        Lighting.OutdoorAmbient = lightingOriginals.OutdoorAmbient
        Lighting.FogEnd = lightingOriginals.FogEnd
        Lighting.GlobalShadows = lightingOriginals.GlobalShadows
        lightingOriginals = nil
    end
end

-- ============================================================
-- module: buff barricades
-- ============================================================
local barricadeCache = setmetatable({}, { __mode = "k" })
local barricadeScanning = false

local BARRICADE_KEYWORDS = { "barricade", "plank" }
local HEALTH_KEYS = { "health", "hp", "durability", "integrity" }

local function barricadeKeywords()
    local list = {}
    for _, k in ipairs(BARRICADE_KEYWORDS) do table.insert(list, k) end
    local extra = F.Keywords and F.Keywords:Get() or ""
    for word in string.gmatch(extra, "[^,%s]+") do
        word = string.lower(word)
        if #word >= 3 then table.insert(list, word) end
    end
    return list
end

local function applyBarricade(part)
    if not part or not part.Parent then return end
    local orig = barricadeCache[part]
    if not orig then
        orig = {
            Anchored = part.Anchored,
            CanCollide = part.CanCollide,
            Transparency = part.Transparency,
            Values = {},
        }
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("NumberValue") and matchAny(child.Name, HEALTH_KEYS) then
                orig.Values[child] = child.Value
            end
        end
        barricadeCache[part] = orig
    end
    part.Anchored = true
    part.CanCollide = true
    part.Transparency = 0
    for value in pairs(orig.Values) do
        if value and value.Parent then value.Value = 1e9 end
    end
end

local function restoreBarricades()
    for part, orig in pairs(barricadeCache) do
        if part and part.Parent then
            part.Anchored = orig.Anchored
            part.CanCollide = orig.CanCollide
            part.Transparency = orig.Transparency
            for value, v in pairs(orig.Values) do
                if value and value.Parent then value.Value = v end
            end
        end
    end
    table.clear(barricadeCache)
end

local function scanBarricades()
    if barricadeScanning then return end
    barricadeScanning = true
    task.spawn(function()
        local keywords = barricadeKeywords()
        local all = Workspace:GetDescendants()
        local limit = math.min(#all, 30000)
        for i = 1, limit do
            if not F.BuffBarricades or not F.BuffBarricades:Get() then break end
            local obj = all[i]
            if obj:IsA("BasePart") and matchAny(obj.Name, keywords) then
                applyBarricade(obj)
            end
            if i % 400 == 0 then task.wait() end
        end
        barricadeScanning = false
    end)
end

-- ============================================================
-- module: no outside detection
-- ============================================================
local DETECT_KEYWORDS = { "spotted", "detected", "outside", "reveal", "exposed" }
local detectUI = setmetatable({}, { __mode = "k" })
local detectBools = setmetatable({}, { __mode = "k" })

local function detectKeywords()
    local list = {}
    for _, k in ipairs(DETECT_KEYWORDS) do table.insert(list, k) end
    return list
end

local function scanDetected()
    local patterns = detectKeywords()
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    local roots = {}
    if pg then table.insert(roots, pg) end
    if LP.Character then table.insert(roots, LP.Character) end

    for _, root in ipairs(roots) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("GuiObject") and matchAny(obj.Name, patterns) then
                if detectUI[obj] == nil then detectUI[obj] = obj.Visible end
                obj.Visible = false
            elseif obj:IsA("BoolValue") and matchAny(obj.Name, patterns) then
                if detectBools[obj] == nil then detectBools[obj] = obj.Value end
                obj.Value = false
            end
        end
    end
end

local function restoreDetected()
    for obj, visible in pairs(detectUI) do
        if obj and obj.Parent then
            pcall(function() obj.Visible = visible end)
        end
    end
    table.clear(detectUI)
    for obj, value in pairs(detectBools) do
        if obj and obj.Parent then obj.Value = value end
    end
    table.clear(detectBools)
end

-- ============================================================
-- features — menu wiring
-- ============================================================
F.Aimbot     = makeToggle("Combat", "Aimbot", false)
F.AimMode    = makeCycle("Combat", "Aim mode", { "Hold M2", "Always" }, "Hold M2")
F.AimFov     = makeSlider("Combat", "Aim FOV", 10, 600, 140, 0)
F.AimSmooth  = makeSlider("Combat", "Smoothing", 1, 30, 6, 1)
F.AimPart    = makeCycle("Combat", "Target part", { "Head", "HumanoidRootPart" }, "Head")
F.AimWall    = makeToggle("Combat", "Wall check", true)
F.AimTeam    = makeToggle("Combat", "Team check", true)
F.Silent     = makeToggle("Combat", "Silent aim", false)
F.SilentFov  = makeSlider("Combat", "Silent FOV", 10, 800, 160, 0)
F.SilentMode = makeCycle("Combat", "Silent mode", { "Camera", "Remote" }, "Camera")
F.SilentRemote = makeText("Combat", "Remote name", "", "exact remote name")

F.ESP        = makeToggle("Visuals", "ESP", false)
F.EspBox     = makeToggle("Visuals", "Show box", true)
F.EspName    = makeToggle("Visuals", "Show name", true)
F.EspHealth  = makeToggle("Visuals", "Show health", true)
F.EspDist    = makeToggle("Visuals", "Show distance", true)
F.EspTracer  = makeToggle("Visuals", "Show tracer", false)
F.EspTeam    = makeToggle("Visuals", "Team check", true)
F.EspMax     = makeSlider("Visuals", "Max distance", 100, 5000, 1500, 0)
F.EspSize    = makeSlider("Visuals", "Text size", 8, 24, 13, 0)
F.Fullbright = makeToggle("Visuals", "Fullbright", false, setFullbright)

F.BuffBarricades = makeToggle("Game", "Buff barricades", false, function(v)
    if v then
        scanBarricades()
    else
        restoreBarricades()
    end
end)
F.NoOutside = makeToggle("Game", "No outside detection", false, function(v)
    if not v then restoreDetected() end
end)
F.Keywords = makeText("Game", "Extra keywords", "", "comma separated", function()
    if F.BuffBarricades:Get() then
        restoreBarricades()
        scanBarricades()
    end
end)
makeButton("Game", "Force rescan", function()
    if F.BuffBarricades:Get() then
        restoreBarricades()
        scanBarricades()
    end
end)

F.Speed      = makeSlider("Player", "Walk speed", 16, 200, 16, 0, applyHumanoid)
F.Jump       = makeSlider("Player", "Jump power", 50, 250, 50, 0, applyHumanoid)
F.InfJump    = makeToggle("Player", "Infinite jump", false)
F.Hitbox     = makeToggle("Player", "Hitbox expander", false, function(v)
    if not v then restoreHitbox() end
end)
F.HitboxSize = makeSlider("Player", "Hitbox size", 1, 10, 3, 1, function()
    if F.Hitbox:Get() then applyHitbox() end
end)

F.HeaderImage = makeText("Setup", "Header image", "", "rbxassetid://...", function(text)
    text = tostring(text or ""):gsub("%s+", "")
    if text == "" then
        HeaderImage.Visible = false
        return
    end
    if text:match("^%d+$") then
        text = "rbxassetid://" .. text
    end
    HeaderImage.Image = text
    HeaderImage.Visible = true
end)

-- ============================================================
-- esp
-- ============================================================
local espCache = {}

local function espHide(o)
    for _, obj in pairs(o) do
        pcall(function() obj.Visible = false end)
    end
end

local function espClear()
    for plr, o in pairs(espCache) do
        for _, obj in pairs(o) do
            pcall(function() obj:Remove() end)
        end
        espCache[plr] = nil
    end
end

local function espFor(plr)
    local o = espCache[plr]
    if o then return o end
    if not DRAW then return nil end

    o = {
        Box      = DRAW.new("Square"),
        Name     = DRAW.new("Text"),
        Dist     = DRAW.new("Text"),
        HealthBg = DRAW.new("Square"),
        Health   = DRAW.new("Square"),
        Tracer   = DRAW.new("Line"),
    }
    o.Box.Thickness = 1
    o.Box.Filled = false
    o.Box.Color = T.Accent
    o.Name.Center = true
    o.Name.Outline = true
    o.Name.Color = T.Text
    o.Dist.Center = true
    o.Dist.Outline = true
    o.Dist.Color = T.Dim
    o.HealthBg.Filled = true
    o.HealthBg.Color = Color3.fromRGB(0, 0, 0)
    o.Health.Filled = true
    o.Health.Color = Color3.fromRGB(60, 220, 110)
    o.Tracer.Thickness = 1
    o.Tracer.Color = T.Accent

    espCache[plr] = o
    return o
end

local function espHighlight(char, on)
    local existing = char:FindFirstChild("GOOOD_HL")
    if on then
        if existing then return end
        local hl = inst("Highlight", {
            Name = "GOOOD_HL",
            FillColor = T.Accent,
            FillTransparency = 0.78,
            OutlineColor = T.Accent,
            OutlineTransparency = 0,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            Adornee = char,
        }, char)
        return hl
    end
    if existing then existing:Destroy() end
end

local function espStep()
    local on = F.ESP:Get()
    local maxDist = F.EspMax:Get()
    local textSize = F.EspSize:Get()
    local showBox = F.EspBox:Get()
    local showName = F.EspName:Get()
    local showHp = F.EspHealth:Get()
    local showDist = F.EspDist:Get()
    local showTracer = F.EspTracer:Get()
    local teamCheck = F.EspTeam:Get()

    local vp = Camera.ViewportSize
    local camPos = Camera.CFrame.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local o = espFor(plr)

            local valid = on and char and hum and hrp and hum.Health > 0
                and (camPos - hrp.Position).Magnitude <= maxDist
                and not (teamCheck and sameTeam(plr))

            local sp, onScreen = Camera:WorldToViewportPoint(
                hrp and (hrp.Position + Vector3.new(0, 2.0, 0)) or Vector3.zero
            )
            local fp, onScreen2 = Camera:WorldToViewportPoint(
                hrp and (hrp.Position - Vector3.new(0, 2.8, 0)) or Vector3.zero
            )

            if valid and onScreen and onScreen2 and o then
                local h = math.abs(fp.Y - sp.Y)
                local w = h * 0.55
                local x = sp.X - w * 0.5
                local y = sp.Y
                local dist = math.floor((camPos - hrp.Position).Magnitude + 0.5)

                o.Box.Size = Vector2.new(w, h)
                o.Box.Position = Vector2.new(x, y)
                o.Box.Color = T.Accent
                o.Box.Visible = showBox

                o.Name.Size = textSize
                o.Name.Position = Vector2.new(x + w * 0.5, y - textSize - 3)
                o.Name.Text = plr.Name
                o.Name.Visible = showName

                o.Dist.Size = textSize - 1
                o.Dist.Position = Vector2.new(x + w * 0.5, y + h + 2)
                o.Dist.Text = tostring(dist) .. "m"
                o.Dist.Visible = showDist

                local frac = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                local barX = x - 6
                o.HealthBg.Size = Vector2.new(3, h)
                o.HealthBg.Position = Vector2.new(barX, y)
                o.HealthBg.Visible = showHp
                o.Health.Size = Vector2.new(3, h * frac)
                o.Health.Position = Vector2.new(barX, y + h * (1 - frac))
                o.Health.Visible = showHp

                o.Tracer.From = Vector2.new(vp.X * 0.5, vp.Y)
                o.Tracer.To = Vector2.new(x + w * 0.5, y + h)
                o.Tracer.Visible = showTracer

                if not DRAW then espHighlight(char, true) end
            else
                if o then espHide(o) end
                if not DRAW and char then espHighlight(char, false) end
            end
        end
    end
end

-- ============================================================
-- aimbot / silent
-- ============================================================
local fovCircle
if DRAW then
    fovCircle = DRAW.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.Filled = false
    fovCircle.Color = T.Accent
    fovCircle.Transparency = 0.6
    fovCircle.Visible = false
end

local function aimMove(pos, dt)
    if MOUSEMOVEREL then
        local vp = Camera.ViewportSize
        local sp = Camera:WorldToViewportPoint(pos)
        local dx = sp.X - vp.X * 0.5
        local dy = sp.Y - vp.Y * 0.5
        local f = 1 / math.max(1, F.AimSmooth:Get())
        MOUSEMOVEREL(dx * f, dy * f)
    else
        local cf = CFrame.lookAt(Camera.CFrame.Position, pos)
        local speed = math.max(1, F.AimSmooth:Get())
        Camera.CFrame = Camera.CFrame:Lerp(cf, math.clamp(1 - math.exp(-speed * dt * 6), 0, 1))
    end
end

local function silentCamera()
    if not F.Silent:Get() or F.SilentMode:Get() ~= "Camera" then return end
    local target = findTarget(F.SilentFov:Get(), false, F.AimTeam:Get())
    if target then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
    end
end

if HOOKMETHOD and GETNAME then
    local oldNamecall
    oldNamecall = HOOKMETHOD(game, "__namecall", function(self, ...)
        local method = GETNAME()

        if F.NoOutside and F.NoOutside:Get()
            and (method == "FireServer" or method == "InvokeServer")
            and matchAny(self.Name, detectKeywords()) then
            return nil
        end

        if F.Silent and F.Silent:Get() and F.SilentMode:Get() == "Remote" then
            local remoteName = F.SilentRemote:Get()
            if remoteName ~= "" and self.Name == remoteName
                and (method == "FireServer" or method == "InvokeServer") then
                local target = findTarget(F.SilentFov:Get(), false, F.AimTeam:Get())
                if target then
                    local args = { ... }
                    for i = 1, #args do
                        local v = args[i]
                        local t = typeof(v)
                        if t == "CFrame" then
                            args[i] = CFrame.lookAt(v.Position, target.Position)
                        elseif t == "Vector3" then
                            args[i] = target.Position
                        elseif t == "Ray" then
                            local origin = v.Origin
                            local dir = (target.Position - origin)
                            args[i] = Ray.new(origin, dir.Unit * v.Direction.Magnitude)
                        end
                    end
                    return oldNamecall(self, table.unpack(args))
                end
            end
        end

        return oldNamecall(self, ...)
    end)
end

-- ============================================================
-- render / heartbeat
-- ============================================================
track(RunService.RenderStepped:Connect(function(dt)
    espStep()

    local aimActive = F.Aimbot:Get()
        and (F.AimMode:Get() == "Always" or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2))
    if aimActive then
        local target = findTarget(F.AimFov:Get(), F.AimWall:Get(), F.AimTeam:Get())
        if target then aimMove(target.Position, dt) end
    end

    if fovCircle then
        local show = F.Aimbot:Get() or F.Silent:Get()
        fovCircle.Visible = show
        if show then
            local vp = Camera.ViewportSize
            fovCircle.Position = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
            fovCircle.Radius = F.Aimbot:Get() and F.AimFov:Get() or F.SilentFov:Get()
        end
    end
end))

track(RunService:BindToRenderStep("GOOOD_Silent", Enum.RenderPriority.Camera.Value + 1, silentCamera))

local hitboxAccum = 0
local barricadeAccum = 0
local detectAccum = 0

track(RunService.Heartbeat:Connect(function(dt)
    if F.Hitbox:Get() then
        hitboxAccum += dt
        if hitboxAccum >= 0.1 then
            hitboxAccum = 0
            applyHitbox()
        end
    end

    if F.BuffBarricades:Get() then
        barricadeAccum += dt
        if barricadeAccum >= 0.5 then
            barricadeAccum = 0
            for part in pairs(barricadeCache) do
                applyBarricade(part)
            end
        end
    end

    if F.NoOutside:Get() then
        detectAccum += dt
        if detectAccum >= 0.25 then
            detectAccum = 0
            scanDetected()
        end
    end
end))

track(Workspace.DescendantAdded:Connect(function(obj)
    if not F.BuffBarricades or not F.BuffBarricades:Get() then return end
    if obj:IsA("BasePart") and matchAny(obj.Name, barricadeKeywords()) then
        applyBarricade(obj)
    end
end))

track(UIS.JumpRequest:Connect(function()
    if not F.InfJump:Get() then return end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Workspace.CurrentCamera then Camera = Workspace.CurrentCamera end
end))

track(LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyHumanoid()
end))
applyHumanoid()

track(UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end))

-- drag header ------------------------------------------------
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = UIS:GetMouseLocation()
        startPos = Main.Position
    end
end)
track(UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local m = UIS:GetMouseLocation()
        local d = m - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end))
track(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end))

-- search -----------------------------------------------------
track(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(SearchBox.Text)
    for _, r in ipairs(Rows) do
        local visible = (r.Tab == ActiveTab)
        if visible and query ~= "" then
            visible = string.find(r.Label, query, 1, true) ~= nil
        end
        r.Frame.Visible = visible
    end
end))

-- ============================================================
-- config / unload
-- ============================================================
local CONFIG_FILE = "GOOOD_jailbird.json"

local function snapshot()
    return {
        Aimbot = F.Aimbot:Get(),
        AimMode = F.AimMode:Get(),
        AimFov = F.AimFov:Get(),
        AimSmooth = F.AimSmooth:Get(),
        AimPart = F.AimPart:Get(),
        AimWall = F.AimWall:Get(),
        AimTeam = F.AimTeam:Get(),
        Silent = F.Silent:Get(),
        SilentFov = F.SilentFov:Get(),
        SilentMode = F.SilentMode:Get(),
        SilentRemote = F.SilentRemote:Get(),
        ESP = F.ESP:Get(),
        EspBox = F.EspBox:Get(),
        EspName = F.EspName:Get(),
        EspHealth = F.EspHealth:Get(),
        EspDist = F.EspDist:Get(),
        EspTracer = F.EspTracer:Get(),
        EspTeam = F.EspTeam:Get(),
        EspMax = F.EspMax:Get(),
        EspSize = F.EspSize:Get(),
        Fullbright = F.Fullbright:Get(),
        BuffBarricades = F.BuffBarricades:Get(),
        NoOutside = F.NoOutside:Get(),
        Keywords = F.Keywords:Get(),
        Speed = F.Speed:Get(),
        Jump = F.Jump:Get(),
        InfJump = F.InfJump:Get(),
        Hitbox = F.Hitbox:Get(),
        HitboxSize = F.HitboxSize:Get(),
    }
end

local function saveConfig()
    if not writefile then return end
    writefile(CONFIG_FILE, Http:JSONEncode(snapshot()))
end

local function loadConfig()
    if not (isfile and readfile) then return end
    if not isfile(CONFIG_FILE) then return end
    local ok, data = pcall(function()
        return Http:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not ok or type(data) ~= "table" then return end
    for k, v in pairs(data) do
        if F[k] and F[k].Set then F[k].Set(v) end
    end
end

local function unload()
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Connections)

    pcall(function() RunService:UnbindFromRenderStep("GOOOD_Silent") end)

    restoreHitbox()
    restoreHumanoid()
    restoreBarricades()
    restoreDetected()
    setFullbright(false)
    espClear()

    if fovCircle then pcall(function() fovCircle:Remove() end) end
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        local hl = char and char:FindFirstChild("GOOOD_HL")
        if hl then hl:Destroy() end
    end

    if Menu then Menu:Destroy() end
end

makeButton("Setup", "Save config", saveConfig)
makeButton("Setup", "Load config", loadConfig)
makeButton("Setup", "Unload", unload)

-- first paint
Tabs["Combat"].Frame.Visible = true
Tabs["Combat"].Button.TextColor3 = T.Text
Tabs["Combat"].Button.BackgroundColor3 = T.RowAlt
