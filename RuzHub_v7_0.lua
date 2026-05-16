-- ================================================================
--  RuzHub Mmv And Mm2  v7.0
--  Changes from v6.1:
--    * Only 2 tabs: Main + ESP
--    * Skybox, Crosshair, Graphics, Extra all merged into Main tab
--    * Custom Skybox ID input + presets inside Main
--    * Graphics: Low (plastic/no texture) + High (enhanced lighting) toggles
--    * Custom Crosshair ID input + preset picker inside Main
--    * Extra scripts (Emotes, Infinite Yield) inside Main
--    * Crosshair ShiftLock notification
-- ================================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- GLOBALS
-- ==========================================
local goldCD       = false
local normalCD     = false
local BULLET_SPEED = 250
local KNIFE_SPEED  = 65
local MAX_VELOCITY = 200
local BASE_GLITCH  = 200
local autoPingPred = false
local fovValue     = 70
local lowGraphics  = false
local highGraphics = false
local droppedGunEspEnabled = true

local CURSOR_TEXTURE = "rbxassetid://5159914132"
local KNIFE_TEXTURE  = "rbxassetid://9695655416"

-- ==========================================
-- WINDUI
-- ==========================================
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"
))()
WindUI:SetTheme("Crimson")

local function Notify(content)
    WindUI:Notify({
        Title    = "RuzHub",
        Content  = tostring(content),
        Duration = 3,
        Icon     = "bell",
    })
end

-- ==========================================
-- MOBILE SLIDER POPUP
-- ==========================================
local function OpenSliderPopup(title, minVal, maxVal, defaultVal, step, onApply, onReset)
    local uid      = "RuzSlider_" .. title:gsub("%s+", "_")
    local existing = game.CoreGui:FindFirstChild(uid)
    if existing then existing:Destroy(); return end

    local sg              = Instance.new("ScreenGui", game.CoreGui)
    sg.Name               = uid
    sg.ResetOnSpawn       = false
    sg.DisplayOrder       = 55
    sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling

    local frame                  = Instance.new("Frame", sg)
    frame.Size                   = UDim2.new(0, 300, 0, 175)
    frame.Position               = UDim2.new(0.5, -150, 0.35, 0)
    frame.BackgroundColor3       = Color3.fromRGB(10, 10, 10)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel        = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local fs      = Instance.new("UIStroke", frame)
    fs.Color      = Color3.fromRGB(220, 38, 38)
    fs.Thickness  = 1.5
    fs.Transparency = 0.15

    local hdr                  = Instance.new("TextLabel", frame)
    hdr.Size                   = UDim2.new(1, -44, 0, 36)
    hdr.Position               = UDim2.new(0, 12, 0, 0)
    hdr.BackgroundTransparency = 1
    hdr.Text                   = "RuzHub  -  " .. title
    hdr.TextColor3             = Color3.fromRGB(255, 255, 255)
    hdr.Font                   = Enum.Font.GothamBold
    hdr.TextSize               = 14
    hdr.TextXAlignment         = Enum.TextXAlignment.Left

    local xBtn                 = Instance.new("TextButton", frame)
    xBtn.Size                  = UDim2.new(0, 28, 0, 28)
    xBtn.Position              = UDim2.new(1, -34, 0, 4)
    xBtn.BackgroundColor3      = Color3.fromRGB(180, 30, 30)
    xBtn.Text                  = "X"
    xBtn.TextColor3            = Color3.new(1, 1, 1)
    xBtn.Font                  = Enum.Font.GothamBold
    xBtn.TextSize              = 13
    Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0, 6)
    xBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local currentVal = defaultVal

    local valLbl                  = Instance.new("TextLabel", frame)
    valLbl.Size                   = UDim2.new(1, 0, 0, 22)
    valLbl.Position               = UDim2.new(0, 0, 0, 38)
    valLbl.BackgroundTransparency = 1
    valLbl.Text                   = title .. ":  " .. tostring(currentVal)
    valLbl.TextColor3             = Color3.fromRGB(210, 210, 210)
    valLbl.Font                   = Enum.Font.Gotham
    valLbl.TextSize               = 13

    local track                  = Instance.new("Frame", frame)
    track.Size                   = UDim2.new(1, -30, 0, 10)
    track.Position               = UDim2.new(0, 15, 0, 72)
    track.BackgroundColor3       = Color3.fromRGB(45, 45, 45)
    track.BorderSizePixel        = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fillRel0 = (currentVal - minVal) / (maxVal - minVal)
    local fill     = Instance.new("Frame", track)
    fill.Size      = UDim2.new(fillRel0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
    fill.BorderSizePixel  = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local handle                  = Instance.new("TextButton", track)
    handle.Size                   = UDim2.new(0, 26, 0, 26)
    handle.Position               = UDim2.new(fillRel0, -13, 0.5, -13)
    handle.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    handle.Text                   = ""
    handle.AutoButtonColor        = false
    handle.BorderSizePixel        = 0
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

    local function updateFromX(screenX)
        local abs = track.AbsolutePosition.X
        local sz  = track.AbsoluteSize.X
        local rel = math.clamp((screenX - abs) / sz, 0, 1)
        currentVal = math.round(minVal + rel * (maxVal - minVal))
        if step and step > 0 then
            currentVal = math.round(currentVal / step) * step
        end
        local r2 = (currentVal - minVal) / (maxVal - minVal)
        fill.Size       = UDim2.new(r2, 0, 1, 0)
        handle.Position = UDim2.new(r2, -13, 0.5, -13)
        valLbl.Text     = title .. ":  " .. tostring(currentVal)
    end

    local dragging = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; updateFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then updateFromX(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    local btnRow                  = Instance.new("Frame", frame)
    btnRow.Size                   = UDim2.new(1, -20, 0, 36)
    btnRow.Position               = UDim2.new(0, 10, 0, 126)
    btnRow.BackgroundTransparency = 1

    local applyBtn                = Instance.new("TextButton", btnRow)
    applyBtn.Size                 = UDim2.new(0.48, 0, 1, 0)
    applyBtn.BackgroundColor3     = Color3.fromRGB(20, 160, 20)
    applyBtn.Text                 = "Apply"
    applyBtn.TextColor3           = Color3.new(1, 1, 1)
    applyBtn.Font                 = Enum.Font.GothamBold
    applyBtn.TextSize             = 13
    Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 6)
    applyBtn.MouseButton1Click:Connect(function()
        onApply(currentVal)
        Notify(title .. " set to " .. currentVal)
    end)

    local resetBtn                = Instance.new("TextButton", btnRow)
    resetBtn.Size                 = UDim2.new(0.48, 0, 1, 0)
    resetBtn.Position             = UDim2.new(0.52, 0, 0, 0)
    resetBtn.BackgroundColor3     = Color3.fromRGB(160, 20, 20)
    resetBtn.Text                 = "Reset"
    resetBtn.TextColor3           = Color3.new(1, 1, 1)
    resetBtn.Font                 = Enum.Font.GothamBold
    resetBtn.TextSize             = 13
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)
    resetBtn.MouseButton1Click:Connect(function()
        onReset(); sg:Destroy()
    end)

    local pd, ps, pp
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            pd = true; ps = i.Position; pp = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(i)
        if not pd then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - ps
            frame.Position = UDim2.new(pp.X.Scale, pp.X.Offset + d.X,
                                       pp.Y.Scale, pp.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then pd = false end
    end)
end

-- ==========================================
-- LOW GRAPHICS STAR
-- ==========================================
local lgStarGui            = Instance.new("ScreenGui", game.CoreGui)
lgStarGui.Name             = "RuzLGStar"
lgStarGui.ResetOnSpawn     = false
lgStarGui.DisplayOrder     = 40
local lgStarLbl                  = Instance.new("TextLabel", lgStarGui)
lgStarLbl.Size                   = UDim2.new(0, 28, 0, 28)
lgStarLbl.Position               = UDim2.new(1, -34, 0, 4)
lgStarLbl.BackgroundTransparency = 1
lgStarLbl.Text                   = "★"
lgStarLbl.TextColor3             = Color3.fromRGB(255, 215, 0)
lgStarLbl.Font                   = Enum.Font.GothamBold
lgStarLbl.TextSize               = 22
lgStarLbl.Visible                = false

-- ==========================================
-- PREDICTION PART
-- ==========================================
local predPart            = Instance.new("Part")
predPart.Name             = "RuzPredictionPart"
predPart.Size             = Vector3.new(0.5, 0.5, 0.5)
predPart.Anchored         = true
predPart.CanCollide       = false
predPart.Transparency     = 1
predPart.Parent           = Workspace

-- ==========================================
-- GUN MARKER
-- ==========================================
local gunMarker = nil
local function ClearGunMarker()
    if gunMarker then gunMarker:Destroy(); gunMarker = nil end
end
local function PlaceGunMarker(pos)
    ClearGunMarker()
    local p        = Instance.new("Part")
    p.Name         = "RuzGunMarker"
    p.Size         = Vector3.new(1.5, 0.15, 1.5)
    p.Anchored     = true
    p.CanCollide   = false
    p.CastShadow   = false
    p.Material     = Enum.Material.Neon
    p.Color        = Color3.fromRGB(50, 255, 80)
    p.Transparency = 0.25
    p.CFrame       = CFrame.new(pos)
    p.Parent       = Workspace
    task.spawn(function()
        while p and p.Parent do
            for t = 0, 1, 0.05 do
                if not (p and p.Parent) then break end
                p.Transparency = 0.25 + 0.5 * math.sin(t * math.pi)
                task.wait(0.03)
            end
        end
    end)
    gunMarker = p
