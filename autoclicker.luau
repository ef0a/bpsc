-- [[ SoulNoob AutoClicker Module - v1.38 ]] --

local AutoClickerModule = {}

-- Services
local VirtualInputManager = game:GetService("VirtualInputManager")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrentCamera = Workspace.CurrentCamera

-- Base screen size & ratios
local BASE_WIDTH = 1800
local BASE_HEIGHT = 1014
local TARGET_X = 486 + (216 / 2) -- Center X: 594
local TARGET_Y = 410 + (177 / 2) -- Center Y: 498.5

local RATIO_X = TARGET_X / BASE_WIDTH   -- ~0.3300
local RATIO_Y = TARGET_Y / BASE_HEIGHT  -- ~0.4916

-- Module State
local State = {
    M1Enabled = false,
    M1AutoStandby = false,
    LobbyClickEnabled = false,
    LobbyClickDelay = 3.0,
    ZEnabled = false,
    XEnabled = false,
    NEnabled = false,
    AutoSkipEnabled = false, -- New v1.38 feature
    M1Delay = 0.1,
    ZDelay = 1.0,
    XDelay = 1.0,
    NDelay = 5.0,
    AutoSkipDelay = 4.0,     -- 4s interval for remote firing
    M1Bind = "=",
    
    -- Standby State Tracker
    StandbyDelay = 7,
    InStandby = false,
    StandbyStartTime = 0
}

local LastPressed = {
    M1 = 0,
    Lobby = 0,
    Z = 0,
    X = 0,
    N = 0,
    AutoSkip = 0,
}

local Connections = {}

-- Helper to safely fire the Vote/Skip Remote
local function fireSkipRemote()
    pcall(function()
        local voteEvents = ReplicatedStorage:FindFirstChild("VoteEvents")
        if voteEvents then
            local submitVote = voteEvents:FindFirstChild("SubmitVote")
            if submitVote and submitVote:IsA("RemoteEvent") then
                submitVote:FireServer(true)
            end
        end
    end)
end

-- Input Helpers
local function clickM1()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
    if mouse1click then mouse1click() end
end

local function clickPosition(x, y)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function pressKey(keyCode)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.01)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
    if keypress and keyrelease then
        keypress(keyCode.Value)
        task.wait(0.01)
        keyrelease(keyCode.Value)
    end
end

