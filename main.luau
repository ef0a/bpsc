-- [[ SoulNoob Main Script - Modular Engine v1.37 ]] --

local ALL_LIMBS = {
    "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", 
    "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", 
    "LeftLowerLeg", "RightLowerLeg"
}

local OriginalSizes = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Cache-Busting Module Loader
local function fetchModule(url)
    local cacheBustUrl = url .. "?nocache=" .. tick()
    local success, result = pcall(function() return loadstring(game:HttpGet(cacheBustUrl))() end)
    return success and result or nil
end

local MODULE_URLS = {
    Priority    = "https://raw.githubusercontent.com/ef0a/bpsc/refs/heads/main/priority.luau",
    Orbit       = "https://raw.githubusercontent.com/ef0a/bpsc/refs/heads/main/orbit.luau",
    Aimbot      = "https://raw.githubusercontent.com/ef0a/bpsc/refs/heads/main/aimbot.luau",
    AutoClicker = "https://raw.githubusercontent.com/ef0a/bpsc/refs/heads/main/autoclicker.luau",
}

local Modules = {}
for name, url in pairs(MODULE_URLS) do
    Modules[name] = fetchModule(url)
end

local PriorityMod = Modules.Priority

-- State & Connections
local _G = {
    HitboxEnabled = false, HitboxTargetMode = "Head", TPEnabled = false,
    TargetCFrame = nil, Mode = "Normal", Size = 20, Transparency = 0.99, Bind = "J",
    TargetPriority = "Mega Bosses", AutoRefreshEnabled = false
}
local Connections = {}
local AutoRefreshThread = nil

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "SoulNoob_v135" ScreenGui.ResetOnSpawn = false ScreenGui.DisplayOrder = 999999999

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 250, 0, 480) Main.Position = UDim2.new(0.05, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25) Main.BorderSizePixel = 2 Main.BorderColor3 = Color3.fromRGB(0, 255, 150)
Main.Active = true Main.Draggable = true

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -30, 0, 35) Title.Text = " SoulNoob v1.35" Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40) Title.TextColor3 = Color3.new(1, 1, 1)

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 30, 0, 35) CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X" CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40) CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.SourceSansBold CloseBtn.BorderSizePixel = 0

-- Dynamic Tab System (5-Tab Layout)
local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1, 0, 0, 30) TabBar.Position = UDim2.new(0, 0, 0, 35) TabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

local TabFrames, TabButtons = {}, {}
local function createTab(name, w, pos)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(w, 0, 1, 0) btn.Position = UDim2.new(pos, 0, 0, 0) btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) btn.TextColor3 = Color3.new(1, 1, 1) btn.Font = Enum.Font.SourceSansBold
    
    local frame = Instance.new("Frame", Main)
    frame.Size = UDim2.new(1, 0, 1, -65) frame.Position = UDim2.new(0, 0, 0, 65) frame.BackgroundTransparency = 1 frame.Visible = false
    
    TabButtons[name], TabFrames[name] = btn, frame
    btn.MouseButton1Click:Connect(function()
        for k, f in pairs(TabFrames) do f.Visible = (k == name) end
        for k, b in pairs(TabButtons) do
            b.BackgroundColor3 = (k == name) and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(50, 50, 50)
            b.TextColor3 = (k == name) and Color3.fromRGB(20, 20, 20) or Color3.new(1, 1, 1)
        end
    end)
    return frame
end

local MainTabFrame    = createTab("Main",    0.20, 0)
local PrioTabFrame    = createTab("Prio",    0.20, 0.20)
local OrbitTabFrame   = createTab("Orbit",   0.20, 0.40)
local ABTabFrame      = createTab("AB",      0.20, 0.60)
local ClickerTabFrame = createTab("Clicker", 0.20, 0.80)

TabFrames["Main"].Visible = true
TabButtons["Main"].BackgroundColor3 = Color3.fromRGB(0, 255, 150)
TabButtons["Main"].TextColor3 = Color3.fromRGB(20, 20, 20)

