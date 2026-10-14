--------------------------------------------------------------------------
-- PetSmart: Sections/Abilities.lua
-- Section: Pet Abilities (Learned / Unlearned), the Abilities Index, and ability/tame-pet detail pages.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local SetAbilitiesMode = ns.SetAbilitiesMode
local Tame = ns.Tame
local abilitiesPanel = ns.abilitiesPanel
local indexCategoryExpanded = ns.indexCategoryExpanded
local rareTrackBtn = ns.rareTrackBtn

----------------------------------------------------------------------
-- Pet Abilities data (right-click panel)
----------------------------------------------------------------------
-- Backed by Data\PetAbilitiesData.lua, Data\FamilyData.lua and
-- Data\PetopiaTameData.lua (ns.PET_ABILITIES / ns.PET_ABILITY_ORDER /
-- ns.PET_FAMILIES / ns.PETOPIA_TAME_MOBS - see PetSmart.toc for load
-- order). "Learned" is read live from
-- what the hunter's own character actually knows (IsSpellKnown on each
-- rank's spell ID) - this is what the hunter has learned via Beast
-- Training or by taming, independent of which pet is currently active,
-- matching how the game itself tracks it.

local abilityDisplayNameCache = {}
local function GetAbilityDisplayName(key, entry)
    local cached = abilityDisplayNameCache[key]
    if cached then return cached end
    if entry.displayName and entry.displayName ~= "" then
        abilityDisplayNameCache[key] = entry.displayName
        return entry.displayName
    end
    local name
    local firstRank = entry.ranks[1]
    if firstRank then
        if C_Spell and C_Spell.GetSpellName then
            name = C_Spell.GetSpellName(firstRank.spellId)
        end
        if (not name or name == "") and GetSpellInfo then
            name = GetSpellInfo(firstRank.spellId)
        end
    end
    if not name or name == "" then
        name = key:sub(1, 1):upper() .. key:sub(2) -- best-effort fallback only
    end
    abilityDisplayNameCache[key] = name
    return name
end

local abilitySpellDescriptionCache = {}
local function GetAbilitySpellDescription(spellId)
    if not spellId then return nil end
    local cached = abilitySpellDescriptionCache[spellId]
    if cached then return cached end
    local desc
    if C_Spell and C_Spell.GetSpellDescription then
        local ok, d = pcall(C_Spell.GetSpellDescription, spellId)
        if ok then desc = d end
    end
    if (not desc or desc == "") and GetSpellDescription then
        local ok, d = pcall(GetSpellDescription, spellId)
        if ok then desc = d end
    end
    if desc and desc ~= "" then
        abilitySpellDescriptionCache[spellId] = desc
    end
    return desc
end

-- A family's "specialty" is the one ability restricted to that family
-- alone (as opposed to shared abilities like Bite/Claw/Dash that many
-- families learn) - e.g. Prowl for Cat, Dismember for Crocolisk,
-- Furious Howl for Wolf. Every Forever pet family has exactly one.
local function GetFamilySpecialty(familyId)
    if not ns.PET_ABILITY_ORDER then return nil end
    for _, key in ipairs(ns.PET_ABILITY_ORDER) do
        local entry = ns.PET_ABILITIES[key]
        if entry.families and #entry.families == 1 and entry.families[1] == familyId then
            return { key = key, entry = entry, displayName = GetAbilityDisplayName(key, entry) }
        end
    end
    return nil
end

local function IsAbilityRankKnown(spellId)
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellId)
        if ok and known then return true end
        local ok2, known2 = pcall(IsSpellKnown, spellId, true) -- isPetSpell: check current pet's spellbook too
        if ok2 and known2 then return true end
    end
    if C_SpellBook and C_SpellBook.IsSpellInSpellBook and Enum and Enum.SpellBookSpellBank then
        local ok, known = pcall(C_SpellBook.IsSpellInSpellBook, spellId, Enum.SpellBookSpellBank.Player)
        if ok and known then return true end
        local ok2, known2 = pcall(C_SpellBook.IsSpellInSpellBook, spellId, Enum.SpellBookSpellBank.Pet)
        if ok2 and known2 then return true end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellId)
        if ok and known then return true end
    end
    return false
end

