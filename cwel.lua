print("[HakoUI] v4.0 loading...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local VIM = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local Workspace = workspace

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Unloaded = false

local function ri(c, p, par)
    local o = Instance.new(c)
    if p then for k, v in pairs(p) do pcall(function() o[k] = v end) end end
    if par then pcall(function() o.Parent = par end) end
    return o
end

local function getChar()
    local c = LP.Character
    if c and c.Parent then return c end
end

local function getHum()
    local c = getChar()
    if c then return c:FindFirstChildOfClass("Humanoid") end
end

local function getHRP()
    local c = getChar()
    if c then return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart end
end

local function viewport()
    local v = Camera.ViewportSize
    if v.X < 100 or v.Y < 100 then v = Vector2.new(900, 600) end
    return v
end

local Cfg = {
    Combat = {
        aim = false, aimFov = 140, aimSpeed = 12, aimSmooth = 0.65, aimPart = 1, aimMode = 1,
        aimVisibleOnly = false, aimTeamCheck = true, aimIgnoreDead = true, aimRing = true,
        aimHighlight = true, aimHumanize = false, aimMaxDist = 2000, aimPredict = 0,
        aimSwitch = false, aimSwitchDelay = 250, aimMultiTarget = true,
        aimPriority = 1, aimLockMode = 1, aimShake = 0, aimThrottle = 0,
        aimSticky = false, aimStickyTime = 500,
        silentAim = false, silentMode = 1, silentWallCheck = true,
        shoot = false, shootMethod = 1, shootDelay = 120, shootOnlyTarget = true, shootHold = false,
        shootBurst = 1, shootBurstDelay = 60,
        trigger = false, triggerRange = 30, triggerDelay = 60,
        hitbox = false, hitboxSize = 3,
        autoPlay = false, autoPlayMode = 1, autoPlayDodge = true, autoPlayRange = 60,
        disabler = false,
    },
    Movement = {
        speed = false, speedValue = 34, speedMethod = 1,
        jump = false, jumpPower = 60,
        infJump = false, bhop = false, highJump = false, longJump = false, airStrafe = false,
        fly = false, flyMode = 1, flySpeed = 70, vertSpeed = 70,
        noclip = false, noFall = false, water = false,
        gravity = false, gravityValue = 196,
        antiFling = false,
    },
    Visuals = {
        esp = false, espVisible = false, espBox = true, espNames = true, espDist = false,
        espHealth = false, espTracer = false, espHead = false, chams = false, chamsColor = 1,
        fullbright = false, camFov = false, camFovValue = 90,
        thirdPerson = false, thirdPersonDist = 12,
        fogDist = 500,
        crosshair = false,
    },
    Cosmetics = {
        enabled = false,
        wings = false, wingsMode = 1, wingsColor = 1, wingsSize = 1,
        halo = false, haloMode = 1, haloColor = 1,
        trail = false, trailMode = 1, trailColor = 1,
        aura = false, auraColor = 1, auraDensity = 1,
        footTrail = false, footTrailColor = 1,
        itemSpin = false, itemTrail = false,
        mainColor = 1,
    },
    World = {
        atmosphere = false, atmospherePreset = 1, atmosphereColors = false,
        atmosphereHue = 0, atmosphereSat = 1, atmosphereContrast = 1, atmosphereBright = 1,
        atmosphereAmbient = 1,
        optimizer = false, optimizerFps = 60, optimizerShadows = false, optimizerTextures = false,
        optimizerMeshes = false, optimizerLighting = false, optimizerParticles = false,
    },
    Exploits = {
        forceOp = true, forceOpMode = 1,
        antiKick = false,
    },
    Misc = {
        antiAfk = false, watermark = true,
    },
}

local Theme = {
    bg = Color3.fromRGB(10, 11, 16),
    card = Color3.fromRGB(20, 23, 32),
    card2 = Color3.fromRGB(26, 30, 41),
    stroke = Color3.fromRGB(42, 48, 63),
    text = Color3.fromRGB(240, 242, 250),
    sub = Color3.fromRGB(140, 148, 168),
    accent = Color3.fromRGB(140, 100, 255),
    accent2 = Color3.fromRGB(90, 200, 255),
    accent3 = Color3.fromRGB(255, 100, 200),
    track = Color3.fromRGB(32, 36, 47),
    off = Color3.fromRGB(48, 54, 70),
    white = Color3.fromRGB(255, 255, 255),
    good = Color3.fromRGB(90, 220, 150),
    bad = Color3.fromRGB(240, 90, 110),
    warn = Color3.fromRGB(255, 200, 80),
}

local Colors = {
    {Color3.fromRGB(255, 220, 80), "Gold"},
    {Color3.fromRGB(140, 100, 255), "Purple"},
    {Color3.fromRGB(90, 200, 255), "Cyan"},
    {Color3.fromRGB(255, 100, 200), "Pink"},
    {Color3.fromRGB(90, 220, 150), "Green"},
    {Color3.fromRGB(255, 150, 50), "Orange"},
    {Color3.fromRGB(255, 80, 80), "Red"},
    {Color3.fromRGB(255, 255, 255), "White"},
}

local AtmosPresets = {"Clean", "Cinematic", "Neon", "Noir", "Warm", "Cold", "Custom"}
local FlyModes = {"Velocity", "CFrame", "Noclip", "Glide"}
local WingModes = {"Angel", "Demon", "Butterfly", "Mechanical", "Dragon"}
local AutoModes = {"Shooting", "Bedwars", "Skywars", "CTF", "Duels"}

local currentTarget, lastSwitch, candidateList = nil, 0, {}
local targetHL = nil
local espObjects = {}
local cosObjects = {}
local notifications = {}

local function notify(msg, color)
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if not ok or not cg then return end
    local f = Instance.new("Frame")
    f.Size = UDim2.fromOffset(300, 40)
    f.Position = UDim2.new(1, -320, 0, 20 + #notifications * 48)
    f.BackgroundColor3 = Theme.card
    f.BackgroundTransparency = 0.08
    f.BorderSizePixel = 0
    if not pcall(function() f.Parent = cg end) then f:Destroy(); return end
    ri("UICorner", {CornerRadius = UDim.new(0, 10)}, f)
    ri("UIStroke", {Color = color or Theme.accent, Thickness = 1, Transparency = 0.3}, f)
    local lbl = ri("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = Theme.text, TextXAlignment = Enum.TextXAlignment.Left, Text = msg,
    }, f)
    notifications[#notifications + 1] = f
    task.spawn(function()
        task.wait(3)
        pcall(function()
            Tween:Create(f, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            Tween:Create(lbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        end)
        task.wait(0.35)
        pcall(function() f:Destroy() end)
        for i, n in ipairs(notifications) do if n == f then table.remove(notifications, i); break end end
    end)
end

local function makeParams(ignore)
    local p = RaycastParams.new()
    p.IgnoreWater = true
    local ok = pcall(function() p.FilterType = Enum.RaycastFilterType.Exclude end)
    if not ok then pcall(function() p.FilterType = Enum.RaycastFilterType.Blacklist end) end
    p.FilterDescendantsInstances = ignore
    return p
end

local function isVisibleFrom(pos, targetChar, fromPos)
    local origin = fromPos or Camera.CFrame.Position
    local ignore = {}
    if LP.Character then table.insert(ignore, LP.Character) end
    if targetChar then table.insert(ignore, targetChar) end
    local ok, res = pcall(function() return Workspace:Raycast(origin, pos - origin, makeParams(ignore)) end)
    if not ok then return true end
    return res == nil
end

local function isVisibleMulti(pos, ch)
    if not Cfg.Combat.aimVisibleOnly and not Cfg.Visuals.espVisible then return true end
    local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
    local origin = Camera.CFrame.Position
    if isVisibleFrom(pos, ch, origin) then return true end
    if root then
        for _, off in ipairs({
            Vector3.new(0, 0, 3), Vector3.new(0, 0, -3), Vector3.new(3, 0, 0),
            Vector3.new(-3, 0, 0), Vector3.new(0, 3, 0), Vector3.new(0, -2, 0)
        }) do
            if isVisibleFrom(root.Position + off, ch, origin) then return true end
        end
    end
    return false
end

local function aimParts(ch)
    local out = {}
    if Cfg.Combat.aimPart == 1 then
        local h = ch:FindFirstChild("Head"); if h then out[1] = h end
    elseif Cfg.Combat.aimPart == 2 then
        local t = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("Head")
        if t then out[1] = t end
    else
        for _, p in ipairs(ch:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then out[#out + 1] = p end
        end
    end
    return out
end

local function setTargetHL(ch)
    if not Cfg.Combat.aimHighlight or not ch then
        if targetHL then pcall(function() targetHL:Destroy() end); targetHL = nil end
        return
    end
    if not targetHL then
        local ok, h = pcall(function()
            local x = Instance.new("Highlight")
            x.FillTransparency = 0.5
            x.FillColor = Theme.accent
            x.OutlineColor = Theme.accent2
            x.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            return x
        end)
        if ok then targetHL = h end
    end
    if targetHL and targetHL.Parent ~= ch then pcall(function() targetHL.Parent = ch end) end
end

local function scoreCandidate(part, ch, cx, cy)
    local dist = (part.Position - Camera.CFrame.Position).Magnitude
    if dist > Cfg.Combat.aimMaxDist then return nil end
    local sp, on = Camera:WorldToViewportPoint(part.Position)
    if not on or sp.Z <= 0 then return nil end
    local d = math.sqrt((sp.X - cx) ^ 2 + (sp.Y - cy) ^ 2)
    if d > Cfg.Combat.aimFov then return nil end
    if Cfg.Combat.aimTeamCheck then
        local ok, same = pcall(function()
            return ch and LP.Team and ch.Parent and ch.Parent.Team == LP.Team
        end)
        if ok and same then return nil end
    end
    if not isVisibleMulti(part.Position, ch) then return nil end
    local score = d
    if Cfg.Combat.aimPriority == 2 then score = dist end
    if Cfg.Combat.aimPriority == 3 then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        score = hum and (hum.MaxHealth - hum.Health) * 100 or 0
    end
    if Cfg.Combat.aimMultiTarget and currentTarget and currentTarget.ch == ch then
        score = score * 0.85
    end
    return score, d
end

local function gatherTargets()
    local v = viewport()
    local cx, cy = v.X / 2, v.Y / 2
    candidateList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch = p.Character
            if ch and ch.Parent then
                local hum = ch:FindFirstChildOfClass("Humanoid")
                if hum and (not Cfg.Combat.aimIgnoreDead or hum.Health > 0) then
                    for _, part in ipairs(aimParts(ch)) do
                        if part and part.Parent then
                            local score, d = scoreCandidate(part, ch, cx, cy)
                            if score then
                                candidateList[#candidateList + 1] = {
                                    ch = ch, part = part, score = score, dist = d, player = p, hum = hum
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    table.sort(candidateList, function(a, b) return a.score < b.score end)
end

local function bestCandidate()
    if #candidateList == 0 then return nil end
    local now = os.clock() * 1000
    if Cfg.Combat.aimSwitch and currentTarget and currentTarget.part and currentTarget.part.Parent then
        local still = false
        for _, c in ipairs(candidateList) do
            if c.ch == currentTarget.ch and c.part == currentTarget.part then still = true; break end
        end
        if still then
            if now - lastSwitch >= Cfg.Combat.aimSwitchDelay then
                for _, c in ipairs(candidateList) do
                    if c.ch ~= currentTarget.ch and c.score < currentTarget.score then return c end
                end
            end
            return currentTarget
        end
        if now - lastSwitch < Cfg.Combat.aimSwitchDelay and currentTarget then return currentTarget end
    end
    if Cfg.Combat.aimSticky and currentTarget and currentTarget.part and currentTarget.part.Parent then
        for _, c in ipairs(candidateList) do
            if c.ch == currentTarget.ch then return currentTarget end
        end
    end
    return candidateList[1]
end

local shootBtn, btnPath = nil, nil

local function capturePath(b)
    local names, isCore = {}, false
    local cur = b
    while cur do
        if cur:IsA("PlayerGui") then break end
        if cur:IsA("CoreGui") then isCore = true; break end
        if cur == game then break end
        table.insert(names, 1, cur.Name)
        cur = cur.Parent
    end
    return {names = names, isCore = isCore}
end

local function resolveByPath(path)
    if not path then return nil end
    local root
    if path.isCore then
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok then root = cg end
    else
        root = LP:FindFirstChildOfClass("PlayerGui")
    end
    if not root then return nil end
    local cur = root
    for _, n in ipairs(path.names) do
        if not cur then return nil end
        cur = cur:FindFirstChild(n)
    end
    if cur and cur:IsA("GuiObject") then return cur end
end

local function getShootBtn()
    if shootBtn and shootBtn.Parent then return shootBtn end
    shootBtn = nil
    if btnPath then shootBtn = resolveByPath(btnPath) end
    return shootBtn
end

local function fireSignals(b)
    if not b or not b.Parent then return 0 end
    local fired = 0
    for _, n in ipairs({"MouseButton1Click", "Activated"}) do
        local ev = b[n]
        if ev and type(getconnections) == "function" then
            local ok, conns = pcall(getconnections, ev)
            if ok and conns then
                for _, c in ipairs(conns) do
                    pcall(function()
                        if c.Fire then c:Fire(); fired = fired + 1
                        elseif c.func then c.func(); fired = fired + 1 end
                    end)
                end
            end
        end
    end
    if fired == 0 and type(firesignal) == "function" then
        for _, n in ipairs({"MouseButton1Click", "Activated"}) do
            local ev = b[n]
            if ev and pcall(function() firesignal(ev) end) then fired = fired + 1 end
        end
    end
    return fired
end

local function toolFire()
    local ch = getChar()
    if not ch then return false end
    local tool = ch:FindFirstChildOfClass("Tool")
    if tool then return (pcall(function() tool:Activate() end)) end
    return false
end

local function autoFire()
    -- FIX: tool first (never blocks movement), then button, never raw VIM by default
    if toolFire() then return true end
    local m = Cfg.Combat.shootMethod
    if m == 1 then
        local b = getShootBtn()
        if b and fireSignals(b) > 0 then return true end
    end
    if m == 3 and type(mouse1click) == "function" then
        return pcall(mouse1click)
    end
    return false
end

local function findButtonAtPoint(pos)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then
        local ok, objs = pcall(function() return pg:GetGuiObjectsAtPosition(pos.X, pos.Y) end)
        if ok and objs then
            for _, o in ipairs(objs) do
                local inOurs = false
                pcall(function() inOurs = o:IsDescendantOf(gui) end)
                if not inOurs then
                    local cur = o
                    while cur and cur ~= pg do
                        if cur:IsA("GuiButton") then return cur end
                        cur = cur.Parent
                    end
                end
            end
        end
    end
end

-- ================== COSMETICS (3D wings) ==================
local function clearCosObject(k)
    if cosObjects[k] then
        pcall(function() cosObjects[k]:Destroy() end)
        cosObjects[k] = nil
    end
end

local function clearAllCosmetics()
    for _, o in pairs(cosObjects) do
        if o and o.Parent then pcall(function() o:Destroy() end) end
    end
    cosObjects = {}
end

local function buildWingSide(side, mode, col)
    local ch = getChar()
    local torso = ch and (ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso"))
    if not torso then return end
    local folder = Instance.new("Folder")
    folder.Name = "HakoWing_" .. side
    folder.Parent = ch
    local sgn = side == "L" and -1 or 1

    local segments = {}
    if mode == 1 then
        segments = {{1.4, 2.2, 0.3}, {1.2, 1.6, 0.28}, {1.0, 1.0, 0.25}}
    elseif mode == 2 then
        segments = {{1.6, 2.0, 0.35}, {1.0, 1.4, 0.3}, {0.6, 0.9, 0.25}}
    elseif mode == 3 then
        segments = {{0.9, 1.8, 0.2}, {1.3, 2.4, 0.22}, {0.9, 1.8, 0.2}}
    elseif mode == 4 then
        segments = {{1.2, 2.6, 0.4}, {1.1, 1.8, 0.35}, {0.9, 1.2, 0.3}, {0.7, 0.8, 0.25}}
    else
        segments = {{1.5, 2.4, 0.4}, {1.3, 2.0, 0.35}, {1.0, 1.6, 0.3}, {0.7, 1.2, 0.25}}
    end

    local lastPart = torso
    local lastCF = CFrame.new(sgn * 0.5, 0.5, 0.5) * CFrame.Angles(0, math.rad(sgn * -30), math.rad(sgn * -25))
    for i, seg in ipairs(segments) do
        local w, h, t = seg[1], seg[2], seg[3]
        local part = Instance.new("Part")
        part.Name = "HakoWingSeg" .. i
        part.Size = Vector3.new(w * Cfg.Cosmetics.wingsSize, h * Cfg.Cosmetics.wingsSize, t)
        part.Transparency = 0.15
        part.Material = Enum.Material.Neon
        part.Color = col
        part.CanCollide = false
        part.Massless = true
        part.Anchored = false
        local w2 = Instance.new("Weld")
        w2.Part0 = lastPart
        w2.Part1 = part
        if i == 1 then
            w2.C0 = lastCF
        else
            w2.C0 = CFrame.new(0, segments[i - 1][2] * 0.9, 0) * CFrame.Angles(0, math.rad(sgn * -10), math.rad(sgn * -8))
        end
        w2.Parent = part
        part.Parent = folder
        lastPart = part
    end
    cosObjects["wing_" .. side] = folder
end

local function buildHalo()
    local ch = getChar()
    local head = ch and ch:FindFirstChild("Head")
    if not head then return end
    clearCosObject("halo")
    local part = Instance.new("Part")
    part.Name = "HakoHalo"
    part.Shape = Enum.PartType.Cylinder
    if Cfg.Cosmetics.haloMode == 1 then
        part.Size = Vector3.new(0.18, 2.6, 2.6)
    elseif Cfg.Cosmetics.haloMode == 2 then
        part.Size = Vector3.new(0.3, 3.0, 3.0)
    else
        part.Size = Vector3.new(0.12, 2.0, 2.0)
    end
    part.Transparency = 0.15
    part.Material = Enum.Material.Neon
    part.Color = Colors[Cfg.Cosmetics.haloColor][1]
    part.CanCollide = false
    part.Massless = true
    part.Anchored = false
    local w = Instance.new("Weld")
    w.Part0 = head
    w.Part1 = part
    w.C0 = CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90))
    w.Parent = part
    part.Parent = ch
    cosObjects.halo = part
end

local function buildTrail()
    local ch = getChar()
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    clearCosObject("trail")
    local att = Instance.new("Attachment")
    att.Position = Vector3.new(0, 0, 0)
    att.Parent = hrp
    local tr = Instance.new("Trail")
    tr.Attachment0 = att
    tr.Attachment1 = att
    if Cfg.Cosmetics.trailMode == 1 then
        tr.Lifetime = 1.2
        tr.MinLength = 0.1
    elseif Cfg.Cosmetics.trailMode == 2 then
        tr.Lifetime = 2.0
        tr.MinLength = 0.5
    else
        tr.Lifetime = 0.5
        tr.MinLength = 0.05
    end
    tr.Color = ColorSequence.new(Colors[Cfg.Cosmetics.trailColor][1], Theme.accent2)
    tr.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
    tr.Parent = hrp
    cosObjects.trail = tr
    cosObjects.trailAtt = att
end

local function buildAura()
    local ch = getChar()
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    clearCosObject("aura")
    local pe = Instance.new("ParticleEmitter")
    pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    pe.Rate = 40 * Cfg.Cosmetics.auraDensity
    pe.Lifetime = NumberRange.new(0.6, 1.2)
    pe.Speed = NumberRange.new(1, 3)
    pe.SpreadAngle = Vector2.new(360, 360)
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0)
    })
    pe.Color = ColorSequence.new(Colors[Cfg.Cosmetics.auraColor][1])
    pe.LightEmission = 0.8
    pe.Parent = hrp
    cosObjects.aura = pe
end

local function attachFootTrail()
    local ch = getChar()
    if not ch then return end
    for _, name in ipairs({"LeftFoot", "RightFoot", "LeftLeg", "RightLeg"}) do
        local part = ch:FindFirstChild(name)
        if part and not part:FindFirstChild("HakoFootTrail") then
            local att = Instance.new("Attachment")
            att.Name = "HakoFootTrail"
            att.Parent = part
            local pe = Instance.new("ParticleEmitter")
            pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
            pe.Rate = 8
            pe.Lifetime = NumberRange.new(0.4, 0.8)
            pe.Speed = NumberRange.new(0.5, 1.5)
            pe.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.6),
                NumberSequenceKeypoint.new(1, 0)
            })
            pe.Color = ColorSequence.new(Colors[Cfg.Cosmetics.footTrailColor][1])
            pe.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(1, 1)
            })
            pe.Parent = att
        end
    end
