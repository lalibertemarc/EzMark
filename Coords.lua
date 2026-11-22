-- EzMark: map coordinates typed in chat ("rare at 45.2, 67.8", "/way Elwynn Forest 45 67") → links that put a
-- pin on your map. No game API here: tests/coords.lua runs it in plain Lua 5.1.
local _, ns = ...

local HYPERLINK = "|H.-|h.-|h"
local TEXTURE = "|T.-|t"
local ATLAS = "|A.-|a"
local KSTRING = "|K.-|k"
local TOKEN = "\001(%d+)\002"

-- Before a coordinate pair: start of line, a space, an opening bracket, "@", ":" or a quote.
local BEFORE = "[%s%(%[@:\"'~]"

-- Words right before a pair that say it's a place ("at 45 67", "coords: 45 67", "/way 45 67").
local CONTEXT = { "at", "near", "around", "coords", "coord", "coordinates", "loc", "location", "pos", "way" }
-- Words right before a pair that say it isn't ("level 45, 60").
local NOT_PLACE = { "level", "levels", "lvl", "lvls", "lv", "ilvl", "rank", "ranks", "page", "pages", "age" }

local function Token(saved, s)
    saved[#saved + 1] = s
    return "\001" .. #saved .. "\002"
end

local function Trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

-- A coordinate at s[i]: 0-100, at most two decimals. Returns value, text, last index, had decimals.
local function NumberAt(s, i)
    local int = s:match("^%d+", i)
    if not int or (#int > 2 and int ~= "100") then return nil end
    local j = i + #int
    local frac = s:match("^%.(%d+)", j)
    local text = int
    if frac then
        if #frac > 2 then return nil end
        text = int .. "." .. frac
        j = j + 1 + #frac
    end
    local value = tonumber(text)
    if not value or value > 100 then return nil end
    return value, text, j - 1, frac ~= nil
end

local function EndsWithWord(s, word)
    if #s < #word or s:sub(-#word) ~= word then return false end
    local before = s:sub(-#word - 1, -#word - 1)
    return before == "" or not before:find("[%w\128-\255]")
end

local function StripSeparators(s)
    return (s:gsub("[%s,:@%-%(%[]+$", ""))
end

-- The zone named right before the pair, if any. zones = { { name = "elwynn forest", map = 1429 }, ... },
-- longest first. p = lowercase text before the pair, trailing separators gone.
local function ZoneBefore(p, zones)
    if not zones then return nil end
    for _, z in ipairs(zones) do
        if EndsWithWord(p, z.name) then return z end
    end
end

-- Looks at the text before a pair: (said it's a place, zone or nil, said it isn't).
local function Lead(prefix, zones)
    local p = prefix:lower():gsub("[%s,:%(%[]+$", "")
    local context = p:sub(-1) == "@"
    p = StripSeparators(p)
    for _, word in ipairs(NOT_PLACE) do
        if not context and EndsWithWord(p, word) then return false, nil, true end
    end
    for _, word in ipairs(context and {} or CONTEXT) do
        if EndsWithWord(p, word) then
            context = true
            p = StripSeparators(p:sub(1, -#word - 1))
            break
        end
    end
    local zone = ZoneBefore(p, zones)
    return context or zone ~= nil, zone, false
end

-- Every coordinate pair in s (links already swapped for tokens). Returns { { s, e, x, y, label, zone }, ... }:
-- s..e is the part the link replaces (with its brackets when the pair sits alone inside them), label the pair as
-- typed.
local function FindPairs(s, zones)
    local found = {}
    local i = 1
    while true do
        local p = s:find("%d", i)
        if not p then break end
        local x, xText, xEnd, xDec = NumberAt(s, p)
        local nextFrom = (s:find("[^%d%.]", p) or #s + 1)
        local before = s:sub(p - 1, p - 1)
        if x and (before == "" or before:find(BEFORE)) then
            local sep = s:match("^%s*,%s*", xEnd + 1)
            local comma = sep ~= nil
            sep = sep or s:match("^%s+", xEnd + 1)
            local y, yText, yEnd, yDec
            if sep then y, yText, yEnd, yDec = NumberAt(s, xEnd + 1 + #sep) end
            local after = y and s:sub(yEnd + 1)
            local ok = after and not after:find("^[%w%%\128-\255\001]")
                and not after:find("^:%d") and not after:find("^%s*,?%s*%d")
                and not s:sub(1, p - 1):find("%d%s*,?%s*$")
                and not (x == 0 and y == 0)
            if ok then
                local first, last = p, yEnd
                local open, close = s:sub(p - 1, p - 1), s:sub(yEnd + 1, yEnd + 1)
                local wrapped = (open == "(" and close == ")") or (open == "[" and close == "]")
                if wrapped then first, last = p - 1, yEnd + 1 end
                local prefix, suffix = s:sub(1, first - 1), s:sub(last + 1)
                local place, zone, notPlace = Lead(prefix, zones)
                local alone = Trim(prefix) == "" and not suffix:find("[%w\128-\255\001]")
                if notPlace and not wrapped and not alone then
                    ok = false
                elseif not (place or wrapped or alone or xDec or yDec) then
                    ok = comma and (x >= 10 or y >= 10)
                end
                if ok then
                    found[#found + 1] = { s = first, e = last, x = x, y = y,
                        label = xText .. ", " .. yText, zone = zone and zone.map }
                    nextFrom = last + 1
                end
            end
        end
        i = math.max(nextFrom, p + 1)
    end
    return found
end

-- msg with every coordinate pair swapped for makeLink(pair) (pair = { x, y, label, zone }; may return nil to leave
-- it as typed). Links, textures and the like already in the line are never looked into.
-- Returns the line and how many were swapped (0: the line itself, unchanged).
function ns.ConvertCoords(msg, zones, makeLink)
    if type(msg) ~= "string" or not msg:find("%d") then return msg, 0 end
    local saved = {}
    local s = msg:gsub(HYPERLINK, function(t) return Token(saved, t) end)
    s = s:gsub(TEXTURE, function(t) return Token(saved, t) end)
    s = s:gsub(ATLAS, function(t) return Token(saved, t) end)
    s = s:gsub(KSTRING, function(t) return Token(saved, t) end)
    local pairs_ = FindPairs(s, zones)
    local count = 0
    for k = #pairs_, 1, -1 do
        local pair = pairs_[k]
        local link = makeLink(pair)
        if link then
            s = s:sub(1, pair.s - 1) .. Token(saved, link) .. s:sub(pair.e + 1)
            count = count + 1
        end
    end
    if count == 0 then return msg, 0 end
    return (s:gsub(TOKEN, function(n) return saved[tonumber(n)] end)), count
end

-- Coordinates as they'd be typed: 45.2 stays 45.2, 45.0 becomes 45.
local function Coord(v)
    return (("%.2f"):format(v):gsub("%.?0+$", ""))
end
ns.Coord = Coord

-- |Haddon:EzMark:pin:<map>:<x>:<y>|h[45.2, 67.8]|h; map 0 = not known.
function ns.PinLink(map, x, y, label, color)
    return ("|cff%s|Haddon:%s:pin:%d:%s:%s|h[%s]|h|r"):format(color or ns.PIN_COLOR, ns.LINK_TYPE, map or 0,
        Coord(x), Coord(y), label or (Coord(x) .. ", " .. Coord(y)))
end

-- link = "addon:EzMark:pin:1429:45.2:67.8". Returns map (nil if not known), x, y (0-100), or nil (not ours).
function ns.ParsePin(link)
    if type(link) ~= "string" then return nil end
    local map, x, y = link:match("^addon:" .. ns.LINK_TYPE .. ":pin:(%d+):([%d%.]+):([%d%.]+)")
    map, x, y = tonumber(map), tonumber(x), tonumber(y)
    if not (map and x and y) or x > 100 or y > 100 then return nil end
    return map > 0 and map or nil, x, y
end

-- What to type so anyone reading it (EzMark, TomTom's /way, people) gets the place: "Elwynn Forest 45.2, 67.8".
function ns.ShareCoords(zoneName, x, y)
    local text = Coord(x) .. ", " .. Coord(y)
    return zoneName and (zoneName .. " " .. text) or text
end

-- Zone list for ConvertCoords from { [mapID] = name }: lowercase, longest first.
function ns.ZoneList(names)
    local list = {}
    for map, name in pairs(names) do
        if type(name) == "string" and name ~= "" then list[#list + 1] = { name = name:lower(), map = map } end
    end
    table.sort(list, function(a, b)
        if #a.name ~= #b.name then return #a.name > #b.name end
        return a.map < b.map
    end)
    return list
end
