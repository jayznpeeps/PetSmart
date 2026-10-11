local ADDON_NAME, ns = ...

-- Per-family combat classification, diet and basic-skill data.
-- HAND-MAINTAINED - this file is NOT generator output. Source: the
-- user-supplied "PetFamilyInformation.xlsx" spreadsheet (Forever-
-- verified Tree/Basic Skill/Diet/DPS/Armor/Health data), limited to
-- families that exist in WoW: Forever. This superseded the original
-- Petopia-Classic-sourced draft of this file (the two matched on every
-- modifier that overlapped) and is now the source of truth for "spec"
-- (the Tree column: offensive/defensive/general - no longer "Unknown"
-- in the Pet Types panel) and for the new basicSkill field. Family 26
-- was renamed from "Owl" to "Bird of Prey" (the spreadsheet lists it as
-- "REBRAND: Bird of Prey"); family 40 ("Fox") was added per Forever's
-- own family changes. Dragonhawk/Ravager/Warp Stalker/Sporebat/Nether
-- Ray/Serpent don't exist on Forever and are omitted.
-- TIER IS NIL THROUGHOUT: no verified tier list source yet - the
-- tooltip simply omits the tier part.
-- Keys are the CreatureFamily IDs from FamilyData.lua.
--
-- info(familyId, spec, tier, health, armor, damage, diet, basicSkill,
--      healthQualifier, armorQualifier, dpsQualifier)

ns.FAMILY_INFO = {}
local function info(familyId, spec, tier, health, armor, damage, diet, basicSkill, healthQualifier, armorQualifier, dpsQualifier)
    ns.FAMILY_INFO[familyId] = {
        spec = spec, tier = tier,
        health = health, armor = armor, damage = damage,
        diet = diet, basicSkill = basicSkill,
        healthQualifier = healthQualifier, armorQualifier = armorQualifier, dpsQualifier = dpsQualifier,
    }
end

--        id   spec         tier  health armor damage  diet                                                       skill    healthQ   armorQ    dpsQ
info(1,  "general", nil, 1.00, 1.05, 1.00, { "Meat" }, "Bite", "Medium", "Medium", "Medium") -- Wolf
info(2,  "offense", nil, 0.98, 1.00, 1.10, { "Fish", "Meat" }, "Claw", "Medium", "Low", "High") -- Cat
info(3,  "offense", nil, 1.00, 1.00, 1.07, { "Meat" }, "Bite", "Medium", "Low", "High") -- Spider
info(4,  "defense", nil, 1.08, 1.05, 0.91, { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" }, "Claw", "High", "Medium", "Low") -- Bear
info(5,  "defense", nil, 1.04, 1.09, 0.90, { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" }, "Bite", "High", "Medium", "Low") -- Boar
info(6,  "defense", nil, 0.95, 1.10, 1.00, { "Fish", "Meat" }, "Bite", "Low", "High", "Medium") -- Crocolisk
info(7,  "general", nil, 1.00, 1.05, 1.00, { "Fish", "Meat" }, "Bite", "Medium", "Medium", "Medium") -- Carrion Bird
info(8,  "defense", nil, 0.96, 1.13, 0.95, { "Bread", "Fish", "Fruit", "Fungus" }, "Claw", "Low", "High", "Low") -- Crab
info(9,  "defense", nil, 1.04, 1.00, 1.02, { "Fruit", "Fungus" }, "Smack", "High", "Low", "Medium") -- Gorilla
info(11, "offense", nil, 0.95, 1.03, 1.10, { "Meat" }, "Claw", "Low", "Low", "High") -- Raptor
info(12, "defense", nil, 1.05, 1.00, 1.00, { "Cheese", "Fruit", "Fungus" }, "Claw", "High", "Low", "Medium") -- Tallstrider
info(20, "defense", nil, 1.00, 1.10, 0.94, { "Meat" }, "Claw", "Medium", "High", "Low") -- Scorpid
info(21, "defense", nil, 1.00, 1.13, 0.90, { "Fish", "Fruit", "Fungus", "Raw Fish" }, "Bite", "Medium", "High", "Low") -- Turtle
info(24, "offense", nil, 1.00, 1.00, 1.07, { "Fruit", "Fungus" }, "Bite", "Medium", "Low", "High") -- Bat
info(25, "general", nil, 1.00, 1.05, 1.00, { "Fruit", "Meat" }, "Bite", "Medium", "Medium", "Medium") -- Hyena
info(26, "offense", nil, 1.00, 1.00, 1.07, { "Meat" }, "Claw", "Medium", "Low", "High") -- Bird of Prey
info(27, "offense", nil, 1.00, 1.00, 1.07, { "Bread", "Cheese", "Fish" }, "Bite", "Medium", "Low", "High") -- Wind Serpent
info(40, "general", nil, 1.00, 1.05, 1.00, { "Meat" }, "Bite", "Medium", "Medium", "Medium") -- Fox
