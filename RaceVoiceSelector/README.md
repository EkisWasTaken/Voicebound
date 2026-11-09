# Voicebound: speak with any race's voice (WoW Forever)

Your character speaks with another race's voice for the current play session. Example: a Troll whose "Not enough energy!" and `/laugh` come out in a Dwarf voice.
This only changes what **you** hear from your own character. It uses the game's original recordings only. It changes no game files and needs no server changes or outside programs.

## Install

1. Copy the `RaceVoiceSelector` folder to `World of Warcraft/_forever_/Interface/AddOns/`.
2. Restart the game or type `/reload`.
3. If the character screen lists it as *out of date*, tick **Load out of date AddOns**. The `.toc` declares interface `16001`, the same as the other Forever addons installed.

## Use

| Command | What it does |
|---|---|
| `/rvs` or `/voicebound` | Open or close the window |
| `/rvs on` / `/rvs off` | Turn the voice override on or off |
| `/rvs reset` | Go back to your character's own race and gender, with the override off |
| `/rvs race dwarf` | Choose the voice race (`human orc dwarf nightelf undead tauren gnome troll`) |
| `/rvs gender male` | Choose male or female recordings |
| `/rvs minimap` | Hide or show the minimap button |
| `/rvs test energy` | Play one line whose name contains that word (extra command, for testing) |

**Minimap button:** left-click opens the window, right-click turns the voice on or off, and dragging moves it around the minimap. Hover over it to see the current voice.

**Window:** pick a race and gender, then tick **Enable Voice Override**.
**Test Voice** plays the next line on each click: the common error lines first ("Not enough energy", "Out of range", …), then the emotes. The line under the checkbox shows what played.

Voice settings last for this session only, so logging out returns you to your own voice. Only the minimap button's position is saved.

## What gets replaced

**All of your character's error voice lines** (about 49 per race), including:
- Not enough energy, rage or mana
- Out of range, and "I can't do that yet" (ability or spell not ready)
- No target or invalid target
- Inventory full, can't loot, can't use or equip that

**Voiced emotes:** Laugh, Joke, Cheer, Cry, Sigh, Yes (`/nod`), No, Attack, Incoming, Flee, Heal, Thank, Goodbye. These work from the slash command, the emote menu and voice macros.

**Not replaced:** combat sounds such as attack grunts, getting-hit and death cries, and spell shouts. No addon hook exists for those.

## How replacement works

WoW Forever runs a Classic-numbered client (1.60) on the modern engine. Addons cannot play game sounds by path any more, but they can play them by SoundKit ID (`PlaySound`). They can also silence specific sound files on their own client (`MuteSoundFile`).

**Error lines.** When an error happens, Blizzard's own UI code (`UIErrorsFrame`) calls `C_Sound.PlayVocalErrorSound(id)` (`PlayVocalErrorSoundID` on older clients; the addon hooks whichever exists). That plays your race's line for that error.
While the override is on, the addon keeps all of your native error recordings muted. It also hooks that call and plays the chosen race's recording for the same `id`.
Error lines only ever play for your own character, so the mute affects nobody else's sounds. Turning the override off, `/rvs reset` and logging out all unmute.

**Emotes.** The addon hooks `C_ChatInfo.PerformEmote` / `DoEmote`. It mutes your native line for that emote for 3 seconds, which covers the server round-trip, and plays the chosen race's line. If the chosen race has no line for an emote, nothing changes.

All sound IDs in `VoiceMapping.lua` come from the WoW Forever client's own tables (build 1.60.1.70862), downloaded from wago.tools: `VocalUISounds` and `EmotesTextSound` (race/gender/line → SoundKit), and `SoundKitEntry` (SoundKit → sound files).
To regenerate after a patch: download `EmotesText`, `EmotesTextSound`, `VocalUISounds` and `SoundKitEntry` as CSV from `https://wago.tools/db2/<Table>/csv?build=<your build>` into `tools/`. Then run `python tools/gen_voicemapping.py VoiceMapping.lua`.

## Known limitations

- **Not tested in the real client yet.** The logic was tested against stand-in game functions. The first thing to check in game is that you hear only the new voice, never both.
- **Same-race emotes nearby.** For 3 seconds after *your* emote, the same emote from a nearby player of your own race and gender is silent on your client. This doesn't happen for error lines.
- **Restricted moments may go silent.** Midnight can hide some values from addons during restricted moments. If that ever hides an error line's ID, that one line is silent rather than doubled.
- **Missing lines go silent.** If the chosen race has no recording for a given error, that line is silent while the override is on. All 8 races have nearly the same set (48–50 lines).
- **Only the 8 classic races.** WoW Forever ships voice data only for Human, Orc, Dwarf, Night Elf, Undead, Tauren, Gnome and Troll.
- **Possible data drift.** The data matches build 1.60.1.70862. If a later patch changes the tables, regenerate.
