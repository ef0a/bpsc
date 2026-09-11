-- [[ AB (Aimbot) Module - SoulNoob Component v1.33 ]] --
local ABModule = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

-- Internal Module State
local _state = {
    Enabled = false,
    AutoDisable = false, -- Auto-turn off when no enemies exist
    Smoothness = 0.5,   -- 1 = Instant Snap, Lower = Smoother
    TargetPart = "Head"
}

function ABModule.Init(ABTabFrame, createBtn, createTBox, getRoot, getPrimaryTarget)
    -- Build UI inside the passed ABTabFrame
    local ABToggleBtn    = createBtn(ABTabFrame, 10, "AB (Aimbot): OFF", Color3.fromRGB(100, 100, 100))
    local PartBtn        = createBtn(ABTabFrame, 47, "Target: HEAD", Color3.fromRGB(0, 150, 100))
    local SmoothBox      = createTBox(ABTabFrame, Vector2.new(0.05, 90), "Smoothness (0.1 - 1)", "Smooth: ".._state.Smoothness)
    local AutoDisableBtn = createBtn(ABTabFrame, 125, "Auto-Off (No Mobs): OFF", Color3.fromRGB(100, 40, 40))

    -- UI Handlers
    ABToggleBtn.MouseButton1Click:Connect(function()
        _state.Enabled = not _state.Enabled
        ABToggleBtn.Text = "AB (Aimbot): " .. (_state.Enabled and "ON" or "OFF")
        ABToggleBtn.BackgroundColor3 = _state.Enabled and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(100, 100, 100)
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

    AutoDisableBtn.MouseButton1Click:Connect(function()
        _state.AutoDisable = not _state.AutoDisable
        AutoDisableBtn.Text = "Auto-Off (No Mobs): " .. (_state.AutoDisable and "ON" or "OFF")
        AutoDisableBtn.BackgroundColor3 = _state.AutoDisable and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(100, 40, 40)
    end)

    -- Camera Lock Step Routine
    return function()
        if not _state.Enabled then return end

        local targetMob = getPrimaryTarget()
        
        -- If no target is returned / no enemies present
        if not targetMob then
            if _state.AutoDisable then
                _state.Enabled = false
                ABToggleBtn.Text = "AB (Aimbot): OFF"
                ABToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            end
            return
        end

        local targetPart = targetMob:FindFirstChild(_state.TargetPart) or targetMob:FindFirstChild("HumanoidRootPart")
        if not targetPart then return end

        -- Calculate CFrame pointing from camera directly to target
        local camPos = CurrentCamera.CFrame.Position
        local targetPos = targetPart.Position
        local targetCFrame = CFrame.new(camPos, targetPos)

        -- Interpolate camera orientation smoothly toward target
        if _state.Smoothness >= 1 then
            CurrentCamera.CFrame = targetCFrame
        else
            CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(targetCFrame, _state.Smoothness)
        end
    end
end

function ABModule.Cleanup()
    _state.Enabled = false
    _state.AutoDisable = false
end

return ABModule
