std = "lua51"
max_line_length = false
self = false

globals = {
    "EzMarkDB",
    "SLASH_EZMARK1",
    "SLASH_EZMARK2",
    "SlashCmdList",
    "BINDING_HEADER_EZMARK",
    "_G",
}

read_globals = {
    -- Frames & UI
    "CreateFrame", "UIParent", "DEFAULT_CHAT_FRAME", "EventRegistry", "GetCursorPosition",
    -- Namespaced APIs
    "C_CVar", "C_Map", "C_SuperTrack", "UiMapPoint", "Enum",
    "ChatFrameUtil", "ChatFrame_AddMessageEventFilter", "ChatEdit_InsertLink", "IsModifiedClick",
    -- Global APIs
    "InCombatLockdown", "IsAltKeyDown", "issecretvalue",
    "UnitExists", "UnitIsPlayer", "UnitName",
    "IsInRaid", "GetNumGroupMembers", "UnitIsGroupLeader", "UnitIsGroupAssistant",
    "GameTooltip", "GetTime", "C_Timer", "PlaySound", "SOUNDKIT",
    "RaidNotice_AddMessage", "RaidWarningFrame", "ChatTypeInfo",
    "GetBindingKey", "GetBindingText", "IsShiftKeyDown", "UnitIsDead", "IsInGroup",
    -- Lua helpers WoW adds
    "strtrim", "strlower",
}
