--------------------------------------------------------------------------
-- PetSmart: Feeding/FeedButton.lua
-- The on-screen Feed Pet icon: happiness border, tooltip, and the food panel.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local BUTTON_SIZE = ns.BUTTON_SIZE
local BuildFoodList = ns.BuildFoodList
local COLUMNS = ns.COLUMNS
local GetFeedSpellName = ns.GetFeedSpellName
local MAX_BUTTONS = ns.MAX_BUTTONS
local PADDING = ns.PADDING
local Tame = ns.Tame

----------------------------------------------------------------------
-- UI: toggle icon
----------------------------------------------------------------------
local BORDER_THICKNESS = 3
local panel -- forward declaration; the food panel frame is created below,
local toggle = CreateFrame("Button", "PetSmartToggleButton", UIParent)
toggle:SetSize(40, 40)
toggle:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
toggle:SetFrameStrata("MEDIUM")
toggle:SetClampedToScreen(true)
toggle:SetMovable(true)
toggle:RegisterForDrag("LeftButton")
toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
toggle:Hide()

-- Colored border frame: sits behind the icon; a strip of it shows on all
-- four sides as a happiness-colored ring around the button.
local border = CreateFrame("Frame", nil, toggle)
border:SetAllPoints()
border:SetFrameLevel(math.max(toggle:GetFrameLevel() - 1, 0))

