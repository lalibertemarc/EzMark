# EzMark

## v1.1.0

- New: watch for an NPC. `/mark watch <name>` keeps an eye out for it and warns you (chat, center of the screen, raid warning sound) when it shows up on a nameplate, under your mouse or as someone's target.
- A skull button (and a key you can set under Key Bindings > AddOns > EzMark) targets the NPC and marks it in one press. Spam it all you like: if it isn't in view, your target doesn't change.
- `/mark watch icon`, `sound` and `reset` change the marker, the alert sound and the button's spot. `/mark unwatch` stops.
- `/mark <name>` no longer tries to mark: WoW Forever refuses markers from an addon's command (it showed an error). It now gives you a two-line macro that does it.

## v1.0.2

- Listed under **Chat & Communication** in the game's AddOns list.

## v1.0.1

- Fixed a Lua error when holding Alt over a player name on some chat lines. On those lines the highlight now centers on the cursor.

## v1.0.0

- First release for WoW Forever.
- Hold Alt and click a player's name in chat to put a raid marker over them (a red X by default). Alt+click them again to take it off.
- Works in a crowded city: the click targets the player by name, like a `/targetexact` macro, so they don't need a nameplate. Out of combat only.
- `/mark <name>` marks a player who's your target, focus, group member or under your mouse; `/mark icon <1-8 or name>` changes the icon.
