<p align="center"><img src="branding/curseforge-logo-400.png" width="160" alt="Voicebound icon"></p>

<h1 align="center">Voicebound</h1>
<p align="center"><b>Having an identity crisis? Give your character any race's voice.</b><br>A World of Warcraft Forever addon. Troll body, Dwarf soul.</p>

Voicebound swaps your own character's voice lines to another race's original Blizzard recordings, male or female. That covers the "Not enough energy!" and "Out of range" error lines and the voiced emotes. Only you hear the change, and it lasts for your play session.

## Install

1. Download the latest zip from [Releases](https://github.com/EkisWasTaken/Voicebound/releases), or clone this repo.
2. Copy the `RaceVoiceSelector` folder to `World of Warcraft/_forever_/Interface/AddOns/`.
3. `/reload` in game, then click the Voicebound minimap button or type `/rvs`.

Full usage, the list of replaced lines, how it works and known limitations: [RaceVoiceSelector/README.md](RaceVoiceSelector/README.md).

## Repo layout

| Path | What it is |
|---|---|
| `RaceVoiceSelector/` | The addon itself (this folder is what goes in `AddOns`) |
| `RaceVoiceSelector/tools/gen_voicemapping.py` | Regenerates `VoiceMapping.lua` from the game's DB2 tables (dev only, not shipped) |
| `branding/` | Icon source, CurseForge logo, CurseForge page text and release guide |