border.tex = border:CreateTexture(nil, "BACKGROUND")
border.tex:SetAllPoints()
border.tex:SetColorTexture(0x80 / 255, 0x80 / 255, 0x80 / 255, 1) -- neutral grey until happiness data is available (#808080, matches NEUTRAL_BORDER_COLOR below)

toggle.icon = toggle:CreateTexture(nil, "ARTWORK")
toggle.icon:SetPoint("TOPLEFT", BORDER_THICKNESS, -BORDER_THICKNESS)
toggle.icon:SetPoint("BOTTOMRIGHT", -BORDER_THICKNESS, BORDER_THICKNESS)
toggle.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
toggle:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
toggle:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

-- Round the corners of both the border and the icon using a shared
-- rounded-rect alpha mask shipped with the addon.
local MASK_PATH = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\RoundMask"

local borderMask = border:CreateMaskTexture()
borderMask:SetTexture(MASK_PATH, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
borderMask:SetAllPoints(border.tex)
border.tex:AddMaskTexture(borderMask)

local iconMask = toggle:CreateMaskTexture()
iconMask:SetTexture(MASK_PATH, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
iconMask:SetAllPoints(toggle.icon)
toggle.icon:AddMaskTexture(iconMask)

-- Icon size (Options panel): the icon/border textures are anchored to
-- `toggle` itself (TOPLEFT/BOTTOMRIGHT with a fixed border inset, or
-- SetAllPoints), so simply resizing the button scales everything else
-- along with it.
local function ApplyIconSize()
    local size = (ns.profile and ns.profile.iconSize) or 40
    toggle:SetSize(size, size)
end

----------------------------------------------------------------------
-- Happiness border color
----------------------------------------------------------------------
-- Classic-style happiness (1 = Unhappy, 2 = Content, 3 = Happy). Some
-- client versions removed GetPetHappiness entirely; if it's missing the
-- border just stays neutral grey instead of erroring.
local HAPPINESS_COLOR = {
    [1] = { 0x9c / 255, 0x00 / 255, 0x00 / 255 }, -- Unhappy - #9c0000
    [2] = { 0xbd / 255, 0xad / 255, 0x00 / 255 }, -- Content  - #bdad00
    [3] = { 0x0d / 255, 0x7a / 255, 0x2b / 255 }, -- Happy    - #0d7a2b
}
local HAPPINESS_LABEL = { [1] = "Unhappy", [2] = "Content", [3] = "Happy" }
-- Shown instead of a happiness color whenever there's nothing to report
-- one (no pet out, or the happiness API/data isn't available) - a neutral
-- grey ring rather than no ring at all, so the border always shows
-- something instead of silently vanishing.
local NEUTRAL_BORDER_COLOR = { 0x80 / 255, 0x80 / 255, 0x80 / 255 } -- #808080

-- Newer clients moved this off the global namespace and onto the
-- C_PetInfo table; fall back to the old global if that doesn't exist.
local function GetHappinessState()
    if C_PetInfo and C_PetInfo.GetPetHappiness then
        return C_PetInfo.GetPetHappiness()
    end
    if GetPetHappiness then
        return GetPetHappiness()
    end
    return nil
end

local function UpdateHappiness()
    -- Grey out the icon whenever there's no active pet to feed.
    if UnitExists("pet") then
        toggle.icon:SetVertexColor(1, 1, 1)
        toggle.hasPet = true
    else
        toggle.icon:SetVertexColor(0.4, 0.4, 0.4)
        toggle.hasPet = false
        if panel:IsShown() then panel:Hide() end
    end

    if not UnitExists("pet") then
        border.tex:SetColorTexture(NEUTRAL_BORDER_COLOR[1], NEUTRAL_BORDER_COLOR[2], NEUTRAL_BORDER_COLOR[3], 1) -- grey: no pet out
        border.state = nil
        return
    end
    local state = GetHappinessState()
    if not state then
        border.tex:SetColorTexture(NEUTRAL_BORDER_COLOR[1], NEUTRAL_BORDER_COLOR[2], NEUTRAL_BORDER_COLOR[3], 1) -- grey: no happiness API/data available
        border.state = nil
        return
    end
    local c = HAPPINESS_COLOR[state] or HAPPINESS_COLOR[2]
    border.tex:SetColorTexture(c[1], c[2], c[3], 1)
    border.state = state
end

----------------------------------------------------------------------
-- Loyalty (shown in the tooltip only, e.g. "Loyalty: Best Friend")
----------------------------------------------------------------------
-- C_PetInfo.GetPetLoyalty() returns the rank name as a string directly
-- (not a number to look up). The 6 ranks, lowest to highest:
--   1 Rebellious, 2 Unruly, 3 Submissive/Compliant, 4 Dependable,
--   5 Faithful, 6 Best Friend
-- Kept only as a fallback in case a future client instead returns a
-- plain numeric rank.
local LOYALTY_LABEL = {
    [1] = "Rebellious",
    [2] = "Unruly",
    [3] = "Submissive",
    [4] = "Dependable",
    [5] = "Faithful",
    [6] = "Best Friend",
}

local function GetLoyaltyLabel()
    if not (C_PetInfo and C_PetInfo.GetPetLoyalty) then return nil end
    local result = C_PetInfo.GetPetLoyalty()
    if type(result) == "string" and result ~= "" then
        return result
    end
    if type(result) == "number" then
        return LOYALTY_LABEL[result] or ("Level " .. tostring(result))
    end
    return nil
end

-- Pulled out of OnEnter so the middle-click handler can also call it, to
-- immediately drop the "Middle-click: Untrack ..." line the moment a rare
-- is untracked while the tooltip is still open (otherwise it would keep
-- showing that option, stale, until the mouse left and re-entered).
local function ShowToggleTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("PetSmart")
    local petName = (ns.profile.tooltipShowName and UnitExists("pet")) and UnitName("pet") or nil
    if petName and petName ~= "" then
        local pr, pg, pb = 0x56 / 255, 0x99 / 255, 0x65 / 255 -- #569965
        GameTooltip:AddLine(petName, pr, pg, pb)
        local fs = _G["GameTooltipTextLeft" .. GameTooltip:NumLines()]
        if fs then
            if GameTooltipHeaderText then
                fs:SetFontObject(GameTooltipHeaderText)
            end
            fs:SetTextColor(pr, pg, pb) -- re-apply after font object, which resets color
        end
    end
    if ns.profile.tooltipShowHappiness and border.state then
        GameTooltip:AddLine("Happiness: " .. (HAPPINESS_LABEL[border.state] or "Unknown"), 1, 1, 1)
    end
    if ns.profile.tooltipShowLoyalty and UnitExists("pet") then
        GameTooltip:AddLine("Loyalty: " .. (GetLoyaltyLabel() or "Unknown"), 1, 1, 1)
    end
    GameTooltip:AddLine("Left-click: Feed Pet", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Open/Close Compendium", 1, 1, 1)
    local untrackCount, untrackName = Tame.UntrackTarget()
    if untrackCount == 1 then
        GameTooltip:AddLine("Middle-click: Untrack " .. untrackName, 1, 1, 1)
    elseif untrackCount > 1 then
        GameTooltip:AddLine(("Middle-click: Untrack All (%d)"):format(untrackCount), 1, 1, 1)
    end
    GameTooltip:AddLine("Shift-drag: move", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end
toggle:SetScript("OnEnter", ShowToggleTooltip)
toggle:SetScript("OnLeave", function() GameTooltip:Hide() end)

----------------------------------------------------------------------
-- UI: food panel
----------------------------------------------------------------------
local panelTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
panel = CreateFrame("Frame", "PetSmartPanel", UIParent, panelTemplate)
panel:SetFrameStrata("DIALOG")
panel:SetClampedToScreen(true)
-- Without this, empty/backdrop areas of the panel (anywhere that isn't
-- itself a button) let clicks fall straight through to whatever's behind
-- them - including the 3D world, which both clicked that NPC/object and
-- (via the WorldFrame hook below) closed the panel on the same click.
panel:EnableMouse(true)
panel:Hide()
if panel.SetBackdrop then
    panel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    panel:SetBackdropColor(0, 0, 0, 0.9)
end

panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
panel.title:SetPoint("TOPLEFT", 10, -8)

panel.empty = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
panel.empty:SetPoint("TOPLEFT", 10, -30)
panel.empty:SetText("No suitable pet food in your bags.")
panel.empty:Hide()

local buttons = {}
ns.pendingRefresh = false

local function CreateFoodButton(index)
    local b = CreateFrame("Button", "PetSmartFoodButton" .. index, panel, "SecureActionButtonTemplate")
    b:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "macro")

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    b.count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    b.count:SetPoint("BOTTOMRIGHT", -2, 2)

    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    b:SetScript("OnEnter", function(self)
        if not self.link then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:AddLine("Pet food: " .. (self.ftype or "?"), 0.3, 1, 0.6)
        GameTooltip:AddLine("Click to feed your pet", 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Close the panel after a feed click (only possible out of combat)
    b:SetScript("PostClick", function()
        if not InCombatLockdown() then panel:Hide() end
    end)
    return b
end

local function RefreshPanel()
    if InCombatLockdown() then
        ns.pendingRefresh = true
        return
    end
    ns.pendingRefresh = false

    local spell = GetFeedSpellName()
    local list = BuildFoodList()
    if #list > MAX_BUTTONS then
        for i = #list, MAX_BUTTONS + 1, -1 do list[i] = nil end
    end

    for i, item in ipairs(list) do
        local b = buttons[i] or CreateFoodButton(i)
        buttons[i] = b
        local col = (i - 1) % COLUMNS
        local row = math.floor((i - 1) / COLUMNS)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", panel, "TOPLEFT",
            PADDING + 6 + col * (BUTTON_SIZE + PADDING),
            -(26 + row * (BUTTON_SIZE + PADDING)))
        b.icon:SetTexture(item.icon)
        b.count:SetText(item.count > 1 and item.count or "")
        b.link, b.ftype = item.link, item.ftype
        -- Feed Pet puts the cursor into "target an item" mode; /use then targets the bag slot.
        b:SetAttribute("macrotext", string.format("/cast %s\n/use %d %d", spell, item.bag, item.slot))
        b:Show()
    end
    for i = #list + 1, #buttons do buttons[i]:Hide() end

    local petName = UnitExists("pet") and UnitName("pet") or nil
    panel.title:SetText(petName and ("Feed " .. petName) or "Feed Pet")

    local cols = math.max(1, math.min(COLUMNS, #list))
    local rows = math.max(1, math.ceil(#list / COLUMNS))
    if #list == 0 then
        panel.empty:SetText(UnitExists("pet") and "No suitable pet food in your bags." or "You have no pet summoned.")
        panel.empty:Show()
        panel:SetSize(200, 52)
    else
        panel.empty:Hide()
        panel:SetSize(cols * (BUTTON_SIZE + PADDING) + PADDING + 12, rows * (BUTTON_SIZE + PADDING) + 32)
    end
end

panel:SetScript("OnShow", RefreshPanel)
tinsert(UISpecialFrames, "PetSmartPanel") -- ESC closes it

-- Exported for the other PetSmart files.
ns.ApplyIconSize = ApplyIconSize
ns.GetLoyaltyLabel = GetLoyaltyLabel
ns.RefreshPanel = RefreshPanel
ns.ShowToggleTooltip = ShowToggleTooltip
ns.UpdateHappiness = UpdateHappiness
ns.panel = panel
ns.panelTemplate = panelTemplate
ns.toggle = toggle
