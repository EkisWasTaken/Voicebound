-- Core: session state + voice replacement for your own character.
--
-- Two kinds of voice lines are replaced (see README "How replacement works"):
--   * Error lines ("Not enough energy", ...): Blizzard code calls C_Sound.PlayVocalErrorSound(id).
--     While the override is on, your native error files stay muted (MuteSoundFile) and a
--     post-hook plays the chosen race's line for the same id.
--   * Emotes (/laugh, /cheer, ...): post-hook on C_ChatInfo.PerformEmote / DoEmote mutes your
--     native line for a few seconds and plays the chosen race's line.
local addonName, ns = ...

ns.EMOTES = { "LAUGH", "JOKE", "CHEER", "CRY", "SIGH", "NOD", "NO", "ATTACKMYTARGET",
              "INCOMING", "FLEE", "HEALME", "THANK", "BYE" }
ns.EMOTE_LABEL = { LAUGH = "Laugh", JOKE = "Joke", CHEER = "Cheer", CRY = "Cry", SIGH = "Sigh",
    NOD = "Yes", NO = "No", ATTACKMYTARGET = "Attack", INCOMING = "Incoming", FLEE = "Flee",
    HEALME = "Heal", THANK = "Thank", BYE = "Goodbye" }

-- Common error voice lines (vocalErrorSoundID -> label), used by Test Voice.
-- Every error line is replaced in play; these are just the ones offered for testing.
ns.ERROR_TESTS = {
    { 64, "Not enough energy" }, { 63, "Not enough rage" }, { 15, "Not enough mana" },
    { 57, "Out of range" }, { 50, "Ability not ready" }, { 12, "Spell not ready" },
    { 45, "No target" }, { 11, "Invalid target" }, { 0, "Inventory full" },
}

