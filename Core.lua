-- EzMark: Alt+click a player name in chat to put a raid marker over them.
local addonName, ns = ...

local GetCVar, SetCVar = C_CVar.GetCVar, C_CVar.SetCVar

local db          -- EzMarkDB, set on ADDON_LOADED
local pending     -- name we're waiting on while friendly nameplates come up
local hover       -- player link under the mouse in chat
local plates = {} -- active nameplate unit tokens
local events = CreateFrame("Frame")

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99EzMark|r: " .. msg)
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function IconText(index)
    return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index .. ":0|t"
end

-- Lowercase, own realm stripped, so "Bob", "bob" and "Bob-MyRealm" all match.
local function NameKey(name)
    return strlower(Ambiguate(name, "none"))
end

---------------------------------------------------------------------------
-- Finding the player
---------------------------------------------------------------------------
-- SetRaidTarget needs a unit token, not a name, so look for a token that points at them.
local function UnitMatches(unit, key)
    if not UnitExists(unit) then return false end
    local isPlayer = UnitIsPlayer(unit)
    if IsSecret(isPlayer) or not isPlayer then return false end
    local name, realm = UnitName(unit)
    if not name or IsSecret(name) or IsSecret(realm) then return false end
    if realm and realm ~= "" then name = name .. "-" .. realm end
    return NameKey(name) == key
end

local FIXED_UNITS = { "target", "mouseover", "focus" }

local function FindUnit(key)
    for _, unit in ipairs(FIXED_UNITS) do
        if UnitMatches(unit, key) then return unit end
    end
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        if UnitMatches(prefix .. i, key) then return prefix .. i end
    end
    for unit in pairs(plates) do
        if UnitMatches(unit, key) then return unit end
    end
end

---------------------------------------------------------------------------
-- Friendly nameplates
---------------------------------------------------------------------------
-- Turned on just long enough to find the player, then put back. Saved in the DB so a
-- /reload in that window still restores them; nameplate CVars can't change in combat.
local function RestorePlates()
    local saved = db.plateRestore
    if not saved then return end
    if InCombatLockdown() then
        events:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    for cvar, value in pairs(saved) do SetCVar(cvar, value) end
    db.plateRestore = nil
end

local function FriendPlatesShown()
    for _, cvar in ipairs(ns.FRIEND_PLATE_CVARS) do
        if GetCVar(cvar) == "1" then return true end
    end
    return false
end

local function ShowFriendPlates()
    local saved = {}
    for _, cvar in ipairs(ns.FRIEND_PLATE_CVARS) do
        local value = GetCVar(cvar)
        if value ~= nil then
            saved[cvar] = value
            SetCVar(cvar, "1")
        end
    end
    if not next(saved) then return false end
    db.plateRestore = saved
    return true
end

local function FinishPending()
    if not pending then return end
    pending.timer:Cancel()
    pending = nil
    RestorePlates()
end

---------------------------------------------------------------------------
-- Marking
---------------------------------------------------------------------------
-- In a raid only the leader and assistants can mark; in a party or solo anyone can.
local function CanMark()
    if IsInRaid() and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        Print("you need to be raid leader or assistant to mark.")
        return false
    end
    return true
end

-- Clicking someone who already has the icon takes it off.
local function ApplyMark(unit, name)
    local icon = db.icon
    local current = GetRaidTargetIndex(unit)
    if not IsSecret(current) and current == icon then
        SetRaidTarget(unit, 0)
        Print("removed " .. IconText(icon) .. " from " .. name .. ".")
    else
        SetRaidTarget(unit, icon)
        Print("marked " .. name .. " " .. IconText(icon))
    end
end

local function PrintOutOfRange(name)
    Print(name .. " isn't close enough to mark.")
end

local function MarkByName(name)
    name = strtrim(name or "")
    if name == "" or not CanMark() then return end

    local key = NameKey(name)
    local unit = FindUnit(key)
    if unit then return ApplyMark(unit, name) end

    FinishPending()
    if FriendPlatesShown() or InCombatLockdown() or not ShowFriendPlates() then
        return PrintOutOfRange(name)
    end
    pending = { name = name, key = key }
    pending.timer = C_Timer.NewTimer(ns.PLATE_WAIT, function()
        local missed = pending.name
        FinishPending()
        PrintOutOfRange(missed)
    end)
