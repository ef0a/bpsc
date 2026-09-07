-- [[ SoulNoob Multi-Tool v1.16 - Orbit & Target Lock Line ]] --

-- // EASY CONFIGURATION //
local MOB_FOLDERS = {
    workspace:WaitForChild("CurrentEnemies", 5),
    workspace:WaitForChild("CurrentBosses", 5),
    workspace:WaitForChild("CurrentMegaBosses", 5),
    -- workspace.World1.npc2, -- Add extra folders here 
}

local HITBOX_SIZE = 20
local HITBOX_TRANSPARENCY = 0.7
local KILL_ZONE_DISTANCE = -8                
local DEFAULT_BIND = "G"                     

-- Orbit Defaults
local DEFAULT_ORBIT_RADIUS = 35
local DEFAULT_ORBIT_SPEED = 5
local DEFAULT_ORBIT_HEIGHT = 15

-- Limbs targeted to trigger multi-part damage hits (R6 & R15)
local TARGET_LIMBS = {
    "HumanoidRootPart", "Torso", "Head",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg", -- R6
    "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", 
    "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", 
    "LeftLowerLeg", "RightLowerLeg" -- R15
}

-- Original part size cache for clean resetting
local OriginalSizes = {}

-- // CORE SERVICES //
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- // SMART ORBIT CHAOS SEED //
local swarmSeed = LocalPlayer.UserId
if not swarmSeed or swarmSeed < 1 then swarmSeed = math.random(1, 999999) end

local orbitDir = (swarmSeed % 2 == 0) and 1 or -1
local freqX = 0.3 + ((swarmSeed % 15) / 50)
local freqZ = 0.3 + ((swarmSeed % 19) / 50)
local phaseShiftX = (swarmSeed % 7) * (math.pi / 3.5)
local phaseShiftZ = (swarmSeed % 11) * (math.pi / 5.5)
local radiusVariance = 0.85 + ((swarmSeed % 30) / 100)
local heightVariance = ((swarmSeed % 9) - 4)
local waveSpeedMod = 0.6 + ((swarmSeed % 13) / 20)

-- // STATE //
local _G = {
    HitboxEnabled = false,
    TPEnabled = false,
    TargetCFrame = nil,
    TargetMode = "Mobs", 
    Mode = "Normal", 
    Size = HITBOX_SIZE,
    Transparency = HITBOX_TRANSPARENCY,
    Bind = DEFAULT_BIND:upper(),
    
    -- New Orbit & Lock Line Settings
    OrbitMode = "OFF", -- "OFF", "Normal", "Smart"
    OrbitRadius = DEFAULT_ORBIT_RADIUS,
    OrbitSpeed = DEFAULT_ORBIT_SPEED,
    OrbitHeight = DEFAULT_ORBIT_HEIGHT,
    LockLineEnabled = true
}

-- Connections tracker for clean script unloading
local Connections = {}

-- Visual Target Lock Line (Beam Part)
local LockBeam = Instance.new("Part")
LockBeam.Name = "SoulNoob_LockBeam"
LockBeam.Anchored = true
LockBeam.CanCollide = false
LockBeam.Material = Enum.Material.Neon
LockBeam.Color = Color3.fromRGB(0, 255, 120)
LockBeam.Transparency = 1
LockBeam.Parent = workspace

-- // UI SETUP //
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "SoulNoob_v116"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999 

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 230, 0, 500)
Main.Position = UDim2.new(0.05, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 2
Main.BorderColor3 = Color3.fromRGB(0, 255, 150)
Main.Active = true
Main.Draggable = true

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -30, 0, 35)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Text = " SoulNoob v1.16"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.new(1, 1, 1)

-- Close ('X') Button
local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 30, 0, 35)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0

local function btn(pos, text, color)
    local b = Instance.new("TextButton", Main)
    b.Size = UDim2.new(0.9, 0, 0, 32)
    b.Position = UDim2.new(0.05, 0, 0, pos)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.BorderSizePixel = 0
    return b
end

local function tbox(pos, placeholder, defaultText)
    local t = Instance.new("TextBox", Main)
    t.Size = UDim2.new(0.42, 0, 0, 28)
    t.Position = UDim2.new(pos.X, 0, 0, pos.Y)
    t.PlaceholderText = placeholder
    t.Text = defaultText
    t.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    t.TextColor3 = Color3.new(1, 1, 1)
    t.ClearTextOnFocus = false
    return t
end

-- UI Controls
local TargetBtn = btn(40, "Target: MOBS", Color3.fromRGB(0, 150, 100))
local NormalBtn = btn(77, "Hitbox: Normal", Color3.fromRGB(0, 120, 200))
local FreezeBtn = btn(114, "Hitbox: Stun (Freeze)", Color3.fromRGB(150, 0, 0))
local TPBtn = btn(151, "SET KILL ZONE: OFF", Color3.fromRGB(150, 0, 150))
local OrbitBtn = btn(188, "Orbit: OFF", Color3.fromRGB(100, 100, 100))
local LockBtn = btn(225, "Lock Line: ON", Color3.fromRGB(0, 180, 120))

