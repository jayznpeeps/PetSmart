local ADDON_NAME, ns = ...

--------------------------------------------------------------------------
-- Rare/unique tameable pet spawns.
--
-- List of which 66 rares to include: Petopia Classic's rare-pet index
-- (https://www.wow-petopia.com/classic/browse.php?id=rare).
-- Per-rare spawn coordinates and descriptions: wowhead.com and
-- warcraft.wiki.gg (fetched 2026-10-02). Coordinates are given as the
-- standard 0-100 zone-percentage system. A line's trailing "-- approximate"
-- comment means no exact coordinate was found and the value is a
-- best-effort estimate (a named landmark translated to a rough position,
-- or a zone-center guess when no landmark was findable at all) - worth a
-- quick in-game check before relying on it for precision.
--
-- ns.ZONE_MAP_IDS[zoneName] = the zone's Classic-era UiMapID (for
-- C_Map/WorldMapFrame positioning). Four entries (flagged below) could
-- not be independently confirmed within the research pass that produced
-- this file; verify with /dump C_Map.GetBestMapForUnit("player") while
-- standing in that zone if the pin for those ends up misplaced.
--
-- ns.RARE_SPAWNS[i] = { name, familyId, level, zone, mapID, x, y, description }
--
-- 8 Forever-specific rares added 2026-10-03 (Coldrasp, Fernfeather,
-- Ghostfang, Matriarch Bristlefur, Mystmane, Nightscreech, Shal'ma,
-- Slydris), sourced from a user-supplied spreadsheet of Forever tameable-
-- pet data, cross-referenced against this server's own NpcInfoTables.lua
-- (same source RARE_LOCATION_OVERRIDES already draws on) for their
-- RARE_LOCATION_OVERRIDES centroid coordinates - that data confirmed every
-- spreadsheet zone/coordinate pairing. Public wowhead.com/forever pages for
-- these specific named rares aren't indexed/renderable yet (Forever is too
-- new), so their `description` lines are original flavor text written from
-- the spreadsheet's own data plus general Zephras Isle zone lore (a
-- floating, Skywall-inspired Skyborne starting zone), not transcribed from
-- an existing wiki entry.
--------------------------------------------------------------------------

