-- Minimap button: left-click opens the window, right-click toggles the override,
-- drag to move it around the minimap. Position/visibility are saved in VoiceboundDB.
-- Layout numbers follow the common LibDBIcon look so it matches other addons' buttons.
local _, ns = ...
local S = ns.S

local b = CreateFrame("Button", "VoiceboundMinimapButton", Minimap)
b:SetSize(31, 31)
b:SetFrameStrata("MEDIUM")
b:SetFrameLevel(8)
b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
b:RegisterForDrag("LeftButton")
b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local bg = b:CreateTexture(nil, "BACKGROUND")
bg:SetSize(24, 24)
bg:SetPoint("CENTER")
bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

local icon = b:CreateTexture(nil, "ARTWORK")
icon:SetSize(20, 20)
icon:SetPoint("CENTER")
icon:SetTexture("Interface\\AddOns\\RaceVoiceSelector\\Media\\icon")
icon:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- crop the square gold frame; the round border replaces it
if b.CreateMaskTexture then
    local mask = b:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    icon:AddMaskTexture(mask)
end

local border = b:CreateTexture(nil, "OVERLAY")
border:SetSize(50, 50)
border:SetPoint("TOPLEFT")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local db -- VoiceboundDB.minimap, set on login

local function Place()
    local a = math.rad(db.angle)
    local r = Minimap:GetWidth() / 2 + 10
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function FollowCursor()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local s = Minimap:GetEffectiveScale()
    db.angle = math.deg(math.atan2(py / s - my, px / s - mx))
    Place()
end

b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", FollowCursor) end)
b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

function ns.ToggleOverride()
    S.enabled = not S.enabled
    ns.Apply()
    ns.Refresh()
    ns.Print("voice override " .. (S.enabled and "ON" or "OFF"))
end

b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then ns.ToggleOverride() else ns.Toggle() end
end)

b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Voicebound")
    local voice = ns.RaceName(S.race) .. (S.sex == 1 and " Female" or " Male")
    GameTooltip:AddLine(voice .. (S.enabled and "  |cff00ff00ON|r" or "  |cffff4040OFF|r"), 1, 1, 1)
    GameTooltip:AddLine("Left-click: open window", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Right-click: turn voice on/off", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Drag: move button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
b:SetScript("OnLeave", function() GameTooltip:Hide() end)

function ns.ToggleMinimapButton()
    db.hide = not db.hide
    b:SetShown(not db.hide)
    ns.Print("minimap button " .. (db.hide and "hidden (/rvs minimap to show)" or "shown"))
end

-- Addon compartment (the addon list button by the minimap on newer clients); ignored if absent.
function Voicebound_OnCompartmentClick(_, button)
    if button == "RightButton" then ns.ToggleOverride() else ns.Toggle() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    VoiceboundDB = VoiceboundDB or {}
    VoiceboundDB.minimap = VoiceboundDB.minimap or { angle = 200, hide = false }
    db = VoiceboundDB.minimap
    Place()
    b:SetShown(not db.hide)
end)