end

local function detachFootTrail()
    local ch = getChar()
    if not ch then return end
    for _, d in ipairs(ch:GetDescendants()) do
        if d.Name == "HakoFootTrail" and d:IsA("Attachment") then pcall(function() d:Destroy() end) end
    end
end

local function refreshWings()
    clearCosObject("wing_L")
    clearCosObject("wing_R")
    if Cfg.Cosmetics.wings then
        local col = Colors[Cfg.Cosmetics.wingsColor][1]
        buildWingSide("L", Cfg.Cosmetics.wingsMode, col)
        buildWingSide("R", Cfg.Cosmetics.wingsMode, col)
    end
end

local function refreshHalo()
    clearCosObject("halo")
    if Cfg.Cosmetics.halo then buildHalo() end
end

local function refreshTrail()
    clearCosObject("trail")
    if Cfg.Cosmetics.trail then buildTrail() end
end

local function refreshAura()
    clearCosObject("aura")
    if Cfg.Cosmetics.aura then buildAura() end
end

local function applyItemAnim()
    local ch = getChar()
    if not ch then return end
    for _, tool in ipairs(ch:GetChildren()) do
        if tool:IsA("Tool") then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                if Cfg.Cosmetics.itemSpin and not handle:FindFirstChild("HakoSpinAV") then
                    pcall(function()
                        local av = Instance.new("BodyAngularVelocity")
                        av.Name = "HakoSpinAV"
                        av.AngularVelocity = Vector3.new(0, 8, 0)
                        av.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                        av.Parent = handle
                    end)
                elseif not Cfg.Cosmetics.itemSpin and handle:FindFirstChild("HakoSpinAV") then
                    pcall(function() handle.HakoSpinAV:Destroy() end)
                end
                if Cfg.Cosmetics.itemTrail and not handle:FindFirstChild("HakoToolTrail") then
                    pcall(function()
                        local a0 = Instance.new("Attachment")
                        a0.Name = "HakoToolTrail"
                        a0.Position = Vector3.new(0, 0.5, 0)
                        a0.Parent = handle
                        local a1 = Instance.new("Attachment")
                        a1.Name = "HakoToolTrail2"
                        a1.Position = Vector3.new(0, -0.5, 0)
                        a1.Parent = handle
                        local tr = Instance.new("Trail")
                        tr.Attachment0 = a0
                        tr.Attachment1 = a1
                        tr.Lifetime = 0.4
                        tr.Color = ColorSequence.new(Colors[Cfg.Cosmetics.mainColor][1])
                        tr.Parent = handle
                    end)
                elseif not Cfg.Cosmetics.itemTrail then
                    for _, d in ipairs(handle:GetChildren()) do
                        if d.Name == "HakoToolTrail" or d.Name == "HakoToolTrail2" then
                            pcall(function() d:Destroy() end)
                        end
                        if d:IsA("Trail") then pcall(function() d:Destroy() end) end
                    end
                end
            end
        end
    end
end

-- ================== ATMOSPHERE ==================
local atmosOriginal = nil
local function saveAtmos()
    if atmosOriginal then return end
    atmosOriginal = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        Brightness = Lighting.Brightness,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
    }
end

