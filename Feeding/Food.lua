--------------------------------------------------------------------------
-- PetSmart: Feeding/Food.lua
-- Pet diets and food classification: which bag items the current pet will eat.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local ItemClassIDs = ns.ItemClassIDs
local LAST_BAG = ns.LAST_BAG
local NumSlots = ns.NumSlots
local SlotInfo = ns.SlotInfo

----------------------------------------------------------------------
-- Pet diet
----------------------------------------------------------------------
local FOOD_TYPES = { "Meat", "Fish", "Bread", "Cheese", "Fruit", "Fungus" }

-- Fallback diets (classic-era) used if the client has no GetPetFoodTypes().
local FAMILY_DIET = {
    ["bat"]          = { "Fruit", "Fungus" },
    ["bear"]         = { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" },
    ["boar"]         = { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" },
    ["carrion bird"] = { "Fish", "Meat" },
    ["cat"]          = { "Fish", "Meat" },
    ["crab"]         = { "Bread", "Fish", "Fruit", "Fungus" },
    ["crocolisk"]    = { "Fish", "Meat" },
    ["fox"]          = { "Meat" },
    ["gorilla"]      = { "Fruit", "Fungus" },
    ["hyena"]        = { "Fruit", "Meat" },
    ["owl"]          = { "Meat" },
    ["raptor"]       = { "Meat" },
    ["scorpid"]      = { "Meat" },
    ["serpent"]      = { "Fish", "Meat" },
    ["spider"]       = { "Meat" },
    ["tallstrider"]  = { "Cheese", "Fruit", "Fungus", "Meat" },
    ["turtle"]       = { "Fish", "Fruit", "Fungus" },
    ["wind serpent"] = { "Bread", "Cheese", "Fish" },
    ["wolf"]         = { "Meat" },
}

local function ToSet(list)
    local set, any = {}, false
    for _, v in ipairs(list) do
        for _, t in ipairs(FOOD_TYPES) do
            if tostring(v):lower() == t:lower() then set[t] = true; any = true end
        end
    end
    return any and set or nil
end

-- Returns a set like { Meat = true, Fish = true } or nil if unknown.
local function GetPetDiet()
    if not UnitExists("pet") then return nil end
    if GetPetFoodTypes then
        local set = ToSet({ GetPetFoodTypes() })
        if set then return set end
    end
    local family = UnitCreatureFamily and UnitCreatureFamily("pet")
    if family and FAMILY_DIET[family:lower()] then
        return ToSet(FAMILY_DIET[family:lower()])
    end
    return nil
end

----------------------------------------------------------------------
-- Food classification (known items + item name keywords + user overrides)
----------------------------------------------------------------------
-- Items whose food type is known outright by item ID, rather than left to
-- the name-keyword guesswork below - for items whose name wouldn't
-- otherwise be caught (or could be guessed wrong) by those keywords.
-- Checked before the keyword pass, but a player's own /fp override (see
-- Classify() below) still wins over even this.
local KNOWN_ITEMS = {
    [1205] = "NONE",  -- Melon Juice - a drink for players (restores mana), not pet food
    [6889] = "NONE",  -- Small Egg - a cooking crafting reagent, not something a pet can eat
                       -- (its name matched the "egg" keyword in the Meat list below, which is
                       -- otherwise meant for real food like eggs/omelets, not this reagent)
}

-- Same idea, by exact item name (lower-case) - for items whose ID isn't
-- recorded here, e.g. Forever-only foods.
local KNOWN_NAMES = {
    ["melon juice"] = "NONE",               -- player drink (mana), not pet food
    ["red delicious stormapple"] = "Fruit", -- Forever fruit
}

local KEYWORDS = {
    { "Cheese", { "cheese", "bleu", "brie", "swiss", "sharp", "cheddar" } },
    { "Fungus", { "mushroom", "mushrooms", "truffle", "fungus", "morel", "shroom" } },
    { "Fruit",  { "apple", "stormapple", "banana", "melon", "berry", "berries", "pear", "grape", "grapes",
                  "peach", "pineapple", "plum", "cherry", "orange", "lemon", "fruit", "fig",
                  "coconut", "mango", "papaya", "pomegranate" } },
    { "Bread",  { "bread", "muffin", "biscuit", "roll", "rolls", "loaf", "cornbread", "flatbread",
                  "pastry", "sourdough", "baguette", "bun", "pretzel", "cracker" } },
    { "Fish",   { "fish", "salmon", "trout", "bass", "snapper", "mackerel", "cod", "eel",
                  "lobster", "catfish", "tuna", "herring", "sardine", "smallfish", "clam",
                  "oyster", "squid", "sunfish", "grouper", "flounder", "crab", "shrimp",
                  "calamari", "seafood" } },
    { "Meat",   { "meat", "steak", "jerky", "ham", "sausage", "chop", "chops", "rib", "ribs",
                  "haunch", "drumstick", "wing", "wings", "leg", "tenderloin", "venison",
                  "turkey", "chicken", "egg", "eggs", "brain", "liver", "heart", "flank",
                  "filet", "shank", "kabob", "kebab", "gizzard", "rump", "roast", "mutton",
                  "lamb", "beef", "pork", "bacon", "stew", "spare", "tail", "tails" } },
}

local function Classify(itemID, name)
    local override = PetSmartDB.custom[itemID]
    if override then return override end
    if KNOWN_ITEMS[itemID] then return KNOWN_ITEMS[itemID] end
    local lname = (name or ""):lower()
    if KNOWN_NAMES[lname] then return KNOWN_NAMES[lname] end
    for _, group in ipairs(KEYWORDS) do
        for _, kw in ipairs(group[2]) do
            if lname:find("%f[%a]" .. kw .. "%f[%A]") then return group[1] end
        end
    end
    return nil
end

local function IsFoodItemClass(itemID)
    local classID, subID = ItemClassIDs(itemID)
    if not classID then return true end            -- unknown -> let name check decide
    if classID == 0 and subID == 5 then return true end  -- Consumable: Food & Drink
    if classID == 7 and subID == 8 then return true end  -- Trade goods: Meat / Cooking (raw meat & fish)
    return false
end

----------------------------------------------------------------------
-- Build list of feedable items from bags
----------------------------------------------------------------------
local function BuildFoodList()
    local diet = GetPetDiet()
    local list = {}
    for bag = 0, LAST_BAG do
        for slot = 1, NumSlots(bag) do
            local id, icon, count, link = SlotInfo(bag, slot)
            if id and IsFoodItemClass(id) then
                local name = link and link:match("%[(.-)%]") or ""
                local ftype = Classify(id, name)
                local ok
                if PetSmartDB.showAll then
                    ok = ftype ~= "NONE"
                else
                    ok = ftype and ftype ~= "NONE" and (diet == nil or diet[ftype])
                end
                if ok then
                    list[#list + 1] = {
                        bag = bag, slot = slot, id = id, icon = icon,
                        count = count or 1, link = link, name = name, ftype = ftype or "?",
                    }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.ftype ~= b.ftype then return a.ftype < b.ftype end
        if a.name ~= b.name then return a.name < b.name end
        return a.count > b.count
    end)
    return list
end

-- Exported for the other PetSmart files.
ns.BuildFoodList = BuildFoodList