-- UI Builders
local function createBtn(parent, pos, text, color)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.9, 0, 0, 32) b.Position = UDim2.new(0.05, 0, 0, pos)
    b.BackgroundColor3 = color b.Text = text b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold b.BorderSizePixel = 0
    return b
end

local function createTBox(parent, pos, placeholder, defaultText)
    local t = Instance.new("TextBox", parent)
    t.Size = UDim2.new(0.42, 0, 0, 28) t.Position = UDim2.new(pos.X, 0, 0, pos.Y)
    t.PlaceholderText = placeholder t.Text = defaultText
    t.BackgroundColor3 = Color3.fromRGB(50, 50, 50) t.TextColor3 = Color3.new(1, 1, 1) t.ClearTextOnFocus = false
    return t
end

-- Helper Functions
local function getRoot() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end

local function cleanModel(model)
    if not model then return end
    for _, p in pairs(model:GetChildren()) do
        if p:IsA("BasePart") then
            if OriginalSizes[p] then p.Size = OriginalSizes[p] end
            p.Transparency, p.Material, p.CanCollide, p.CanTouch, p.Anchored, p.Massless = 0, Enum.Material.Plastic, true, true, false, false
        end
    end
end

local function resetAll()
    _G.HitboxEnabled, _G.TPEnabled, _G.TargetCFrame = false, false, nil
    if PriorityMod and PriorityMod.ResetLock then PriorityMod.ResetLock() end
    
    local allMobs = PriorityMod and PriorityMod.GetAllMobs and PriorityMod.GetAllMobs() or {}
    for _, enemy in ipairs(allMobs) do cleanModel(enemy) end
end

local function triggerNormalHitbox()
    _G.HitboxEnabled = true
    _G.Mode = "Normal"
end

-- Main Controls
local ModeBtn      = createBtn(MainTabFrame, 10, "Target Parts: HEAD", Color3.fromRGB(0, 150, 100))
local NormalBtn    = createBtn(MainTabFrame, 47, "Hitbox: Normal", Color3.fromRGB(0, 120, 200))
local FreezeBtn    = createBtn(MainTabFrame, 84, "Hitbox: Stun (Freeze)", Color3.fromRGB(150, 0, 0))
local TPBtn        = createBtn(MainTabFrame, 121, "SET KILL ZONE: OFF", Color3.fromRGB(150, 0, 150))
local SizeBox      = createTBox(MainTabFrame, Vector2.new(0.05, 165), "Hitbox Size", "Size: ".._G.Size)
local TransBox     = createTBox(MainTabFrame, Vector2.new(0.53, 165), "Transparency", "Trans: ".._G.Transparency)
local BindBox      = createTBox(MainTabFrame, Vector2.new(0.05, 200), "Bind", "Bind: ".._G.Bind)

local AutoRefreshBtn = createBtn(MainTabFrame, 320, "Auto Refresh (20s): OFF", Color3.fromRGB(100, 40, 40))
local OffBtn         = createBtn(MainTabFrame, 360, "RESET / ALL OFF", Color3.fromRGB(70, 70, 70))

-- Auto Refresh Sequence Task
local function startAutoRefreshLoop()
    if AutoRefreshThread then task.cancel(AutoRefreshThread) end
    AutoRefreshThread = task.spawn(function()
        while _G.AutoRefreshEnabled do
            task.wait(20)
            if _G.AutoRefreshEnabled then
                resetAll()
                task.wait(0.1)
                triggerNormalHitbox()
            end
        end
    end)
end

AutoRefreshBtn.MouseButton1Click:Connect(function()
    _G.AutoRefreshEnabled = not _G.AutoRefreshEnabled
    if _G.AutoRefreshEnabled then
        AutoRefreshBtn.Text = "Auto Refresh (20s): ON"
        AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        startAutoRefreshLoop()
    else
        AutoRefreshBtn.Text = "Auto Refresh (20s): OFF"
        AutoRefreshBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
        if AutoRefreshThread then
            task.cancel(AutoRefreshThread)
            AutoRefreshThread = nil
        end
    end
end)