end

-- ==========================================
-- GUN DROP ESP
-- ==========================================
local activeHL   = nil
local activeBB   = nil
local gunHLColor = Color3.fromRGB(255, 215, 0)

local function ClearGunESP()
    if activeHL then activeHL:Destroy(); activeHL = nil end
    if activeBB then activeBB:Destroy(); activeBB = nil end
end

local function ApplyGunESP(gunDrop)
    if not droppedGunEspEnabled then return end
    ClearGunESP()
    local hl               = Instance.new("Highlight")
    hl.Adornee             = gunDrop
    hl.FillColor           = gunHLColor
    hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency    = 0.35
    hl.OutlineTransparency = 0
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent              = gunDrop
    activeHL               = hl

    local handle = gunDrop:FindFirstChild("Handle")
        or (gunDrop:IsA("Model") and gunDrop.PrimaryPart)
        or gunDrop:FindFirstChildWhichIsA("BasePart")
    if not handle and gunDrop:IsA("BasePart") then handle = gunDrop end

    if handle then
        PlaceGunMarker(handle.Position + Vector3.new(0, 0.1, 0))
        local bb         = Instance.new("BillboardGui")
        bb.Adornee       = handle
        bb.Size          = UDim2.new(0, 130, 0, 36)
        bb.StudsOffset   = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop   = true
        bb.MaxDistance   = 300
        bb.Parent        = handle
        local bg                   = Instance.new("Frame", bb)
        bg.Size                    = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3        = Color3.fromRGB(0, 0, 0)
        bg.BackgroundTransparency  = 0.4
        bg.BorderSizePixel         = 0
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)
        local bgS        = Instance.new("UIStroke", bg)
        bgS.Color        = gunHLColor
        bgS.Thickness    = 1.5
        bgS.Transparency = 0.1
        local lbl                   = Instance.new("TextLabel", bg)
        lbl.Size                    = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency  = 1
        lbl.Text                    = "GUN ON MAP"
        lbl.TextColor3              = gunHLColor
        lbl.Font                    = Enum.Font.GothamBlack
        lbl.TextSize                = 13
        lbl.TextStrokeTransparency  = 0.4
        lbl.TextStrokeColor3        = Color3.fromRGB(0, 0, 0)
        activeBB = bb
    elseif gunDrop:IsA("Model") then
        PlaceGunMarker(gunDrop:GetModelCFrame().Position + Vector3.new(0, 0.1, 0))
    end
end

local function FindGunDrop()
    return Workspace:FindFirstChild("GunDrop", true)
end

local function OnGunFound(gd)
    if droppedGunEspEnabled then ApplyGunESP(gd) end
    Notify("Gun dropped on the map!")
end
local function OnGunRemoved() ClearGunESP(); ClearGunMarker() end

-- ==========================================
-- GUN DROP WATCHER
-- ==========================================
local watchedFolders = {}
local function WatchFolder(folder)
    if watchedFolders[folder] then return end
    watchedFolders[folder] = true
    folder.ChildAdded:Connect(function(obj)
        if obj.Name == "GunDrop" then task.wait(0.1); OnGunFound(obj) end
        if obj:IsA("Model") or obj:IsA("Folder") then WatchFolder(obj) end
    end)
    folder.ChildRemoved:Connect(function(obj)
        if obj.Name == "GunDrop" then OnGunRemoved() end
    end)
    for _, c in ipairs(folder:GetChildren()) do
        if c:IsA("Model") or c:IsA("Folder") then WatchFolder(c) end
    end
end
WatchFolder(Workspace)
Workspace.ChildAdded:Connect(function(obj)
    if obj:IsA("Model") or obj:IsA("Folder") then WatchFolder(obj) end
    if obj.Name == "GunDrop" then task.wait(0.1); OnGunFound(obj) end
end)
task.spawn(function()
    task.wait(1.5)
    local ex = FindGunDrop(); if ex then OnGunFound(ex) end
end)

-- ==========================================
-- SHERIFF WATCHER
-- ==========================================
local function WatchSheriff(p)
    local function hook(char)
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 5); if not hum then return end
        hum.Died:Connect(function()
            if p.Backpack:FindFirstChild("Gun") or char:FindFirstChild("Gun") then
                task.delay(0.8, function()
                    local gd = FindGunDrop(); if gd then OnGunFound(gd) end
                end)
            end
        end)
    end
    if p.Character then hook(p.Character) end
    p.CharacterAdded:Connect(hook)
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= player then task.spawn(WatchSheriff, p) end
end
Players.PlayerAdded:Connect(function(p)
    if p ~= player then WatchSheriff(p) end
end)

-- ==========================================
-- ROLE ESP
-- ==========================================
local espEnabled  = false
local espConn     = nil
local rolesData   = {}
local lastEspTick = 0

local espSettings = {
    Murderer = true, Sheriff = true,
    Hero     = true, Innocent = true, Self = true,
}

local ESP_COLORS = {
    Murderer = Color3.fromRGB(255,  40,  40),
    Sheriff  = Color3.fromRGB( 40, 130, 255),
    Hero     = Color3.fromRGB(255, 215,   0),
    Innocent = Color3.fromRGB(  0, 220,   0),
}

local function GetRole(p)
    local role  = "Innocent"
    local pData = rolesData[p.Name]
    if pData then
        local r = tostring(pData.Role or pData.role or pData.Team or ""):lower()
        if     r:find("murd")                     then role = "Murderer"
        elseif r:find("sheriff") or r:find("gun") then role = "Sheriff"
        elseif r:find("hero")                     then role = "Hero" end
    end
    return role
end

local function ApplyHL(char, color)
    local hl               = char:FindFirstChild("RuzHub_ESP") or Instance.new("Highlight")
    hl.Name                = "RuzHub_ESP"
    hl.Parent              = char
    hl.FillColor           = color
    hl.FillTransparency    = 0.70
    hl.OutlineColor        = Color3.fromRGB(255, 255, 255)
    hl.OutlineTransparency = 0.15
    hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
end

local function RemoveHL(char)
    local hl = char:FindFirstChild("RuzHub_ESP"); if hl then hl:Destroy() end
end

local function ClearAllESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then RemoveHL(p.Character) end
    end
    rolesData = {}; lastEspTick = 0
end

local function StartESP()
    local remote = ReplicatedStorage:FindFirstChild("GetCurrentPlayerData", true)
    if not remote or not remote:IsA("RemoteFunction") then
        Notify("ESP remote not found!"); espEnabled = false; return
    end
    if espConn then espConn:Disconnect(); espConn = nil end
    espConn = RunService.Heartbeat:Connect(function()
        if not espEnabled then return end
        if tick() - lastEspTick > 0.5 then
            local ok, data = pcall(function() return remote:InvokeServer() end)
            if ok and type(data) == "table" then rolesData = data end
            lastEspTick = tick()
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local role = GetRole(p)
                local show = espSettings[role]
                if p == player and not espSettings.Self then show = false end
                if show then ApplyHL(p.Character, ESP_COLORS[role])
                else         RemoveHL(p.Character) end
            end
        end
    end)
end

local function StopESP()
    if espConn then espConn:Disconnect(); espConn = nil end
    task.delay(0.1, ClearAllESP)
end

local function SetESP(on)
    espEnabled = on
    if on then StartESP() else StopESP() end
end

-- ==========================================
-- TARGET FINDER
-- ==========================================
local currentTarget = nil
local function FindBestTarget()
    local myChar = player.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local killerChar, sheriffs = nil, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local c        = p.Character
            local hum      = c:FindFirstChildOfClass("Humanoid")
            local hasKnife = p.Backpack:FindFirstChild("Knife") or c:FindFirstChild("Knife")
            local hasGun   = p.Backpack:FindFirstChild("Gun")   or c:FindFirstChild("Gun")
            if hum and hum.Health > 0 then
                if hasKnife   then killerChar = c
                elseif hasGun then table.insert(sheriffs, c) end
            end
        end
    end
    if killerChar then return killerChar end
    if #sheriffs >= 1 then
        local best, bestD = nil, math.huge
        for _, c in ipairs(sheriffs) do
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestD then bestD = d; best = c end
            end
        end
        return best
    end
    return nil
end

-- ==========================================
-- PREDICTION LOOP
-- ==========================================
RunService.RenderStepped:Connect(function()
    local tgt = FindBestTarget(); currentTarget = tgt
    if not tgt then return end
    local myChar = player.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    local head  = tgt:FindFirstChild("Head")
    local torso = tgt:FindFirstChild("UpperTorso") or tgt:FindFirstChild("HumanoidRootPart")
    local hum   = tgt:FindFirstChildOfClass("Humanoid")
    if not torso then return end
    local base = head and head.Position or (torso.Position + Vector3.new(0, 0.5, 0))
    local dist = (base - myHRP.Position).Magnitude
    local tt   = dist / BULLET_SPEED
    if autoPingPred then
        local ok, ping = pcall(function() return player:GetNetworkPing() end)
        if ok then tt = tt + ping end
    end
    local vel = torso.AssemblyLinearVelocity
    if hum and (hum:GetState() == Enum.HumanoidStateType.Freefall
             or hum:GetState() == Enum.HumanoidStateType.Jumping) then
        vel = Vector3.new(vel.X, 0, vel.Z)
    end
    predPart.CFrame = CFrame.new(base + vel * tt)
end)

