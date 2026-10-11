--------------------------------------------------------------------------
-- PetSmart: Compendium/Refresh.lua
-- Draws the current page: header state, the shared row helpers, then the section's page function.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local GetRow = ns.GetRow
local GetRowWidth = ns.GetRowWidth
local HideAllRows = ns.HideAllRows
local PetPage = ns.PetPage
local ROW_PADDING = ns.ROW_PADDING
local SetAbilitiesMode = ns.SetAbilitiesMode
local TOP_LEVEL_MODES = ns.TOP_LEVEL_MODES
local UpdateHeaderFontScale = ns.UpdateHeaderFontScale
local UpdateNavIcons = ns.UpdateNavIcons
local VALID_LAST_SECTION = ns.VALID_LAST_SECTION
local abilitiesBgTexture = ns.abilitiesBgTexture
local abilitiesPanel = ns.abilitiesPanel
local iconSizeSlider = ns.iconSizeSlider
local navBack = ns.navBack
local optionsBgTexture = ns.optionsBgTexture
local petTypesBgTexture = ns.petTypesBgTexture
local rareSpawnsBgTexture = ns.rareSpawnsBgTexture
local rareTrackBtn = ns.rareTrackBtn
local scrollChild = ns.scrollChild
local scrollFrame = ns.scrollFrame
local tabIndexLink = ns.tabIndexLink
local tabLearned = ns.tabLearned
local tabUnlearned = ns.tabUnlearned
local trainingBgTexture = ns.trainingBgTexture
local XP = ns.XP

ns.Pages = ns.Pages or {}

