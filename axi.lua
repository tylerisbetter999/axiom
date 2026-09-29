-- Single-file feature framework
-- Lifecycle: Register -> Initialize -> Enable -> Disable -> Destroy

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

----------------------------------------------------------------
-- FeatureRegistry
----------------------------------------------------------------
local FeatureRegistry = {
    Features = {}
}

function FeatureRegistry:Register(feature)
    for _, existing in ipairs(self.Features) do
        if existing == feature or existing.Name == feature.Name then
            warn("Feature already registered: " .. tostring(feature.Name))
            return false
        end
    end
    table.insert(self.Features, feature)
    return true
end

----------------------------------------------------------------
-- FeatureManager
----------------------------------------------------------------
local FeatureManager = {
    Features = {}
}

function FeatureManager:Initialize()
    self.Features = FeatureRegistry.Features

    for _, feature in ipairs(self.Features) do
        if not feature.Initialized then
            feature:Initialize()
        end
    end
end

function FeatureManager:GetFeature(name)
    for _, feature in ipairs(self.Features) do
        if feature.Name == name then
            return feature
        end
    end
    return nil
end

function FeatureManager:EnableFeature(name)
    local feature = self:GetFeature(name)
    if feature then
        feature:Enable()
    else
        warn("Feature not found: " .. name)
    end
end

function FeatureManager:DisableFeature(name)
    local feature = self:GetFeature(name)
    if feature then
        feature:Disable()
    else
        warn("Feature not found: " .. name)
    end
end

function FeatureManager:DestroyAll()
    for _, feature in ipairs(self.Features) do
        feature:Destroy()
    end
end

----------------------------------------------------------------
-- Features
----------------------------------------------------------------

-- ESP -----------------------------------------------------------
local ESP = {
    Name = "ESP",
    Enabled = false,
    Initialized = false,
    Highlights = {},
    Connections = {},        -- global connections
    PlayerConnections = {}   -- per-player connections
}

function ESP:Initialize()
    if self.Initialized then return end
    self.Initialized = true
    print(self.Name, "initialized")
end

function ESP:Enable()
    if not self.Initialized then
        self:Initialize()
    end
    if self.Enabled then
        return
    end
    self.Enabled = true

    for _, player in ipairs(Players:GetPlayers()) do
        self:TrackPlayer(player)
    end

    table.insert(self.Connections, Players.PlayerAdded:Connect(function(player)
        self:TrackPlayer(player)
    end))
    table.insert(self.Connections, Players.PlayerRemoving:Connect(function(player)
        self:UntrackPlayer(player)
    end))

    print(self.Name, "enabled")
end

function ESP:TrackPlayer(player)
    if player == Players.LocalPlayer then
        return
    end
    if self.PlayerConnections[player] then
        return
    end

    self:HighlightCharacter(player, player.Character)

    self.PlayerConnections[player] = player.CharacterAdded:Connect(function(character)
        self:HighlightCharacter(player, character)
    end)
end

function ESP:HighlightCharacter(player, character)
    local old = self.Highlights[player]
    if old then
        old:Destroy()
        self.Highlights[player] = nil
    end
    if not character then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)
    highlight.Parent = character
    self.Highlights[player] = highlight
end

function ESP:UntrackPlayer(player)
    local conn = self.PlayerConnections[player]
    if conn then
        conn:Disconnect()
        self.PlayerConnections[player] = nil
    end
    local highlight = self.Highlights[player]
    if highlight then
        highlight:Destroy()
        self.Highlights[player] = nil
    end
end

function ESP:Disable()
    if not self.Enabled then
        return
    end
    self.Enabled = false

    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    self.Connections = {}

    for player in pairs(self.PlayerConnections) do
        self:UntrackPlayer(player)
    end
    for player, highlight in pairs(self.Highlights) do
        highlight:Destroy()
        self.Highlights[player] = nil
    end

    print(self.Name, "disabled")
end

function ESP:Destroy()
    self:Disable()
    self.Initialized = false
    print(self.Name, "destroyed")
end

-- Speed ---------------------------------------------------------
local TARGET_SPEED = 50

local Speed = {
    Name = "Speed",
    Enabled = false,
    Initialized = false,
    SteppedConnection = nil,
    CharacterConnection = nil,
    Humanoid = nil,
    OriginalWalkSpeed = nil
}

