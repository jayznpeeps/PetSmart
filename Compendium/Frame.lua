--------------------------------------------------------------------------
-- PetSmart: Compendium/Frame.lua
-- The Compendium window: banner, icon column, content panel, header widgets, rows, drag/resize, bag dodge.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local ApplyIconSize = ns.ApplyIconSize
local ICON_SIZE_MAX = ns.ICON_SIZE_MAX
local ICON_SIZE_MIN = ns.ICON_SIZE_MIN
local panelTemplate = ns.panelTemplate

----------------------------------------------------------------------
-- UI: pet abilities panel (right-click)
-- Sized 75% larger than the original layout, with a slightly larger
-- row font (GameFontHighlight instead of GameFontHighlightSmall), and a
-- scrollable body (mouse wheel + up/down arrow buttons) so long lists -
-- and wrapped "Usable by:" lines - are never cut off or truncated.
----------------------------------------------------------------------
----------------------------------------------------------------------
-- v1.61.0 three-panel layout:
--   * Top: logo bar - the PetSmart logo, always visible.
--   * Left: a narrow column of section icons (each section's medallion
--     artwork - the same images used as that section's watermark).
--   * Right: the content panel - shows whichever section's icon was
--     clicked (title, tabs, Back/Track buttons and the scrolling list).
-- The old "main menu" page is gone: the icon column replaces it.
----------------------------------------------------------------------
-- (Layout sizes, art paths and colours for the Compendium window.)
local LAYOUT = {
    OUTER_PAD = 6,
    LOGO_BAR_HEIGHT = 84,
    LOGO_DISPLAY_HEIGHT = 78,
    LOGO_TEXTURE = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\Logo",
    -- Logo.tga is 512x256 with the art in the top 512x169 (padded to a
    -- power-of-two height for older clients), so only that part is shown.
    LOGO_TEX_BOTTOM = 169 / 256,
    LOGO_ASPECT = 512 / 169,
    -- Banner art behind the logo: black lion left, white lion right.
    -- 2048x256 (8:1), drawn at the banner's full height; at the default
    -- window width only its middle is shown, and widening the window
    -- reveals more of the galaxy at either end.
    BANNER_TEXTURE = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\BannerBackground",
    BANNER_ASPECT = 8,
    BANNER_ALPHA = 0.70, -- faded backdrop, but stronger than the section watermarks
    BACK_TEXTURE = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\BackButton",
    BACK_SIZE = 26,
    -- Track/Untrack toggle: a trail of paw prints. Gold with a faint glow
    -- while tracked, plain grey while not.
    TRACK_ON_TEXTURE  = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\TrackPawOn",
    TRACK_OFF_TEXTURE = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\TrackPawOff",
    TRACK_WIDTH = 52, TRACK_HEIGHT = 26,
    -- Same gold paw trail, inline in list rows in place of "[Tracked]".
    TRACKED_INLINE = "|TInterface\\AddOns\\PetSmart\\Media\\UI-Elements\\TrackPawOn:12:24|t",
    NAV_COLUMN_WIDTH = 68,
    NAV_ICON_SIZE = 52,
    NAV_ICON_GAP = 10,
    COLUMN_GAP = 4,
    CONTENT_WIDTH = 455,   -- same body width the old single panel had
    CONTENT_HEIGHT = 470,
    ABILITIES_PANEL_MIN_WIDTH = 500, ABILITIES_PANEL_MIN_HEIGHT = 490, -- fits all six section icons
    ABILITIES_PANEL_MAX_WIDTH = 1200, ABILITIES_PANEL_MAX_HEIGHT = 1100,
    SUBPANEL_BACKDROP = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    },
}
local ABILITIES_PANEL_WIDTH = LAYOUT.OUTER_PAD + LAYOUT.NAV_COLUMN_WIDTH + LAYOUT.COLUMN_GAP + LAYOUT.CONTENT_WIDTH + LAYOUT.OUTER_PAD
local ABILITIES_PANEL_HEIGHT = LAYOUT.OUTER_PAD + LAYOUT.LOGO_BAR_HEIGHT + LAYOUT.COLUMN_GAP + LAYOUT.CONTENT_HEIGHT + LAYOUT.OUTER_PAD
local ROWS_TOP_OFFSET = 62 -- room for the header: title/back icon, then the tabs/subtitle and track icon
local ROW_PADDING = 3


local abilitiesPanel = CreateFrame("Frame", "PetSmartAbilitiesPanel", UIParent, panelTemplate)
abilitiesPanel:SetFrameStrata("DIALOG")
abilitiesPanel:SetClampedToScreen(true)
-- Same reasoning as panel:EnableMouse(true) above - without this, clicks
-- on empty/backdrop space fall through to the world instead of being
-- caught here.
abilitiesPanel:EnableMouse(true)
abilitiesPanel:SetSize(ABILITIES_PANEL_WIDTH, ABILITIES_PANEL_HEIGHT)
abilitiesPanel:Hide()
if abilitiesPanel.SetBackdrop then
    abilitiesPanel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    abilitiesPanel:SetBackdropColor(0, 0, 0, 0.9)
end

