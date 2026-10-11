# PetSmart Changelog

## v1.61.0

- **Fixed:** while the pet page was open, hovering another section icon lost its highlight after a moment (the page's live refresh was resetting the icons). Hovered icons now stay lit, and the icons only re-arrange when a pet is summoned or dismissed.
- **Fixed:** the pet page (and the floating XP bar) threw "attempt to perform arithmetic on a secret number value" on clients that return protected "secret" stat values (e.g. pet health). Those values are now shown as-is; while they're secret the page can't add up or compare them, so numbers show without thousands separators, buff/debuff colouring is skipped, Attack Power shows the base value, Movement Speed shows "--" and the XP percentage is left off. Scrolling no longer errors on those clients either, on any Compendium page: the Compendium now has its own scrollbar (same look: arrows, draggable knob, mouse wheel) instead of Blizzard's scroll template, which broke once the scroll range became a secret value.
- **New: pet experience bar.** A free-floating experience bar, visible while a pet is out, styled like the one on the Compendium's pet page (gold-brown rounded border, blue gradient fill, gold at max level). It shows your pet's name, level and XP, e.g. "Muddles - 30 - XP: 12,480/34,900 (35%)"; on a narrower bar it drops the numbers first, then the name, keeping the percentage. Drag it to move it and drag its corner to resize it; hovering shows the exact XP and how much is left to the next level. New **Pet Experience Bar** options: Show Experience Bar, Show Bar Text, Lock Bar (Move/Resize), and Bar Width / Bar Height sliders. Saved per profile.
- **Under the hood:** the addon's code is now split into separate files by area instead of one large PetSmart.lua: `Core/` (setup, launchers, events), `Feeding/` (food and the Feed Pet icon), `Tracking/` (map pins and tracking), `Compendium/` (the window and page drawing) and `Sections/` (one file per Compendium section: Pet, Abilities, Training, Pet Types, Rare Spawns, Options). Everything loads in order from `embeds.xml`. No change in behaviour; this keeps each file well clear of Lua's per-file limits (the old single file was within 2 of one of them).
- The `Media` folder is sorted into `UI-Elements`, `Section-Backgrounds`, `Rare-Elements` and `Tame-Elements` (which holds the tame spawn-area `Areas`).
- **Compendium UI overhaul:** the Compendium is now a three-panel window.
  - **Top:** the new PetSmart logo, always visible, over a banner of the black lion (left) and white lion (right) set in one shared galaxy scene. Widening the window reveals more of the galaxy at either end; the lions always stay beside the logo.
  - **Left:** a column of section icons - Pet Abilities, General Training Info, Pet Types, Rare Pet Spawns and Options - each using that section's medallion artwork. Hovering an icon shows the section's name (Pet Abilities, General Training Info, Pet Types, Rare Pet Spawns, Options); the open section's icon is highlighted with a gold marker.
  - **Right:** the selected section's content (e.g. clicking the Rare Pet Spawns icon shows the rare pets list, Current Zone section and Track buttons, exactly as before).
- **New: current pet page.** While you have a pet out, a new icon (the seated black lion) appears at the top of the icon column and the others shift down one; it disappears again when the pet is dismissed. Its tooltip and page title are your pet's name, with "Level N Family" and the pet's current loyalty (e.g. "Best Friend") underneath. The page is styled after the in-game pet panel: an experience bar (blue gradient fill, gold at max level, framed to match the section headers), then framed **General** (health, armor, damage, attack power, critical strike, movement speed), **Resistances** (arcane, fire, frost, nature, shadow, each with its school icon) and **Abilities** (the active abilities your pet's family can learn, three per row: its Family Special plus tame-learned abilities like Bite, Claw, Cower, Dash and Dive; names only, no ranks; trainer-learned abilities such as the resistances are left out) sections, with gold labels and right-aligned values over the page's background art, and buffed/debuffed values in green/red. Everything updates live while the page is open. The page scrolls with the mouse wheel and has no visible scrollbar. If the pet is dismissed while you're on this page, the Compendium switches to Pet Abilities.
  - Critical strike uses the game's own pet crit value when the client provides one; otherwise it shows an estimate marked with "~" (5% base plus 3% per rank of Ferocity).
- The old main menu page has been replaced by the icon column. The Compendium now reopens on whichever section you used last.
- **Abilities Index** is now the third tab of Pet Abilities (next to Learned and Unlearned), since both share the paw-book icon.
- The "Main" button is gone (the icons do that job now). The "<- Back" text is replaced by a clickable paw-shield icon in the top-right corner of detail pages (an ability, pet type, rare, tameable creature or Manage Profiles); it steps back one level, e.g. from a rare back to the Rare Pet Spawns list.
- **Track/Untrack** is now a paw-print trail icon instead of text: **gold** with a faint glow while tracked, **grey** while not. Click it to toggle; hovering shows "Track" or "Untrack" ("Untrack All" when several rares are tracked). Hovering the back icon shows "Back". It's used on a rare's page, a tameable creature's page, and the Rare Pet Spawns / Abilities Index pages (where it untracks whatever's tracked). Tracked rares in the lists show a small gold paw trail instead of "[Tracked]".
- Page titles no longer start with "PetSmart - ", since the logo is always shown above them.
- The Compendium's default size is larger to fit the new layout. Its saved size starts fresh once after updating (your saved position is kept); after that, resizing is remembered as before.

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
