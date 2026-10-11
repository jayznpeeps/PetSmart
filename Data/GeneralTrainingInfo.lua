local ADDON_NAME, ns = ...

-- Reference text for the "General Training Info" panel. HAND-WRITTEN,
-- condensed from Wowhead's Classic hunter pets guide
-- (wowhead.com/classic/guide/classic-wow-hunter-pets) for everything
-- except the Compact Critter Carrier lines (folded into Stable Masters &
-- Stable Slots, since it's another way to reach a stabled pet), which
-- come from its own Wowhead Forever item/spell page
-- (wowhead.com/forever/spell=1266920/compact-critter-carrier).
--
-- Each entry is { title = "...", lines = { "...", "...", ... } }, shown
-- in order as a gold section title followed by its body lines.

ns.GENERAL_TRAINING_INFO = {
    {
        title = "Loyalty",
        lines = {
            "Your pet's loyalty rises through six ranks: Rebellious, Unruly, Submissive, Dependable, Faithful, and Best Friend.",
            "Rebellious - Very low loyalty. Failing to feed the pet, dismissing it frequently, or getting yourself or the pet killed repeatedly has a high probability of the pet abandoning you.",
            "Unruly - Your pet is still not convinced, so you'll need to keep treating it well and not abusing its trust. It can still leave you at this stage.",
            "Submissive - The pet is more willing to put up with some bad luck occasionally, and needs less food to keep it happy.",
            "Dependable - Loyalty is still improving and food requirements are continuing to go down.",
            "Faithful - Less food is required, and the likelihood of running off is very slim.",
            "Best Friend - The highest loyalty rank. The pet requires the least amount of food to keep happy and goes longer between feedings.",
            "Higher loyalty also increases the training points your pet has available (see Training Points below).",
        },
    },
    {
        title = "Pet Food & Happiness",
        lines = {
            "Your pet's happiness affects its damage output: Happy pets deal 125% damage, Content pets deal 100%, and Unhappy pets deal only 75%.",
            "There are six food categories: Bread, Cheese, Fish, Fruit, Fungus, and Meat. Each pet family will only eat certain categories - see that family's entry in Pet Types for its diet. Boars are the only family that will eat anything from all six categories.",
            "Lower-loyalty pets need to be fed more often to stay happy; higher-loyalty pets go longer between feedings.",
        },
    },
    {
        title = "Training Points",
        lines = {
            "Training points are earned as your pet gains levels and loyalty, following the formula: pet level x (loyalty rank - 1).",
            "A level 60 pet at the highest loyalty rank (Best Friend) has a maximum of 300 training points.",
            "Training points are spent to teach your pet abilities, whether learned from a trainer or from taming. A pet can only have 4 active abilities learned at any one time, so choose which ones to train carefully.",
        },
    },
    {
        title = "Taming a Pet",
        lines = {
            "Hunters can start taming pets at level 10.",
            "You can only tame a beast that is at or below your own level.",
            "Taming channels the Tame Beast spell; while channeling it you lose 100% of your armor, leaving you vulnerable to attack.",
            "Abilities such as Concussive Shot, Aspect of the Monkey, and Freezing Trap can help protect you while taming. For tougher beasts, having a Mage or Druid keep it crowd-controlled (Polymorph or Hibernate) helps too.",
        },
    },
    {
        title = "Learning & Teaching Abilities",
        lines = {
            "Some pet abilities can't be learned from a trainer at all - they can only be learned by taming a pet that already knows them.",
            "Taming that 'teacher' pet doesn't grant you the ability right away. The pet must actively use that ability in combat - it won't count just by knowing it or using it outside of combat - and you must keep fighting with that pet until you get a message that you've learned the skill.",
            "Once the ability is learned, it's learned permanently - you can release the teacher pet and spend training points to teach the ability to any other compatible pet, including your main one.",
        },
    },
    {
        title = "Stable Masters & Stable Slots",
        lines = {
            "A Stable Master is an NPC found in most friendly hubs who lets you store extra pets you aren't currently using.",
            "You can only have one active pet out at a time, but you can keep two more stabled with a Stable Master - three pets total.",
            "Compact Critter Carrier - a Hunter-only crafted item, made by Blacksmiths. Using it places a Compact Critter Carrier that lasts 3 minutes, letting Hunters in your group access their stabled pets from anywhere, without needing to find a Stable Master.",
            "Casting the Compact Critter Carrier has a 45 second cast time and a 30 minute cooldown, and requires level 40 to use.",
        },
    },
    {
        title = "Pet Command Modes",
        lines = {
            "Aggressive - the pet attacks any enemy that comes within its aggro radius on its own, without needing a direct command.",
            "Assist - the pet attacks whatever target its master attacks, automatically switching targets if its master does. With no target to assist, it behaves like Defensive.",
            "Defensive - the pet won't attack on its own, but will retaliate immediately if it or its master is actually hit.",
            "Passive - the pet will not attack unless given a direct Attack command, and ignores attacks made against itself or its master.",
        },
    },
}
