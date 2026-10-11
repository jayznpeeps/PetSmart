--------------------------------------------------------------------------
-- PetSmart: Sections/Pet.lua
-- Section: the current pet (stats, experience, resistances), shown while a pet is out.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local GetLoyaltyLabel = ns.GetLoyaltyLabel
local LAYOUT = ns.LAYOUT
local PetPage = ns.PetPage
local SetAbilitiesMode = ns.SetAbilitiesMode
local abilitiesPanel = ns.abilitiesPanel
local panelTemplate = ns.panelTemplate
local scrollChild = ns.scrollChild
local tabIndexLink = ns.tabIndexLink

ns.Pages.pet = function(ctx)
    local name = UnitName("pet") or "Pet"
    abilitiesPanel.title:SetText(name)
    local level = UnitLevel("pet")
    local family = (UnitCreatureFamily and UnitCreatureFamily("pet")) or ""
    if ns.AnySecret(level) then
        abilitiesPanel.subtitle:SetFormattedText("Level %s %s", level, family)
    else
        abilitiesPanel.subtitle:SetText(("Level %s %s"):format(level and level > 0 and level or "?", family))
    end
    abilitiesPanel.subtitle:Show()
    abilitiesPanel.subtitle2:SetText(GetLoyaltyLabel() or "Unknown")
    abilitiesPanel.subtitle2:Show()
    ctx.y = PetPage.Render(ctx.rowWidth, ctx.y)
end

tabIndexLink:SetScript("OnClick", function() SetAbilitiesMode("index") end)
----------------------------------------------------------------------
-- Current-pet page: stat lines and live updates.
----------------------------------------------------------------------
local function Num(n)
    n = math.floor((n or 0) + 0.5)
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
    return tostring(n)
end

-- Pet melee crit has no API on Classic-era clients, so this is an
-- estimate: 5% base plus 3% per rank of the hunter's Ferocity talent.
function PetPage.CritEstimate()
    local ranks = 0
    if GetNumTalentTabs and GetNumTalents and GetTalentInfo then
        pcall(function()
            for tab = 1, GetNumTalentTabs() do
                for i = 1, GetNumTalents(tab) do
                    local tname, _, _, _, rank = GetTalentInfo(tab, i)
                    if tname == "Ferocity" then ranks = rank or 0 end
                end
            end
        end)
    end
    return 5 + 3 * ranks
end

-- Pet melee crit: use the client's own value if it exposes one (the
-- in-game pet panel shows it), otherwise fall back to the estimate.
-- Returns value, isEstimate.
function PetPage.Crit()
    for _, fname in ipairs({ "GetPetMeleeCritChance", "GetPetCritChance" }) do
        local fn = _G[fname]
        if type(fn) == "function" then
            local ok, v = pcall(fn)
            if ok and type(v) == "number" then return v, false end
        end
    end
    return PetPage.CritEstimate(), true
end

PetPage.GREEN, PetPage.RED, PetPage.WHITE = { 0.1, 1, 0.1 }, { 1, 0.15, 0.15 }, { 1, 1, 1 }

