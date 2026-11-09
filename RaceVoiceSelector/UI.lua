-- UI: one small movable window built from stock Blizzard templates.
local _, ns = ...
local S = ns.S

local f = CreateFrame("Frame", "RaceVoiceSelectorFrame", UIParent, "BasicFrameTemplateWithInset")
f:SetSize(260, 230)
f:SetPoint("CENTER")
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetClampedToScreen(true)
f:Hide()
tinsert(UISpecialFrames, f:GetName()) -- Escape closes it

f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
f.title:SetPoint("TOP", 0, -5)
f.title:SetText("Voicebound")

local function Label(text, y)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 16, y)
    fs:SetText(text)
end

local function Dropdown(y, setup)
    local dd = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
    dd:SetPoint("TOPLEFT", 110, y + 4)
    dd:SetWidth(130)
    dd:SetupMenu(setup)
    return dd
end

Label("Voice Race", -36)
local raceDD = Dropdown(-36, function(_, root)
    root:SetScrollMode(300)
    for _, r in ipairs(ns.RACES) do
        root:CreateRadio(r.name, function() return S.race == r.id end, function() S.race = r.id; ns.Apply() end)
    end
end)

Label("Voice Gender", -70)
local sexDD = Dropdown(-70, function(_, root)
    root:CreateRadio("Male", function() return S.sex == 0 end, function() S.sex = 0; ns.Apply() end)
    root:CreateRadio("Female", function() return S.sex == 1 end, function() S.sex = 1; ns.Apply() end)
end)

local cb = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
cb:SetPoint("TOPLEFT", 12, -98)
cb.Text:SetText("Enable Voice Override")
cb:SetScript("OnClick", function(self)
    S.enabled = self:GetChecked()
    ns.Apply()
end)

local status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
status:SetPoint("TOPLEFT", 18, -136)
status:SetWidth(224)
status:SetJustifyH("LEFT")

local testIndex = 0
local test = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
test:SetSize(110, 24)
test:SetPoint("BOTTOMLEFT", 16, 14)
test:SetText("Test Voice")
test:SetScript("OnClick", function()
    testIndex = testIndex % #ns.TESTS + 1 -- each click tries the next line
    ns.Test(ns.TESTS[testIndex])
end)

local close = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
close:SetSize(110, 24)
close:SetPoint("BOTTOMRIGHT", -16, 14)
close:SetText("Close")
close:SetScript("OnClick", function() f:Hide() end)

function ns.SetStatus(text) status:SetText(text) end

-- entry: { key, label } from ns.TESTS
function ns.Test(entry)
    local key, label = entry[1], entry[2]
    local who = ns.RaceName(S.race) .. (S.sex == 1 and " Female" or " Male")
    local ok = ns.Play(S.race, S.sex, key)
    local msg = ok and ("Played: " .. who .. " - " .. label)
                    or ("No sound for " .. who .. " - " .. label)
    ns.SetStatus(msg)
    if not f:IsShown() then ns.Print(msg) end
end

function ns.Refresh()
    raceDD:GenerateMenu()
    sexDD:GenerateMenu()
    cb:SetChecked(S.enabled)
end

function ns.Toggle()
    if f:IsShown() then f:Hide() else ns.Refresh(); f:Show() end
end

f:SetScript("OnShow", function() ns.Refresh(); ns.SetStatus("Click Test Voice to hear each voice line.") end)
