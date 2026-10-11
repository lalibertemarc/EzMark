# EzMark

## v1.0.1

- Fixed a Lua error when holding Alt over a player name on some chat lines. On those lines the highlight now centers on the cursor.

## v1.0.0

- First release for WoW Forever.
- Hold Alt and click a player's name in chat to put a raid marker over them (a red X by default). Alt+click them again to take it off.
- Works in a crowded city: the click targets the player by name, like a `/targetexact` macro, so they don't need a nameplate. Out of combat only.
- `/mark <name>` marks a player who's your target, focus, group member or under your mouse; `/mark icon <1-8 or name>` changes the icon.
