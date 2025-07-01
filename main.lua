local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local workspace = workspace

local flying = false
local direction = Vector3.new(0,0,0)
local speed = 100
local bv

-- Set WalkSpeed
local function setWalkSpeed(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.WalkSpeed = 100
end

-- ESP Highlights
local function addHighlightToPlayer(player)
    if not player.Character then return end
    local char = player.Character
    if char:FindFirstChild("Highlight") then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = char
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = char
end

local function setupESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                addHighlightToPlayer(player)
            end)
            if player.Character then
                addHighlightToPlayer(player)
            end
        end
    end

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            addHighlightToPlayer(player)
        end)
    end)
end

-- Update flying direction
local function updateDirection()
    direction = Vector3.new(0,0,0)
    if UIS:IsKeyDown(Enum.KeyCode.W) then direction = direction + Vector3.new(0,0,-1) end
    if UIS:IsKeyDown(Enum.KeyCode.S) then direction = direction + Vector3.new(0,0,1) end
    if UIS:IsKeyDown(Enum.KeyCode.A) then direction = direction + Vector3.new(-1,0,0) end
    if UIS:IsKeyDown(Enum.KeyCode.D) then direction = direction + Vector3.new(1,0,0) end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction + Vector3.new(0,-1,0) end
end

local function toggleFly(hrp)
    if flying then
        flying = false
        if bv then bv:Destroy() end
        bv = nil
    else
        flying = true
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e9,1e9,1e9)
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = hrp
    end
end

local function startFlying(hrp)
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F then
            toggleFly(hrp)
        end
    end)

    RunService.RenderStepped:Connect(function()
        if flying and bv and hrp then
            updateDirection()
            local cam = workspace.CurrentCamera
            if direction.Magnitude > 0 then
                local move = cam.CFrame:VectorToWorldSpace(direction).Unit
                bv.Velocity = move * speed
            else
                bv.Velocity = Vector3.new(0,0,0)
            end
        end
    end)
end

-- Aimbot camera lock with distance and visibility check
RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    local origin = cam.CFrame.Position
    local maxDistance = 100
    local closestDist = math.huge
    local targetHead = nil

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local dist = (head.Position - origin).Magnitude
            if dist < maxDistance and dist < closestDist then
                -- Raycast to check visibility
                local directionRay = (head.Position - origin)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

                local raycastResult = workspace:Raycast(origin, directionRay, raycastParams)
                if raycastResult and raycastResult.Instance and raycastResult.Instance:IsDescendantOf(player.Character) then
                    closestDist = dist
                    targetHead = head
                end
            end
        end
    end

    if targetHead then
        cam.CFrame = CFrame.new(cam.CFrame.Position, targetHead.Position)
    end
end)

-- On character spawn
local function onCharacterAdded(char)
    local hrp = char:WaitForChild("HumanoidRootPart")
    setWalkSpeed(char)
    startFlying(hrp)
end

-- Init
setupESP()

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
