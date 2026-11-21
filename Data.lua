-- EzMark: static data.
local _, ns = ...

-- Raid target icons in SetRaidTarget order (1-8).
ns.ICONS = { "star", "circle", "diamond", "triangle", "moon", "square", "cross", "skull" }

-- Aliases accepted by /mark icon.
ns.ICON_ALIASES = { x = 7 }

ns.DEFAULT_ICON = 7 -- cross

-- Watching for an NPC (Watch.lua).
ns.WATCH_ICON = 8     -- skull
ns.ALERT_GAP = 60     -- seconds out of sight before it alerts again
ns.GLOW_GONE = 5      -- seconds out of sight before the button stops glowing
ns.SCAN_EVERY = 1     -- seconds between looks at nameplates, target, mouseover, focus, group targets
ns.MISS_GAP = 3       -- seconds between "not in view" lines when the key is held or spammed
ns.WATCH_SIZE = 36
ns.MAX_NAME = 60