-- Top: logo bar. Not mouse-enabled, so clicking/dragging on it moves the
-- whole window exactly like clicking any other empty part of it.
do
    local logoBar = CreateFrame("Frame", nil, abilitiesPanel)
    logoBar:SetPoint("TOPLEFT", LAYOUT.OUTER_PAD, -LAYOUT.OUTER_PAD)
    logoBar:SetPoint("TOPRIGHT", -LAYOUT.OUTER_PAD, -LAYOUT.OUTER_PAD)
    logoBar:SetHeight(LAYOUT.LOGO_BAR_HEIGHT)

    -- Banner background (the two lions), clipped to the bar. The art is
    -- always drawn at the bar's height and centred, so the lions stay
    -- right beside the logo at any window width: when the bar is
    -- narrower than the art, only the middle slice is used (via
    -- texcoords, so nothing is squashed); when it's wider, the art sits
    -- centred and its dark faded ends meet the window background.
    local banner = logoBar:CreateTexture(nil, "BACKGROUND")
    banner:SetTexture(LAYOUT.BANNER_TEXTURE)
    banner:SetAlpha(LAYOUT.BANNER_ALPHA)
    local function LayoutBanner()
        local w, h = logoBar:GetWidth(), logoBar:GetHeight()
        if not (w and h) or w <= 0 or h <= 0 then return end
        local artW = h * LAYOUT.BANNER_ASPECT
        banner:ClearAllPoints()
        if w <= artW then
            local cut = (1 - w / artW) / 2
            banner:SetAllPoints(logoBar)
            banner:SetTexCoord(cut, 1 - cut, 0, 1)
        else
            banner:SetPoint("CENTER", logoBar, "CENTER", 0, 0)
            banner:SetSize(artW, h)
            banner:SetTexCoord(0, 1, 0, 1)
        end
    end
    logoBar:SetScript("OnSizeChanged", LayoutBanner)
    LayoutBanner()

    -- Thin frame border around the banner, matching the two panels below.
    local frameBorder = CreateFrame("Frame", nil, logoBar, panelTemplate)
    -- Exactly on the bar's edges, so its left/right borders line up with
    -- the icon column's left border and the content panel's right border
    -- below it (all three share the same OUTER_PAD inset).
    frameBorder:SetAllPoints(logoBar)
    if frameBorder.SetBackdrop then
        frameBorder:SetBackdrop({
            edgeFile = LAYOUT.SUBPANEL_BACKDROP.edgeFile, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frameBorder:SetBackdropBorderColor(0.55, 0.45, 0.3, 1)
    end

    local logoTexture = logoBar:CreateTexture(nil, "ARTWORK")
    logoTexture:SetTexture(LAYOUT.LOGO_TEXTURE)
    logoTexture:SetTexCoord(0, 1, 0, LAYOUT.LOGO_TEX_BOTTOM)
    logoTexture:SetPoint("CENTER", 0, 0)
    logoTexture:SetSize(math.floor(LAYOUT.LOGO_DISPLAY_HEIGHT * LAYOUT.LOGO_ASPECT), LAYOUT.LOGO_DISPLAY_HEIGHT)

end

-- Left: section icon column (icons are added further down, once
-- SetAbilitiesMode exists for them to call).
local navColumn = CreateFrame("Frame", nil, abilitiesPanel, panelTemplate)
navColumn:SetPoint("TOPLEFT", abilitiesPanel, "TOPLEFT", LAYOUT.OUTER_PAD, -(LAYOUT.OUTER_PAD + LAYOUT.LOGO_BAR_HEIGHT + LAYOUT.COLUMN_GAP))
navColumn:SetPoint("BOTTOMLEFT", abilitiesPanel, "BOTTOMLEFT", LAYOUT.OUTER_PAD, LAYOUT.OUTER_PAD)
navColumn:SetWidth(LAYOUT.NAV_COLUMN_WIDTH)
if navColumn.SetBackdrop then
    navColumn:SetBackdrop(LAYOUT.SUBPANEL_BACKDROP)
    navColumn:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    navColumn:SetBackdropBorderColor(0.55, 0.45, 0.3, 1)
end

-- Right: content panel. Everything the old single panel used to hold
-- (title, subtitle, tabs, Back/Track buttons, watermark, scroll list)
-- now lives in here, at the same offsets it used to have relative to
-- the whole panel. Not mouse-enabled either, so its empty space still
-- drags the window.
local contentPanel = CreateFrame("Frame", "PetSmartContentPanel", abilitiesPanel, panelTemplate)
contentPanel:SetPoint("TOPLEFT", navColumn, "TOPRIGHT", LAYOUT.COLUMN_GAP, 0)
contentPanel:SetPoint("BOTTOMRIGHT", abilitiesPanel, "BOTTOMRIGHT", -LAYOUT.OUTER_PAD, LAYOUT.OUTER_PAD)
if contentPanel.SetBackdrop then
    contentPanel:SetBackdrop(LAYOUT.SUBPANEL_BACKDROP)
    contentPanel:SetBackdropColor(0.05, 0.05, 0.08, 0.85)
    contentPanel:SetBackdropBorderColor(0.55, 0.45, 0.3, 1)
end

-- Faint section watermarks behind the content panel's list - low alpha
-- so each reads as background texture, never competing with the row
-- text drawn on top of it. Each is sized to span the content panel's
-- inner width edge-to-edge (keeping the art's square aspect ratio).
-- These are the same images the left-hand section icons use.
local function MakeWatermark(texturePath)
    local tex = contentPanel:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(texturePath)
    tex:SetPoint("CENTER", 0, -14)
    tex:SetAlpha(0.25)
    tex:Hide()
    local function UpdateSize()
        local w = contentPanel:GetWidth()
        if not w or w <= 0 then return end
        local size = math.max(80, w - 20)
        tex:SetSize(size, size)
    end
    contentPanel:HookScript("OnSizeChanged", UpdateSize)
    UpdateSize()
    return tex
end

local SECTION_ART = {
    abilities = "Interface\\AddOns\\PetSmart\\Media\\Section-Backgrounds\\AbilitiesBackground",
    training  = "Interface\\AddOns\\PetSmart\\Media\\Section-Backgrounds\\TrainingBackground",
    types     = "Interface\\AddOns\\PetSmart\\Media\\Section-Backgrounds\\PetTypesBackground",
    spawns    = "Interface\\AddOns\\PetSmart\\Media\\Section-Backgrounds\\RareSpawnsBackground",
    options   = "Interface\\AddOns\\PetSmart\\Media\\Section-Backgrounds\\OptionsBackground",
    pet       = "Interface\\AddOns\\PetSmart\\Media\\Section-Backgrounds\\PetInfoBackground",
}

-- Gear: Options and Manage Profiles.
local optionsBgTexture = MakeWatermark(SECTION_ART.options)
-- Beast medallion: Pet Types and its detail screens.
local petTypesBgTexture = MakeWatermark(SECTION_ART.types)
-- Dragon medallion: Rare Pet Spawns and its rare-detail screen.
local rareSpawnsBgTexture = MakeWatermark(SECTION_ART.spawns)
-- Paw book: Pet Abilities (Learned/Unlearned), the Abilities Index, and
-- any ability/tame-pet detail page reached from those.
local abilitiesBgTexture = MakeWatermark(SECTION_ART.abilities)
-- Elf and lion: General Training Info.
local trainingBgTexture = MakeWatermark(SECTION_ART.training)
-- Current-pet page: its own watermark (the seated black lion), slightly
-- fainter than the others, plus the page's helpers and live-update state.
local PetPage = { bg = MakeWatermark(SECTION_ART.pet) }
PetPage.bg:SetAlpha(0.20)

abilitiesPanel.title = contentPanel:CreateFontString(nil, "OVERLAY", GameFontNormalLarge and "GameFontNormalLarge" or "GameFontNormal")
abilitiesPanel.title:SetPoint("TOPLEFT", 12, -10)
-- Force left/top justification explicitly - a FontString with only a
-- single anchor point should keep that corner fixed regardless of
-- justification, but without this the "PetSmart" text visibly nudged
-- left/right by a few pixels whenever the title's full string got
-- longer or shorter switching between panels.
abilitiesPanel.title:SetJustifyH("LEFT")
abilitiesPanel.title:SetJustifyV("TOP")

-- Subheader shown on detail pages: e.g. when viewing an ability's detail
-- page reached from the Abilities Index, the ability's own name/rank (so
-- the main header can stay "Abilities Index" instead of replacing itself
-- with the ability). Sits where the Learned/Unlearned tabs would be,
-- which are never shown at the same time. Uses the same color as the
-- main title, one font size down from it (GameFontNormal vs. the
-- title's GameFontNormalLarge).
abilitiesPanel.subtitle = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
abilitiesPanel.subtitle:SetPoint("TOPLEFT", 12, -30)
abilitiesPanel.subtitle:SetJustifyH("LEFT")
abilitiesPanel.subtitle:SetJustifyV("TOP")
do
    local r, g, b = abilitiesPanel.title:GetTextColor()
    abilitiesPanel.subtitle:SetTextColor(r, g, b)
end
abilitiesPanel.subtitle:Hide()

-- Second subheader line, under the subtitle - used by the current-pet
-- page for the pet's loyalty. Same font and colour as the subtitle.
abilitiesPanel.subtitle2 = contentPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
abilitiesPanel.subtitle2:SetPoint("TOPLEFT", abilitiesPanel.subtitle, "BOTTOMLEFT", 0, -4)
abilitiesPanel.subtitle2:SetJustifyH("LEFT")
abilitiesPanel.subtitle2:SetTextColor(abilitiesPanel.subtitle:GetTextColor())
abilitiesPanel.subtitle2:Hide()

local function MakeTabButton(text, xOff, width, yOff, anchor)
    anchor = anchor or "TOPRIGHT"
    local b = CreateFrame("Button", nil, contentPanel)
    b:SetSize(width or 90, 20)
    b:SetPoint(anchor, contentPanel, anchor, xOff, yOff or -10)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.text:SetAllPoints()
    b.text:SetText(text)
    b.text:SetJustifyH(anchor == "TOPLEFT" and "LEFT" or "RIGHT")
    b:SetScript("OnEnter", function() b.text:SetTextColor(1, 1, 1) end)
    b:SetScript("OnLeave", function()
        b.text:SetTextColor(b.active and 1 or 0.6, b.active and 0.85 or 0.6, b.active and 0.2 or 0.6)
    end)
    return b
end

-- Anchored to the left (under the title) rather than the right, so they
-- don't compete for space with the fixed Back button above them.
local tabLearned   = MakeTabButton("Learned", 12, 74, -32, "TOPLEFT")
local tabUnlearned = MakeTabButton("Unlearned", 92, 90, -32, "TOPLEFT")

-- Third tab of the Pet Abilities section: the full Abilities Index.
-- (Pet Abilities and the Index share one section icon, since they share
-- the same paw-book artwork.)
local tabIndexLink = MakeTabButton("Abilities Index", 188, 130, -32, "TOPLEFT")

-- Back button: the paw-shield icon, top-right of the content panel, on
-- detail pages only (a section's own top page is reached from its icon
-- instead). It steps back one level - its destination is recomputed each
-- refresh based on the current mode (see RefreshAbilitiesPanel). It sits
-- in the static header, outside the scroll frame, so it never scrolls
-- away. Hovering brightens it and shows a "Back" tooltip.
local navBack = CreateFrame("Button", "PetSmartBackButton", contentPanel)
navBack:SetSize(LAYOUT.BACK_SIZE, LAYOUT.BACK_SIZE)
navBack:SetPoint("TOPRIGHT", contentPanel, "TOPRIGHT", -8, -4)
navBack:SetNormalTexture(LAYOUT.BACK_TEXTURE)
navBack:SetPushedTexture(LAYOUT.BACK_TEXTURE)
do
    local pushed = navBack:GetPushedTexture()
    if pushed then
        -- Nudge the icon down-right a pixel while held, like a pressed button.
        pushed:ClearAllPoints()
        pushed:SetPoint("TOPLEFT", 1, -1)
        pushed:SetPoint("BOTTOMRIGHT", 1, -1)
    end
    local glow = navBack:CreateTexture(nil, "HIGHLIGHT")
    glow:SetAllPoints()
    glow:SetTexture(LAYOUT.BACK_TEXTURE)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.5)
end
navBack:RegisterForClicks("LeftButtonUp")
navBack:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Back", 1, 1, 1)
    GameTooltip:Show()
end)
navBack:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Track/Untrack button - right side of the subheader row, shown only on
-- a rare's own detail page (see the "raredetail" mode below). Its text
-- and OnClick are refreshed every pass through RefreshAbilitiesPanel,
-- same pattern as navBack above.
local rareTrackBtn = CreateFrame("Button", "PetSmartTrackButton", contentPanel)
rareTrackBtn:SetSize(LAYOUT.TRACK_WIDTH, LAYOUT.TRACK_HEIGHT)
rareTrackBtn:SetPoint("TOPRIGHT", contentPanel, "TOPRIGHT", -6, -36) -- 6px below the back icon
rareTrackBtn:RegisterForClicks("LeftButtonUp")
rareTrackBtn.icon = rareTrackBtn:CreateTexture(nil, "ARTWORK")
rareTrackBtn.icon:SetAllPoints()
rareTrackBtn.hover = rareTrackBtn:CreateTexture(nil, "HIGHLIGHT")
rareTrackBtn.hover:SetAllPoints()
rareTrackBtn.hover:SetBlendMode("ADD")
rareTrackBtn.hover:SetAlpha(0.3)
rareTrackBtn:SetScript("OnMouseDown", function(self)
    self.icon:ClearAllPoints()
    self.icon:SetPoint("TOPLEFT", 1, -1)
    self.icon:SetPoint("BOTTOMRIGHT", 1, -1)
end)
rareTrackBtn:SetScript("OnMouseUp", function(self) self.icon:SetAllPoints() end)
rareTrackBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    -- Names what a click will do: "Track", "Untrack", or "Untrack All"
    -- (the Rare Pet Spawns list with several rares tracked).
    GameTooltip:SetText(self.tip or (self.tracked and "Untrack" or "Track"), 1, 1, 1)
    GameTooltip:Show()
end)
rareTrackBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
-- Shows the button in its tracked (gold) or not-tracked (grey) state and
-- sets the click. `tip` overrides the default "Track"/"Untrack" tooltip.
function rareTrackBtn:SetState(tracked, tip, onClick)
    self.tracked = tracked and true or false
    self.tip = tip
    local tex = self.tracked and LAYOUT.TRACK_ON_TEXTURE or LAYOUT.TRACK_OFF_TEXTURE
    self.icon:SetTexture(tex)
    self.hover:SetTexture(tex)
    self:SetScript("OnClick", onClick)
    self:Show()
    if GameTooltip:IsOwned(self) then self:GetScript("OnEnter")(self) end