local function applyAtmosphere()
    if not Cfg.World.atmosphere then
        if atmosOriginal then
            pcall(function()
                Lighting.Ambient = atmosOriginal.Ambient
                Lighting.OutdoorAmbient = atmosOriginal.OutdoorAmbient
                Lighting.Brightness = atmosOriginal.Brightness
                Lighting.ColorShift_Top = atmosOriginal.ColorShift_Top
                Lighting.ColorShift_Bottom = atmosOriginal.ColorShift_Bottom
            end)
        end
        return
    end
    saveAtmos()
    local p = Cfg.World.atmospherePreset
    if p == 1 then
        Lighting.Ambient = Color3.fromRGB(180, 190, 210)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 190, 210)
        Lighting.Brightness = 2
        Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 240)
        Lighting.ColorShift_Bottom = Color3.fromRGB(200, 210, 230)
    elseif p == 2 then
        Lighting.Ambient = Color3.fromRGB(70, 90, 130)
        Lighting.OutdoorAmbient = Color3.fromRGB(60, 80, 120)
        Lighting.Brightness = 1
        Lighting.ColorShift_Top = Color3.fromRGB(100, 140, 200)
        Lighting.ColorShift_Bottom = Color3.fromRGB(40, 50, 80)
    elseif p == 3 then
        Lighting.Ambient = Color3.fromRGB(200, 140, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 140, 255)
        Lighting.Brightness = 2
        Lighting.ColorShift_Top = Color3.fromRGB(255, 100, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(100, 200, 255)
    elseif p == 4 then
        Lighting.Ambient = Color3.fromRGB(60, 60, 60)
        Lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 60)
        Lighting.Brightness = 0.3
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.fromRGB(30, 30, 30)
    elseif p == 5 then
        Lighting.Ambient = Color3.fromRGB(240, 200, 160)
        Lighting.OutdoorAmbient = Color3.fromRGB(240, 200, 160)
        Lighting.Brightness = 2
        Lighting.ColorShift_Top = Color3.fromRGB(255, 220, 180)
        Lighting.ColorShift_Bottom = Color3.fromRGB(200, 150, 100)
    elseif p == 6 then
        Lighting.Ambient = Color3.fromRGB(180, 200, 240)
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 200, 240)
        Lighting.Brightness = 1.5
        Lighting.ColorShift_Top = Color3.fromRGB(180, 220, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(150, 180, 220)
    else
        local h = Cfg.World.atmosphereHue
        local s = Cfg.World.atmosphereSat
        local b = Cfg.World.atmosphereBright
        local c = Color3.fromHSV(h, s, b)
        Lighting.Ambient = c
        Lighting.OutdoorAmbient = c
        Lighting.Brightness = Cfg.World.atmosphereContrast * 2
        Lighting.ColorShift_Top = c
        Lighting.ColorShift_Bottom = c
    end
end

-- ================== OPTIMIZER ==================
local optimizerStore = nil
local function applyOptimizer()
    if not Cfg.World.optimizer then
        if optimizerStore then
            pcall(function()
                for d, v in pairs(optimizerStore) do
                    if d and d.Parent then d.Transparency = v end
                end
            end)
            optimizerStore = nil
        end
        return
    end
    if Cfg.World.optimizerShadows then
        pcall(function()
            for _, d in ipairs(Lighting:GetChildren()) do
                if d:IsA("Sky") then d.Parent = nil end
            end
            Lighting.GlobalShadows = false
        end)
    end
    if Cfg.World.optimizerParticles then
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                    d.Enabled = false
                end
            end
        end)
    end
    if Cfg.World.optimizerLighting then
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
                    d.Enabled = false
                end
            end
        end)
    end
    if Cfg.World.optimizerMeshes then
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("MeshPart") or d:IsA("SpecialMesh") then
                    d.Enabled = false
                end
            end
        end)
    end
    if Cfg.World.optimizerFps > 0 then
        pcall(function()
            if setfpscap then setfpscap(Cfg.World.optimizerFps) end
        end)
    end
end

-- ================== AUTOPLAY ==================
local function autoPlayLoop()
    if not Cfg.Combat.autoPlay then return end
    gatherTargets()
    local target = candidateList[1]
    if not target then return end
    local dist = target.dist
    if dist > Cfg.Combat.autoPlayRange then
        -- move toward target
        local hum = getHum()
        local hrp = getHRP()
        if hum and hrp then
            local dir = (target.part.Position - hrp.Position).Unit
            pcall(function()
                hum:Move(dir, false)
            end)
        end
        return
    end
    autoFire()
    if Cfg.Combat.autoPlayDodge then
        local hum = getHum()
        local hrp = getHRP()
        if hum and hrp then
            local right = Camera.CFrame.RightVector
            local strafe = math.sin(os.clock() * 2) > 0 and right or -right
            pcall(function()
                hum:Move(strafe, false)
            end)
        end
    end
end

-- ================== FORCEOP (client-side) ==================
local ForceOP = {god = false, commands = {}}

local function opGamemode(arg)
    local mode = tostring(arg or "1")
    local hum = getHum()
    if mode == "1" or mode == "creative" or mode == "c" then
        if hum then
            hum.WalkSpeed = 50
            hum.JumpPower = 100
            hum.UseJumpPower = true
        end
        Cfg.Movement.fly = true
        Cfg.Movement.noclip = true
        notify("/gamemode creative", Theme.good)
    elseif mode == "0" or mode == "survival" or mode == "s" then
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
        Cfg.Movement.fly = false
        Cfg.Movement.noclip = false
        notify("/gamemode survival", Theme.accent2)
    elseif mode == "2" or mode == "adventure" or mode == "a" then
        if hum then hum.WalkSpeed = 16 end
        Cfg.Movement.fly = false
        notify("/gamemode adventure", Theme.accent2)
    elseif mode == "3" or mode == "spectator" or mode == "sp" then
        Cfg.Movement.fly = true
        Cfg.Movement.noclip = true
        notify("/gamemode spectator", Theme.accent3)
    end
end

local function opOp() notify("/op granted (local)", Theme.good) end
local function opDeop() notify("/deop (local)", Theme.accent2) end
local function opGive(arg)
    notify("/give " .. (arg or "item") .. " (local)", Theme.accent2)
end
local function opClear()
    local ch = getChar()
    if ch then
        for _, c in ipairs(ch:GetChildren()) do
            if c:IsA("Tool") then pcall(function() c:Destroy() end) end
        end
    end
    notify("/clear", Theme.accent2)
end
local function opEffect(arg)
    local t = tonumber(arg) or 5
    local hum = getHum()
    if hum then pcall(function() hum.WalkSpeed = 16 + t end) end
    notify("/effect speed " .. t, Theme.accent2)
end
local function opEnchant()
    notify("/enchant (local)", Theme.accent2)
end
local function opXp(arg)
    local n = tonumber(arg) or 100
    notify("/xp " .. n .. " (local)", Theme.accent2)
