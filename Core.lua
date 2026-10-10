-- EzMark: Alt+click a player name in chat to put a raid marker over them.
local addonName, ns = ...

local db          -- EzMarkDB, set on ADDON_LOADED
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

-- Forever returns a character's surname where UnitName's realm would be, and chat links
-- may carry it too ("Sephrina Gam"). First names are unique, so that's what we match on.
local function FirstName(name)
    return name:match("^[^%s%-]+") or name
end

local function NameKey(name)
    return strlower(FirstName(name))
end

---------------------------------------------------------------------------
-- Finding the player
---------------------------------------------------------------------------
-- SetRaidTarget needs a unit token, not a name, so look for a token that points at them.
local function UnitMatches(unit, key)
    if not UnitExists(unit) then return false end
    local isPlayer = UnitIsPlayer(unit)
    if IsSecret(isPlayer) or not isPlayer then return false end
    local name = UnitName(unit)
    if not name or IsSecret(name) then return false end
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

-- /mark can't target (that needs a secure click), so it only finds players who already have
-- a unit token: target, mouseover, focus, group or a visible nameplate.
local function MarkByName(name)
    name = strtrim(name or "")
    if name == "" or not CanMark() then return end
    local unit = FindUnit(NameKey(name))
    if unit then return ApplyMark(unit, name) end
    PrintOutOfRange(name)
end

---------------------------------------------------------------------------
-- Alt+click in chat
---------------------------------------------------------------------------
-- A plain click on a player name opens a whisper, and hooking that path would taint the
-- chat box. Instead, while Alt is held over a name, this button covers it and takes the
-- click, so the chat frame never sees it.
--
-- Forever doesn't give addons nameplates for friendly players, so there's often no unit
-- token to mark. The button is secure and runs a macro instead: clear the target, target
-- the player by name (works for anyone in view), then /tm, which toggles the icon.
-- Secure frames can't be moved or changed in combat, so it only shows out of combat.
local overlay = CreateFrame("Button", "EzMarkOverlay", UIParent, "SecureActionButtonTemplate")
overlay:SetFrameStrata("DIALOG")
overlay:RegisterForClicks(C_CVar.GetCVarBool("ActionButtonUseKeyDown") and "LeftButtonDown" or "LeftButtonUp")
overlay:SetAttribute("type", "macro")
overlay:EnableMouseWheel(true)
overlay:Hide()

local glow = overlay:CreateTexture(nil, "BACKGROUND")
glow:SetAllPoints()
glow:SetColorTexture(1, 0.2, 0.2, 0.25)

local MIN_WIDTH, MIN_HEIGHT = 24, 14

-- Try the full name, then the first name: the unit's name is the first name alone, so that
-- line is the likelier match and gets the last word.
local function MarkMacro(name)
    name = name:gsub("%c", "")
    local first = FirstName(name)
    local lines = { "/cleartarget" }
    if first ~= name then lines[#lines + 1] = "/targetexact " .. name end
    lines[#lines + 1] = "/targetexact " .. first
    lines[#lines + 1] = "/tm " .. db.icon
    return table.concat(lines, "\n")
end

local function LinkSize(ratio)
    return math.max((hover.width or 0) * ratio, MIN_WIDTH), math.max((hover.height or 0) * ratio, MIN_HEIGHT)
end

-- The link's box in UIParent coordinates. A secure frame can't be anchored to the chat's
-- font string, so the box is worked out here and placed on UIParent instead.
local function LinkRect(scale)
    local region = hover.region
    local regionLeft, regionBottom = region and region:GetLeft(), region and region:GetBottom()
    if not (regionLeft and hover.left and hover.bottom) then return end
    local owner = region.GetEffectiveScale and region or region:GetParent()
    local ratio = owner:GetEffectiveScale() / scale
    return (regionLeft + hover.left) * ratio, (regionBottom + hover.bottom) * ratio, LinkSize(ratio)
end

-- The link bounds line up for one-line messages but not always for wrapped ones, so if the
-- box doesn't land under the cursor, center it on the cursor instead.
local function ShowOverlay()
    if InCombatLockdown() then return end
    local scale = overlay:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    local left, bottom, width, height = LinkRect(scale)
    overlay:ClearAllPoints()
    if left and x >= left and x <= left + width and y >= bottom and y <= bottom + height then
        overlay:SetSize(width, height)
        overlay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left, bottom)
    else
        overlay:SetSize(LinkSize(1))
        overlay:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
    overlay.name = hover.name
    overlay:SetAttribute("macrotext", MarkMacro(hover.name))
    overlay:Show()
end

local function HideOverlay()
    if not InCombatLockdown() then overlay:Hide() end
    hover = nil
end

-- The macro has run by now; if they aren't the target, /targetexact didn't find them.
overlay:SetScript("PostClick", function(self)
    if not UnitMatches("target", NameKey(self.name)) then
        PrintOutOfRange(self.name)
    else
        CanMark()
    end
end)
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
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        plates[arg1] = true
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        plates[arg1] = nil
    elseif event == "MODIFIER_STATE_CHANGED" then
        if arg1 ~= "LALT" and arg1 ~= "RALT" then return end
        if arg2 == 1 and hover then
            ShowOverlay()
        elseif arg2 == 0 and not InCombatLockdown() then
            overlay:Hide()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        HideOverlay() -- last chance before lockdown freezes it
    end
end)
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("MODIFIER_STATE_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
