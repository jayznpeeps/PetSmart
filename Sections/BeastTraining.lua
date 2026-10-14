--------------------------------------------------------------------------
-- PetSmart: Sections/BeastTraining.lua
-- Which pet abilities the hunter can teach from the Beast Training window,
-- for the green/red paws on the pet's Learned list.
--------------------------------------------------------------------------
local addonName, ns = ...

-- The game only lists Beast Training's contents while that window is open,
-- so every time it opens (or changes) the list is read and saved for this
-- character in PetSmartDB.beastTraining[charKey]:
--   spells = { [spellId] = true }        from each entry's link, when it has one
--   names  = { ["bite#3"] = true }       lower-case name + rank, as a fallback
-- Until it has been opened once, the hunter's own spellbook is used instead.
local BT = {}
ns.BeastTraining = BT

BT.PAW_GREEN = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\PawGreen"
BT.PAW_RED = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\PawRed"

local function Lower(s)
    return type(s) == "string" and s:lower() or nil
end

-- Letters only, lower-case ("Great Stamina" / "greatstamina" -> "greatstamina"),
-- so a name matches whatever spacing/punctuation the client uses.
local function Norm(s)
    return type(s) == "string" and s:lower():gsub("[^%a]", "") or nil
end

-- Bumped when the saved format changes; an older save is ignored (and
-- rebuilt the next time Beast Training is opened). v3: ranks resolved properly.
BT.STORE_VERSION = 3

function BT.Store()
    if not (PetSmartDB and ns.GetCharKey) then return nil end
    PetSmartDB.beastTraining = PetSmartDB.beastTraining or {}
    local s = PetSmartDB.beastTraining[ns.GetCharKey()]
    if s and s.v ~= BT.STORE_VERSION then return nil end
    return s
end

function BT.HasScan()
    return BT.Store() ~= nil
end

-- Lower-case names of every pet ability PetSmart knows (its own display names
-- plus the client's spell names), so any open profession-style window can be
-- recognised as Beast Training by its contents - whatever the client calls the
-- window or whichever list API it uses.
local abilityNames
local function AbilityNames()
    if abilityNames then return abilityNames end
    abilityNames = {}
    for key, entry in pairs(ns.PET_ABILITIES or {}) do
        if entry.displayName then abilityNames[entry.displayName:lower()] = true end
        for _, r in ipairs(entry.ranks or {}) do
            local nm = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(r.spellId))
                or (GetSpellInfo and GetSpellInfo(r.spellId))
            if type(nm) == "string" then abilityNames[nm:lower()] = true end
        end
        abilityNames[key:lower()] = true
    end
    local extra = {}
    for nm in pairs(abilityNames) do extra[Norm(nm)] = true end
    for nm in pairs(extra) do abilityNames[nm] = true end
    return abilityNames
end

-- lower-case ability name -> its ns.PET_ABILITIES entry (to work out ranks)
local abilityByName
local function AbilityByName(lname)
    if not abilityByName then
        abilityByName = {}
        for key, entry in pairs(ns.PET_ABILITIES or {}) do
            abilityByName[key:lower()] = entry
            abilityByName[Norm(key)] = entry
            if entry.displayName then
                abilityByName[entry.displayName:lower()] = entry
                abilityByName[Norm(entry.displayName)] = entry
            end
            for _, r in ipairs(entry.ranks or {}) do
                local nm = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(r.spellId))
                    or (GetSpellInfo and GetSpellInfo(r.spellId))
                if type(nm) == "string" then
                    abilityByName[nm:lower()] = entry
                    abilityByName[Norm(nm)] = entry
                end
            end
        end
    end
    return abilityByName[lname]
end