end
rareTrackBtn:Hide()

-- Scrollable body: a plain ScrollFrame (no Blizzard template) with
-- PetSmart's own scrollbar. Blizzard's UIPanelScrollFrameTemplate reads
-- the scroll range back from the client and does maths on it, and on
-- newer clients that range can be a protected "secret" value once a page
-- shows secret stats - which made every page's scrolling error. Here the
-- position and range are PetSmart's own plain numbers (Scroll.offset /
-- Scroll.max), worked out from the content height each page lays out.
local scrollFrame = CreateFrame("ScrollFrame", "PetSmartAbilitiesScrollFrame", contentPanel)
scrollFrame:SetPoint("TOPLEFT", 12, -ROWS_TOP_OFFSET)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetSize(1, 1) -- resized in RefreshAbilitiesPanel

-- Recomputed every call (not cached) since the panel - and so the scroll
-- frame - can now be resized; a cached value would leave row text
-- wrapped to the panel's original width forever.
local function GetRowWidth()
    return math.max(100, math.floor(scrollFrame:GetWidth() or (LAYOUT.CONTENT_WIDTH - 42)))
end

local Scroll = { offset = 0, max = 0, contentHeight = 0, step = 32 }

-- The scrollbar: up arrow, a draggable knob on a dark track, down arrow,
-- using the standard WoW scrollbar art.
local scrollBar = CreateFrame("Slider", "PetSmartAbilitiesScrollBar", contentPanel)
scrollBar:SetOrientation("VERTICAL")
scrollBar:SetWidth(16)
scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 7, -16)
scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 7, 16)
scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
scrollBar:GetThumbTexture():SetSize(18, 24)
scrollBar:SetValueStep(1)
if scrollBar.SetObeyStepOnDrag then scrollBar:SetObeyStepOnDrag(true) end
scrollBar:SetMinMaxValues(0, 0)
scrollBar:SetValue(0)
do
    local track = scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0, 0, 0, 0.35)
