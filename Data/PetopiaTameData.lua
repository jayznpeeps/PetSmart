local ADDON_NAME, ns = ...

--------------------------------------------------------------------------
-- Vanilla-only tameable-creature data, transcribed directly from
-- Petopia Classic (https://www.wow-petopia.com/classic/abilities.php),
-- fetched 2026-09-29. This is the sole source of tameable-creature/
-- zone/level data for the addon (no generated/TBC-sourced mob file is
-- used), keyed directly by ability key and rank number so it needs no
-- separate DB-builder function.
--
-- The "screech" entries below only list Carrion Bird sources: on
-- Forever this ability is Carrion-Bird-exclusive (renamed to
-- Demoralizing Screech - see Data\PetAbilitiesData.lua), whereas
-- Petopia's page covers the old shared Carrion Bird/Bat/Owl version;
-- non-Carrion-Bird entries were removed accordingly.
--
-- ns.PETOPIA_TAME_MOBS[abilityKey][rankNumber] = {
--     { name, family, levels, zone }, ...
-- }
--------------------------------------------------------------------------

ns.PETOPIA_TAME_MOBS = {

    bite = {
        [1] = {
            {"Juvenile Vuldren","Fox","1","Zephras Isle"},
            {"Ragged Scavenger","Wolf","2-3","Tirisfal Glades"},
            {"Night Web Spider","Spider","3-4","Tirisfal Glades"},
            {"Prairie Wolf","Wolf","5-6","Mulgore"},
            {"Night Web Matriarch","Spider","5","Tirisfal Glades"},
            {"Githyiss the Vile","Spider","5","Teldrassil"},
            {"Forest Spider","Spider","5-6","Elwynn Forest"},
            {"Vuldren","Fox","6","Zephras Isle"},
            {"Snow Tracker Wolf","Wolf","6-7","Dun Morogh"},
            {"Prairie Stalker","Wolf","7-8","Mulgore"},
            {"Gray Forest Wolf","Wolf","7-8","Elwynn Forest"},
            {"Webwood Venomfang","Spider","7-8","Teldrassil"},
            {"Winter Wolf","Wolf","7-8","Dun Morogh"},
            {"Ukorsbane","Spider","8 Elite","Durotar"},
            {"Dreadmaw Crocolisk","Crocolisk","9-11","Durotar"},
        },
        [2] = {
            {"Vulgara the Insatiable","Wolf","8","Zephras Isle"},
            {"Starving Winter Wolf","Wolf","8-9","Dun Morogh"},
            {"Webwood Silkspinner","Spider","8-9","Teldrassil"},
            {"Prowler","Wolf","9-10","Elwynn Forest"},
            {"Vicious Night Web Spider","Spider","9-10","Tirisfal Glades"},
            {"Prairie Wolf Alpha","Wolf","9-10","Mulgore"},
            {"Forest Lurker","Spider","10-11","Loch Modan"},
            {"Coyote","Wolf","10-11","Westfall"},
            {"Giant Webwood Spider","Spider","10-11","Teldrassil"},
            {"Worg","Wolf","10-11","Silverpine Forest"},
            {"Timber","Wolf","10","Dun Morogh"},
            {"Coyote Packleader","Wolf","11-12","Westfall"},
            {"Lady Sathrah","Spider","12","Teldrassil"},
            {"Loch Crocolisk","Crocolisk","14-15","Loch Modan"},
            {"Tarantula","Spider","15-16","Redridge Mountains"},
            {"Oasis Snapjaw","Turtle","15-16","The Barrens"},
        },
        [3] = {
            {"Bloodsnout Worg","Wolf","16-17","Silverpine Forest"},
            {"Deepmoss Creeper","Spider","16-17","Stonetalon Mountains"},
            {"Wood Lurker","Spider","17-18","Loch Modan"},
            {"Deviate Crocolisk","Crocolisk","18-19","Wailing Caverns (Dungeon)"},
            {"Greater Tarantula","Spider","19-20","Redridge Mountains"},
            {"Ghostpaw Runner","Wolf","19-20","Ashenvale"},
            {"Deepmoss Webspinner","Spider","19-20","Stonetalon Mountains"},
            {"Shanda the Spinner","Spider","19","Loch Modan"},
            {"Kresh","Turtle","20","Wailing Caverns (Dungeon)"},
            {"Forest Moss Creeper","Spider","20-21","Hillsbrad Foothills"},
            {"Besseleth","Spider","21","Stonetalon Mountains"},
            {"Green Recluse","Spider","21-22","Duskwood"},
            {"Large Loch Crocolisk","Crocolisk","22","Loch Modan"},
            {"Chatter","Spider","23","Redridge Mountains"},
            {"Lupos","Wolf","23","Duskwood"},
            {"Aku'mai Fisher","Turtle","23-24","Blackfathom Deeps (Dungeon)"},
            {"Creepthess","Spider","24","Hillsbrad Foothills"},
        },
        [4] = {
            {"Leech Widow","Spider","24","Wetlands"},
            {"Giant Moss Creeper","Spider","24-25","Hillsbrad Foothills"},
            {"Black Ravager","Wolf","24-25","Duskwood"},
            {"Ghamoo-ra","Turtle","25","Blackfathom Deeps (Dungeon)"},
            {"Giant Wetlands Crocolisk","Crocolisk","25-26","Wetlands"},
            {"Black Ravager Mastiff","Wolf","25-26","Duskwood"},
            {"Highland Tortoise","Turtle","26","Wetlands"},
            {"Elder Moss Creeper","Spider","26-27","Hillsbrad Foothills"},
            {"Aku'mai Snapjaw","Turtle","26-27","Blackfathom Deeps (Dungeon)"},
            {"Naraxis","Spider","27","Duskwood"},
            {"Ghostpaw Alpha","Wolf","27-28","Ashenvale"},
            {"Wildthorn Lurker","Spider","28-29","Ashenvale"},
            {"Snapjaw","Turtle","30-31","Hillsbrad Foothills"},
            {"Cranky Benj","Turtle","32","Alterac Mountains"},
        },
        [5] = {
            {"Plains Creeper","Spider","32-33","Arathi Highlands"},
            {"Sparkleshell Snapper","Turtle","34-35","Thousand Needles"},
            {"Crag Coyote","Wolf","35-36","Badlands"},
            {"Drywallow Crocolisk","Crocolisk","35-36","Dustwallow Marsh"},
            {"Giant Plains Creeper","Spider","35-36","Arathi Highlands"},
            {"Darkfang Spider","Spider","35-36","Dustwallow Marsh"},
            {"Mudrock Tortoise","Turtle","36-37","Dustwallow Marsh"},
            {"Darkfang Lurker","Spider","36-37","Dustwallow Marsh"},
            {"Mottled Drywallow Crocolisk","Crocolisk","38-39","Dustwallow Marsh"},
            {"Darkfang Creeper","Spider","38-39","Dustwallow Marsh"},
        },
        [6] = {
            {"Barnabus","Wolf","38","Badlands"},
            {"Ripscale","Crocolisk","39","Dustwallow Marsh"},
            {"Drywallow Daggermaw","Crocolisk","40-41","Dustwallow Marsh"},
            {"Longtooth Runner","Wolf","40-41","Feralas"},
            {"Deathstrike Tarantula","Spider","40-41","Swamp of Sorrows"},
            {"Sawtooth Snapper","Crocolisk","41-42","Swamp of Sorrows"},
            {"Mudrock Snapjaw","Turtle","41-42","Dustwallow Marsh"},
            {"Old Cliff Jumper","Wolf","42","The Hinterlands"},
            {"Snarler","Wolf","42","Feralas"},
            {"Deadmire","Crocolisk","45","Dustwallow Marsh"},
            {"Timberweb Recluse","Spider","47-48","Azshara"},
            {"Felpaw Wolf","Wolf","47-48","Felwood"},
            {"Death Howl","Wolf","49","Felwood"},
        },
        [7] = {
            {"Rekk'tilac","Spider","48","Searing Gorge"},
            {"Saltwater Snapjaw","Turtle","49-50","The Hinterlands"},
            {"Cave Creeper","Spider","50-52","Blackrock Depths (Dungeon)"},
            {"Sewer Beast","Crocolisk","50","Stormwind City"},
            {"Vilebranch Raiding Wolf","Wolf","50-51","The Hinterlands"},
            {"Felpaw Ravager","Wolf","51-52","Felwood"},
            {"Ironback","Turtle","51","The Hinterlands"},
            {"Uhk'loc","Gorilla","52","Un'Goro Crater"},
            {"Diseased Wolf","Wolf","53-54","Western Plaguelands"},
            {"Plague Lurker","Spider","54-55","Western Plaguelands"},
        },
        [8] = {
            {"Bloodaxe Worg","Wolf","56-57","Blackrock Spire (Dungeon)"},
        },
    },

    charge = {
        [1] = {
            {"Young Thistle Boar","Boar","1-2","Teldrassil"},
            {"Mottled Boar","Boar","1-2","Durotar"},
            {"Thistle Boar","Boar","2-3","Teldrassil"},
            {"Battleboar","Boar","3-4","Mulgore"},
            {"Small Crag Boar","Boar","3","Dun Morogh"},
            {"Bristleback Battleboar","Boar","4-5","Mulgore"},
            {"Crag Boar","Boar","5-6","Dun Morogh"},
            {"Dire Mottled Boar","Boar","6-7","Durotar"},
            {"Large Crag Boar","Boar","6-7","Dun Morogh"},
            {"Porcine Entourage","Boar","7","Elwynn Forest"},
            {"Elder Crag Boar","Boar","7-8","Dun Morogh"},
            {"Rockhide Boar","Boar","7-8","Elwynn Forest"},
            {"Stonetusk Boar","Boar","7-8","Elwynn Forest"},
            {"Elder Mottled Boar","Boar","8-9","Durotar"},
            {"Princess","Boar","9","Elwynn Forest"},
            {"Scarred Crag Boar","Boar","9-10","Dun Morogh"},
            {"Corrupted Mottled Boar","Boar","10-11","Durotar"},
            {"Longsnout","Boar","10-11","Elwynn Forest"},
            {"Mountain Boar","Boar","10-11","Loch Modan"},
        },
        [2] = {
            {"Young Goretusk","Boar","12-13","Westfall"},
            {"Goretusk","Boar","14-15","Westfall"},
            {"Mangy Mountain Boar","Boar","14-15","Loch Modan"},
            {"Elder Mountain Boar","Boar","16-17","Loch Modan"},
            {"Great Goretusk","Boar","16-17","Redridge Mountains / Westfall"},
        },
        [3] = {
            {"Bellygrub","Boar","24","Redridge Mountains"},
            {"Agam'ar","Boar","24-25","Razorfen Kraul (Dungeon)"},
            {"Raging Agam'ar","Boar","25-26","Razorfen Kraul (Dungeon)"},
            {"Rotting Agam'ar","Boar","28","Razorfen Kraul (Dungeon)"},
        },
        -- [4] intentionally omitted: "No known training source" per Petopia
        [5] = {
            {"Ashmane Boar","Boar","48-49","Blasted Lands"},
            {"Grunter","Boar","50","Blasted Lands"},
        },
        [6] = {
            {"Plagued Swine","Boar","60","Eastern Plaguelands"},
        },
    },

    claw = {
        [1] = {
            {"Scrawny Ursera","Bear","3-4","Zephras Isle"},
            {"Scorpid Worker","Scorpid","3","Durotar"},
            {"Sarkoth","Scorpid","4","Durotar"},
            {"Ursera Scavenger","Bear","4","Zephras Isle"},
            {"Urs'anah","Bear","5","Zephras Isle"},
            {"Pygmy Surf Crawler","Crab","5-6","Durotar"},
            {"Strigid Owl","Bird of Prey","5-6","Teldrassil"},
            {"Ice Claw Bear","Bear","7-8","Dun Morogh"},
            {"Highlands Ursera","Bear","8","Zephras Isle"},
        },
        [2] = {
            {"Windsong Crawler","Crab","8-9","Zephras Isle"},
            {"Young Forest Bear","Bear","8-9","Elwynn Forest"},
            {"Strigid Hunter","Bird of Prey","8-9","Teldrassil"},
            {"Encrusted Surf Crawler","Crab","9-10","Durotar"},
            {"Venomtail Scorpid","Scorpid","9-10","Durotar"},
            {"Mangeclaw","Bear","11","Dun Morogh"},
            {"Death Flayer","Scorpid","11","Durotar"},
            {"Ferocious Grizzled Bear","Bear","11-12","Silverpine Forest"},
            {"Thistle Bear","Bear","11-12","Darkshore"},
            {"Bjarn","Bear","12","Dun Morogh"},
            {"Elmpaw","Bear","12","Elwynn Forest"},
            {"Tide Crawler","Crab","12-14","Darkshore"},
        },
        [3] = {
            {"Shadowgale Ursera","Bear","10","Zephras Isle"},
            {"Black Bear Patriarch","Bear","16-17","Loch Modan"},
            {"Shore Crawler","Crab","17-18","Westfall"},
            {"Den Mother","Bear","18-19","Darkshore"},
            {"Ghost Saber","Cat","19-20","Darkshore"},
            {"Clattering Crawler","Crab","19-20","Ashenvale"},
            {"Ol' Sooty","Bear","20","Loch Modan"},
            {"Gray Bear","Bear","21-22","Hillsbrad Foothills"},
            {"Ashenvale Bear","Bear","21-22","Ashenvale"},
            {"Skittering Crustacean","Crab","22-23","Blackfathom Deeps (Dungeon)"},
            {"Snapping Crustacean","Crab","23-24","Blackfathom Deeps (Dungeon)"},
        },
        [4] = {
            {"Elder Ashenvale Bear","Bear","25-26","Ashenvale"},
            {"Barbed Crustacean","Crab","25-26","Blackfathom Deeps (Dungeon)"},
            {"Scorpashi Snapper","Scorpid","30-31","Desolace"},
            {"Scorpid Reaver","Scorpid","31-32","Thousand Needles"},
        },
        [5] = {
            {"Scorpashi Lasher","Scorpid","34-35","Desolace"},
            {"Vile Sting","Scorpid","35","Thousand Needles"},
            {"Drywallow Snapper","Crocolisk","37-38","Dustwallow Marsh"},
            {"Venomlash Scorpid","Scorpid","39-40","Uldaman (Dungeon)"},
        },
        [6] = {
            {"Scorpid Hunter","Scorpid","40-41","Tanaris"},
            {"Silt Crawler","Crab","40-41","Swamp of Sorrows"},
            {"Ironfur Bear","Bear","41-42","Feralas"},
            {"King Bangalash","Cat","43","Stranglethorn Vale"},
            {"Old Grizzlegut","Bear","43","Feralas"},
            {"Monstrous Crawler","Crab","43-44","Swamp of Sorrows"},
        },
        [7] = {
            {"Ironfur Patriarch","Bear","48-49","Feralas"},
            {"Angerclaw Mauler","Bear","49-50","Felwood"},
            {"Mongress","Bear","50","Felwood"},
            {"Ironbeak Hunter","Bird of Prey","50-51","Felwood"},
            {"Olm the Wise","Bird of Prey","52","Felwood"},
            {"Shardtooth Bear","Bear","53-54","Winterspring"},
            {"Clack the Reaver","Scorpid","53","Blasted Lands"},
            {"Winterspring Owl","Bird of Prey","54-56","Winterspring"},
            {"Deathlash Scorpid","Scorpid","54-55","Burning Steppes"},
            {"Diseased Grizzly","Bear","55-56","Western Plaguelands"},
        },
        [8] = {
            {"Winterspring Screecher","Bird of Prey","57-59","Winterspring"},
            {"Elder Shardtooth","Bear","57-58","Winterspring"},
        },
    },

    cower = {
        [1] = {
            {"Prideclaw","Cat","5-6","Zephras Isle"},
            {"Nightsaber","Cat","5-6","Teldrassil"},
            {"Juvenile Snow Leopard","Cat","5-6","Dun Morogh"},
            {"Greater Duskbat","Bat","6-7","Tirisfal Glades"},
            {"Flatland Cougar","Cat","7-8","Mulgore"},
            {"Durotar Tiger","Cat","7-8","Durotar"},
            {"Shriekling Fledgling","Raptor","8-9","Zephras Isle"},
            {"Elder Plainstrider","Tallstrider","8-9","Mulgore"},
            {"Shal'ma","Cat","9","Durotar"},
            {"Mazzranache","Tallstrider","9","Mulgore"},
            {"Child of Jai'vhanel","Bird of Prey","10","Darkshore"},
            {"Moonstalker Runt","Cat","10-11","Darkshore"},
            {"Foreststrider Fledgling","Tallstrider","11-13","Darkshore"},
            {"Fleeting Plainstrider","Tallstrider","12-13","The Barrens"},
        },
        [2] = {
            {"Savannah Patriarch","Cat","15-16","The Barrens"},
            {"Ornery Plainstrider","Tallstrider","16-17","The Barrens"},
            {"Giant Foreststrider","Tallstrider","17-19","Darkshore"},
            {"Moonstalker Sire","Cat","17-18","Darkshore"},
            {"Twilight Runner","Cat","23-24","Stonetalon Mountains"},
            {"Starving Mountain Lion","Cat","23-24","Hillsbrad Foothills"},
        },
        [3] = {
            {"Crag Stalker","Cat","25-26","Thousand Needles"},
            {"Feral Mountain Lion","Cat","27-28","Hillsbrad Foothills"},
            {"Kraul Bat","Bat","30-31","Razorfen Kraul (Dungeon)"},
            {"Young Panther","Cat","30-31","Stranglethorn Vale"},
            {"Young Stranglethorn Tiger","Cat","30-31","Stranglethorn Vale"},
            {"Greater Kraul Bat","Bat","32","Razorfen Kraul (Dungeon)"},
            {"Panther","Cat","32-33","Stranglethorn Vale"},
        },
        [4] = {
            {"Ridge Stalker","Cat","36-37","Badlands"},
            {"Shrike Bat","Bat","38-39","Uldaman (Dungeon)"},
            {"Ridge Huntress","Cat","38-39","Badlands"},
        },
        [5] = {
            {"Jaguero Stalker","Cat","50","Stranglethorn Vale"},
            {"Plaguebat","Bat","53-55","Eastern Plaguelands"},
            {"Noxious Plaguebat","Bat","54-56","Eastern Plaguelands"},
        },
        [6] = {
            {"Frostsaber Cub","Cat","55-56","Winterspring"},
            {"Monstrous Plaguebat","Bat","56-58","Eastern Plaguelands"},
        },
    },

    dash = {
        [1] = {
            {"Kurzen War Tiger","Cat","32-33","Stranglethorn Vale"},
            {"Stranglethorn Tiger","Cat","32-33","Stranglethorn Vale"},
            {"Bonepaw Hyena","Hyena","33-35","Desolace"},
            {"Scarlet Tracking Hound","Hyena","33-34","Scarlet Monastery (Dungeon)"},
            {"Crag Coyote","Wolf","35-36","Badlands"},
            {"Spot","Wolf","35","Dustwallow Marsh"},
            {"Swamp Jaguar","Cat","36-37","Swamp of Sorrows"},
            {"Magram Bonepaw","Hyena","37-38","Desolace"},
            {"Feral Crag Coyote","Wolf","37-38","Badlands"},
            {"Broken Tooth","Cat","37","Badlands"},
            {"Sin'Dall","Cat","37","Stranglethorn Vale"},
            {"Elder Crag Coyote","Wolf","39-40","Badlands"},
        },
        [2] = {
            {"Longtooth Runner","Wolf","40-41","Feralas"},
            {"Ridge Stalker Patriarch","Cat","40-41","Badlands"},
            {"Bhag'thera","Cat","40","Stranglethorn Vale"},
            {"Starving Blisterpaw","Hyena","41-42","Tanaris"},
            {"Rabid Crag Coyote","Wolf","42-43","Badlands"},
            {"Old Cliff Jumper","Wolf","42","The Hinterlands"},
            {"Elder Shadowmaw Panther","Cat","42-43","Stranglethorn Vale"},
            {"Murderous Blisterpaw","Hyena","43","Tanaris"},
            {"King Bangalash","Cat","43","Stranglethorn Vale"},
            {"Blisterpaw Hyena","Hyena","44-45","Tanaris"},
            {"Silvermane Stalker","Wolf","47-48","The Hinterlands"},
            {"Rabid Blisterpaw","Hyena","47-48","Tanaris"},
        },
        [3] = {
            {"Broodwidow","Spider","16","Ruins of Lordaeron (Dungeon)"},
            {"Vilebranch Raiding Wolf","Wolf","50-51","The Hinterlands"},
            {"Grunter","Boar","50","Blasted Lands"},
            {"Ravage","Hyena","51","Blasted Lands"},
            {"Scarshield Worg","Wolf","53-54","Blackrock Spire (Dungeon)"},
            {"Blackrock Worg","Wolf","54-55","Burning Steppes"},
            {"Bloodaxe Worg","Wolf","56-57","Blackrock Spire (Dungeon)"},
            {"Rak'Shiri","Cat","57","Winterspring"},
            {"Frostsaber Huntress","Cat","58-59","Winterspring"},
            {"Frostsaber Stalker","Cat","59-60","Winterspring"},
            {"Zulian Panther","Cat","60","Zul'Gurub (Raid)"},
        },
    },

    dive = {
        [1] = {
            {"Kraul Bat","Bat","30-31","Razorfen Kraul (Dungeon)"},
            {"Young Mesa Buzzard","Carrion Bird","31-32","Arathi Highlands"},
            {"Greater Kraul Bat","Bat","32","Razorfen Kraul (Dungeon)"},
            {"Mesa Buzzard","Carrion Bird","34-35","Arathi Highlands"},
            {"Wayward Buzzard","Carrion Bird","35-37","Badlands"},
            {"Dread Flyer","Carrion Bird","36-37","Desolace"},
            {"Shrike Bat","Bat","38-39","Uldaman (Dungeon)"},
        },
        [2] = {
            {"Vale Screecher","Wind Serpent","41-43","Feralas"},
            {"Roc","Carrion Bird","42-43","Tanaris"},
            {"Fire Roc","Carrion Bird","43-45","Tanaris"},
            {"Rogue Vale Screecher","Wind Serpent","44-46","Feralas"},
            {"Greater Firebird","Carrion Bird","46","Tanaris"},
            {"Searing Roc","Carrion Bird","47-49","Tanaris"},
            {"Ironbeak Owl","Bird of Prey","48-49","Felwood"},
            {"Arash-ethis","Wind Serpent","49","Feralas"},
        },
        [3] = {
            {"Carrion Vulture","Carrion Bird","50-52","Western Plaguelands"},
            {"Ironbeak Hunter","Bird of Prey","50-51","Felwood"},
            {"Dark Screecher","Bat","50-52","Blackrock Depths (Dungeon)"},
            {"Spawn of Hakkar","Wind Serpent","51","The Temple of Atal'Hakkar (Dungeon)"},
            {"Spiteflayer","Carrion Bird","52","Blasted Lands"},
            {"Olm the Wise","Bird of Prey","52","Felwood"},
            {"Ironbeak Screecher","Bird of Prey","52-53","Felwood"},
            {"Plaguebat","Bat","53-55","Eastern Plaguelands"},
            {"Winterspring Owl","Bird of Prey","54-56","Winterspring"},
            {"Zaricotl","Carrion Bird","55","Badlands"},
            {"Winterspring Screecher","Bird of Prey","57-59","Winterspring"},
        },
    },

    dustcloud = {
        [1] = {
            {"Galestrider","Tallstrider","5-6","Zephras Isle"},
            {"Ornery Galestrider","Tallstrider","8","Zephras Isle"},
        },
    },

    furioushowl = {
        [1] = {
            {"Prairie Wolf Alpha","Wolf","9-10","Mulgore"},
            {"Worg","Wolf","10-11","Silverpine Forest"},
            {"Coyote Packleader","Wolf","11-12","Westfall"},
            {"Coldrasp","Wolf","12","Tirisfal Glades"},
            {"Mist Howler","Wolf","22","Ashenvale"},
        },
        [2] = {
            {"Black Ravager Mastiff","Wolf","25-26","Duskwood"},
            {"Ghostpaw Alpha","Wolf","27-28","Ashenvale"},
            {"Elder Crag Coyote","Wolf","39-40","Badlands"},
            {"Longtooth Howler","Wolf","43-44","Feralas"},
            {"Silvermane Howler","Wolf","45-46","The Hinterlands"},
        },
        [3] = {
            {"Longtooth Runner","Wolf","40-41","Feralas"},
            {"Snarler","Wolf","42","Feralas"},
            {"Silvermane Wolf","Wolf","43-44","The Hinterlands"},
            {"Felpaw Wolf","Wolf","47-48","Felwood"},
            {"Death Howl","Wolf","49","Felwood"},
        },
        [4] = {
            {"Bloodaxe Worg","Wolf","56-57","Blackrock Spire (Dungeon)"},
        },
    },

    -- Rank 1 intentionally omitted: Petopia lists it as "No known training source"
    lightningbreath = {
        [2] = {
            {"Deviate Coiler","Wind Serpent","15-16","Wailing Caverns (Dungeon)"},
            {"Deviate Stinglash","Wind Serpent","16-17","Wailing Caverns (Dungeon)"},
            {"Thunderhawk Hatchling","Wind Serpent","18-20","The Barrens"},
            {"Thunderhawk Cloudscraper","Wind Serpent","20-22","The Barrens"},
            {"Deviate Dreadfang","Wind Serpent","20-21","Wailing Caverns (Dungeon)"},
            {"Deviate Venomwing","Wind Serpent","20-21","Wailing Caverns (Dungeon)"},
            {"Greater Thunderhawk","Wind Serpent","23-24","The Barrens"},
        },
        [3] = {
            {"Washte Pawne","Wind Serpent","25","The Barrens"},
            {"Cloud Serpent","Wind Serpent","25-26","Thousand Needles"},
            {"Venomous Cloud Serpent","Wind Serpent","26-28","Thousand Needles"},
            {"Elder Cloud Serpent","Wind Serpent","27-29","Thousand Needles"},
        },
        [4] = {
            {"Vale Screecher","Wind Serpent","41-43","Feralas"},
            {"Rogue Vale Screecher","Wind Serpent","44-46","Feralas"},
        },
        [5] = {
            {"Hakkari Sapper","Wind Serpent","49-50","The Temple of Atal'Hakkar (Dungeon)"},
            {"Hakkari Frostwing","Wind Serpent","49-50","The Temple of Atal'Hakkar (Dungeon)"},
            {"Arash-ethis","Wind Serpent","49","Feralas"},
            {"Spawn of Hakkar","Wind Serpent","51","The Temple of Atal'Hakkar (Dungeon)"},
        },
        [6] = {
            {"Son of Hakkar","Wind Serpent","60","Zul'Gurub (Raid)"},
        },
    },

    prowl = {
        [1] = {
            {"Mountain Lion","Cat","32-33","Alterac Mountains"},
            {"Ridge Stalker","Cat","36-37","Badlands"},
            {"Shadowmaw Panther","Cat","37-38","Stranglethorn Vale"},
            {"Shadow Panther","Cat","39-40","Swamp of Sorrows"},
        },
        [2] = {
            {"Ridge Stalker Patriarch","Cat","40-41","Badlands"},
            {"Elder Shadowmaw Panther","Cat","42-43","Stranglethorn Vale"},
        },
        [3] = {
            {"Jaguero Stalker","Cat","50","Stranglethorn Vale"},
            {"Frostsaber Stalker","Cat","59-60","Winterspring"},
        },
    },

    -- Savage Rend is otherwise Raptor-only (see PetAbilitiesData.lua), but
    -- Forever's own data lists a Bear and a Bird of Prey teaching it too -
    -- transcribed as-is from the source spreadsheet rather than treated as
    -- an error, since this table is informational "where to find a
    -- teacher" data, independent of the ability's own family-eligibility
    -- list.
    savagerend = {
        [1] = {
            {"Shriekling Matriarch","Raptor","9","Zephras Isle"},
            {"Shadowgale Shriekling","Bird of Prey","10-11","Zephras Isle"},
            {"Mystmane","Bear","13","Zephras Isle"},
        },
    },

    scorpidpoison = {
        [1] = {
            {"Venomtail Scorpid","Scorpid","9-10","Durotar"},
            {"Corrupted Scorpid","Scorpid","10-11","Durotar"},
            {"Death Flayer","Scorpid","11","Durotar"},
            {"Silithid Creeper","Scorpid","20-21","The Barrens"},
            {"Silithid Swarmer","Scorpid","21-22","The Barrens"},
        },
        [2] = {
            {"Scorpashi Snapper","Scorpid","30-31","Desolace"},
            {"Scorpid Reaver","Scorpid","31-32","Thousand Needles"},
            {"Scorpid Terror","Scorpid","33-34","Thousand Needles"},
            {"Cleft Scorpid","Scorpid","35-36","Uldaman (Dungeon)"},
            {"Vile Sting","Scorpid","35","Thousand Needles"},
            {"Scorpashi Venomlash","Scorpid","38-39","Desolace"},
        },
        [3] = {
            {"Scorpid Hunter","Scorpid","40-41","Tanaris"},
            {"Deadly Cleft Scorpid","Scorpid","42-43","Uldaman (Dungeon)"},
            {"Scorpid Tail Lasher","Scorpid","43-44","Tanaris"},
            {"Scorpid Duneburrower","Scorpid","46-47","Tanaris"},
            {"Scorpid Dunestalker","Scorpid","46-47","Tanaris"},
            {"Scorpok Stinger","Scorpid","50-51","Blasted Lands"},
            {"Deep Stinger","Scorpid","50-52","Blackrock Depths (Dungeon)"},
            {"Venomtip Scorpid","Scorpid","52-53","Burning Steppes"},
            {"Deathlash Scorpid","Scorpid","54-55","Burning Steppes"},
            {"Stonelash Scorpid","Scorpid","54-55","Silithus"},
        },
        [4] = {
            {"Krellack","Scorpid","56","Silithus"},
            {"Stonelash Pincer","Scorpid","56-57","Silithus"},
            {"Firetail Scorpid","Scorpid","56-57","Burning Steppes"},
            {"Stonelash Flayer","Scorpid","58-59","Silithus"},
        },
    },

    -- Demoralizing Screech (renamed from Screech, Carrion-Bird-exclusive
    -- on Forever): non-Carrion-Bird sources from Petopia's shared-Screech
    -- page removed. No Carrion Bird source is recorded for rank 4.
    screech = {
        [1] = {
            {"Greater Fleshripper","Carrion Bird","16-17","Westfall"},
        },
        [2] = {
            {"Salt Flats Vulture","Carrion Bird","32-34","Thousand Needles"},
            {"Dread Ripper","Carrion Bird","39-40","Desolace"},
        },
        [3] = {
            {"Carrion Vulture","Carrion Bird","50-52","Western Plaguelands"},
        },
    },

    shellshield = {
        [1] = {
            {"Kresh","Turtle","20","Wailing Caverns (Dungeon)"},
            {"Aku'mai Fisher","Turtle","23-24","Blackfathom Deeps (Dungeon)"},
            {"Ghamoo-ra","Turtle","25","Blackfathom Deeps (Dungeon)"},
            {"Aku'mai Snapjaw","Turtle","26-27","Blackfathom Deeps (Dungeon)"},
            {"Snapjaw","Turtle","30-31","Hillsbrad Foothills"},
            {"Cranky Benj","Turtle","32","Alterac Mountains"},
        },
    },

    thunderstomp = {
        [1] = {
            {"Mistvale Gorilla","Gorilla","32-33","Stranglethorn Vale"},
            {"Jungle Thunderer","Gorilla","37-38","Stranglethorn Vale"},
        },
        [2] = {
            {"Elder Mistvale Gorilla","Gorilla","40-41","Stranglethorn Vale"},
            {"Groddoc Thunderer","Gorilla","49-50","Feralas"},
        },
        [3] = {
            {"Un'Goro Thunderer","Gorilla","52-53","Un'Goro Crater"},
            {"U'cha","Gorilla","55","Un'Goro Crater"},
        },
    },

    tricklersdance = {
        [1] = {
            {"Vuldren Alpha","Fox","10","Zephras Isle"},
        },
    },

    web = {
        [2] = {
            {"Moss Stalker","Spider","12","Silverpine Forest"},
        },
    },
}