-- ==========================================
-- AUTO KILL  (instant)
-- ==========================================
local function AutoKill()
    local char  = player.Character; if not char then return end
    local myHRP = char:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local gun   = player.Backpack:FindFirstChild("Gun") or char:FindFirstChild("Gun")
    if not gun then Notify("No gun in inventory!"); return end
    if not currentTarget then Notify("No target found."); return end
    if gun.Parent ~= char then char.Humanoid:EquipTool(gun); task.wait(0) end
    local tPos = predPart.CFrame.Position
    pcall(function()
        gun:WaitForChild("Shoot"):FireServer(
            CFrame.new(myHRP.Position, tPos), CFrame.new(tPos)
        )
    end)
end

-- ==========================================
-- KNIFE THROW  (instant)
-- ==========================================
local function ThrowKnife()
    local char  = player.Character; if not char then return end
    local myHRP = char:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local knife = player.Backpack:FindFirstChild("Knife") or char:FindFirstChild("Knife")
    if not knife then Notify("No knife in inventory!"); return end
    if knife.Parent ~= char then char.Humanoid:EquipTool(knife); task.wait(0) end
    local nearChar, nearDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < nearDist then nearDist = d; nearChar = p.Character end
            end
        end
    end
    if not nearChar then Notify("No nearby target!"); return end
    local tHRP = nearChar:FindFirstChild("HumanoidRootPart"); if not tHRP then return end
    local vel  = tHRP.AssemblyLinearVelocity
    local dist = (tHRP.Position - myHRP.Position).Magnitude
    local pingExtra = 0
    if autoPingPred then
        local ok, ping = pcall(function() return player:GetNetworkPing() end)
        pingExtra = ok and ping or 0
    end
    local predPos = tHRP.Position + Vector3.new(vel.X, 0, vel.Z) * (dist / KNIFE_SPEED + pingExtra)
    pcall(function()
        knife:WaitForChild("Events"):WaitForChild("KnifeThrown"):FireServer(
            CFrame.new(myHRP.Position, predPos), CFrame.new(predPos)
        )
    end)
end

-- ==========================================
-- SMART FLICK  (180 deg)
-- ==========================================
local flickCD = false
local function DoSmartFlick()
    if flickCD then return end
    local char  = player.Character; if not char then return end
    local myHRP = char:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    flickCD = true
    local isShiftLock = (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
    if not isShiftLock then
        local s = myHRP.CFrame
        local t = s * CFrame.Angles(0, math.pi, 0)
        for i = 1, 4 do myHRP.CFrame = s:Lerp(t, i/4); RunService.RenderStepped:Wait() end
    else
        local camCF   = Camera.CFrame
        local pos     = camCF.Position
        local look    = camCF.LookVector
        local newLook = Vector3.new(-look.X, look.Y, -look.Z)
        local targetCF = CFrame.lookAt(pos, pos + newLook)
        for i = 1, 5 do Camera.CFrame = camCF:Lerp(targetCF, i/5); RunService.RenderStepped:Wait() end
    end
    task.wait(0.15); flickCD = false
end

-- ==========================================
-- WALL HOP  (smooth eased rotation)
-- ==========================================
local wallhopCD = false

local function DoWallHop()
    if wallhopCD then return end
    local char  = player.Character; if not char then return end
    local myHRP = char:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local hum   = char:FindFirstChildOfClass("Humanoid");   if not hum  then return end
    wallhopCD = true

    local isShiftLock = (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
    local _, origYaw, _ = myHRP.CFrame:ToEulerAnglesYXZ()
    local origCamCF     = Camera.CFrame

    local STEPS = 7
    if not isShiftLock then
        local targetYaw = origYaw - math.pi / 2
        for i = 1, STEPS do
            local t     = i / STEPS
            local eased = 1 - (1 - t) ^ 2
            local curY  = origYaw + (targetYaw - origYaw) * eased
            myHRP.CFrame = CFrame.new(myHRP.Position) * CFrame.fromEulerAnglesYXZ(0, curY, 0)
            RunService.RenderStepped:Wait()
        end
    else
        local origLook   = Vector3.new(origCamCF.LookVector.X,  0, origCamCF.LookVector.Z).Unit
        local targetLook = Vector3.new(origCamCF.RightVector.X, 0, origCamCF.RightVector.Z).Unit
        for i = 1, STEPS do
            local t      = i / STEPS
            local eased  = 1 - (1 - t) ^ 2
            local bLook  = origLook:Lerp(targetLook, eased).Unit
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position,
                                          Camera.CFrame.Position + bLook)
            RunService.RenderStepped:Wait()
        end
    end

    local v = myHRP.AssemblyLinearVelocity
    myHRP.AssemblyLinearVelocity = Vector3.new(v.X, 55, v.Z)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    task.wait(0.12)

    local RSTEPS = 5
    if not isShiftLock then
        local _, curY, _ = myHRP.CFrame:ToEulerAnglesYXZ()
        for i = 1, RSTEPS do
            local t     = i / RSTEPS
            local eased = 1 - (1 - t) ^ 2
            local lerpY = curY + (origYaw - curY) * eased
            myHRP.CFrame = CFrame.new(myHRP.Position) * CFrame.fromEulerAnglesYXZ(0, lerpY, 0)
            RunService.RenderStepped:Wait()
        end
    else
        local origLook = Vector3.new(origCamCF.LookVector.X, 0, origCamCF.LookVector.Z).Unit
        local curLook  = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z).Unit
        for i = 1, RSTEPS do
            local t     = i / RSTEPS
            local eased = 1 - (1 - t) ^ 2
            local bLook = curLook:Lerp(origLook, eased).Unit
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position,
                                          Camera.CFrame.Position + bLook)
            RunService.RenderStepped:Wait()
        end
    end
    task.wait(0.10)
    wallhopCD = false
end

-- ==========================================
-- BOMB RETRIEVER
-- ==========================================
task.spawn(function()
    while true do
        task.wait(2)
        pcall(function()
            ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb")
            ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GoldBomb")
        end)
    end
end)

-- ==========================================
-- JUMP ENGINE
-- ==========================================
local function ExecuteJump(bombName, isGold)
    local char = player.Character; if not char then return end
    local bomb = player.Backpack:FindFirstChild(bombName) or char:FindFirstChild(bombName)
    if not bomb then Notify("No " .. bombName .. " found!"); return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if bomb.Parent ~= char then char.Humanoid:EquipTool(bomb); task.wait() end
    pcall(function()
        bomb.Remote:FireServer(
            CFrame.new(hrp.Position + hrp.CFrame.LookVector * 1.5 + Vector3.new(0,-3,0)), 50
        )
    end)
    char.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    hrp.AssemblyLinearVelocity = Vector3.new(
        hrp.AssemblyLinearVelocity.X, 62, hrp.AssemblyLinearVelocity.Z
    )
    if isGold then
        task.spawn(function() goldCD = true;   task.wait(4);  goldCD   = false end)
    else
        task.spawn(function() normalCD = true; task.wait(21); normalCD = false end)
    end
end

-- ==========================================
-- SPEED GLITCH
-- ==========================================
local speedEnabled = false
local speedConn    = nil
local function SetupSpeedGlitch(char)
    local hum = char:WaitForChild("Humanoid")
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.RenderStepped:Connect(function()
        if not speedEnabled then hum.WalkSpeed = 16; return end
        local state = hum:GetState()
        local inAir = state == Enum.HumanoidStateType.Jumping
                   or state == Enum.HumanoidStateType.Freefall
        hum.WalkSpeed = (inAir and hum.MoveDirection.Magnitude > 0) and BASE_GLITCH or 16
    end)
end
player.CharacterAdded:Connect(SetupSpeedGlitch)
if player.Character then task.spawn(SetupSpeedGlitch, player.Character) end

-- ==========================================
-- STRETCH RESOLUTION
-- ==========================================
local stretchEnabled = false
local stretchConn    = nil
local stretchValue   = 0.50
local function SetStretch(on)
    stretchEnabled = on
    if on then
        if stretchConn then stretchConn:Disconnect() end
        stretchConn = RunService.RenderStepped:Connect(function()
            Camera.CFrame = Camera.CFrame * CFrame.new(0,0,0,1,0,0,0,stretchValue,0,0,0,1)
        end)
    else
        if stretchConn then stretchConn:Disconnect(); stretchConn = nil end
    end
end

-- ==========================================
-- GRAB GUN
-- ==========================================
local function DoGrabGun()
    local gd = Workspace:FindFirstChild("GunDrop", true)
    if not gd then Notify("No gun on map!"); return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local targetPos
    if gd:IsA("BasePart") then
        targetPos = gd.Position
    else
        local part = gd:FindFirstChild("Handle")
            or gd:FindFirstChildWhichIsA("BasePart")
            or gd.PrimaryPart
        if part then
            targetPos = part.Position
        else
            targetPos = gd:GetModelCFrame().Position
        end
    end

    if not targetPos then Notify("Gun position not found!"); return end
    local oldCF = hrp.CFrame
    hrp.CFrame  = CFrame.new(targetPos + Vector3.new(0, 2, 0))
    task.wait(0.2)
    hrp.CFrame  = oldCF
    Notify("Teleported to gun!")
