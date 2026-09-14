-- [[ XP Orb Collection Method Tester ]] --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local BulletsFolder = workspace:WaitForChild("Bullets")

-- State
local Toggles = {
    CFrameMagnet = false,
    TouchInterest = false,
    PhysicsPull = false
}
local Connections = {}

-- UI Setup
local ScreenGui = Instance.new("ScreenGui", PlayerGui)
ScreenGui.Name = "OrbTester_UI"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 180)
Frame.Position = UDim2.new(0.8, 0, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 150)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "XP Orb Collector Tester"
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16

local function createToggleBtn(pos, text, key)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.Text = text .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0

    btn.MouseButton1Click:Connect(function()
        Toggles[key] = not Toggles[key]
        if Toggles[key] then
            btn.Text = text .. ": ON"
            btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
        else
            btn.Text = text .. ": OFF"
            btn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        end
    end)
    return btn
end

createToggleBtn(40, "Method A (CFrame Magnet)", "CFrameMagnet")
createToggleBtn(85, "Method B (Touch Interest)", "TouchInterest")
createToggleBtn(130, "Method C (Physics Pull)", "PhysicsPull")

-- Helper: Get Player Root Part
local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-- Collection Logic Loop
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local root = getRoot()
    if not root then return end

    for _, orb in ipairs(BulletsFolder:GetChildren()) do
        if orb.Name == "Ignore1" and orb:IsA("BasePart") then
            
            -- Method A: CFrame Magnet
            if Toggles.CFrameMagnet then
                orb.CFrame = root.CFrame
            end

            -- Method B: Virtual FireTouchInterest
            if Toggles.TouchInterest and firetouchinterest then
                firetouchinterest(root, orb, 0)
                firetouchinterest(root, orb, 1)
            end

            -- Method C: Physics Velocity Pull
            if Toggles.PhysicsPull then
                local direction = (root.Position - orb.Position).Unit
                orb.AssemblyLinearVelocity = direction * 100
            end

        end
    end
end))

-- Instant Catch on New Orbs Spawning
table.insert(Connections, BulletsFolder.ChildAdded:Connect(function(orb)
    if orb.Name == "Ignore1" and orb:IsA("BasePart") then
        task.wait() -- Brief pause to ensure part is initialized
        local root = getRoot()
        if not root then return end

        if Toggles.CFrameMagnet then
            orb.CFrame = root.CFrame
        end

        if Toggles.TouchInterest and firetouchinterest then
            firetouchinterest(root, orb, 0)
            firetouchinterest(root, orb, 1)
        end
    end
end))