-- Text Input Grid
local SizeBox = tbox(Vector2.new(0.05, 265), "Hitbox Size", "Size: ".._G.Size)
local TransBox = tbox(Vector2.new(0.53, 265), "Transparency", "Trans: ".._G.Transparency)
local RadiusBox = tbox(Vector2.new(0.05, 300), "Orbit Radius", "Rad: ".._G.OrbitRadius)
local SpeedBox = tbox(Vector2.new(0.53, 300), "Orbit Speed", "Spd: ".._G.OrbitSpeed)
local HeightBox = tbox(Vector2.new(0.05, 335), "Orbit Height", "Hgt: ".._G.OrbitHeight)
local BindBox = tbox(Vector2.new(0.53, 335), "Bind", "Bind: ".._G.Bind)

local OffBtn = btn(380, "RESET / ALL OFF", Color3.fromRGB(70, 70, 70))

-- // LOGIC //

local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Helper to retrieve valid target models
local function getAllMobs()
    local mobs = {}
    for _, folder in ipairs(MOB_FOLDERS) do
        if folder and folder:IsA("Instance") then
            for _, descendant in ipairs(folder:GetDescendants()) do
                if descendant:IsA("Model") and descendant:FindFirstChildOfClass("Humanoid") then
                    table.insert(mobs, descendant)
                end
            end
        end
    end
    return mobs
end

