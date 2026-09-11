-- [[ AB (Aimbot) Module - SoulNoob Component v1.34 ]] --
local ABModule = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

-- Internal Module State
local _state = {
    Enabled = false,
    AutoMode = false,
    Smoothness = 0.5,
    TargetPart = "Head",
    
    -- v1.34 State Additions
    StandbyDelay = 7,     -- Seconds to wait before zooming out (5-10s range)
    InStandby = false,
    StandbyStartTime = 0,
    IsZoomedIn = false
}

-- Virtual Key Helper for Camera Zoom
local function triggerKey(keyCode, amount)
    task.spawn(function()
        for i = 1, (amount or 6) do
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            task.wait(0.02)
        end
    end)
end

local function zoomIn()
    triggerKey(Enum.KeyCode.I, 8)
    _state.IsZoomedIn = true
end

local function zoomOut()
    triggerKey(Enum.KeyCode.O, 8)
    _state.IsZoomedIn = false
end

function ABModule.Init(ABTabFrame, createBtn, createTBox, getRoot, getPrimaryTarget, getAllMobs)
    -- Build UI inside the passed ABTabFrame
    local ABToggleBtn    = createBtn(ABTabFrame, 10, "AB (Aimbot): OFF", Color3.fromRGB(100, 100, 100))
    local PartBtn        = createBtn(ABTabFrame, 47, "Target: HEAD", Color3.fromRGB(0, 150, 100))
    local SmoothBox      = createTBox(ABTabFrame, Vector2.new(0.05, 90), "Smoothness (0.1 - 1)", "Smooth: ".._state.Smoothness)
    local AutoModeBtn    = createBtn(ABTabFrame, 125, "Auto-Standby (No Mobs): OFF", Color3.fromRGB(100, 40, 40))

    -- UI Handlers
    ABToggleBtn.MouseButton1Click:Connect(function()
        _state.Enabled = not _state.Enabled
        if _state.Enabled then
            ABToggleBtn.Text = "AB (Aimbot): ON"
            ABToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
            zoomIn() -- Force zoom-in on manual enable
        else
            ABToggleBtn.Text = "AB (Aimbot): OFF"
            ABToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            _state.InStandby = false
            if _state.IsZoomedIn then zoomOut() end -- Zoom back out on manual disable
        end
    end)

    PartBtn.MouseButton1Click:Connect(function()
        _state.TargetPart = (_state.TargetPart == "Head") and "HumanoidRootPart" or "Head"
        PartBtn.Text = "Target: " .. (_state.TargetPart == "Head" and "HEAD" or "TORSO")
    end)

    SmoothBox.FocusLost:Connect(function()
        local val = tonumber(SmoothBox.Text:match("%d+%.?%d*"))
        if val then
            _state.Smoothness = math.clamp(val, 0.05, 1)
            SmoothBox.Text = "Smooth: " .. _state.Smoothness
        end
    end)

    AutoModeBtn.MouseButton1Click:Connect(function()
        _state.AutoMode = not _state.AutoMode
        AutoModeBtn.Text = "Auto-Standby (No Mobs): " .. (_state.AutoMode and "ON" or "OFF")
        AutoModeBtn.BackgroundColor3 = _state.AutoMode and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(100, 40, 40)
    end)

    -- Camera Lock Step Routine
    return function()
        if not _state.Enabled then return end

        -- 1. Check Primary Priority Target
        local targetMob = getPrimaryTarget()

        -- 2. Check Fallback Across All Enemy Folders
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

        -- 3. No enemies present
        if not targetMob then
            if _state.AutoMode then
                if not _state.InStandby then
                    -- Start buffer timer
                    _state.InStandby = true
                    _state.StandbyStartTime = tick()
                else
                    local elapsed = tick() - _state.StandbyStartTime
                    local remaining = math.ceil(_state.StandbyDelay - elapsed)

                    if remaining > 0 then
                        ABToggleBtn.Text = "AB: WAITING (" .. remaining .. "s)"
                        ABToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
                    else
                        -- Buffer expired! Zoom out to 3rd person
                        ABToggleBtn.Text = "AB: STANDBY (OUT)"
                        ABToggleBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
                        if _state.IsZoomedIn then
                            zoomOut()
                        end
                    end
                end
            end
            return -- Stop camera lock
        end

        -- 4. Enemy detected! Reset Standby state & engage camera lock
        if _state.InStandby or not _state.IsZoomedIn then
            _state.InStandby = false
            zoomIn() -- Zoom into 1st person automatically
        end

        if _state.AutoMode and ABToggleBtn.Text ~= "AB (Aimbot): ON" then
            ABToggleBtn.Text = "AB (Aimbot): ON"
            ABToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        end

        local targetPart = targetMob:FindFirstChild(_state.TargetPart) or targetMob:FindFirstChild("HumanoidRootPart")
        if not targetPart then return end

        -- Camera Lock Step
        local camPos = CurrentCamera.CFrame.Position
        local targetPos = targetPart.Position
        local targetCFrame = CFrame.new(camPos, targetPos)

        if _state.Smoothness >= 1 then
            CurrentCamera.CFrame = targetCFrame
        else
            CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(targetCFrame, _state.Smoothness)
        end
    end
end

function ABModule.Cleanup()
    _state.Enabled = false
    _state.AutoMode = false
    _state.InStandby = false
    _state.IsZoomedIn = false
end

return ABModule
