local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Reference the ServerBrowser GUI inside PlayerGui
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local serverBrowserGui = playerGui:FindFirstChild("ServerBrowser")

if serverBrowserGui then
    -- 1. Make the main frame visible on your screen
    local mainFrame = serverBrowserGui:FindFirstChild("MainFrame")
    if mainFrame then
        mainFrame.Visible = true
    end

    -- 2. Ensure the local script is enabled
    local scriptRef = serverBrowserGui:FindFirstChild("ServerBrowserScript")
    if scriptRef and scriptRef:IsA("LocalScript") then
        scriptRef.Disabled = false
    end

    -- 3. Request fresh server list data from the server remote
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local serverBrowserRemote = remotes:FindFirstChild("ServerBrowser")
        if serverBrowserRemote then
            serverBrowserRemote:FireServer("Refresh")
        end
    end
else
    warn("ServerBrowser GUI not found in PlayerGui.")
end