-- Priority Controls (Dedicated Prio Tab)
local PriorityBtn = createBtn(PrioTabFrame, 10, "Priority: MEGA BOSSES", Color3.fromRGB(200, 0, 100))

-- Dynamic Map Target Buttons Builder
local mapYOffset = 60
if PriorityMod and PriorityMod.MAP_TARGETS then
    for _, pathStr in ipairs(PriorityMod.MAP_TARGETS) do
        local targetName = pathStr:match("[^%.]+$") or pathStr
        local mapBtn = createBtn(PrioTabFrame, mapYOffset, "Map: " .. targetName .. " [OFF]", Color3.fromRGB(100, 40, 40))
        
        mapBtn.MouseButton1Click:Connect(function()
            local newState = PriorityMod.ToggleMapTarget(pathStr)
            if newState then
                mapBtn.Text = "Map: " .. targetName .. " [OVERRIDE ON]"
                mapBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
            else
                mapBtn.Text = "Map: " .. targetName .. " [OFF]"
                mapBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
            end
        end)
        mapYOffset = mapYOffset + 37
    end
end

local function toggleKillZone()
    local myRoot = getRoot() if not myRoot then return end
    _G.TPEnabled = not _G.TPEnabled
    if _G.TPEnabled then
        _G.TargetCFrame = myRoot.CFrame * CFrame.new(0, 0, -8)
        TPBtn.Text, TPBtn.BackgroundColor3 = "KILL ZONE: LOCKED", Color3.fromRGB(255, 0, 255)
    else
        _G.TargetCFrame, TPBtn.Text, TPBtn.BackgroundColor3 = nil, "SET KILL ZONE: OFF", Color3.fromRGB(150, 0, 150)
    end
end

local function applyEffects(model)
    if not model or model == LocalPlayer.Character then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")

    if _G.HitboxEnabled then
        local partsToExpand = {}
        if _G.HitboxTargetMode == "Head" then
            local head = model:FindFirstChild("Head") or root
            if head then table.insert(partsToExpand, head) end
        else
            for _, limbName in ipairs(ALL_LIMBS) do
                local p = model:FindFirstChild(limbName) if p and p:IsA("BasePart") then table.insert(partsToExpand, p) end
            end
            if #partsToExpand == 0 and root then table.insert(partsToExpand, root) end
        end

        for _, p in ipairs(partsToExpand) do
            if not OriginalSizes[p] then OriginalSizes[p] = p.Size end
            p.Size, p.Transparency, p.Material, p.Massless, p.CanTouch = Vector3.new(_G.Size, _G.Size, _G.Size), _G.Transparency, Enum.Material.Neon, true, true
            p.Color = (_G.Mode == "Freeze") and Color3.new(1, 0, 0) or Color3.new(1, 1, 0)
            p.Anchored, p.CanCollide = (_G.Mode == "Freeze"), false
        end
    end

    if _G.TPEnabled and _G.TargetCFrame and root then
        root.CFrame, root.Velocity, root.RotVelocity = _G.TargetCFrame, Vector3.zero, Vector3.zero
    end
end

-- Event Listeners & Button Handlers
table.insert(Connections, UIS.InputBegan:Connect(function(i, p) if not p and i.KeyCode.Name == _G.Bind then toggleKillZone() end end))

PriorityBtn.MouseButton1Click:Connect(function()
    if PriorityMod and PriorityMod.ResetLock then PriorityMod.ResetLock() end
    if _G.TargetPriority == "Mega Bosses" then
        _G.TargetPriority = "Bosses"
        PriorityBtn.Text = "Priority: BOSSES"
        PriorityBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
    elseif _G.TargetPriority == "Bosses" then
        _G.TargetPriority = "Enemies"
        PriorityBtn.Text = "Priority: ENEMIES ONLY"
        PriorityBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    elseif _G.TargetPriority == "Enemies" then
        _G.TargetPriority = "Closest"
        PriorityBtn.Text = "Priority: CLOSEST (ALL)"
        PriorityBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        _G.TargetPriority = "Mega Bosses"
        PriorityBtn.Text = "Priority: MEGA BOSSES"
        PriorityBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 100)
    end
