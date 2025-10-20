--[[
  Remote Announcer + Blue Flash + Killfeed-based Killstreak (LocalScript)
  - Tracks your killstreak until death
  - Plays sounds from FragMap (3+), SpecialMap.DoubleKill (2), and fallback for 1 (deterministic, no random)
  - If MAX mapped audio is reached: play it once, then reset streak to 0
  - BlueFlash: uses a new ScreenGui each call (supports multiple kills per frame)
  - DEBUG: Press X to spoof a kill
  - OPTIONAL (toggled at top):
      * AimLock (press E to toggle) — locks to enemy closest to mouse, binds to death, instantly re-acquires
      * Highlights for all other players with team-colored outlines
  - NEW: Plays Rust hitsound on every kill (in addition to announcer)
  - FIXED: De-dupes Killfeed events and suppresses immediate repeat of same VO key
]]

-- =======================
-- CONFIG
-- =======================
local CONFIG = {
    debug = false, -- enable debug hotkey
    debugKey = Enum.KeyCode.X, -- key to spoof a kill

    enableFlashOnSounds = true, -- per-sound auto-flash (suppressed for streak sounds)
    flashFadeInTime = 0.10,
    flashHoldTime = 0.20,
    flashFadeOutTime = 0.35,
    flashPeakVisibility = 0.35, -- 0.20 = 20% visible blue (Transparency = 0.8)

    configUrl = 'https://raw.githubusercontent.com/localscripts/Audio/main/announcer_config.lua',
    cacheDir = 'QuakeSounds',
    cachePath = 'QuakeSounds/announcer_config.lua',

    -- ===== HitSound on kill =====
    hitsound = {
        enabled = true,
        url = 'https://github.com/localscripts/Audio/raw/refs/heads/main/Hitsound/Rust.wav',
        cacheName = 'hitsound_rust.wav', -- local filename
        volume = 0.9,   -- 0..1+ (Roblox allows >1 but can distort)
        pitch  = 1.0,   -- PlaybackSpeed (1 = normal)
    },

    -- ===== AimLock =====
    aim = {
        enabled = true, -- toggle AimLock system
        aimToggleKey = Enum.KeyCode.E, -- press to toggle aiming on/off
    },

    -- ===== Highlights =====
    highlight = {
        enabled = true, -- toggle highlighting of other players
        fillColor = Color3.fromRGB(0, 0, 0), -- black inside
        fillTransparency = 0.5,
        outlineTransparency = 0,
        depthAlwaysOnTop = true, -- true = visible through walls; false = occluded by walls

        defaultOutlineIfNoTeam = Color3.fromRGB(255, 255, 255), -- fallback color when no team

        useTeamOverrides = true, -- enable manual team color overrides
        teamOutlineOverrides = {
            -- ["Red"]  = Color3.fromRGB(255, 70, 70),
            -- ["Blue"] = Color3.fromRGB(70, 70, 255),
        },

        playerOutlineAttribute = 'OutlineOverride', -- optional per-player Color3 attribute to override outline
    },
}

-- ==============================
-- Remote module loader
-- ==============================
if not isfolder(CONFIG.cacheDir) then
    makefolder(CONFIG.cacheDir)
end

local function fetchRemoteModule(url, cachePath)
    local ok, res = pcall(function()
        return request({ Url = url, Method = 'GET' })
    end)
    if ok and res and res.StatusCode == 200 and res.Body then
        writefile(cachePath, res.Body)
        return res.Body
    end
    if isfile(cachePath) then
        return readfile(cachePath)
    end
    return nil
end

local src = fetchRemoteModule(CONFIG.configUrl, CONFIG.cachePath)
assert(src, '[Announcer] Failed to load remote module and no cache exists')

local ok, cfg = pcall(function()
    return loadstring(src)()
end)
assert(
    ok and type(cfg) == 'table',
    '[Announcer] Remote module did not return a table'
)

local baseUrl = cfg.baseUrl
local folder = cfg.folder
local Sounds = cfg.Sounds
local FragMap = cfg.FragMap
local SpecialMap = cfg.SpecialMap

if folder and type(folder) == 'string' and folder ~= '' then
    if not isfolder(folder) then
        makefolder(folder)
    end
end

-- ======================
-- Services
-- ======================
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local LocalPlayer = Players.LocalPlayer

