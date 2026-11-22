# EzMark

**Spot someone in a crowd: Alt+click their name in chat and a raid marker appears over their head.**

Someone in trade chat is selling what you need, or a friend says "I'm at the bank" and the bank is packed. Hold **Alt** and click their name in the chat window, and EzMark puts a red **X** over them.

## How to use it

- **Alt+click** a player's name in chat to mark them. The name lights up red while Alt is held, so you know the click will mark rather than whisper
- **Alt+click** the same name again to take the marker off
- **`/mark <name>`** shows a two-line macro that marks them: WoW Forever only lets the game's own `/tm` put markers on, not an addon's command
- **`/mark icon <icon>`** changes the marker: `1`-`8` or `star`, `circle`, `diamond`, `triangle`, `moon`, `square`, `cross`, `skull` (also `x`)

## Watch for an NPC

Hunting a rare, or need one NPC marked in a crowd? Give EzMark its name and it keeps an eye out.

- **`/mark watch <NPC name>`** starts watching, for example `/mark watch Hogger`. A skull button appears with the name under it
- **When it shows up** (on a nameplate, under your mouse, as your target or focus, or as a group member's target), EzMark warns you in chat and on screen, plays the raid warning sound and the button glows. Friendly NPCs (guards, vendors) only have nameplates when friendly NPC nameplates are turned on in the game's options, so until then EzMark only notices them under your mouse or as a target
- **Press the button, or your key,** to target the NPC and mark it. Set the key under Key Bindings > AddOns > EzMark. You can press it as often as you like: if the NPC isn't in view, your target stays as it was
- **Right-click the button** or type **`/mark unwatch`** to stop watching
- **`/mark watch icon <icon>`** changes the watch marker (skull by default), **`/mark watch sound on|off`** the alert sound, **`/mark watch reset`** puts the button back. **Shift-drag** the button to move it
- **`/mark watch`** shows what's being watched and the settings

The game only lets you target with your own key press or click, so EzMark never targets anything by itself. Marking needs a press too, so the button or key does both.

## Map coordinates in chat

Someone says "rare at 45.2, 67.8"? The numbers turn blue: **click** them and a pin goes on your map, with the arrow pointing the way. Click again to take the pin off.

- **Which map:** if the line names a zone ("Westfall 56, 47", "/way Elwynn Forest 45 67"), that zone. From your party or raid, the sender's zone. Otherwise your own zone
- **What counts:** two numbers from 0 to 100, with a comma between them or decimals ("45, 67", "45.2 67.8"). Two whole numbers with only a space between them ("45 67") count after "at", "@", "coords", "/way" or a zone name, in brackets, or alone on the line, so "I have 45 67 problems" stays as typed
- **Hover** shows the zone and coordinates. **Shift-click** while typing puts "Zone 45.2, 67.8" in your line, so anyone can read it
- **`/mark coords off`** leaves coordinates as typed (`on` to bring it back)

## Good to know

- **Your target changes:** Alt+click targets the player so it can mark them, the same way a `/targetexact` macro would. They stay targeted, which also helps you find them
- **Range:** the player has to be in view. If they aren't, EzMark says so and your target is cleared
- **Groups:** solo or in a party you can always mark. In a raid you need to be leader or assistant
- **Who sees it:** markers are shown to you and your group only
- **Combat:** Alt+click doesn't work during combat (the game locks targeting buttons), so a click on a name opens a whisper as usual
