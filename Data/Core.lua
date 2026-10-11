local ADDON_NAME, ns = ...

--------------------------------------------------------------------------
-- Data-file loader helpers.
--
-- FamilyData.lua, FamilyInfoData.lua and PetAbilitiesData.lua are
-- hunter-pet reference data for WoW: Forever. PetAbilitiesData.lua calls
-- a small DB-builder function (ns.NewPetAbilityDB) to register each
-- ability and its ranks. This file MUST load before it (see the .toc
-- file order).
--------------------------------------------------------------------------

-- ns.PET_ABILITIES[key] = { key = "bite", families = {1,2,...} or nil, displayName = "Bite" or nil, ranks = { {spellId, rank, petLevel, tpCost, source, moneyCost}, ... } }
-- ns.PET_ABILITY_ORDER = { "arcaneresistance", "bite", ... } (declaration order)
-- ns.PET_ABILITIES_BY_SPELL[spellId] = { key = "bite", rank = <rank entry table> }
function ns.NewPetAbilityDB()
    ns.PET_ABILITIES = ns.PET_ABILITIES or {}
    ns.PET_ABILITY_ORDER = ns.PET_ABILITY_ORDER or {}
    ns.PET_ABILITIES_BY_SPELL = ns.PET_ABILITIES_BY_SPELL or {}

    local current

    -- displayName is optional: when the game's own GetSpellInfo(spellId)
    -- can resolve a real, correct name, leave it nil. Pass it explicitly
    -- for Forever-custom abilities where that lookup may not resolve to
    -- the right (or any) name.
    local function ability(key, families, displayName)
        local entry = { key = key, families = families, displayName = displayName, ranks = {} }
        ns.PET_ABILITIES[key] = entry
        table.insert(ns.PET_ABILITY_ORDER, key)
        current = entry
    end

    local function rank(spellId, rankNum, petLevel, tpCost, source, moneyCost)
        local r = {
            spellId = spellId, rank = rankNum, petLevel = petLevel,
            tpCost = tpCost, source = source, moneyCost = moneyCost,
        }
        table.insert(current.ranks, r)
        ns.PET_ABILITIES_BY_SPELL[spellId] = { key = current.key, rank = r }
    end

    return ability, rank
end