end

-- ==========================================
-- SKYBOX
-- ==========================================
local SKYBOX_OPTIONS = { "Red", "Pink", "Pink 2", "Green", "Black", "Cosmic", "Yellow" }
local SKYBOX_IDS = {
    Red     = "98490421374360",
    Pink    = "95000769820905",
    ["Pink 2"] = "82988835868087",
    Green   = "5036205687",
    Black   = "80807192441609",
    Cosmic  = "77816282467771",
    Yellow  = "2669948520",
}
local defaultSkyData = nil
local skyboxActive   = false
local selectedSky    = "Red"

local function SaveDefaultSky()
    local s = Lighting:FindFirstChildOfClass("Sky")
    if s then
        defaultSkyData = {
            SkyboxBk=s.SkyboxBk, SkyboxDn=s.SkyboxDn, SkyboxFt=s.SkyboxFt,
            SkyboxLf=s.SkyboxLf, SkyboxRt=s.SkyboxRt, SkyboxUp=s.SkyboxUp,
        }
    end
end
SaveDefaultSky()

local function RestoreDefaultSky()
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") then obj:Destroy() end
    end
    if defaultSkyData then
        local s = Instance.new("Sky", Lighting)
        for k, v in pairs(defaultSkyData) do s[k] = v end
    end
    Notify("RuzHub: Skybox restored to default.")
end

local function ApplySkyboxById(id)
    -- Temizle
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then obj:Destroy() end
    end
    local sky = Instance.new("Sky", Lighting)
    sky.Name  = "RuzHub_CustomSky"
    local u   = "rbxassetid://" .. tostring(id)
    sky.SkyboxBk=u; sky.SkyboxDn=u; sky.SkyboxFt=u
    sky.SkyboxLf=u; sky.SkyboxRt=u; sky.SkyboxUp=u
    sky.SunTextureId  = ""
    sky.MoonTextureId = ""
    sky.SunAngularSize = 0
    sky.StarCount      = 0
    Lighting.ClockTime    = 14
    Lighting.Brightness   = 2
    Lighting.GlobalShadows = false
    Lighting.FogEnd       = 999999
end

local function ApplySkybox(name)
    local id = SKYBOX_IDS[name]; if not id then return end
    ApplySkyboxById(id)
    Notify("RuzHub: Skybox → " .. name)
end

-- ==========================================
-- ANTI-FLING
-- ==========================================
local antiFling     = false
local antiFlingConn = nil
local function SetAntiFling(on)
    antiFling = on
    if on then
        if antiFlingConn then antiFlingConn:Disconnect() end
        antiFlingConn = RunService.Heartbeat:Connect(function()
            if not antiFling then return end
            local c   = player.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vel = hrp.AssemblyLinearVelocity
                if vel.Magnitude > MAX_VELOCITY then
                    hrp.AssemblyLinearVelocity = vel.Unit * MAX_VELOCITY
                end
            end
        end)
    else
        if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn = nil end
    end
end

-- ================================================================
--  FLING ENGINE
-- ================================================================
getgenv().RuzOldPos = nil
getgenv().RuzFPDH   = Workspace.FallenPartsDestroyHeight
local flingBusy = false

local function SkidFling(targetPlayer)
    if flingBusy then return end
    local char  = player.Character;              if not char  then return end
    local hum   = char:FindFirstChildOfClass("Humanoid"); if not hum  then return end
    local myHRP = hum.RootPart;                  if not myHRP then return end
    local tChar = targetPlayer.Character;        if not tChar then return end
    local tHum  = tChar:FindFirstChildOfClass("Humanoid")
    local tHRP  = tHum and tHum.RootPart
    local tHead = tChar:FindFirstChild("Head")
    local acc   = tChar:FindFirstChildOfClass("Accessory")
    local aHandle = acc and acc:FindFirstChild("Handle")

    if myHRP.Velocity.Magnitude < 50 then getgenv().RuzOldPos = myHRP.CFrame end
    if tHum and tHum.Sit then Notify(targetPlayer.Name .. " is sitting, skipped."); return end

    local camSubj = tHead or aHandle or tHum
    if camSubj then Workspace.CurrentCamera.CameraSubject = camSubj end
    if not tChar:FindFirstChildWhichIsA("BasePart") then return end

    local function FPos(base, offset, ang)
        myHRP.CFrame = CFrame.new(base.Position) * offset * ang
        pcall(function() char:SetPrimaryPartCFrame(CFrame.new(base.Position) * offset * ang) end)
        myHRP.Velocity    = Vector3.new(9e7, 9e7 * 10, 9e7)
        myHRP.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local function RunFling(basePart)
        local deadline = tick() + 2.5
        local angle    = 0
        repeat
            if not (myHRP and tHum) then break end
            local spd = basePart.Velocity.Magnitude
            if spd < 40 then
                angle += 100
                FPos(basePart, CFrame.new(0,  1.5, 0) + tHum.MoveDirection * spd/1.25,
                     CFrame.Angles(math.rad(angle), 0, 0)); task.wait()
                FPos(basePart, CFrame.new(0, -1.5, 0) + tHum.MoveDirection * spd/1.25,
                     CFrame.Angles(math.rad(angle), 0, 0)); task.wait()
                FPos(basePart, CFrame.new(0,  1.5, 0) + tHum.MoveDirection * spd/1.25,
                     CFrame.Angles(math.rad(angle), 0, 0)); task.wait()
                FPos(basePart, CFrame.new(0, -1.5, 0) + tHum.MoveDirection * spd/1.25,
                     CFrame.Angles(math.rad(angle), 0, 0)); task.wait()
                FPos(basePart, CFrame.new(0,  1.5, 0), CFrame.Angles(math.rad(angle), 0, 0)); task.wait()
                FPos(basePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(angle), 0, 0)); task.wait()
            else
                local dir = tHum.MoveDirection
                local ws  = tHum.WalkSpeed
                FPos(basePart, CFrame.new(dir.X*ws*0.12, 3,  dir.Z*ws*0.12),
                     CFrame.Angles(math.rad(90), 0, 0))
                myHRP.Velocity = Vector3.new(9e8, 9e8, 9e8); task.wait()
                FPos(basePart, CFrame.new(-dir.X*ws*0.06, -3, -dir.Z*ws*0.06),
                     CFrame.Angles(0, 0, 0))
                myHRP.Velocity = Vector3.new(9e8, 9e8, 9e8); task.wait()
                FPos(basePart, CFrame.new(dir.X*ws*0.18, 3,  dir.Z*ws*0.18),
                     CFrame.Angles(math.rad(90), 0, 0))
                myHRP.Velocity = Vector3.new(9e8, 9e8, 9e8); task.wait()
                FPos(basePart, CFrame.new(-dir.X*ws*0.06, -3, -dir.Z*ws*0.06),
                     CFrame.Angles(0, 0, 0))
                myHRP.Velocity = Vector3.new(9e8, 9e8, 9e8); task.wait()
            end
        until tick() > deadline
    end

    flingBusy = true
    Workspace.FallenPartsDestroyHeight = 0/0
    local bv       = Instance.new("BodyVelocity")
    bv.Velocity    = Vector3.new(0,0,0)
    bv.MaxForce    = Vector3.new(9e9,9e9,9e9)
    bv.Parent      = myHRP
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local basePart = tHRP or tHead or aHandle
    if basePart then RunFling(basePart)
    else Notify(targetPlayer.Name .. " — no valid fling part.") end

    bv:Destroy()
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    Workspace.CurrentCamera.CameraSubject = hum

    if getgenv().RuzOldPos then
        local attempts = 0
        repeat
            attempts += 1
            myHRP.CFrame = getgenv().RuzOldPos * CFrame.new(0,0.5,0)
            pcall(function() char:SetPrimaryPartCFrame(getgenv().RuzOldPos * CFrame.new(0,0.5,0)) end)
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then
                    p.Velocity = Vector3.new(); p.RotVelocity = Vector3.new()
                end
            end
            task.wait()
        until attempts > 30 or (myHRP.Position - getgenv().RuzOldPos.p).Magnitude < 25
        Workspace.FallenPartsDestroyHeight = getgenv().RuzFPDH
        Notify("Returned to previous position.")
    end
    flingBusy = false
end

local function FlingMurderer()
    if flingBusy then Notify("Fling in progress..."); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hasKnife = p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("Knife")
            if hasKnife then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    Notify("Flinging murderer: " .. p.Name); task.spawn(SkidFling, p); return
                end
            end
        end
    end
    Notify("No knife player found!")
end

local function FlingSheriff()
    if flingBusy then Notify("Fling in progress..."); return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hasGun = p.Backpack:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun")
            if hasGun then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    Notify("Flinging sheriff: " .. p.Name); task.spawn(SkidFling, p); return
                end
            end
        end
    end
    Notify("No gun player found!")
end

-- ==========================================
-- LOW GRAPHICS / HIGH GRAPHICS
-- ==========================================
local origLightData = {
    GlobalShadows = Lighting.GlobalShadows,
    Brightness    = Lighting.Brightness,
    Ambient       = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}
local origPartData = {}
local lgDescConn   = nil

