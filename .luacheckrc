std = "lua51"
max_line_length = false
self = false

globals = {
    "EzMarkDB",
    "SLASH_EZMARK1",
    "SLASH_EZMARK2",
    "SlashCmdList",
}

read_globals = {
    -- Frames & UI
    "CreateFrame", "UIParent", "DEFAULT_CHAT_FRAME", "EventRegistry", "GetCursorPosition",
    -- Namespaced APIs
    "C_CVar",
    -- Global APIs
    "InCombatLockdown", "IsAltKeyDown", "issecretvalue",
    "UnitExists", "UnitIsPlayer", "UnitName",
    "IsInRaid", "GetNumGroupMembers", "UnitIsGroupLeader", "UnitIsGroupAssistant",
    "GetRaidTargetIndex", "SetRaidTarget",
    -- Lua helpers WoW adds
    "strtrim", "strlower",
}
