-- EzMark: static data.
local _, ns = ...

-- Raid target icons in SetRaidTarget order (1-8).
ns.ICONS = { "star", "circle", "diamond", "triangle", "moon", "square", "cross", "skull" }

-- Aliases accepted by /mark icon.
ns.ICON_ALIASES = { x = 7 }

ns.DEFAULT_ICON = 7 -- cross