-- ======================
-- Blue screen flash UI (new instance per call)
-- ======================
local function BlueFlash()
    local playerGui = LocalPlayer:WaitForChild('PlayerGui')

    -- brand-new GUI each time, force topmost layer
    local gui = Instance.new('ScreenGui')
    gui.Name = ('BlueFlashGui_%d'):format(math.floor(os.clock() * 1000))
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999
    gui.Enabled = true
    gui.Parent = playerGui

    -- full-screen overlay
    local frame = Instance.new('Frame')
    frame.Name = 'BlueOverlay'
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromScale(1, 1)
    frame.ZIndex = 999999
    frame.Parent = gui

    frame.BackgroundTransparency = 1
    local peakT = 1 - CONFIG.flashPeakVisibility

    local fadeIn = TweenService:Create(
        frame,
        TweenInfo.new(
            CONFIG.flashFadeInTime,
            Enum.EasingStyle.Cubic,
            Enum.EasingDirection.Out
        ),
        { BackgroundTransparency = peakT }
    )
    local fadeOut = TweenService:Create(
        frame,
        TweenInfo.new(
            CONFIG.flashFadeOutTime,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out
        ),
        { BackgroundTransparency = 1 }
    )

    fadeIn:Play()
    fadeIn.Completed:Wait()
    task.wait(CONFIG.flashHoldTime)
    fadeOut:Play()
    fadeOut.Completed:Wait()
    gui:Destroy()
end

-- ======================
-- Audio helpers
-- ======================
local function downloadIfNeeded(name)
    local filename = Sounds[name]
    if not filename then
        warn(("[Announcer] Unknown sound '%s'"):format(tostring(name)))
        return nil
    end
    local path = ('%s/%s'):format(folder, filename)
    if not isfile(path) then
        local url = baseUrl .. filename
        local resOk, res = pcall(function()
            return request({ Url = url, Method = 'GET' })
        end)
        if
            not resOk
            or not res
            or (res.StatusCode ~= 200 and res.Success == false)
            or not res.Body
        then
            warn(('[Announcer] Download failed: %s'):format(url))
            return nil
        end
        writefile(path, res.Body)
    end
    return path
end

function PlayAnnouncerSound(name, opts)
    opts = opts or {}
    local path = downloadIfNeeded(name)
    if not path then
        return
    end

    local s = Instance.new('Sound')
    s.SoundId = getcustomasset(path)
    s.Volume = 1
    s.Parent = workspace
    s:Play()

    if CONFIG.enableFlashOnSounds and not opts.noFlash then
        task.spawn(BlueFlash)
    end

    s.Ended:Connect(function()
        s:Destroy()
    end)
end

-- ===== Hitsound helpers (Rust.wav on every kill) =====
-- Cache an arbitrary URL to disk (re-uses remote 'folder' if set, else CONFIG.cacheDir)
local function cacheExternal(url, filename)
    local targetDir = (folder and type(folder) == 'string' and folder ~= '') and folder or CONFIG.cacheDir
    if not isfolder(targetDir) then
        makefolder(targetDir)
    end
    local path = ('%s/%s'):format(targetDir, filename)
    if not isfile(path) then
        local ok2, res2 = pcall(function()
            return request({ Url = url, Method = 'GET' })
        end)
        if not ok2 or not res2 or res2.StatusCode ~= 200 or not res2.Body then
            warn(('[Announcer] HitSound download failed: %s'):format(tostring(url)))
            return nil
        end
        writefile(path, res2.Body)
    end
    return path
end

local function PlayHitSound()
    local hs = CONFIG.hitsound
    if not (hs and hs.enabled) then return end
    local p = cacheExternal(hs.url, hs.cacheName or 'hitsound.wav')
    if not p then return end

    local s = Instance.new('Sound')
    s.SoundId = getcustomasset(p)
    s.Volume = hs.volume or 1
    s.PlaybackSpeed = hs.pitch or 1
    s.Parent = workspace
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- ======================
-- Fallback helpers (key existence)
-- ======================
local function keyExists(name)
    return name and Sounds[name] ~= nil
end

-- ======================
-- Killstreak tracking + deterministic mapper
-- ======================
local killStreak = 0
local Killfeed = ReplicatedStorage:WaitForChild('Killfeed')