-- Which rank a Beast Training entry is, when its text doesn't say: by its
-- spell ID, its description (matched against the wowhead.com/forever rank
-- tooltips in Data\PetAbilityDescriptions.lua), or its required pet level.
local function ResolveRank(e)
    if e.rank then return e.rank end
    local entry = AbilityByName(e.name:lower()) or AbilityByName(Norm(e.name))
    if not entry then return nil end
    local ranks = entry.ranks or {}
    if e.spellId then
        for _, r in ipairs(ranks) do if r.spellId == e.spellId then return r.rank end end
    end
    -- Description: only when exactly one rank has that text (Growl's ranks,
    -- for one, all share the same tooltip, so it can't tell them apart).
    if type(e.desc) == "string" and e.desc ~= "" and ns.PET_ABILITY_RANK_TOOLTIPS then
        local d = e.desc:gsub("%s+", " "):lower()
        local hit, hits = nil, 0
        for _, r in ipairs(ranks) do
            local t = ns.PET_ABILITY_RANK_TOOLTIPS[r.spellId]
            if type(t) == "string" and t:gsub("%s+", " "):lower() == d then hit, hits = r.rank, hits + 1 end
        end
        if hits == 1 then return hit end
    end
    if tonumber(e.level) then
        local hit, hits = nil, 0
        for _, r in ipairs(ranks) do
            if r.petLevel == tonumber(e.level) then hit, hits = r.rank, hits + 1 end
        end
        if hits == 1 then return hit end
    end
    if #ranks == 1 then return ranks[1].rank end
    return nil
end

-- The rank from "Rank 3" / "Bite (Rank 3)" / "Bite 3" style text, or nil.
local function ParseRank(sub, name)
    local r = type(sub) == "string" and tonumber(sub:match("(%d+)") or "")
    if not r and type(name) == "string" then r = tonumber(name:match("%(%a+ (%d+)%)") or name:match(" (%d+)$") or "") end
    return r or nil
end

local function StripRank(name)
    return (name:gsub("%s*%(.-%)%s*$", ""):gsub("%s+%d+$", ""))
end

local function LinkSpellId(link)
    return type(link) == "string" and tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)") or "") or nil
end