local function ApplyLGToInstance(v)
    if v:IsA("BasePart") then
        if not origPartData[v] then
            origPartData[v] = { Material = v.Material, CastShadow = v.CastShadow }
        end
        v.Material = Enum.Material.SmoothPlastic; v.CastShadow = false
    end
    if v:IsA("Decal") or v:IsA("Texture") then
        if not origPartData[v] then origPartData[v] = { Transparency = v.Transparency } end
        v.Transparency = 1
    end
end

local function EnableLowGraphics()
    -- Önce high graphics kapat
    if highGraphics then
        highGraphics = false
        Lighting.Brightness    = origLightData.Brightness
        Lighting.GlobalShadows = origLightData.GlobalShadows
        Lighting.Ambient       = origLightData.Ambient
        Lighting.OutdoorAmbient = origLightData.OutdoorAmbient
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
                obj:Destroy()
            end
        end
    end
    lowGraphics = true
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function() setfpscap(9999) end)
    Lighting.GlobalShadows = false
    Lighting.Brightness    = 2
    for _, v in ipairs(Workspace:GetDescendants()) do
        pcall(function() ApplyLGToInstance(v) end)
    end
    if lgDescConn then lgDescConn:Disconnect() end
    lgDescConn = Workspace.DescendantAdded:Connect(function(v)
        task.wait(0.1); pcall(function() ApplyLGToInstance(v) end)
    end)
    lgStarLbl.Visible = true
    Notify("RuzHub: Low Graphics ON - FPS Boost active")
end

local function DisableLowGraphics()
    lowGraphics = false
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    Lighting.GlobalShadows  = origLightData.GlobalShadows
    Lighting.Brightness     = origLightData.Brightness
    Lighting.Ambient        = origLightData.Ambient
    Lighting.OutdoorAmbient = origLightData.OutdoorAmbient
    if lgDescConn then lgDescConn:Disconnect(); lgDescConn = nil end
    for obj, data in pairs(origPartData) do
        if obj and obj.Parent then
            pcall(function() for k, v in pairs(data) do obj[k] = v end end)
        end
    end
    origPartData = {}
    lgStarLbl.Visible = false
    Notify("RuzHub: Low Graphics OFF")
end

local function EnableHighGraphics()
    -- Önce low graphics kapat
    if lowGraphics then
        DisableLowGraphics()
    end
    highGraphics = true
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level21 end)
    Lighting.GlobalShadows  = true
    Lighting.Brightness     = 3.5
    Lighting.Ambient        = Color3.fromRGB(80, 80, 100)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 110, 130)

    -- Bloom effect
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
    bloom.Intensity = 0.6
    bloom.Size      = 24
    bloom.Threshold = 0.95

    -- Sun rays
    local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
    rays.Intensity = 0.25
    rays.Spread    = 1

    -- Color correction
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect", Lighting)
    cc.Saturation = 0.2
    cc.Contrast   = 0.1
    cc.Brightness = 0.05

    Notify("RuzHub: High Graphics ON - Beautiful mode active")
end

local function DisableHighGraphics()
    highGraphics = false
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    Lighting.Brightness     = origLightData.Brightness
    Lighting.GlobalShadows  = origLightData.GlobalShadows
    Lighting.Ambient        = origLightData.Ambient
    Lighting.OutdoorAmbient = origLightData.OutdoorAmbient
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then
            obj:Destroy()
        end
    end
    Notify("RuzHub: High Graphics OFF")
end

-- ==========================================
-- CROSSHAIR SYSTEM
-- ==========================================
local CURSORS = {
    { name = "Neon Cyan",       id = "11770890197" },
    { name = "Electric Purple", id = "11770691141" },
    { name = "Precision Dot",   id = "10878218308" },
    { name = "Aim Cross",       id = "10891594349" },
    { name = "Blue Spec",       id = "11720475063" },
    { name = "Circle Dot",      id = "10831379335" },
    { name = "Green Hit",       id = "8375241602"  },
}

local crosshairActive = false
local activeCursorId  = CURSORS[1].id
local crosshairImg    = nil

local function SetupCrosshairDisplay()
    local old = game.CoreGui:FindFirstChild("RuzCrosshairDisplay")
    if old then old:Destroy() end
    local sg              = Instance.new("ScreenGui", game.CoreGui)
    sg.Name               = "RuzCrosshairDisplay"
    sg.ResetOnSpawn       = false
    sg.DisplayOrder       = 25
    sg.IgnoreGuiInset     = true
    crosshairImg          = Instance.new("ImageLabel", sg)
    crosshairImg.AnchorPoint = Vector2.new(0.5, 0.5)
    crosshairImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    crosshairImg.Size     = UDim2.new(0, 42, 0, 42)
    crosshairImg.BackgroundTransparency = 1
    crosshairImg.Image    = "rbxassetid://" .. activeCursorId
    crosshairImg.ZIndex   = 10
    crosshairImg.Visible  = false
    RunService.RenderStepped:Connect(function()
        if not (crosshairImg and crosshairImg.Parent) then return end
        local locked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        -- Beyaz Roblox crosshair'ı gizle
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            local tb = pg:FindFirstChild("GameTopbar")
            if tb and tb:FindFirstChild("Crosshair") then
                tb.Crosshair.Visible = false
            end
        end
        local show   = crosshairActive and locked
        crosshairImg.Visible          = show
        UserInputService.MouseIconEnabled = not show
    end)
end

local function OpenCursorPicker()
    local uid = "RuzCursorPicker"
    local existing = game.CoreGui:FindFirstChild(uid)
    if existing then existing:Destroy(); return end

    local sg              = Instance.new("ScreenGui", game.CoreGui)
    sg.Name               = uid
    sg.ResetOnSpawn       = false
    sg.DisplayOrder       = 60

    local frame                  = Instance.new("Frame", sg)
    frame.Size                   = UDim2.new(0, 290, 0, 370)
    frame.Position               = UDim2.new(0.5, -145, 0.08, 0)
    frame.BackgroundColor3       = Color3.fromRGB(10, 10, 10)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel        = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local fs     = Instance.new("UIStroke", frame)
    fs.Color     = Color3.fromRGB(220, 38, 38)
    fs.Thickness = 1.5

    local hdr                   = Instance.new("TextLabel", frame)
    hdr.Size                    = UDim2.new(1, -44, 0, 36)
    hdr.Position                = UDim2.new(0, 10, 0, 0)
    hdr.BackgroundTransparency  = 1
    hdr.Text                    = "RuzHub  —  Cursor Picker"
    hdr.TextColor3              = Color3.fromRGB(255, 255, 255)
    hdr.Font                    = Enum.Font.GothamBold
    hdr.TextSize                = 14
    hdr.TextXAlignment          = Enum.TextXAlignment.Left

    local xBtn                  = Instance.new("TextButton", frame)
    xBtn.Size                   = UDim2.new(0, 28, 0, 28)
    xBtn.Position               = UDim2.new(1, -34, 0, 4)
    xBtn.BackgroundColor3       = Color3.fromRGB(180, 30, 30)
    xBtn.Text                   = "X"
    xBtn.TextColor3             = Color3.new(1, 1, 1)
    xBtn.Font                   = Enum.Font.GothamBold
    xBtn.TextSize               = 13
    Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0, 6)
    xBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local scroll                   = Instance.new("ScrollingFrame", frame)
    scroll.Size                    = UDim2.new(1, -14, 1, -44)
    scroll.Position                = UDim2.new(0, 7, 0, 40)
    scroll.BackgroundTransparency  = 1
    scroll.BorderSizePixel         = 0
    scroll.ScrollBarThickness      = 4
    scroll.CanvasSize              = UDim2.new(0, 0, 0, math.ceil(#CURSORS / 2) * 118 + 10)

    local grid       = Instance.new("UIGridLayout", scroll)
    grid.CellSize    = UDim2.new(0, 122, 0, 108)
    grid.CellPadding = UDim2.new(0, 8, 0, 8)
    grid.SortOrder   = Enum.SortOrder.LayoutOrder

    for i, cursor in ipairs(CURSORS) do
        local isActive                = (activeCursorId == cursor.id)
        local cell                    = Instance.new("TextButton", scroll)
        cell.Size                     = UDim2.new(0, 122, 0, 108)
        cell.BackgroundColor3         = isActive and Color3.fromRGB(55,15,15) or Color3.fromRGB(22,22,22)
        cell.Text                     = ""
        cell.AutoButtonColor          = false
        cell.LayoutOrder              = i
        Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 8)
        local cs     = Instance.new("UIStroke", cell)
        cs.Color     = isActive and Color3.fromRGB(220,38,38) or Color3.fromRGB(50,50,50)
        cs.Thickness = 1.3

        local img                     = Instance.new("ImageLabel", cell)
        img.Size                      = UDim2.new(0, 54, 0, 54)
        img.AnchorPoint               = Vector2.new(0.5, 0)
        img.Position                  = UDim2.new(0.5, 0, 0, 8)
        img.BackgroundTransparency    = 1
        img.Image                     = "rbxassetid://" .. cursor.id

        local nameLbl                 = Instance.new("TextLabel", cell)
        nameLbl.Size                  = UDim2.new(1, -6, 0, 26)
        nameLbl.Position              = UDim2.new(0, 3, 1, -28)
        nameLbl.BackgroundTransparency= 1
        nameLbl.Text                  = cursor.name
        nameLbl.TextColor3            = Color3.fromRGB(200,200,200)
        nameLbl.Font                  = Enum.Font.Gotham
        nameLbl.TextSize              = 11
        nameLbl.TextWrapped           = true

        cell.MouseButton1Click:Connect(function()
            activeCursorId = cursor.id
            if crosshairActive and crosshairImg then
                crosshairImg.Image = "rbxassetid://" .. cursor.id
            end
            Notify("RuzHub: Cursor: " .. cursor.name .. " | ShiftLock'u aç görmen için.")
            sg:Destroy()
        end)
    end

    local pd, ps, pp
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            pd=true; ps=i.Position; pp=frame.Position
        end
    end)
    frame.InputChanged:Connect(function(i)
        if not pd then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - ps
            frame.Position = UDim2.new(pp.X.Scale, pp.X.Offset+d.X,
                                       pp.Y.Scale, pp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then pd=false end
    end)
end

-- ================================================================
--  FLOATING BUTTON SYSTEM
-- ================================================================
local btnGui = (function()
    local old = game.CoreGui:FindFirstChild("RuzHub_BtnLayer")
    if old then old:Destroy() end
    local sg              = Instance.new("ScreenGui", game.CoreGui)
    sg.Name               = "RuzHub_BtnLayer"
    sg.ResetOnSpawn       = false
    sg.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder       = 10
    return sg
end)()

local btnRefs = {}

local function AddDrag(btn)
    local dragging, dStart, dPos
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging=true; dStart=i.Position; dPos=btn.Position
        end
    end)
    btn.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - dStart
            btn.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X,
                                     dPos.Y.Scale, dPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging=false end
    end)