-- Test Voice order: error lines first, then emotes. Entries: { key, label }
-- where key is a vocalErrorSoundID (number) or an emote token (string).
ns.TESTS = {}
for _, t in ipairs(ns.ERROR_TESTS) do ns.TESTS[#ns.TESTS + 1] = t end
for _, e in ipairs(ns.EMOTES) do ns.TESTS[#ns.TESTS + 1] = { e, ns.EMOTE_LABEL[e] } end

-- The 8 classic races: the only ones with voice data in WoW Forever (build 1.60.1).
-- Playable races offered in the UI. key = slash-command name.
ns.RACES = {
    { id = 1,  key = "human",       name = "Human" },
    { id = 2,  key = "orc",         name = "Orc" },
    { id = 3,  key = "dwarf",       name = "Dwarf" },
    { id = 4,  key = "nightelf",    name = "Night Elf" },
    { id = 5,  key = "undead",      name = "Undead" },
    { id = 6,  key = "tauren",      name = "Tauren" },
    { id = 7,  key = "gnome",       name = "Gnome" },
    { id = 8,  key = "troll",       name = "Troll" },
}

local MUTE_SECONDS = 3      -- covers server round-trip before the native voice plays
local CHANNEL = "Dialog"    -- emote voices play on the dialog channel

-- Session-only settings: no SavedVariables, so everything resets on logout.
local S = { enabled = false }
ns.S = S
ns.native = {}

local function Print(msg) print("|cffe8b84bVoicebound|r: " .. msg) end
ns.Print = Print

function ns.RaceName(id)
    for _, r in ipairs(ns.RACES) do if r.id == id then return r.name end end
    return "Race " .. tostring(id)
end

function ns.FindRace(key)
    key = key and key:lower():gsub("[%s'%-]", "")
    if key == "scourge" then key = "undead" end
    for _, r in ipairs(ns.RACES) do if r.key == key then return r end end
end

local function Voice(raceID, sex, token)
    local race = ns.VOICES[raceID]
    return race and race[sex] and race[sex][token]
end

function ns.IsOverriding()
    return S.enabled and (S.race ~= ns.native.race or S.sex ~= ns.native.sex)
end

-- Muting ----------------------------------------------------------------
local muted, muteGen = {}, 0

local function UnmuteAll()
    for id in pairs(muted) do UnmuteSoundFile(id) end
    wipe(muted)
end
ns.UnmuteAll = UnmuteAll

local function MuteFor(files)
    for _, id in ipairs(files) do
        if not muted[id] then MuteSoundFile(id); muted[id] = true end
    end
    muteGen = muteGen + 1
    local gen = muteGen
    -- only the newest emote's timer unmutes, so rapid emotes don't unmute early
    C_Timer.After(MUTE_SECONDS, function() if gen == muteGen then UnmuteAll() end end)
end

-- Playback --------------------------------------------------------------
-- key: emote token (string) or vocalErrorSoundID (number)
function ns.Play(raceID, sex, key)
    local kit
    if type(key) == "number" then
        local race = ns.ERROR_VOICES[raceID]
        kit = race and race[sex] and race[sex][key]
    else
        local v = Voice(raceID, sex, key)
        kit = v and v.kit
    end
    if not kit then return false end
    return PlaySound(kit, CHANNEL)
end

local lastToken, lastTime = nil, 0
local function OnEmote(token)
    if not ns.IsOverriding() or type(token) ~= "string" then return end
    if issecretvalue and issecretvalue(token) then return end
    token = token:upper()
    -- DoEmote may wrap PerformEmote; both hooks fire for one emote
    local now = GetTime()
    if token == lastToken and now - lastTime < 0.2 then return end
    lastToken, lastTime = token, now

    local replacement = Voice(S.race, S.sex, token)
    if not replacement then return end -- no replacement: native sound plays untouched
    local original = Voice(ns.native.race, ns.native.sex, token)
    if original and MuteSoundFile then MuteFor(original.files) end
    PlaySound(replacement.kit, CHANNEL)
end

-- Error voice lines ("Not enough energy", "I can't do that yet", ...) ---
-- Blizzard's UIErrorsFrame calls C_Sound.PlayVocalErrorSound(id), which plays your own
-- race's line. Those lines are only ever played for your own character, so we can keep
-- your native ones muted for as long as the override is on, and play the chosen race's line.
local errMuted = {}

local function UnmuteErrors()
    for id in pairs(errMuted) do UnmuteSoundFile(id) end
    wipe(errMuted)
end

-- Call after any settings change: mutes or unmutes native error lines to match.
function ns.Apply()
    UnmuteErrors()
    if not ns.IsOverriding() then ns.UnmuteAll(); return end
    local race = ns.ERROR_MUTE[ns.native.race]
    for _, id in ipairs(race and race[ns.native.sex] or {}) do
        MuteSoundFile(id); errMuted[id] = true
    end
end

local function OnVocalError(id)
    if not ns.IsOverriding() or (issecretvalue and issecretvalue(id)) then return end
    local race = ns.ERROR_VOICES[S.race]
    local kit = race and race[S.sex] and race[S.sex][id]
    if kit then PlaySound(kit, CHANNEL) end
end

-- Setup -----------------------------------------------------------------
function ns.ResetToNative()
    S.race, S.sex = ns.native.race, ns.native.sex
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then UnmuteAll(); UnmuteErrors(); return end

    local _, _, raceID = UnitRace("player")
    local sex = UnitSex("player") == 3 and 1 or 0 -- UnitSex: 2 male, 3 female; DB2: 0 male, 1 female
    ns.native.race, ns.native.sex = raceID, sex
    ns.ResetToNative()
    if not ns.VOICES[raceID] then
        Print("no voice data for your race (" .. tostring(raceID) .. "); your own voice cannot be muted.")
    end

    local hooked = false
    if C_ChatInfo and C_ChatInfo.PerformEmote then hooksecurefunc(C_ChatInfo, "PerformEmote", OnEmote); hooked = true end
    if DoEmote then hooksecurefunc("DoEmote", OnEmote); hooked = true end
    if not hooked then Print("no emote API found; emotes will not be replaced.") end
    if C_Sound and C_Sound.PlayVocalErrorSound then
        hooksecurefunc(C_Sound, "PlayVocalErrorSound", OnVocalError)
    elseif PlayVocalErrorSoundID then
        hooksecurefunc("PlayVocalErrorSoundID", OnVocalError)
    else
        Print("no vocal error API found; error voice lines will not be replaced.")
    end
    if not MuteSoundFile then Print("MuteSoundFile unavailable; you will hear both voices.") end
    f:UnregisterEvent("PLAYER_LOGIN")
end)
