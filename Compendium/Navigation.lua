--------------------------------------------------------------------------
-- PetSmart: Compendium/Navigation.lua
-- Section list, page switching, and the left-hand section icons.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local LAYOUT = ns.LAYOUT
local PetPage = ns.PetPage
local SECTION_ART = ns.SECTION_ART
local navColumn = ns.navColumn
local rows = ns.rows
local savedScrollByMode = ns.savedScrollByMode
local Scroll = ns.Scroll

----------------------------------------------------------------------
-- Sections: one per icon in the left-hand column. `root` is the mode the
-- icon opens; every other mode belongs to exactly one section (see
-- SECTION_BY_MODE) so the right icon stays highlighted on detail pages.
----------------------------------------------------------------------
local SECTIONS = {
    -- Current pet: only shown while a pet is out (see LayoutNavIcons);
    -- its tooltip and page title are the pet's own name.
    { key = "pet",       label = "Pet",                   root = "pet",      art = SECTION_ART.pet, needsPet = true },
    { key = "abilities", label = "Abilities Index",       root = "index",    art = SECTION_ART.abilities },
    { key = "training",  label = "General Training Info", root = "training", art = SECTION_ART.training },
    { key = "types",     label = "Pet Types",             root = "types",    art = SECTION_ART.types },
    { key = "spawns",    label = "Rare Pet Spawns",       root = "spawns",   art = SECTION_ART.spawns },
    { key = "options",   label = "Options",               root = "options",  art = SECTION_ART.options },
}
local SECTION_BY_MODE = {
    pet = "pet", learned = "pet", unlearned = "pet",
    index = "abilities", detail = "abilities", tamedetail = "abilities",
    training = "training",
    types = "types", typedetail = "types",
    spawns = "spawns", raredetail = "spawns",
    options = "options", profiles = "options",
}
-- Which section a mode belongs to. The pet's Learned/Unlearned ability
-- lists (opened from links on the pet page) belong to the pet's section,
-- and so does an ability page opened from Unlearned; one opened from the
-- Abilities Index belongs to the Abilities Index section.
local function SectionForMode(mode)
    if (mode == "detail" or mode == "tamedetail") and ns.detailReturnMode == "unlearned" then
        return "pet"
    end
    return SECTION_BY_MODE[mode] or "abilities"
end

-- Modes that are a section's top page: no back icon there, since the
-- icon column is the way out. (Learned/Unlearned are sub-pages of the
-- pet page now, so they get a back icon to it.)
local TOP_LEVEL_MODES = {
    pet = true, index = true,
    training = true, types = true, spawns = true, options = true,
}
local VALID_LAST_SECTION = {}
for _, sec in ipairs(SECTIONS) do VALID_LAST_SECTION[sec.root] = true end

local function SetAbilitiesMode(mode, data, returnMode)
    savedScrollByMode[ns.abilitiesMode] = Scroll.offset
    ns.abilitiesMode = mode
    -- Remember the last section opened (by its top page), so the
    -- Compendium reopens there next time.
    if ns.profile and VALID_LAST_SECTION[mode] then
        ns.profile.lastSection = mode
    end
    if mode == "detail" then
        ns.selectedRankData = data
        if returnMode then ns.detailReturnMode = returnMode end
    elseif mode == "typedetail" then
        ns.selectedFamilyId = data
    elseif mode == "raredetail" then
        ns.selectedRare = data
    elseif mode == "tamedetail" then
        ns.selectedTameTeacher = data
    end
    ns.RefreshAbilitiesPanel()
    if mode == "detail" or mode == "typedetail" or mode == "raredetail" or mode == "tamedetail" then
        Scroll.Set(0) -- a detail page is new content every time - always start at the top
    else
        Scroll.Set(savedScrollByMode[mode] or 0)
    end
end