end
local function opTp(arg)
    if not arg or arg == "" then notify("/tp <name>", Theme.bad); return end
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Name:lower():sub(1, #arg) == arg:lower() then target = p; break end
    end
    if target and target.Character then
        local hrp = getHRP()
        local thrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp and thrp then
            hrp.CFrame = thrp.CFrame + Vector3.new(0, 3, 0)
            notify("/tp " .. target.Name, Theme.good)
        end
    else
        notify("/tp: not found", Theme.bad)
    end
end
local function opKill()
    local hum = getHum()
    if hum then pcall(function() hum.Health = 0 end) end
    notify("/kill", Theme.bad)
end
local function opKick(arg)
    notify("/kick " .. (arg or "target") .. " (local)", Theme.warn)
end
local function opBan(arg)
    notify("/ban " .. (arg or "target") .. " (local)", Theme.warn)
end
local function opPardon(arg)
    notify("/pardon " .. (arg or "target"), Theme.accent2)
end
local function opWhitelist(arg)
    notify("/whitelist " .. (arg or "add") .. " (local)", Theme.accent2)
end
local function opTime(arg)
    local t = tonumber(arg) or 12000
    pcall(function() Lighting.ClockTime = t end)
    notify("/time set " .. t, Theme.accent2)
end
local function opWeather(arg)
    notify("/weather " .. (arg or "clear"), Theme.accent2)
end
local function opDifficulty(arg)
    notify("/difficulty " .. (arg or "peaceful"), Theme.accent2)
end
local function opGamerule(arg)
    notify("/gamerule " .. (arg or "keepInventory"), Theme.accent2)
end
local function opSetSpawn()
    notify("/setworldspawn (local)", Theme.accent2)
end
local function opSpawnpoint()
    notify("/spawnpoint (local)", Theme.accent2)
end
local function opSummon(arg)
    local p = Instance.new("Part")
    p.Size = Vector3.new(2, 2, 2)
    p.Material = Enum.Material.Neon
    p.Color = Theme.accent2
    p.Position = Camera.CFrame.Position + Camera.CFrame.LookVector * 8
    p.Parent = Workspace
    notify("/summon " .. (arg or "part"), Theme.accent2)
end
local function opFill(arg)
    local hrp = getHRP()
    if not hrp then return end
    for x = -3, 3 do
        for y = 0, 2 do
            for z = -3, 3 do
                local p = Instance.new("Part")
                p.Size = Vector3.new(4, 4, 4)
                p.Material = Enum.Material.Neon
                p.Color = Theme.accent
                p.CanCollide = false
                p.Position = hrp.Position + Vector3.new(x * 4, y * 4, z * 4)
                p.Parent = Workspace
            end
        end
    end
    notify("/fill (local)", Theme.accent2)
end
local function opClone()
    notify("/clone (local)", Theme.accent2)
end
local function opSetblock()
    local hrp = getHRP()
    if not hrp then return end
    local p = Instance.new("Part")
    p.Size = Vector3.new(4, 4, 4)
    p.Material = Enum.Material.Neon
    p.Color = Theme.accent
    p.Position = hrp.Position + Vector3.new(0, 6, 0)
    p.Parent = Workspace
    notify("/setblock (local)", Theme.accent2)
end
local function opExplode(arg)
    local hrp = getHRP()
    if not hrp then return end
    for _ = 1, 6 do
        task.spawn(function()
            local ex = Instance.new("Explosion")
            ex.Position = hrp.Position + Vector3.new(math.random(-10, 10), math.random(0, 8), math.random(-10, 10))
            ex.BlastRadius = 8
            ex.BlastPressure = 0
            ex.DestroyJointRadiusPercent = 0
            ex.Parent = Workspace
            task.wait(0.15)
            pcall(function() ex:Destroy() end)
        end)
    end
    notify("/execute explode", Theme.accent3)
end
local function opTitle(arg)
    local t = arg or "HakoUI"
    local gui = LP:FindFirstChildOfClass("PlayerGui"):FindFirstChild("HakoUI")
    local f = Instance.new("TextLabel")
    f.Size = UDim2.fromScale(1, 0.2)
    f.Position = UDim2.fromScale(0, 0.4)
    f.BackgroundTransparency = 1
    f.Font = Enum.Font.GothamBlack
    f.TextSize = 60
    f.TextColor3 = Theme.accent
    f.TextStrokeTransparency = 0
    f.Text = t
    f.Parent = gui or LP:FindFirstChildOfClass("PlayerGui")
    task.wait(2)
    pcall(function()
        Tween:Create(f, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
    end)
    task.wait(0.6)
    pcall(function() f:Destroy() end)
    notify("/title " .. t, Theme.accent2)
end
local function opPlaysound()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://9046901975"
    s.Volume = 2
    s.Parent = getHRP() or Camera
    s:Play()
    notify("/playsound", Theme.accent2)
end
local function opParticle()
    local hrp = getHRP()
    if not hrp then return end
    local pe = Instance.new("ParticleEmitter")
    pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    pe.Rate = 60
    pe.Lifetime = NumberRange.new(0.5, 1)
    pe.Parent = hrp
    task.wait(1)
    pcall(function() pe:Destroy() end)
    notify("/particle", Theme.accent2)
end
local function opWorldborder()
    notify("/worldborder (local)", Theme.accent2)
end
local function opLocate()
    notify("/locate (local)", Theme.accent2)
end
local function opPlace()
    notify("/place (local)", Theme.accent2)
end
local function opDamage(arg)
    local n = tonumber(arg) or 5
    local hum = getHum()
    if hum then pcall(function() hum.Health = math.max(0, hum.Health - n) end) end
    notify("/damage " .. n, Theme.bad)
end
local function opAttribute()
    notify("/attribute (local)", Theme.accent2)
end
local function opData()
    notify("/data (local)", Theme.accent2)
end
local function opBossbar()
    notify("/bossbar (local)", Theme.accent2)
end
local function opSchedule()
    notify("/schedule (local)", Theme.accent2)
end
local function opFunction()
    notify("/function (local)", Theme.accent2)
end
local function opHeal()
    local hum = getHum()
    if hum then pcall(function() hum.Health = hum.MaxHealth end) end
    notify("/heal", Theme.good)
end
local function opGod()
    ForceOP.god = not ForceOP.god
    notify("/god " .. (ForceOP.god and "ON" or "OFF"), ForceOP.god and Theme.good or Theme.bad)
end
local function opFly()
    Cfg.Movement.fly = not Cfg.Movement.fly
    notify("/fly " .. (Cfg.Movement.fly and "ON" or "OFF"), Theme.accent)
end
local function opSpeed(arg)
    local n = tonumber(arg) or 50
    local hum = getHum()
    if hum then pcall(function() hum.WalkSpeed = math.clamp(n, 1, 500) end) end
    notify("/speed " .. n, Theme.accent)
end
local function opJump(arg)
    local n = tonumber(arg) or 100
    local hum = getHum()
    if hum then
        pcall(function()
            hum.UseJumpPower = true
            hum.JumpPower = math.clamp(n, 1, 500)
        end)
    end
    notify("/jump " .. n, Theme.accent)
end
local function opHelp()
    notify("Commands: /op /deop /gamemode /give /clear /effect /enchant /xp /tp /kill /kick /ban /whitelist /time /weather /difficulty /gamerule /summon /fill /setblock /execute /title /playsound /particle /damage /god /fly /speed /jump /heal /help", Theme.accent2)
end

ForceOP.commands = {
    op = opOp, deop = opDeop,
    gamemode = opGamemode, gm = opGamemode,
    give = opGive, clear = opClear,
    effect = opEffect, enchant = opEnchant,
    xp = opXp, experience = opXp,
    tp = opTp, teleport = opTp,
    kill = opKill, kick = opKick,
    ban = opBan, pardon = opPardon,
    whitelist = opWhitelist,
    time = opTime, weather = opWeather, difficulty = opDifficulty,
    gamerule = opGamerule, setworldspawn = opSetSpawn, spawnpoint = opSpawnpoint,
    summon = opSummon, fill = opFill, clone = opClone, setblock = opSetblock,
    execute = opExplode,
    title = opTitle, playsound = opPlaysound, stopsound = opPlaysound,
    particle = opParticle, worldborder = opWorldborder,
    locate = opLocate, place = opPlace,
    damage = opDamage, attribute = opAttribute,
    data = opData, bossbar = opBossbar,
    schedule = opSchedule, function = opFunction,
    heal = opHeal, god = opGod, fly = opFly,
    speed = opSpeed, jump = opJump,
    help = opHelp,
}

local function execForceOp(text)
    if not Cfg.Exploits.forceOp then return false end
    if text:sub(1, 1) ~= "/" then return false end
    local body = text:sub(2)
    local parts = {}
    for w in body:gmatch("%S+") do parts[#parts + 1] = w end
    if #parts == 0 then return false end
    local cmd = parts[1]:lower()
    local arg = parts[2]
    local h = ForceOP.commands[cmd]
    if h then
        pcall(h, arg)
        return true
    end
    return false
end

-- ================== CODE EXPOSER ==================
local function codeExpose()
    local info = {}
    info.place = game.PlaceId
    info.jobId = game.JobId
    info.playerCount = #Players:GetPlayers()
    info.services = {}
    for _, s in ipairs(game:GetChildren()) do
        if s:IsA("ServiceProvider") or pcall(function() s.Name end) then
            info.services[#info.services + 1] = s.Name
        end
    end
    info.playerScripts = {}
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, d in ipairs(pg:GetDescendants()) do
            if d:IsA("LocalScript") then
                info.playerScripts[#info.playerScripts + 1] = d:GetFullName()
            end
        end
    end
    info.gEnv = {}
    for k in pairs(getgenv and getgenv() or {}) do
        info.gEnv[#info.gEnv + 1] = tostring(k)
    end
    return info
end

local function execLua(code)
    local fn, err = loadstring(code)
    if not fn then return false, err end
    local ok, res = pcall(fn)
    return ok, res
end

-- ================== MAP EXPLOIT / NUKER / CRASHER ==================
local function mapExploit(mode)
    if mode == "hideall" then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then d.Transparency = 1 end
        end
        notify("Map Exploit: hid all parts", Theme.accent3)
    elseif mode == "deleteall" then
        local n = 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") and not d:IsDescendantOf(getChar()) then
                pcall(function() d:Destroy() end)
                n = n + 1
            end
        end
        notify("Map Exploit: deleted " .. n .. " parts", Theme.accent3)
    elseif mode == "nullparts" then
        local n = 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                pcall(function()
                    d.Size = Vector3.new(0.1, 0.1, 0.1)
                    d.Transparency = 1
                    d.CanCollide = false
                end)
                n = n + 1
            end
        end
        notify("Map Exploit: nulled " .. n, Theme.accent3)
    elseif mode == "killnpcs" then
        local n = 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Humanoid") and not d:IsDescendantOf(getChar()) then
                pcall(function() d.Health = 0 end)
                n = n + 1
            end
        end
        notify("Map Exploit: killed " .. n .. " NPCs", Theme.accent3)
    elseif mode == "deletelights" then
        local n = 0
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Light") then
                pcall(function() d:Destroy() end)
                n = n + 1
            end
        end
        notify("Map Exploit: deleted " .. n .. " lights", Theme.accent3)
    end
end

local function mapNuker(mode, radius)
    local hrp = getHRP()
    if not hrp then return end
    local n = 0
    radius = radius or 50
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and not d:IsDescendantOf(getChar()) then
            if mode == "radius" then
                if (d.Position - hrp.Position).Magnitude <= radius then
                    pcall(function() d:Destroy() end)
                    n = n + 1
                end
            elseif mode == "types" then
                if d.Material == Enum.Material.Plastic or d.Material == Enum.Material.Wood then
                    pcall(function() d:Destroy() end)
                    n = n + 1
                end
            elseif mode == "everything" then
                pcall(function() d:Destroy() end)
                n = n + 1
            end
            if n > 2000 then break end
        end
    end
    notify("Nuke: " .. mode .. " -> " .. n .. " parts", Theme.accent3)
end

local crashActive = false
local function crash(mode)
    if crashActive then return end
    crashActive = true
    if mode == "parts" then
        for _ = 1, 100 do
            local p = Instance.new("Part")
            p.Size = Vector3.new(1000, 1000, 1000)
            p.Parent = Workspace
        end
    elseif mode == "particles" then
        local hrp = getHRP()
        if hrp then
            for _ = 1, 20 do
                local pe = Instance.new("ParticleEmitter")
                pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                pe.Rate = 500
                pe.Lifetime = NumberRange.new(10, 20)
                pe.Parent = hrp
            end
        end
    elseif mode == "sounds" then
        for _ = 1, 30 do
            local s = Instance.new("Sound")
            s.SoundId = "rbxassetid://9046901975"
            s.Volume = 10
            s.Looped = true
            s.Parent = Camera
            s:Play()
        end
    elseif mode == "loop" then
        for _ = 1, 100000 do
            local p = Instance.new("Part")
            p.Parent = nil
        end
    end
    notify("Crasher: " .. mode, Theme.bad)
    task.wait(5)
    crashActive = false
end

-- ================== CONFIG SYSTEM ==================
local ConfigFolder = "HakoUI_Configs"
local function ensureFolder()
    pcall(function() if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end end)
end
local function saveConfig(name)
    if not name or name == "" then name = "default" end
    ensureFolder()
    local path = ConfigFolder .. "/" .. name .. ".json"
    local ok, data = pcall(function() return HttpService:JSONEncode(Cfg) end)
    if ok and writefile then
        writefile(path, data)
        notify("Config saved: " .. name, Theme.good)
    end
end
local function loadConfig(name)
    if not name or name == "" then name = "default" end
    ensureFolder()
    local path = ConfigFolder .. "/" .. name .. ".json"
    if readfile and isfile and isfile(path) then
        local ok, data = pcall(function() return readfile(path) end)
        if ok and data then
            local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
            if ok2 and decoded then
                for group, vals in pairs(decoded) do
                    if Cfg[group] then
                        for k, v in pairs(vals) do
                            Cfg[group][k] = v
                        end
                    end
                end
                notify("Config loaded: " .. name, Theme.good)
            end
        end
    end
end
local function listConfigs()
    ensureFolder()
    local list = {}
    if listfiles then
        local ok, files = pcall(function() return listfiles(ConfigFolder) end)
        if ok and files then
            for _, f in ipairs(files) do
                local name = f:match("([^/\\]+)%.json$")
                if name then list[#list + 1] = name end
            end
        end
    end
    return list
end

-- ================== UI BUILD ==================
local function makeGui()
    local g = Instance.new("ScreenGui")
    g.Name = "HakoUI"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    pcall(function() g.DisplayOrder = 2147483000 end)
    pcall(function() g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then pcall(function() pg = LP:WaitForChild("PlayerGui", 8) end) end
    if pg then
        local old = pg:FindFirstChild("HakoUI")
        if old then pcall(function() old:Destroy() end) end
        pcall(function() g.Parent = pg end)
    end
    if not g.Parent then
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok and cg then
            local old = cg:FindFirstChild("HakoUI")
            if old then pcall(function() old:Destroy() end) end
            pcall(function() g.Parent = cg end)
        end
    end
    return g
end

local gui = makeGui()
if not gui.Parent then warn("[HakoUI] GUI failed"); return end
print("[HakoUI] GUI attached")

local main, winScale, open = nil, nil, false
local tabList, pageBuilders = {}, {}
local scroller, pageFrame, pageList = nil, nil, nil
local activeSlider = nil
local flyV = 0
local pickMode, pickToast, toastText = false, nil, nil
local shootStatus = nil
local hBtn, hStroke = nil, nil

local function setStatus(t)
    if shootStatus and shootStatus.Parent then shootStatus.Text = t end
end

local function updateShootStatus()
    local b = getShootBtn()
    if b then setStatus("Button: " .. b.Name) else setStatus("Button: none") end
end

local function startPick()
    pickMode = true
    if pickToast then
        pickToast.Visible = true
        toastText.Text = "Click the shoot button in-game to bind"
    end
    if open then open = false; if main then main.Visible = false end end
end

local function setShootBtn(b)
    shootBtn = b
    btnPath = capturePath(b)
    updateShootStatus()
end

local function setOpen(v)
    open = v
    if not main or not main.Parent or not winScale then return end
    if v then
        main.Visible = true
        pcall(function()
            winScale.Scale = 0.85
            Tween:Create(winScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        end)
    else
        pcall(function()
            local tw = Tween:Create(winScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.85})
            tw.Completed:Connect(function() if main and not open then main.Visible = false end end)
            tw:Play()
        end)
    end
end

local hBtnSize = 56
hBtn = ri("TextButton", {
    Name = "HakoH",
    Size = UDim2.fromOffset(hBtnSize, hBtnSize),
    Position = UDim2.new(1, -(hBtnSize + 18), 1, -(hBtnSize + 150)),
    BackgroundColor3 = Theme.accent,
    BorderSizePixel = 0,
    Text = "H",
    Font = Enum.Font.GothamBold,
    TextSize = 26,
    TextColor3 = Theme.white,
    AutoButtonColor = false,
    ZIndex = 61,
}, gui)
ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, hBtn)
hStroke = ri("UIStroke", {Color = Theme.white, Thickness = 1, Transparency = 0.7}, hBtn)
ri("UIGradient", {Color = ColorSequence.new(Theme.accent, Theme.accent2), Rotation = 45}, hBtn)

task.spawn(function()
    while gui.Parent and not Unloaded do
        if hBtn and hStroke then
            pcall(function()
                hStroke.Transparency = 0.4 + (math.sin(os.clock() * 2) + 1) / 2 * 0.3
            end)
        end
        task.wait(0.05)
    end
end)

local hDrag, hMoved = false, false
local hStartInput, hStartAbs = Vector2.new(), Vector2.new()
hBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        hDrag = true
        hMoved = false
        hStartInput = i.Position
        hStartAbs = hBtn.AbsolutePosition
    end
end)
UIS.InputChanged:Connect(function(i)
    if not hDrag then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local d = i.Position - hStartInput
        if d.Magnitude > 10 then hMoved = true end
        if hMoved then
            local v = viewport()
            hBtn.Position = UDim2.fromOffset(
                math.clamp(hStartAbs.X + d.X, 4, v.X - hBtnSize - 4),
                math.clamp(hStartAbs.Y + d.Y, 4, v.Y - hBtnSize - 4)
            )
        end
    end
end)
UIS.InputEnded:Connect(function(i)
    if not hDrag then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        hDrag = false
        if not hMoved then setOpen(not open) end
    end
end)

local flyCtrl = ri("Frame", {
    Name = "FlyCtrl",
    Size = UDim2.fromOffset(58, 124),
    Position = UDim2.new(0, 12, 0.5, -62),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 45,
}, gui)

local function flyBtn(text, y, dir)
    local b = ri("TextButton", {
        Size = UDim2.fromOffset(58, 58),
        Position = UDim2.fromOffset(0, y),
        BackgroundColor3 = Theme.bg,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = Theme.accent2,
        AutoButtonColor = false,
        ZIndex = 46,
    }, flyCtrl)
    ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, b)
    ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = 0.3}, b)
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then flyV = dir end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then flyV = 0 end
    end)
end
flyBtn("^", 0, 1)
flyBtn("v", 66, -1)

pickToast = ri("Frame", {
    Name = "PickToast",
    Size = UDim2.fromOffset(300, 100),
    Position = UDim2.new(0.5, 0, 0, 60),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = Theme.bg,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 500,
}, gui)
ri("UICorner", {CornerRadius = UDim2.new(0, 16, 0, 16)}, pickToast)
ri("UIStroke", {Color = Theme.accent, Thickness = 1, Transparency = 0.25}, pickToast)
toastText = ri("TextLabel", {
    Size = UDim2.new(1, -24, 0, 56),
    Position = UDim2.new(0, 12, 0, 8),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextWrapped = true,
    TextColor3 = Theme.text,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = "Click the shoot button in-game",
    ZIndex = 501,
}, pickToast)
local cancelPick = ri("TextButton", {
    Size = UDim2.new(1, -24, 0, 28),
    Position = UDim2.new(0, 12, 1, -36),
    BackgroundColor3 = Theme.card,
    BorderSizePixel = 0,
    Text = "Cancel",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Theme.sub,
    AutoButtonColor = false,
    ZIndex = 501,
}, pickToast)
ri("UICorner", {CornerRadius = UDim2.new(0, 9, 0, 9)}, cancelPick)
cancelPick.MouseButton1Click:Connect(function() pickMode = false; pickToast.Visible = false end)

local watermark = ri("Frame", {
    Name = "WM",
    Size = UDim2.fromOffset(240, 34),
    Position = UDim2.new(0, 14, 0, 14),
    BackgroundColor3 = Theme.bg,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ZIndex = 55,
}, gui)
ri("UICorner", {CornerRadius = UDim2.new(0, 10, 0, 10)}, watermark)
local wmStroke = ri("UIStroke", {Color = Theme.accent, Thickness = 1, Transparency = 0.4}, watermark)
ri("UIGradient", {Color = ColorSequence.new(Theme.accent, Theme.accent2), Rotation = 30}, wmStroke)
local wmDot = ri("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(0, 10, 0.5, -4),
    BackgroundColor3 = Theme.accent,
    BorderSizePixel = 0,
    ZIndex = 56,
}, watermark)
ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, wmDot)
local wmText = ri("TextLabel", {
    Size = UDim2.new(1, -30, 1, 0),
    Position = UDim2.new(0, 24, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = Theme.white,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "HakoUI v4.0",
    ZIndex = 56,
}, watermark)

task.spawn(function()
    while gui.Parent and not Unloaded do
        if watermark and watermark.Parent then
            watermark.Visible = Cfg.Misc.watermark
            if watermark.Visible then
                pcall(function()
                    wmStroke.Transparency = 0.4 + (math.sin(os.clock() * 1.5) + 1) / 2 * 0.35
                    wmDot.BackgroundColor3 = Color3.fromRGB(
                        math.floor(140 + math.sin(os.clock()) * 30),
                        math.floor(100 + math.sin(os.clock() + 2) * 30),
                        255
                    )
                end)
                local ping = 0
                pcall(function() local p = LP:GetNetworkPing(); if p then ping = math.floor(p * 1000) end end)
                wmText.Text = "HakoUI v4.0 | " .. ping .. "ms"
            end
        end
        task.wait(0.1)
    end
end)

-- UI helpers
local function section(parent, title)
    local l = ri("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Theme.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = string.upper(title),
        ZIndex = 23,
    }, parent)
    ri("UIPadding", {PaddingLeft = UDim2.new(0, 6, 0, 0)}, l)