end)

ModeBtn.MouseButton1Click:Connect(function()
    _G.HitboxTargetMode = (_G.HitboxTargetMode == "Head") and "All" or "Head"
    ModeBtn.Text = "Target Parts: " .. _G.HitboxTargetMode:upper()
    ModeBtn.BackgroundColor3 = (_G.HitboxTargetMode == "All") and Color3.fromRGB(180, 100, 0) or Color3.fromRGB(0, 150, 100)
    
    local allMobs = PriorityMod and PriorityMod.GetAllMobs and PriorityMod.GetAllMobs() or {}
    if _G.HitboxEnabled then for _, enemy in ipairs(allMobs) do cleanModel(enemy) end end
end)

TPBtn.MouseButton1Click:Connect(toggleKillZone)
NormalBtn.MouseButton1Click:Connect(triggerNormalHitbox)
FreezeBtn.MouseButton1Click:Connect(function() _G.HitboxEnabled, _G.Mode = true, "Freeze" end)
OffBtn.MouseButton1Click:Connect(function()
    resetAll()
    TPBtn.Text, TPBtn.BackgroundColor3 = "SET KILL ZONE: OFF", Color3.fromRGB(150, 0, 150)
end)

SizeBox.FocusLost:Connect(function() local v = tonumber(SizeBox.Text:match("%d+%.?%d*")) if v then _G.Size, SizeBox.Text = v, "Size: "..v end end)
TransBox.FocusLost:Connect(function() local v = tonumber(TransBox.Text:match("%d+%.?%d*")) if v then _G.Transparency, TransBox.Text = math.clamp(v, 0, 1), "Trans: "..v end end)
BindBox.FocusLost:Connect(function() local k = BindBox.Text:gsub("Bind: ", ""):upper() if #k == 1 then _G.Bind, BindBox.Text = k, "Bind: "..k end end)

-- Init External Modules
local HeartbeatSteps, RenderSteppedSteps = {}, {}
local function getPrimaryTarget()
    if PriorityMod and PriorityMod.GetPrimaryTarget then
        return PriorityMod.GetPrimaryTarget(_G.TargetPriority, getRoot)
    end
    return nil
end

local function getAllMobs()
    if PriorityMod and PriorityMod.GetAllMobs then
        return PriorityMod.GetAllMobs()
    end
    return {}
end

if Modules.Orbit and Modules.Orbit.Init then table.insert(HeartbeatSteps, Modules.Orbit.Init(OrbitTabFrame, createBtn, createTBox, getRoot, getPrimaryTarget)) end
if Modules.Aimbot and Modules.Aimbot.Init then table.insert(RenderSteppedSteps, Modules.Aimbot.Init(ABTabFrame, createBtn, createTBox, getRoot, getPrimaryTarget, getAllMobs)) end
if Modules.AutoClicker and Modules.AutoClicker.Init then table.insert(HeartbeatSteps, Modules.AutoClicker.Init(ClickerTabFrame, createBtn, createTBox, getRoot, getPrimaryTarget, getAllMobs)) end

CloseBtn.MouseButton1Click:Connect(function()
    resetAll()
    _G.AutoRefreshEnabled = false
    if AutoRefreshThread then task.cancel(AutoRefreshThread) end
    for _, mod in pairs(Modules) do if mod and mod.Cleanup then mod.Cleanup() end end
    for _, conn in ipairs(Connections) do conn:Disconnect() end
    ScreenGui:Destroy()
end)

-- Dual Engine Loops
table.insert(Connections, RunService.Heartbeat:Connect(function()
    pcall(function()
        local allMobs = getAllMobs()
        for _, enemy in ipairs(allMobs) do applyEffects(enemy) end
        for _, step in ipairs(HeartbeatSteps) do step() end
    end)
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    pcall(function() for _, step in ipairs(RenderSteppedSteps) do step() end end)
end))