end

local function OnPlateAdded(unit)
    plates[unit] = true
    if pending and UnitMatches(unit, pending.key) then
        ApplyMark(unit, pending.name) -- before the plate (and its token) goes away
        FinishPending()
    end
end

---------------------------------------------------------------------------
-- Alt+click in chat
---------------------------------------------------------------------------
-- A plain click on a player name opens a whisper, and hooking that path would taint the
-- chat box. Instead, while Alt is held over a name, this button covers it and takes the
-- click, so the chat frame never sees it.
local overlay = CreateFrame("Button", nil, UIParent)
overlay:SetFrameStrata("DIALOG")
overlay:RegisterForClicks("LeftButtonUp")
overlay:EnableMouseWheel(true)
overlay:Hide()

local glow = overlay:CreateTexture(nil, "BACKGROUND")
glow:SetAllPoints()
glow:SetColorTexture(1, 0.2, 0.2, 0.25)

local function ShowOverlay()
    overlay:ClearAllPoints()
    overlay:SetPoint("BOTTOMLEFT", hover.region, "BOTTOMLEFT", hover.left, hover.bottom)
    overlay:SetSize(hover.width, hover.height)
    overlay.name = hover.name
    overlay:Show()
end

local function HideOverlay()
    overlay:Hide()
    hover = nil
end

overlay:SetScript("OnClick", function(self) MarkByName(self.name) end)
overlay:SetScript("OnLeave", HideOverlay)
overlay:SetScript("OnMouseWheel", HideOverlay) -- chat would scroll a different line under it

EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkEnter", function(_, _, link, _, region, left, bottom, width, height)
    if IsSecret(link) then return end
    local name = link:match("^player:([^:]+)")
    if not name or name == "" then return end
    hover = { name = name, region = region, left = left, bottom = bottom, width = width, height = height }
    if IsAltKeyDown() then ShowOverlay() end
end, overlay)

-- Showing the overlay moves the mouse off the link; that leave doesn't count.
EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkLeave", function()
    if not overlay:IsShown() then hover = nil end
end, overlay)

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------
local function ParseIcon(arg)
    local index = tonumber(arg)
    if index and ns.ICONS[index] then return index end
    for i, iconName in ipairs(ns.ICONS) do
        if iconName == arg then return i end
    end
    return ns.ICON_ALIASES[arg]
end

local function PrintHelp()
    Print("Alt+click a player's name in chat to mark them " .. IconText(db.icon) .. " (again to remove).")
    Print("/mark <name> - mark a player by name")
    Print("/mark icon <1-8 or name> - change the icon (star, circle, diamond, triangle, moon, square, cross, skull)")
end

SLASH_EZMARK1 = "/mark"
SLASH_EZMARK2 = "/ezmark"
SlashCmdList.EZMARK = function(msg)
    msg = strtrim(msg or "")
    local cmd, rest = msg:match("^(%S+)%s*(.-)$")
    if not cmd then return PrintHelp() end
    if strlower(cmd) == "icon" and rest ~= "" then
        local index = ParseIcon(strlower(rest))
        if not index then return Print("unknown icon '" .. rest .. "'.") end
        db.icon = index
        return Print("icon set to " .. IconText(index))
    end
    MarkByName(msg)
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
events:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        self:UnregisterEvent("ADDON_LOADED")
        EzMarkDB = EzMarkDB or {}
        db = EzMarkDB
        if not ns.ICONS[db.icon or 0] then db.icon = ns.DEFAULT_ICON end
        RestorePlates()
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        OnPlateAdded(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        plates[arg1] = nil
    elseif event == "MODIFIER_STATE_CHANGED" then
        if arg1 ~= "LALT" and arg1 ~= "RALT" then return end
        if arg2 == 1 and hover then
            ShowOverlay()
        elseif arg2 == 0 then
            overlay:Hide()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        RestorePlates()
    end
end)
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("MODIFIER_STATE_CHANGED")