end
local function ScrollArrow(name, dir)
    local b = CreateFrame("Button", name, scrollBar)
    b:SetSize(18, 16)
    if dir == "Up" then
        b:SetPoint("BOTTOM", scrollBar, "TOP", 0, 0)
    else
        b:SetPoint("TOP", scrollBar, "BOTTOM", 0, 0)
    end
    local base = "Interface\\Buttons\\UI-ScrollBar-Scroll" .. dir .. "Button-"
    b:SetNormalTexture(base .. "Up")
    b:SetPushedTexture(base .. "Down")
    b:SetDisabledTexture(base .. "Disabled")
    b:SetHighlightTexture(base .. "Highlight", "ADD")
    return b
end
scrollBar.up = ScrollArrow("PetSmartAbilitiesScrollBarUp", "Up")
scrollBar.down = ScrollArrow("PetSmartAbilitiesScrollBarDown", "Down")

-- Scroll to v pixels (clamped to 0..Scroll.max) and sync the bar.
function Scroll.Set(v)
    v = math.floor((v or 0) + 0.5)
    if v > Scroll.max then v = Scroll.max end
    if v < 0 then v = 0 end
    Scroll.offset = v
    scrollFrame:SetVerticalScroll(v)
    if not Scroll.syncing then
        Scroll.syncing = true
        scrollBar:SetValue(v)
        Scroll.syncing = false
    end
    if v > 0 then scrollBar.up:Enable() else scrollBar.up:Disable() end
    if v < Scroll.max then scrollBar.down:Enable() else scrollBar.down:Disable() end