-- The General block's rows: { label, format, { values }, colour }, drawn
-- with SetFormattedText so secret values can be shown as-is. Buffed values
-- are green and debuffed red, like the in-game pet panel - only when the
-- numbers are ordinary (secret ones can't be compared, so they stay white).
function PetPage.GeneralStats()
    local out = {}
    local WHITE = PetPage.WHITE
    local AnySecret = ns.AnySecret
    do
        local h, hm = UnitHealth("pet"), UnitHealthMax("pet")
        if AnySecret(h, hm) then
            out[#out + 1] = { "Health", "%s / %s", { h or 0, hm or 0 }, WHITE }
        else
            out[#out + 1] = { "Health", "%s / %s", { Num(h), Num(hm) }, WHITE }
        end
    end
    do
        local base, effective, _, posBuff, negBuff = UnitArmor("pet")
        if AnySecret(base, effective, posBuff, negBuff) then
            out[#out + 1] = { "Armor", "%s", { effective or base or 0 }, WHITE }
        else
            local c = ((negBuff or 0) < 0 and PetPage.RED) or (((posBuff or 0) > 0 or (effective or 0) > (base or 0)) and PetPage.GREEN) or WHITE
            out[#out + 1] = { "Armor", "%s", { Num(effective or base) }, c }
        end
    end
    do
        local minD, maxD = UnitDamage("pet")
        if not (minD and maxD) then
            out[#out + 1] = { "Damage", "%s", { "-" }, WHITE }
        elseif AnySecret(minD, maxD) then
            out[#out + 1] = { "Damage", "%.0f - %.0f", { minD, maxD }, WHITE }
        else
            out[#out + 1] = { "Damage", "%s - %s", { Num(math.floor(minD)), Num(math.ceil(maxD)) }, WHITE }
        end
    end
    do
        local base, pos, neg = UnitAttackPower("pet")
        if AnySecret(base, pos, neg) then
            -- can't add the buffs on to a secret base: show the base value
            out[#out + 1] = { "Attack Power", "%s", { base or 0 }, WHITE }
        else
            local c = ((neg or 0) < 0 and PetPage.RED) or ((pos or 0) > 0 and PetPage.GREEN) or WHITE
            out[#out + 1] = { "Attack Power", "%s", { Num((base or 0) + (pos or 0) + (neg or 0)) }, c }
        end
    end
    do
        local crit, est = PetPage.Crit()
        if AnySecret(crit) then
            out[#out + 1] = { "Critical Strike", "%.1f%%", { crit }, WHITE }
        else
            out[#out + 1] = { "Critical Strike", "%s", { (est and "~" or "") .. ("%.1f%%"):format(crit) }, WHITE }
        end
    end
    do
        local current, run = 0, nil
        if GetUnitSpeed then current, run = GetUnitSpeed("pet") end
        if AnySecret(current, run) then
            out[#out + 1] = { "Movement Speed", "%s", { "--" }, WHITE } -- a percentage needs maths
        else
            local speed = (run and run > 0) and run or ((current and current > 0) and current or 7)
            out[#out + 1] = { "Movement Speed", "%s", { ("%d%%"):format(math.floor(speed / 7 * 100 + 0.5)) }, WHITE }
        end
    end
    return out
end

-- Resistance schools: UnitResistance index, and the row in Blizzard's own
-- resistance-icon strip (the same icons the character/pet panels use).
PetPage.RESIST = {
    { "Arcane", 6, 0,          0.11328125 },
    { "Fire",   2, 0.2265625,  0.33984375 },
    { "Frost",  4, 0.11328125, 0.2265625 },
    { "Nature", 3, 0.33984375, 0.453125 },
    { "Shadow", 5, 0.453125,   0.56640625 },
}

-- Gradient fill (shared with the floating pet XP bar; see Core/Init.lua).
PetPage.Gradient = ns.SetBarGradient

-- Active abilities the current pet's family can learn: Family Specials
-- and abilities learned by taming (Bite, Claw, Cower, Dash, Dive...).
-- Trainer-learned ones (resistances, Great Stamina, Natural Armor, Growl)
-- are left out. Names only, alphabetical, no ranks.
function PetPage.LearnableAbilities()
    local names = {}
    if not (ns.PET_ABILITY_ORDER and ns.GetAbilityCategory and ns.GetAbilityDisplayName) then return names end
    local family = UnitCreatureFamily and UnitCreatureFamily("pet")
    local familyId = family and ns.FAMILY_BY_NAME and ns.FAMILY_BY_NAME[family]
    for _, key in ipairs(ns.PET_ABILITY_ORDER) do
        local entry = ns.PET_ABILITIES[key]
        if entry and ns.GetAbilityCategory(entry) ~= "Trainer Learned" then
            local canLearn = (entry.families == nil)
            if not canLearn and familyId then
                for _, fid in ipairs(entry.families) do
                    if fid == familyId then canLearn = true; break end
                end
            end
            if canLearn then names[#names + 1] = ns.GetAbilityDisplayName(key, entry) end
        end
    end
    table.sort(names)
    return names
end

-- Three ability names side by side (informational only - not clickable).
-- The columns are positioned in Render, once the row's width is known.
PetPage.ABILITY_COLUMNS = 3
function PetPage.AbilityRow()
    local r = CreateFrame("Frame", nil, scrollChild)
    r:SetHeight(18)
    r.cols = {}
    for c = 1, PetPage.ABILITY_COLUMNS do
        local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetJustifyH("LEFT")
        r.cols[c] = fs
    end
    return r
end

-- Widgets are created once, on first use, inside the scroll area.
function PetPage.Widgets()
    if PetPage.w then return PetPage.w end
    local w = { rows = {}, res = {} }
    local function Header(text)
        local h = CreateFrame("Frame", nil, scrollChild, panelTemplate)
        h:SetHeight(22)
        if h.SetBackdrop then
            h:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = LAYOUT.SUBPANEL_BACKDROP.edgeFile,
                tile = true, tileSize = 16, edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 } })
            h:SetBackdropColor(0.16, 0.12, 0.08, 0.95)
            h:SetBackdropBorderColor(0.55, 0.45, 0.3, 1)
        end
        h.text = h:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        h.text:SetPoint("CENTER", 0, 0)
        h.text:SetText(text)
        return h
    end
    local function Row(withIcon)
        local r = CreateFrame("Frame", nil, scrollChild)
        r:SetHeight(withIcon and 20 or 18)
        -- No background band: the page's watermark shows through.
        r.label = r:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        r.label:SetJustifyH("LEFT")
        r.value = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        r.value:SetPoint("RIGHT", -8, 0)
        r.value:SetJustifyH("RIGHT")
        if withIcon then
            r.icon = r:CreateTexture(nil, "ARTWORK")
            r.icon:SetSize(16, 16)
            r.icon:SetPoint("LEFT", 4, 0)
            r.icon:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ResistanceIcons")
            r.label:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        else
            r.label:SetPoint("LEFT", 8, 0)
        end
        return r
    end
    -- Experience bar: framed exactly like the General/Resistances headers
    -- (same width, border and rounded corners), with a blue gradient fill
    -- inset inside the border and the numbers on top.
    local xp = Header("")
    if xp.SetBackdropColor then xp:SetBackdropColor(0, 0, 0, 0.75) end
    xp.bar = CreateFrame("StatusBar", nil, xp)
    xp.bar:SetPoint("TOPLEFT", 3, -3)
    xp.bar:SetPoint("BOTTOMRIGHT", -3, 3)
    xp.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    -- The same border again, on a frame above the fill, so the fill's
    -- square ends sit under the rounded corners instead of over them.
    xp.edge = CreateFrame("Frame", nil, xp, panelTemplate)
    xp.edge:SetAllPoints()
    xp.edge:SetFrameLevel(xp.bar:GetFrameLevel() + 1)
    if xp.edge.SetBackdrop then
        xp.edge:SetBackdrop({ edgeFile = LAYOUT.SUBPANEL_BACKDROP.edgeFile, edgeSize = 10 })
        xp.edge:SetBackdropBorderColor(0.55, 0.45, 0.3, 1)
    end
    xp.text:SetParent(xp.edge)
    xp.text:SetFontObject("GameFontHighlightSmall")
    w.xp = xp
    w.general = Header("General")
    w.abilities = Header("Abilities")
    w.ab = {}
    w.resist = Header("Resistances")
    for i = 1, 6 do w.rows[i] = Row(false) end
    for i = 1, #PetPage.RESIST do
        local r = Row(true)
        local t = PetPage.RESIST[i]
        r.icon:SetTexCoord(0, 1, t[3], t[4])
        r.label:SetText(t[1])
        w.res[i] = r
    end
    PetPage.w = w
    return w
end

function PetPage.HideWidgets()
    local w = PetPage.w
    if not w then return end
    w.xp:Hide(); w.general:Hide(); w.abilities:Hide(); w.resist:Hide()
    for _, r in ipairs(w.ab) do r:Hide() end
    for _, r in ipairs(w.rows) do r:Hide() end
    for _, r in ipairs(w.res) do r:Hide() end
end

-- Lays the page out from y (pixels below the scroll area's top), in a
-- centred column like the in-game pet panel. Returns the new y.
function PetPage.Render(width, y)
    local w = PetPage.Widgets()
    local colW = math.min(width - 8, 300)
    local x = math.floor((width - colW) / 2)
    local function Place(f, step)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x, -y)
        f:SetWidth(colW)
        f:Show()
        y = y + step
    end

    local cur, nextXP = 0, 0
    if GetPetExperience then cur, nextXP = GetPetExperience() end
    cur, nextXP = cur or 0, nextXP or 0
    if ns.AnySecret(cur, nextXP) then
        -- Secret XP: the bar can still show it, but no percentage maths.
        w.xp.bar:SetMinMaxValues(0, nextXP)
        w.xp.bar:SetValue(cur)
        PetPage.Gradient(w.xp.bar, unpack(ns.BAR_COLORS.xp))
        w.xp.text:SetFormattedText("Experience: %s / %s", cur, nextXP)
    elseif nextXP > 0 then
        w.xp.bar:SetMinMaxValues(0, nextXP)
        w.xp.bar:SetValue(cur)
        PetPage.Gradient(w.xp.bar, unpack(ns.BAR_COLORS.xp))  -- deep to bright blue
        w.xp.text:SetText(("Experience: %s / %s  (%d%%)"):format(Num(cur), Num(nextXP), math.floor(cur / nextXP * 100)))
    else
        w.xp.bar:SetMinMaxValues(0, 1)
        w.xp.bar:SetValue(1)
        PetPage.Gradient(w.xp.bar, unpack(ns.BAR_COLORS.max)) -- gold at max level
        w.xp.text:SetText("Experience: Max Level")
    end
    y = y + 12 -- clears the loyalty line above
    Place(w.xp, 22 + 12)

    Place(w.general, 22 + 4)
    for i, st in ipairs(PetPage.GeneralStats()) do
        local r = w.rows[i]
        r.label:SetText(st[1] .. ":")
        r.value:SetFormattedText(st[2], unpack(st[3]))
        r.value:SetTextColor(st[4][1], st[4][2], st[4][3])
        Place(r, 18 + 2)
    end
    y = y + 10

    Place(w.resist, 22 + 4)
    for i, t in ipairs(PetPage.RESIST) do
        local r = w.res[i]
        local _, total, pos, neg = UnitResistance("pet", t[2])
        local c = PetPage.WHITE
        if ns.AnySecret(total, pos, neg) then
            r.value:SetFormattedText("%s", total or 0)
        else
            c = ((neg or 0) < 0 and PetPage.RED) or ((pos or 0) > 0 and PetPage.GREEN) or PetPage.WHITE
            r.value:SetText(Num(total or 0))
        end
        r.value:SetTextColor(c[1], c[2], c[3])
        Place(r, 20 + 2)
    end
    y = y + 10

    -- Abilities: three names per row, below Resistances.
    Place(w.abilities, 22 + 4)
    local names = PetPage.LearnableAbilities()
    if #names == 0 then names = { "None on record" } end
    local nCols = PetPage.ABILITY_COLUMNS
    for i = 1, math.ceil(#names / nCols) do
        w.ab[i] = w.ab[i] or PetPage.AbilityRow()
        local r = w.ab[i]
        for c = 1, nCols do
            local fs = r.cols[c]
            fs:ClearAllPoints()
            fs:SetPoint("LEFT", r, "LEFT", 8 + math.floor((c - 1) * colW / nCols), 0)
            fs:SetText(names[(i - 1) * nCols + c] or "")
        end
        Place(r, 18 + 2)
    end
    return y
end

-- Live updates: summoning/dismissing a pet re-stacks the icon column (and
-- leaves the pet page if it was open); any change to the pet's stats
-- refreshes the page while it's showing, throttled so combat health
-- ticks don't rebuild it every frame. Movement speed has no event of its
-- own (e.g. Dash), so the open page is also refreshed every half second.
do
    local f = CreateFrame("Frame")
    PetPage.events = f
    for _, e in ipairs({ "UNIT_PET", "PET_UI_UPDATE", "PLAYER_ENTERING_WORLD", "UNIT_PET_EXPERIENCE",
        "UNIT_HEALTH", "UNIT_HEALTH_FREQUENT", "UNIT_MAXHEALTH", "UNIT_STATS", "UNIT_RESISTANCES",
        "UNIT_ATTACK_POWER", "UNIT_DAMAGE", "UNIT_ATTACK_SPEED", "UNIT_LEVEL", "UNIT_NAME_UPDATE",
        "UNIT_AURA", "CHARACTER_POINTS_CHANGED" }) do
        pcall(f.RegisterEvent, f, e) -- not every event exists on every client
    end
    local dirty, sincePoll, sinceRefresh = false, 0, 0
    f:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_PET" or event == "PET_UI_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            if abilitiesPanel:IsShown() then ns.RefreshAbilitiesPanel() else PetPage.LayoutNavIcons() end
        elseif unit == nil or unit == "pet" then
            dirty = true
        end
    end)
    f:SetScript("OnUpdate", function(_, elapsed)
        if not (abilitiesPanel:IsShown() and ns.abilitiesMode == "pet") then return end
        sinceRefresh = sinceRefresh + elapsed
        sincePoll = sincePoll + elapsed
        if (dirty and sinceRefresh >= 0.2) or sincePoll >= 0.5 then
            dirty, sinceRefresh, sincePoll = false, 0, 0
            ns.RefreshAbilitiesPanel()
        end
    end)
end
