--------------------------------------------------------------------------
-- PetSmart: Sections/PetTypes.lua
-- Section: Pet Types and each family's detail page.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local BuildFamilyAbilityNames = ns.BuildFamilyAbilityNames
local GetAbilitySpellDescription = ns.GetAbilitySpellDescription
local GetFamilySpecialty = ns.GetFamilySpecialty
local SPEC_LABEL = ns.SPEC_LABEL
local SetAbilitiesMode = ns.SetAbilitiesMode
local abilitiesPanel = ns.abilitiesPanel

ns.Pages.types = function(ctx)
    abilitiesPanel.title:SetText("Pet Types")
    local familyIds = {}
    if ns.PET_FAMILIES then
        for familyId in pairs(ns.PET_FAMILIES) do
            familyIds[#familyIds + 1] = familyId
        end
        table.sort(familyIds, function(a, b) return ns.PET_FAMILIES[a] < ns.PET_FAMILIES[b] end)
    end
    local items = {}
    for _, familyId in ipairs(familyIds) do
        items[#items + 1] = {
            text = ns.PET_FAMILIES[familyId], color = { 1, 1, 1 },
            onClick = function() SetAbilitiesMode("typedetail", familyId) end,
        }
    end
    ctx.AddList(items, "No pet family data loaded.")
end

ns.Pages.typedetail = function(ctx)
    local familyId = ns.selectedFamilyId
    local familyName = (familyId and ns.PET_FAMILIES and ns.PET_FAMILIES[familyId]) or "Pet Type"
    -- Keep the main header on "Pet Types" and put the family itself
    -- in the subheader instead of replacing it, same as how an
    -- ability's detail page behaves when reached from the Abilities
    -- Index.
    abilitiesPanel.title:SetText("Pet Types")
    abilitiesPanel.subtitle:SetText(familyName)
    abilitiesPanel.subtitle:Show()
    if not familyId then
        ctx.AddLine("No pet type selected.", 0.8, 0.8, 0.8)
    else
        local info = ns.FAMILY_INFO and ns.FAMILY_INFO[familyId]
        local dietText = (info and info.diet and #info.diet > 0) and table.concat(info.diet, ", ") or "Unknown"
        ctx.AddLine("Diet: " .. dietText, 0.8, 0.8, 0.8)

        local roleText = (info and SPEC_LABEL[info.spec]) or "Unknown"
        ctx.AddLine("Combat Role: " .. roleText, 0.8, 0.8, 0.8)

        ctx.AddLine("Basic Attack: " .. ((info and info.basicSkill) or "Unknown"), 0.8, 0.8, 0.8)

        if info and info.healthQualifier and info.armorQualifier and info.dpsQualifier then
            ctx.AddLine(string.format("Health: %s   Armor: %s   DPS: %s", info.healthQualifier, info.armorQualifier, info.dpsQualifier), 0.8, 0.8, 0.8)
        end

        ctx.AddLine(" ", 1, 1, 1)
        local desc = ns.PET_TYPE_DESCRIPTIONS and ns.PET_TYPE_DESCRIPTIONS[familyId]
        ctx.AddLine(desc or "No description available.", 0.9, 1, 0.9)

        ctx.AddLine(" ", 1, 1, 1)
        local specialty = GetFamilySpecialty(familyId)
        if specialty then
            ctx.AddLine("Family Specialty: " .. specialty.displayName, 1, 0.82, 0)
            local firstRank = specialty.entry.ranks[1]
            local specialtyDesc = (ns.PET_ABILITY_DESCRIPTIONS and ns.PET_ABILITY_DESCRIPTIONS[specialty.key])
                or (firstRank and GetAbilitySpellDescription(firstRank.spellId))
            ctx.AddLine(specialtyDesc or "No description available.", 0.9, 1, 0.9)
        else
            ctx.AddLine("Family Specialty:", 1, 0.82, 0)
            ctx.AddLine("None on record.", 0.8, 0.8, 0.8)
        end

        ctx.AddLine(" ", 1, 1, 1)
        ctx.AddLine("Family Abilities:", 1, 0.82, 0)
        local abilityNames = BuildFamilyAbilityNames(familyId)
        if #abilityNames > 0 then
            ctx.AddLine(table.concat(abilityNames, ", "), 1, 1, 1)
        else
            ctx.AddLine("None on record.", 0.8, 0.8, 0.8)
        end
    end
end
