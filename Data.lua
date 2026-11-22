-- EzMark: static data.
local _, ns = ...

-- Raid target icons in /tm order (1-8).
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

-- Map coordinates in chat (Coords.lua, Pins.lua).
ns.LINK_TYPE = "EzMark"   -- |Haddon:EzMark:pin:...|h
ns.PIN_COLOR = "80d1ff"
ns.TOP_MAP = 947          -- Azeroth, when the player's own map can't be walked up yet
ns.COORD_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM", "CHAT_MSG_CHANNEL", "CHAT_MSG_COMMUNITIES_CHANNEL",
}
-- Events from your group: the sender's own zone is known, so their coordinates go on their map.
ns.GROUP_EVENTS = {
    CHAT_MSG_PARTY = true, CHAT_MSG_PARTY_LEADER = true, CHAT_MSG_RAID = true, CHAT_MSG_RAID_LEADER = true,
    CHAT_MSG_RAID_WARNING = true, CHAT_MSG_INSTANCE_CHAT = true, CHAT_MSG_INSTANCE_CHAT_LEADER = true,
}