end

local function NewBtn(key, pos, size, color, label)
    if btnRefs[key] then btnRefs[key].btn:Destroy(); btnRefs[key]=nil end
    local btn                   = Instance.new("TextButton", btnGui)
    btn.Name                    = "RuzBtn_" .. key
    btn.Size                    = size
    btn.Position                = pos
    btn.BackgroundColor3        = Color3.fromRGB(0,0,0)
    btn.BackgroundTransparency  = 0.6
    btn.Text                    = ""
    btn.AutoButtonColor         = false
    btn.BorderSizePixel         = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, size.Y.Offset * 0.20)
    local stroke                = Instance.new("UIStroke", btn)
    stroke.Color                = color
    stroke.Thickness            = 1.3
    stroke.Transparency         = 0.5
    stroke.ApplyStrokeMode      = Enum.ApplyStrokeMode.Border
    local lbl                   = Instance.new("TextLabel", btn)
    lbl.Name                    = "Lbl"
    lbl.Size                    = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency  = 1
    lbl.Text                    = label
    lbl.TextColor3              = color
    lbl.Font                    = Enum.Font.GothamBold
    lbl.TextSize                = math.max(10, size.Y.Offset * 0.14)
    lbl.TextYAlignment          = Enum.TextYAlignment.Center
    lbl.TextXAlignment          = Enum.TextXAlignment.Center
    AddDrag(btn)
    btnRefs[key] = { btn=btn, stroke=stroke, lbl=lbl }
    return btnRefs[key]
end

local function AddSpinImg(ref, texId)
    local bSize = ref.btn.Size.Y.Offset
    local imgSz = math.floor(bSize * 0.55)
    local img   = Instance.new("ImageLabel", ref.btn)
    img.Name    = "SpinImg"
    img.Size    = UDim2.new(0, imgSz, 0, imgSz)
    img.Position = UDim2.new(0.5, -imgSz/2, 0.5, -imgSz/2)
    img.BackgroundTransparency = 1
    img.Image   = "rbxassetid://" .. tostring(texId)
    ref.img     = img
    ref.lbl.Size     = UDim2.new(1,0,0.28,0)
    ref.lbl.Position = UDim2.new(0,0,0.72,0)
    ref.lbl.TextSize = math.max(9, bSize * 0.12)
    task.spawn(function()
        while img and img.Parent do
            img.Rotation += 4; RunService.RenderStepped:Wait()
        end
    end)
    return img
end

-- ================================================================
--  BUTTON SIZES & POSITIONS
-- ================================================================
local BIG   = UDim2.new(0, 88, 0, 88)
local SMALL = UDim2.new(0, 56, 0, 56)

local DEFAULT_POS = {
    GoldBomb      = UDim2.new(0.5, -210, 0.78,  0),
    NormalBomb    = UDim2.new(0.5, -110, 0.78,  0),
    Shoot         = UDim2.new(0.5,  -10, 0.78,  0),
    ESP           = UDim2.new(0.5,   90, 0.78, 16),
    Flick         = UDim2.new(0.5,  154, 0.78, 16),
    Speed         = UDim2.new(0.5, -278, 0.78, 16),
    Stretch       = UDim2.new(0.5, -214, 0.78, 16),
    GrabGun       = UDim2.new(0.5,   90, 0.68, 16),
    WallHop       = UDim2.new(0.5,  154, 0.68, 16),
    FlingMurderer = UDim2.new(0.5, -278, 0.68, 16),
    FlingSheriff  = UDim2.new(0.5, -214, 0.68, 16),
}

-- ================================================================
--  BUTTON LOADERS
-- ================================================================
local function LoadGoldBomb(v)
    if not v then if btnRefs.GoldBomb then btnRefs.GoldBomb.btn:Destroy(); btnRefs.GoldBomb=nil end; return end
    NewBtn("GoldBomb", DEFAULT_POS.GoldBomb, BIG, Color3.fromRGB(255,215,0), "GOLD\nJUMP")
    btnRefs.GoldBomb.btn.MouseButton1Click:Connect(function()
        if goldCD then Notify("Gold Bomb on cooldown.") else ExecuteJump("GoldBomb", true) end
    end)
end

local function LoadNormalBomb(v)
    if not v then if btnRefs.NormalBomb then btnRefs.NormalBomb.btn:Destroy(); btnRefs.NormalBomb=nil end; return end
    NewBtn("NormalBomb", DEFAULT_POS.NormalBomb, BIG, Color3.fromRGB(0,170,255), "NORMAL\nJUMP")
    btnRefs.NormalBomb.btn.MouseButton1Click:Connect(function()
        if normalCD then Notify("Normal Bomb on cooldown.") else ExecuteJump("FakeBomb", false) end
    end)
end

local function LoadShoot(v)
    if not v then if btnRefs.Shoot then btnRefs.Shoot.btn:Destroy(); btnRefs.Shoot=nil end; return end
    local ref = NewBtn("Shoot", DEFAULT_POS.Shoot, BIG, Color3.fromRGB(255,255,255), "SHOOT")
    AddSpinImg(ref, 5159914132)
    ref.btn.MouseButton1Click:Connect(function()
        local c = player.Character
        local hasKnife = c and (player.Backpack:FindFirstChild("Knife") or c:FindFirstChild("Knife"))
        if hasKnife then ThrowKnife() else AutoKill() end
    end)
end

local function LoadESP(v)
    if not v then if btnRefs.ESP then btnRefs.ESP.btn:Destroy(); btnRefs.ESP=nil end; return end
    local c = espEnabled and Color3.fromRGB(50,220,80) or Color3.fromRGB(10,140,30)
    NewBtn("ESP", DEFAULT_POS.ESP, SMALL, c, espEnabled and "ESP\nON" or "ESP\nOFF")
    btnRefs.ESP.btn.MouseButton1Click:Connect(function()
        SetESP(not espEnabled); Notify(espEnabled and "ESP ON" or "ESP OFF")
    end)
end

local function LoadFlick(v)
    if not v then if btnRefs.Flick then btnRefs.Flick.btn:Destroy(); btnRefs.Flick=nil end; return end
    NewBtn("Flick", DEFAULT_POS.Flick, SMALL, Color3.fromRGB(180,50,255), "FLICK")
    btnRefs.Flick.btn.MouseButton1Click:Connect(DoSmartFlick)
end

local function LoadSpeed(v)
    if not v then if btnRefs.Speed then btnRefs.Speed.btn:Destroy(); btnRefs.Speed=nil end; return end
    local c = speedEnabled and Color3.fromRGB(0,220,200) or Color3.fromRGB(0,140,120)
    NewBtn("Speed", DEFAULT_POS.Speed, SMALL, c, speedEnabled and "SPEED\nON" or "SPEED")
    btnRefs.Speed.btn.MouseButton1Click:Connect(function()
        speedEnabled = not speedEnabled
        Notify(speedEnabled and "Speed Glitch ON" or "Speed Glitch OFF")
    end)
end

local function LoadStretch(v)
    if not v then if btnRefs.Stretch then btnRefs.Stretch.btn:Destroy(); btnRefs.Stretch=nil end; return end
    local c = stretchEnabled and Color3.fromRGB(255,140,30) or Color3.fromRGB(200,80,0)
    NewBtn("Stretch", DEFAULT_POS.Stretch, SMALL, c, stretchEnabled and "STRETCH\nON" or "STRETCH")
    btnRefs.Stretch.btn.MouseButton1Click:Connect(function()
        stretchEnabled = not stretchEnabled
        SetStretch(stretchEnabled)
        Notify(stretchEnabled and "Stretch ON" or "Stretch OFF")
    end)