end

local function makeToggle(parent, text, tbl, key, cb)
    local row = ri("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.card,
        BorderSizePixel = 0,
        ZIndex = 23,
    }, parent)
    ri("UICorner", {CornerRadius = UDim2.new(0, 12, 0, 12)}, row)
    ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = 0.45}, row)
    ri("TextLabel", {
        Size = UDim2.new(1, -86, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        ZIndex = 24,
    }, row)
    local sw = ri("Frame", {
        Size = UDim2.fromOffset(46, 26),
        Position = UDim2.new(1, -60, 0.5, -13),
        BackgroundColor3 = Theme.off,
        BorderSizePixel = 0,
        ZIndex = 24,
    }, row)
    ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, sw)
    local knob = ri("Frame", {
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.new(0, 3, 0.5, -10),
        BackgroundColor3 = Theme.white,
        BorderSizePixel = 0,
        ZIndex = 25,
    }, sw)
    ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, knob)
    local hit = ri("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 26,
    }, row)
    local function render(instant)
        local info = TweenInfo.new(instant and 0 or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        pcall(function()
            Tween:Create(sw, info, {BackgroundColor3 = tbl[key] and Theme.accent or Theme.off}):Play()
            Tween:Create(knob, info, {
                Position = tbl[key] and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
            }):Play()
        end)
    end
    hit.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        render(false)
        if cb then pcall(cb, tbl[key]) end
    end)
    render(true)
end

local function makeSlider(parent, text, tbl, key, min, max, step, cb)
    local holder = ri("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Theme.card,
        BorderSizePixel = 0,
        ZIndex = 23,
    }, parent)
    ri("UICorner", {CornerRadius = UDim2.new(0, 12, 0, 12)}, holder)
    ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = 0.45}, holder)
    ri("TextLabel", {
        Size = UDim2.new(1, -96, 0, 18),
        Position = UDim2.new(0, 14, 0, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        ZIndex = 24,
    }, holder)
    local val = ri("TextLabel", {
        Size = UDim2.new(0, 76, 0, 18),
        Position = UDim2.new(1, -90, 0, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Theme.accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(tbl[key]),
        ZIndex = 24,
    }, holder)
    local valHit = ri("TextButton", {
        Size = UDim2.fromOffset(80, 20),
        Position = UDim2.new(1, -90, 0, 10),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 25,
    }, holder)
    local track = ri("Frame", {
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 1, -22),
        BackgroundColor3 = Theme.track,
        BorderSizePixel = 0,
        ZIndex = 24,
    }, holder)
    ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, track)
    local fill = ri("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
        ZIndex = 25,
    }, track)
    ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, fill)
    ri("UIGradient", {Color = ColorSequence.new(Theme.accent, Theme.accent2), Rotation = 0}, fill)
    local knob = ri("Frame", {
        Size = UDim2.fromOffset(18, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Theme.white,
        BorderSizePixel = 0,
        ZIndex = 26,
    }, track)
    ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, knob)
    local hit = ri("TextButton", {
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 1, -38),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 27,
    }, holder)

    local function fmt(x)
        if step >= 1 then return tostring(math.floor(x + 0.5)) end
        return string.format("%.2f", x)
    end
    local function render()
        local a = 0
        if max > min then a = math.clamp((tbl[key] - min) / (max - min), 0, 1) end
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        val.Text = fmt(tbl[key])
    end
    local function applyAt(x)
        local ax, aw = hit.AbsolutePosition.X, hit.AbsoluteSize.X
        if aw <= 0 then return end
        local a = math.clamp((x - ax) / aw, 0, 1)
        local nv = min + (max - min) * a
        if step > 0 then nv = math.floor(nv / step + 0.5) * step end
        tbl[key] = math.clamp(nv, min, max)
        render()
        if cb then pcall(cb, tbl[key]) end
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            activeSlider = applyAt
            applyAt(i.Position.X)
        end
    end)

    -- number input on double tap (allow exceeding max!)
    local lastTap = 0
    valHit.MouseButton1Click:Connect(function()
        local t = os.clock()
        if t - lastTap < 0.35 then
            local editor = ri("TextBox", {
                Size = UDim2.fromOffset(80, 22),
                Position = UDim2.new(1, -90, 0, 8),
                BackgroundColor3 = Theme.card2,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = Theme.accent,
                Text = tostring(tbl[key]),
                ZIndex = 30,
            }, holder)
            ri("UICorner", {CornerRadius = UDim2.new(0, 6, 0, 6)}, editor)
            editor:CaptureFocus()
            editor.FocusLost:Connect(function(enter)
                if enter then
                    local n = tonumber(editor.Text)
                    if n then
                        tbl[key] = n
                        render()
                        if cb then pcall(cb, tbl[key]) end
                    end
                end
                editor:Destroy()
            end)
        end
        lastTap = t
    end)
    render()
end

local function makeCycle(parent, text, tbl, key, opts, cb)
    local row = ri("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.card,
        BorderSizePixel = 0,
        ZIndex = 23,
    }, parent)
    ri("UICorner", {CornerRadius = UDim2.new(0, 12, 0, 12)}, row)
    ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = 0.45}, row)
    ri("TextLabel", {
        Size = UDim2.new(1, -126, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextColor3 = Theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        ZIndex = 24,
    }, row)
    local vb = ri("TextButton", {
        Size = UDim2.fromOffset(104, 32),
        Position = UDim2.new(1, -116, 0.5, -16),
        BackgroundColor3 = Theme.track,
        BorderSizePixel = 0,
        Text = tostring(opts[tbl[key]] or opts[1]),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Theme.accent2,
        AutoButtonColor = false,
        ZIndex = 25,
    }, row)
    ri("UICorner", {CornerRadius = UDim2.new(0, 9, 0, 9)}, vb)
    ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = 0.4}, vb)
    vb.MouseButton1Click:Connect(function()
        tbl[key] = tbl[key] % #opts + 1
        vb.Text = tostring(opts[tbl[key]])
        if cb then pcall(cb, tbl[key]) end
    end)
end

local function makeButton(parent, text, accent, cb)
    local b = ri("TextButton", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = accent and Theme.accent or Theme.card2,
        BorderSizePixel = 0,
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = accent and Theme.white or Theme.text,
        AutoButtonColor = false,
        ZIndex = 24,
    }, parent)
    ri("UICorner", {CornerRadius = UDim2.new(0, 11, 0, 11)}, b)
    ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = accent and 1 or 0.45}, b)
    b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
    b.MouseEnter:Connect(function()
        pcall(function() Tween:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = accent and Theme.accent2 or Theme.card}):Play() end)
    end)
    b.MouseLeave:Connect(function()
        pcall(function() Tween:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = accent and Theme.accent or Theme.card2}):Play() end)
    end)
end

local function makeLabel(parent, text)
    local l = ri("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.card,
        BackgroundTransparency = 0.4,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextColor3 = Theme.sub,
        Text = text,
        ZIndex = 23,
    }, parent)
    ri("UICorner", {CornerRadius = UDim2.new(0, 10, 0, 10)}, l)
    return l
end

-- ================== TABS ==================
pageBuilders.combat = function()
    local p = pageFrame
    section(p, "AIM ASSIST")
    makeToggle(p, "Aim Assist", Cfg.Combat, "aim")
    makeSlider(p, "FOV", Cfg.Combat, "aimFov", 40, 500, 1)
    makeSlider(p, "Speed", Cfg.Combat, "aimSpeed", 1, 40, 1)
    makeSlider(p, "Smoothness", Cfg.Combat, "aimSmooth", 0.1, 1, 0.05)
    makeSlider(p, "Max Distance", Cfg.Combat, "aimMaxDist", 200, 5000, 100)
    makeSlider(p, "Prediction", Cfg.Combat, "aimPredict", 0, 100, 5)
    makeCycle(p, "Part", Cfg.Combat, "aimPart", {"Head", "Torso", "Nearest"})
    makeCycle(p, "Activation", Cfg.Combat, "aimMode", {"Always", "Hold RMB"})
    makeCycle(p, "Priority", Cfg.Combat, "aimPriority", {"Crosshair", "Distance", "Health"})
    makeToggle(p, "Only Visible", Cfg.Combat, "aimVisibleOnly")
    makeToggle(p, "Team Check", Cfg.Combat, "aimTeamCheck")
    makeToggle(p, "Ignore Dead", Cfg.Combat, "aimIgnoreDead")
    makeToggle(p, "FOV Ring", Cfg.Combat, "aimRing")
    makeToggle(p, "Highlight", Cfg.Combat, "aimHighlight")
    makeToggle(p, "Humanize", Cfg.Combat, "aimHumanize")
    makeToggle(p, "Sticky Target", Cfg.Combat, "aimSticky")

    section(p, "TARGET SWITCH")
    makeToggle(p, "Enable Switch", Cfg.Combat, "aimSwitch")
    makeSlider(p, "Switch Delay (ms)", Cfg.Combat, "aimSwitchDelay", 0, 1500, 25)
    makeToggle(p, "Multi Target", Cfg.Combat, "aimMultiTarget")

    section(p, "SILENT AIM")
    makeToggle(p, "Silent Aim", Cfg.Combat, "silentAim")
    makeCycle(p, "Mode", Cfg.Combat, "silentMode", {"Camera", "Mouse", "Both"})
    makeToggle(p, "Wall Check", Cfg.Combat, "silentWallCheck")

    section(p, "AUTO SHOOT")
    makeToggle(p, "Auto Shoot", Cfg.Combat, "shoot", function(v)
        if v and Cfg.Combat.shootMethod == 1 and not getShootBtn() then startPick() end
    end)
    makeCycle(p, "Method", Cfg.Combat, "shootMethod", {"Button", "Tool", "Mouse"}, function(i)
        if i == 1 and not getShootBtn() then startPick() end
    end)
    makeSlider(p, "Delay (ms)", Cfg.Combat, "shootDelay", 30, 800, 10)
    makeToggle(p, "Only With Target", Cfg.Combat, "shootOnlyTarget")
    makeToggle(p, "Hold (Mouse)", Cfg.Combat, "shootHold")
    makeButton(p, "Set Shoot Button", true, startPick)
    makeButton(p, "Test Fire", false, function()
        local ok = autoFire()
        setStatus(ok and "Fire OK" or "Fire FAIL")
    end)
    shootStatus = makeLabel(p, "Button: checking...")
    updateShootStatus()

    section(p, "TRIGGERBOT")
    makeToggle(p, "TriggerBot", Cfg.Combat, "trigger")
    makeSlider(p, "Range (px)", Cfg.Combat, "triggerRange", 5, 120, 1)
    makeSlider(p, "Delay (ms)", Cfg.Combat, "triggerDelay", 20, 400, 10)

    section(p, "HITBOX")
    makeToggle(p, "Hitbox Expander", Cfg.Combat, "hitbox")
    makeSlider(p, "Size", Cfg.Combat, "hitboxSize", 1, 10, 0.5)

    section(p, "AUTOPLAY")
    makeToggle(p, "Auto Play", Cfg.Combat, "autoPlay")
    makeCycle(p, "Mode", Cfg.Combat, "autoPlayMode", AutoModes)
    makeToggle(p, "Dodge", Cfg.Combat, "autoPlayDodge")
    makeSlider(p, "Combat Range", Cfg.Combat, "autoPlayRange", 20, 200, 5)

    section(p, "DISABLER")
    makeToggle(p, "Disabler", Cfg.Combat, "disabler")