end

-- New content height (from RefreshAbilitiesPanel): recompute the range.
function Scroll.SetContentHeight(h)
    Scroll.contentHeight = h or 0
    local frameH = scrollFrame:GetHeight()
    if not frameH or ns.AnySecret(frameH) then frameH = Scroll.frameH or 0 end
    Scroll.frameH = frameH
    Scroll.max = math.max(0, math.floor(Scroll.contentHeight - frameH + 0.5))
    scrollBar:SetMinMaxValues(0, Scroll.max)
    Scroll.Set(Scroll.offset)
end

scrollBar:SetScript("OnValueChanged", function(_, value)
    if Scroll.syncing then return end
    Scroll.syncing = true
    Scroll.Set(value)
    Scroll.syncing = false
end)
scrollBar.up:SetScript("OnClick", function() Scroll.Set(Scroll.offset - Scroll.step) end)
scrollBar.down:SetScript("OnClick", function() Scroll.Set(Scroll.offset + Scroll.step) end)
local function OnWheel(_, delta) Scroll.Set(Scroll.offset - delta * Scroll.step) end
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", OnWheel)
scrollBar:EnableMouseWheel(true)
scrollBar:SetScript("OnMouseWheel", OnWheel)
-- Window resized: the visible height changed, so the range did too.
scrollFrame:SetScript("OnSizeChanged", function() Scroll.SetContentHeight(Scroll.contentHeight) end)

-- Reusable row buttons shared by every view in this panel. Text wraps
-- (fixed width, word wrap on) so nothing runs past the panel edge, and
-- each row is re-measured and re-positioned every refresh to fit its
-- actual (possibly multi-line) height.
local rows = {}
local function GetRow(i)
    local r = rows[i]
    if r then return r end
    r = CreateFrame("Button", nil, scrollChild)
    r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    r.text:SetPoint("TOPLEFT", 2, 0)
    r.text:SetJustifyH("LEFT")
    r.text:SetJustifyV("TOP")
    r.text:SetWordWrap(true)
    r:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    rows[i] = r
    return r
end

----------------------------------------------------------------------
-- Icon Size slider (Options panel): a single persistent widget, not a
-- pooled row like the plain text lines above - it's positioned and
-- shown/hidden by hand inside the "options" branch of
-- RefreshAbilitiesPanel, same way rareTrackBtn is handled for its own
-- page. Hand-rolled rather than a Blizzard slider template so it looks
-- and behaves the same across every client this addon targets. Lets
-- the player pick any whole-pixel size instead of a fixed set of steps.
----------------------------------------------------------------------
local iconSizeSlider = CreateFrame("Slider", "PetSmartIconSizeSlider", scrollChild)
iconSizeSlider:SetOrientation("HORIZONTAL")
iconSizeSlider:SetHeight(16)
iconSizeSlider:SetHitRectInsets(0, 0, -8, -8)
iconSizeSlider:SetMinMaxValues(ICON_SIZE_MIN, ICON_SIZE_MAX)
iconSizeSlider:SetValueStep(1)
if iconSizeSlider.SetObeyStepOnDrag then iconSizeSlider:SetObeyStepOnDrag(true) end
iconSizeSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
local iconSizeSliderThumb = iconSizeSlider:GetThumbTexture()
iconSizeSliderThumb:SetSize(24, 24)

