-- EzMark: map coordinates in chat become links; a click puts a pin on your map (Coords.lua finds them).
local _, ns = ...

local db
local ZONE = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
local WORLD = Enum and Enum.UIMapType and Enum.UIMapType.World or 1

local function Readable(value)
    if value ~= nil and not ns.IsSecret(value) then return value end
end

local function MapInfo(map)
    return map and map > 0 and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(map) or nil
end

-- The zone a map belongs to (a cave or a town's own map: its zone), or nil above zones.
local function ZoneOf(map)
    local info = MapInfo(map)
    for _ = 1, 8 do
        if not info then return nil end
        if info.mapType == ZONE then return info.mapID end
        if info.mapType < ZONE then return nil end
        info = MapInfo(info.parentMapID)
    end
end

local function UnitZone(unit)
    local map = C_Map and C_Map.GetBestMapForUnit and Readable(C_Map.GetBestMapForUnit(unit))
    return map and ZoneOf(map)
end

local function MapName(map)
    local info = MapInfo(map)
    return info and Readable(info.name)
end

---------------------------------------------------------------------------
-- Zone names, so "Elwynn Forest 45 67" goes on Elwynn's map wherever you read it
---------------------------------------------------------------------------
local zones

-- The world map above the player's (Azeroth), or ns.TOP_MAP.
local function TopMap()
    local info = MapInfo(C_Map and C_Map.GetBestMapForUnit and Readable(C_Map.GetBestMapForUnit("player")))
    for _ = 1, 10 do
        if not info then break end
        if info.mapType <= WORLD then return info.mapID end
        local parent = MapInfo(info.parentMapID)
        if not parent then return info.mapID end
        info = parent
    end
    return ns.TOP_MAP
end

local function Zones()
    if zones then return zones end
    if not (C_Map and C_Map.GetMapChildrenInfo) then return nil end
    local names = {}
    for _, info in ipairs(C_Map.GetMapChildrenInfo(TopMap(), ZONE, true) or {}) do
        local name = Readable(info.name)
        if name and info.mapType == ZONE then names[info.mapID] = name end
    end
    local list = ns.ZoneList(names)
    if #list > 0 then zones = list end -- too early to read the maps: try again on the next line
    return list
end

---------------------------------------------------------------------------
-- Chat filter
---------------------------------------------------------------------------
-- A group member's zone, matched by first name (Forever's chat names may carry a surname).
local function GroupZone(author)
    if type(author) ~= "string" or ns.IsSecret(author) then return nil end
    local key = strlower(author:match("^[^%s%-]+") or author)
    local raid = IsInRaid()
    for i = 1, raid and GetNumGroupMembers() or 4 do
        local unit = (raid and "raid" or "party") .. i
        local name = UnitExists(unit) and Readable(UnitName(unit))
        if name and strlower(name:match("^[^%s%-]+") or name) == key then return UnitZone(unit) end
    end
end

-- Coordinates with no zone named go on the sender's zone when they're in your group, else on yours.
local function SenderZone(event, author)
    return ns.GROUP_EVENTS[event] and GroupZone(author) or UnitZone("player")
end

-- Every chat window runs the filter on the same line; work it out once.
local lastLine, lastOut

local function Filter(_, event, msg, author, ...)
    if not (db and db.coords) or ns.IsSecret(msg) or type(msg) ~= "string" or not msg:find("%d") then
        return false
    end
    local lineID = Readable((select(9, ...)))
    if lineID and lineID == lastLine then
        if lastOut then return false, lastOut, author, ... end
        return false
    end
    local senderZone
    local out, count = ns.ConvertCoords(msg, Zones(), function(pair)
        local map = pair.zone
        if not map then
            if senderZone == nil then senderZone = SenderZone(event, author) or false end
            map = senderZone or nil
        end
        return ns.PinLink(map, pair.x, pair.y, pair.label)
    end)
    lastLine, lastOut = lineID, count > 0 and out or nil
    if count == 0 then return false end
    return false, out, author, ...
end

local AddFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
for _, event in ipairs(ns.COORD_EVENTS) do AddFilter(event, Filter) end

---------------------------------------------------------------------------
-- Clicks and tooltips
---------------------------------------------------------------------------
local function CanPin(map)
    return map and C_Map and C_Map.SetUserWaypoint and UiMapPoint and C_Map.CanSetUserWaypointOnMap
        and C_Map.CanSetUserWaypointOnMap(map)
end

-- Your map pin is already on this spot.
local function IsPinned(map, x, y)
    local pin = C_Map and C_Map.HasUserWaypoint and C_Map.HasUserWaypoint() and C_Map.GetUserWaypoint()
    if not (pin and pin.uiMapID == map and pin.position) then return false end
    return math.abs(pin.position.x * 100 - x) < 0.05 and math.abs(pin.position.y * 100 - y) < 0.05
end

local function Where(map, x, y)
    return ns.ShareCoords(MapName(map), x, y)
end

local function Click(map, x, y)
    if not map then
        return ns.Print(Where(map, x, y) .. ": no zone named, and EzMark couldn't tell which zone it's in.")
    end
    if not CanPin(map) then
        return ns.Print(Where(map, x, y) .. ": the game doesn't allow a map pin there.")
    end
    if IsPinned(map, x, y) then
        C_Map.ClearUserWaypoint()
        return ns.Print("map pin removed.")
    end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x / 100, y / 100))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    ns.Print("map pin set: " .. Where(map, x, y) .. ". Click it again to take it off.")
end

local function OurPin(link)
    if ns.IsSecret(link) then return nil end
    return ns.ParsePin(link)
end

local tipFrame

if EventRegistry and EventRegistry.RegisterCallback then
    -- Blizzard's handler for |Haddon:...|h links passes clicks on here (nothing in chat is hooked).
    EventRegistry:RegisterCallback("SetItemRef", function(_, link)
        local map, x, y = OurPin(link)
        if not x then return end
        -- Shift-click while typing: the zone and coordinates as text, so anyone reading gets the place.
        if IsModifiedClick("CHATLINK") then
            local Insert = (ChatFrameUtil and ChatFrameUtil.InsertLink) or ChatEdit_InsertLink
            if Insert and Insert(Where(map, x, y)) then return end
        end
        Click(map, x, y)
    end, ns)

    EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkEnter", function(_, frame, link)
        local map, x, y = OurPin(link)
        if not x or not frame then return end
        tipFrame = frame
        GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
        GameTooltip:AddLine("Map coordinates", 1, 0.82, 0)
        GameTooltip:AddLine(Where(map, x, y), 1, 1, 1)
        if not CanPin(map) then
            GameTooltip:AddLine("No map pin possible there.", 1, 0.3, 0.3)
        elseif IsPinned(map, x, y) then
            GameTooltip:AddLine("Click: take your map pin off", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("Click: put a pin on your map", 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("Shift-click while typing: put it in your line", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end, ns)

    EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkLeave", function()
        if tipFrame and GameTooltip:IsOwned(tipFrame) then GameTooltip:Hide() end
        tipFrame = nil
    end, ns)
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
function ns.CoordsCommand(rest)
    local word = strlower(strtrim(rest or ""))
    if word == "on" then
        db.coords = true
    elseif word == "off" then
        db.coords = false
    elseif word ~= "" then
        return ns.Print("/mark coords [on|off]")
    end
    ns.Print("map coordinates in chat are " .. (db.coords and "clickable" or "left as typed")
        .. " (/mark coords " .. (db.coords and "off" or "on") .. ").")
end

function ns.PinsLoaded(saved)
    db = saved
    if db.coords == nil then db.coords = true end
end
