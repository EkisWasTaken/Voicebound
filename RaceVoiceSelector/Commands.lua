-- Commands: /rvs [on|off|reset|race <name>|gender <male|female>|test [emote]]
local _, ns = ...
local S = ns.S

local function Describe()
    return ns.RaceName(S.race) .. (S.sex == 1 and " Female" or " Male") .. ", override " .. (S.enabled and "ON" or "OFF")
end

local function RaceKeys()
    local t = {}
    for _, r in ipairs(ns.RACES) do t[#t + 1] = r.key end
    return table.concat(t, ", ")
end

SLASH_RACEVOICESELECTOR1 = "/rvs"
SLASH_RACEVOICESELECTOR2 = "/voicebound"
SlashCmdList.RACEVOICESELECTOR = function(msg)
    local cmd, arg = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if cmd == "" then ns.Toggle(); return end

    if cmd == "on" then
        S.enabled = true
    elseif cmd == "off" then
        S.enabled = false
    elseif cmd == "reset" then
        S.enabled = false
        ns.ResetToNative()
    elseif cmd == "race" then
        local r = ns.FindRace(arg)
        if not r then ns.Print("unknown race '" .. arg .. "'. Use one of: " .. RaceKeys()); return end
        S.race = r.id
    elseif cmd == "gender" then
        if arg == "male" then S.sex = 0
        elseif arg == "female" then S.sex = 1
        else ns.Print("use /rvs gender male|female"); return end
    elseif cmd == "test" then
        -- "/rvs test energy" or "/rvs test laugh": first line whose label contains the text
        local pick = ns.TESTS[1]
        for _, t in ipairs(ns.TESTS) do
            if arg ~= "" and t[2]:lower():find(arg, 1, true) then pick = t; break end
        end
        ns.Test(pick)
        return
    elseif cmd == "minimap" then
        ns.ToggleMinimapButton()
        return
    else
        ns.Print("commands: /rvs, on, off, reset, race <name>, gender <male|female>, test [line], minimap")
        return
    end
    ns.Apply()
    ns.Refresh()
    ns.Print(Describe())
end
