-- [[ SoulNoob AutoClicker Module - v1.0 ]] --

local AutoClickerModule = {}

-- Services
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Module State
local State = {
    M1Enabled = false,
    ZEnabled = false,
    XEnabled = false,
    M1Delay = 0.1,
    ZDelay = 1.0,
    XDelay = 1.0,
}

local LastPressed = {
    M1 = 0,
    Z = 0,
    X = 0,
}

-- Input Helpers
local function clickM1()
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
    if mouse1click then mouse1click() end
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
function AutoClickerModule.Init(tabFrame, createBtn, createTBox)
    -- UI Elements Setup
    local M1Btn = createBtn(tabFrame, 10, "Auto Click (M1): OFF", Color3.fromRGB(150, 0, 0))
    local M1Box = createTBox(tabFrame, Vector2.new(0.05, 47), "M1 Delay (s)", "M1 Delay: " .. State.M1Delay)

    local ZBtn  = createBtn(tabFrame, 84, "Auto Skill (Z): OFF", Color3.fromRGB(150, 0, 0))
    local ZBox  = createTBox(tabFrame, Vector2.new(0.05, 121), "Z Delay (s)", "Z Delay: " .. State.ZDelay)

    local XBtn  = createBtn(tabFrame, 158, "Auto Skill (X): OFF", Color3.fromRGB(150, 0, 0))
    local XBox  = createTBox(tabFrame, Vector2.new(0.05, 195), "X Delay (s)", "X Delay: " .. State.XDelay)

    -- Button Connections
    M1Btn.MouseButton1Click:Connect(function()
        State.M1Enabled = not State.M1Enabled
        M1Btn.Text = "Auto Click (M1): " .. (State.M1Enabled and "ON" or "OFF")
        M1Btn.BackgroundColor3 = State.M1Enabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(150, 0, 0)
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

    -- TextBox Connections
    M1Box.FocusLost:Connect(function()
        local val = tonumber(M1Box.Text:match("%d+%.?%d*"))
        if val then State.M1Delay, M1Box.Text = math.max(0.01, val), "M1 Delay: " .. math.max(0.01, val) end
    end)

    ZBox.FocusLost:Connect(function()
        local val = tonumber(ZBox.Text:match("%d+%.?%d*"))
        if val then State.ZDelay, ZBox.Text = math.max(0.05, val), "Z Delay: " .. math.max(0.05, val) end
    end)

    XBox.FocusLost:Connect(function()
        local val = tonumber(XBox.Text:match("%d+%.?%d*"))
        if val then State.XDelay, XBox.Text = math.max(0.05, val), "X Delay: " .. math.max(0.05, val) end
    end)

    -- Heartbeat Step Loop
    return function()
        local now = tick()

        if State.M1Enabled and (now - LastPressed.M1 >= State.M1Delay) then
            LastPressed.M1 = now
            clickM1()
        end

        if State.ZEnabled and (now - LastPressed.Z >= State.ZDelay) then
            LastPressed.Z = now
            pressKey(Enum.KeyCode.Z)
        end

        if State.XEnabled and (now - LastPressed.X >= State.XDelay) then
            LastPressed.X = now
            pressKey(Enum.KeyCode.X)
        end
    end
end

function AutoClickerModule.Cleanup()
    State.M1Enabled = false
    State.ZEnabled = false
    State.XEnabled = false
end

return AutoClickerModule
