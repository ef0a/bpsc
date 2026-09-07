-- [[ SoulNoob Main Script - Modular Setup ]] --

local MOB_FOLDERS = {
    workspace:WaitForChild("CurrentEnemies", 5),
    workspace:WaitForChild("CurrentBosses", 5),
    workspace:WaitForChild("CurrentMegaBosses", 5),
}

local HITBOX_SIZE = 20
local HITBOX_TRANSPARENCY = 0.94
local KILL_ZONE_DISTANCE = -8                
local DEFAULT_BIND = "J"                     

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

-- Load External Orbit Module
local ORBIT_URL = "https://raw.githubusercontent.com/ef0a/bpsc/refs/heads/main/orbit.luau"
local OrbitModule = loadstring(game:HttpGet(ORBIT_URL))()

-- State
local _G = {
    HitboxEnabled = false,
    HitboxTargetMode = "Head",
    TPEnabled = false,
    TargetCFrame = nil,
    Mode = "Normal", 
    Size = HITBOX_SIZE,
    Transparency = HITBOX_TRANSPARENCY,
    Bind = DEFAULT_BIND:upper()
}

local Connections = {}

-- UI Build
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "SoulNoob_Main"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999999 

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 230, 0, 420)
Main.Position = UDim2.new(0.05, 0, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 2
Main.BorderColor3 = Color3.fromRGB(0, 255, 150)
Main.Active = true
Main.Draggable = true

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, -30, 0, 35)
Title.Text = " SoulNoob v1.18"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.new(1, 1, 1)

local CloseBtn = Instance.new("TextButton", Main)
CloseBtn.Size = UDim2.new(0, 30, 0, 35)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.BorderSizePixel = 0

-- Tabs
local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1, 0, 0, 30)
TabBar.Position = UDim2.new(0, 0, 0, 35)
TabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

local TabMainBtn = Instance.new("TextButton", TabBar)
TabMainBtn.Size = UDim2.new(0.5, 0, 1, 0)
TabMainBtn.Text = "Main"
TabMainBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
TabMainBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
TabMainBtn.Font = Enum.Font.SourceSansBold

local TabOrbitBtn = Instance.new("TextButton", TabBar)
TabOrbitBtn.Size = UDim2.new(0.5, 0, 1, 0)
TabOrbitBtn.Position = UDim2.new(0.5, 0, 0, 0)
TabOrbitBtn.Text = "Orbit"
TabOrbitBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TabOrbitBtn.TextColor3 = Color3.new(1, 1, 1)
TabOrbitBtn.Font = Enum.Font.SourceSansBold

local MainTabFrame = Instance.new("Frame", Main)
MainTabFrame.Size = UDim2.new(1, 0, 1, -65)
MainTabFrame.Position = UDim2.new(0, 0, 0, 65)
MainTabFrame.BackgroundTransparency = 1

local OrbitTabFrame = Instance.new("Frame", Main)
OrbitTabFrame.Size = UDim2.new(1, 0, 1, -65)
OrbitTabFrame.Position = UDim2.new(0, 0, 0, 65)
OrbitTabFrame.BackgroundTransparency = 1
OrbitTabFrame.Visible = false

local function createBtn(parent, pos, text, color)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(0.9, 0, 0, 32)
    b.Position = UDim2.new(0.05, 0, 0, pos)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.BorderSizePixel = 0
    return b
end

local function createTBox(parent, pos, placeholder, defaultText)
    local t = Instance.new("TextBox", parent)
    t.Size = UDim2.new(0.42, 0, 0, 28)
    t.Position = UDim2.new(pos.X, 0, 0, pos.Y)
    t.PlaceholderText = placeholder
    t.Text = defaultText
    t.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    t.TextColor3 = Color3.new(1, 1, 1)
    t.ClearTextOnFocus = false
    return t
end

-- Controls
local ModeBtn = createBtn(MainTabFrame, 10, "Target Parts: HEAD", Color3.fromRGB(0, 150, 100))
local NormalBtn = createBtn(MainTabFrame, 47, "Hitbox: Normal", Color3.fromRGB(0, 120, 200))
local FreezeBtn = createBtn(MainTabFrame, 84, "Hitbox: Stun (Freeze)", Color3.fromRGB(150, 0, 0))
local TPBtn = createBtn(MainTabFrame, 121, "SET KILL ZONE: OFF", Color3.fromRGB(150, 0, 150))

local SizeBox = createTBox(MainTabFrame, Vector2.new(0.05, 165), "Hitbox Size", "Size: ".._G.Size)
local TransBox = createTBox(MainTabFrame, Vector2.new(0.53, 165), "Transparency", "Trans: ".._G.Transparency)
local BindBox = createTBox(MainTabFrame, Vector2.new(0.05, 200), "Bind", "Bind: ".._G.Bind)

local OffBtn = createBtn(MainTabFrame, 280, "RESET / ALL OFF", Color3.fromRGB(70, 70, 70))

-- Helper Functions
local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

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

local function getPrimaryTarget()
    local myRoot = getRoot()
    if not myRoot then return nil end
    local closest, shortestDist = nil, math.huge
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
    return closest
end

-- Initialize External Orbit Component
local orbitStep = OrbitModule.Init(OrbitTabFrame, createBtn, createTBox, getRoot, getPrimaryTarget)

-- Tab Handlers
TabMainBtn.MouseButton1Click:Connect(function()
    MainTabFrame.Visible = true OrbitTabFrame.Visible = false
    TabMainBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150) TabMainBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    TabOrbitBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) TabOrbitBtn.TextColor3 = Color3.new(1, 1, 1)
end)

TabOrbitBtn.MouseButton1Click:Connect(function()
    MainTabFrame.Visible = false OrbitTabFrame.Visible = true
    TabOrbitBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150) TabOrbitBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    TabMainBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) TabMainBtn.TextColor3 = Color3.new(1, 1, 1)
end)

CloseBtn.MouseButton1Click:Connect(function()
    OrbitModule.Cleanup()
    for _, conn in ipairs(Connections) do conn:Disconnect() end
    ScreenGui:Destroy()
end)

-- Main Loop
table.insert(Connections, RunService.Heartbeat:Connect(function()
    pcall(function()
        if orbitStep then orbitStep() end
    end)
end))
