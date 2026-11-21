-- EzMark: watch for one NPC by name. When it's around, alert, and let one key (or the skull
-- button) target and mark it.
--
-- Targeting needs your own key press or click, so the addon never targets by itself. Marking
-- is no better: in Forever SetRaidTarget from addon code is ADDON_ACTION_FORBIDDEN, from the
-- watcher's events and even from the button's PostClick (2026-11-21). So the secure button's
-- macro does both (see WatchMacro); the watcher only spots and alerts.
local _, ns = ...

local Print, IsSecret, IconText = ns.Print, ns.IsSecret, ns.IconText

local db
local watchKey      -- lowercase watched name, nil when not watching
local lastSeen = 0  -- GetTime() of the last sighting
local lastMiss = 0
local glowing
local pending       -- secure changes waiting for combat to end
local ticker
local events = CreateFrame("Frame")

local BINDING = "CLICK EzMarkWatchButton:LeftButton"
BINDING_HEADER_EZMARK = "EzMark"
_G["BINDING_NAME_" .. BINDING] = "Target and mark the watched NPC"

local function KeyText()
    local key = GetBindingKey(BINDING)
    return key and GetBindingText(key)
end

---------------------------------------------------------------------------
-- The button
---------------------------------------------------------------------------
-- Bindings click on press and on release; the macro runs on the release (useOnKeyDown off).
local button = CreateFrame("Button", "EzMarkWatchButton", UIParent, "SecureActionButtonTemplate")
button:SetSize(ns.WATCH_SIZE, ns.WATCH_SIZE)
button:SetFrameStrata("MEDIUM")
button:RegisterForClicks("AnyUp", "AnyDown")
button:SetAttribute("useOnKeyDown", false)
button:SetAttribute("type", "macro")
button:SetAttribute("type2", "macro") -- right-click targets nothing: it means "stop watching"
button:SetAttribute("macrotext2", "/stopmacro")
button:SetMovable(true)
button:SetClampedToScreen(true)
button:RegisterForDrag("LeftButton")
button:Hide()

local glow = button:CreateTexture(nil, "BACKGROUND", nil, -8)
glow:SetPoint("TOPLEFT", -4, 4)
glow:SetPoint("BOTTOMRIGHT", 4, -4)
glow:SetColorTexture(1, 0.82, 0, 0.9)
glow:Hide()

local pulse = glow:CreateAnimationGroup()
pulse:SetLooping("BOUNCE")
local fade = pulse:CreateAnimation("Alpha")
fade:SetFromAlpha(1)
fade:SetToAlpha(0.25)
fade:SetDuration(0.5)

local bg = button:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.7)

local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetPoint("TOPLEFT", 4, -4)
icon:SetPoint("BOTTOMRIGHT", -4, 4)

local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
label:SetPoint("TOP", button, "BOTTOM", 0, -2)

local function SetGlow(on)
    if on == glowing then return end
    glowing = on
    glow:SetShown(on)
    if on then pulse:Play() else pulse:Stop() end
end

local function UpdateLook()
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. db.watchIcon)
    label:SetText(db.watch or "")
end

local function Place()
    button:ClearAllPoints()
    local pos = db.watchPos
    if pos then
        button:SetPoint("CENTER", UIParent, "CENTER", pos[1], pos[2])
    else
        button:SetPoint("TOP", UIParent, "TOP", 0, -160)
    end
end

-- Clear the target first so that, if the NPC isn't in view, /tm finds nothing to mark instead
-- of marking whatever you had; then go back to that target. "/tm !N" never toggles the marker
-- off (Blizzard's SlashCommands.lua), so spamming the key keeps it on.
function ns.WatchMacro(name, marker)
    return table.concat({
        "/cleartarget",
        "/targetexact " .. name,
        "/tm [exists] !" .. marker,
        "/targetlasttarget [noexists]",
    }, "\n")
end

-- Attributes and Show/Hide are locked in combat; they wait for it to end.
local function ApplySecure()
    if InCombatLockdown() then
        pending = true
        return
    end
    pending = nil
    if db.watch then
        button:SetAttribute("macrotext", ns.WatchMacro(db.watch, db.watchIcon))
        button:Show()
    else
        button:SetAttribute("macrotext", nil)
        button:Hide()
    end
end

button:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end
end)

button:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    local cx, cy = UIParent:GetCenter()
    db.watchPos = { x - cx, y - cy }
    if not InCombatLockdown() then Place() end
end)

button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("EzMark: " .. (db.watch or "nothing"))
    GameTooltip:AddLine("Click to target it and mark it " .. IconText(db.watchIcon) .. ".", 1, 1, 1, true)
    local key = KeyText()
    GameTooltip:AddLine(key and ("Key: " .. key) or "Set a key under Key Bindings > AddOns > EzMark.", 0.8, 0.8, 0.8, true)
    GameTooltip:AddLine("Right-click to stop watching. Shift-drag to move.", 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function() GameTooltip:Hide() end)

---------------------------------------------------------------------------
-- Spotting and marking
---------------------------------------------------------------------------
local function Matches(unit)
    if not watchKey or not UnitExists(unit) then return false end
    local isPlayer = UnitIsPlayer(unit)
    if IsSecret(isPlayer) or isPlayer then return false end
    local name = UnitName(unit)
    if not name or IsSecret(name) then return false end
    return strlower(name) == watchKey
end

local FIXED_UNITS = { "target", "mouseover", "focus" }

-- Calls fn(unit) for every unit token the addon can see right now.
local function EachUnit(fn)
    for unit in pairs(ns.plates) do fn(unit) end
    for _, unit in ipairs(FIXED_UNITS) do fn(unit) end
    if IsInGroup() then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, GetNumGroupMembers() do fn(prefix .. i .. "target") end
    end