function Speed:Initialize()
    if self.Initialized then return end
    self.Initialized = true
    print(self.Name, "initialized")
end

function Speed:BindHumanoid(character)
    self:RestoreSpeed()
    self.Humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if self.Humanoid then
        self.OriginalWalkSpeed = self.Humanoid.WalkSpeed
        self.Humanoid.WalkSpeed = TARGET_SPEED
    end
end

function Speed:RestoreSpeed()
    if self.Humanoid and self.OriginalWalkSpeed then
        self.Humanoid.WalkSpeed = self.OriginalWalkSpeed
    end
    self.Humanoid = nil
    self.OriginalWalkSpeed = nil
end

function Speed:Enable()
    if not self.Initialized then
        self:Initialize()
    end
    if self.Enabled then
        return
    end
    self.Enabled = true

    local localPlayer = Players.LocalPlayer
    self:BindHumanoid(localPlayer.Character)

    self.CharacterConnection = localPlayer.CharacterAdded:Connect(function(character)
        self:BindHumanoid(character)
    end)

    self.SteppedConnection = RunService.Stepped:Connect(function()
        if self.Humanoid and self.Humanoid.WalkSpeed ~= TARGET_SPEED then
            self.Humanoid.WalkSpeed = TARGET_SPEED
        end
    end)

    print(self.Name, "enabled")
end

function Speed:Disable()
    if not self.Enabled then
        return
    end
    self.Enabled = false

    if self.SteppedConnection then
        self.SteppedConnection:Disconnect()
        self.SteppedConnection = nil
    end
    if self.CharacterConnection then
        self.CharacterConnection:Disconnect()
        self.CharacterConnection = nil
    end
    self:RestoreSpeed()

    print(self.Name, "disabled")
end

function Speed:Destroy()
    self:Disable()
    self.Initialized = false
    print(self.Name, "destroyed")
end

-- Aimbot (lifecycle stub only, no targeting logic) ---------------
local Aimbot = {
    Name = "Aimbot",
    Enabled = false,
    Initialized = false
}

function Aimbot:Initialize()
    if self.Initialized then return end
    self.Initialized = true
    print(self.Name, "initialized")
end

function Aimbot:Enable()
    if not self.Initialized then
        self:Initialize()
    end
    if self.Enabled then return end
    self.Enabled = true
    print(self.Name, "enabled")
end

function Aimbot:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    print(self.Name, "disabled")
end

function Aimbot:Destroy()
    self:Disable()
    self.Initialized = false
    print(self.Name, "destroyed")
end

-- TestFeature2 --------------------------------------------------
local TestFeature2 = {
    Name = "TestFeature2",
    Enabled = false,
    Initialized = false
}

function TestFeature2:Initialize()
    if self.Initialized then return end
    self.Initialized = true
    print(self.Name, "initialized")
end

function TestFeature2:Enable()
    if not self.Initialized then
        self:Initialize()
    end
    if self.Enabled then
        return
    end

    self.Enabled = true
    Players.LocalPlayer:SetAttribute("CustomName", "Cheater")
    print(self.Name, "enabled")
end

function TestFeature2:Disable()
    if not self.Enabled then
        return
    end

    self.Enabled = false
    Players.LocalPlayer:SetAttribute("CustomName", nil)
    print(self.Name, "disabled")
end

function TestFeature2:Destroy()
    self:Disable()
    self.Initialized = false
    print(self.Name, "destroyed")
end

----------------------------------------------------------------
-- Loader
----------------------------------------------------------------
local Loader = {}

function Loader:loadFeatureModules()
    local features = { ESP, Speed, Aimbot, TestFeature2 }
    for _, feature in ipairs(features) do
        FeatureRegistry:Register(feature)  -- Register
    end
end

function Loader:init()
    self:loadFeatureModules()
    FeatureManager:Initialize()            -- Initialize
    return true
end

----------------------------------------------------------------
-- Start
----------------------------------------------------------------
Loader:init()

-- Usage examples:
-- FeatureManager:EnableFeature("ESP")
-- FeatureManager:DisableFeature("ESP")
-- FeatureManager:DestroyAll()

return FeatureManager