----------------------------------------------------------------------
-- Left-hand section icons. Each one is that section's medallion art
-- (the same image as its watermark). The selected section's icon is
-- shown in full color with a gold marker beside it; the others are
-- dimmed and desaturated until hovered. Clicking an icon opens that
-- section's top page (clicking the already-open section's icon also
-- jumps back to its top page, like the old "Main" button did).
----------------------------------------------------------------------
local navIcons = {}
do
    local count = #SECTIONS
    for i, sec in ipairs(SECTIONS) do
        local b = CreateFrame("Button", "PetSmartNavIcon_" .. sec.key, navColumn)
        b:SetSize(LAYOUT.NAV_ICON_SIZE, LAYOUT.NAV_ICON_SIZE)
        b.section = sec -- positioned by LayoutNavIcons below

        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints()
        b.icon:SetTexture(sec.art)

        -- Hover glow: the same round art drawn again with additive
        -- blending, so it brightens just the medallion (its transparent
        -- corners stay transparent) instead of a square highlight box.
        b.glow = b:CreateTexture(nil, "HIGHLIGHT")
        b.glow:SetAllPoints()
        b.glow:SetTexture(sec.art)
        b.glow:SetBlendMode("ADD")
        b.glow:SetAlpha(0.35)

        -- Selected marker: a thin gold bar along the column's left edge.
        b.marker = navColumn:CreateTexture(nil, "OVERLAY")
        b.marker:SetColorTexture(1, 0.82, 0.2, 1)
        b.marker:SetSize(3, LAYOUT.NAV_ICON_SIZE - 12)
        b.marker:SetPoint("RIGHT", b, "LEFT", -3, 0)
        b.marker:Hide()

        b:RegisterForClicks("LeftButtonUp")
        b:SetScript("OnClick", function() SetAbilitiesMode(sec.root) end)
        b:SetScript("OnEnter", function(self)
            self.hovered = true
            if not self.selected then
                self.icon:SetDesaturated(false)
                self.icon:SetAlpha(1)
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            -- Just the section's name, same plain style as the Back and
            -- Track/Untrack tooltips.
            GameTooltip:SetText(sec.needsPet and (UnitName("pet") or sec.label) or sec.label, 1, 1, 1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function(self)
            self.hovered = false
            if not self.selected then
                self.icon:SetDesaturated(true)
                self.icon:SetAlpha(0.6)
            end
            GameTooltip:Hide()
        end)
        navIcons[i] = b
    end
end

-- Current-pet art: the medallion for the pet's family (Media\Pet-Families),
-- used for both its nav icon and the pet page's watermark. Cats use the
-- seated black lion (the section's original art), which is also the
-- fallback when the family can't be read.
local FAMILY_ART_DIR = "Interface\\AddOns\\PetSmart\\Media\\Pet-Families\\"
local FAMILY_ART = {
    [1] = "Wolf", [3] = "Spider", [4] = "Bear", [5] = "Boar", [6] = "Crocolisk",
    [7] = "CarrionBird", [8] = "Crab", [9] = "Gorilla", [11] = "Raptor",
    [12] = "Tallstrider", [20] = "Scorpid", [21] = "Turtle", [24] = "Bat",
    [25] = "Hyena", [26] = "BirdofPrey", [27] = "WindSerpent", [40] = "Fox",
}
function PetPage.FamilyArt()
    local family = UnitExists("pet") and UnitCreatureFamily and UnitCreatureFamily("pet")
    if not family or ns.AnySecret(family) then return SECTION_ART.pet end
    local id = ns.FAMILY_BY_NAME and ns.FAMILY_BY_NAME[family]
    if not id and family == "Owl" then id = 26 end -- pre-rename name for Bird of Prey
    if id == 2 then return SECTION_ART.pet end -- Cat: the seated black lion is its medallion
    local file = id and FAMILY_ART[id]
    return file and (FAMILY_ART_DIR .. file) or SECTION_ART.pet
end

-- Points the pet nav icon and the pet page watermark at the current pet's
-- family medallion (only touches the textures when it actually changes).
function PetPage.UpdateFamilyArt()
    local art = PetPage.FamilyArt()
    if PetPage.familyArt == art then return end
    PetPage.familyArt = art
    PetPage.bg:SetTexture(art)
    for _, b in ipairs(navIcons) do
        if b.section.needsPet then
            b.icon:SetTexture(art)
            b.glow:SetTexture(art)
        end
    end
end

-- Stacks the visible icons from the top of the column. The current-pet
-- icon only shows while a pet is out, at the very top, pushing the rest
-- down one slot; without a pet the rest sit exactly where they always do.
function PetPage.LayoutNavIcons()
    local hasPet = UnitExists("pet") and true or false
    -- Only re-stack when a pet was summoned/dismissed; the pet page
    -- refreshes twice a second and shouldn't keep moving icons around.
    if PetPage.navLaidOutForPet == hasPet then return end
    PetPage.navLaidOutForPet = hasPet
    local slot = 0
    for _, b in ipairs(navIcons) do
        local show = (not b.section.needsPet) or hasPet
        b:SetShown(show)
        if show then
            b:ClearAllPoints()
            b:SetPoint("TOP", navColumn, "TOP", 0, -(10 + slot * (LAYOUT.NAV_ICON_SIZE + LAYOUT.NAV_ICON_GAP)))
            slot = slot + 1
        end
    end
end
PetPage.LayoutNavIcons()

-- Highlights the icon for whichever section the current mode belongs to
-- (and re-stacks the column first, in case a pet was summoned/dismissed).
local function UpdateNavIcons()
    PetPage.LayoutNavIcons()
    PetPage.UpdateFamilyArt()
    local current = SectionForMode(ns.abilitiesMode)
    for _, b in ipairs(navIcons) do
        local selected = (b.section.key == current) and b:IsShown()
        b.selected = selected
        -- The icon under the mouse stays lit, so the pet page's twice-a-
        -- second refresh doesn't switch off its hover highlight.
        local lit = selected or b.hovered
        b.icon:SetDesaturated(not lit)
        b.icon:SetAlpha(lit and 1 or 0.6)
        b.marker:SetShown(selected)
    end
end

local function HideAllRows()
    for _, r in ipairs(rows) do
        r:Hide()
        r:SetScript("OnClick", nil)
        r.text:SetTextColor(1, 1, 1)
        r:EnableMouse(false)
    end
end

-- Exported for the other PetSmart files.
ns.HideAllRows = HideAllRows
ns.SectionForMode = SectionForMode
ns.SetAbilitiesMode = SetAbilitiesMode
ns.TOP_LEVEL_MODES = TOP_LEVEL_MODES
ns.UpdateNavIcons = UpdateNavIcons
ns.VALID_LAST_SECTION = VALID_LAST_SECTION
