-- [[ Orbit Module - SoulNoob Component ]] --
local OrbitModule = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Internal Module State
local _state = {
    OrbitMode = "OFF",
    OrbitRadius = 35,
    OrbitSpeed = 4,
    OrbitHeight = 15,
    LockLineEnabled = true
}

-- Smart Orbit Math Variables
local swarmSeed = LocalPlayer.UserId or math.random(1, 999999)
local orbitDir = (swarmSeed % 2 == 0) and 1 or -1
local freqX = 0.3 + ((swarmSeed % 15) / 50)
local freqZ = 0.3 + ((swarmSeed % 19) / 50)
local phaseShiftX = (swarmSeed % 7) * (math.pi / 3.5)
local phaseShiftZ = (swarmSeed % 11) * (math.pi / 5.5)
local radiusVariance = 0.85 + ((swarmSeed % 30) / 100)
local heightVariance = ((swarmSeed % 9) - 4)
local waveSpeedMod = 0.6 + ((swarmSeed % 13) / 20)

-- Lock Beam Setup
local LockBeam = Instance.new("Part")
LockBeam.Name = "SoulNoob_LockBeam"
LockBeam.Anchored = true
LockBeam.CanCollide = false
LockBeam.Material = Enum.Material.Neon
LockBeam.Color = Color3.fromRGB(0, 255, 120)
LockBeam.Transparency = 1
LockBeam.Parent = workspace

function OrbitModule.Init(OrbitTabFrame, createBtn, createTBox, getRoot, getPrimaryTarget)
    -- Build UI inside the passed OrbitTabFrame
    local OrbitBtn = createBtn(OrbitTabFrame, 10, "Orbit: OFF", Color3.fromRGB(100, 100, 100))
    local LockBtn = createBtn(OrbitTabFrame, 47, "Lock Line: ON", Color3.fromRGB(0, 180, 120))

    local RadiusBox = createTBox(OrbitTabFrame, Vector2.new(0.05, 90), "Orbit Radius", "Rad: ".._state.OrbitRadius)
    local SpeedBox = createTBox(OrbitTabFrame, Vector2.new(0.53, 90), "Orbit Speed", "Spd: ".._state.OrbitSpeed)
    local HeightBox = createTBox(OrbitTabFrame, Vector2.new(0.05, 125), "Orbit Height", "Hgt: ".._state.OrbitHeight)

    -- Handlers
    OrbitBtn.MouseButton1Click:Connect(function()
        if _state.OrbitMode == "OFF" then
            _state.OrbitMode = "Normal"
            OrbitBtn.Text = "Orbit: NORMAL"
            OrbitBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        elseif _state.OrbitMode == "Normal" then
            _state.OrbitMode = "Smart"
            OrbitBtn.Text = "Orbit: SMART (Lissajous)"
            OrbitBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
        else
            _state.OrbitMode = "OFF"
            OrbitBtn.Text = "Orbit: OFF"
            OrbitBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        end
    end)

    LockBtn.MouseButton1Click:Connect(function()
        _state.LockLineEnabled = not _state.LockLineEnabled
        LockBtn.Text = "Lock Line: " .. (_state.LockLineEnabled and "ON" or "OFF")
        LockBtn.BackgroundColor3 = _state.LockLineEnabled and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(120, 120, 120)
    end)

    RadiusBox.FocusLost:Connect(function()
        local val = tonumber(RadiusBox.Text:match("%d+%.?%d*"))
        if val then _state.OrbitRadius = val RadiusBox.Text = "Rad: "..val end
    end)

    SpeedBox.FocusLost:Connect(function()
        local val = tonumber(SpeedBox.Text:match("%d+%.?%d*"))
        if val then _state.OrbitSpeed = val SpeedBox.Text = "Spd: "..val end
    end)

    HeightBox.FocusLost:Connect(function()
        local val = tonumber(HeightBox.Text:match("%d+%.?%d*"))
        if val then _state.OrbitHeight = val HeightBox.Text = "Hgt: "..val end
    end)

    -- Runtime Step (Called inside Main's Heartbeat)
    return function()
        local myRoot = getRoot()
        local primaryTarget = getPrimaryTarget()
        local targetPart = primaryTarget and (primaryTarget:FindFirstChild("HumanoidRootPart") or primaryTarget:FindFirstChildWhichIsA("BasePart"))

        if _state.OrbitMode ~= "OFF" and myRoot and targetPart then
            local t = tick() * _state.OrbitSpeed
            local x, z, h

            if _state.OrbitMode == "Smart" then
                local actualRadius = _state.OrbitRadius * radiusVariance
                x = math.cos((t * freqX * orbitDir) + phaseShiftX) * actualRadius
                z = math.sin((t * freqZ * orbitDir) + phaseShiftZ) * actualRadius
                h = (_state.OrbitHeight + heightVariance) + (math.sin(t * waveSpeedMod) * 5)
            else
                x = math.cos(t) * _state.OrbitRadius
                z = math.sin(t) * _state.OrbitRadius
                h = _state.OrbitHeight
            end

            myRoot.CFrame = CFrame.new(targetPart.Position + Vector3.new(x, h, z), targetPart.Position)
        end

        if _state.LockLineEnabled and myRoot and targetPart then
            local distance = (myRoot.Position - targetPart.Position).Magnitude
            LockBeam.Size = Vector3.new(0.2, 0.2, distance)
            LockBeam.CFrame = CFrame.new(myRoot.Position:Lerp(targetPart.Position, 0.5), targetPart.Position)
            LockBeam.Transparency = 0.4
        else
            LockBeam.Transparency = 1
        end
    end
end

function OrbitModule.Cleanup()
    _state.OrbitMode = "OFF"
    _state.LockLineEnabled = false
    if LockBeam then LockBeam:Destroy() end
end

return OrbitModule