-- Get closest target for Orbit and Lock Line
local function getPrimaryTarget()
    local myRoot = getRoot()
    if not myRoot then return nil end

    local closest, shortestDist = nil, math.huge

    if _G.TargetMode == "Mobs" then
        for _, mob in ipairs(getAllMobs()) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
            if hum and hum.Health > 0 and root then
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = mob
                end
            end
        end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local root = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and root then
                    local dist = (myRoot.Position - root.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = plr.Character
                    end
                end
            end
        end
    end

    return closest
end

local function cleanModel(model)
    if not model then return end
    for _, p in pairs(model:GetChildren()) do
        if p:IsA("BasePart") then
            if OriginalSizes[p] then
                p.Size = OriginalSizes[p]
            end
            p.Transparency = 0
            p.Material = Enum.Material.Plastic
            p.CanCollide = true
            p.CanTouch = true
            p.Anchored = false
            p.Massless = false
        end
    end
end

local function resetAll()
    _G.HitboxEnabled = false
    _G.TPEnabled = false
    _G.OrbitMode = "OFF"
    _G.TargetCFrame = nil
    
    TPBtn.Text = "SET KILL ZONE: OFF"
    TPBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
    OrbitBtn.Text = "Orbit: OFF"
    OrbitBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    LockBeam.Transparency = 1
    
    for _, enemy in ipairs(getAllMobs()) do 
        cleanModel(enemy) 
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then 
            cleanModel(plr.Character) 
        end
    end
end

local function toggleKillZone()
    local myRoot = getRoot()
    if not myRoot then return end
    _G.TPEnabled = not _G.TPEnabled
    if _G.TPEnabled then
        _G.TargetCFrame = myRoot.CFrame * CFrame.new(0, 0, KILL_ZONE_DISTANCE)
        TPBtn.Text = "KILL ZONE: LOCKED"
        TPBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
    else
        _G.TargetCFrame = nil
        TPBtn.Text = "SET KILL ZONE: OFF"
        TPBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
    end
end

local function applyEffects(model)
    if not model or model == LocalPlayer.Character then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local root = model:FindFirstChild("HumanoidRootPart")
    
    -- Hitbox Expansion Engine
    if _G.HitboxEnabled then
        for _, limbName in ipairs(TARGET_LIMBS) do
            local p = model:FindFirstChild(limbName)
            if p and p:IsA("BasePart") then
                if not OriginalSizes[p] then
                    OriginalSizes[p] = p.Size
                end
                
                p.Size = Vector3.new(_G.Size, _G.Size, _G.Size)
                p.Transparency = _G.Transparency
                p.Material = Enum.Material.Neon
                p.Color = (_G.Mode == "Freeze") and Color3.new(1, 0, 0) or Color3.new(1, 1, 0)
                p.Massless = true
                p.CanTouch = true

                if _G.Mode == "Freeze" then
                    p.Anchored = true
                    p.CanCollide = false 
                else
                    p.Anchored = false
                    p.CanCollide = true 
                end

                if _G.TPEnabled then p.CanCollide = false end
            end
        end
    end

    -- Kill Zone Lock Engine
    if _G.TPEnabled and _G.TargetCFrame and root then
        root.CFrame = _G.TargetCFrame
        root.Velocity = Vector3.zero 
        root.RotVelocity = Vector3.zero
    end
end

-- // CONNECTIONS & BUTTON HANDLERS //

table.insert(Connections, UIS.InputBegan:Connect(function(input, processed)
    if processed then return end 
    if input.KeyCode.Name == _G.Bind then toggleKillZone() end
end))

TargetBtn.MouseButton1Click:Connect(function()
    if _G.TargetMode == "Mobs" then
        _G.TargetMode = "Players"
        TargetBtn.Text = "Target: PLAYERS"
        TargetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        _G.TargetMode = "Mobs"
        TargetBtn.Text = "Target: MOBS"
        TargetBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    end
end)

TPBtn.MouseButton1Click:Connect(toggleKillZone)
NormalBtn.MouseButton1Click:Connect(function() _G.HitboxEnabled = true _G.Mode = "Normal" end)
FreezeBtn.MouseButton1Click:Connect(function() _G.HitboxEnabled = true _G.Mode = "Freeze" end)

OrbitBtn.MouseButton1Click:Connect(function()
    if _G.OrbitMode == "OFF" then
        _G.OrbitMode = "Normal"
        OrbitBtn.Text = "Orbit: NORMAL"
        OrbitBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    elseif _G.OrbitMode == "Normal" then
        _G.OrbitMode = "Smart"
        OrbitBtn.Text = "Orbit: SMART (Lissajous)"
        OrbitBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
    else
        _G.OrbitMode = "OFF"
        OrbitBtn.Text = "Orbit: OFF"
        OrbitBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

LockBtn.MouseButton1Click:Connect(function()
    _G.LockLineEnabled = not _G.LockLineEnabled
    LockBtn.Text = "Lock Line: " .. (_G.LockLineEnabled and "ON" or "OFF")
    LockBtn.BackgroundColor3 = _G.LockLineEnabled and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(120, 120, 120)
end)

OffBtn.MouseButton1Click:Connect(resetAll)

CloseBtn.MouseButton1Click:Connect(function()
    resetAll()
    for _, conn in ipairs(Connections) do
        conn:Disconnect()
    end
    LockBeam:Destroy()
    ScreenGui:Destroy()
end)

-- Text Box Handlers
SizeBox.FocusLost:Connect(function()
    local val = tonumber(SizeBox.Text:match("%d+%.?%d*"))
    if val then _G.Size = val SizeBox.Text = "Size: "..val end
end)

TransBox.FocusLost:Connect(function()
    local val = tonumber(TransBox.Text:match("%d+%.?%d*"))
    if val then _G.Transparency = math.clamp(val, 0, 1) TransBox.Text = "Trans: ".._G.Transparency end
end)

RadiusBox.FocusLost:Connect(function()
    local val = tonumber(RadiusBox.Text:match("%d+%.?%d*"))
    if val then _G.OrbitRadius = val RadiusBox.Text = "Rad: "..val end
end)

SpeedBox.FocusLost:Connect(function()
    local val = tonumber(SpeedBox.Text:match("%d+%.?%d*"))
    if val then _G.OrbitSpeed = val SpeedBox.Text = "Spd: "..val end
end)

HeightBox.FocusLost:Connect(function()
    local val = tonumber(HeightBox.Text:match("%d+%.?%d*"))
    if val then _G.OrbitHeight = val HeightBox.Text = "Hgt: "..val end
end)

BindBox.FocusLost:Connect(function()
    local key = BindBox.Text:gsub("Bind: ", ""):upper()
    if #key == 1 then _G.Bind = key BindBox.Text = "Bind: "..key end
end)

-- // MAIN HEARTBEAT RUNTIME //
table.insert(Connections, RunService.Heartbeat:Connect(function()
    pcall(function()
        local myRoot = getRoot()
        local primaryTarget = getPrimaryTarget()
        local targetPart = primaryTarget and (primaryTarget:FindFirstChild("HumanoidRootPart") or primaryTarget:FindFirstChildWhichIsA("BasePart"))

        -- 1. Orbit Engine Loop
        if _G.OrbitMode ~= "OFF" and myRoot and targetPart then
            local t = tick() * _G.OrbitSpeed
            local x, z, h

            if _G.OrbitMode == "Smart" then
                -- Lissajous Chaos Orbit Math
                local actualRadius = _G.OrbitRadius * radiusVariance
                x = math.cos((t * freqX * orbitDir) + phaseShiftX) * actualRadius
                z = math.sin((t * freqZ * orbitDir) + phaseShiftZ) * actualRadius
                h = (_G.OrbitHeight + heightVariance) + (math.sin(t * waveSpeedMod) * 5)
            else
                -- Normal Circular Orbit
                x = math.cos(t) * _G.OrbitRadius
                z = math.sin(t) * _G.OrbitRadius
                h = _G.OrbitHeight
            end

            myRoot.CFrame = CFrame.new(targetPart.Position + Vector3.new(x, h, z), targetPart.Position)
        end

        -- 2. Target Lock Line Render Loop
        if _G.LockLineEnabled and myRoot and targetPart then
            local distance = (myRoot.Position - targetPart.Position).Magnitude
            LockBeam.Size = Vector3.new(0.2, 0.2, distance)
            LockBeam.CFrame = CFrame.new(myRoot.Position:Lerp(targetPart.Position, 0.5), targetPart.Position)
            LockBeam.Transparency = 0.4
        else
            LockBeam.Transparency = 1
        end

        -- 3. Multi-Limb Hitbox Expansion Loop
        if _G.TargetMode == "Mobs" then
            for _, enemy in ipairs(getAllMobs()) do
                applyEffects(enemy)
            end
        else
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then 
                    applyEffects(plr.Character) 
                end
            end
        end
    end)
end))