local function FamiliesToText(familyIds)
    if not familyIds then return "All Pets" end
    local names = {}
    for _, fid in ipairs(familyIds) do
        names[#names + 1] = (ns.PET_FAMILIES and ns.PET_FAMILIES[fid]) or ("Family " .. fid)
    end
    return table.concat(names, ", ")
end

local function FormatMoney(copper)
    copper = copper or 0
    if copper <= 0 then return "Free" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. "g" end
    if s > 0 then parts[#parts + 1] = s .. "s" end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "c" end
    return table.concat(parts, " ")
end

-- Builds two arrays (learned / unlearned), one entry per ability RANK
-- (not per ability) so every individual rank shows up on its own line,
-- e.g. "Claw (Rank 3)". Unlearned ranks are capped to the pet's level
-- plus a small look-ahead so the list stays focused on what's actually
-- reachable soon. Requires an active pet: abilities are filtered to
-- ones that pet's family can actually learn, and - since training a
-- higher rank implicitly supersedes lower ones - an ability's unlearned
-- list only starts above whatever rank the pet already knows.
local function GetPetFamilyId()
    if not UnitExists("pet") then return nil end
    local famName = UnitCreatureFamily and UnitCreatureFamily("pet")
    if not famName or not ns.FAMILY_BY_NAME then return nil end
    return ns.FAMILY_BY_NAME[famName]
end

local function FamilyCanLearn(families, familyId)
    if not families then return true end -- nil = usable by all families
    if not familyId then return true end -- unknown family: don't filter it out
    for _, fid in ipairs(families) do
        if fid == familyId then return true end
    end
    return false
end

local function BuildAbilityLines()
    local learned, unlearned = {}, {}
    if not ns.PET_ABILITY_ORDER or not UnitExists("pet") then return learned, unlearned end

    local familyId = GetPetFamilyId()
    local refLevel = (UnitLevel and UnitLevel("pet")) or 70
    if not refLevel or refLevel <= 0 then refLevel = 70 end
    refLevel = refLevel + 2

    for _, key in ipairs(ns.PET_ABILITY_ORDER) do
        local entry = ns.PET_ABILITIES[key]
        if FamilyCanLearn(entry.families, familyId) then
            local displayName = GetAbilityDisplayName(key, entry)

            -- Highest rank this pet already knows for this ability, so
            -- lower ranks aren't listed as "unlearned" once superseded.
            local maxKnownRank = 0
            for _, r in ipairs(entry.ranks) do
                if IsAbilityRankKnown(r.spellId) and r.rank > maxKnownRank then
                    maxKnownRank = r.rank
                end
            end

            for _, r in ipairs(entry.ranks) do
                local wrapped = {
                    key = key, spellId = r.spellId, rank = r.rank, petLevel = r.petLevel,
                    tpCost = r.tpCost, source = r.source, moneyCost = r.moneyCost,
                    families = entry.families, displayName = displayName,
                }
                local text = displayName .. " (Rank " .. r.rank .. ")"
                local known = IsAbilityRankKnown(r.spellId)
                if known then
                    learned[#learned + 1] = { text = text, data = wrapped }
                elseif r.rank > maxKnownRank and r.petLevel <= refLevel then
                    unlearned[#unlearned + 1] = { text = text, data = wrapped }
                end
            end
        end
    end
    return learned, unlearned
end

local function BuildDetailLines(data)
    local lines = {}

    -- Tooltip/effect text for this specific rank - the hand-transcribed
    -- wowhead.com/forever table first (covers every rank, not just each
    -- family's rank-1 specialty move), falling back to the live spell
    -- API for anything not in that table (e.g. a couple of resistance
    -- aura top ranks Wowhead hasn't published a page for yet).
    local desc = (ns.PET_ABILITY_RANK_TOOLTIPS and ns.PET_ABILITY_RANK_TOOLTIPS[data.spellId])
        or GetAbilitySpellDescription(data.spellId)
    if desc and desc ~= "" then
        lines[#lines + 1] = { text = desc, color = { 1, 1, 1 } }
        lines[#lines + 1] = { text = " ", color = { 1, 1, 1 } }
    end

    lines[#lines + 1] = { text = "Usable by: " .. FamiliesToText(data.families), color = { 0.8, 0.8, 0.8 } }
    lines[#lines + 1] = {
        text = string.format("Requires pet level %d, %d training points", data.petLevel or 0, data.tpCost or 0),
        color = { 0.8, 0.8, 0.8 },
    }

    local src = data.source or ""
    if src:find("t") then
        lines[#lines + 1] = { text = "Train from Beast Trainer - " .. FormatMoney(data.moneyCost), color = { 1, 0.82, 0.2 } }
    end
    if src:find("w") then
        local mobs = ns.PETOPIA_TAME_MOBS and ns.PETOPIA_TAME_MOBS[data.key] and ns.PETOPIA_TAME_MOBS[data.key][data.rank]
        lines[#lines + 1] = { text = "Tame one of:", color = { 1, 0.82, 0.2 } }
        if mobs and #mobs > 0 then
            for _, m in ipairs(mobs) do
                local name, family, levels, zone = m[1], m[2], m[3], m[4]
                -- Plain data only here, no onClick - SetAbilitiesMode isn't
                -- defined yet at this point in the file, so a closure built
                -- right here would silently capture a nil global instead of
                -- the real function. The "detail" render block builds the
                -- actual click handler from this `mob` field once the line
                -- reaches the screen, well after SetAbilitiesMode exists.
                lines[#lines + 1] = {
                    text = "  " .. name .. " (" .. family .. ") - " .. zone .. " (Lv " .. levels .. ")", color = { 0.9, 1, 0.9 },
                    mob = { name = name, family = family, levels = levels, zone = zone },
                }
            end
        else
            lines[#lines + 1] = { text = "  No tameable source on record for this rank.", color = { 0.8, 0.8, 0.8 } }
        end
    end
    if src == "n" or src == "" then
        lines[#lines + 1] = { text = "No known source recorded for this rank.", color = { 0.8, 0.8, 0.8 } }
    end
    return lines
end

-- Maps FamilyInfoData.lua's "spec" field (the Forever-verified "Tree"
-- column from the user's pet-family spreadsheet) to the label shown in
-- the Pet Types panel.
local SPEC_LABEL = { offense = "Offensive", defense = "Defensive", general = "General" }

-- Collects the display names of every family-restricted ("Family
-- Special") ability a given pet family can learn, alphabetically
-- sorted. Used by the Pet Types panel; deliberately excludes the
-- all-family abilities (resistances, Growl, Cower, etc.) since those
-- aren't what makes a given family distinct.
local function BuildFamilyAbilityNames(familyId)
    local names = {}
    if ns.PET_ABILITY_ORDER then
        for _, key in ipairs(ns.PET_ABILITY_ORDER) do
            local entry = ns.PET_ABILITIES[key]
            if entry.families then
                for _, fid in ipairs(entry.families) do
                    if fid == familyId then
                        names[#names + 1] = GetAbilityDisplayName(key, entry)
                        break
                    end
                end
            end
        end
    end
    table.sort(names)
    return names
end

-- Section order for the Abilities Index.
local INDEX_CATEGORY_ORDER = { "Trainer Learned", "General Tame", "Family Special" }

-- Classifies an ability entry into one of the three index sections:
--   "Trainer Learned" - usable by all families, taught by the pet trainer
--   "General Tame"     - learned only by taming a beast that already knows
--                         it (e.g. Cower), whether that's every family
--                         (entry.families == nil) or several families that
--                         don't add up to a single-family specialty (e.g.
--                         Bite, Claw, Dash, Dive)
--   "Family Special"   - unique to exactly one family
local function GetAbilityCategory(entry)
    if entry.families == nil then
        local firstSource = entry.ranks[1] and entry.ranks[1].source
        if firstSource == "w" then
            return "General Tame"
        end
        return "Trainer Learned"
    end
    if #entry.families > 1 then
        return "General Tame"
    end
    return "Family Special"
end

-- Every ability/rank in the dataset, with no filtering at all - no level
-- cutoff, no family restriction, no known/unknown distinction, and no pet
-- required. Grouped into sections (see INDEX_CATEGORY_ORDER) and sorted
-- alphabetically by ability name within each section; ranks stay in
-- ascending order within an ability. A pure reference list.
--
-- Returns a list of { category, items } sections rather than a flat list
-- of lines, so the index can collapse/expand each section the same way
-- the General Training Info panel does (see indexCategoryExpanded below) -
-- the caller decides whether to render a section's items.
local function BuildIndexLines()
    local sections = {}
    if not ns.PET_ABILITY_ORDER then return sections end

    local grouped = {}
    for _, name in ipairs(INDEX_CATEGORY_ORDER) do
        grouped[name] = {}
    end

    for _, key in ipairs(ns.PET_ABILITY_ORDER) do
        local entry = ns.PET_ABILITIES[key]
        local displayName = GetAbilityDisplayName(key, entry)
        local category = GetAbilityCategory(entry)
        table.insert(grouped[category], { key = key, entry = entry, displayName = displayName })
    end

    for _, category in ipairs(INDEX_CATEGORY_ORDER) do
        local abilities = grouped[category]
        if #abilities > 0 then
            table.sort(abilities, function(a, b) return a.displayName < b.displayName end)
            local items = {}
            for _, a in ipairs(abilities) do
                for _, r in ipairs(a.entry.ranks) do
                    local wrapped = {
                        key = a.key, spellId = r.spellId, rank = r.rank, petLevel = r.petLevel,
                        tpCost = r.tpCost, source = r.source, moneyCost = r.moneyCost,
                        families = a.entry.families, displayName = a.displayName,
                    }
                    items[#items + 1] = { text = a.displayName .. " (Rank " .. r.rank .. ")", data = wrapped }
                end
            end
            sections[#sections + 1] = { category = category, items = items }
        end
    end

    return sections
end

-- Key under the pet's Learned / Unlearned lists and the Abilities Index explaining the paws.
function ns.AddPawKey(ctx)
    local BT = ns.BeastTraining
    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine(("|T%s:12:12|t In your Beast Training   |T%s:12:12|t Not in Beast Training yet"):format(BT.PAW_GREEN, BT.PAW_RED), 0.7, 0.7, 0.7)
    ctx.AddLine("Paws update when you learn an ability (from its chat message) or open Beast Training. "
        .. "If one looks wrong, open Beast Training once to refresh it.", 0.6, 0.6, 0.6)
end

ns.Pages.learned = function(ctx)
    -- Part of the pet page: same header (name, level, loyalty, XP bar),
    -- with this list in place of the stats.
    if UnitExists("pet") then ns.PetPage.Header() else abilitiesPanel.title:SetText("Pet Abilities") end
    if not UnitExists("pet") then
        ctx.AddLine("No pet currently active.", 0.8, 0.8, 0.8)
    else
        local learned = BuildAbilityLines()
        local items = {}
        -- Paw: green = the hunter can teach it from Beast Training, red = not yet.
        local BT = ns.BeastTraining
        for _, e in ipairs(learned) do
            local paw = BT and (BT.Paw(e.data) .. " ") or ""
            items[#items + 1] = { text = paw .. e.text, color = { 0.9, 1, 0.9 } }
        end
        ctx.AddList(items, "No trained abilities found for this pet.")
        if BT and #learned > 0 then ns.AddPawKey(ctx) end
    end
end

ns.Pages.unlearned = function(ctx)
    -- Part of the pet page: same header (name, level, loyalty, XP bar),
    -- with this list in place of the stats.
    if UnitExists("pet") then ns.PetPage.Header() else abilitiesPanel.title:SetText("Pet Abilities") end
    if not UnitExists("pet") then
        ctx.AddLine("No pet currently active.", 0.8, 0.8, 0.8)
    else
        local _, unlearned = BuildAbilityLines()
        local items = {}
        -- Paw: green = it's in your Beast Training, so you can teach it now.
        local BT = ns.BeastTraining
        for _, e in ipairs(unlearned) do
            local paw = BT and (BT.Paw(e.data) .. " ") or ""
            items[#items + 1] = { text = paw .. e.text, color = { 1, 1, 1 }, onClick = function() SetAbilitiesMode("detail", e.data, "unlearned") end }
        end
        ctx.AddList(items, "No unlearned ranks within reach of your current level.")
        if BT and #unlearned > 0 then ns.AddPawKey(ctx) end
    end
end

ns.Pages.index = function(ctx)
    abilitiesPanel.title:SetText("Abilities Index")
    Tame.ShowUntrackButton(ns.RefreshAbilitiesPanel)
    local sections = BuildIndexLines()
    -- Paw beside every rank, same as the pet's Learned/Unlearned lists:
    -- green = it's in your Beast Training, red = not yet.
    local BT = ns.BeastTraining
    if #sections == 0 then
        ctx.AddLine("No ability data loaded.", 0.7, 0.7, 0.7)
    else
        for _, section in ipairs(sections) do
            -- Sections start expanded; the player can collapse any of them.
            local expanded = indexCategoryExpanded[section.category] ~= false
            ctx.AddLine(section.category, 1, 0.82, 0, function()
                indexCategoryExpanded[section.category] = not expanded
                ns.RefreshAbilitiesPanel()
            end)
            if expanded then
                for _, item in ipairs(section.items) do
                    local paw = BT and (BT.Paw(item.data) .. " ") or ""
                    ctx.AddLine(paw .. item.text, 1, 1, 1, function() SetAbilitiesMode("detail", item.data, "index") end)
                end
                ctx.AddLine(" ", 1, 1, 1)
            end
        end
        if BT then ns.AddPawKey(ctx) end
    end
end

ns.Pages.detail = function(ctx)
    local data = ns.selectedRankData
    local abilityText = data and (data.displayName .. " (Rank " .. data.rank .. ")") or "Ability"
    if ns.detailReturnMode == "index" then
        -- Keep the main header on "Abilities Index" and put the
        -- ability itself in the subheader instead of replacing it.
        abilitiesPanel.title:SetText("Abilities Index")
        Tame.ShowUntrackButton(ns.RefreshAbilitiesPanel)
        abilitiesPanel.subtitle:SetText(abilityText)
        abilitiesPanel.subtitle:Show()
    else
        abilitiesPanel.title:SetText(abilityText)
    end
    if data then
        for _, l in ipairs(BuildDetailLines(data)) do
            local onClick = nil
            if l.mob then
                onClick = function() SetAbilitiesMode("tamedetail", l.mob) end
            end
            ctx.AddLine(l.text, l.color[1], l.color[2], l.color[3], onClick)
        end
    end
end

ns.Pages.tamedetail = function(ctx)
    local mob = ns.selectedTameTeacher
    -- Keep the main header on the ability this teacher was reached
    -- from and put the creature's own name in the subheader, same
    -- pattern as every other detail-of-a-detail page in this panel.
    local abilityText = ns.selectedRankData and (ns.selectedRankData.displayName .. " (Rank " .. ns.selectedRankData.rank .. ")") or "Ability"
    abilitiesPanel.title:SetText(abilityText)
    abilitiesPanel.subtitle:SetText(mob and mob.name or "Tameable Pet")
    abilitiesPanel.subtitle:Show()

    local spawnInfo = mob and Tame.GetSpawnInfo(mob.name)
    if spawnInfo then
        local tracked = Tame.IsTracking(mob.name)
        rareTrackBtn:SetState(tracked,
            nil,
            function()
                Tame.Set(mob.name, spawnInfo)
                ns.RefreshAbilitiesPanel()
            end)
    end

    if not mob then
        ctx.AddLine("No tameable pet selected.", 0.8, 0.8, 0.8)
    else
        ctx.AddLine("Family: " .. mob.family, 0.8, 0.8, 0.8)
        ctx.AddLine("Pet Level: " .. tostring(mob.levels), 0.8, 0.8, 0.8)
        local pointCount = spawnInfo and spawnInfo.points and #spawnInfo.points or 0
        local zoneLine = "Zone: " .. tostring(mob.zone)
        if pointCount > 1 then
            zoneLine = zoneLine .. "  (" .. pointCount .. " known spawn areas)"
        end
        ctx.AddLine(zoneLine, 0.8, 0.8, 0.8)
        ctx.AddLine(" ", 1, 1, 1)
        if spawnInfo and spawnInfo.description then
            ctx.AddLine(spawnInfo.description, 0.9, 1, 0.9)
            ctx.AddLine(" ", 1, 1, 1)
        end
        if not spawnInfo then
            ctx.AddLine("(No location on record for this creature yet - tracking isn't available for it.)", 0.6, 0.6, 0.6)
        elseif not spawnInfo.mapID then
            ctx.AddLine("(Map tracking unavailable for this zone.)", 0.6, 0.6, 0.6)
        elseif pointCount > 1 then
            ctx.AddLine("Tracking this pet pins every known spawn area at once (one pin per area it's known to appear in, not every individual sighting), regardless of your Multi-Tracking setting.", 0.6, 0.6, 0.6)
        end
    end
end

-- Exported for the other PetSmart files.
ns.BuildFamilyAbilityNames = BuildFamilyAbilityNames
ns.GetAbilityCategory = GetAbilityCategory
ns.GetAbilityDisplayName = GetAbilityDisplayName
ns.GetAbilitySpellDescription = GetAbilitySpellDescription
ns.GetFamilySpecialty = GetFamilySpecialty
ns.SPEC_LABEL = SPEC_LABEL
