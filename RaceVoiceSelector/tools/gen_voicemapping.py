"""Generate VoiceMapping.lua from wago.tools DB2 CSVs (EmotesText, EmotesTextSound, SoundKitEntry)."""
import csv, sys, os

here = os.path.dirname(os.path.abspath(__file__))
out = sys.argv[1]

def rows(name):
    return csv.DictReader(open(os.path.join(here, name + ".csv"), encoding="utf-8"))

# Priority emotes, keyed by EmotesText.Name (= the DoEmote token).
WANT = ["LAUGH", "JOKE", "CHEER", "CRY", "SIGH", "NOD", "NO", "ATTACKMYTARGET",
        "INCOMING", "FLEE", "HEALME", "THANK", "BYE"]
emote_id = {r["Name"]: r["ID"] for r in rows("EmotesText") if r["Name"] in WANT}
missing = set(WANT) - set(emote_id)
assert not missing, missing
id_emote = {v: k for k, v in emote_id.items()}

# (race, sex, emote) -> soundkit; prefer ClassID 0 (generic) over class-specific rows.
kits = {}
for r in rows("EmotesTextSound"):
    e = id_emote.get(r["EmotesTextID"])
    if not e:
        continue
    key = (int(r["RaceID"]), int(r["SexID"]), e)
    if key not in kits or r["ClassID"] == "0":
        kits[key] = int(r["SoundID"])

need = set(kits.values())
files = {}
for r in rows("SoundKitEntry"):
    k = int(r["SoundKitID"])
    if k in need:
        files.setdefault(k, []).append(int(r["FileDataID"]))

races = sorted({k[0] for k in kits})
L = ["-- GENERATED from DB2 tables EmotesText / EmotesTextSound / SoundKitEntry (wago.tools).",
     "-- VOICES[raceID][sex][EMOTE] = { kit = SoundKitID, files = { FileDataID, ... } }",
     "-- sex: 0 = male, 1 = female (DB2 convention). Do not hand-edit; regenerate.",
     "local _, ns = ...", "local V = {}", "ns.VOICES = V"]
for race in races:
    L.append(f"V[{race}] = {{")
    for sex in (0, 1):
        L.append(f"  [{sex}] = {{")
        for e in WANT:
            k = kits.get((race, sex, e))
            if k:
                f = ", ".join(map(str, sorted(files.get(k, []))))
                L.append(f"    {e} = {{ kit = {k}, files = {{ {f} }} }},")
        L.append("  },")
    L.append("}")
print(f"emotes: {len(races)} races, {len(kits)} entries")

# Error voice lines ("Not enough energy", ...) from VocalUISounds.
# NormalSoundID_0 = male kit, NormalSoundID_1 = female kit; VocalUIEnum = the id
# Blizzard's UIErrorsFrame passes to C_Sound.PlayVocalErrorSound.
err = {}       # (race, sex) -> {enum: kit}   (generic ClassID 0 rows win)
err_all = {}   # (race, sex) -> every kit, incl. class-specific (Demon Hunter) voices, for muting
for r in rows("VocalUISounds"):
    race, enum = int(r["RaceID"]), int(r["VocalUIEnum"])
    for sex in (0, 1):
        k = int(r[f"NormalSoundID_{sex}"])
        if not k:
            continue
        err_all.setdefault((race, sex), set()).add(k)
        d = err.setdefault((race, sex), {})
        if enum not in d or r["ClassID"] == "0":
            d[enum] = k
need = set().union(*err_all.values()) - set(files)
for r in rows("SoundKitEntry"):
    k = int(r["SoundKitID"])
    if k in need:
        files.setdefault(k, []).append(int(r["FileDataID"]))

L += ["", "-- ERROR_VOICES[raceID][sex][vocalErrorSoundID] = SoundKitID",
      "-- ERROR_MUTE[raceID][sex] = every FileDataID of that voice's error lines",
      "local E, M = {}, {}", "ns.ERROR_VOICES, ns.ERROR_MUTE = E, M"]
for race in sorted({k[0] for k in err}):
    L.append(f"E[{race}] = {{")
    for sex in (0, 1):
        d = err.get((race, sex), {})
        L.append(f"  [{sex}] = {{ " + ", ".join(f"[{e}] = {d[e]}" for e in sorted(d)) + " },")
    L.append("}")
    L.append(f"M[{race}] = {{")
    for sex in (0, 1):
        ids = sorted({f for k in err_all.get((race, sex), ()) for f in files.get(k, [])})
        L.append(f"  [{sex}] = {{ " + ", ".join(map(str, ids)) + " },")
    L.append("}")
open(out, "w", encoding="utf-8", newline="\n").write("\n".join(L) + "\n")
print(f"errors: {len(err)} race/sex voices -> {out}")