ns.ZONE_MAP_IDS = {
    ["Alterac Mountains"]      = 36,   -- verify in-game (small contested zone, less documented)
    ["Arathi Highlands"]       = 45,
    ["Ashenvale"]              = 63,
    ["Azshara"]                = 16,
    ["Badlands"]               = 15,
    ["Blasted Lands"]          = 4,
    ["Burning Steppes"]        = 41,
    ["Darkshore"]              = 62,
    ["Desolace"]               = 66,
    ["Dun Morogh"]             = 27,
    ["Durotar"]                = 1,
    ["Dustwallow Marsh"]       = 70,
    ["Duskwood"]               = 10,
    ["Eastern Plaguelands"]    = 139,
    ["Elwynn Forest"]          = 37,
    ["Feralas"]                = 69,
    ["Felwood"]                = 77,
    ["Hillsbrad Foothills"]    = 267,  -- verify in-game
    ["Loch Modan"]             = 38,
    ["Mulgore"]                = 87,
    ["Razorfen Kraul"]         = 2057, -- verify in-game (dungeon map id, low confidence)
    ["Redridge Mountains"]     = 44,
    ["Searing Gorge"]          = 32,
    ["Silithus"]               = 81,
    ["Silverpine Forest"]      = 130,
    ["Stormwind City"]         = 1519, -- verify in-game (instanced city map, low confidence)
    ["Stonetalon Mountains"]   = 406,
    ["Stranglethorn Vale"]     = 33,
    ["Swamp of Sorrows"]       = 8,
    ["Tanaris"]                = 71,
    ["Teldrassil"]             = 57,
    ["The Barrens"]            = 17,
    ["The Hinterlands"]        = 26,
    ["Thousand Needles"]       = 64,
    ["Tirisfal Glades"]        = 85,
    ["Un'Goro Crater"]         = 76,   -- verify in-game
    ["Westfall"]               = 40,
    ["Western Plaguelands"]    = 28,
    ["Wetlands"]               = 56,
    ["Winterspring"]           = 83,
    -- Zephras Isle is Forever-original content (the Skyborne starting
    -- zone) with no Classic-era equivalent, so there's no legacy id to
    -- fall back on here - this value is this server's own in-client
    -- mapID, straight from the user-supplied spreadsheet, not independently
    -- re-confirmed. Every Zephras Isle rare below also has a
    -- RARE_LOCATION_OVERRIDES entry (that server's own zoneID, 2521),
    -- which takes precedence over this anyway.
    ["Zephras Isle"]           = 16593,
}

-- Petopia's rare-pet family names don't all match Forever's current
-- family names 1:1 (e.g. Forever renamed "Owl" to "Bird of Prey").
local FAMILY_NAME_FIXUPS = {
    ["Owl"] = "Bird of Prey",
}

local raw = {
    -- Bats
    { name = "Ressan the Needler", family = "Bat", level = "11", zone = "Tirisfal Glades",
      x = 42.0, y = 47.0, -- approximate
      description = "A white, pink-winged rare bat that spawns near Cold Hearth Manor, using a Sonic Burst that damages and silences nearby enemies." },
    { name = "Blind Hunter", family = "Bat", level = "32 Elite", zone = "Razorfen Kraul", dungeon = true,
      x = 50.0, y = 50.0, -- approximate (deep inside the dungeon)
      description = "An albino rare bat native to the deepest, lightless reaches of Razorfen Kraul, which may explain its unusual coloring and blindness." },

    -- Bears
    { name = "Big Samras", family = "Bear", level = "27", zone = "Hillsbrad Foothills",
      x = 60.0, y = 45.0, -- approximate (northwest of Durnholde Keep)
      description = "A rare plagued bear roaming northwest of Durnholde Keep, formerly known as Little Samras before its corrupted Forsaken-influenced appearance." },
    { name = "Ursol'lok", family = "Bear", level = "31", zone = "Ashenvale",
      x = 89.6, y = 46.6,
      description = "A rare black bear found roaming northeastern Ashenvale, with a leaping charge attack and an armor-reducing swipe." },
    { name = "Old Grizzlegut", family = "Bear", level = "43", zone = "Feralas",
      x = 45.0, y = 70.0, -- approximate (Ruins of Isildien)
      description = "A rare black bear found prowling the Ruins of Isildien in southern Feralas." },
    { name = "Old Vicejaw", family = "Bear", level = "14", zone = "Silverpine Forest",
      x = 45.0, y = 55.0, -- approximate (between Ambermill and Deep Elem Mine)
      description = "A rare brown bear that roams the area between Ambermill and Deep Elem Mine in Silverpine Forest." },
    { name = "Mongress", family = "Bear", level = "50", zone = "Felwood",
      x = 45.0, y = 70.0, -- approximate (southern Felwood)
      description = "A rare brown bear found in southern Felwood, capable of enraging, hibernating to heal, and a wide swiping attack." },
    { name = "Bjarn", family = "Bear", level = "12", zone = "Dun Morogh",
      x = 69.8, y = 56.8,
      description = "The only white bear in Dun Morogh, found in the Tundrid Hills south of Amberstill Ranch." },
    { name = "Matriarch Bristlefur", family = "Bear", level = "10", zone = "Elwynn Forest",
      x = 64.4, y = 77.0,
      points = { -- several named sightings across a wide northern Elwynn range; RARE_LOCATION_OVERRIDES below supersedes with a sourced centroid
          { x = 64.4, y = 77.0 },
          { x = 59.0, y = 80.6 },
          { x = 51.8, y = 79.2 },
      },
      description = "A rare bear that watches over her territory across a wide stretch of northern Elwynn Forest." },
    { name = "Mystmane", family = "Bear", level = "13", zone = "Zephras Isle",
      x = 60.2, y = 34.6,
      description = "A rare bear drifting through the fog-wreathed terraces of Zephras Isle, who has picked up a Savage Rend bite more typical of the island's raptors than its own kind." },

    -- Boars
    { name = "Grunter", family = "Boar", level = "50", zone = "Blasted Lands",
      x = 50.0, y = 50.0, -- approximate
      description = "A rare helboar in the Blasted Lands, historically prized as the highest-level tameable boar in the game." },

    -- Carrion Birds
    { name = "Vultros", family = "Carrion Bird", level = "26", zone = "Westfall",
      x = 40.0, y = 50.0, -- approximate (roams Dead Acre / Dust Plains / Molsen Farm / Furlbrow's / Stendel's Pond)
      points = { -- roams between several named farm sites; all approximate
          { x = 38.0, y = 46.0 }, -- Dead Acre
          { x = 44.0, y = 52.0 }, -- Dust Plains / Molsen Farm
          { x = 50.0, y = 58.0 }, -- Furlbrow's Pumpkin Patch
          { x = 55.0, y = 62.0 }, -- Stendel's Pond
      },
      description = "A rare vulture that roams several farmland sites across Westfall, including the Dead Acre and Furlbrow's Pumpkin Patch." },
    { name = "Lord Condar", family = "Carrion Bird", level = "15-16", zone = "Loch Modan",
      x = 48.0, y = 38.0, -- approximate (southwest of Farstrider Lodge)
      description = "A rare condor found southwest of Farstrider Lodge in Loch Modan." },
    { name = "Greater Firebird", family = "Carrion Bird", level = "46", zone = "Tanaris",
      x = 50.0, y = 45.0, -- approximate
      description = "A rare two-headed vulture wreathed in fire, found in Tanaris, using Crimson Fury and Fire Nova attacks." },
    { name = "Zaricotl", family = "Carrion Bird", level = "55 Elite", zone = "Badlands",
      x = 57.0, y = 52.0,
      description = "A rare white buzzard, one of the rarest colorations in the Badlands, found circling the central part of the zone." },
    { name = "Spiteflayer", family = "Carrion Bird", level = "52", zone = "Blasted Lands",
      x = 55.0, y = 55.0, -- approximate
      description = "A rare two-headed vulture found in the Blasted Lands." },

    -- Cats
    { name = "Shadowclaw", family = "Cat", level = "13", zone = "Darkshore",
      x = 40.0, y = 45.0, -- approximate (Withering Thicket, north of Ruins of Auberdine)
      description = "A rare nightsaber that stays stealthed in the Withering Thicket north of the Ruins of Auberdine." },
    { name = "Araga", family = "Cat", level = "35", zone = "Desolace",
      -- Corrected from an earlier "Alterac Mountains" mistag - every
      -- datamined source (below, RARE_LOCATION_OVERRIDES) places it in
      -- Desolace, which is also where this rare lion is actually known from.
      x = 50.0, y = 50.0, -- superseded by RARE_LOCATION_OVERRIDES below
      description = "A roaming rare lion found in Desolace." },
    { name = "Broken Tooth", family = "Cat", level = "37", zone = "Badlands",
      x = 55.0, y = 24.0, -- sourced (one of three spawn points; this is a vantage point to spot all three)
      points = { -- spawns at one of three points; only one is independently sourced, the other two are approximate spread around it
          { x = 55.0, y = 24.0 }, -- sourced
          { x = 48.0, y = 30.0 }, -- approximate
          { x = 62.0, y = 20.0 }, -- approximate
      },
      description = "The most contested rare pet in the game: a cat with a 1.0 base attack speed, the fastest available, excellent for interrupting enemy casters in PvP. Spawns at one of three points in the Badlands." },
    { name = "Duskstalker", family = "Cat", level = "9", zone = "Teldrassil",
      x = 45.0, y = 50.0, -- approximate (south of Lake Al'Ameth)
      description = "A rare frostsaber found south of Lake Al'Ameth in Teldrassil, which uses Tendon Rip to slow its prey." },
    { name = "Dishu", family = "Cat", level = "13", zone = "The Barrens",
      x = 45.0, y = 45.0, -- approximate (beneath a tree north of the Crossroads)
      description = "A rare cheetah resting beneath a tree north of the Crossroads in the Northern Barrens, alongside a pride of lions." },
    { name = "Rak'Shiri", family = "Cat", level = "57", zone = "Winterspring",
      x = 35.0, y = 40.0, -- approximate (Frostsaber Rock)
      description = "A rare aqua-colored frostsaber found at Frostsaber Rock in Winterspring, famed in lore as the quarry of a rivalry between Hemet Nesingwary and Shado 'Fitz' Farstrider." },
    { name = "Humar The Pridelord", family = "Cat", level = "23", zone = "The Barrens",
      x = 62.0, y = 33.0,
      description = "A distinctive black lion resting in the shade of a large tree northwest of Ratchet." },
    { name = "The Rake", family = "Cat", level = "10", zone = "Mulgore",
      x = 60.0, y = 45.0, -- approximate (Golden Plains, east of Thunder Bluff)
      description = "A rare lion found in the Golden Plains east of Thunder Bluff, historically valued for its fast attack speed." },
    { name = "Shal'ma", family = "Cat", level = "9", zone = "Durotar",
      x = 61.0, y = 90.0,
      points = { -- several named sightings across a wide Durotar range; RARE_LOCATION_OVERRIDES below supersedes with a sourced centroid
          { x = 61.0, y = 90.0 },
          { x = 68.6, y = 71.4 },
          { x = 63.0, y = 95.0 },
      },
      description = "A rare cat that roams widely across Durotar, from the coast up into the northern hills." },
    { name = "Ghostfang", family = "Cat", level = "10", zone = "Dun Morogh",
      x = 74.0, y = 64.0,
      points = { -- several named sightings across Dun Morogh's foothills; RARE_LOCATION_OVERRIDES below supersedes with a sourced centroid
          { x = 74.0, y = 64.0 },
          { x = 80.0, y = 46.0 },
          { x = 79.0, y = 43.0 },
          { x = 82.0, y = 55.0 },
      },
      description = "A pale rare cat that ranges widely across Dun Morogh's foothills, rarely seen twice in the same place." },

    -- Crocolisks
    { name = "Ripscale", family = "Crocolisk", level = "39", zone = "Dustwallow Marsh",
      x = 45.0, y = 45.0, -- approximate
      description = "A rare crocolisk roaming Dustwallow Marsh, using an infected bite and a bleeding rip attack." },
    { name = "Sewer Beast", family = "Crocolisk", level = "50", zone = "Stormwind City",
      x = 50.0, y = 50.0, -- approximate (the Canals)
      description = "A large albino crocolisk that lazily swims the canals of Stormwind City, near Stormwind Keep's exterior." },
    { name = "Large Loch Crocolisk", family = "Crocolisk", level = "22", zone = "Loch Modan",
      x = 45.0, y = 45.0, -- approximate (the Loch)
      description = "A rare crocolisk found in the waters of the Loch in Loch Modan." },

    -- Foxes
    { name = "Slydris", family = "Fox", level = "Unknown", zone = "Zephras Isle",
      x = 51.0, y = 51.0,
      description = "A rare fox skulking the floating terraces of Zephras Isle; sightings are scarce enough that even its exact strength remains unconfirmed." },

    -- Gorillas
    { name = "Kurmokk", family = "Gorilla", level = "42", zone = "Stranglethorn Vale",
      x = 40.0, y = 30.0, -- approximate (Mistvale Valley)
      description = "A rare gorilla found in Mistvale Valley in northern Stranglethorn Vale." },
    { name = "Uhk'loc", family = "Gorilla", level = "52", zone = "Un'Goro Crater",
      x = 45.0, y = 30.0, -- approximate (Fungal Rock)
      description = "A uniquely colored rare gorilla found at Fungal Rock in Un'Goro Crater, the only tameable gorilla of its shade." },

    -- Hyenas
    { name = "Giggler", family = "Hyena", level = "34", zone = "Desolace",
      x = 50.0, y = 50.0, -- approximate
      description = "A rare hyena found in Desolace, whose Rabies attack saps enemy health regeneration and stats." },
    { name = "Murderous Blisterpaw", family = "Hyena", level = "43", zone = "Tanaris",
      x = 50.0, y = 50.0, -- approximate
      description = "A rare brown hyena found in Tanaris, once a target for field-sampling hunters." },
    { name = "Snort the Heckler", family = "Hyena", level = "17", zone = "The Barrens",
      x = 55.0, y = 75.0, -- approximate (east of Vendetta Point, Southern Barrens)
      points = { -- roams the area east of Vendetta Point; both approximate
          { x = 55.0, y = 75.0 },
          { x = 60.0, y = 80.0 },
      },
      description = "A rare purple hyena found roaming east of Vendetta Point in the Southern Barrens." },
    { name = "Ravage", family = "Hyena", level = "51", zone = "Blasted Lands",
      x = 50.0, y = 50.0, -- approximate
      description = "A rare hyena prowling the Blasted Lands." },

    -- Owls
    { name = "Olm the Wise", family = "Owl", level = "52", zone = "Felwood",
      x = 55.0, y = 45.0, -- approximate (between Irontree Woods and Talonbranch Glade)
      description = "A spectral-looking rare owl that flies between Irontree Woods and Talonbranch Glade in Felwood; taming it briefly angers the Cenarion Circle but costs no reputation." },
    { name = "Nightscreech", family = "Owl", level = "11", zone = "Teldrassil",
      x = 46.8, y = 32.0,
      description = "A rare owl haunting the moonlit boughs of Teldrassil, whose piercing shriek carries long after it's gone quiet again." },

    -- Raptors
    { name = "Takk the Leaper", family = "Raptor", level = "19 Elite", zone = "The Barrens",
      x = 50.0, y = 55.0, -- approximate (ridge southeast of the Sludge Fen)
      description = "An elite rare raptor that roams the ridge southeast of the Sludge Fen in the Barrens, known for its Leaping Rush attack." },
    { name = "Dart", family = "Raptor", level = "38", zone = "Dustwallow Marsh",
      x = 50.0, y = 40.0, -- approximate
      description = "A rare raptor found in Dustwallow Marsh." },
    { name = "Razormaw Matriarch", family = "Raptor", level = "31", zone = "Wetlands",
      x = 69.8, y = 29.2,
      description = "A rare yellow raptor that watches over her brood within the Raptor Ridge cavern in the Wetlands." },

    -- Scorpids
    { name = "Death Flayer", family = "Scorpid", level = "11", zone = "Durotar",
      x = 38.4, y = 47.3,
      description = "A rare scorpid found south of the Southfury Watershed, among the rocks near the Southfury River in Durotar." },
    { name = "Krellack", family = "Scorpid", level = "56", zone = "Silithus",
      x = 45.0, y = 45.0, -- approximate
      description = "A rare scorpid found in Silithus, with a Fatal Sting that only triggers when it is badly wounded." },
    { name = "Vile Sting", family = "Scorpid", level = "35", zone = "Thousand Needles",
      x = 65.0, y = 25.0, -- approximate (above Highperch)
      description = "A rare scorpid roaming the heights above Highperch in Thousand Needles." },
    { name = "Clack the Reaver", family = "Scorpid", level = "53", zone = "Blasted Lands",
      x = 45.0, y = 45.0, -- approximate
      description = "A rare scorpid found in the Blasted Lands, striking with poison bolts and venom splash." },

    -- Spiders
    { name = "Shanda the Spinner", family = "Spider", level = "19", zone = "Loch Modan",
      x = 61.0, y = 75.0,
      description = "A rare tarantula that spawns in a cave in Loch Modan, combining a poisonous bite with an immobilizing web." },
    { name = "Creepthess", family = "Spider", level = "24", zone = "Hillsbrad Foothills",
      x = 50.0, y = 50.0, -- approximate
      description = "A rare tarantula in Hillsbrad Foothills valued for its unusually high Creeper Ichor drop rate." },
    { name = "Gretheer", family = "Spider", level = "57", zone = "Silithus",
      x = 55.0, y = 55.0, -- approximate
      description = "A rare tarantula found in Silithus, armed with poison and web attacks." },
    { name = "Rekk'tilac", family = "Spider", level = "48", zone = "Searing Gorge",
      x = 45.0, y = 45.0, -- approximate
      description = "A rare lava spider found in Searing Gorge, delivering a lingering Deadly Poison." },
    { name = "Chatter", family = "Spider", level = "23", zone = "Redridge Mountains",
      x = 35.0, y = 45.0, -- approximate (near Alther's Mill)
      description = "A reddish-brown rare tarantula found near Alther's Mill in Redridge Mountains." },
    { name = "Sri'skulk", family = "Spider", level = "13", zone = "Tirisfal Glades",
      x = 50.0, y = 65.0, -- approximate (Venomweb Vale)
      description = "A rare spider found in Venomweb Vale in Tirisfal Glades." },
    { name = "Krethis Shadowspinner", family = "Spider", level = "15", zone = "Silverpine Forest",
      x = 40.0, y = 70.0, -- approximate (the Skittering Dark)
      description = "A rare spider that lurks in and around the cave known as the Skittering Dark in Silverpine Forest." },
    { name = "Mother Fang", family = "Spider", level = "10", zone = "Elwynn Forest",
      x = 25.0, y = 55.0, -- approximate (Jasperlode Mine)
      description = "A rare spider found deep within Jasperlode Mine in Elwynn Forest, combining poison with webbing crowd control." },
    { name = "Leech Widow", family = "Spider", level = "24", zone = "Wetlands",
      x = 50.0, y = 60.0, -- approximate (Thelgen Rock)
      description = "A rare spider found at Thelgen Rock in the Wetlands." },
    { name = "Darkmist Widow", family = "Spider", level = "40", zone = "Dustwallow Marsh",
      x = 30.0, y = 60.0, -- approximate (outside Darkmist Cavern)
      description = "A rare spider found just outside Darkmist Cavern in Dustwallow Marsh." },
    { name = "Naraxis", family = "Spider", level = "27", zone = "Duskwood",
      x = 60.0, y = 70.0, -- approximate (cave southeast of Darkshire)
      description = "A distinctively red-and-green rare venom spider found in a cave southeast of Darkshire in Duskwood." },

    -- Tallstriders
    { name = "Mazzranache", family = "Tallstrider", level = "9", zone = "Mulgore",
      x = 40.0, y = 55.0, -- approximate (southwest of Thunder Bluff)
      description = "A flamingo-pink rare tallstrider found southwest of Thunder Bluff in Mulgore." },
    { name = "Strider Clutchmother", family = "Tallstrider", level = "20", zone = "Darkshore",
      x = 45.0, y = 75.0, -- approximate (southern Darkshore)
      description = "A teal-skinned rare tallstrider roaming southern Darkshore, usually accompanied by two Foreststrider Fledglings." },
    { name = "Fernfeather", family = "Tallstrider", level = "10", zone = "Zephras Isle",
      x = 48.0, y = 85.4,
      points = { -- two named sightings; RARE_LOCATION_OVERRIDES below supersedes with a sourced centroid
          { x = 48.0, y = 85.4 },
          { x = 53.8, y = 78.8 },
      },
      description = "A rare tallstrider striding the open plateaus of Zephras Isle, its fern-green plumage blending into the isle's hanging gardens." },

    -- Turtles
    { name = "Ironback", family = "Turtle", level = "51", zone = "The Hinterlands",
      x = 60.0, y = 70.0, -- approximate (shore below Overlook Cliffs)
      description = "A rare turtle found along the shore beneath the Overlook Cliffs in the Hinterlands." },
    { name = "Cranky Benj", family = "Turtle", level = "32", zone = "Alterac Mountains",
      x = 45.0, y = 60.0, -- approximate
      description = "A rare turtle, formerly known as Optimistic Benj, found in the Alterac Mountains / Hillsbrad border area." },

    -- Wind Serpents
    { name = "Azzere the Skyblade", family = "Wind Serpent", level = "25", zone = "The Barrens",
      x = 45.0, y = 80.0, -- approximate (south of Ruins of Taurajo)
      description = "A rare wind serpent that patrols south of the Ruins of Taurajo in the Southern Barrens, armed with Fireball and Flame Spike." },
    { name = "Hayoc", family = "Wind Serpent", level = "41", zone = "Dustwallow Marsh",
      x = 48.6, y = 60.8,
      description = "A rare wind serpent found over the Quagmire in Dustwallow Marsh." },
    { name = "Arash-ethis", family = "Wind Serpent", level = "49", zone = "Feralas",
      x = 30.0, y = 45.0, -- approximate (southwest of Ruins of Ravenwind, west of Camp Ataya)
      points = { -- circles a path between two named landmarks; both approximate
          { x = 28.0, y = 42.0 }, -- southwest of Ruins of Ravenwind
          { x = 33.0, y = 48.0 }, -- west of Camp Ataya
      },
      description = "A rare wind serpent that circles a path southwest of the Ruins of Ravenwind and west of Camp Ataya in Feralas." },

    -- Wolves
    { name = "Coldrasp", family = "Wolf", level = "12", zone = "Tirisfal Glades",
      x = 19.5, y = 64.5,
      description = "A rare frost-pale wolf prowling Tirisfal Glades, whose rasping, broken howl gives it its name." },
    { name = "Snarler", family = "Wolf", level = "42", zone = "Feralas",
      x = 70.0, y = 30.0, -- approximate (northeastern Feralas)
      description = "A rare timber wolf found in northeastern Feralas." },
    { name = "Mist Howler", family = "Wolf", level = "22", zone = "Ashenvale",
      x = 25.8, y = 26.0,
      description = "A rare timber wolf in northwestern Ashenvale, once famous for an unusually fast attack speed." },
    { name = "Deathmaw", family = "Wolf", level = "53", zone = "Burning Steppes",
      x = 50.0, y = 50.0, -- approximate (near Dreadmaul Rock)
      description = "A rare worg found near Dreadmaul Rock in the Burning Steppes, one of only a few wolves with a unique skin." },
    { name = "Old Cliff Jumper", family = "Wolf", level = "42", zone = "The Hinterlands",
      x = 13.6, y = 53.8,
      description = "A dark grey rare timber wolf found around the haystacks at Featherbeard's Hovel in the Hinterlands." },
    { name = "Gorefang", family = "Wolf", level = "13", zone = "Silverpine Forest",
      x = 45.0, y = 30.0, -- approximate (between Forsaken High Command and Valgan's Field)
      description = "A grey-and-white rare worg, unusual among the typically black worgs of Silverpine Forest, roaming between the Forsaken High Command and Valgan's Field." },
    { name = "Barnabus", family = "Wolf", level = "38", zone = "Badlands",
      x = 45.0, y = 55.0, -- approximate
      description = "A rare wolf found in the Badlands that can enrage and snarl for bonus damage." },
    { name = "Timber", family = "Wolf", level = "10", zone = "Dun Morogh",
      x = 65.0, y = 37.8,
      description = "A rare frost wolf found near the eastern side of Iceflow Lake in Dun Morogh." },
    { name = "Lupos", family = "Wolf", level = "23", zone = "Duskwood",
      x = 50.0, y = 45.0, -- approximate (Brightwood Grove / the Darkened Bank)
      description = "A rare wolf that roams between Brightwood Grove and the Darkened Bank in Duskwood." },
    { name = "Death Howl", family = "Wolf", level = "49", zone = "Felwood",
      x = 40.0, y = 50.0, -- approximate
      description = "A rare worg found in Felwood, capable of a horrifying howl, infected wounds, and tendon-ripping bites." },
}

--------------------------------------------------------------------------
-- Precise spawn points + map ids, sourced from this server's own
-- NpcInfoTables.lua (the user supplied it directly - a per-npc-id database
-- keyed by this exact client's zoneID/UiMapID). That file's own single
-- "primary" x/y field turned out to be an unreliable anchor point (user
-- feedback: positions using it were worse than the previous, SilverDragon-
-- based data) - so instead this uses the CENTROID of that same entry's
-- `overlay` list, a few to several dozen individually logged sighting
-- coordinates per rare, which is a far better-sampled estimate of where a
-- rare actually spawns than its one named anchor point. The point count
-- noted per rare below is how many sightings that average is built from -
-- single digits means take it with a grain of salt. Covers every rare here
-- except Blind Hunter (not present in that table under any name), which
-- keeps its old estimated x/y.
--------------------------------------------------------------------------
local RARE_LOCATION_OVERRIDES = {
    ["Araga"] = { mapID = 1443, x = 34.2, y = 84.06 }, -- 28 pts
    ["Arash-ethis"] = { mapID = 1444, x = 43.23, y = 23.97 }, -- 7 pts
    ["Azzere the Skyblade"] = { mapID = 1413, x = 44.93, y = 62.2 }, -- 3 pts
    ["Barnabus"] = { mapID = 1418, x = 47.56, y = 67.91 }, -- 37 pts
    ["Big Samras"] = { mapID = 1424, x = 79.03, y = 36.15 }, -- 21 pts
    ["Bjarn"] = { mapID = 1426, x = 57.56, y = 58.14 }, -- 35 pts
    ["Broken Tooth"] = { mapID = 1418, x = 52.05, y = 29.87 }, -- 60 pts
    ["Chatter"] = { mapID = 1433, x = 53.97, y = 42.26 }, -- 49 pts
    ["Clack the Reaver"] = { mapID = 1419, x = 53.61, y = 35.15 }, -- 44 pts
    ["Coldrasp"] = { mapID = 1420, x = 19.8, y = 65.0 }, -- 1 pts
    ["Cranky Benj"] = { mapID = 1416, x = 27.26, y = 37.39 }, -- 32 pts
    ["Creepthess"] = { mapID = 1424, x = 32.5, y = 56.22 }, -- 32 pts
    ["Darkmist Widow"] = { mapID = 1445, x = 30.4, y = 20.8 }, -- 1 pts
    ["Dart"] = { mapID = 1445, x = 47.66, y = 17.46 }, -- 7 pts
    ["Death Flayer"] = { mapID = 1411, x = 36.88, y = 50.19 }, -- 21 pts
    ["Death Howl"] = { mapID = 1448, x = 50.97, y = 81.0 }, -- 7 pts
    ["Deathmaw"] = { mapID = 1428, x = 80.7, y = 43.71 }, -- 29 pts
    ["Dishu"] = { mapID = 1413, x = 50.3, y = 22.25 }, -- 4 pts
    ["Duskstalker"] = { mapID = 1438, x = 56.56, y = 75.45 }, -- 17 pts
    ["Fernfeather"] = { mapID = 2521, x = 51.55, y = 81.5 }, -- 4 pts
    ["Ghostfang"] = { mapID = 1426, x = 78.16, y = 53.92 }, -- 5 pts
    ["Giggler"] = { mapID = 1443, x = 60.72, y = 21.45 }, -- 36 pts
    ["Gorefang"] = { mapID = 1421, x = 50.71, y = 18.63 }, -- 27 pts
    ["Greater Firebird"] = { mapID = 1446, x = 47.28, y = 36.97 }, -- 20 pts
    ["Gretheer"] = { mapID = 1451, x = 44.27, y = 55.52 }, -- 29 pts
    ["Grunter"] = { mapID = 1419, x = 58.02, y = 27.72 }, -- 19 pts
    ["Hayoc"] = { mapID = 1445, x = 53.56, y = 64.04 }, -- 15 pts
    ["Humar The Pridelord"] = { mapID = 1413, x = 62.0, y = 34.1 }, -- 2 pts
    ["Ironback"] = { mapID = 1425, x = 78.14, y = 66.54 }, -- 34 pts
    ["Krellack"] = { mapID = 1451, x = 64.47, y = 33.62 }, -- 43 pts
    ["Krethis Shadowspinner"] = { mapID = 1421, x = 35.57, y = 12.33 }, -- 6 pts
    ["Kurmokk"] = { mapID = 1434, x = 33.38, y = 65.76 }, -- 9 pts
    ["Large Loch Crocolisk"] = { mapID = 1432, x = 59.74, y = 34.28 }, -- 42 pts
    ["Leech Widow"] = { mapID = 1437, x = 46.27, y = 63.2 }, -- 3 pts
    ["Lord Condar"] = { mapID = 1432, x = 71.03, y = 72.44 }, -- 22 pts
    ["Lupos"] = { mapID = 1431, x = 41.69, y = 27.12 }, -- 68 pts
    ["Matriarch Bristlefur"] = { mapID = 1429, x = 58.62, y = 78.55 }, -- 11 pts
    ["Mazzranache"] = { mapID = 1412, x = 43.42, y = 43.84 }, -- 62 pts
    ["Mist Howler"] = { mapID = 1440, x = 22.96, y = 27.44 }, -- 16 pts
    ["Mongress"] = { mapID = 1448, x = 44.49, y = 80.63 }, -- 7 pts
    ["Mother Fang"] = { mapID = 1429, x = 60.9, y = 47.5 }, -- 2 pts
    ["Mystmane"] = { mapID = 2521, x = 58.95, y = 36.65 }, -- 4 pts
    ["Murderous Blisterpaw"] = { mapID = 1446, x = 51.33, y = 31.96 }, -- 14 pts
    ["Naraxis"] = { mapID = 1431, x = 86.33, y = 49.0 }, -- 3 pts
    ["Nightscreech"] = { mapID = 1438, x = 42.85, y = 37.35 }, -- 4 pts
    ["Old Cliff Jumper"] = { mapID = 1425, x = 19.66, y = 52.32 }, -- 17 pts
    ["Old Grizzlegut"] = { mapID = 1444, x = 63.88, y = 52.38 }, -- 12 pts
    ["Old Vicejaw"] = { mapID = 1421, x = 53.44, y = 58.95 }, -- 22 pts
    ["Olm the Wise"] = { mapID = 1448, x = 55.62, y = 17.98 }, -- 11 pts
    ["Rak'Shiri"] = { mapID = 1452, x = 51.36, y = 13.58 }, -- 25 pts
    ["Ravage"] = { mapID = 1419, x = 54.41, y = 36.41 }, -- 23 pts
    ["Razormaw Matriarch"] = { mapID = 1437, x = 68.89, y = 30.29 }, -- 9 pts
    ["Rekk'tilac"] = { mapID = 1427, x = 49.32, y = 55.19 }, -- 44 pts
    ["Ressan the Needler"] = { mapID = 1420, x = 51.01, y = 63.77 }, -- 41 pts
    ["Ripscale"] = { mapID = 1445, x = 44.58, y = 54.08 }, -- 21 pts
    ["Sewer Beast"] = { mapID = 1453, x = 48.09, y = 51.55 }, -- 120 pts
    ["Shadowclaw"] = { mapID = 1439, x = 39.62, y = 38.69 }, -- 22 pts
    ["Shal'ma"] = { mapID = 1411, x = 63.98, y = 85.38 }, -- 9 pts
    ["Shanda the Spinner"] = { mapID = 1432, x = 78.1, y = 52.1 }, -- 2 pts
    ["Slydris"] = { mapID = 2521, x = 50.2, y = 51.0 }, -- 1 pts
    ["Snarler"] = { mapID = 1444, x = 79.1, y = 39.04 }, -- 18 pts
    ["Snort the Heckler"] = { mapID = 1413, x = 41.15, y = 24.25 }, -- 8 pts
    ["Spiteflayer"] = { mapID = 1419, x = 59.26, y = 40.1 }, -- 29 pts
    ["Sri'skulk"] = { mapID = 1420, x = 87.15, y = 48.56 }, -- 29 pts
    ["Strider Clutchmother"] = { mapID = 1439, x = 37.28, y = 90.22 }, -- 22 pts
    ["Takk the Leaper"] = { mapID = 1413, x = 59.54, y = 9.49 }, -- 13 pts
    ["The Rake"] = { mapID = 1412, x = 51.08, y = 20.02, -- 43 pts
        extraPoints = { { x = 50.6, y = 29.3 } } }, -- additional confirmed spawn point
    ["Timber"] = { mapID = 1426, x = 34.33, y = 41.17 }, -- 6 pts
    ["Uhk'loc"] = { mapID = 1449, x = 68.6, y = 14.13 }, -- 3 pts
    ["Ursol'lok"] = { mapID = 1440, x = 84.62, y = 56.25 }, -- 16 pts
    ["Vile Sting"] = { mapID = 1441, x = 71.92, y = 69.85 }, -- 45 pts
    ["Vultros"] = { mapID = 1436, x = 48.66, y = 48.36 }, -- 56 pts
    ["Zaricotl"] = { mapID = 1418, x = 39.94, y = 56.99 }, -- 241 pts
}



--------------------------------------------------------------------------
-- The hardcoded table above assumed Classic-era UiMapIDs, which turned
-- out not to match this custom client at all (confirmed in-game: a rare
-- whose hardcoded id was 87 needed the player's actual displayed map id
-- to land in the 1400s to show up, nowhere near 87's neighborhood). So
-- mapIDs are resolved at runtime instead, by asking the client itself
-- for the real id behind each zone's name via C_Map.GetMapInfo - this
-- works on any client regardless of how its ids are numbered, which a
-- hardcoded guess never could. The hardcoded table above still serves as
-- a fallback for a zone name the client doesn't recognize.
--
-- This can't run as soon as this file loads: a first attempt scanning
-- C_Map.GetMapInfo right here, at addon-load time, left every rare still
-- on its old hardcoded (wrong) id - C_Map's data evidently isn't
-- populated that early on this client. ns.ResolveRareMapIDs() instead
-- does the scan on demand; PetSmart.lua calls it during PLAYER_LOGIN,
-- once the world is actually loading, and again records what happened
-- per zone in ns.RareZoneResolveLog so it can be reported in chat.
--------------------------------------------------------------------------
function ns.ResolveRareMapIDs()
    local dynamic = {}
    local scanned = 0
    if C_Map and C_Map.GetMapInfo then
        for id = 0, 3000 do
            local info = C_Map.GetMapInfo(id)
            if info and info.name then
                scanned = scanned + 1
                if not dynamic[info.name] then
                    dynamic[info.name] = id
                end
            end
        end
    end

    local log = { dynamic = {}, fallback = {}, unresolved = {}, scanned = scanned }
    for _, rare in ipairs(ns.RARE_SPAWNS) do
        -- A rare whose mapID came straight from RARE_LOCATION_OVERRIDES
        -- (this server's own NpcInfoTables.lua) already has the right id,
        -- not a zone-name guess, so it's left alone here. (No `goto`: WoW's
        -- Lua is 5.1, which doesn't have it.)
        if not rare.mapIDFixed then
            local zoneName = rare.zone
            local id = dynamic[zoneName]
            if id then
                log.dynamic[zoneName] = id
                rare.mapID = id
            else
                local fallback = ns.ZONE_MAP_IDS[zoneName]
                if fallback then
                    log.fallback[zoneName] = fallback
                    rare.mapID = fallback
                else
                    log.unresolved[zoneName] = true
                    rare.mapID = nil
                end
            end
        end
    end
    -- Tame-teacher spawns (Data/TameTeacherSpawnData.lua) get their mapIDs
    -- from the same hardcoded placeholder table when they load, so they
    -- need the exact same real-id resolution - otherwise tracking one opens
    -- the wrong map and its pins/area highlights only line up when the
    -- player happens to be standing in a zone with that placeholder id.
    -- Dungeon entries are left alone (they can't be tracked anyway).
    if ns.TAME_TEACHER_SPAWNS then
        for _, spawn in ipairs(ns.TAME_TEACHER_SPAWNS) do
            if not spawn.isDungeon then
                local id = dynamic[spawn.zone]
                if id then
                    log.dynamic[spawn.zone] = id
                    spawn.mapID = id
                else
                    local fallback = ns.ZONE_MAP_IDS[spawn.zone]
                    if fallback then
                        log.fallback[spawn.zone] = fallback
                        spawn.mapID = fallback
                    else
                        log.unresolved[spawn.zone] = true
                        spawn.mapID = nil
                    end
                end
            end
        end
    end
    ns.RareZoneResolveLog = log
end

ns.RARE_SPAWNS = {}
for _, r in ipairs(raw) do
    local familyName = FAMILY_NAME_FIXUPS[r.family] or r.family
    local familyId = ns.FAMILY_BY_NAME and ns.FAMILY_BY_NAME[familyName]
    local override = RARE_LOCATION_OVERRIDES[r.name]
    -- Precedence for a rare's map point(s): RARE_LOCATION_OVERRIDES (this
    -- server's own NpcInfoTables.lua) first, then any hand-set `points`
    -- list in `raw` above, then a single-entry list built from x/y as the
    -- last resort for the one rare none of that covers. An override's own
    -- `extraPoints` (manually confirmed additional camps on top of its
    -- centroid point) are appended when present.
    local points
    if override then
        points = { { x = override.x, y = override.y } }
        if override.extraPoints then
            for _, p in ipairs(override.extraPoints) do
                points[#points + 1] = { x = p.x, y = p.y }
            end
        end
    else
        points = r.points or { { x = r.x, y = r.y } }
    end
    ns.RARE_SPAWNS[#ns.RARE_SPAWNS + 1] = {
        name = r.name,
        familyId = familyId,
        level = r.level,
        zone = r.zone,
        -- An override's mapID is this server's own zoneID straight from
        -- NpcInfoTables.lua, already correct - ns.ResolveRareMapIDs() (at
        -- PLAYER_LOGIN) leaves it alone when mapIDFixed is set. Everything
        -- else gets this placeholder (wrong on this client) until that
        -- dynamic zone-name resolution runs.
        mapID = override and override.mapID or ns.ZONE_MAP_IDS[r.zone],
        mapIDFixed = override ~= nil or nil,
        points = points,
        description = r.description,
        -- Dungeon/raid rares have no world map on Forever at all (no
        -- continent map for the instance), so their mapID is unusable:
        -- handing it to WorldMapFrame:SetMapID crashes deep inside
        -- Blizzard's own WorldQuestDataProvider. These are flagged so the
        -- tracking code can refuse them outright instead of trying.
        isDungeon = r.dungeon or nil,
    }
end