-- De-duplication for killfeed messages (ignore the same text for ~0.7s)
local _recentKillfeed = {}
local function _isDuplicateKillfeed(msg)
    local now = os.clock()
    -- purge old
    for i = #_recentKillfeed, 1, -1 do
        if now - _recentKillfeed[i].t > 0.7 then
            table.remove(_recentKillfeed, i)
        end
    end
    -- seen?
    for _, it in ipairs(_recentKillfeed) do
        if it.msg == msg then
            return true
        end
    end
    table.insert(_recentKillfeed, { msg = msg, t = now })
    return false
end

-- Prevent immediate repeats of the same announcer key
local _lastPlayedKey = nil
local _lastPlayedAt = 0
local function PlayStreakKeyOnce(key)
    if not key then return end
    local now = os.clock()
    -- If same key repeats within 0.3s, suppress it
    if _lastPlayedKey == key and (now - _lastPlayedAt) < 0.3 then
        return
    end
    _lastPlayedKey, _lastPlayedAt = key, now
    PlayAnnouncerSound(key, { noFlash = true })
end

-- Compute MAX_FRAG (highest valid FragMap key)
local MAX_FRAG = 0
for s, k in pairs(FragMap) do
    if typeof(s) == 'number' and keyExists(k) and s > MAX_FRAG then
        MAX_FRAG = s
    end
end

-- Deterministic mapping only (no randomness):
--  1 -> first available single-kill line from a fixed list (optional)
--  2 -> first valid from SpecialMap.DoubleKill (if any), else FragMap[2], else nil
--  3+ -> exact FragMap[streak], else nil
local function resolveStreakKey(streak)
    if streak <= 0 then return nil end

    if streak == 1 then
        local firsts = { 'excellent', 'impressive', 'ownage', 'bullseye', 'eagleeye' }
        for _, k in ipairs(firsts) do
            if keyExists(k) then return k end
        end
        return nil
    end

    if streak == 2 then
        if SpecialMap and SpecialMap.DoubleKill then
            for _, k in ipairs(SpecialMap.DoubleKill) do
                if keyExists(k) then return k end
            end
        end
        if FragMap and keyExists(FragMap[2]) then
            return FragMap[2]
        end
        return nil
    end

    local k = FragMap and FragMap[streak]
    if keyExists(k) then
        return k
    end
    return nil
end

local function resetStreak(reason)
    killStreak = 0
    _lastPlayedKey, _lastPlayedAt = nil, 0
    if CONFIG.debug then
        -- print("[Streak reset]", reason)
    end
end

local function hookCharacter(char)
    local hum = char:FindFirstChildOfClass('Humanoid')
    if hum then
        hum.Died:Connect(function()
            resetStreak('died')
        end)
    end
end

if LocalPlayer.Character then
    hookCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

local function handleLocalKill(src)
    killStreak += 1

    -- Play hitsound for every kill (independent of announcer/flash)
    PlayHitSound()

    -- If we reached/exceeded the max mapped frag level, play that once, flash, then reset
    if MAX_FRAG > 0 and killStreak >= MAX_FRAG then
        local maxKey = resolveStreakKey(MAX_FRAG)
        if maxKey then
            PlayStreakKeyOnce(maxKey)
        end
        task.spawn(BlueFlash)
        resetStreak('max_reached')
        return
    end

    local key = resolveStreakKey(killStreak)
    if key then
        PlayStreakKeyOnce(key) -- suppresses immediate duplicate VO (e.g., double “triple kill”)
    end
    task.spawn(BlueFlash)

    if CONFIG.debug then
        -- print(("KillStreak %d (%s)"):format(killStreak, tostring(src)))
    end
end

local function isLocalPlayerKiller(feedText)
    if not feedText or feedText == '' then
        return false
    end
    local lower = string.lower(feedText)
    local killerPart = lower:match('^(.-)%s+killed%s+')
    if not killerPart then
        return false
    end
    local uname = string.lower(LocalPlayer.Name)
    local dname = string.lower(LocalPlayer.DisplayName or LocalPlayer.Name)
    return killerPart:find('(@' .. uname .. ')', 1, true)
        or killerPart:find(uname, 1, true)
        or killerPart:find(dname, 1, true)
end

