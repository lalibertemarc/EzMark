-- EzMark: static data.
local _, ns = ...

-- Raid target icons in SetRaidTarget order (1-8).
ns.ICONS = { "star", "circle", "diamond", "triangle", "moon", "square", "cross", "skull" }

-- Aliases accepted by /mark icon.
ns.ICON_ALIASES = { x = 7 }

ns.DEFAULT_ICON = 7 -- cross

-- Friendly-player nameplate CVars, briefly turned on when the player has no nameplate.
-- Forever uses one or the other depending on build; missing ones are skipped.
ns.FRIEND_PLATE_CVARS = { "nameplateShowFriends", "nameplateShowFriendlyPlayers" }

-- How long to wait for the player's nameplate to appear after turning friendly plates on.
ns.PLATE_WAIT = 1