local iconSizeSliderTrack = iconSizeSlider:CreateTexture(nil, "BACKGROUND")
iconSizeSliderTrack:SetColorTexture(0, 0, 0, 0.6)
iconSizeSliderTrack:SetPoint("TOPLEFT", 0, -5)
iconSizeSliderTrack:SetPoint("BOTTOMRIGHT", 0, 5)

iconSizeSlider.label = iconSizeSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
iconSizeSlider.label:SetPoint("BOTTOMLEFT", iconSizeSlider, "TOPLEFT", 0, 2)
iconSizeSlider.label:SetJustifyH("LEFT")

iconSizeSlider.low = iconSizeSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
iconSizeSlider.low:SetPoint("TOPLEFT", iconSizeSlider, "BOTTOMLEFT", 0, -1)
iconSizeSlider.low:SetText(tostring(ICON_SIZE_MIN))

iconSizeSlider.high = iconSizeSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
iconSizeSlider.high:SetPoint("TOPRIGHT", iconSizeSlider, "BOTTOMRIGHT", 0, -1)
iconSizeSlider.high:SetText(tostring(ICON_SIZE_MAX))

iconSizeSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)
    self.label:SetText(("Icon Size: %dpx"):format(value))
    if not ns.profile or ns.profile.iconSize == value then return end
    ns.profile.iconSize = value
    ApplyIconSize()
end)
iconSizeSlider:Hide()
ns.selectedRankData = nil
ns.selectedFamilyId = nil
ns.selectedRare = nil
ns.selectedTameTeacher = nil -- the { name, family, levels, zone } mob entry behind a "tamedetail" page
ns.detailReturnMode = "unlearned" -- "unlearned" | "index" - which view "< Back" returns to from a detail page
ns.abilitiesMode = "learned" -- "learned" | "unlearned" | "index" | "detail" | "training" | "types" | "typedetail" | "spawns" | "raredetail" | "tamedetail"
local trainingInfoExpanded = {} -- [sectionIndex] = true once a General Training Info section has been expanded; sections start collapsed
local indexCategoryExpanded = {} -- [categoryName] = true once an Abilities Index section has been expanded; sections start collapsed, same as General Training Info
local savedScrollByMode = {} -- [mode] = last scroll position seen in that mode, so e.g. leaving the Abilities Index for a detail page and coming back restores where you were
-- ns.RefreshAbilitiesPanel is defined in Compendium/Refresh.lua.

----------------------------------------------------------------------
-- Free-floating panel: draggable, resizable, and both remembered across
-- hide/show and across reloads.
----------------------------------------------------------------------
local function SaveAbilitiesPanelLayout()
    local point, _, relPoint, x, y = abilitiesPanel:GetPoint()
    if point then
        ns.profile.abilitiesPanelPos = { point, relPoint, x, y }
    end
    -- Saved under a new key in v1.61.0: sizes saved by older versions were
    -- for the old single-panel layout and would be too small now.
    ns.profile.compendiumSize = { abilitiesPanel:GetWidth(), abilitiesPanel:GetHeight() }
end

-- Dragging: clicking and dragging any empty (non-button) part of the
-- panel moves it, the same way most Blizzard dialog windows work -
-- there's no separate title bar, but every row/button inside is its own
-- mouse-enabled frame, so a click on one of those never reaches this.
abilitiesPanel:SetMovable(true)
abilitiesPanel:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not ns.profile.abilitiesPanelLocked then
        self:StartMoving()
    end
end)
abilitiesPanel:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    SaveAbilitiesPanelLayout()
end)

-- Resizing: a small grip in the bottom-right corner, just past where the
-- scrollbar's own down-arrow button ends (the scroll frame is inset 30px
-- from the panel's right edge and 12px from its bottom - see its anchor
-- below - so a grip tucked into that same corner sits right under it).
abilitiesPanel:SetResizable(true)
if abilitiesPanel.SetResizeBounds then
    pcall(abilitiesPanel.SetResizeBounds, abilitiesPanel, LAYOUT.ABILITIES_PANEL_MIN_WIDTH, LAYOUT.ABILITIES_PANEL_MIN_HEIGHT, LAYOUT.ABILITIES_PANEL_MAX_WIDTH, LAYOUT.ABILITIES_PANEL_MAX_HEIGHT)
elseif abilitiesPanel.SetMinResize then
    pcall(abilitiesPanel.SetMinResize, abilitiesPanel, LAYOUT.ABILITIES_PANEL_MIN_WIDTH, LAYOUT.ABILITIES_PANEL_MIN_HEIGHT)
    if abilitiesPanel.SetMaxResize then pcall(abilitiesPanel.SetMaxResize, abilitiesPanel, LAYOUT.ABILITIES_PANEL_MAX_WIDTH, LAYOUT.ABILITIES_PANEL_MAX_HEIGHT) end
end

