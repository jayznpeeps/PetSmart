local ADDON_NAME, ns = ...

--------------------------------------------------------------------------
-- Spawn data for tameable "teacher" pets - the creatures listed under an
-- ability's rank in the Abilities Index as "Tame one of:" - that are NOT
-- already covered by RareSpawnData.lua's rare-pet list, but still have a
-- single, findable spawn point rather than roaming an entire zone.
--
-- A `points` list of more than one entry is deliberately a handful of
-- general "cluster" areas the species is known to appear in (e.g. Lady
-- Sathrah's two lakeside banks, Den Mother's cave mouth plus the path up
-- to it) - one pin per documented area, not one pin per individual
-- sighting. The game's own tame-teacher tracking (SetAbilitiesMode's
-- "tamedetail" page) always shows every cluster pin a creature has at
-- once, uncapped by Multi-Tracking - see TAME_MAX_OVERLAY_POINTS in
-- PetSmart.lua, sized at 12 specifically so a species with that many
-- distinct documented areas could still show every one.
--
-- Most of PetopiaTameData.lua's ~320 distinct teacher names are ordinary
-- leveled world mobs (e.g. "Crag Boar", "Ridge Stalker", "Scorpashi
-- Venomlash") that spawn with even density across their ENTIRE zone,
-- rather than at a handful of discrete camps - confirmed by checking both
-- classic Wowhead's own per-NPC comment threads and hunter-pet-taming
-- guides (warcrafttavern.com's per-pet pages) for several of them, none
-- of which describe sub-areas to cluster. Inventing 2-3 arbitrary pins
-- scattered across the zone for those would misrepresent an even-density
-- spread as a clustered one, so they're deliberately left out of this
-- file rather than given invented points - there's genuinely no "cluster"
-- shape to capture for a mob that's simply everywhere. The entries below
-- are the ones that stood out from that pattern: individually-named,
-- singular creatures (often unique quest or hunter-pet targets) that
-- classic Wowhead's own player comments and/or warcraft.wiki.gg
-- consistently place at one or a few specific camps, caves, or hilltops.
--
-- Coordinates: fetched 2026-10-06 from wowhead.com/classic NPC pages
-- (specifically their user-comment coordinate call-outs, since Wowhead's
-- own interactive spawn map doesn't render through this tool - the same
-- limitation RareSpawnData.lua's header notes). A trailing "-- approximate"
-- comment means the comments didn't agree on one exact point and this is
-- a best-effort center of the cluster - worth a quick in-game check. A
-- `nil` x/y (points left empty) means even the general landmark wasn't
-- precise enough to place a pin at all; those still get a real zone and
-- flavor text, just no Track button.
--
-- wowhead.com/forever was re-checked specifically for this pass (including
-- Zephras Isle's own fauna, e.g. Vuldren/Ursera/Galestrider) and still has
-- no indexed per-creature NPC pages for ordinary world mobs at all
-- (Forever is too new/niche for generic-NPC pages to exist yet), and
-- wow-petopia.com/classic's per-family browse pages don't carry exact
-- coordinates either - so classic Wowhead's own comment threads were the
-- only source that actually panned out for this pass.
--------------------------------------------------------------------------

-- `radius` is this entry's spawn-area overlay size, in the same 0-100
-- zone-percentage units as x/y - how big a soft highlighted circle gets
-- drawn on the world map, centered on each of its points, with the pin
-- placed in the middle of it (see TAME_AREA_DEFAULT_RADIUS in
-- PetSmart.lua for the fallback used when an entry omits this). It's a
-- rough stand-in for "roughly this big an area", sized from how tightly
-- or loosely the sourced comments agreed on a spot - not a traced
-- boundary (no source here gives one), so treat it the same as any other
-- "-- approximate" value in this file.
local raw = {
    { name = "Mangeclaw", zone = "Dun Morogh", fromAreas = true,
      description = "A unique bear denned in the tunnel near North Gate Outpost, reached by heading east from Ironforge past Steelgrill's Depot." },

    { name = "Ol' Sooty", zone = "Loch Modan", fromAreas = true,
      description = "A black bear that dens in a cave in the hills south of Thelsamar, though he wanders the path and valley around it too." },

    { name = "Sarkoth", zone = "Durotar", fromAreas = true,
      description = "A scorpid that spawns on the hill just north and west of The Den, above the orc starting burrow." },

    { name = "Sin'Dall", zone = "Stranglethorn Vale", fromAreas = true,
      description = "A panther that patrols the top of a hill near the Tkashi Ruins, southwest of Nesingwary's Expedition." },

    { name = "King Bangalash", zone = "Stranglethorn Vale", fromAreas = true,
      description = "A panther found on a hill along the western coast, near the arena grounds north of Grom'Gol Base Camp." },

    { name = "Washte Pawne", zone = "The Barrens", fromAreas = true,
      description = "A wind serpent found south of Camp Taurajo, near the quilboar territory around Blackthorn Ridge." },

    { name = "Den Mother", zone = "Darkshore", fromAreas = true,
      description = "A bear denned in a hidden mountain cave due east of Bashal'Aran, up a hidden path north from Auberdine." },

    { name = "Lady Sathrah", zone = "Teldrassil", x = 45.0, y = 25.0, radius = 4.0, extraPoints = { { x = 39.0, y = 26.0 } }, -- approximate (either side of the lake)
      description = "A spider found at the falls atop Wellspring River, on either side of Wellspring Lake - she doesn't patrol between the two." },

    { name = "Githyiss the Vile", zone = "Teldrassil", x = 39.0, y = 28.0, radius = 2.5, -- approximate (per warcraft.wiki.gg, Shadowthread Cave)
      description = "Guards the Webwood Egg inside Shadowthread Cave, home to Teldrassil's webwood spiders." },

    { name = "Vulgara the Insatiable", zone = "Zephras Isle", x = 42.8, y = 52.2, radius = 2.5,
      description = "A wolf found on Zephras Isle, at the spot marked on the map." },

    -- Spread across wide areas: the highlighted zones (and pin spots) come from
    -- Data/TameTeacherAreaData.lua, traced around wowhead.com/classic's pin cloud.
    { name = "Prairie Wolf", zone = "Mulgore", fromAreas = true,
      description = "A common grey wolf that prowls the plains south and west of Camp Narache, around the lake and out toward Red Cloud Mesa - a single wide hunting ground, not a single camp." },

    { name = "Black Ravager", zone = "Duskwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Duskwood - see the highlighted zones on the map." },

    { name = "Black Ravager Mastiff", zone = "Duskwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Duskwood - see the highlighted zones on the map." },

    { name = "Bloodsnout Worg", zone = "Silverpine Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Silverpine Forest - see the highlighted zones on the map." },

    { name = "Coyote", zone = "Westfall", fromAreas = true,
      description = "Found in several wide hunting grounds across Westfall - see the highlighted zones on the map." },

    { name = "Coyote Packleader", zone = "Westfall", fromAreas = true,
      description = "Found in several wide hunting grounds across Westfall - see the highlighted zones on the map." },

    { name = "Crag Coyote", zone = "Badlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Badlands - see the highlighted zones on the map." },

    { name = "Darkfang Creeper", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Darkfang Lurker", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Darkfang Spider", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Deadmire", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Dreadmaw Crocolisk", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Drywallow Crocolisk", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Drywallow Daggermaw", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Elder Moss Creeper", zone = "Hillsbrad Foothills", fromAreas = true,
      description = "Found in several wide hunting grounds across Hillsbrad Foothills - see the highlighted zones on the map." },

    { name = "Felpaw Ravager", zone = "Felwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Felwood - see the highlighted zones on the map." },

    { name = "Felpaw Wolf", zone = "Felwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Felwood - see the highlighted zones on the map." },

    { name = "Forest Lurker", zone = "Loch Modan", fromAreas = true,
      description = "Found in several wide hunting grounds across Loch Modan - see the highlighted zones on the map." },

    { name = "Forest Moss Creeper", zone = "Hillsbrad Foothills", fromAreas = true,
      description = "Found in several wide hunting grounds across Hillsbrad Foothills - see the highlighted zones on the map." },

    { name = "Forest Spider", zone = "Elwynn Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Elwynn Forest - see the highlighted zones on the map." },

    { name = "Ghostpaw Alpha", zone = "Ashenvale", fromAreas = true,
      description = "Found in several wide hunting grounds across Ashenvale - see the highlighted zones on the map." },

    { name = "Ghostpaw Runner", zone = "Ashenvale", fromAreas = true,
      description = "Found in several wide hunting grounds across Ashenvale - see the highlighted zones on the map." },

    { name = "Giant Moss Creeper", zone = "Hillsbrad Foothills", fromAreas = true,
      description = "Found in several wide hunting grounds across Hillsbrad Foothills - see the highlighted zones on the map." },

    { name = "Giant Webwood Spider", zone = "Teldrassil", fromAreas = true,
      description = "Found in several wide hunting grounds across Teldrassil - see the highlighted zones on the map." },

    { name = "Giant Wetlands Crocolisk", zone = "Wetlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Wetlands - see the highlighted zones on the map." },

    { name = "Gray Forest Wolf", zone = "Elwynn Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Elwynn Forest - see the highlighted zones on the map." },

    { name = "Greater Tarantula", zone = "Redridge Mountains", fromAreas = true,
      description = "Found in several wide hunting grounds across Redridge Mountains - see the highlighted zones on the map." },

    { name = "Green Recluse", zone = "Duskwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Duskwood - see the highlighted zones on the map." },

    { name = "Juvenile Vuldren", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Large Loch Crocolisk", zone = "Loch Modan", fromAreas = true,
      description = "Found in several wide hunting grounds across Loch Modan - see the highlighted zones on the map." },

    { name = "Leech Widow", zone = "Wetlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Wetlands - see the highlighted zones on the map." },

    { name = "Loch Crocolisk", zone = "Loch Modan", fromAreas = true,
      description = "Found in several wide hunting grounds across Loch Modan - see the highlighted zones on the map." },

    { name = "Longtooth Runner", zone = "Feralas", fromAreas = true,
      description = "Found in several wide hunting grounds across Feralas - see the highlighted zones on the map." },

    { name = "Mottled Drywallow Crocolisk", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Mudrock Tortoise", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Night Web Matriarch", zone = "Tirisfal Glades", fromAreas = true,
      description = "Found in several wide hunting grounds across Tirisfal Glades - see the highlighted zones on the map." },

    { name = "Night Web Spider", zone = "Tirisfal Glades", fromAreas = true,
      description = "Found in several wide hunting grounds across Tirisfal Glades - see the highlighted zones on the map." },

    { name = "Oasis Snapjaw", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Prairie Stalker", zone = "Mulgore", fromAreas = true,
      description = "Found in several wide hunting grounds across Mulgore - see the highlighted zones on the map." },

    { name = "Prairie Wolf Alpha", zone = "Mulgore", fromAreas = true,
      description = "Found in several wide hunting grounds across Mulgore - see the highlighted zones on the map." },

    { name = "Ragged Scavenger", zone = "Tirisfal Glades", fromAreas = true,
      description = "Found in several wide hunting grounds across Tirisfal Glades - see the highlighted zones on the map." },

    { name = "Saltwater Snapjaw", zone = "The Hinterlands", fromAreas = true,
      description = "Found in several wide hunting grounds across The Hinterlands - see the highlighted zones on the map." },

    { name = "Snapjaw", zone = "Hillsbrad Foothills", fromAreas = true,
      description = "Found in several wide hunting grounds across Hillsbrad Foothills - see the highlighted zones on the map." },

    { name = "Snow Tracker Wolf", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Sparkleshell Snapper", zone = "Thousand Needles", fromAreas = true,
      description = "Found in several wide hunting grounds across Thousand Needles - see the highlighted zones on the map." },

    { name = "Starving Winter Wolf", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Tarantula", zone = "Redridge Mountains", fromAreas = true,
      description = "Found in several wide hunting grounds across Redridge Mountains - see the highlighted zones on the map." },

    { name = "Vicious Night Web Spider", zone = "Tirisfal Glades", fromAreas = true,
      description = "Found in several wide hunting grounds across Tirisfal Glades - see the highlighted zones on the map." },

    { name = "Vilebranch Raiding Wolf", zone = "The Hinterlands", fromAreas = true,
      description = "Found in several wide hunting grounds across The Hinterlands - see the highlighted zones on the map." },

    { name = "Vuldren", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Webwood Silkspinner", zone = "Teldrassil", fromAreas = true,
      description = "Found in several wide hunting grounds across Teldrassil - see the highlighted zones on the map." },

    { name = "Webwood Venomfang", zone = "Teldrassil", fromAreas = true,
      description = "Found in several wide hunting grounds across Teldrassil - see the highlighted zones on the map." },

    { name = "Wildthorn Lurker", zone = "Ashenvale", fromAreas = true,
      description = "Found in several wide hunting grounds across Ashenvale - see the highlighted zones on the map." },

    { name = "Winter Wolf", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Wood Lurker", zone = "Loch Modan", fromAreas = true,
      description = "Found in several wide hunting grounds across Loch Modan - see the highlighted zones on the map." },

    { name = "Worg", zone = "Silverpine Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Silverpine Forest - see the highlighted zones on the map." },

    { name = "Deathstrike Tarantula", zone = "Swamp of Sorrows", fromAreas = true,
      description = "Found in several wide hunting grounds across Swamp of Sorrows - see the highlighted zones on the map." },

    { name = "Deepmoss Creeper", zone = "Stonetalon Mountains", fromAreas = true,
      description = "Found in several wide hunting grounds across Stonetalon Mountains - see the highlighted zones on the map." },

    { name = "Deepmoss Webspinner", zone = "Stonetalon Mountains", fromAreas = true,
      description = "Found in several wide hunting grounds across Stonetalon Mountains - see the highlighted zones on the map." },

    { name = "Diseased Wolf", zone = "Western Plaguelands", fromAreas = true,
      description = "Found in several wide hunting grounds across Western Plaguelands - see the highlighted zones on the map." },

    { name = "Giant Plains Creeper", zone = "Arathi Highlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Arathi Highlands - see the highlighted zones on the map." },

    { name = "Plague Lurker", zone = "Western Plaguelands", fromAreas = true,
      description = "Found in several wide hunting grounds across Western Plaguelands - see the highlighted zones on the map." },

    { name = "Plains Creeper", zone = "Arathi Highlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Arathi Highlands - see the highlighted zones on the map." },

    { name = "Sawtooth Snapper", zone = "Swamp of Sorrows", fromAreas = true,
      description = "Found in several wide hunting grounds across Swamp of Sorrows - see the highlighted zones on the map." },

    { name = "Timberweb Recluse", zone = "Azshara", fromAreas = true,
      description = "Found in several wide hunting grounds across Azshara - see the highlighted zones on the map." },

    { name = "Young Thistle Boar", zone = "Teldrassil", fromAreas = true,
      description = "Found in several wide hunting grounds across Teldrassil - see the highlighted zones on the map." },

    { name = "Battleboar", zone = "Mulgore", fromAreas = true,
      description = "Found in several wide hunting grounds across Mulgore - see the highlighted zones on the map." },

    { name = "Bristleback Battleboar", zone = "Mulgore", fromAreas = true,
      description = "Found in several wide hunting grounds across Mulgore - see the highlighted zones on the map." },

    { name = "Corrupted Mottled Boar", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Crag Boar", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Dire Mottled Boar", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Elder Crag Boar", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Elder Mottled Boar", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Large Crag Boar", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Longsnout", zone = "Elwynn Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Elwynn Forest - see the highlighted zones on the map." },

    { name = "Mottled Boar", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Mountain Boar", zone = "Loch Modan", fromAreas = true,
      description = "Found in several wide hunting grounds across Loch Modan - see the highlighted zones on the map." },

    { name = "Porcine Entourage", zone = "Elwynn Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Elwynn Forest - see the highlighted zones on the map." },

    { name = "Rockhide Boar", zone = "Elwynn Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Elwynn Forest - see the highlighted zones on the map." },

    { name = "Scarred Crag Boar", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Small Crag Boar", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Stonetusk Boar", zone = "Elwynn Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Elwynn Forest - see the highlighted zones on the map." },

    { name = "Thistle Boar", zone = "Teldrassil", fromAreas = true,
      description = "Found in several wide hunting grounds across Teldrassil - see the highlighted zones on the map." },

    { name = "Great Goretusk", zone = "Redridge Mountains", fromAreas = true,
      description = "Found in several wide hunting grounds across Redridge Mountains - see the highlighted zones on the map." },

    { name = "Young Goretusk", zone = "Westfall", fromAreas = true,
      description = "Found in several wide hunting grounds across Westfall - see the highlighted zones on the map." },

    { name = "Elder Mountain Boar", zone = "Loch Modan", fromAreas = true,
      description = "Found in several wide hunting grounds across Loch Modan - see the highlighted zones on the map." },

    { name = "Goretusk", zone = "Westfall", fromAreas = true,
      description = "Found in several wide hunting grounds across Westfall - see the highlighted zones on the map." },

    { name = "Mangy Mountain Boar", zone = "Loch Modan", fromAreas = true,
      description = "Found in several wide hunting grounds across Loch Modan - see the highlighted zones on the map." },

    { name = "Bellygrub", zone = "Redridge Mountains", fromAreas = true,
      description = "Found in several wide hunting grounds across Redridge Mountains - see the highlighted zones on the map." },

    { name = "Ashmane Boar", zone = "Blasted Lands", fromAreas = true,
      description = "Found in several wide hunting grounds across Blasted Lands - see the highlighted zones on the map." },

    { name = "Plagued Swine", zone = "Eastern Plaguelands", fromAreas = true,
      description = "Found in several wide hunting grounds across Eastern Plaguelands - see the highlighted zones on the map." },

    { name = "Highlands Ursera", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Ice Claw Bear", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Pygmy Surf Crawler", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Scorpid Worker", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Scrawny Ursera", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Strigid Owl", zone = "Teldrassil", fromAreas = true,
      description = "Found in several wide hunting grounds across Teldrassil - see the highlighted zones on the map." },

    { name = "Urs'anah", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Ursera Scavenger", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Elmpaw", zone = "Elwynn Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Elwynn Forest - see the highlighted zones on the map." },

    { name = "Encrusted Surf Crawler", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Ferocious Grizzled Bear", zone = "Silverpine Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Silverpine Forest - see the highlighted zones on the map." },

    { name = "Strigid Hunter", zone = "Teldrassil", fromAreas = true,
      description = "Found in several wide hunting grounds across Teldrassil - see the highlighted zones on the map." },

    { name = "Thistle Bear", zone = "Darkshore", fromAreas = true,
      description = "Found in several wide hunting grounds across Darkshore - see the highlighted zones on the map." },

    { name = "Tide Crawler", zone = "Darkshore", fromAreas = true,
      description = "Found in several wide hunting grounds across Darkshore - see the highlighted zones on the map." },

    { name = "Venomtail Scorpid", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Windsong Crawler", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Young Forest Bear", zone = "Elwynn Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Elwynn Forest - see the highlighted zones on the map." },

    { name = "Ashenvale Bear", zone = "Ashenvale", fromAreas = true,
      description = "Found in several wide hunting grounds across Ashenvale - see the highlighted zones on the map." },

    { name = "Black Bear Patriarch", zone = "Loch Modan", fromAreas = true,
      description = "Found in several wide hunting grounds across Loch Modan - see the highlighted zones on the map." },

    { name = "Clattering Crawler", zone = "Ashenvale", fromAreas = true,
      description = "Found in several wide hunting grounds across Ashenvale - see the highlighted zones on the map." },

    { name = "Ghost Saber", zone = "Darkshore", fromAreas = true,
      description = "Found in several wide hunting grounds across Darkshore - see the highlighted zones on the map." },

    { name = "Gray Bear", zone = "Hillsbrad Foothills", fromAreas = true,
      description = "Found in several wide hunting grounds across Hillsbrad Foothills - see the highlighted zones on the map." },

    { name = "Shadowgale Ursera", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Shore Crawler", zone = "Westfall", fromAreas = true,
      description = "Found in several wide hunting grounds across Westfall - see the highlighted zones on the map." },

    { name = "Elder Ashenvale Bear", zone = "Ashenvale", fromAreas = true,
      description = "Found in several wide hunting grounds across Ashenvale - see the highlighted zones on the map." },

    { name = "Scorpashi Snapper", zone = "Desolace", fromAreas = true,
      description = "Found in several wide hunting grounds across Desolace - see the highlighted zones on the map." },

    { name = "Scorpid Reaver", zone = "Thousand Needles", fromAreas = true,
      description = "Found in several wide hunting grounds across Thousand Needles - see the highlighted zones on the map." },

    { name = "Drywallow Snapper", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dustwallow Marsh - see the highlighted zones on the map." },

    { name = "Scorpashi Lasher", zone = "Desolace", fromAreas = true,
      description = "Found in several wide hunting grounds across Desolace - see the highlighted zones on the map." },

    { name = "Ironfur Bear", zone = "Feralas", fromAreas = true,
      description = "Found in several wide hunting grounds across Feralas - see the highlighted zones on the map." },

    { name = "Monstrous Crawler", zone = "Swamp of Sorrows", fromAreas = true,
      description = "Found in several wide hunting grounds across Swamp of Sorrows - see the highlighted zones on the map." },

    { name = "Scorpid Hunter", zone = "Tanaris", fromAreas = true,
      description = "Found in several wide hunting grounds across Tanaris - see the highlighted zones on the map." },

    { name = "Silt Crawler", zone = "Swamp of Sorrows", fromAreas = true,
      description = "Found in several wide hunting grounds across Swamp of Sorrows - see the highlighted zones on the map." },

    { name = "Angerclaw Mauler", zone = "Felwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Felwood - see the highlighted zones on the map." },

    { name = "Deathlash Scorpid", zone = "Burning Steppes", fromAreas = true,
      description = "Found in several wide hunting grounds across Burning Steppes - see the highlighted zones on the map." },

    { name = "Diseased Grizzly", zone = "Western Plaguelands", fromAreas = true,
      description = "Found in several wide hunting grounds across Western Plaguelands - see the highlighted zones on the map." },

    { name = "Ironbeak Hunter", zone = "Felwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Felwood - see the highlighted zones on the map." },

    { name = "Ironfur Patriarch", zone = "Feralas", fromAreas = true,
      description = "Found in several wide hunting grounds across Feralas - see the highlighted zones on the map." },

    { name = "Shardtooth Bear", zone = "Winterspring", fromAreas = true,
      description = "Found in several wide hunting grounds across Winterspring - see the highlighted zones on the map." },

    { name = "Winterspring Owl", zone = "Winterspring", fromAreas = true,
      description = "Found in several wide hunting grounds across Winterspring - see the highlighted zones on the map." },

    { name = "Elder Shardtooth", zone = "Winterspring", fromAreas = true,
      description = "Found in several wide hunting grounds across Winterspring - see the highlighted zones on the map." },

    { name = "Winterspring Screecher", zone = "Winterspring", fromAreas = true,
      description = "Found in several wide hunting grounds across Winterspring - see the highlighted zones on the map." },

    { name = "Child of Jai'vhanel", zone = "Darkshore", fromAreas = true,
      description = "Found in several wide hunting grounds across Darkshore - see the highlighted zones on the map." },

    { name = "Durotar Tiger", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Elder Plainstrider", zone = "Mulgore", fromAreas = true,
      description = "Found in several wide hunting grounds across Mulgore - see the highlighted zones on the map." },

    { name = "Flatland Cougar", zone = "Mulgore", fromAreas = true,
      description = "Found in several wide hunting grounds across Mulgore - see the highlighted zones on the map." },

    { name = "Fleeting Plainstrider", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Foreststrider Fledgling", zone = "Darkshore", fromAreas = true,
      description = "Found in several wide hunting grounds across Darkshore - see the highlighted zones on the map." },

    { name = "Greater Duskbat", zone = "Tirisfal Glades", fromAreas = true,
      description = "Found in several wide hunting grounds across Tirisfal Glades - see the highlighted zones on the map." },

    { name = "Juvenile Snow Leopard", zone = "Dun Morogh", fromAreas = true,
      description = "Found in several wide hunting grounds across Dun Morogh - see the highlighted zones on the map." },

    { name = "Moonstalker Runt", zone = "Darkshore", fromAreas = true,
      description = "Found in several wide hunting grounds across Darkshore - see the highlighted zones on the map." },

    { name = "Nightsaber", zone = "Teldrassil", fromAreas = true,
      description = "Found in several wide hunting grounds across Teldrassil - see the highlighted zones on the map." },

    { name = "Prideclaw", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Shriekling Fledgling", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Giant Foreststrider", zone = "Darkshore", fromAreas = true,
      description = "Found in several wide hunting grounds across Darkshore - see the highlighted zones on the map." },

    { name = "Moonstalker Sire", zone = "Darkshore", fromAreas = true,
      description = "Found in several wide hunting grounds across Darkshore - see the highlighted zones on the map." },

    { name = "Ornery Plainstrider", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Savannah Patriarch", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Starving Mountain Lion", zone = "Hillsbrad Foothills", fromAreas = true,
      description = "Found in several wide hunting grounds across Hillsbrad Foothills - see the highlighted zones on the map." },

    { name = "Twilight Runner", zone = "Stonetalon Mountains", fromAreas = true,
      description = "Found in several wide hunting grounds across Stonetalon Mountains - see the highlighted zones on the map." },

    { name = "Crag Stalker", zone = "Thousand Needles", fromAreas = true,
      description = "Found in several wide hunting grounds across Thousand Needles - see the highlighted zones on the map." },

    { name = "Feral Mountain Lion", zone = "Hillsbrad Foothills", fromAreas = true,
      description = "Found in several wide hunting grounds across Hillsbrad Foothills - see the highlighted zones on the map." },

    { name = "Panther", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Young Panther", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Young Stranglethorn Tiger", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Ridge Huntress", zone = "Badlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Badlands - see the highlighted zones on the map." },

    { name = "Ridge Stalker", zone = "Badlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Badlands - see the highlighted zones on the map." },

    { name = "Jaguero Stalker", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Noxious Plaguebat", zone = "Eastern Plaguelands", fromAreas = true,
      description = "Found in several wide hunting grounds across Eastern Plaguelands - see the highlighted zones on the map." },

    { name = "Plaguebat", zone = "Eastern Plaguelands", fromAreas = true,
      description = "Found in several wide hunting grounds across Eastern Plaguelands - see the highlighted zones on the map." },

    { name = "Frostsaber Cub", zone = "Winterspring", fromAreas = true,
      description = "Found in several wide hunting grounds across Winterspring - see the highlighted zones on the map." },

    { name = "Monstrous Plaguebat", zone = "Eastern Plaguelands", fromAreas = true,
      description = "Found in several wide hunting grounds across Eastern Plaguelands - see the highlighted zones on the map." },

    { name = "Bonepaw Hyena", zone = "Desolace", fromAreas = true,
      description = "Found in several wide hunting grounds across Desolace - see the highlighted zones on the map." },

    { name = "Elder Crag Coyote", zone = "Badlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Badlands - see the highlighted zones on the map." },

    { name = "Feral Crag Coyote", zone = "Badlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Badlands - see the highlighted zones on the map." },

    { name = "Kurzen War Tiger", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Magram Bonepaw", zone = "Desolace", fromAreas = true,
      description = "Found in several wide hunting grounds across Desolace - see the highlighted zones on the map." },

    { name = "Stranglethorn Tiger", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Swamp Jaguar", zone = "Swamp of Sorrows", fromAreas = true,
      description = "Found in several wide hunting grounds across Swamp of Sorrows - see the highlighted zones on the map." },

    { name = "Bhag'thera", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Blisterpaw Hyena", zone = "Tanaris", fromAreas = true,
      description = "Found in several wide hunting grounds across Tanaris - see the highlighted zones on the map." },

    { name = "Elder Shadowmaw Panther", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Rabid Blisterpaw", zone = "Tanaris", fromAreas = true,
      description = "Found in several wide hunting grounds across Tanaris - see the highlighted zones on the map." },

    { name = "Rabid Crag Coyote", zone = "Badlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Badlands - see the highlighted zones on the map." },

    { name = "Ridge Stalker Patriarch", zone = "Badlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Badlands - see the highlighted zones on the map." },

    { name = "Silvermane Stalker", zone = "The Hinterlands", fromAreas = true,
      description = "Found in several wide hunting grounds across The Hinterlands - see the highlighted zones on the map." },

    { name = "Starving Blisterpaw", zone = "Tanaris", fromAreas = true,
      description = "Found in several wide hunting grounds across Tanaris - see the highlighted zones on the map." },

    { name = "Blackrock Worg", zone = "Burning Steppes", fromAreas = true,
      description = "Found in several wide hunting grounds across Burning Steppes - see the highlighted zones on the map." },

    { name = "Frostsaber Huntress", zone = "Winterspring", fromAreas = true,
      description = "Found in several wide hunting grounds across Winterspring - see the highlighted zones on the map." },

    { name = "Frostsaber Stalker", zone = "Winterspring", fromAreas = true,
      description = "Found in several wide hunting grounds across Winterspring - see the highlighted zones on the map." },

    { name = "Greater Fleshripper", zone = "Westfall", fromAreas = true,
      description = "Found in several wide hunting grounds across Westfall - see the highlighted zones on the map." },

    { name = "Dread Ripper", zone = "Desolace", fromAreas = true,
      description = "Found in several wide hunting grounds across Desolace - see the highlighted zones on the map." },

    { name = "Salt Flats Vulture", zone = "Thousand Needles", fromAreas = true,
      description = "Found in several wide hunting grounds across Thousand Needles - see the highlighted zones on the map." },

    { name = "Carrion Vulture", zone = "Western Plaguelands", fromAreas = true,
      description = "Found in several wide hunting grounds across Western Plaguelands - see the highlighted zones on the map." },

    { name = "Dread Flyer", zone = "Desolace", fromAreas = true,
      description = "Found in several wide hunting grounds across Desolace - see the highlighted zones on the map." },

    { name = "Mesa Buzzard", zone = "Arathi Highlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Arathi Highlands - see the highlighted zones on the map." },

    { name = "Wayward Buzzard", zone = "Badlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Badlands - see the highlighted zones on the map." },

    { name = "Young Mesa Buzzard", zone = "Arathi Highlands", fromAreas = true,
      description = "Found in several wide hunting grounds across Arathi Highlands - see the highlighted zones on the map." },

    { name = "Fire Roc", zone = "Tanaris", fromAreas = true,
      description = "Found in several wide hunting grounds across Tanaris - see the highlighted zones on the map." },

    { name = "Ironbeak Owl", zone = "Felwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Felwood - see the highlighted zones on the map." },

    { name = "Roc", zone = "Tanaris", fromAreas = true,
      description = "Found in several wide hunting grounds across Tanaris - see the highlighted zones on the map." },

    { name = "Rogue Vale Screecher", zone = "Feralas", fromAreas = true,
      description = "Found in several wide hunting grounds across Feralas - see the highlighted zones on the map." },

    { name = "Searing Roc", zone = "Tanaris", fromAreas = true,
      description = "Found in several wide hunting grounds across Tanaris - see the highlighted zones on the map." },

    { name = "Vale Screecher", zone = "Feralas", fromAreas = true,
      description = "Found in several wide hunting grounds across Feralas - see the highlighted zones on the map." },

    { name = "Ironbeak Screecher", zone = "Felwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Felwood - see the highlighted zones on the map." },

    { name = "Galestrider", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Ornery Galestrider", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Longtooth Howler", zone = "Feralas", fromAreas = true,
      description = "Found in several wide hunting grounds across Feralas - see the highlighted zones on the map." },

    { name = "Silvermane Howler", zone = "The Hinterlands", fromAreas = true,
      description = "Found in several wide hunting grounds across The Hinterlands - see the highlighted zones on the map." },

    { name = "Silvermane Wolf", zone = "The Hinterlands", fromAreas = true,
      description = "Found in several wide hunting grounds across The Hinterlands - see the highlighted zones on the map." },

    { name = "Greater Thunderhawk", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Thunderhawk Cloudscraper", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Thunderhawk Hatchling", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Cloud Serpent", zone = "Thousand Needles", fromAreas = true,
      description = "Found in several wide hunting grounds across Thousand Needles - see the highlighted zones on the map." },

    { name = "Elder Cloud Serpent", zone = "Thousand Needles", fromAreas = true,
      description = "Found in several wide hunting grounds across Thousand Needles - see the highlighted zones on the map." },

    { name = "Venomous Cloud Serpent", zone = "Thousand Needles", fromAreas = true,
      description = "Found in several wide hunting grounds across Thousand Needles - see the highlighted zones on the map." },

    { name = "Mountain Lion", zone = "Alterac Mountains", fromAreas = true,
      description = "Found in several wide hunting grounds across Alterac Mountains - see the highlighted zones on the map." },

    { name = "Shadow Panther", zone = "Swamp of Sorrows", fromAreas = true,
      description = "Found in several wide hunting grounds across Swamp of Sorrows - see the highlighted zones on the map." },

    { name = "Shadowmaw Panther", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Shadowgale Shriekling", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Shriekling Matriarch", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Corrupted Scorpid", zone = "Durotar", fromAreas = true,
      description = "Found in several wide hunting grounds across Durotar - see the highlighted zones on the map." },

    { name = "Silithid Creeper", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Silithid Swarmer", zone = "The Barrens", fromAreas = true,
      description = "Found in several wide hunting grounds across The Barrens - see the highlighted zones on the map." },

    { name = "Scorpashi Venomlash", zone = "Desolace", fromAreas = true,
      description = "Found in several wide hunting grounds across Desolace - see the highlighted zones on the map." },

    { name = "Scorpid Terror", zone = "Thousand Needles", fromAreas = true,
      description = "Found in several wide hunting grounds across Thousand Needles - see the highlighted zones on the map." },

    { name = "Firetail Scorpid", zone = "Burning Steppes", fromAreas = true,
      description = "Found in several wide hunting grounds across Burning Steppes - see the highlighted zones on the map." },

    { name = "Stonelash Flayer", zone = "Silithus", fromAreas = true,
      description = "Found in several wide hunting grounds across Silithus - see the highlighted zones on the map." },

    { name = "Stonelash Pincer", zone = "Silithus", fromAreas = true,
      description = "Found in several wide hunting grounds across Silithus - see the highlighted zones on the map." },

    { name = "Jungle Thunderer", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Mistvale Gorilla", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Elder Mistvale Gorilla", zone = "Stranglethorn Vale", fromAreas = true,
      description = "Found in several wide hunting grounds across Stranglethorn Vale - see the highlighted zones on the map." },

    { name = "Groddoc Thunderer", zone = "Feralas", fromAreas = true,
      description = "Found in several wide hunting grounds across Feralas - see the highlighted zones on the map." },

    { name = "Un'Goro Thunderer", zone = "Un'Goro Crater", fromAreas = true,
      description = "Found in several wide hunting grounds across Un'Goro Crater - see the highlighted zones on the map." },

    { name = "Vuldren Alpha", zone = "Zephras Isle", fromAreas = true,
      description = "Found in several wide hunting grounds across Zephras Isle - see the highlighted zones on the map." },

    { name = "Moss Stalker", zone = "Silverpine Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Silverpine Forest - see the highlighted zones on the map." },

    { name = "Bloodwing Bat", zone = "Hillsbrad Foothills", fromAreas = true,
      description = "Found in several wide hunting grounds across Hillsbrad Foothills - see the highlighted zones on the map." },

    { name = "Foothills Duskbat", zone = "Silverpine Forest", fromAreas = true,
      description = "Found in several wide hunting grounds across Silverpine Forest - see the highlighted zones on the map." },

    { name = "Gray Fox", zone = "Duskwood", fromAreas = true,
      description = "Found in several wide hunting grounds across Duskwood - see the highlighted zones on the map." },

    -- No exact point found - zone and flavor text only, no Track button.
    { name = "Ukorsbane", zone = "Durotar", fromAreas = true,
      description = "An elite spider found in Durotar. It drops Ukor's Lost Pack, an item that starts a quest." },
    { name = "Princess", zone = "Elwynn Forest", fromAreas = true,
      description = "A unique boar roaming Elwynn Forest; player reports of her exact spot don't agree closely enough to pin with confidence." },
    { name = "Prowler", zone = "Elwynn Forest", fromAreas = true,
      description = "A unique wolf roaming Elwynn Forest alongside Princess, with no single confirmed camp of its own." },
    { name = "Besseleth", zone = "Stonetalon Mountains", fromAreas = true,
      description = "A spider that spawns at one of several spots within Sishir Canyon, moving between them rather than holding one camp." },
    { name = "U'cha", zone = "Un'Goro Crater", fromAreas = true,
      description = "A gorilla found somewhere in the southeastern reaches of Un'Goro Crater, among the other gorillas there." },
    { name = "Spot", zone = "Dustwallow Marsh", fromAreas = true,
      description = "Theramore Isle's own dog, kept behind the barracks on the island's west side - not out in the marsh proper." },
    { name = "Aku'mai Fisher", zone = "Blackfathom Deeps", dungeon = true,
      description = "A turtle found inside the Blackfathom Deeps dungeon, so it can't be tracked on the world map." },
    { name = "Deviate Crocolisk", zone = "Wailing Caverns", dungeon = true,
      description = "A crocolisk found inside the Wailing Caverns dungeon, so it can't be tracked on the world map." },
    { name = "Kresh", zone = "Wailing Caverns", dungeon = true,
      description = "A turtle found in a river channel inside Wailing Caverns, past the first druids and before the crocolisks." },
}

ns.TAME_TEACHER_SPAWNS = {}
for _, r in ipairs(raw) do
    local points = { { x = r.x, y = r.y, r = r.radius } }
    if r.extraPoints then
        for _, p in ipairs(r.extraPoints) do
            points[#points + 1] = { x = p.x, y = p.y, r = p.r or r.radius }
        end
    end
    local areas
    if r.fromAreas then
        areas = ns.TAME_TEACHER_AREAS and ns.TAME_TEACHER_AREAS[r.name]
        points = nil
        if areas then
            points = {}
            for _, a in ipairs(areas) do points[#points + 1] = { x = a.cx, y = a.cy } end
        end
    elseif not r.x then
        points = nil
    end
    ns.TAME_TEACHER_SPAWNS[#ns.TAME_TEACHER_SPAWNS + 1] = {
        name = r.name,
        zone = r.zone,
        mapID = ns.ZONE_MAP_IDS and ns.ZONE_MAP_IDS[r.zone] or nil,
        points = points,
        areas = areas, -- polygon highlight textures (one per point), or nil -> circle fallback
        description = r.description,
        isDungeon = r.dungeon or nil,
    }
end