-- Reads whichever list window is open (Craft, classic TradeSkill or the modern
-- C_TradeSkillUI). Returns entries { name, rank, spellId } and a short note on
-- where they came from (for /petsmart bt).
function BT.ReadOpenWindow()
    local out, src = {}, nil
    -- WoW: Forever's Beast Training window is a trainer-style window (Training
    -- Points, "Already known", a Train button), read with the trainer API.
    -- An NPC trainer uses the same API, so it's only read when no NPC is being
    -- talked to - i.e. the window came from the Beast Training spell.
    if GetNumTrainerServices and GetTrainerServiceInfo and not (UnitExists and UnitExists("npc")) then
        local ok, n = pcall(GetNumTrainerServices)
        if ok and (n or 0) > 0 then
            src = "Trainer"
            for i = 1, n do
                local ok2, name, sub, stype = pcall(GetTrainerServiceInfo, i)
                if ok2 and type(name) == "string" and stype ~= "header" then
                    local id, level, desc
                    if GetTrainerServiceItemLink then
                        local ok3, link = pcall(GetTrainerServiceItemLink, i)
                        id = ok3 and LinkSpellId(link) or nil
                    end
                    if GetTrainerServiceLevelReq then
                        local ok3, lv = pcall(GetTrainerServiceLevelReq, i)
                        level = ok3 and lv or nil
                    end
                    if GetTrainerServiceDescription then
                        local ok3, d = pcall(GetTrainerServiceDescription, i)
                        desc = ok3 and d or nil
                    end
                    out[#out + 1] = { name = StripRank(name), rank = ParseRank(sub, name), spellId = id,
                        level = level, desc = desc, sub = sub }
                end
            end
        end
    end
    if #out == 0 and GetNumCrafts and GetCraftInfo then
        local ok, n = pcall(GetNumCrafts)
        if ok and (n or 0) > 0 then
            src = "Craft"
            for i = 1, n do
                local name, sub, ctype = GetCraftInfo(i)
                if type(name) == "string" and ctype ~= "header" then
                    local id
                    for _, fname in ipairs({ "GetCraftItemLink", "GetCraftRecipeLink" }) do
                        local fn = _G[fname]
                        if fn and not id then
                            local ok2, link = pcall(fn, i)
                            id = ok2 and LinkSpellId(link) or nil
                        end
                    end
                    out[#out + 1] = { name = StripRank(name), rank = ParseRank(sub, name), spellId = id }
                end
            end
        end
    end
    if #out == 0 and GetNumTradeSkills and GetTradeSkillInfo then
        local ok, n = pcall(GetNumTradeSkills)
        if ok and (n or 0) > 0 then
            src = "TradeSkill"
            for i = 1, n do
                local name, ttype = GetTradeSkillInfo(i)
                if type(name) == "string" and ttype ~= "header" and ttype ~= "subheader" then
                    local id
                    if GetTradeSkillRecipeLink then
                        local ok2, link = pcall(GetTradeSkillRecipeLink, i)
                        id = ok2 and LinkSpellId(link) or nil
                    end
                    out[#out + 1] = { name = StripRank(name), rank = ParseRank(nil, name), spellId = id }
                end
            end
        end
    end
    if #out == 0 and C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo then
        local ok, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
        if ok and type(ids) == "table" and #ids > 0 then
            src = "C_TradeSkillUI"
            for _, rid in ipairs(ids) do
                local ok2, info = pcall(C_TradeSkillUI.GetRecipeInfo, rid)
                if ok2 and type(info) == "table" and type(info.name) == "string" and info.learned ~= false then
                    out[#out + 1] = { name = StripRank(info.name), rank = ParseRank(info.rank and tostring(info.rank), info.name), spellId = rid }
                end
            end
        end
    end
    return out, src
end

-- Redraw the pet's Learned / Unlearned list if one is open.
function BT.RefreshLists()
    local mode = ns.abilitiesMode
    if ns.abilitiesPanel and ns.abilitiesPanel:IsShown() and (mode == "learned" or mode == "unlearned" or mode == "index")
        and ns.RefreshAbilitiesPanel then
        ns.RefreshAbilitiesPanel()
    end
end

-- Records one ability rank as in the hunter's Beast Training (merged into the
-- saved list). Returns true if it was a pet ability PetSmart knows.
-- Highest rank of an ability the current pet knows (from the pet's own
-- spellbook). When the hunter learns an ability by watching their pet use it,
-- the game's message can name just the ability ("Claw") - the rank learned is
-- the one that pet has.
local function PetKnownRank(lname)
    local entry = AbilityByName(lname) or AbilityByName(Norm(lname))
    if not (entry and UnitExists and UnitExists("pet")) then return nil end
    local best
    for _, r in ipairs(entry.ranks or {}) do
        local known = false
        if IsSpellKnown then
            local ok, k = pcall(IsSpellKnown, r.spellId, true) -- true = the pet's spellbook
            known = ok and k or false
        end
        if not known and C_SpellBook and C_SpellBook.IsSpellInSpellBook and Enum and Enum.SpellBookSpellBank then
            local ok, k = pcall(C_SpellBook.IsSpellInSpellBook, r.spellId, Enum.SpellBookSpellBank.Pet)
            known = ok and k or false
        end
        if known and (not best or r.rank > best) then best = r.rank end
    end
    return best
end

-- The rank for a spell ID from PetSmart's ability data (or nil).
local function RankForSpellId(lname, spellId)
    local entry = spellId and (AbilityByName(lname) or AbilityByName(Norm(lname)))
    for _, r in ipairs(entry and entry.ranks or {}) do
        if r.spellId == spellId then return r.rank end
    end
    return nil
end

function BT.AddKnown(name, rank, spellId)
    if not (PetSmartDB and ns.GetCharKey and type(name) == "string") then return false end
    local lname = StripRank(name):lower()
    if not (AbilityNames()[lname] or AbilityNames()[Norm(lname)]) then return false end
    -- Rank text in the message first; then the rank your current pet knows (you
    -- learn an ability from your pet, and the game's link for it - e.g.
    -- "[Claw]" - carries no rank); then the link's spell ID; then, for a
    -- one-rank ability, that rank.
    rank = rank or PetKnownRank(lname) or RankForSpellId(lname, spellId) or ResolveRank({ name = lname })
    if not rank then return false end
    PetSmartDB.beastTraining = PetSmartDB.beastTraining or {}
    local key = ns.GetCharKey()
    local s = BT.Store() or { v = BT.STORE_VERSION, spells = {}, names = {} }
    s.names = s.names or {}
    s.names[lname .. "#" .. rank] = true
    s.names[Norm(lname) .. "#" .. rank] = true
    PetSmartDB.beastTraining[key] = s
    return true
end

-- "You have learned Bite (Rank 2)." / "You have learned a new ability: Bite (Rank 2)."
-- in the system chat channel -> add it, so the paws turn green without having
-- to open Beast Training. Patterns come from the client's own (localized)
-- message formats where available, plus the plain English wording.
local learnPatterns
local function LearnPatterns()
    if learnPatterns then return learnPatterns end
    learnPatterns = {}
    for _, g in ipairs({ "ERR_LEARN_ABILITY_S", "ERR_LEARN_SPELL_S", "ERR_LEARN_RECIPE_S", "ERR_LEARN_PASSIVE_S" }) do
        local fmt = _G[g]
        if type(fmt) == "string" and fmt:find("%%s") then
            local pat = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%%%s", "(.+)")
            learnPatterns[#learnPatterns + 1] = "^" .. pat .. "$"
        end
    end
    learnPatterns[#learnPatterns + 1] = "^You have learned a new %a+: (.+)$"
    learnPatterns[#learnPatterns + 1] = "^You have learned (.+)$"
    return learnPatterns
end

-- Only ever called for CHAT_MSG_SYSTEM: the game's own yellow system
-- messages. Players can't send those - anything a player types arrives as
-- CHAT_MSG_SAY / YELL / WHISPER / PARTY / GUILD / CHANNEL etc., which PetSmart
-- never listens to, and another addon printing text to a chat window doesn't
-- fire this event either. As a second check, a real system message has no
-- sender, no sender GUID and no channel - anything carrying one is ignored.
-- (arg2 = sender name, arg4/arg9 = channel name, arg12 = sender GUID)
local function FromGame(author, ...)
    local channelName = select(2, ...)      -- arg4
    local channelBaseName = select(7, ...)  -- arg9
    local guid = select(10, ...)            -- arg12
    local function empty(v)
        if issecretvalue and issecretvalue(v) then return false end -- can't inspect it: don't trust it
        return v == nil or v == "" or v == 0
    end
    return empty(author) and empty(channelName) and empty(channelBaseName) and empty(guid)
end
BT._FromGame = FromGame

function BT.OnSystemMessage(msg, ...)
    if type(msg) ~= "string" or (issecretvalue and issecretvalue(msg)) then return end
    if not FromGame(...) then return end
    -- the spell ID from a link, if the message has one ("|Hspell:16829|h[Claw]|h")
    local linkId = tonumber(msg:match("|Hspell:(%d+)") or msg:match("|Henchant:(%d+)") or "")
    -- strip colours and links: "|cff...|Hspell:123|h[Bite (Rank 2)]|h|r" -> "Bite (Rank 2)"
    local text = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h%[?(.-)%]?|h", "%1")
    for _, pat in ipairs(LearnPatterns()) do
        local what = text:match(pat)
        if what then
            what = what:gsub("%.$", ""):gsub("^%[", ""):gsub("%]$", "")
            local name, rank = what:match("^(.-)%s*%(%a+%s*(%d+)%)$")
            if not name then name, rank = what, nil end
            local added = BT.AddKnown(name, tonumber(rank), linkId)
            BT.lastLearn = ("%q -> %s"):format(msg:gsub("|", "||"), added and "added" or "not a pet ability / rank unknown")
            if added then BT.RefreshLists() end
            return
        end
    end
end
BT._LearnPatterns = LearnPatterns

function BT.Scan()
    if not (PetSmartDB and ns.GetCharKey) then return end
    local entries = BT.ReadOpenWindow()
    if #entries == 0 then return end
    local known = AbilityNames()
    local spells, names, matched = {}, {}, 0
    for _, e in ipairs(entries) do
        local lname = e.name:lower()
        if known[lname] or known[Norm(lname)] then
            matched = matched + 1
            local rank = ResolveRank(e)
            if rank then
                names[lname .. "#" .. rank] = true
                names[Norm(lname) .. "#" .. rank] = true
            end
            if e.spellId then spells[e.spellId] = true end
        end
    end
    -- Only a window full of pet abilities is Beast Training (not Enchanting,
    -- Cooking, ...); anything else is left alone.
    if matched == 0 or matched < #entries / 2 then return end
    -- Merged into what was already saved: the window's Filters can hide
    -- entries, and a hunter never loses an ability from Beast Training.
    PetSmartDB.beastTraining = PetSmartDB.beastTraining or {}
    local key = ns.GetCharKey()
    local old = BT.Store()
    if old then
        for k in pairs(old.spells or {}) do spells[k] = true end
        for k in pairs(old.names or {}) do names[k] = true end
    end
    PetSmartDB.beastTraining[key] = { v = BT.STORE_VERSION, spells = spells, names = names }
    BT.RefreshLists()
end

-- /petsmart bt - what the client reports for the open window, for troubleshooting.
function BT.Debug()
    local function P(...) print("|cff33ff99PetSmart BT:|r", ...) end
    local function has(n) return _G[n] and "yes" or "no" end
    P("APIs: GetNumTrainerServices=" .. has("GetNumTrainerServices") .. " GetNumCrafts=" .. has("GetNumCrafts") .. " GetNumTradeSkills=" .. has("GetNumTradeSkills")
        .. " C_TradeSkillUI=" .. ((C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs) and "yes" or "no"))
    if GetCraftDisplaySkillLine then P("Craft window:", tostring(select(2, pcall(GetCraftDisplaySkillLine)))) end
    if GetTradeSkillLine then P("TradeSkill window:", tostring(select(2, pcall(GetTradeSkillLine)))) end
    local entries, src = BT.ReadOpenWindow()
    P(("Read %d entries from %s"):format(#entries, tostring(src or "nothing open")))
    local known = AbilityNames()
    for i = 1, #entries do
        local e = entries[i]
        P(("  %s | sub=%s | level=%s | spell=%s -> rank %s%s"):format(e.name, tostring(e.sub), tostring(e.level),
            tostring(e.spellId), tostring(ResolveRank(e)), known[e.name:lower()] and "" or " (not a pet ability)"))
    end
    -- What the client offers that could be Beast Training (names only).
    local found = {}
    for k, v in pairs(_G) do
        if type(k) == "string" and (k:find("Trainer") or k:find("Beast") or k:find("PetTrain") or k:find("Craft")) then
            if type(v) == "function" or (type(v) == "table" and k:sub(1, 2) == "C_") then found[#found + 1] = k end
        end
    end
    table.sort(found)
    P("Related API:", #found > 0 and table.concat(found, ", ", 1, math.min(#found, 30)) or "none")
    if GetNumTrainerServices then
        local ok, n = pcall(GetNumTrainerServices)
        P("Trainer services:", tostring(ok and n), " npc:", tostring(UnitExists and UnitExists("npc")))
        if ok and (n or 0) > 0 then
            local ok2, a, b, c = pcall(GetTrainerServiceInfo, 1)
            P("  first:", tostring(a), tostring(b), tostring(c))
        end
    end
    P("Last 'You have learned' message:", BT.lastLearn or "none seen this session")
    local store = BT.Store()
    local n = 0
    if store and store.names then for _ in pairs(store.names) do n = n + 1 end end
    P("Saved for this character:", store and (n .. " abilities") or "nothing yet")
    local yes, total = 0, 0
    for _, entry in pairs(ns.PET_ABILITIES or {}) do
        for _, r in ipairs(entry.ranks or {}) do
            total = total + 1
            if BT.PlayerKnows(r.spellId) then yes = yes + 1 end
        end
    end
    P(("Spellbook check (C_SpellBook.IsSpellKnown=%s): hunter knows %d of %d pet-ability ranks")
        :format((C_SpellBook and C_SpellBook.IsSpellKnown) and "yes" or "no", yes, total))
end

-- The hunter's own (player) spellbook - not the pet's.
-- Does the hunter permanently know this pet-ability rank (i.e. it's in their
-- Beast Training)? Spell IDs are WoW: Forever's own pet-ability IDs from
-- wowhead.com/forever (Data\PetAbilitiesData.lua). C_SpellBook.IsSpellKnown is
-- the modern-client check; the older globals are fallbacks. Only the player's
-- (hunter's) spellbook is asked - never the pet's - so a pet that knows an
-- ability doesn't make it count as trainable.
function BT.PlayerKnows(spellId)
    if not spellId then return false end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, spellId)
        if ok and known then return true end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellId)
        if ok and known then return true end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellId) -- no isPet flag: the hunter's own spells
        if ok and known then return true end
    end
    return false
end

-- Can the hunter teach this rank from Beast Training? `data` is a Learned
-- list entry: { spellId, rank, displayName, key }. Green when the spellbook
-- says the hunter knows it, or when it was seen in the Beast Training window.
function BT.CanTrain(data)
    if BT.PlayerKnows(data.spellId) then return true end
    local store = BT.Store()
    if store then
        if store.spells and store.spells[data.spellId] then return true end
        if store.names then
            local rank = data.rank or 1
            local spellName = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(data.spellId))
                or (GetSpellInfo and GetSpellInfo(data.spellId))
            for _, nm in pairs({ Lower(data.displayName), Lower(spellName), Lower(data.key),
                Norm(data.displayName), Norm(spellName), Norm(data.key) }) do
                if store.names[nm .. "#" .. rank] then return true end
            end
        end
    end
    return false
end

-- True when the client has a spellbook check to answer CanTrain directly
-- (so there's no need to ask the player to open Beast Training first).
function BT.HasSpellCheck()
    return (C_SpellBook and C_SpellBook.IsSpellKnown or IsPlayerSpell or IsSpellKnown) and true or false
end

-- Inline paw for a Learned line ("|T...|t"), green = trainable.
function BT.Paw(data, size)
    size = size or 14
    return ("|T%s:%d:%d|t"):format(BT.CanTrain(data) and BT.PAW_GREEN or BT.PAW_RED, size, size)
end

do
    local f = CreateFrame("Frame")
    for _, e in ipairs({ "TRAINER_SHOW", "TRAINER_UPDATE", "CRAFT_SHOW", "CRAFT_UPDATE", "TRADE_SKILL_SHOW", "TRADE_SKILL_UPDATE",
        "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED", "SPELLS_CHANGED" }) do
        pcall(f.RegisterEvent, f, e) -- not every event exists on every client
    end
    pcall(f.RegisterEvent, f, "LEARNED_SPELL_IN_TAB")
    pcall(f.RegisterEvent, f, "CHAT_MSG_SYSTEM")
    f:SetScript("OnEvent", function(_, event, msg, ...)
        if event == "CHAT_MSG_SYSTEM" then
            BT.OnSystemMessage(msg, ...)
            return
        end
        if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
            -- a newly learned ability: redraw the paws if a list is open
            BT.RefreshLists()
            return
        end
        BT.Scan()
        -- the list can fill in a moment after the window opens: look again shortly
        if C_Timer and C_Timer.After then C_Timer.After(0.3, BT.Scan) end
    end)
end