local resizeGrip = CreateFrame("Button", "PetSmartAbilitiesResizeGrip", abilitiesPanel)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", -3, 3)
resizeGrip:SetFrameLevel(abilitiesPanel:GetFrameLevel() + 20) -- above the content panel and its scrollbar
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeGrip:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" or ns.profile.abilitiesPanelLocked then return end
    -- StartSizing("BOTTOMRIGHT") only grows intuitively (following the
    -- mouse down and to the right) when the frame's own anchor is the
    -- opposite corner, TOPLEFT - and the panel could be anchored from any
    -- corner by now depending on how/whether it's been dragged. Re-anchor
    -- it via TOPLEFT at its current on-screen position first so resizing
    -- always behaves the same regardless of that history.
    local left, top = abilitiesPanel:GetLeft(), abilitiesPanel:GetTop()
    if left and top then
        -- GetLeft()/GetTop() are already in the same bottom-left-origin
        -- coordinate space as a BOTTOMLEFT-relative SetPoint, so these
        -- plug straight in with no further conversion.
        abilitiesPanel:ClearAllPoints()
        abilitiesPanel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end
    abilitiesPanel:StartSizing("BOTTOMRIGHT")
end)
resizeGrip:SetScript("OnMouseUp", function()
    abilitiesPanel:StopMovingOrSizing()
    SaveAbilitiesPanelLayout()
    -- Row text wraps to the scroll frame's width, which just changed -
    -- re-flow the current view at the new size instead of leaving rows
    -- wrapped to the old one.
    if ns.RefreshAbilitiesPanel then ns.RefreshAbilitiesPanel() end
end)

-- Lock (Options panel): hides the resize grip entirely and stops the
-- panel-body drag from starting (both OnMouseDown handlers above also
-- check the setting directly, so this is really just about the grip's
-- visibility - called whenever the Options toggle changes it, and once
-- at login to match whatever was saved).
local function UpdateAbilitiesPanelLockState()
    resizeGrip:SetShown(not ns.profile.abilitiesPanelLocked)
end

----------------------------------------------------------------------
-- Auto-dodge the bag frames: if opening the bags would leave them
-- overlapping the Compendium panel, slide the panel to the left of the
-- bags (horizontally only - its vertical position never changes) until
-- the bags close again, then put it right back where it was. This is a
-- purely visual, temporary nudge - it's never written to the saved
-- position, so it can't clobber whatever the player actually dragged the
-- panel to.
----------------------------------------------------------------------
local BAG_DODGE_GAP = 6
local bagDodgeSavedPoint -- {point, relativeTo, relativePoint, x, y} while dodging, else nil
local bagDodgeActive = false

--- Returns the on-screen bounding box (left, right, bottom, top) of
--- whichever bag frames are currently open, or nil if none are.
local function GetOpenBagsBounds()
    -- Newer clients can show one combined bag frame instead of one per bag.
    local combined = _G.ContainerFrameCombinedBags
    if combined and combined:IsShown() then
        local l, b, w, h = combined:GetRect()
        if l then return l, l + w, b, b + h end
    end

    local left, right, bottom, top
    local numFrames = NUM_CONTAINER_FRAMES or 13
    for i = 1, numFrames do
        local f = _G["ContainerFrame" .. i]
        if f and f:IsShown() then
            local l, b, w, h = f:GetRect()
            if l then
                left = left and math.min(left, l) or l
                right = right and math.max(right, l + w) or (l + w)
                bottom = bottom and math.min(bottom, b) or b
                top = top and math.max(top, b + h) or (b + h)
            end
        end
    end
    if left then return left, right, bottom, top end
    return nil
end

local function RestoreFromBagDodge()
    if bagDodgeActive and bagDodgeSavedPoint then
        local p = bagDodgeSavedPoint
        abilitiesPanel:ClearAllPoints()
        abilitiesPanel:SetPoint(p[1], p[2], p[3], p[4], p[5])
    end
    bagDodgeActive = false
    bagDodgeSavedPoint = nil
end

local function CheckBagDodge()
    if not abilitiesPanel:IsShown() then return end

    local bagLeft, bagRight, bagBottom, bagTop = GetOpenBagsBounds()
    if not bagLeft then
        -- No bags open anymore - put the panel back if it had been moved.
        RestoreFromBagDodge()
        return
    end

    if bagDodgeActive then
        -- Already slid out of the way for this bag-opening - leave it be
        -- until the bags close, rather than re-measuring against a
        -- position this code itself chose.
        return
    end

    local pLeft, pRight = abilitiesPanel:GetLeft(), abilitiesPanel:GetRight()
    local pBottom, pTop = abilitiesPanel:GetBottom(), abilitiesPanel:GetTop()
    if not (pLeft and bagRight) then return end

    local overlapsHorizontally = pLeft < bagRight and pRight > bagLeft
    local overlapsVertically = pBottom < bagTop and pTop > bagBottom
    if not (overlapsHorizontally and overlapsVertically) then return end

    -- Remember exactly how the panel is anchored right now so it can be
    -- restored verbatim once the bags close.
    local point, relTo, relPoint, x, y = abilitiesPanel:GetPoint()
    if not point then return end
    bagDodgeSavedPoint = { point, relTo, relPoint, x, y }
    bagDodgeActive = true

    -- Slide left just far enough to clear the bags - same vertical
    -- position, only the horizontal position changes.
    local newLeft = bagLeft - BAG_DODGE_GAP - abilitiesPanel:GetWidth()
    abilitiesPanel:ClearAllPoints()
    abilitiesPanel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newLeft, pTop)
end