end

local function Alert()
    local key = KeyText()
    local how = key and ("press " .. key) or ("click the " .. IconText(db.watchIcon) .. " button")
    Print("|cffffd100" .. db.watch .. " is here!|r " .. how:gsub("^%l", string.upper) .. " to target it.")
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        RaidNotice_AddMessage(RaidWarningFrame, IconText(db.watchIcon) .. " " .. db.watch .. " is here!", ChatTypeInfo.RAID_WARNING)
    end
    if db.watchSound and SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
end

local function Seen(unit)
    if not Matches(unit) then return end
    local dead = UnitIsDead(unit)
    if dead and not IsSecret(dead) then return end
    local now = GetTime()
    local fresh = now - lastSeen > ns.ALERT_GAP
    lastSeen = now
    if fresh then Alert() end
    SetGlow(true)
end

local function Scan()
    EachUnit(Seen)
    if glowing and GetTime() - lastSeen > ns.GLOW_GONE then SetGlow(false) end
end

local function StartWatching()
    watchKey = db.watch and strlower(db.watch)
    lastSeen = 0
    SetGlow(false)
    if ticker then ticker:Cancel() ticker = nil end
    if watchKey then
        ticker = C_Timer.NewTicker(ns.SCAN_EVERY, Scan)
        Scan()
    end
end

-- The macro has run by now (on the release); the press itself does nothing. Right-click stops
-- watching. Otherwise only says why nothing happened: a secret name (dungeons) can't be
-- checked, so it stays quiet then.
button:SetScript("PostClick", function(_, mouse, down)
    if down or not db.watch then return end
    if mouse == "RightButton" then
        GameTooltip:Hide()
        return ns.WatchCommand("unwatch")
    end
    if Matches("target") then return end
    if UnitExists("target") and IsSecret(UnitName("target")) then return end
    local now = GetTime()
    if now - lastMiss < ns.MISS_GAP then return end
    lastMiss = now
    if not ns.CanMark(true) then
        Print("you need to be raid leader or assistant to mark.")
    else
        Print(db.watch .. " isn't in view.")
    end
end)

---------------------------------------------------------------------------
-- Slash: /mark watch …, /mark unwatch
---------------------------------------------------------------------------
local function OnOff(arg, current)
    if arg == "on" then return true elseif arg == "off" then return false end
    return not current
end

local function Status()
    if db.watch then
        Print("watching for " .. db.watch .. " " .. IconText(db.watchIcon) .. ".")
    else
        Print("not watching for anything.")
    end
    local key = KeyText()
    Print("key: " .. (key or "none (Key Bindings > AddOns > EzMark)")
        .. ", sound: " .. (db.watchSound and "on" or "off"))
    Print("/mark watch <NPC name> - watch for it; /mark unwatch - stop")
    Print("/mark watch icon <icon>, sound [on|off], reset (button position)")
end

local function SetWatch(name)
    db.watch = name
    UpdateLook()
    ApplySecure()
    StartWatching()
end

function ns.WatchCommand(cmd, rest)
    rest = strtrim(rest or "")
    local sub, arg = rest:match("^(%S+)%s*(.-)$")
    sub = sub and strlower(sub)
    arg = strlower(arg or "")
    if cmd == "unwatch" or (sub == "off" and arg == "") then
        if not db.watch then return Print("not watching for anything.") end
        local old = db.watch
        SetWatch(nil)
        Print("stopped watching for " .. old .. "." .. (pending and " The button goes away after combat." or ""))
    elseif not sub then
        Status()
    elseif sub == "icon" and arg ~= "" then
        local index = ns.ParseIcon(arg)
        if not index then return Print("unknown icon '" .. arg .. "'.") end
        db.watchIcon = index
        UpdateLook()
        ApplySecure()
        Print("watch icon set to " .. IconText(index))
    elseif sub == "sound" then
        db.watchSound = OnOff(arg, db.watchSound)
        Print("alert sound " .. (db.watchSound and "on" or "off") .. ".")
    elseif sub == "reset" and arg == "" then
        db.watchPos = nil
        if InCombatLockdown() then return Print("can't move the button in combat.") end
        Place()
        Print("button moved back.")
    else
        local name = rest:gsub("%c", ""):sub(1, ns.MAX_NAME)
        name = strtrim(name)
        if name == "" then return Status() end
        SetWatch(name)
        local key = KeyText()
        Print("watching for " .. name .. " " .. IconText(db.watchIcon) .. ". "
            .. (key and ("Press " .. key) or "Click the button (or set a key in Key Bindings > AddOns > EzMark)")
            .. " to target and mark it." .. (pending and " The button shows up after combat." or ""))
    end
end

---------------------------------------------------------------------------
-- Setup and events
---------------------------------------------------------------------------
function ns.WatchLoaded(saved)
    db = saved
    if not ns.ICONS[db.watchIcon or 0] then db.watchIcon = ns.WATCH_ICON end
    db.watchAuto, db.watchBlocked = nil, nil -- the dropped auto-mark's settings
    if db.watchSound == nil then db.watchSound = true end
    UpdateLook()
    Place()
    ApplySecure()
    StartWatching()
end

events:SetScript("OnEvent", function(_, event, arg1)
    if not db then return end
    if event == "NAME_PLATE_UNIT_ADDED" then
        Seen(arg1)
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        Seen("mouseover")
    elseif event == "PLAYER_TARGET_CHANGED" then
        Seen("target")
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pending then ApplySecure() end
    end
end)
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
