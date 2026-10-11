local ADDON_NAME, ns = ...

-- Hand-transcribed rank-1 tooltip text for each family's "specialty"
-- ability (see GetFamilySpecialty in PetSmart.lua). Sourced from
-- https://www.wowhead.com/forever spell pages (fetched 2026-10-02),
-- except tricklersdance (Trickster's Dance, Fox), which Wowhead hasn't
-- published a readable tooltip for yet - that one is user-supplied. The
-- live C_Spell.GetSpellDescription()/GetSpellDescription() API call in
-- PetSmart.lua doesn't reliably resolve these Forever-specific/pet-only
-- spell IDs client-side, so this table is checked first and the API
-- call is kept only as a fallback for anything not listed here.
--
-- Keys are the same ability "key" strings used in
-- Data\PetAbilitiesData.lua.

ns.PET_ABILITY_DESCRIPTIONS = {
    furioushowl = "The wolf howls, increasing the melee attack power of all party members within 15 yards by 13. Lasts 1 min.",
    prowl = "Puts your pet in stealth mode, but slows its movement speed by 50%. The first attack from stealth receives a 20% bonus to damage. Lasts until cancelled.",
    web = "Entangles an enemy in a corrosive web, immobilizing them and dealing 12 Nature damage over 4 sec.",
    swipe = "Swipes 3 nearby enemies, inflicting 4 damage.",
    charge = "Charges an enemy, immobilizes it for 1 sec, and adds 66 melee attack power to the boar's next attack.",
    dismember = "Viciously bites enemy appendages for 11 to 13 damage and reduces the effectiveness of any healing by 50% for 10 sec.",
    screech = "Blasts a single enemy for 7 to 9 damage and lowers the melee attack power of all enemies in melee range by 63 for 30 sec.", -- Demoralizing Screech
    pinch = "Pinches an enemy's legs for 19 to 21 damage and reduces movement speed by 50% for 9 sec.",
    thunderstomp = "Shakes the ground with thundering force, dealing 53 to 61 Nature damage to all enemies within 8 yards.",
    savagerend = "Slashes an enemy with razor talons, causing the target to Bleed for 30 damage over 18 sec.",
    dustcloud = "Kicks up an abrasive cloud of dust, reducing the target's Armor by 65 for 30 sec.",
    scorpidpoison = "Inflicts 5 Nature damage over 10 sec. Effect can stack up to 5 times on a single target.",
    shellshield = "Reduces all damage your pet takes by 50% and increases the time between your pet's attacks by 60%, but deals more damage with each attack. Lasts 12 sec.",
    sonicblast = "Emits a piercing shriek, inflicting 15 to 17 Nature damage and increasing the casting time of all spells by 60% for 30 sec.",
    tendonrip = "Tears at an enemy's legs for 12 damage over 9 sec and reduces movement speed by 50% for the same duration.",
    mine = "Grabs an enemy's weapon with its talons, causing 10 to 12 damage and disarming them for 4 sec.",
    lightningbreath = "Breathes lightning, instantly dealing 8 to 10 Nature damage to a single target.",
    tricklersdance = "Increases your pet's chance to Dodge by 50% and decreases the time between your pet's attacks by 30% for 12 sec.", -- user-supplied; not yet listed on wowhead.com/forever with a readable tooltip
}

----------------------------------------------------------------------
-- Per-rank tooltip text for EVERY rank of EVERY ability in the dataset
-- (not just each family's rank-1 specialty move above), keyed by the
-- rank's exact spellId so the Abilities Index detail page can show the
-- real effect text for whichever specific rank was clicked. Sourced
-- from https://www.wowhead.com/forever spell pages (fetched
-- 2026-10-02). Trickster's Dance's only rank has no page on Wowhead
-- yet and is intentionally left out of this table - PetSmart falls
-- back to the live C_Spell.GetSpellDescription()/GetSpellDescription()
-- API for any spellId not listed here (see GetAbilitySpellDescription
-- in PetSmart.lua), rather than guessing its text. The resistance
-- auras only go up to rank 4 here, matching PetAbilitiesData.lua -
-- their rank 5 was added in TBC and doesn't exist in Forever.
----------------------------------------------------------------------
ns.PET_ABILITY_RANK_TOOLTIPS = {
    -- Arcane Resistance 1-4
    [24493] = "Increases Arcane resistance by 30.",
    [24497] = "Increases Arcane resistance by 60.",
    [24500] = "Increases Arcane resistance by 90.",
    [24501] = "Increases Arcane resistance by 120.",
    -- Fire Resistance 1-4
    [23992] = "Increases Fire resistance by 30.",
    [24439] = "Increases Fire resistance by 60.",
    [24444] = "Increases Fire resistance by 90.",
    [24445] = "Increases Fire resistance by 120.",
    -- Frost Resistance 1-4
    [24446] = "Increases Frost resistance by 30.",
    [24447] = "Increases Frost resistance by 60.",
    [24448] = "Increases Frost resistance by 90.",
    [24449] = "Increases Frost resistance by 120.",
    -- Nature Resistance 1-4
    [24492] = "Increases Nature resistance by 30.",
    [24502] = "Increases Nature resistance by 60.",
    [24503] = "Increases Nature resistance by 90.",
    [24504] = "Increases Nature resistance by 120.",
    -- Shadow Resistance 1-4
    [24488] = "Increases Shadow resistance by 30.",
    [24505] = "Increases Shadow resistance by 60.",
    [24506] = "Increases Shadow resistance by 90.",
    [24507] = "Increases Shadow resistance by 120.",

    -- Great Stamina 1-10
    [4187] = "Stamina increased by 3.",
    [4188] = "Stamina increased by 5.",
    [4189] = "Stamina increased by 7.",
    [4190] = "Stamina increased by 10.",
    [4191] = "Stamina increased by 13.",
    [4192] = "Stamina increased by 17.",
    [4193] = "Stamina increased by 21.",
    [4194] = "Stamina increased by 26.",
    [5041] = "Stamina increased by 32.",
    [5042] = "Stamina increased by 40.",

    -- Natural Armor 1-10
    [24545] = "Armor increased by 50.",
    [24549] = "Armor increased by 100.",
    [24550] = "Armor increased by 160.",
    [24551] = "Armor increased by 240.",
    [24552] = "Armor increased by 330.",
    [24553] = "Armor increased by 430.",
    [24554] = "Armor increased by 550.",
    [24555] = "Armor increased by 675.",
    [24629] = "Armor increased by 810.",
    [24630] = "Armor increased by 1000.",

    -- Growl 1-7 (same effect text at every rank; rank raises threat value, not described in the tooltip itself)
    [2649] = "Taunt the target, increasing the likelihood the creature will focus attacks on you.",
    [14916] = "Taunt the target, increasing the likelihood the creature will focus attacks on you.",
    [14917] = "Taunt the target, increasing the likelihood the creature will focus attacks on you.",
    [14918] = "Taunt the target, increasing the likelihood the creature will focus attacks on you.",
    [14919] = "Taunt the target, increasing the likelihood the creature will focus attacks on you.",
    [14920] = "Taunt the target, increasing the likelihood the creature will focus attacks on you.",
    [14921] = "Taunt the target, increasing the likelihood the creature will focus attacks on you.",

    -- Cower 1-6 (same effect text at every rank)
    [1742] = "Cower, causing no damage but lowering your threat, making the enemy less likely to attack you.",
    [1753] = "Cower, causing no damage but lowering your threat, making the enemy less likely to attack you.",
    [1754] = "Cower, causing no damage but lowering your threat, making the enemy less likely to attack you.",
    [1755] = "Cower, causing no damage but lowering your threat, making the enemy less likely to attack you.",
    [1756] = "Cower, causing no damage but lowering your threat, making the enemy less likely to attack you.",
    [16697] = "Cower, causing no damage but lowering your threat, making the enemy less likely to attack you.",

    -- Bite 1-8
    [17253] = "Bite the enemy, causing 7 to 9 damage.",
    [17255] = "Bite the enemy, causing 16 to 18 damage.",
    [17256] = "Bite the enemy, causing 24 to 28 damage.",
    [17257] = "Bite the enemy, causing 31 to 37 damage.",
    [17258] = "Bite the enemy, causing 40 to 48 damage.",
    [17259] = "Bite the enemy, causing 49 to 59 damage.",
    [17260] = "Bite the enemy, causing 66 to 80 damage.",
    [17261] = "Bite the enemy, causing 81 to 99 damage.",

    -- Claw 1-8
    [16827] = "Claw the enemy, causing 4 to 6 damage.",
    [16828] = "Claw the enemy, causing 8 to 12 damage.",
    [16829] = "Claw the enemy, causing 12 to 16 damage.",
    [16830] = "Claw the enemy, causing 16 to 22 damage.",
    [16831] = "Claw the enemy, causing 21 to 29 damage.",
    [16832] = "Claw the enemy, causing 26 to 36 damage.",
    [3010] = "Claw the enemy, causing 35 to 49 damage.",
    [3009] = "Claw the enemy, causing 43 to 59 damage.",

    -- Dash 1-3
    [23099] = "Increases movement speed by 40% for 15 sec.",
    [23109] = "Increases movement speed by 60% for 15 sec.",
    [23110] = "Increases movement speed by 80% for 15 sec.",

    -- Dive 1-3
    [23145] = "Increases movement speed by 40% for 15 sec.",
    [23147] = "Increases movement speed by 60% for 15 sec.",
    [23148] = "Increases movement speed by 80% for 15 sec.",

    -- Charge 1-6
    [7371] = "Charges an enemy, immobilizes it for 1 sec, and adds 66 melee attack power to the boar's next attack.",
    [26177] = "Charges an enemy, immobilizes it for 1 sec, and adds 130 melee attack power to the boar's next attack.",
    [26178] = "Charges an enemy, immobilizes it for 1 sec, and adds 204 melee attack power to the boar's next attack.",
    [26179] = "Charges an enemy, immobilizes it for 1 sec, and adds 294 melee attack power to the boar's next attack.",
    [26201] = "Charges an enemy, immobilizes it for 1 sec, and adds 430 melee attack power to the boar's next attack.",
    [27685] = "Charges an enemy, immobilizes it for 1 sec, and adds 520 melee attack power to the boar's next attack.",

    -- Furious Howl 1-4
    [24604] = "The wolf howls, increasing the melee attack power of all party members within 15 yards by 13. Lasts 1 min.",
    [24605] = "The wolf howls, increasing the melee attack power of all party members within 15 yards by 31 to 38. Lasts 1 min.",
    [24603] = "The wolf howls, increasing the melee attack power of all party members within 15 yards by 68. Lasts 1 min.",
    [24597] = "The wolf howls, increasing the melee attack power of all party members within 15 yards by 84. Lasts 1 min.",

    -- Lightning Breath 1-6
    [24844] = "Breathes lightning, instantly dealing 8 to 10 Nature damage to a single target.",
    [25008] = "Breathes lightning, instantly dealing 20 to 22 Nature damage to a single target.",
    [25009] = "Breathes lightning, instantly dealing 32 to 36 Nature damage to a single target.",
    [25010] = "Breathes lightning, instantly dealing 46 to 54 Nature damage to a single target.",
    [25011] = "Breathes lightning, instantly dealing 71 to 81 Nature damage to a single target.",
    [25012] = "Breathes lightning, instantly dealing 86 to 98 Nature damage to a single target.",

    -- Prowl 1-3
    [24450] = "Puts your pet in stealth mode, but slows its movement speed by 50%. The first attack from stealth receives a 20% bonus to damage. Lasts until cancelled.",
    [24452] = "Puts your pet in stealth mode, but slows its movement speed by 45%. The first attack from stealth receives a 35% bonus to damage. Lasts until cancelled.",
    [24453] = "Puts your pet in stealth mode, but slows its movement speed by 40%. The first attack from stealth receives a 50% bonus to damage. Lasts until cancelled.",

    -- Scorpid Poison 1-4
    [24640] = "Inflicts 5 Nature damage over 10 sec. Effect can stack up to 5 times on a single target.",
    [24583] = "Inflicts 10 Nature damage over 10 sec. Effect can stack up to 5 times on a single target.",
    [24586] = "Inflicts 20 Nature damage over 10 sec. Effect can stack up to 5 times on a single target.",
    [24587] = "Inflicts 25 Nature damage over 10 sec. Effect can stack up to 5 times on a single target.",

    -- Shell Shield 1 (only rank)
    [26064] = "Reduces all damage your pet takes by 50% and increases the time between your pet's attacks by 60%, but deals more damage with each attack. Lasts 12 sec.",

    -- Thunderstomp 1-4
    [26090] = "Shakes the ground with thundering force, doing 53 to 61 Nature damage to all enemies within 8 yards.",
    [26187] = "Shakes the ground with thundering force, doing 69 to 79 Nature damage to all enemies within 8 yards.",
    [26188] = "Shakes the ground with thundering force, doing 92 to 106 Nature damage to all enemies within 8 yards.",
    [1264455] = "Shakes the ground with thundering force, doing 122 to 142 Nature damage to all enemies within 8 yds.",

    -- Demoralizing Screech 1-4
    [24423] = "Blasts a single enemy for 7 to 9 damage and lowers the melee attack power of all enemies in melee range by 63 for 30 sec.",
    [24577] = "Blasts a single enemy for 9 to 13 damage and lowers the attack power of all enemies in melee range by 111 for 30 sec.",
    [24578] = "Blasts a single enemy for 21 to 27 damage and lowers the melee attack power of all enemies in melee range by 164 for 30 sec.",
    [24579] = "Blasts a single enemy for 24 to 42 damage and lowers the melee attack power of all enemies in melee range by 204 for 30 sec.",

    -- Savage Rend 1-5 (Forever-exclusive, Raptor)
    [1265065] = "Slash an enemy with razor talons, causing the target to Bleed for 30 damage over 18 sec.",
    [1265066] = "Slash an enemy with razor talons, causing the target to Bleed for 54 damage over 18 sec.",
    [1265067] = "Slash an enemy with razor talons, causing the target to Bleed for 72 damage over 18 sec.",
    [1265068] = "Slash an enemy with razor talons, causing the target to Bleed for 120 damage over 18 sec.",
    [1265069] = "Slash an enemy with razor talons, causing the target to Bleed for 156 damage over 18 sec.",

    -- Dismember 1-5 (Forever-exclusive, Crocolisk)
    [1264937] = "Viciously bites enemy appendages for 11 to 13 damage and reduces the effectiveness of any healing by 50% for 10 sec.",
    [1264939] = "Viciously bites enemy appendages for 18 to 20 damage and reduces the effectiveness of any healing by 50% for 10 sec.",
    [1264970] = "Viciously bites enemy appendages for 26 to 30 damage and reduces the effectiveness of any healing by 50% for 10 sec.",
    [1264971] = "Viciously bites enemy appendages for 39 to 45 damage and reduces the effectiveness of any healing by 50% for 10 sec.",
    [1264972] = "Viciously bites enemy appendages for 50 to 58 damage and reduces the effectiveness of any healing by 50% for 10 sec.",

    -- Mine! 1-5 (Forever-exclusive, Bird of Prey)
    [1265059] = "Grabs an enemy's weapon with its talons, causing 10 to 12 damage and disarming them for 4 sec.",
    [1265060] = "Grabs an enemy's weapon with its talons, causing 14 to 16 damage and disarming them for 4 sec.",
    [1265061] = "Grabs an enemy's weapon with its talons, causing 20 to 24 damage and disarming them for 4 sec.",
    [1265062] = "Grabs an enemy's weapon with its talons, causing 33 to 37 damage and disarming them for 4 sec.",
    [1265064] = "Grabs an enemy's weapon with its talons, causing 41 to 47 damage and disarming them for 4 sec.",

    -- Tendon Rip 1-5 (Forever-exclusive, Hyena)
    [1265043] = "Tears at an enemy's legs for 12 damage over 9 sec and reduces movement speed by 50% for 9 sec.",
    [1265045] = "Tears at an enemy's legs for 21 damage over 9 sec and reduces movement speed by 50% for 9 sec.",
    [1265046] = "Tears at an enemy's legs for 27 damage over 9 sec and reduces movement speed by 50% for 9 sec.",
    [1265047] = "Tears at an enemy's legs for 45 damage over 9 sec and reduces movement speed by 50% for 9 sec.",
    [1265048] = "Tears at an enemy's legs for 60 damage over 9 sec and reduces movement speed by 50% for 9 sec.",

    -- Pinch 1-5 (Forever-exclusive, Crab)
    [1264745] = "Pinches an enemy's legs for 19 to 21 damage and reduces movement speed by 50% for 9 sec.",
    [1264749] = "Pinches an enemy's legs for 32 to 36 damage and reduces movement speed by 50% for 9 sec.",
    [1264750] = "Pinches an enemy's legs for 41 to 47 damage and reduces movement speed by 50% for 9 sec.",
    [1264751] = "Pinches an enemy's legs for 68 to 78 damage and reduces movement speed by 50% for 9 sec.",
    [1264752] = "Pinches an enemy's legs for 88 to 102 damage and reduces movement speed by 50% for 9 sec.",

    -- Web 1-5 (Forever-exclusive, Spider)
    [1265887] = "Entangles an enemy in a corrosive web, immobilizing them and dealing 12 Nature damage over 4 sec.",
    [1265888] = "Entangles an enemy in a corrosive web, immobilizing them and dealing 20 Nature damage over 4 sec.",
    [1265890] = "Entangles an enemy in a corrosive web, immobilizing them and dealing 28 Nature damage over 4 sec.",
    [1265891] = "Entangles an enemy in a corrosive web, immobilizing them and dealing 40 Nature damage over 4 sec.",
    [1265892] = "Entangles an enemy in a corrosive web, immobilizing them and dealing 52 Nature damage over 4 sec.",

    -- Dust Cloud 1-5 (Forever-exclusive, Tallstrider)
    [1265907] = "Your tallstrider kicks up an abrasive cloud of dust, reducing the target's Armor by 65 for 30 sec.",
    [1265908] = "Your tallstrider kicks up an abrasive cloud of dust, reducing the target's Armor by 175 for 30 sec.",
    [1265909] = "Your tallstrider kicks up an abrasive cloud of dust, reducing the target's Armor by 285 for 30 sec.",
    [1265913] = "Your tallstrider kicks up an abrasive cloud of dust, reducing the target's Armor by 395 for 30 sec.",
    [1265911] = "Your tallstrider kicks up an abrasive cloud of dust, reducing the target's Armor by 505 for 30 sec.",

    -- Swipe 1-5 (Forever-exclusive, Bear)
    [1264727] = "Swipes 3 nearby enemies, inflicting 4 damage.",
    [1264729] = "Swipes 3 nearby enemies, inflicting 8 to 10 damage.",
    [1264730] = "Swipes 3 nearby enemies, inflicting 11 to 13 damage.",
    [1264731] = "Swipes 3 nearby enemies, inflicting 16 to 18 damage.",
    [1264732] = "Swipes 3 nearby enemies, inflicting 20 to 22 damage.",

    -- Sonic Blast 1-5 (Forever-exclusive, Bat)
    [1264478] = "Emits a piercing shriek, inflicting 15 to 17 Nature damage and increasing the casting time of all spells by 60% for 30 sec.",
    [1264479] = "Emits a piercing shriek, inflicting 33 to 39 Nature damage and increasing the casting time of all spells by 60% for 30 sec.",
    [1264480] = "Emits a piercing shriek, inflicting 44 to 52 Nature damage and increasing the casting time of all spells by 60% for 30 sec.",
    [1264481] = "Emits a piercing shriek, inflicting 62 to 74 Nature damage and increasing the casting time of all spells by 60% for 30 sec.",
    [1264482] = "Emits a piercing shriek, inflicting 77 to 91 Nature damage and increasing the casting time of all spells by 60% for 30 sec.",

    -- Trickster's Dance 1 (Forever-exclusive, Fox; only rank 1310617 not on
    -- Wowhead yet - reusing the user-supplied text from the table above)
    [1310617] = ns.PET_ABILITY_DESCRIPTIONS.tricklersdance,
}