-- Bag frames are created/shown through several different code paths across
-- client versions (combined bag frame, per-bag ContainerFrameN, Classic vs
-- Retail toggling), so rather than chase down every one of them, just poll
-- lightly while the Compendium panel is actually on screen.
local bagDodgeWatcher = CreateFrame("Frame")
do
    local elapsedSince = 0
    bagDodgeWatcher:SetScript("OnUpdate", function(_, elapsed)
        if not abilitiesPanel:IsShown() then return end
        elapsedSince = elapsedSince + elapsed
        if elapsedSince < 0.2 then return end
        elapsedSince = 0
        CheckBagDodge()
    end)
end

-- Shrink the title/subtitle text, but only once they'd actually run into
-- the fixed-position back icon (title's row) or Track (subtitle's
-- row) buttons - not on a fixed ratio of the panel's size. The nav/tab/
-- track button labels themselves never need this: each is SetAllPoints
-- to its own fixed-pixel-size button, which doesn't change size as the
-- panel is resized, so its text always fits exactly as well as it did at
-- the default panel size. Title and subtitle are the only two without a
-- fixed width - they're anchored just at a left edge - so they're the
-- only ones that can grow into another element's space.
local MIN_HEADER_FONT_SIZE = 8
local HEADER_EDGE_GAP = 8 -- minimum breathing room kept before the next element
local headerBaseFonts = {}
for _, fs in ipairs({ abilitiesPanel.title, abilitiesPanel.subtitle }) do
    local path, size, flags = fs:GetFont()
    if path and size then
        headerBaseFonts[fs] = { path = path, size = size, flags = flags }
    end
end

-- Right-hand boundary of the title's own row: the left edge of the back icon
-- (the leftmost of the two nav buttons, always shown/hidden together),
-- or the panel's own right edge when neither is shown (the main menu).
local function TitleRowRightEdge()
    if navBack:IsShown() then return navBack:GetLeft() end
    return contentPanel:GetRight()
end

-- Right-hand boundary of the subtitle's row: the left edge of the
-- Track/Untrack button when it's showing (a rare's own detail page),
-- otherwise the panel's own right edge.
local function SubtitleRowRightEdge()
    if rareTrackBtn:IsShown() then return rareTrackBtn:GetLeft() end
    return contentPanel:GetRight()
end

-- Sets fs to its full base size, then - only if that actually overflows
-- into rightEdge - shrinks it (down to the floor) just enough to fit.
local function FitHeaderFontString(fs, rightEdge)
    local base = headerBaseFonts[fs]
    if not base then return end
    fs:SetFont(base.path, base.size, base.flags)
    local left = fs:GetLeft()
    if not (left and rightEdge) then return end
    local available = (rightEdge - left) - HEADER_EDGE_GAP
    local textWidth = fs:GetStringWidth()
    if textWidth <= available then return end -- fits at full size already
    local scale = math.max(available, 0) / textWidth
    local newSize = math.max(MIN_HEADER_FONT_SIZE, math.floor(base.size * scale))
    fs:SetFont(base.path, newSize, base.flags)
end

local function UpdateHeaderFontScale()
    if not (contentPanel:GetWidth() and contentPanel:GetWidth() > 0) then return end
    FitHeaderFontString(abilitiesPanel.title, TitleRowRightEdge())
    FitHeaderFontString(abilitiesPanel.subtitle, SubtitleRowRightEdge())
end
-- Fires continuously while dragging the resize grip, so the header text
-- visibly shrinks (or grows back) in step with the panel instead of only
-- updating once the mouse button is released. RefreshAbilitiesPanel also
-- calls this directly (see its end) since the title/subtitle text and
-- which buttons are shown both change on every mode switch, independent
-- of any resize.
contentPanel:HookScript("OnSizeChanged", UpdateHeaderFontScale)

-- Exported for the other PetSmart files.
ns.ABILITIES_PANEL_HEIGHT = ABILITIES_PANEL_HEIGHT
ns.ABILITIES_PANEL_WIDTH = ABILITIES_PANEL_WIDTH
ns.GetRow = GetRow
ns.GetRowWidth = GetRowWidth
ns.LAYOUT = LAYOUT
ns.PetPage = PetPage
ns.ROW_PADDING = ROW_PADDING
ns.SECTION_ART = SECTION_ART
ns.UpdateAbilitiesPanelLockState = UpdateAbilitiesPanelLockState
ns.UpdateHeaderFontScale = UpdateHeaderFontScale
ns.abilitiesBgTexture = abilitiesBgTexture
ns.abilitiesPanel = abilitiesPanel
ns.iconSizeSlider = iconSizeSlider
ns.indexCategoryExpanded = indexCategoryExpanded
ns.navBack = navBack
ns.navColumn = navColumn
ns.optionsBgTexture = optionsBgTexture
ns.petTypesBgTexture = petTypesBgTexture
ns.rareSpawnsBgTexture = rareSpawnsBgTexture
ns.rareTrackBtn = rareTrackBtn
ns.rows = rows
ns.savedScrollByMode = savedScrollByMode
ns.scrollChild = scrollChild
ns.Scroll = Scroll
ns.scrollBar = scrollBar
ns.scrollFrame = scrollFrame
ns.tabIndexLink = tabIndexLink
ns.tabLearned = tabLearned
ns.tabUnlearned = tabUnlearned
ns.trainingBgTexture = trainingBgTexture
ns.trainingInfoExpanded = trainingInfoExpanded