end

pageBuilders.movement = function()
    local p = pageFrame
    section(p, "SPEED")
    makeToggle(p, "Speed", Cfg.Movement, "speed", function(v)
        if not v then local h = getHum(); if h then pcall(function() h.WalkSpeed = 16 end) end end
    end)
    makeSlider(p, "Value", Cfg.Movement, "speedValue", 16, 500, 1)
    makeCycle(p, "Method", Cfg.Movement, "speedMethod", {"WalkSpeed", "Velocity"})

    section(p, "JUMP")
    makeToggle(p, "Jump Power", Cfg.Movement, "jump", function(v)
        if not v then local h = getHum(); if h then pcall(function() h.JumpPower = 50 end) end end
    end)
    makeSlider(p, "Power", Cfg.Movement, "jumpPower", 50, 500, 5)
    makeToggle(p, "Infinite Jump", Cfg.Movement, "infJump")
    makeToggle(p, "Bunny Hop", Cfg.Movement, "bhop")
    makeToggle(p, "High Jump", Cfg.Movement, "highJump")
    makeToggle(p, "Long Jump", Cfg.Movement, "longJump")

    section(p, "FLY")
    makeToggle(p, "Fly", Cfg.Movement, "fly", function(v)
        if flyCtrl then flyCtrl.Visible = v end
        if not v then
            flyV = 0
            local hrp = getHRP()
            if hrp then pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end) end
        end
    end)
    makeCycle(p, "Mode", Cfg.Movement, "flyMode", FlyModes)
    makeSlider(p, "Speed", Cfg.Movement, "flySpeed", 20, 500, 5)
    makeSlider(p, "Vertical", Cfg.Movement, "vertSpeed", 20, 500, 5)

    section(p, "OTHER")
    makeToggle(p, "NoClip", Cfg.Movement, "noclip")
    makeToggle(p, "No Fall", Cfg.Movement, "noFall")
    makeToggle(p, "Walk On Water", Cfg.Movement, "water")
    makeToggle(p, "Anti-Fling", Cfg.Movement, "antiFling")
    makeToggle(p, "Gravity Override", Cfg.Movement, "gravity")
    makeSlider(p, "Gravity", Cfg.Movement, "gravityValue", 20, 500, 5)
end

pageBuilders.visuals = function()
    local p = pageFrame
    section(p, "ESP")
    makeToggle(p, "Player ESP", Cfg.Visuals, "esp", function(v) if not v then clearEspFn() end end)
    makeToggle(p, "Only Visible", Cfg.Visuals, "espVisible")
    makeToggle(p, "Box", Cfg.Visuals, "espBox")
    makeToggle(p, "Names", Cfg.Visuals, "espNames")
    makeToggle(p, "Distance", Cfg.Visuals, "espDist")
    makeToggle(p, "Chams", Cfg.Visuals, "chams")

    section(p, "LIGHTING")
    makeToggle(p, "Fullbright", Cfg.Visuals, "fullbright", function(v)
        if v then
            pcall(function()
                Lighting.Brightness = 3
                Lighting.ClockTime = 12
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
                Lighting.GlobalShadows = false
            end)
        else
            pcall(function()
                Lighting.Brightness = 1
                Lighting.ClockTime = 14
                Lighting.Ambient = Color3.fromRGB(70, 70, 70)
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.GlobalShadows = true
            end)
        end
    end)
    makeToggle(p, "Camera FOV", Cfg.Visuals, "camFov")
    makeSlider(p, "FOV Value", Cfg.Visuals, "camFovValue", 40, 200, 1)
    makeSlider(p, "Fog Distance", Cfg.Visuals, "fogDist", 100, 10000, 50)

    section(p, "CAMERA")
    makeToggle(p, "Third Person", Cfg.Visuals, "thirdPerson", function(v)
        if not v then
            pcall(function()
                LP.CameraMaxZoomDistance = 400
                LP.CameraMinZoomDistance = 0.5
            end)
        end
    end)
    makeSlider(p, "Distance", Cfg.Visuals, "thirdPersonDist", 4, 100, 1)

    section(p, "MISC")
    makeToggle(p, "Crosshair", Cfg.Visuals, "crosshair")
end

pageBuilders.cosmetics = function()
    local p = pageFrame
    section(p, "COSMETICS")
    makeToggle(p, "Enable Cosmetics", Cfg.Cosmetics, "enabled")

    section(p, "WINGS")
    makeToggle(p, "Wings", Cfg.Cosmetics, "wings", function() refreshWings() end)
    makeCycle(p, "Wings Mode", Cfg.Cosmetics, "wingsMode", WingModes, function() refreshWings() end)
    makeSlider(p, "Wings Size", Cfg.Cosmetics, "wingsSize", 0.5, 2, 0.1, function() refreshWings() end)
    makeCycle(p, "Wings Color", Cfg.Cosmetics, "wingsColor", {"Gold","Purple","Cyan","Pink","Green","Orange","Red","White"}, function() refreshWings() end)

    section(p, "HALO")
    makeToggle(p, "Halo", Cfg.Cosmetics, "halo", function() refreshHalo() end)
    makeCycle(p, "Halo Mode", Cfg.Cosmetics, "haloMode", {"Thin", "Thick", "Small"}, function() refreshHalo() end)
    makeCycle(p, "Halo Color", Cfg.Cosmetics, "haloColor", {"Gold","Purple","Cyan","Pink","Green","Orange","Red","White"}, function() refreshHalo() end)

    section(p, "TRAIL")
    makeToggle(p, "Trail", Cfg.Cosmetics, "trail", function() refreshTrail() end)
    makeCycle(p, "Trail Mode", Cfg.Cosmetics, "trailMode", {"Long", "Longer", "Short"}, function() refreshTrail() end)
    makeCycle(p, "Trail Color", Cfg.Cosmetics, "trailColor", {"Gold","Purple","Cyan","Pink","Green","Orange","Red","White"}, function() refreshTrail() end)

    section(p, "AURA")
    makeToggle(p, "Aura", Cfg.Cosmetics, "aura", function() refreshAura() end)
    makeSlider(p, "Density", Cfg.Cosmetics, "auraDensity", 0.2, 3, 0.1, function()
        if cosObjects.aura then cosObjects.aura.Rate = 40 * Cfg.Cosmetics.auraDensity end
    end)
    makeCycle(p, "Aura Color", Cfg.Cosmetics, "auraColor", {"Gold","Purple","Cyan","Pink","Green","Orange","Red","White"}, function() refreshAura() end)

    section(p, "FOOT TRAIL")
    makeToggle(p, "Footstep Trail", Cfg.Cosmetics, "footTrail", function(v)
        if v then attachFootTrail() else detachFootTrail() end
    end)

    section(p, "ITEM ANIMATIONS")
    makeToggle(p, "Item Spin", Cfg.Cosmetics, "itemSpin", function() applyItemAnim() end)
    makeToggle(p, "Item Trail", Cfg.Cosmetics, "itemTrail", function() applyItemAnim() end)
end

pageBuilders.world = function()
    local p = pageFrame
    section(p, "ATMOSPHERE")
    makeToggle(p, "Enable", Cfg.World, "atmosphere", function() applyAtmosphere() end)
    makeCycle(p, "Preset", Cfg.World, "atmospherePreset", AtmosPresets, function() applyAtmosphere() end)
    makeToggle(p, "Colors", Cfg.World, "atmosphereColors", function(v)
        if v then
            makeLabel(pageFrame, "Custom color controls:")
            -- Rebuild to show/hide color sliders
        end
    end)
    if Cfg.World.atmosphereColors then
        makeSlider(p, "Hue", Cfg.World, "atmosphereHue", 0, 1, 0.01, function() applyAtmosphere() end)
        makeSlider(p, "Saturation", Cfg.World, "atmosphereSat", 0, 1, 0.01, function() applyAtmosphere() end)
        makeSlider(p, "Brightness", Cfg.World, "atmosphereBright", 0, 1, 0.01, function() applyAtmosphere() end)
        makeSlider(p, "Contrast", Cfg.World, "atmosphereContrast", 0.1, 3, 0.1, function() applyAtmosphere() end)
    end

    section(p, "OPTIMIZER")
    makeToggle(p, "Enable", Cfg.World, "optimizer", function() applyOptimizer() end)
    makeSlider(p, "FPS Cap", Cfg.World, "optimizerFps", 30, 240, 10, function() applyOptimizer() end)
    makeToggle(p, "Disable Shadows", Cfg.World, "optimizerShadows", function() applyOptimizer() end)
    makeToggle(p, "Disable Textures", Cfg.World, "optimizerTextures", function() applyOptimizer() end)
    makeToggle(p, "Disable Meshes", Cfg.World, "optimizerMeshes", function() applyOptimizer() end)
    makeToggle(p, "Disable Lighting", Cfg.World, "optimizerLighting", function() applyOptimizer() end)
    makeToggle(p, "Disable Particles", Cfg.World, "optimizerParticles", function() applyOptimizer() end)

    section(p, "MAP EXPLOIT")
    makeButton(p, "Hide All Parts", false, function() mapExploit("hideall") end)
    makeButton(p, "Delete All Parts", false, function() mapExploit("deleteall") end)
    makeButton(p, "Null All Parts", false, function() mapExploit("nullparts") end)
    makeButton(p, "Kill All NPCs", false, function() mapExploit("killnpcs") end)
    makeButton(p, "Delete All Lights", false, function() mapExploit("deletelights") end)

    section(p, "MAP NUKER")
    makeButton(p, "Nuke Radius (50)", true, function() mapNuker("radius", 50) end)
    makeButton(p, "Nuke Radius (150)", true, function() mapNuker("radius", 150) end)
    makeButton(p, "Nuke by Types", false, function() mapNuker("types") end)
    makeButton(p, "Nuke Everything", true, function() mapNuker("everything") end)

    section(p, "CODE EXPOSER")
    local exposeLabel = makeLabel(p, "Click 'Dump Game' to print info to console.")
    makeButton(p, "Dump Game", false, function()
        local info = codeExpose()
        print("=== HakoUI Code Expose ===")
        print("PlaceId:", info.place)
        print("JobId:", info.jobId)
        print("PlayerCount:", info.playerCount)
        print("Services:", table.concat(info.services, ", "))
        print("PlayerScripts:", table.concat(info.playerScripts, ", "))
    end)
    makeButton(p, "Execute Lua...", true, function()
        local input = Instance.new("TextBox")
        input.Size = UDim2.fromOffset(400, 120)
        input.Position = UDim2.new(0.5, -200, 0.5, -60)
        input.BackgroundColor3 = Theme.bg
        input.TextColor3 = Theme.text
        input.Font = Enum.Font.Code
        input.TextSize = 11
        input.Text = "-- Lua code here"
        input.MultiLine = true
        input.Parent = gui
        local ok = ri("TextButton", {
            Size = UDim2.fromOffset(200, 40),
            Position = UDim2.new(0.5, -100, 0.5, 70),
            BackgroundColor3 = Theme.accent,
            Text = "Execute",
            Font = Enum.Font.GothamBold,
            TextColor3 = Theme.white,
        }, gui)
        ok.MouseButton1Click:Connect(function()
            local code = input.Text
            input:Destroy()
            ok:Destroy()
            local success, err = execLua(code)
            notify(success and "Executed" or ("Error: " .. tostring(err)), success and Theme.good or Theme.bad)
        end)
    end)
end

