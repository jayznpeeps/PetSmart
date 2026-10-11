local ADDON_NAME, ns = ...

-- Pet ability ranks for WoW: Forever. Family IDs match FamilyData.lua
-- (26 = Bird of Prey, 40 = Fox). Real spell IDs / training point costs /
-- pet level requirements / money costs are kept from the original
-- client data where a Forever ability still matches an existing Vanilla
-- one; Forever-exclusive abilities use the real spell IDs supplied for
-- Forever itself, with pet levels per the user-supplied level schedule
-- (spot-checked against wowhead.com/forever) and tpCost an educated
-- guess (see the "Forever-exclusive family signature abilities" section
-- below for the reasoning). moneyCost stays 0 for all of these since
-- they're learned by taming ("w"), never bought from a trainer.
--
-- ability(key, families, displayName): families = CreatureFamily IDs
-- (nil = all). displayName is only needed when GetSpellInfo(spellId)
-- can't be relied on to resolve a correct name (Forever-custom spells).
-- rank(spellId, rank, petLevel, tpCost, source, moneyCost): source "t" =
-- pet trainer, "w" = taming wild beasts, "tw" = both, "n" = no known
-- source. moneyCost in copper.

local ability, rank = ns.NewPetAbilityDB()

----------------------------------------------------------------------
-- Trainer-only stat passives (usable by all families). Unchanged from
-- Vanilla except dropping the TBC-added top rank on Growl/Great Stamina.
----------------------------------------------------------------------
ability("arcaneresistance", nil) -- Arcane Resistance: all families
rank(24493, 1, 20, 5, "t", 4400) -- Arcane Resistance 1
rank(24497, 2, 30, 15, "t", 16000) -- Arcane Resistance 2
rank(24500, 3, 40, 45, "t", 36000) -- Arcane Resistance 3
rank(24501, 4, 50, 90, "t", 72000) -- Arcane Resistance 4
-- Rank 5 removed: added in TBC, does not exist in Forever.

ability("fireresistance", nil) -- Fire Resistance: all families
rank(23992, 1, 20, 5, "t", 4400) -- Fire Resistance 1
rank(24439, 2, 30, 15, "t", 16000) -- Fire Resistance 2
rank(24444, 3, 40, 45, "t", 36000) -- Fire Resistance 3
rank(24445, 4, 50, 90, "t", 72000) -- Fire Resistance 4
-- Rank 5 removed: added in TBC, does not exist in Forever.

ability("frostresistance", nil) -- Frost Resistance: all families
rank(24446, 1, 20, 5, "t", 4400) -- Frost Resistance 1
rank(24447, 2, 30, 15, "t", 16000) -- Frost Resistance 2
rank(24448, 3, 40, 45, "t", 36000) -- Frost Resistance 3
rank(24449, 4, 50, 90, "t", 72000) -- Frost Resistance 4
-- Rank 5 removed: added in TBC, does not exist in Forever.

ability("natureresistance", nil) -- Nature Resistance: all families
rank(24492, 1, 20, 5, "t", 4400) -- Nature Resistance 1
rank(24502, 2, 30, 15, "t", 16000) -- Nature Resistance 2
rank(24503, 3, 40, 45, "t", 36000) -- Nature Resistance 3
rank(24504, 4, 50, 90, "t", 72000) -- Nature Resistance 4
-- Rank 5 removed: added in TBC, does not exist in Forever.

ability("shadowresistance", nil) -- Shadow Resistance: all families
rank(24488, 1, 20, 5, "t", 4400) -- Shadow Resistance 1
rank(24505, 2, 30, 15, "t", 16000) -- Shadow Resistance 2
rank(24506, 3, 40, 45, "t", 36000) -- Shadow Resistance 3
rank(24507, 4, 50, 90, "t", 72000) -- Shadow Resistance 4
-- Rank 5 removed: added in TBC, does not exist in Forever.

ability("greatstamina", nil) -- Great Stamina: all families
rank(4187, 1, 10, 5, "t", 100) -- Great Stamina 1
rank(4188, 2, 12, 10, "t", 1200) -- Great Stamina 2
rank(4189, 3, 18, 15, "t", 4000) -- Great Stamina 3
rank(4190, 4, 24, 25, "t", 14000) -- Great Stamina 4
rank(4191, 5, 30, 50, "t", 16000) -- Great Stamina 5
rank(4192, 6, 36, 75, "t", 28000) -- Great Stamina 6
rank(4193, 7, 42, 100, "t", 48000) -- Great Stamina 7
rank(4194, 8, 48, 125, "t", 64000) -- Great Stamina 8
rank(5041, 9, 54, 150, "t", 84000) -- Great Stamina 9
rank(5042, 10, 60, 185, "t", 100000) -- Great Stamina 10
-- Rank 11 removed: added in TBC, does not exist in Forever.