-- Module Init
function AutoClickerModule.Init(tabFrame, createBtn, createTBox, getRoot, getPrimaryTarget, getAllMobs)
    -- UI Elements Setup
    local M1Btn          = createBtn(tabFrame, 10, "Auto Click (M1): OFF", Color3.fromRGB(150, 0, 0))
    local M1StandbyBtn   = createBtn(tabFrame, 47, "M1 Auto-Standby: OFF", Color3.fromRGB(100, 40, 40))
    local LobbyClickBtn  = createBtn(tabFrame, 84, "Lobby Clicker: OFF", Color3.fromRGB(100, 40, 40))
    
    local M1Box          = createTBox(tabFrame, Vector2.new(0.05, 121), "M1 Delay (s)", "M1 Delay: " .. State.M1Delay)
    local BindBox        = createTBox(tabFrame, Vector2.new(0.53, 121), "M1 Bind", "Bind: " .. State.M1Bind)

    local ZBtn           = createBtn(tabFrame, 158, "Auto Skill (Z): OFF", Color3.fromRGB(150, 0, 0))
    local ZBox           = createTBox(tabFrame, Vector2.new(0.05, 195), "Z Delay (s)", "Z Delay: " .. State.ZDelay)

    local XBtn           = createBtn(tabFrame, 232, "Auto Skill (X): OFF", Color3.fromRGB(150, 0, 0))
    local XBox           = createTBox(tabFrame, Vector2.new(0.05, 269), "X Delay (s)", "X Delay: " .. State.XDelay)

    local NBtn           = createBtn(tabFrame, 306, "Auto Skill (N): OFF", Color3.fromRGB(150, 0, 0))
    local NBox           = createTBox(tabFrame, Vector2.new(0.05, 343), "N Delay (s)", "N Delay: " .. State.NDelay)

    -- New v1.38 Controls: Auto Skip Cutscenes
    local SkipBtn        = createBtn(tabFrame, 380, "Auto Skip Cutscene: OFF", Color3.fromRGB(150, 0, 0))

    local function toggleM1()
        State.M1Enabled = not State.M1Enabled
        if State.M1Enabled then
            M1Btn.Text = "Auto Click (M1): ON"
            M1Btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        else
            M1Btn.Text = "Auto Click (M1): OFF"
            M1Btn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            State.InStandby = false
        end
    end

    -- Button Connections
    M1Btn.MouseButton1Click:Connect(toggleM1)

    M1StandbyBtn.MouseButton1Click:Connect(function()
        State.M1AutoStandby = not State.M1AutoStandby
        M1StandbyBtn.Text = "M1 Auto-Standby: " .. (State.M1AutoStandby and "ON" or "OFF")
        M1StandbyBtn.BackgroundColor3 = State.M1AutoStandby and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(100, 40, 40)
    end)

    LobbyClickBtn.MouseButton1Click:Connect(function()
        State.LobbyClickEnabled = not State.LobbyClickEnabled
        LobbyClickBtn.Text = "Lobby Clicker: " .. (State.LobbyClickEnabled and "ON" or "OFF")
        LobbyClickBtn.BackgroundColor3 = State.LobbyClickEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(100, 40, 40)
    end)

    ZBtn.MouseButton1Click:Connect(function()
        State.ZEnabled = not State.ZEnabled
        ZBtn.Text = "Auto Skill (Z): " .. (State.ZEnabled and "ON" or "OFF")
        ZBtn.BackgroundColor3 = State.ZEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(150, 0, 0)
    end)

    XBtn.MouseButton1Click:Connect(function()
        State.XEnabled = not State.XEnabled
        XBtn.Text = "Auto Skill (X): " .. (State.XEnabled and "ON" or "OFF")
        XBtn.BackgroundColor3 = State.XEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(150, 0, 0)
    end)

    NBtn.MouseButton1Click:Connect(function()
        State.NEnabled = not State.NEnabled
        NBtn.Text = "Auto Skill (N): " .. (State.NEnabled and "ON" or "OFF")
        NBtn.BackgroundColor3 = State.NEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(150, 0, 0)
    end)

    SkipBtn.MouseButton1Click:Connect(function()
        State.AutoSkipEnabled = not State.AutoSkipEnabled
        SkipBtn.Text = "Auto Skip Cutscene: " .. (State.AutoSkipEnabled and "ON" or "OFF")
        SkipBtn.BackgroundColor3 = State.AutoSkipEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(150, 0, 0)
    end)

    -- Keybind Listener
    table.insert(Connections, UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        local keyName = input.KeyCode.Name
        if input.KeyCode == Enum.KeyCode.Equals then keyName = "=" end
        
        if keyName:upper() == State.M1Bind:upper() then
            toggleM1()
        end
    end))

    -- TextBox Connections
    M1Box.FocusLost:Connect(function()
        local val = tonumber(M1Box.Text:match("%d+%.?%d*"))
        if val then State.M1Delay, M1Box.Text = math.max(0.01, val), "M1 Delay: " .. math.max(0.01, val) end
    end)

    BindBox.FocusLost:Connect(function()
        local k = BindBox.Text:gsub("Bind: ", ""):gsub("%s+", "")
        if #k >= 1 then 
            State.M1Bind = k:sub(1,1)
            BindBox.Text = "Bind: " .. State.M1Bind 
        end
    end)

    ZBox.FocusLost:Connect(function()
        local val = tonumber(ZBox.Text:match("%d+%.?%d*"))
        if val then State.ZDelay, ZBox.Text = math.max(0.05, val), "Z Delay: " .. math.max(0.05, val) end
    end)

    XBox.FocusLost:Connect(function()
        local val = tonumber(XBox.Text:match("%d+%.?%d*"))
        if val then State.XDelay, XBox.Text = math.max(0.05, val), "X Delay: " .. math.max(0.05, val) end
    end)

    NBox.FocusLost:Connect(function()
        local val = tonumber(NBox.Text:match("%d+%.?%d*"))
        if val then State.NDelay, NBox.Text = math.max(0.1, val), "N Delay: " .. math.max(0.1, val) end
    end)

    -- Heartbeat Step Loop
    return function()
        local now = tick()

        -- Check for active mobs if M1 and Auto-Standby are active
        local shouldClickM1 = State.M1Enabled
        local bufferExpired = false

        if State.M1Enabled and State.M1AutoStandby then
            local targetMob = getPrimaryTarget and getPrimaryTarget()
            if not targetMob and getAllMobs then
                local allMobs = getAllMobs()
                for _, mob in ipairs(allMobs) do
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        targetMob = mob
                        break
                    end
                end
            end

            if not targetMob then
                if not State.InStandby then
                    State.InStandby = true
                    State.StandbyStartTime = now
                else
                    local elapsed = now - State.StandbyStartTime
                    local remaining = math.ceil(State.StandbyDelay - elapsed)

                    if remaining > 0 then
                        M1Btn.Text = "M1: WAITING (" .. remaining .. "s)"
                        M1Btn.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
                    else
                        M1Btn.Text = "M1: STANDBY (PAUSED)"
                        M1Btn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
                        shouldClickM1 = false
                        bufferExpired = true
                    end
                end
            else
                State.InStandby = false
                if M1Btn.Text ~= "Auto Click (M1): ON" then
                    M1Btn.Text = "Auto Click (M1): ON"
                    M1Btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
                end
            end
        end

        -- Execute M1 Clicks (Normal Combat)
        if shouldClickM1 and (now - LastPressed.M1 >= State.M1Delay) then
            LastPressed.M1 = now
            clickM1()
        end

        -- Execute Lobby Position Clicks
        if State.LobbyClickEnabled and bufferExpired then
            if now - LastPressed.Lobby >= State.LobbyClickDelay then
                LastPressed.Lobby = now
                local viewport = CurrentCamera.ViewportSize
                local clickX = math.floor(viewport.X * RATIO_X)
                local clickY = math.floor(viewport.Y * RATIO_Y)
                clickPosition(clickX, clickY)
            end
        end

        -- Skill key clickers
        if State.ZEnabled and (now - LastPressed.Z >= State.ZDelay) then
            LastPressed.Z = now
            pressKey(Enum.KeyCode.Z)
        end

        if State.XEnabled and (now - LastPressed.X >= State.XDelay) then
            LastPressed.X = now
            pressKey(Enum.KeyCode.X)
        end

        -- Auto Skill (N) Loop
        if State.NEnabled and (now - LastPressed.N >= State.NDelay) then
            LastPressed.N = now
            pressKey(Enum.KeyCode.N)
        end

        -- Auto Skip Remote Loop (Every 4 seconds)
        if State.AutoSkipEnabled and (now - LastPressed.AutoSkip >= State.AutoSkipDelay) then
            LastPressed.AutoSkip = now
            fireSkipRemote()
        end
    end
end

function AutoClickerModule.Cleanup()
    State.M1Enabled = false
    State.M1AutoStandby = false
    State.LobbyClickEnabled = false
    State.InStandby = false
    State.ZEnabled = false
    State.XEnabled = false
    State.NEnabled = false
    State.AutoSkipEnabled = false
    for _, conn in ipairs(Connections) do conn:Disconnect() end
end

return AutoClickerModule
