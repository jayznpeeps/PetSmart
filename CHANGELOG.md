# PetSmart Changelog

## v1.60.1f

- **Minimap button:** The minimap button now uses the standard LibDBIcon-1.0 library, so minimap button managers like Leatrix Plus can pick it up. Your saved button position carries over.
- **Beast Training paws:** each ability on your pet's Learned and Unlearned lists and in the Abilities Index has a paw beside it: green if it's in your Beast Training, red if not yet. It turns green when you learn the ability (PetSmart spots the "You have learned ..." message) or when you open Beast Training, and it's remembered between sessions.
- **Tame data:** added Gray Fox (Duskwood) as the Trickster's Dance 1 teacher, Foothills Duskbat (Silverpine Forest) for Sonic Blast 1, Bloodwing Bat (Hillsbrad Foothills) for Sonic Blast 2, and Matriarch Bristlefur (Elwynn Forest) for Claw 2. Gray Fox, Foothills Duskbat and Bloodwing Bat can be tracked on the map with highlighted spawn areas. Highlands Ursera's level is now 7-8. Removed Vuldren Alpha from Trickster's Dance 1. Removed Prairie Wolf Alpha from Furious Howl 1.
- **Rare data:** Slydris's level is now 6.
- **Pet food:** Melon Juice is no longer offered as pet food (it's a player drink), and Red Delicious Stormapple is now recognised as fruit.
- **Feed panel:** it's now always wide enough for its "Feed <pet name>" title, even with only one food in it. Left-clicking the icon with no food your pet will eat now says so instead of opening an empty panel.
- **Fixed:** a "PetSmart tried to call the protected function" error when right-clicking the icon during combat.
- Bundled libraries updated to the current standard versions (LibStub, CallbackHandler-1.0, LibDataBroker-1.1) and LibDBIcon-1.0 added.

## v1.60.1e

### Compendium redesign
- **Three-panel window:** the PetSmart logo sits across the top over a banner of the black and white lions, section icons run down the left (hover for the section's name; the open one is marked in gold), and the selected section's content shows on the right.
- The old main menu page and the "Main" button are replaced by the icon column. The Compendium reopens on whichever section you used last.
- **Back icon:** detail pages have a paw-shield icon that steps back one level, replacing the "<- Back" text.
- **Track/Untrack icon:** a paw-print trail replaces the text; gold while tracked, grey while not.
- Page titles no longer start with "PetSmart - ", since the logo is always shown above them.
- The Compendium's default size is larger to fit the new layout. Its saved size starts fresh once after updating (your saved position is kept); after that, resizing is remembered as before.

### New: current pet page
- While you have a pet out, a new icon appears at the top of the icon column and the others shift down one; it disappears when the pet is dismissed. If the pet is dismissed while its page is open, the Compendium switches to the Abilities Index.
- **Family art:** the icon and the page's background show the medallion for your pet's family (Bat, Bear, Bird of Prey, Boar, Carrion Bird, Cat (the seated black lion), Crab, Crocolisk, Fox, Gorilla, Hyena, Raptor, Scorpid, Spider, Tallstrider, Turtle, Wind Serpent, Wolf), switching when you summon a different pet.
- **Header:** the pet's name, "Level N Family" and current loyalty (e.g. "Best Friend"), with the pet's experience bar on the right ("XP: 12,480 / 34,900 (35%)": blue gradient, gold at max level). The icon's tooltip is the pet's name.
- **Stats**, styled after the in-game pet panel, in framed sections:
  - **General:** health, armor, damage, attack power, critical strike and movement speed.
  - **Resistances:** arcane, fire, frost, nature and shadow, each with its school icon.
  - **Abilities:** the active abilities your pet's family can learn, three per row (its Family Special plus tame-learned abilities like Bite, Claw, Cower, Dash and Dive; names only, no trainer-learned abilities).
  - Buffed and debuffed values are green and red.
- **Learned / Unlearned:** the pet's learned and unlearned ability lists moved from their own page into the pet page. Links on the right of the header swap the stats for either list, and a back arrow returns to the stats.
- Everything updates live while the page is open.

### New: pet experience bar
- A movable, resizable bar showing your pet's name, level and XP while a pet is out. Its options (show/hide, text, lock, colour, width and height) are under Options > Pet Experience Bar.

### Other changes
- **Abilities Index:** now its own section icon (tooltip and page header "Abilities Index"), and it opens with all sections expanded; click a section heading to collapse it.
- **Teacher pet tracking:** a teacher pet that is also one of the listed rare spawns (40 of them, e.g. Timber, Bjarn, Broken Tooth, Leech Widow) uses the rare pin on the world map and minimap instead of the bronze paw pin.
- **Profiles use the full character name.** WoW: Forever characters have a first and second name and no realm, so profiles are keyed by the full name ("First Last") instead of "Name - Realm". Existing saves move over automatically on login: the character keeps its profile and settings, and a personal profile named after the first name alone is renamed to the full name (unless another character shares it). Manage Profiles shows "First Last is using:".
- **New option: Show Tooltip.** Options > Tooltip > Show Tooltip turns the main (feed) icon's hover tooltip on or off. On by default.
- Options: the Multi-Tracking note is shown next to the option, "(can break immersion)".

### Under the hood
- Code restructuring and cleanup.

## v1.60.1d

- Added Ukorsbane (Spider, Lv 8 Elite, Durotar) to the Bite Rank 1 tame list.
- Fixed Araga (Desolace rare) using the wrong map ID, which sent its tracking to the wrong map.

## v1.60.1c

- **Tame-teacher tracking greatly expanded:** **242 tame creatures** can now be tracked from the Abilities Index (paw-pin on the world map and minimap), with spawn-area highlights on the world map covering 239 of them across 318 areas. The remaining creatures in the tame lists either live inside a dungeon/raid (they show a Track button that explains they can't be tracked on the map) or don't have known spawn locations yet.
- Fixed a typo in the tame-creature list: "Highlands Usera" is now "Highlands Ursera".
- Aku'mai Fisher is now marked as a Blackfathom Deeps dungeon creature: it has a Track button that explains it can't be tracked on the map, like other dungeon creatures.
- Deviate Crocolisk is now marked as a Wailing Caverns dungeon creature: it has a Track button that explains it can't be tracked on the map, like other dungeon creatures.
- Added Highland Tortoise (Turtle, Lv 26, Wetlands) to the Bite Rank 4 tame list.
- Added the spawn location for Vulgara the Insatiable (Zephras Isle, 42.8, 52.2), so it can now be tracked from the Abilities Index.

## v1.60.1b

- **Fixed:** a Lua error that could repeat thousands of times on login ("Cannot find a library instance of CallbackHandler-1.0", followed by "HereBeDragons-Pins-2.0.lua: attempt to call a nil value"). The bundled libraries were loading in the wrong order (CallbackHandler-1.0 now loads before HereBeDragons), which left the minimap pin library half-initialised. HereBeDragons no longer hard-requires CallbackHandler-1.0 (it uses a built-in fallback if it can't be found), is far more tolerant of map-data problems at startup, and the pin updater safely does nothing if the library is incomplete.
- Bundled libraries are now loaded through an `embeds.xml` file referenced from the TOC (in a fixed order: LibStub, CallbackHandler, HereBeDragons, HereBeDragons-Pins, LibDataBroker), the same way other addons embed libraries.
- PetSmart's bundled HereBeDragons libraries now register under private names, so another addon's copy can no longer replace them.
- Slash commands are now `/petsmart` or `/ps`. `/petsmart` shows/hides the Compendium (like left-clicking the launcher) and `/petsmart options` jumps straight to the Options panel (like right-clicking it). The old `/fp` alias and the other sub-commands (lock, unlock, reset, all, add, remove) were removed.
- **Beta:** Tame-teacher tracking in the Abilities Index is a **beta feature that is still being implemented**. Each "Tame one of:" creature under an ability rank is clickable and opens a creature page with Track/Untrack (paw-pin on the world map and minimap), showing spawn areas as a light-blue highlight with a dark-blue outline. Spawn data is incomplete: many creatures have no known locations yet, dungeon creatures cannot be tracked, and only some areas use traced shapes. Expect gaps and changes.
- Tracked teacher pets can now be untracked like rares: middle-click the on-screen icon, minimap button or broker launcher (tooltips list it, and "Untrack All" counts the teacher too), or use the new **Untrack** button in the Abilities Index subheader.
- Map pin tooltips now include the mob's level, e.g. "Humar the Pridelord (Lv 23)" or "Prairie Wolf (Lv 5-6)". Hovering a highlighted teacher-pet spawn area (only the highlighted shape itself) shows the same tooltip.
- Fixed a typo in the tame-creature list: "Juveline Vuldren" is now "Juvenile Vuldren".
- Fixed: tracking a teacher pet now opens the map to the correct zone and shows its pins immediately, and Back from a creature page returns to the ability rank instead of a blank panel.

## v1.60.1a

- Rare Pet Spawns now opens with a **Current Zone** section at the top, showing any rares known to spawn in your current zone (e.g. standing in The Barrens surfaces its Barrens rares first). It updates automatically if you change zones while the panel's open. Clicking a rare here works exactly like clicking one in the family list below - same detail page, same Track/Untrack button. The existing by-family listing is unchanged beneath it.
- The Current Zone section now has a **Track All** option (only shown with Multi-Tracking enabled) that tracks every rare in your current zone at once. If you're already tracking rares from a different zone, it'll ask "Tracking All in this zone will untrack the previous zone." before swapping over - Cancel leaves your existing tracking exactly as it was.
- The main icon's tooltip now says "Right-click: Open/Close Compendium" (previously just "Right-click: Compendium") to make clear right-clicking toggles the panel rather than only opening it.

## v1.60.1 - Initial Release

PetSmart is a Hunter pet-care and pet-reference addon for WoW: Forever (Beta). It's built around two things Hunters juggle constantly - keeping a pet fed and happy, and knowing where to find/tame/train pets - and wraps both into one addon with no other dependencies required to use it.

### Pet Feeding Bar

- A movable, resizable on-screen icon (uses the Feed Pet ability icon) that opens a bag-style food panel.
- Left-click the icon to see a filtered list of food in your bags, limited to only what your **current pet's family** will actually eat - no more scrolling past Cheese and Fish your pet ignores.
- Click any food item in the panel to feed it to your pet directly (casts Feed Pet on that exact bag slot).
- Food is classified by category (Bread, Cheese, Fish, Fruit, Fungus, Meat) using item data plus a hand-maintained lookup table for items that don't classify cleanly on their own, and a diet fallback table covering every pet family (Boars eat everything; every other family eats a specific subset).
- Icon size is adjustable from the Options panel (20px-64px).
- Slash commands: `/petsmart` or `/ps`.

### Pet Abilities Compendium

A full in-game reference panel (separate from the feeding bar), covering:

- **Pet Abilities** - shows your currently active pet's learned and not-yet-learned abilities, with level/training-point requirements.
- **Abilities Index** - a complete, unfiltered reference of every pet ability in the game (31 abilities across all ranks), split into three collapsible sections:
  - *Trainer Learned* - abilities any pet can learn from a class trainer.
  - *General Tame* - abilities not taught by a trainer, usable by multiple families, learned only by taming a pet that already knows them (e.g. Cower, Bite, Claw, Dash, Dive).
  - *Family Special* - abilities unique to a single pet family (e.g. Savage Rend for Raptors, Web for Spiders).
  - Clicking any ability opens a detail page: which families can use it, every rank's level/training-point/gold cost, and (for tame-only abilities) a list of tameable pets that already know it, with their level and zone.
- **General Training Info** - condensed, collapsible reference sections covering Loyalty, Pet Food & Happiness, Training Points, Taming a Pet, Learning & Teaching Abilities, Stable Masters & Stable Slots, and Pet Command Modes.
- **Pet Types** - browse all 18 tameable pet families, each with its diet, combat role (Offensive/Defensive/General), basic attack, relative Health/Armor/DPS, and the family-special abilities unique to it.
- **Rare Pet Spawns** - a reference list of 74 known rare/unique tameable pets, each with level, zone, coordinates, and a short description. Selecting a rare places a tracking pin on the world map and minimap.

### Rare Spawn Tracking

- Track one rare at a time by default, or enable **Multi-Tracking** in Options to track several rares at once (off by default - noted as a feature that can work against the "is this actually here" feeling of hunting a rare).
- Tracked rares show as pins on both the world map and minimap, toggleable independently in Options.
- A minimap launcher icon and LibDataBroker object (for Titan Panel, Bazooka, and similar broker-display addons) both give quick access to the addon and support untracking all rares with a middle-click.

### Options & Profiles

- Per-character profiles (switch, copy, reset, or delete), so multiple characters can share a setup or keep their own.
- Tooltip toggles for showing pet name, loyalty, and happiness.
- Minimap icon visibility and icon size.
- Rare-tracking pin visibility (world map / minimap) and Multi-Tracking.
- Panel lock (prevents accidental move/resize of the Compendium panel).

### Credits

Data cross-referenced from wowhead.com and wow-petopia.com. Special thanks to Nosferatu.
