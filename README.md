# EzMark

**Spot someone in a crowd: Alt+click their name in chat and a raid marker appears over their head.**

Someone in trade chat is selling what you need, or a friend says "I'm at the bank" and the bank is packed. Hold **Alt** and click their name in the chat window, and EzMark puts a red **X** over them.

## How to use it

- **Alt+click** a player's name in chat to mark them. The name lights up red while Alt is held, so you know the click will mark rather than whisper
- **Alt+click** the same name again to take the marker off
- **`/mark <name>`** marks a player by name if they're your target, your focus, in your group or under your mouse
- **`/mark icon <icon>`** changes the marker: `1`-`8` or `star`, `circle`, `diamond`, `triangle`, `moon`, `square`, `cross`, `skull` (also `x`)

## Watch for an NPC

Hunting a rare, or need one NPC marked in a crowd? Give EzMark its name and it keeps an eye out.

- **`/mark watch <NPC name>`** starts watching, for example `/mark watch Hogger`. A skull button appears with the name under it
- **When it shows up** (on a nameplate, under your mouse, as your target or focus, or as a group member's target), EzMark warns you in chat and on screen, plays the raid warning sound and the button glows.
- **Press the button, or your key,** to target the NPC and mark it. Set the key under Key Bindings > AddOns > EzMark. You can press it as often as you like: if the NPC isn't in view, your target stays as it was
- **`/mark unwatch`** stops watching
- **`/mark watch icon <icon>`** changes the watch marker (skull by default), **`/mark watch sound on|off`** the alert sound, **`/mark watch reset`** puts the button back. **Shift-drag** the button to move it
- **`/mark watch`** shows what's being watched and the settings

The game only lets you target with your own key press or click, so EzMark never targets anything by itself. Marking needs a press too, so the button or key does both.

## Good to know

- **Your target changes:** Alt+click targets the player so it can mark them, the same way a `/targetexact` macro would. They stay targeted, which also helps you find them
- **Range:** the player has to be in view. If they aren't, EzMark says so and your target is cleared
- **Groups:** solo or in a party you can always mark. In a raid you need to be leader or assistant
- **Who sees it:** markers are shown to you and your group only
- **Combat:** Alt+click doesn't work during combat (the game locks targeting buttons), so a click on a name opens a whisper as usual