pageBuilders.exploits = function()
    local p = pageFrame
    section(p, "FORCEOP")
    makeToggle(p, "Enable", Cfg.Exploits, "forceOp")
    makeCycle(p, "Mode", Cfg.Exploits, "forceOpMode", {"Local", "Broadcast"})
    makeLabel(p, "Chat commands: /op /gamemode 0|1|2|3 /give /clear /effect /enchant /xp /tp name /kill /kick /ban /pardon /whitelist /time /weather /difficulty /gamerule /setworldspawn /spawnpoint /summon /fill /setblock /execute /title /playsound /particle /worldborder /locate /place /damage /attribute /data /bossbar /schedule /function /god /fly /speed /jump /heal /help")
    makeButton(p, "Test /help", false, function() ForceOP.commands.help() end)
    makeButton(p, "Test /gamemode 1", true, function() ForceOP.commands.gamemode("1") end)

    section(p, "ANTI-KICK")
    makeToggle(p, "Anti-Kick", Cfg.Exploits, "antiKick", function(v)
        if v then notify("Anti-Kick active", Theme.good) end
    end)

    section(p, "CRASHER")
    makeButton(p, "Crash Parts", true, function() crash("parts") end)
    makeButton(p, "Crash Particles", true, function() crash("particles") end)
    makeButton(p, "Crash Sounds", true, function() crash("sounds") end)
    makeButton(p, "Crash Loop", true, function() crash("loop") end)
end

pageBuilders.misc = function()
    local p = pageFrame
    section(p, "CONFIGS")
    local cfgName = "default"
    local nameInput = ri("TextBox", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.card2,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = Theme.text,
        PlaceholderText = "Config name",
        Text = "default",
        ZIndex = 24,
    }, p)
    ri("UICorner", {CornerRadius = UDim2.new(0, 10, 0, 10)}, nameInput)
    ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = 0.4}, nameInput)
    nameInput.FocusLost:Connect(function() cfgName = nameInput.Text end)
    makeButton(p, "Save Config", true, function()
        saveConfig(cfgName or nameInput.Text or "default")
    end)
    makeButton(p, "Load Config", false, function()
        loadConfig(cfgName or nameInput.Text or "default")
    end)
    local cfgList = listConfigs()
    if #cfgList > 0 then
        makeLabel(p, "Saved: " .. table.concat(cfgList, ", "))
    else
        makeLabel(p, "No saved configs yet.")
    end

    section(p, "MISC")
    makeToggle(p, "Anti-AFK", Cfg.Misc, "antiAfk")
    makeToggle(p, "Watermark", Cfg.Misc, "watermark")
    makeButton(p, "Respawn", false, function()
        local h = getHum()
        if h and h.Health > 0 then pcall(function() h.Health = 0 end) end
    end)
    makeButton(p, "Copy Position", false, function()
        local hrp = getHRP()
        if hrp then
            pcall(function()
                setclipboard(string.format("%.2f, %.2f, %.2f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
            end)
            notify("Copied", Theme.good)
        end
    end)

    section(p, "DANGER")
    makeButton(p, "Self Destruct", true, function()
        if Unloaded then return end
        Unloaded = true
        pcall(function()
            for k in pairs(cosObjects) do
                if cosObjects[k] then pcall(function() cosObjects[k]:Destroy() end) end
            end
            detachFootTrail()
            local h = getHum()
            if h then pcall(function() h.WalkSpeed = 16; h.JumpPower = 50 end) end
            pcall(function() Workspace.Gravity = 196 end)
            pcall(function() Camera.FieldOfView = 70 end)
            gui:Destroy()
        end)
    end)
end

local function refreshCanvas()
    if not scroller then return end
    local h = 0
    if pageFrame then
        local ok, a = pcall(function() return pageFrame.AbsoluteSize.Y end)
        if ok and a then h = a end
    end
    if pageList then
        local ok, c = pcall(function() return pageList.AbsoluteContentSize.Y end)
        if ok and c and c > h then h = c end
    end
    scroller.CanvasSize = UDim2.new(0, 0, 0, math.ceil(h) + 40)
end

local function showTab(id)
    if not pageFrame then return end
    activeSlider = nil
    for _, c in ipairs(pageFrame:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            pcall(function() c:Destroy() end)
        end
    end
    local builder = pageBuilders[id]
    if builder then pcall(builder) end
    for _, t in ipairs(tabList) do
        local act = t.id == id
        pcall(function()
            t.btn.BackgroundTransparency = act and 0 or 1
            t.btn.TextColor3 = act and Theme.accent or Theme.sub
            t.stroke.Transparency = act and 0.5 or 1
        end)
    end
    task.defer(refreshCanvas)
    task.delay(0.15, refreshCanvas)
end

local function buildWindow()
    if main or not gui.Parent then return end
    local v = viewport()
    local W = math.clamp(math.floor(v.X * 0.92), 280, 400)
    local H = math.clamp(math.floor(v.Y * 0.75), 340, 520)
    if W > v.X - 16 then W = v.X - 16 end
    if H > v.Y - 48 then H = v.Y - 48 end

    main = ri("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(W, H),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.bg,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 20,
    }, gui)
    ri("UICorner", {CornerRadius = UDim2.new(0, 18, 0, 18)}, main)
    local outerStroke = ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = 0.2}, main)
    ri("UIGradient", {
        Color = ColorSequence.new(Theme.accent, Theme.accent2, Theme.accent3),
        Rotation = 45
    }, outerStroke)
    winScale = ri("UIScale", {Scale = 1}, main)

    local header = ri("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        ZIndex = 21,
    }, main)
    local dot = ri("Frame", {
        Size = UDim2.fromOffset(8, 8),
        Position = UDim2.new(0, 16, 0, 21),
        BackgroundColor3 = Theme.accent,
        BorderSizePixel = 0,
        ZIndex = 22,
    }, header)
    ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, dot)
    ri("UIGradient", {Color = ColorSequence.new(Theme.accent, Theme.accent2), Rotation = 90}, dot)
    ri("TextLabel", {
        Size = UDim2.new(1, -110, 0, 18),
        Position = UDim2.new(0, 32, 0, 11),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "HakoUI",
        ZIndex = 22,
    }, header)
    ri("TextLabel", {
        Size = UDim2.new(1, -110, 0, 14),
        Position = UDim2.new(0, 32, 0, 27),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Theme.sub,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "v4.0",
        ZIndex = 22,
    }, header)
    local closeBtn = ri("TextButton", {
        Size = UDim2.fromOffset(38, 38),
        Position = UDim2.new(1, -48, 0, 5),
        BackgroundColor3 = Theme.card,
        BorderSizePixel = 0,
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.sub,
        AutoButtonColor = false,
        ZIndex = 22,
    }, header)
    ri("UICorner", {CornerRadius = UDim2.new(0, 11, 0, 11)}, closeBtn)
    ri("UIStroke", {Color = Theme.stroke, Thickness = 1, Transparency = 0.4}, closeBtn)
    closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)

    local tabBar = ri("ScrollingFrame", {
        Size = UDim2.new(1, -24, 0, 36),
        Position = UDim2.new(0, 12, 0, 54),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.X,
        ZIndex = 21,
    }, main)
    local tabLayout = ri("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim2.new(0, 4, 0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, tabBar)

    scroller = ri("ScrollingFrame", {
        Size = UDim2.new(1, -24, 1, -102),
        Position = UDim2.new(0, 12, 0, 96),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.stroke,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 21,
    }, main)
    pcall(function() scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y end)

    pageFrame = ri("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 22,
    }, scroller)
    pcall(function() pageFrame.AutomaticSize = Enum.AutomaticSize.Y end)
    pageList = ri("UIListLayout", {
        Padding = UDim2.new(0, 7, 0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, pageFrame)
    ri("UIPadding", {
        PaddingTop = UDim2.new(0, 2, 0, 0),
        PaddingBottom = UDim2.new(0, 8, 0, 0)
    }, pageFrame)

    local tabs = {
        {"combat", "Combat"},
        {"movement", "Move"},
        {"visuals", "Visuals"},
        {"cosmetics", "Cosm"},
        {"world", "World"},
        {"exploits", "Exploits"},
        {"misc", "Misc"},
    }
    for _, d in ipairs(tabs) do
        local id, title = d[1], d[2]
        local btn = ri("TextButton", {
            Size = UDim2.fromOffset(78, 30),
            BackgroundColor3 = Theme.card,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Theme.sub,
            AutoButtonColor = false,
            ZIndex = 22,
        }, tabBar)
        ri("UICorner", {CornerRadius = UDim2.new(0, 9, 0, 9)}, btn)
        local stroke = ri("UIStroke", {Color = Theme.accent, Thickness = 1, Transparency = 1}, btn)
        table.insert(tabList, {id = id, btn = btn, stroke = stroke})
        btn.MouseButton1Click:Connect(function() showTab(id) end)
    end

    local wDrag, wMoved = false, false
    local wStartInput, wCenter = Vector2.new(), Vector2.new()
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wDrag = true
            wMoved = false
            wStartInput = input.Position
            local ap, as = main.AbsolutePosition, main.AbsoluteSize
            wCenter = Vector2.new(ap.X + as.X / 2, ap.Y + as.Y / 2)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not wDrag then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - wStartInput
            if d.Magnitude > 8 then wMoved = true end
            if wMoved then
                local vv = viewport()
                main.Position = UDim2.fromOffset(
                    math.clamp(wCenter.X + d.X, 60, vv.X - 60),
                    math.clamp(wCenter.Y + d.Y, 46, vv.Y - 46)
                )
            end
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            wDrag = false
        end
    end)

    showTab("combat")
    task.spawn(function()
        while gui.Parent and not Unloaded do
            refreshCanvas()
            task.wait(0.3)
        end
    end)
end

buildWindow()

-- FOV ring
local fovRing = ri("Frame", {
    Size = UDim2.fromOffset(Cfg.Combat.aimFov * 2, Cfg.Combat.aimFov * 2),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 10,
}, gui)
ri("UICorner", {CornerRadius = UDim2.new(1, 0, 1, 0)}, fovRing)
ri("UIStroke", {Color = Theme.accent, Thickness = 1, Transparency = 0.55}, fovRing)

task.spawn(function()
    while gui.Parent and not Unloaded do
        local show = Cfg.Combat.aim and Cfg.Combat.aimRing
        if fovRing.Visible ~= show then fovRing.Visible = show end
        if show then
            fovRing.Size = UDim2.fromOffset(math.floor(Cfg.Combat.aimFov * 2), math.floor(Cfg.Combat.aimFov * 2))
        end
        task.wait(0.2)
    end
end)

-- Crosshair
local crossGui = ri("Frame", {
    Size = UDim2.fromOffset(22, 22),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 15,
}, gui)
ri("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0.5, -1), BackgroundColor3 = Theme.accent2, BorderSizePixel = 0, ZIndex = 16}, crossGui)
ri("Frame", {Size = UDim2.new(0, 2, 1, 0), Position = UDim2.new(0.5, -1, 0, 0), BackgroundColor3 = Theme.accent2, BorderSizePixel = 0, ZIndex = 16}, crossGui)

-- ESP clear helper
function clearEspFn()
    for _, o in pairs(espObjects) do
        if o.bb then pcall(function() o.bb:Destroy() end) end
        if o.highlight then pcall(function() o.highlight:Destroy() end) end
    end
    espObjects = {}
end

-- ================== MAIN LOOPS ==================
local function getAvatarPing()
    local ok, p = pcall(function() return LP:GetNetworkPing() end)
    if ok and p then return p end
    return 0
end

-- Aim + Silent + AutoPlay
RunService.RenderStepped:Connect(function(dt)
    if Unloaded then return end

    if Cfg.Combat.aim then
        local active = true
        if Cfg.Combat.aimMode == 2 then
            active = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end
        if active then
            gatherTargets()
            local best = bestCandidate()
            if best then
                if not currentTarget or currentTarget.ch ~= best.ch then
                    currentTarget = best
                    lastSwitch = os.clock() * 1000
                    setTargetHL(best.ch)
                end
                local pos = best.part.Position
                if Cfg.Combat.aimPredict > 0 then
                    local ok, vel = pcall(function()
                        if best.part:IsA("BasePart") then return best.part.AssemblyLinearVelocity end
                        return best.part.Velocity
                    end)
                    if ok and vel then pos = pos + vel * (Cfg.Combat.aimPredict / 100) end
                end
                if Cfg.Combat.aimHumanize then
                    pos = pos + Vector3.new((math.random() - 0.5) * 0.4, (math.random() - 0.5) * 0.4, 0)
                end
                local goal = CFrame.new(Camera.CFrame.Position, pos)
                Camera.CFrame = Camera.CFrame:Lerp(goal, math.clamp(dt * Cfg.Combat.aimSpeed * Cfg.Combat.aimSmooth, 0, 1))
            else
                currentTarget = nil
                setTargetHL(nil)
            end
        end
    else
        setTargetHL(nil)
    end

    if Cfg.Combat.autoPlay then
        pcall(autoPlayLoop)
    end
end)

-- Movement physics
RunService.Stepped:Connect(function(dt)
    if Unloaded then return end
    local hum = getHum()
    local hrp = getHRP()
    if not hum or not hrp then return end

    if Cfg.Movement.fly then
        local dir = hum.MoveDirection
        local baseVel = Vector3.new(dir.X * Cfg.Movement.flySpeed, flyV * Cfg.Movement.vertSpeed, dir.Z * Cfg.Movement.flySpeed)
        if Cfg.Movement.flyMode == 1 then
            pcall(function() hrp.AssemblyLinearVelocity = baseVel end)
        elseif Cfg.Movement.flyMode == 2 then
            pcall(function() hrp.CFrame = hrp.CFrame + baseVel * dt end)
        elseif Cfg.Movement.flyMode == 3 then
            pcall(function()
                hrp.AssemblyLinearVelocity = baseVel
                hrp.CanCollide = false
            end)
        else
            pcall(function()
                local v = hrp.AssemblyLinearVelocity
                hrp.AssemblyLinearVelocity = Vector3.new(
                    dir.X * Cfg.Movement.flySpeed,
                    math.clamp(v.Y + flyV * Cfg.Movement.vertSpeed * dt, -Cfg.Movement.flySpeed, Cfg.Movement.flySpeed),
                    dir.Z * Cfg.Movement.flySpeed
                )
            end)
        end
    end

    if Cfg.Movement.speed then
        if Cfg.Movement.speedMethod == 1 then
            if hum.WalkSpeed ~= Cfg.Movement.speedValue then
                pcall(function() hum.WalkSpeed = Cfg.Movement.speedValue end)
            end
        else
            local md = hum.MoveDirection
            if md.Magnitude > 0.05 then
                pcall(function()
                    local v = hrp.AssemblyLinearVelocity
                    hrp.AssemblyLinearVelocity = Vector3.new(md.X * Cfg.Movement.speedValue, v.Y, md.Z * Cfg.Movement.speedValue)
                end)
            end
        end
    end

    if Cfg.Movement.jump then
        pcall(function()
            hum.UseJumpPower = true
            if hum.JumpPower ~= Cfg.Movement.jumpPower then
                hum.JumpPower = Cfg.Movement.jumpPower
            end
        end)
    end

    if Cfg.Movement.bhop and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    if Cfg.Movement.highJump and hum.FloorMaterial == Enum.Material.Air then
        pcall(function()
            if hrp.AssemblyLinearVelocity.Y < 60 then
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 60, hrp.AssemblyLinearVelocity.Z)
            end
        end)
    end

    if Cfg.Movement.longJump and hum.FloorMaterial == Enum.Material.Air and UIS:IsKeyDown(Enum.KeyCode.Space) then
        local look = Camera.CFrame.LookVector
        pcall(function()
            local v = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(look.X * 90, v.Y, look.Z * 90)
        end)
    end

    if Cfg.Movement.noFall and hrp.AssemblyLinearVelocity.Y < -50 then
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -50, hrp.AssemblyLinearVelocity.Z)
        end)
    end

    if Cfg.Movement.water then
        local ray = Ray.new(hrp.Position, Vector3.new(0, -6, 0))
        local hit, hitPos = Workspace:FindPartOnRay(ray, getChar())
        if hit and hit.Material == Enum.Material.Water then
            pcall(function() hrp.CFrame = CFrame.new(hitPos + Vector3.new(0, 3, 0)) end)
        end
    end

    if Cfg.Movement.antiFling then
        local v = hrp.AssemblyLinearVelocity
        if v.Magnitude > 500 then
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y, 0) end)
        end
    end

    if Cfg.Movement.gravity then
        pcall(function()
            if Workspace.Gravity ~= Cfg.Movement.gravityValue then
                Workspace.Gravity = Cfg.Movement.gravityValue
            end
        end)
    end

    if Cfg.Movement.noclip then
        local ch = getChar()
        if ch then
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    pcall(function() p.CanCollide = false end)
                end
            end
        end
    end

    if ForceOP.god then
        pcall(function() hum.Health = hum.MaxHealth end)
    end