local function isLocalPlayerVictim(feedText)
    if not feedText or feedText == '' then
        return false
    end
    local lower = string.lower(feedText)
    local victimPart = lower:match('%s+killed%s+(.-)$')
    if not victimPart then
        return false
    end
    local uname = string.lower(LocalPlayer.Name)
    local dname = string.lower(LocalPlayer.DisplayName or LocalPlayer.Name)
    return victimPart:find('(@' .. uname .. ')', 1, true)
        or victimPart:find(uname, 1, true)
        or victimPart:find(dname, 1, true)
end

Killfeed.ChildAdded:Connect(function(child)
    local msg = ''
    if child:IsA('StringValue') then
        msg = child.Value or ''
    else
        msg = child.Name or ''
    end

    -- Ignore duplicate killfeed entries within a short window
    if _isDuplicateKillfeed(msg) then
        return
    end

    if isLocalPlayerVictim(msg) then
        resetStreak('killed')
        return
    end
    if isLocalPlayerKiller(msg) then
        handleLocalKill('killfeed')
    end
end)

-- ======================
-- DEBUG: Spoof kill
-- ======================
if CONFIG.debug then
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if input.KeyCode == CONFIG.debugKey then
            handleLocalKill('debug')
        end
    end)
end

-- ======================
-- OPTIONAL: AimLock (toggle via CONFIG.aim) — closest-to-mouse, binds death, instant swap
-- ======================
if CONFIG.aim.enabled then
    local aiming = false
    local lockedTarget = nil
    local targetConns = {} -- RBXScriptConnections tied to current target

    -- settings you can tweak
    local REACQUIRE_ON_INVALID = true     -- if true, re-acquire when current target becomes invalid
    local MAX_SCREEN_DIST = math.huge     -- set to a pixel value if you want a cap (e.g., 250)
    local SMOOTH_ALPHA = 0.35             -- 0..1 each frame (higher = snappier)

    local function disconnectTargetConns()
        for _, c in ipairs(targetConns) do
            if c then pcall(function() c:Disconnect() end) end
        end
        table.clear(targetConns)
    end

    local function clearLock()
        disconnectTargetConns()
        lockedTarget = nil
    end

    local function isEnemy(p)
        if p == LocalPlayer then return false end
        local myTeam = LocalPlayer.Team
        if myTeam and p.Team and p.Team == myTeam then
            return false
        end
        return true
    end

    local function getAimPart(char)
        if not char then return nil end
        return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    end

    local function isAlive(char)
        if not char then return false end
        local h = char:FindFirstChildOfClass("Humanoid")
        return h and h.Health > 0
    end

    local function isValidTarget(p)
        return p
            and p.Character
            and isEnemy(p)
            and isAlive(p.Character)
            and getAimPart(p.Character) ~= nil
    end

    local function bindTargetSignals(p)
        disconnectTargetConns()
        if not p then return end

        local function invalidate()
            -- instantly drop lock; next frame we’ll grab the nearest
            clearLock()
        end

        -- team change (became ally)
        table.insert(targetConns, p:GetPropertyChangedSignal("Team"):Connect(function()
            if not isEnemy(p) then invalidate() end
        end))

        -- character swaps/despawns
        table.insert(targetConns, p.CharacterAdded:Connect(function()
            task.defer(function()
                local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if h then
                    table.insert(targetConns, h.Died:Connect(invalidate))
                    table.insert(targetConns, h.HealthChanged:Connect(function(hp)
                        if hp <= 0 then invalidate() end
                    end))
                end
            end)
        end))
        table.insert(targetConns, p.CharacterRemoving:Connect(invalidate))

        -- current humanoid death
        local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then
            table.insert(targetConns, h.Died:Connect(invalidate))
            table.insert(targetConns, h.HealthChanged:Connect(function(hp)
                if hp <= 0 then invalidate() end
            end))
        end
    end

    local function acquireClosestToMouse()
        local cam = workspace.CurrentCamera
        local mousePos = UserInputService:GetMouseLocation()
        local bestDist, best = math.huge, nil

        for _, plr in ipairs(Players:GetPlayers()) do
            if isEnemy(plr) and plr.Character then
                local part = getAimPart(plr.Character)
                if part and isAlive(plr.Character) then
                    local v3, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local d = (Vector2.new(v3.X, v3.Y) - mousePos).Magnitude
                        if d < bestDist and d <= MAX_SCREEN_DIST then
                            bestDist, best = d, plr
                        end
                    end
                end
            end
        end

        return best
    end

    local function lookAtTarget(p)
        local char = p.Character
        if not char then return end
        local part = getAimPart(char)
        if not part then return end

        local cam = workspace.CurrentCamera
        local camPos = cam.CFrame.Position
        local targetPos = part.Position

        -- smooth camera rotate towards target
        local desired = CFrame.new(camPos, targetPos)
        cam.CFrame = cam.CFrame:Lerp(desired, SMOOTH_ALPHA)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == CONFIG.aim.aimToggleKey then
            aiming = not aiming
            if aiming then
                lockedTarget = acquireClosestToMouse()
                bindTargetSignals(lockedTarget) -- listen for death/changes
            else
                clearLock()
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not aiming then return end

        if not isValidTarget(lockedTarget) then
            if REACQUIRE_ON_INVALID then
                lockedTarget = acquireClosestToMouse()
                bindTargetSignals(lockedTarget)
            else
                return
            end
        end

        if lockedTarget then
            lookAtTarget(lockedTarget)
        end
    end)
