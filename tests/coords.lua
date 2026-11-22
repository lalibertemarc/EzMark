-- Coordinates in chat → pin links. Run from the addon folder: lua tests/coords.lua
local ns = {}
local function Load(file)
    local chunk = assert(loadfile(file))
    chunk("EzMark", ns)
end
Load("Data.lua")
Load("Coords.lua")

local failures = 0
local function Check(ok, what)
    if not ok then
        failures = failures + 1
        print("FAIL: " .. what)
    end
end

local zones = ns.ZoneList({ [1429] = "Elwynn Forest", [1436] = "Westfall", [1453] = "Stormwind City",
    [1424] = "Hillsbrad Foothills", [1440] = "Ashenvale" })

-- Swaps each pair for <x|y|zone> so the tests read easily.
local function Mark(pair)
    return ("<%s|%s|%s>"):format(ns.Coord(pair.x), ns.Coord(pair.y), pair.zone or "-")
end

local function Expect(msg, want)
    local out = ns.ConvertCoords(msg, zones, Mark)
    Check(out == want, ("%q\n  got  %q\n  want %q"):format(msg, out, want))
end

-- Found
Expect("rare at 45.2, 67.8", "rare at <45.2|67.8|->")
Expect("rare at 45.2 67.8 go", "rare at <45.2|67.8|-> go")
Expect("45,67", "<45|67|->")
Expect("45 67", "<45|67|->")
Expect("he's at 45 67", "he's at <45|67|->")
Expect("Hogger @ 32 70!", "Hogger @ <32|70|->!")
Expect("coords: 12 80", "coords: <12|80|->")
Expect("/way 45 67", "/way <45|67|->")
Expect("/way Elwynn Forest 45 67 Hogger", "/way Elwynn Forest <45|67|1429> Hogger")
Expect("Westfall 56.3, 47.5 is the farm", "Westfall <56.3|47.5|1436> is the farm")
Expect("mine in elwynn forest at 40 80", "mine in elwynn forest at <40|80|1429>")
Expect("meet me (45, 67) ok", "meet me <45|67|-> ok")
Expect("meet me [45 67]", "meet me <45|67|->")
Expect("node 23, 45 and 60.1, 12.2", "node <23|45|-> and <60.1|12.2|->")
Expect("Stormwind City 100 0", "Stormwind City <100|0|1453>")
Expect("chest 45.25,67.5.", "chest <45.25|67.5|->.")
Expect("LFG rare at 45 67 |cff0070dd|Hitem:123::::|h[Sword]|h|r",
    "LFG rare at <45|67|-> |cff0070dd|Hitem:123::::|h[Sword]|h|r")

-- Left alone
local function Same(msg) Expect(msg, msg) end
Same("need 2 more")
Same("I have 45 67 problems")       -- spaces, whole numbers, nothing saying it's a place
Same("level 45, 60 soon")
Same("lvl 45.5 67")
Same("pick 1, 2")                   -- two single digits with a comma
Same("1, 2, 3")
Same("45, 67, 89")
Same("costs 10,000 gold")
Same("1,500")
Same("at 12:30 45")
Same("at 45 67%")
Same("at 45g 67s")
Same("at 145 67")
Same("version 1.15.9")
Same("at 45.123 67")
Same("at 0 0")
Same("x45 y67")
Same("|cff0070dd|Hitem:45:67::::|h[Ring 45, 67]|h|r")
Same("|TInterface\\Icons\\foo:0:0:45:67|t")
Same("\001")

-- Links
local link = ns.PinLink(1429, 45.2, 67.8, "45.2, 67.8")
Check(link == "|cff80d1ff|Haddon:EzMark:pin:1429:45.2:67.8|h[45.2, 67.8]|h|r", "PinLink: " .. link)
local map, x, y = ns.ParsePin("addon:EzMark:pin:1429:45.2:67.8")
Check(map == 1429 and x == 45.2 and y == 67.8, "ParsePin")
map, x, y = ns.ParsePin("addon:EzMark:pin:0:45:67")
Check(map == nil and x == 45 and y == 67, "ParsePin without a map")
Check(ns.ParsePin("addon:EzMark:pin:1429:145:67") == nil, "ParsePin past 100")
Check(ns.ParsePin("addon:EzQuestLink:783:1") == nil, "ParsePin, not ours")
Check(ns.ShareCoords("Elwynn Forest", 45, 67.5) == "Elwynn Forest 45, 67.5", "ShareCoords")
Check(ns.ShareCoords(nil, 45.25, 67) == "45.25, 67", "ShareCoords without a zone")

-- A shared line reads back to the same place.
local shared = ns.ShareCoords("Elwynn Forest", 45.2, 67.8)
local back = ns.ConvertCoords(shared, zones, Mark)
Check(back == "Elwynn Forest <45.2|67.8|1429>", "share round trip: " .. back)

-- Links in the line survive, a made link is never looked into again.
local out, count = ns.ConvertCoords("at 45 67 and 12.5, 30", zones, function(pair)
    return ns.PinLink(pair.zone or 1429, pair.x, pair.y, pair.label)
end)
Check(count == 2, "two links made")
Check(out == "at " .. ns.PinLink(1429, 45, 67, "45, 67") .. " and " .. ns.PinLink(1429, 12.5, 30, "12.5, 30"),
    "links in place: " .. out)
local again, n = ns.ConvertCoords(out, zones, Mark)
Check(n == 0 and again == out, "converted line left alone")

-- makeLink may refuse one.
out, count = ns.ConvertCoords("at 45 67", zones, function() return nil end)
Check(count == 0 and out == "at 45 67", "refused link")

if failures > 0 then
    print(failures .. " failed")
    os.exit(1)
end
print("coords: all passed")