end)

-- Jump request for Inf Jump + gamemode 1 jump fix
UIS.JumpRequest:Connect(function()
    if Unloaded then return end
    local hum = getHum()
    if not hum then return end
    -- gamemode 1 fix: if fly is on and grounded, boost upward
    if Cfg.Movement.fly and hum.FloorMaterial ~= Enum.Material.Air then
        local hrp = getHRP()
        if hrp then
            pcall(function()
                hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, 80, 0)
            end)
        end
    end
    if Cfg.Movement.infJump then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

-- Shoot + Trigger loop
local lastShot, lastTrigger = 0, 0
RunService.Heartbeat:Connect(function()
    if Unloaded then return end

    if Cfg.Combat.trigger then
        local now = os.clock() * 1000
        if now - lastTrigger >= Cfg.Combat.triggerDelay then
            local v = viewport()
            local cx, cy = v.X / 2, v.Y / 2
            local found = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP then
                    local ch = p.Character
                    local head = ch and ch:FindFirstChild("Head")
                    if head then
                        local sp, on = Camera:WorldToViewportPoint(head.Position)
                        if on and sp.Z > 0 then
                            local d = math.sqrt((sp.X - cx) ^ 2 + (sp.Y - cy) ^ 2)
                            if d <= Cfg.Combat.triggerRange and isVisibleMulti(head.Position, ch) then
                                found = true
                                break
                            end
                        end
                    end
                end
            end
            if found then
                lastTrigger = now
                autoFire()
            end
        end
    end

    if not Cfg.Combat.shoot then return end
    local hum = getHum()
    if not hum or hum.Health <= 0 then return end
    if Cfg.Combat.shootOnlyTarget then
        gatherTargets()
        if #candidateList == 0 then return end
    end
    local now = os.clock()
    if Cfg.Combat.shootDelay > 0 and (now - lastShot) * 1000 < Cfg.Combat.shootDelay then return end
    lastShot = now
    autoFire()
end)

-- ESP loop
RunService.Heartbeat:Connect(function()
    if Unloaded then return end
    if not Cfg.Visuals.esp then
        if next(espObjects) then clearEspFn() end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch = p.Character
            if ch and ch.Parent then
                local head = ch:FindFirstChild("Head")
                local visible = true
                if Cfg.Visuals.espVisible and head then
                    visible = isVisibleMulti(head.Position, ch)
                end
                local obj = espObjects[p] or {}
                espObjects[p] = obj
                if Cfg.Visuals.espBox then
                    if not obj.bb then
                        obj.bb = Instance.new("BillboardGui")
                        obj.bb.Name = "HakoBox"
                        obj.bb.Size = UDim2.new(0, 60, 0, 60)
                        obj.bb.StudsOffset = Vector3.new(0, 3, 0)
                        obj.bb.AlwaysOnTop = true
                        local f = Instance.new("Frame")
                        f.Size = UDim2.new(1, 0, 1, 0)
                        f.BackgroundTransparency = 1
                        f.Parent = obj.bb
                        local st = Instance.new("UIStroke")
                        st.Color = Theme.accent
                        st.Thickness = 1.5
                        st.Transparency = 0.2
                        st.Parent = f
                        obj.bb.Parent = ch
                    end
                    obj.bb.Adornee = ch
                    obj.bb.Enabled = visible
                end
                if Cfg.Visuals.espNames then
                    if not obj.nameLabel then
                        local bb = obj.bb or Instance.new("BillboardGui")
                        if not obj.bb then
                            bb.Size = UDim2.new(0, 100, 0, 20)
                            bb.StudsOffset = Vector3.new(0, 4, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = ch
                            obj.bb = bb
                        end
                        local nl = Instance.new("TextLabel")
                        nl.Size = UDim2.new(1, 0, 0, 14)
                        nl.Position = UDim2.new(0, 0, 1, 2)
                        nl.BackgroundTransparency = 1
                        nl.TextColor3 = Theme.white
                        nl.TextStrokeTransparency = 0.3
                        nl.Font = Enum.Font.GothamBold
                        nl.TextSize = 11
                        nl.Text = p.Name
                        nl.Parent = bb
                        obj.nameLabel = nl
                    end
                    local dist = head and math.floor((head.Position - Camera.CFrame.Position).Magnitude) or 0
                    obj.nameLabel.Text = Cfg.Visuals.espDist and (p.Name .. " [" .. dist .. "m]") or p.Name
                end
                if obj.bb and head then
                    local dist = (head.Position - Camera.CFrame.Position).Magnitude
                    local sz = math.clamp(2000 / dist, 20, 90)
                    obj.bb.Size = UDim2.new(0, sz, 0, sz)
                end
                if Cfg.Visuals.chams then
                    if not obj.highlight then
                        local ok, h = pcall(function()
                            local x = Instance.new("Highlight")
                            x.FillColor = Theme.accent
                            x.OutlineColor = Theme.accent2
                            x.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            x.Parent = ch
                            return x
                        end)
                        if ok then obj.highlight = h end
                    end
                    if obj.highlight then
                        obj.highlight.Adornee = ch
                        obj.highlight.Enabled = visible
                    end
                elseif obj.highlight then
                    pcall(function() obj.highlight:Destroy() end)
                    obj.highlight = nil
                end
            end
        end
    end

    if Cfg.Visuals.camFov then
        if Camera.FieldOfView ~= Cfg.Visuals.camFovValue then
            Camera.FieldOfView = Cfg.Visuals.camFovValue
        end
    end
    if Cfg.Visuals.thirdPerson then
        pcall(function()
            LP.CameraMaxZoomDistance = Cfg.Visuals.thirdPersonDist
            LP.CameraMinZoomDistance = Cfg.Visuals.thirdPersonDist
        end)
    end
    if Lighting.FogEnd ~= Cfg.Visuals.fogDist then
        Lighting.FogEnd = Cfg.Visuals.fogDist
    end
    crossGui.Visible = Cfg.Visuals.crosshair

    if Cfg.Cosmetics.itemSpin or Cfg.Cosmetics.itemTrail then
        applyItemAnim()
    end
    if Cfg.Cosmetics.footTrail then
        attachFootTrail()
    else
        detachFootTrail()
    end
end)

-- Anti-AFK
LP.Idled:Connect(function()
    if Unloaded or not Cfg.Misc.antiAfk then return end
    pcall(function()
        local v = game:GetService("VirtualUser")
        v:CaptureController()
        v:ClickButton2(Vector2.new())
    end)
end)

-- ForceOP chat + Enter
LP.Chatted:Connect(function(msg)
    if Unloaded or not Cfg.Exploits.forceOp then return end
    if msg:sub(1, 1) ~= "/" then return end
    pcall(execForceOp, msg)
end)

UIS.InputBegan:Connect(function(input)
    if Unloaded then return end
    if input.KeyCode == Enum.KeyCode.Return then
        local box = UIS:GetFocusedTextBox()
        if box and Cfg.Exploits.forceOp then
            local text = box.Text
            if text:sub(1, 1) == "/" then
                local cmd = text:sub(2):match("^%S+")
                if cmd and ForceOP.commands[cmd:lower()] then
                    box.Text = ""
                    pcall(execForceOp, text)
                end
            end
        end
    end
end)

-- Character respawn cosmetics restore
LP.CharacterAdded:Connect(function()
    flyV = 0
    task.wait(0.5)
    if Cfg.Movement.noclip then
        local ch = getChar()
        if ch then
            for _, p in ipairs(ch:GetDescendants()) do
                if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
            end
        end
    end
    if Cfg.Cosmetics.wings then refreshWings() end
    if Cfg.Cosmetics.halo then refreshHalo() end
    if Cfg.Cosmetics.trail then refreshTrail() end
    if Cfg.Cosmetics.aura then refreshAura() end
end)

-- UI input handlers
UIS.InputChanged:Connect(function(input)
    if activeSlider and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        pcall(activeSlider, input.Position.X)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        activeSlider = nil
        flyV = 0
    end
end)

UIS.InputBegan:Connect(function(input)
    if pickMode then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local btn = findButtonAtPoint(input.Position)
            if btn then
                setShootBtn(btn)
                pickMode = false
                if pickToast then pickToast.Visible = false end
            end
        end
        return
    end
    if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
        if not UIS:GetFocusedTextBox() then
            setOpen(not open)
        end
    end
end)

-- Show window on load
if main then
    main.Visible = true
    updateShootStatus()
    setOpen(true)
    main.Visible = true
    task.wait(0.2)
    notify("HakoUI v4.0 loaded", Theme.good)
    print("[HakoUI] v4.0 loaded successfully")
else
    warn("[HakoUI] Window build failed")
end