ability("naturalarmor", nil) -- Natural Armor: all families
rank(24545, 1, 10, 1, "t", 100) -- Natural Armor 1
rank(24549, 2, 12, 5, "t", 1200) -- Natural Armor 2
rank(24550, 3, 18, 10, "t", 4000) -- Natural Armor 3
rank(24551, 4, 24, 15, "t", 14000) -- Natural Armor 4
rank(24552, 5, 30, 25, "t", 16000) -- Natural Armor 5
rank(24553, 6, 36, 50, "t", 28000) -- Natural Armor 6
rank(24554, 7, 42, 75, "t", 48000) -- Natural Armor 7
rank(24555, 8, 48, 100, "t", 64000) -- Natural Armor 8
rank(24629, 9, 54, 125, "t", 84000) -- Natural Armor 9
rank(24630, 10, 60, 150, "tw", 100000) -- Natural Armor 10
-- Rank 11 removed: added in TBC, does not exist in Forever.

ability("growl", nil) -- Growl: all families
rank(2649, 1, 1, 0, "t", 100) -- Growl 1
rank(14916, 2, 10, 0, "t", 100) -- Growl 2
rank(14917, 3, 20, 0, "t", 4000) -- Growl 3
rank(14918, 4, 30, 0, "t", 16000) -- Growl 4
rank(14919, 5, 40, 0, "t", 36000) -- Growl 5
rank(14920, 6, 50, 0, "t", 72000) -- Growl 6
rank(14921, 7, 60, 0, "t", 100000) -- Growl 7
-- Rank 8 removed: added in TBC, does not exist in Forever.

ability("cower", nil) -- Cower: all families
rank(1742, 1, 5, 8, "w", 0) -- Cower 1
rank(1753, 2, 15, 10, "w", 0) -- Cower 2
rank(1754, 3, 25, 12, "w", 0) -- Cower 3
rank(1755, 4, 35, 14, "w", 0) -- Cower 4
rank(1756, 5, 45, 16, "w", 0) -- Cower 5
rank(16697, 6, 55, 18, "w", 0) -- Cower 6
-- Rank 7 removed: added in TBC, does not exist in Forever.