end

local function LoadGrabGun(v)
    if not v then if btnRefs.GrabGun then btnRefs.GrabGun.btn:Destroy(); btnRefs.GrabGun=nil end; return end
    local gd = FindGunDrop()
    local c  = gd and Color3.fromRGB(255,215,0) or Color3.fromRGB(200,120,0)
    NewBtn("GrabGun", DEFAULT_POS.GrabGun, SMALL, c, gd and "GRAB\nGUN" or "NO\nGUN")
    btnRefs.GrabGun.btn.MouseButton1Click:Connect(DoGrabGun)
end

local function LoadWallHop(v)
    if not v then if btnRefs.WallHop then btnRefs.WallHop.btn:Destroy(); btnRefs.WallHop=nil end; return end
    NewBtn("WallHop", DEFAULT_POS.WallHop, SMALL, Color3.fromRGB(0,210,210), "WALL\nHOP")
    btnRefs.WallHop.btn.MouseButton1Click:Connect(DoWallHop)
end

local function LoadFlingMurderer(v)
    if not v then if btnRefs.FlingMurderer then btnRefs.FlingMurderer.btn:Destroy(); btnRefs.FlingMurderer=nil end; return end
    NewBtn("FlingMurderer", DEFAULT_POS.FlingMurderer, SMALL, Color3.fromRGB(255,50,50), "FLING\nMURD")
    btnRefs.FlingMurderer.btn.MouseButton1Click:Connect(FlingMurderer)
end

local function LoadFlingSheriff(v)
    if not v then if btnRefs.FlingSheriff then btnRefs.FlingSheriff.btn:Destroy(); btnRefs.FlingSheriff=nil end; return end
    NewBtn("FlingSheriff", DEFAULT_POS.FlingSheriff, SMALL, Color3.fromRGB(40,130,255), "FLING\nSHERIF")
    btnRefs.FlingSheriff.btn.MouseButton1Click:Connect(FlingSheriff)
end

-- ================================================================
--  HEARTBEAT — sync button colors
-- ================================================================
RunService.Heartbeat:Connect(function()
    if btnRefs.GoldBomb   then btnRefs.GoldBomb.lbl.Text   = goldCD   and "WAIT..." or "GOLD\nJUMP"   end
    if btnRefs.NormalBomb then btnRefs.NormalBomb.lbl.Text  = normalCD and "WAIT..." or "NORMAL\nJUMP" end

    if btnRefs.Shoot and btnRefs.Shoot.img then
        local c = player.Character
        local hasKnife = c and (player.Backpack:FindFirstChild("Knife") or c:FindFirstChild("Knife"))
        btnRefs.Shoot.img.Image = hasKnife and KNIFE_TEXTURE or CURSOR_TEXTURE
        btnRefs.Shoot.lbl.Text  = hasKnife and "THROW" or "SHOOT"
    end

    if btnRefs.ESP then
        local c = espEnabled and Color3.fromRGB(50,220,80) or Color3.fromRGB(10,140,30)
        btnRefs.ESP.lbl.Text       = espEnabled and "ESP\nON" or "ESP\nOFF"
        btnRefs.ESP.lbl.TextColor3 = c
        btnRefs.ESP.stroke.Color   = c
    end

    if btnRefs.Flick then
        local locked   = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        local c = flickCD  and Color3.fromRGB(255,120,0)
               or locked   and Color3.fromRGB(120,200,255)
               or               Color3.fromRGB(180,50,255)
        btnRefs.Flick.lbl.Text       = flickCD and "WAIT..." or "FLICK"
        btnRefs.Flick.lbl.TextColor3 = c
        btnRefs.Flick.stroke.Color   = c
    end

    if btnRefs.WallHop then
        local locked   = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        local c = wallhopCD and Color3.fromRGB(255,120,0)
               or locked    and Color3.fromRGB(0,255,220)
               or               Color3.fromRGB(0,210,210)
        btnRefs.WallHop.lbl.Text       = wallhopCD and "WAIT..." or "WALL\nHOP"
        btnRefs.WallHop.lbl.TextColor3 = c
        btnRefs.WallHop.stroke.Color   = c
    end

    if btnRefs.Speed then
        local c = speedEnabled and Color3.fromRGB(0,220,200) or Color3.fromRGB(0,140,120)
        btnRefs.Speed.lbl.Text       = speedEnabled and "SPEED\nON" or "SPEED"
        btnRefs.Speed.lbl.TextColor3 = c
        btnRefs.Speed.stroke.Color   = c
    end

    if btnRefs.Stretch then
        local c = stretchEnabled and Color3.fromRGB(255,140,30) or Color3.fromRGB(200,80,0)
        btnRefs.Stretch.lbl.Text       = stretchEnabled and "STRETCH\nON" or "STRETCH"
        btnRefs.Stretch.lbl.TextColor3 = c
        btnRefs.Stretch.stroke.Color   = c
    end

    if btnRefs.GrabGun then
        local gd = FindGunDrop()
        local c  = gd and Color3.fromRGB(255,215,0) or Color3.fromRGB(200,100,0)
        btnRefs.GrabGun.lbl.Text       = gd and "GRAB\nGUN" or "NO\nGUN"
        btnRefs.GrabGun.lbl.TextColor3 = c
        btnRefs.GrabGun.stroke.Color   = c
    end

    if btnRefs.FlingMurderer then
        local hasMurd = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                if p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("Knife") then
                    hasMurd = true; break
                end
            end
        end
        local c = flingBusy and Color3.fromRGB(255,180,0)
               or hasMurd   and Color3.fromRGB(255,50,50)
               or               Color3.fromRGB(200,20,20)
        btnRefs.FlingMurderer.lbl.Text       = flingBusy and "FLING..." or hasMurd and "FLING\nMURD" or "NO\nMURD"
        btnRefs.FlingMurderer.lbl.TextColor3 = c
        btnRefs.FlingMurderer.stroke.Color   = c
    end

    if btnRefs.FlingSheriff then
        local hasSheriff = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                if p.Backpack:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun") then
                    hasSheriff = true; break
                end
            end
        end
        local c = flingBusy  and Color3.fromRGB(255,180,0)
               or hasSheriff and Color3.fromRGB(40,130,255)
               or               Color3.fromRGB(10,80,200)
        btnRefs.FlingSheriff.lbl.Text       = flingBusy and "FLING..." or hasSheriff and "FLING\nSHERIF" or "NO\nSHERIF"
        btnRefs.FlingSheriff.lbl.TextColor3 = c
        btnRefs.FlingSheriff.stroke.Color   = c
    end
end)

-- ================================================================
--  WINDUI — POPUP + WINDOW
-- ================================================================
WindUI:Popup({
    Title   = "RuzHub Mmv And Mm2",
    Icon    = "sparkles",
    Content = "v7.0 loaded!\nBombs and Shoot auto-loaded.\nOpen the menu to configure everything.",
    Buttons = {{ Title="Start", Icon="arrow-right", Variant="Primary", Callback=function() end }},
})

local Window = WindUI:CreateWindow({
    Title         = "RuzHub",
    Icon          = "sparkles",
    Author        = "Mmv And Mm2",
    Folder        = "RuzHub",
    Size          = UDim2.fromOffset(700, 550),
    Theme         = "Crimson",
    Acrylic       = false,
    HideSearchBar = false,
    OpenButton    = {
        Title           = "RuzHub",
        CornerRadius    = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled         = true,
        OnlyMobile      = false,
        Color           = ColorSequence.new(
            Color3.fromHex("#dc2626"),
            Color3.fromHex("#991b1b")
        ),
    },
})

-- ================================================================
--  2 SEKME: Main + ESP
-- ================================================================
local NavSec = Window:Section({ Title = "RuzHub", Opened = true })

local MainTab = NavSec:Tab({ Title = "Main", Icon = "zap"  })
local EspTab  = NavSec:Tab({ Title = "ESP",  Icon = "eye"  })

-- ================================================================
--  MAIN TAB ─ Buttons
-- ================================================================
MainTab:Paragraph({
    Title   = "Auto-Loaded Buttons",
    Content = "Gold Bomb, Normal Bomb ve Shoot/Throw varsayılan olarak yüklüdür.",
})

MainTab:Toggle({ Title="Show Gold Bomb",    Default=true,  Callback=function(v) LoadGoldBomb(v)   end })
MainTab:Toggle({ Title="Show Normal Bomb",  Default=true,  Callback=function(v) LoadNormalBomb(v) end })
MainTab:Toggle({ Title="Show Shoot/Throw",  Default=true,  Callback=function(v) LoadShoot(v)      end })

MainTab:Divider()

MainTab:Paragraph({
    Title   = "Optional Buttons",
    Content = "Toggle ile ekrana eklenir veya kaldırılır.",
})

MainTab:Toggle({ Title="Load ESP Toggle",    Default=false, Callback=function(v) LoadESP(v)           end })
MainTab:Toggle({ Title="Load Flick",          Default=false, Callback=function(v) LoadFlick(v)         end })
MainTab:Toggle({ Title="Load Grab Gun",       Default=false, Callback=function(v) LoadGrabGun(v)       end })
MainTab:Toggle({ Title="Load Speed Glitch",   Default=false, Callback=function(v) LoadSpeed(v)         end })
MainTab:Toggle({ Title="Load Stretch",        Default=false, Callback=function(v) LoadStretch(v)       end })
MainTab:Toggle({ Title="Load Fling Murderer", Default=false, Callback=function(v) LoadFlingMurderer(v) end })
MainTab:Toggle({ Title="Load Fling Sheriff",  Default=false, Callback=function(v) LoadFlingSheriff(v)  end })
MainTab:Toggle({ Title="Load WallHop",        Default=false, Callback=function(v) LoadWallHop(v)       end })