ns.RefreshAbilitiesPanel = function()
    if not abilitiesPanel:IsShown() then return end
    -- Pet dismissed (or died/stabled) while its page was open: its icon is
    -- about to disappear, so move over to Pet Abilities.
    if ns.abilitiesMode == "pet" and not UnitExists("pet") then
        ns.abilitiesMode = "learned"
    end
    HideAllRows()

    -- The pet page scrolls with the mouse wheel only (no visible bar);
    -- every other page shows PetSmart's scrollbar.
    ns.scrollBar:SetShown(ns.abilitiesMode ~= "pet")

    -- The Learned/Unlearned sub-tabs only make sense while inside the
    -- "Pet Abilities" section (including a detail page reached from it).
    -- Abilities Index is now the third tab of this row too. (An ability
    -- detail page reached from the Index keeps the tabs hidden, since its
    -- subtitle - the ability's name - sits in this same row.)
    local inPetAbilities = (ns.abilitiesMode == "learned") or (ns.abilitiesMode == "unlearned") or (ns.abilitiesMode == "index")
        or (ns.abilitiesMode == "detail" and ns.detailReturnMode == "unlearned")
    tabLearned:SetShown(inPetAbilities)
    tabUnlearned:SetShown(inPetAbilities)
    tabIndexLink:SetShown(inPetAbilities)
    tabLearned.active = (ns.abilitiesMode == "learned")
    tabUnlearned.active = (ns.abilitiesMode == "unlearned") or (ns.abilitiesMode == "detail" and ns.detailReturnMode == "unlearned")
    tabIndexLink.active = (ns.abilitiesMode == "index")
    for _, tab in ipairs({ tabLearned, tabUnlearned, tabIndexLink }) do
        tab.text:SetTextColor(tab.active and 1 or 0.6, tab.active and 0.85 or 0.6, tab.active and 0.2 or 0.6)
    end

    UpdateNavIcons()

    -- Gear-icon watermark: Options and Manage Profiles only.
    optionsBgTexture:SetShown(ns.abilitiesMode == "options" or ns.abilitiesMode == "profiles")
    -- Beast-medallion watermark: Pet Types and its detail page only.
    petTypesBgTexture:SetShown(ns.abilitiesMode == "types" or ns.abilitiesMode == "typedetail")
    -- Dragon-medallion watermark: Rare Pet Spawns and its detail page only.
    rareSpawnsBgTexture:SetShown(ns.abilitiesMode == "spawns" or ns.abilitiesMode == "raredetail")
    -- Paw-book watermark: Pet Abilities (Learned/Unlearned), the Abilities
    -- Index, and any ability detail page reached from either of those.
    abilitiesBgTexture:SetShown(ns.abilitiesMode == "learned" or ns.abilitiesMode == "unlearned" or ns.abilitiesMode == "index" or ns.abilitiesMode == "tamedetail"
        or (ns.abilitiesMode == "detail" and (ns.detailReturnMode == "learned" or ns.detailReturnMode == "unlearned" or ns.detailReturnMode == "index")))
    -- Elf-and-lion watermark: General Training Info only.
    trainingBgTexture:SetShown(ns.abilitiesMode == "training")
    -- Seated black lion: the current-pet page.
    PetPage.bg:SetShown(ns.abilitiesMode == "pet")

    -- Default: no subtitle. Detail pages below set one (the ability,
    -- family, rare, creature or "Manage Profiles") and show it.
    abilitiesPanel.subtitle:Hide()
    abilitiesPanel.subtitle2:Hide()

    -- Paw-shield back button - detail pages only; each section's
    -- top page is reached from its icon instead. Its destination is one
    -- step up from wherever you are.
    local showNav = not TOP_LEVEL_MODES[ns.abilitiesMode]
    navBack:SetShown(showNav)
    if showNav then
        local backTarget = "learned"
        if ns.abilitiesMode == "detail" then
            backTarget = ns.detailReturnMode
        elseif ns.abilitiesMode == "typedetail" then
            backTarget = "types"
        elseif ns.abilitiesMode == "raredetail" then
            backTarget = "spawns"
        elseif ns.abilitiesMode == "tamedetail" then
            backTarget = "detail"
        elseif ns.abilitiesMode == "profiles" then
            backTarget = "options"
        end
        if ns.abilitiesMode == "tamedetail" then
            -- Back to the ability's detail page: it needs its rank data
            -- handed back in (SetAbilitiesMode("detail") with no data would
            -- blank selectedRankData and render an empty page).
            local rankData = ns.selectedRankData
            navBack:SetScript("OnClick", function() SetAbilitiesMode("detail", rankData) end)
        else
            navBack:SetScript("OnClick", function() SetAbilitiesMode(backTarget) end)
        end
    end

    -- Track/Untrack button: either the specific toggle on a rare's own
    -- detail page, or a plain "Untrack" on the main spawns list (when
    -- something is currently tracked) so it can be cleared without
    -- drilling back into that rare's page.
    rareTrackBtn:Hide()
    -- Icon Size slider: another persistent widget, shown only on its own
    -- row in the Options panel (see the "options" branch below).
    iconSizeSlider:Hide()
    XP.widthSlider:Hide()
    XP.heightSlider:Hide()
    if PetPage.HideWidgets then PetPage.HideWidgets() end

    local rowWidth = GetRowWidth()
    scrollChild:SetWidth(rowWidth)

    -- Drawing context handed to the page function: ctx.y is the running
    -- y offset (pixels below the scroll area's top) and the helpers append
    -- pooled text rows at it.
    local ctx = { y = 0, rowWidth = rowWidth, line = 0 }
    function ctx.AddLine(text, r, g, b, onClick)
        ctx.line = ctx.line + 1
        local row = GetRow(ctx.line)
        row:SetWidth(rowWidth)
        row.text:SetWidth(rowWidth - 4)
        row.text:SetText(text)
        row.text:SetTextColor(r or 1, g or 1, b or 1)
        local h = math.max(16, math.ceil((row.text:GetStringHeight() or 16) + 2))
        row:SetHeight(h)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -ctx.y)
        if onClick then
            row:EnableMouse(true)
            row:SetScript("OnClick", onClick)
        else
            -- Rows are reused by index across refreshes/modes. Without this,
            -- a row that was clickable in a previous view (e.g. an Abilities
            -- Index entry) keeps its highlight texture active and its old
            -- OnClick handler wired up when that same row index is later
            -- reused for plain, non-clickable text (e.g. General Training
            -- Info) - showing a misleading mouseover highlight on lines that
            -- aren't actually links.
            row:EnableMouse(false)
            row:SetScript("OnClick", nil)
        end
        row:Show()
        ctx.y = ctx.y + h + ROW_PADDING
    end

    function ctx.AddList(items, emptyText)
        if #items == 0 then
            ctx.AddLine(emptyText, 0.7, 0.7, 0.7)
            return
        end
        for _, it in ipairs(items) do
            local c = it.color or { 1, 1, 1 }
            ctx.AddLine(it.text, c[1], c[2], c[3], it.onClick)
        end
    end

    -- Each page lives in ns.Pages (see the page functions further down).
    local page = ns.Pages[ns.abilitiesMode]
    if page then page(ctx) end


    ns.Scroll.SetContentHeight(ctx.y)
    local frameH = scrollFrame:GetHeight()
    if ns.AnySecret(frameH) then frameH = 1 end
    scrollChild:SetHeight(math.max(ctx.y, frameH or 1))

    -- Text and button visibility for this mode are both final now -
    -- (re)fit the title/subtitle to whatever room that leaves them.
    UpdateHeaderFontScale()
end

----------------------------------------------------------------------
-- Compendium pages: one function per page (mode), each drawing into
-- the scroll area through ctx (AddLine/AddList, ctx.y, ctx.rowWidth).
----------------------------------------------------------------------

tabLearned:SetScript("OnClick", function() SetAbilitiesMode("learned") end)
tabUnlearned:SetScript("OnClick", function() SetAbilitiesMode("unlearned") end)


-- Reopens on the last section used (its top page), or Pet Abilities the
-- first time.
abilitiesPanel:SetScript("OnShow", function()
    local mode = ns.profile and ns.profile.lastSection
    if not VALID_LAST_SECTION[mode] or (mode == "pet" and not UnitExists("pet")) then mode = "learned" end
    SetAbilitiesMode(mode)
end)
-- Deliberately NOT added to UISpecialFrames - Esc no longer closes this
-- panel (unlike the food panel below, which keeps that behavior). It's a
-- free-floating window now, and the icon's right-click is the one and
-- only way to close it.