end

-- ======================
-- OPTIONAL: Highlights of other players (toggle via CONFIG.highlight)
-- ======================
if CONFIG.highlight.enabled then
    local function getOrCreateHighlight(character)
        local highlight = character:FindFirstChildOfClass('Highlight')
        if not highlight then
            highlight = Instance.new('Highlight')
            highlight.Archivable = true
            highlight.DepthMode = CONFIG.highlight.depthAlwaysOnTop
                    and Enum.HighlightDepthMode.AlwaysOnTop
                or Enum.HighlightDepthMode.Occluded
            highlight.Enabled = true
            highlight.Parent = character
        else
            -- ensure desired depth mode if already exists
            highlight.DepthMode = CONFIG.highlight.depthAlwaysOnTop
                    and Enum.HighlightDepthMode.AlwaysOnTop
                or Enum.HighlightDepthMode.Occluded
        end
        return highlight
    end

    local function resolveOutlineColor(player)
        -- 1) Per-player Color3 attribute override
        local attrName = CONFIG.highlight.playerOutlineAttribute
        if attrName and player:GetAttribute(attrName) ~= nil then
            local v = player:GetAttribute(attrName)
            if typeof(v) == 'Color3' then
                return v
            end
        end

        -- 2) Manual per-team overrides
        if CONFIG.highlight.useTeamOverrides and player.Team then
            local override =
                CONFIG.highlight.teamOutlineOverrides[player.Team.Name]
            if override then
                return override
            end
        end

        -- 3) Auto from team color
        if player.Team and player.Team.TeamColor then
            return player.Team.TeamColor.Color
        end

        -- 4) Default fallback
        return CONFIG.highlight.defaultOutlineIfNoTeam
    end

    local function styleHighlightForPlayer(highlight, player)
        highlight.FillColor = CONFIG.highlight.fillColor
        highlight.FillTransparency = CONFIG.highlight.fillTransparency
        highlight.OutlineTransparency = CONFIG.highlight.outlineTransparency
        highlight.OutlineColor = resolveOutlineColor(player)
    end

    local function applyHighlight(player)
        if player == LocalPlayer then
            return
        end

        local function onCharacterAdded(character)
            local highlight = getOrCreateHighlight(character)
            styleHighlightForPlayer(highlight, player)

            -- Update if player changes team
            player:GetPropertyChangedSignal('Team'):Connect(function()
                if highlight and highlight.Parent then
                    highlight.OutlineColor = resolveOutlineColor(player)
                end
            end)

            -- Update if player attribute changes
            local attrName = CONFIG.highlight.playerOutlineAttribute
            if attrName then
                player:GetAttributeChangedSignal(attrName):Connect(function()
                    if highlight and highlight.Parent then
                        highlight.OutlineColor = resolveOutlineColor(player)
                    end
                end)
            end
        end

        if player.Character then
            onCharacterAdded(player.Character)
        end
        player.CharacterAdded:Connect(onCharacterAdded)
    end

    for _, p in ipairs(Players:GetPlayers()) do
        applyHighlight(p)
    end
    Players.PlayerAdded:Connect(applyHighlight)
end