MainTab:Divider()

MainTab:Toggle({
    Title       = "Anti-Fling",
    Description = "Velocity'yi kısıtla, uçurulma olmasın",
    Default     = false,
    Callback    = function(v) SetAntiFling(v); Notify(v and "Anti-Fling ON" or "Anti-Fling OFF") end,
})

MainTab:Toggle({
    Title       = "Auto Ping Prediction",
    Description = "Ping offsetini shoot/knife tahminine ekle",
    Default     = false,
    Callback    = function(v) autoPingPred=v; Notify(v and "Ping Pred ON" or "Ping Pred OFF") end,
})

MainTab:Divider()

MainTab:Button({
    Title       = "Speed Glitch Slider",
    Description = "Mobil dostu hız değeri seçici",
    Callback    = function()
        OpenSliderPopup("Speed Glitch", 50, 600, BASE_GLITCH, 10,
            function(v) BASE_GLITCH = v end,
            function() BASE_GLITCH=200; Notify("Speed reset to 200") end)
    end,
})

MainTab:Dropdown({
    Title   = "Velocity Cap (Anti-Fling)",
    Options = {"50","100","150","200","300","500"},
    Default = "200",
    Callback= function(v) MAX_VELOCITY = tonumber(v) or 200 end,
})

-- ================================================================
--  MAIN TAB ─ GRAPHICS (Low + High)
-- ================================================================
MainTab:Divider()

MainTab:Paragraph({
    Title   = "Graphics",
    Content = "Low Graphics: Tüm textureler silinir, map plastik görünür. Fps artar.\nHigh Graphics: Bloom, SunRays, güzel lighting aktif olur.",
})

MainTab:Toggle({
    Title    = "Low Graphics (FPS Boost)",
    Default  = false,
    Callback = function(v)
        if v then EnableLowGraphics() else DisableLowGraphics() end
    end,
})

MainTab:Toggle({
    Title    = "High Graphics (Beautiful Mode)",
    Default  = false,
    Callback = function(v)
        if v then EnableHighGraphics() else DisableHighGraphics() end
    end,
})

MainTab:Button({
    Title       = "FOV Slider",
    Description = "Mobil dostu Field of View seçici",
    Callback    = function()
        OpenSliderPopup("Field of View", 30, 120, fovValue, 5,
            function(v) fovValue=v; Camera.FieldOfView=v end,
            function() fovValue=70; Camera.FieldOfView=70; Notify("FOV reset to 70") end)
    end,
})

-- ================================================================
--  MAIN TAB ─ SKYBOX
-- ================================================================
MainTab:Divider()

MainTab:Paragraph({
    Title   = "Skybox",
    Content = "Custom ID gir veya hazır presetlerden seç. Apply Skybox toggle'ı ile aktif et.",
})

MainTab:Input({
    Title       = "Custom Skybox ID",
    Placeholder = "Texture ID gir (örn: 98490421374360)",
    Callback    = function(v)
        if v and v ~= "" then
            skyboxActive = true
            ApplySkyboxById(v)
            Notify("RuzHub: Custom Skybox uygulandı! ID: " .. v)
        end
    end,
})

MainTab:Dropdown({
    Title    = "Skybox Preset",
    Options  = SKYBOX_OPTIONS,
    Default  = "Red",
    Callback = function(v)
        selectedSky = v
        if skyboxActive then ApplySkybox(v) end
    end,
})

MainTab:Toggle({
    Title    = "Apply Skybox",
    Default  = false,
    Callback = function(v)
        skyboxActive = v
        if v then ApplySkybox(selectedSky) else RestoreDefaultSky() end
    end,
})

-- ================================================================
--  MAIN TAB ─ CROSSHAIR
-- ================================================================
MainTab:Divider()

MainTab:Paragraph({
    Title   = "Crosshair",
    Content = "ShiftLock açıkken özel crosshair gösterir. Enable Crosshair toggle'ını aç, sonra ShiftLock'u etkinleştir.",
})

MainTab:Toggle({
    Title       = "Enable Custom Crosshair",
    Description = "Yalnızca ShiftLock açıkken görünür",
    Default     = false,
    Callback    = function(v)
        crosshairActive = v
        if v then
            SetupCrosshairDisplay()
            Notify("RuzHub: Crosshair ON - ShiftLock'u aç görmek için!")
        else
            local old = game.CoreGui:FindFirstChild("RuzCrosshairDisplay")
            if old then old:Destroy(); crosshairImg=nil end
            UserInputService.MouseIconEnabled = true
            Notify("RuzHub: Crosshair OFF")
        end
    end,
})

MainTab:Button({
    Title       = "Open Cursor Picker",
    Description = "Görsel grid — tıkla uygula",
    Callback    = OpenCursorPicker,
})

MainTab:Input({
    Title       = "Custom Cursor ID",
    Placeholder = "Roblox asset ID gir...",
    Callback    = function(v)
        if v and v ~= "" then
            activeCursorId = v
            if crosshairActive and crosshairImg then
                crosshairImg.Image = "rbxassetid://" .. v
            end
            Notify("RuzHub: Custom cursor uygulandı! ShiftLock'u aç kullanmak için.")
        end
    end,
})

-- ================================================================
--  MAIN TAB ─ EXTRA
-- ================================================================
MainTab:Divider()

MainTab:Paragraph({
    Title   = "Extra Scripts",
    Content = "Universal scriptler ve ekstra araçlar.",
})

MainTab:Button({
    Title       = "Load Emotes GUI",
    Description = "7yd7/Hub emote panelini yükle",
    Callback    = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"
            ))()
        end)
        Notify(ok and "RuzHub: Emotes GUI yüklendi!" or "RuzHub: Load failed: " .. tostring(err))
    end,
})

MainTab:Button({
    Title       = "Load Infinite Yield",
    Description = "Infinite Yield universal admin scriptini yükle",
    Callback    = function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(
                "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"
            ))()
        end)
        Notify(ok and "RuzHub: Infinite Yield yüklendi!" or "RuzHub: Load failed: " .. tostring(err))
    end,
})

MainTab:Toggle({
    Title       = "Anti-Fling (mirror)",
    Description = "Yukarıdaki Anti-Fling ile aynı",
    Default     = false,
    Callback    = function(v) SetAntiFling(v); Notify(v and "Anti-Fling ON" or "Anti-Fling OFF") end,
})

MainTab:Toggle({
    Title       = "Ping Prediction (mirror)",
    Description = "Yukarıdaki Ping Pred ile aynı",
    Default     = false,
    Callback    = function(v) autoPingPred=v; Notify(v and "Ping Pred ON" or "Ping Pred OFF") end,
})

-- ================================================================
--  ESP TAB
-- ================================================================
EspTab:Toggle({
    Title    = "Enable ESP",
    Default  = false,
    Callback = function(v) SetESP(v); Notify(v and "ESP ON" or "ESP OFF") end,
})

EspTab:Divider()

EspTab:Toggle({ Title="Show Murderer",  Default=true, Callback=function(v) espSettings.Murderer=v end })
EspTab:Toggle({ Title="Show Sheriff",   Default=true, Callback=function(v) espSettings.Sheriff=v  end })
EspTab:Toggle({ Title="Show Hero",      Default=true, Callback=function(v) espSettings.Hero=v     end })
EspTab:Toggle({ Title="Show Innocents", Default=true, Callback=function(v) espSettings.Innocent=v end })
EspTab:Toggle({ Title="Show Self",      Default=true, Callback=function(v) espSettings.Self=v     end })
EspTab:Toggle({
    Title       = "Dropped Gun ESP",
    Description = "Haritada silah olduğunda highlight + etiket",
    Default     = true,
    Callback    = function(v)
        droppedGunEspEnabled = v
        if not v then ClearGunESP(); ClearGunMarker() end
        Notify(v and "Gun ESP ON" or "Gun ESP OFF")
    end,
})

EspTab:Divider()

EspTab:ColorPicker({ Title="Murderer Color", Default=Color3.fromRGB(255,40,40),
    Callback=function(v) ESP_COLORS.Murderer=v end })
EspTab:ColorPicker({ Title="Sheriff Color",  Default=Color3.fromRGB(40,130,255),
    Callback=function(v) ESP_COLORS.Sheriff=v  end })
EspTab:ColorPicker({ Title="Hero Color",     Default=Color3.fromRGB(255,215,0),
    Callback=function(v) ESP_COLORS.Hero=v     end })
EspTab:ColorPicker({ Title="Innocent Color", Default=Color3.fromRGB(0,220,0),
    Callback=function(v) ESP_COLORS.Innocent=v end })

-- ================================================================
--  AUTO-LOAD
-- ================================================================
task.wait(0.4)
LoadGoldBomb(true)
LoadNormalBomb(true)
LoadShoot(true)

Notify("RuzHub v7.0 ready!")
print("[RuzHub] v7.0 loaded.")