----------------------------------------------------------------------
-- Shared/family abilities (updated families, per Forever's data).
----------------------------------------------------------------------
ability("bite", { 1, 2, 3, 4, 5, 6, 7, 9, 11, 12, 21, 24, 25, 27, 40 }) -- Bite: Bat, Bear, Boar, Carrion Bird, Cat, Crocolisk, Fox, Gorilla, Hyena, Raptor, Spider, Tallstrider, Turtle, Wind Serpent, Wolf
rank(17253, 1, 1, 1, "w", 0) -- Bite 1
rank(17255, 2, 8, 4, "w", 0) -- Bite 2
rank(17256, 3, 16, 7, "w", 0) -- Bite 3
rank(17257, 4, 24, 10, "w", 0) -- Bite 4
rank(17258, 5, 32, 13, "w", 0) -- Bite 5
rank(17259, 6, 40, 17, "w", 0) -- Bite 6
rank(17260, 7, 48, 21, "w", 0) -- Bite 7
rank(17261, 8, 56, 25, "w", 0) -- Bite 8

ability("claw", { 2, 4, 7, 8, 11, 20, 26 }) -- Claw: Bear, Bird of Prey, Carrion Bird, Cat, Crab, Raptor, Scorpid
rank(16827, 1, 1, 1, "w", 0) -- Claw 1
rank(16828, 2, 8, 4, "w", 0) -- Claw 2
rank(16829, 3, 16, 7, "w", 0) -- Claw 3
rank(16830, 4, 24, 10, "w", 0) -- Claw 4
rank(16831, 5, 32, 13, "w", 0) -- Claw 5
rank(16832, 6, 40, 17, "w", 0) -- Claw 6
rank(3010, 7, 48, 21, "w", 0) -- Claw 7
rank(3009, 8, 56, 25, "w", 0) -- Claw 8

ability("dash", { 1, 2, 3, 4, 5, 6, 8, 9, 11, 12, 20, 21, 25 }) -- Dash: Bear, Boar, Cat, Crab, Crocolisk, Gorilla, Hyena, Raptor, Scorpid, Spider, Tallstrider, Turtle, Wolf
rank(23099, 1, 30, 15, "w", 0) -- Dash 1
rank(23109, 2, 40, 20, "w", 0) -- Dash 2
rank(23110, 3, 50, 25, "w", 0) -- Dash 3

ability("dive", { 7, 24, 26, 27 }) -- Dive: Bat, Bird of Prey, Carrion Bird, Wind Serpent
rank(23145, 1, 30, 15, "w", 0) -- Dive 1
rank(23147, 2, 40, 20, "w", 0) -- Dive 2
rank(23148, 3, 50, 25, "w", 0) -- Dive 3

ability("charge", { 5 }) -- Charge: Boar
rank(7371, 1, 1, 5, "w", 0) -- Charge 1
rank(26177, 2, 12, 9, "w", 0) -- Charge 2
rank(26178, 3, 24, 13, "w", 0) -- Charge 3
rank(26179, 4, 36, 17, "n", 0) -- Charge 4
rank(26201, 5, 48, 25, "w", 0) -- Charge 5
rank(27685, 6, 60, 29, "w", 0) -- Charge 6

ability("furioushowl", { 1 }) -- Furious Howl: Wolf
rank(24604, 1, 10, 10, "w", 0) -- Furious Howl 1
rank(24605, 2, 24, 15, "w", 0) -- Furious Howl 2
rank(24603, 3, 40, 20, "w", 0) -- Furious Howl 3
rank(24597, 4, 56, 25, "w", 0) -- Furious Howl 4

ability("lightningbreath", { 27 }) -- Lightning Breath: Wind Serpent
rank(24844, 1, 1, 1, "n", 0) -- Lightning Breath 1 (no known training source)
rank(25008, 2, 12, 5, "w", 0) -- Lightning Breath 2
rank(25009, 3, 24, 10, "w", 0) -- Lightning Breath 3
rank(25010, 4, 36, 15, "w", 0) -- Lightning Breath 4
rank(25011, 5, 48, 20, "w", 0) -- Lightning Breath 5
rank(25012, 6, 60, 25, "w", 0) -- Lightning Breath 6

ability("prowl", { 2 }) -- Prowl: Cat
rank(24450, 1, 30, 15, "w", 0) -- Prowl 1
rank(24452, 2, 40, 20, "w", 0) -- Prowl 2
rank(24453, 3, 50, 25, "w", 0) -- Prowl 3

ability("scorpidpoison", { 20 }) -- Scorpid Poison: Scorpid
rank(24640, 1, 8, 10, "w", 0) -- Scorpid Poison 1
rank(24583, 2, 24, 15, "w", 0) -- Scorpid Poison 2
rank(24586, 3, 40, 20, "w", 0) -- Scorpid Poison 3
rank(24587, 4, 56, 25, "w", 0) -- Scorpid Poison 4

ability("shellshield", { 21 }) -- Shell Shield: Turtle
rank(26064, 1, 20, 15, "w", 0) -- Shell Shield 1

ability("thunderstomp", { 9 }) -- Thunderstomp: Gorilla
rank(26090, 1, 30, 15, "w", 0) -- Thunderstomp 1
rank(26187, 2, 40, 20, "w", 0) -- Thunderstomp 2
rank(26188, 3, 50, 25, "w", 0) -- Thunderstomp 3
rank(1264455, 4, 60, 30, "w", 0) -- Thunderstomp 4 (Forever-added; level confirmed via wowhead.com/forever, tp follows ranks 1-3's level/2 pattern)

-- Screech renamed to Demoralizing Screech, and narrowed to Carrion Bird
-- only (Bat and Owl/Bird of Prey each got their own signature ability
-- below instead of sharing this one).
ability("screech", { 7 }, "Demoralizing Screech") -- Demoralizing Screech: Carrion Bird
rank(24423, 1, 8, 10, "w", 0) -- Demoralizing Screech 1
rank(24577, 2, 24, 15, "w", 0) -- Demoralizing Screech 2
rank(24578, 3, 48, 20, "w", 0) -- Demoralizing Screech 3
rank(24579, 4, 56, 25, "w", 0) -- Demoralizing Screech 4
-- Rank 5 removed: added in TBC, does not exist in Forever.

----------------------------------------------------------------------
-- Forever-exclusive family signature abilities. Real spell IDs as
-- supplied for Forever. Pet levels are the schedule the user originally
-- supplied (dataupdates.txt), spot-checked against
-- https://www.wowhead.com/forever's own spell pages where that site
-- exposes it - rank 5 of Savage Rend and Sonic Blast both show
-- "Requires level 60" there, matching the 12/24/36/48/60 schedule's
-- endpoint (lower ranks' pages all show a generic "Requires level 1"
-- that doesn't vary by rank, so they aren't usable as a check).
--
-- Training point costs aren't published anywhere for these yet, so
-- they're an educated guess using the same tpCost = petLevel / 2
-- relationship that already holds exactly for this file's other
-- family-signature abilities on the same kind of level schedule (Dash,
-- Dive and Prowl: level 30/40/50 -> tp 15/20/25).
----------------------------------------------------------------------
ability("savagerend", { 11 }, "Savage Rend") -- Savage Rend: Raptor
rank(1265065, 1, 12, 6, "w", 0) -- Savage Rend 1
rank(1265066, 2, 24, 12, "w", 0) -- Savage Rend 2
rank(1265067, 3, 36, 18, "w", 0) -- Savage Rend 3
rank(1265068, 4, 48, 24, "w", 0) -- Savage Rend 4
rank(1265069, 5, 60, 30, "w", 0) -- Savage Rend 5

ability("dismember", { 6 }, "Dismember") -- Dismember: Crocolisk
rank(1264937, 1, 12, 6, "w", 0) -- Dismember 1
rank(1264939, 2, 24, 12, "w", 0) -- Dismember 2
rank(1264970, 3, 36, 18, "w", 0) -- Dismember 3
rank(1264971, 4, 48, 24, "w", 0) -- Dismember 4
rank(1264972, 5, 60, 30, "w", 0) -- Dismember 5

ability("mine", { 26 }, "Mine!") -- Mine!: Bird of Prey
rank(1265059, 1, 10, 5, "w", 0) -- Mine! 1
rank(1265060, 2, 20, 10, "w", 0) -- Mine! 2
rank(1265061, 3, 30, 15, "w", 0) -- Mine! 3
rank(1265062, 4, 40, 20, "w", 0) -- Mine! 4
rank(1265064, 5, 50, 25, "w", 0) -- Mine! 5

ability("tendonrip", { 25 }, "Tendon Rip") -- Tendon Rip: Hyena
rank(1265043, 1, 1, 1, "w", 0) -- Tendon Rip 1
rank(1265045, 2, 12, 6, "w", 0) -- Tendon Rip 2
rank(1265046, 3, 24, 12, "w", 0) -- Tendon Rip 3
rank(1265047, 4, 36, 18, "w", 0) -- Tendon Rip 4
rank(1265048, 5, 48, 24, "w", 0) -- Tendon Rip 5

ability("pinch", { 8 }, "Pinch") -- Pinch: Crab
rank(1264745, 1, 12, 6, "w", 0) -- Pinch 1
rank(1264749, 2, 24, 12, "w", 0) -- Pinch 2
rank(1264750, 3, 36, 18, "w", 0) -- Pinch 3
rank(1264751, 4, 48, 24, "w", 0) -- Pinch 4
rank(1264752, 5, 60, 30, "w", 0) -- Pinch 5

ability("web", { 3 }, "Web") -- Web: Spider
rank(1265887, 1, 12, 6, "w", 0) -- Web 1
rank(1265888, 2, 24, 12, "w", 0) -- Web 2
rank(1265890, 3, 36, 18, "w", 0) -- Web 3
rank(1265891, 4, 48, 24, "w", 0) -- Web 4
rank(1265892, 5, 60, 30, "w", 0) -- Web 5

ability("dustcloud", { 12 }, "Dust Cloud") -- Dust Cloud: Tallstrider
rank(1265907, 1, 12, 6, "w", 0) -- Dust Cloud 1
rank(1265908, 2, 24, 12, "w", 0) -- Dust Cloud 2
rank(1265909, 3, 36, 18, "w", 0) -- Dust Cloud 3
rank(1265913, 4, 48, 24, "w", 0) -- Dust Cloud 4
rank(1265911, 5, 60, 30, "w", 0) -- Dust Cloud 5

ability("swipe", { 4 }, "Swipe") -- Swipe: Bear
rank(1264727, 1, 12, 6, "w", 0) -- Swipe 1
rank(1264729, 2, 24, 12, "w", 0) -- Swipe 2
rank(1264730, 3, 36, 18, "w", 0) -- Swipe 3
rank(1264731, 4, 48, 24, "w", 0) -- Swipe 4
rank(1264732, 5, 60, 30, "w", 0) -- Swipe 5

ability("sonicblast", { 24 }, "Sonic Blast") -- Sonic Blast: Bat
rank(1264478, 1, 12, 6, "w", 0) -- Sonic Blast 1
rank(1264479, 2, 24, 12, "w", 0) -- Sonic Blast 2
rank(1264480, 3, 36, 18, "w", 0) -- Sonic Blast 3
rank(1264481, 4, 48, 24, "w", 0) -- Sonic Blast 4
rank(1264482, 5, 60, 30, "w", 0) -- Sonic Blast 5

ability("tricklersdance", { 40 }, "Trickster's Dance") -- Trickster's Dance: Fox
rank(1310617, 1, 20, 10, "w", 0) -- Trickster's Dance 1

-- Removed entirely (TBC-only, Forever doesn't have these):
--   Cobra Reflexes, Avoidance, Fire Breath, Warp, Gore, Poison Spit
-- (Gore and Poison Spit also lost their only non-Vanilla/removed
-- families - Ravager and Serpent respectively - and aren't mentioned
-- as kept in Forever's own data update.)
