-- [[ SoulNoob Priority System Module - v1.31 ]] --

local PriorityModule = {}

-- Folder References
PriorityModule.MOB_FOLDERS = {
    workspace:WaitForChild("CurrentEnemies", 5),
    workspace:WaitForChild("CurrentBosses", 5),
    workspace:WaitForChild("CurrentMegaBosses", 5),
}

-- ============================================================================
-- EASY CONFIG: MAP TARGET PATHS
-- Simply paste full workspace paths here as standard strings!
-- ============================================================================
PriorityModule.MAP_TARGETS = {
    "workspace.Map.SpringWrathCastle.HealthDoor",
    "workspace.Map.SpringWrathCastle.HealthDoor2",
    "workspace.Map.SpringWrathCastle.HealthDoor3",
}
-- ============================================================================

-- Active Toggle State for Map Targets
PriorityModule.ActiveMapTargets = {}

-- Internal Name Priorities
PriorityModule.INTERNAL_PRIORITIES = {
    CurrentMegaBosses = {},
    CurrentBosses = {
        "Dezadon", -- Rank 1
        "Arcane",  -- Rank 2
    },
    CurrentEnemies = {}
}

local LockedTarget = nil

-- Path Resolver (Parses path strings like "workspace.Map.SpringWrathCastle.HealthDoor")
local function resolvePath(pathStr)
    if not pathStr or pathStr == "" then return nil end
    local cleanPath = pathStr:gsub("^workspace%.", ""):gsub("^game%.Workspace%.", "")
    local current = workspace
    for part in cleanPath:gmatch("[^%.]+") do
        if not current then return nil end
        current = current:FindFirstChild(part)
    end
    return current
end

local function isTargetAlive(model)
    if not model or not model.Parent or not model:IsDescendantOf(workspace) then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getAllMobs()
    local mobs = {}
    -- Standard Mobs
    for _, folder in ipairs(PriorityModule.MOB_FOLDERS) do
        if folder and folder:IsA("Instance") then
            for _, d in ipairs(folder:GetDescendants()) do
                if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") then 
                    table.insert(mobs, d) 
                end
            end
        end
    end
    -- Active Map Targets
    for pathStr, enabled in pairs(PriorityModule.ActiveMapTargets) do
        if enabled then
            local model = resolvePath(pathStr)
            if model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
                table.insert(mobs, model)
            end
        end
    end
    return mobs
end

local function getMobsFromFolder(folderName)
    local found = {}
    for _, folder in ipairs(PriorityModule.MOB_FOLDERS) do
        if folder and folder.Name == folderName then
            for _, d in ipairs(folder:GetDescendants()) do
                if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") then 
                    table.insert(found, d) 
                end
            end
        end
    end
    return found
end

local function getInternalRank(folderName, mobName)
    local priorityList = PriorityModule.INTERNAL_PRIORITIES[folderName]
    if not priorityList then return math.huge end
    
    for rank, name in ipairs(priorityList) do
        if mobName == name then return rank end
    end
    return math.huge
end

local function getBestTargetFromList(mobList, folderName, getRootFunc)
    local myRoot = getRootFunc and getRootFunc()
    if not myRoot or #mobList == 0 then return nil end
    
    local candidates = {}
    for _, mob in ipairs(mobList) do
        local hum, root = mob:FindFirstChildOfClass("Humanoid"), mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
        if hum and hum.Health > 0 and root then
            table.insert(candidates, {
                model = mob,
                hum = hum,
                rank = getInternalRank(folderName, mob.Name),
                dist = (myRoot.Position - root.Position).Magnitude,
                id = mob:GetDebugId()
            })
        end
    end

    if #candidates == 0 then return nil end

    table.sort(candidates, function(a, b)
        if a.rank ~= b.rank then
            return a.rank < b.rank
        elseif math.abs(a.dist - b.dist) > 0.1 then
            return a.dist < b.dist
        elseif a.hum.Health ~= b.hum.Health then
            return a.hum.Health < b.hum.Health
        else
            return a.id < b.id
        end
    end)

    return candidates[1].model
end

local function getMobCategory(mob)
    if not mob or not mob.Parent then return nil end
    for _, folder in ipairs(PriorityModule.MOB_FOLDERS) do
        if folder and mob:IsDescendantOf(folder) then
            return folder.Name
        end
    end
    return nil
end

-- Public API
function PriorityModule.ResetLock()
    LockedTarget = nil
end

function PriorityModule.GetAllMobs()
    return getAllMobs()
end

function PriorityModule.ToggleMapTarget(pathStr)
    PriorityModule.ActiveMapTargets[pathStr] = not PriorityModule.ActiveMapTargets[pathStr]
    LockedTarget = nil
    return PriorityModule.ActiveMapTargets[pathStr]
end

function PriorityModule.GetPrimaryTarget(targetPriorityMode, getRootFunc)
    -- 1. Check for Active Map Target Overrides First
    for pathStr, enabled in pairs(PriorityModule.ActiveMapTargets) do
        if enabled then
            local mapModel = resolvePath(pathStr)
            if isTargetAlive(mapModel) then
                LockedTarget = mapModel
                return LockedTarget
            end
        end
    end

    -- 2. Fall back to standard folder priorities
    local tiers = {}
    if targetPriorityMode == "Mega Bosses" then
        tiers = {"CurrentMegaBosses", "CurrentBosses", "CurrentEnemies"}
    elseif targetPriorityMode == "Bosses" then
        tiers = {"CurrentBosses", "CurrentEnemies", "CurrentMegaBosses"}
    elseif targetPriorityMode == "Enemies" then
        tiers = {"CurrentEnemies", "CurrentMegaBosses", "CurrentBosses"}
    else
        tiers = {"ALL"}
    end

    local currentLockValid = isTargetAlive(LockedTarget)
    local currentCategory = currentLockValid and getMobCategory(LockedTarget) or nil

    if tiers[1] == "ALL" then
        if currentLockValid then return LockedTarget end
        LockedTarget = getBestTargetFromList(getAllMobs(), "ALL", getRootFunc)
        return LockedTarget
    end

    for _, folderName in ipairs(tiers) do
        local mobsInFolder = getMobsFromFolder(folderName)
        if #mobsInFolder > 0 then
            local bestInFolder = getBestTargetFromList(mobsInFolder, folderName, getRootFunc)
            
            if currentLockValid and currentCategory == folderName then
                local currentRank = getInternalRank(folderName, LockedTarget.Name)
                local bestRank = getInternalRank(folderName, bestInFolder.Name)
                
                if bestRank < currentRank then
                    LockedTarget = bestInFolder
                    return LockedTarget
                end
                
                return LockedTarget
            end
            
            LockedTarget = bestInFolder
            return LockedTarget
        end
    end

    if currentLockValid then return LockedTarget end
    LockedTarget = getBestTargetFromList(getAllMobs(), "ALL", getRootFunc)
    return LockedTarget
end

return PriorityModule
