local ADDON_NAME, ns = ...

-- General flavor descriptions for the Pet Types panel. HAND-WRITTEN
-- short summaries (not scraped verbatim from any single source) informed
-- by Wowhead's Classic hunter pets guide
-- (wowhead.com/classic/guide/classic-wow-hunter-pets) and Petopia
-- Classic's per-family pages, limited to families that exist in
-- WoW: Forever. Deliberately free of any offense/defense/general combat
-- framing - the Pet Types panel reports that as "Unknown" until a
-- verified Forever-specific source exists.
--
-- Keys are the CreatureFamily IDs from FamilyData.lua.

ns.PET_TYPE_DESCRIPTIONS = {
    [1]  = "A loyal, versatile pack hunter at home in nearly any fight.",
    [2]  = "A swift, agile predator that relies on speed and stealth.",
    [3]  = "A venomous ambusher that binds foes in webbing.",
    [4]  = "A thick-hided brawler that shrugs off punishment.",
    [5]  = "A tusked omnivore willing to eat almost anything.",
    [6]  = "An ambush predator that lurks at the water's edge.",
    [7]  = "A scavenging flier that picks apart weakened prey.",
    [8]  = "A heavily armored crustacean built like a walking fortress.",
    [9]  = "A powerful, territorial brawler known for its ground-shaking slam.",
    [11] = "A fast, vicious hunter that tears into prey with claw and fang.",
    [12] = "A flightless ground bird with a surprisingly sturdy frame.",
    [20] = "An armored arachnid whose sting wears down its prey.",
    [21] = "A heavily-shelled reptile built to absorb punishment.",
    [24] = "A nimble flier that uses sound to disorient its prey.",
    [25] = "A scrappy pack hunter known for its infectious bite.",
    [26] = "A sharp-eyed raptor-bird with a taste for shiny trinkets.",
    [27] = "An elemental serpent that breathes crackling lightning.",
    [40] = "A clever, quick companion unique to Forever, known for its trickery.",
}
