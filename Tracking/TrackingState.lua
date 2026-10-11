--------------------------------------------------------------------------
-- PetSmart: Tracking/TrackingState.lua
-- What is being tracked (rares and the tame-teacher pet), plus the shared tracking lookups.
--------------------------------------------------------------------------
local addonName, ns = ...

            -- but UpdateHappiness() (defined before it) needs to reference it.
-- Ordered list of every rare currently being tracked - 0 or 1 entries
-- when multi-tracking is off, possibly more when it's on (see
-- multiTrackingEnabled in PROFILE_DEFAULTS). Declared (not just forward-
-- declared) here, early, since the icon's own tooltip just below needs
-- to check it to decide whether to show the middle-click-to-untrack
-- hint, well before SetTrackedRare() further down actually populates it.
ns.trackedRares = {}
local function IsTrackedRare(rare)
    for _, r in ipairs(ns.trackedRares) do
        if r == rare then return true end
    end
    return false
end

-- The single tameable-pet "teacher" tracked from an Abilities Index
-- detail page (e.g. clicking one of the tames listed under Claw Rank 4).
-- Entirely separate from trackedRares above - its own pin pool, own
-- texture, and (per design) only ever one at a time, with no
-- multi-tracking option of its own: see Tame.Set further
-- down. Holds { name, spawnInfo } where spawnInfo is the matching
-- ns.RARE_SPAWNS entry (mapID/points/zone) this teacher's name resolved
-- to, since that's the only source of real coordinates this addon has.
ns.trackedTameTeacher = nil
local Tame = {} -- tame-teacher tracking API, shared with the other files as ns.Tame
function Tame.IsTracking(name)
    return ns.trackedTameTeacher ~= nil and ns.trackedTameTeacher.name == name
end
-- "Name (Lv 5-6)" label for a tracked teacher pet's pins/tooltips. The level
-- comes from the Abilities Index tame lists (first entry with that name),
-- falling back to the spawn entry's own level (teachers that are also rares).
function Tame.GetLabel(name, spawnInfo)
    local levels
    if ns.PETOPIA_TAME_MOBS then
        for _, ranks in pairs(ns.PETOPIA_TAME_MOBS) do
            for _, mobs in pairs(ranks) do
                for _, m in ipairs(mobs) do
                    if m[1] == name and m[3] then levels = m[3]; break end
                end
                if levels then break end
            end
            if levels then break end
        end
    end
    levels = levels or (spawnInfo and spawnInfo.level)
    if levels and tostring(levels) ~= "" then
        return name .. " (Lv " .. tostring(levels) .. ")"
    end
    return name
end

-- How many things a middle-click would untrack (rares + the tracked
-- teacher), plus the lone name when that total is exactly one.
function Tame.UntrackTarget()
    local n = #ns.trackedRares + (ns.trackedTameTeacher and 1 or 0)
    if n == 1 then
        return 1, ns.trackedRares[1] and ns.trackedRares[1].name or ns.trackedTameTeacher.name
    end
    return n, nil
end

-- Resolves a tameable "teacher" pet's name into real map coordinates by
-- exact-name match, checked against two sources in turn: ns.RARE_SPAWNS
-- first (the ~40 teacher names that double as a listed rare, like Timber
-- or Bjarn), then ns.TAME_TEACHER_SPAWNS (Data/TameTeacherSpawnData.lua -
-- individually-named teacher pets that aren't rares but still have one
-- real, findable spot, researched separately from classic Wowhead's own
-- comment threads). Most of PetopiaTameData.lua's ~320 distinct teacher
-- names are ordinary leveled world mobs that spawn throughout a whole
-- zone with no one camp to pin - wowhead.com/forever has no indexed pages
-- for them (Forever is too new/niche) and wow-petopia.com's per-family
-- pages don't give exact coordinates either, so rather than invent a
-- point for those, a name not covered by either source here returns nil
-- and the tame-teacher detail page shows "no location on record" instead
-- of a Track button. A dungeon match (isDungeon) also returns nil for
-- tracking purposes even when a description exists, since it can never
-- be tracked - see SetTrackedRare - but BuildDetailLines/tamedetail still
-- show its zone/description text from whichever source matched.
function Tame.GetSpawnInfo(name)
    if not name then return nil end
    if ns.RARE_SPAWNS then
        for _, rare in ipairs(ns.RARE_SPAWNS) do
            if rare.name == name and not rare.isDungeon then
                return rare
            end
        end
    end
    if ns.TAME_TEACHER_SPAWNS then
        for _, spawn in ipairs(ns.TAME_TEACHER_SPAWNS) do
            if spawn.name == name then
                return spawn
            end
        end
    end
    -- Any creature the tame lists place ONLY inside a dungeon/raid (zone text
    -- ending in "(Dungeon)" / "(Raid)") gets a stand-in entry flagged
    -- isDungeon, so its page shows a Track button that explains it can't be
    -- tracked on the map instead of having no button at all.
    Tame.dungeonCache = Tame.dungeonCache or {}
    local cached = Tame.dungeonCache[name]
    if cached == nil then
        cached = false
        local instanceZone, onlyInstances = nil, true
        local found = false
        for _, ranks in pairs(ns.PETOPIA_TAME_MOBS or {}) do
            for _, mobs in pairs(ranks) do
                for _, m in ipairs(mobs) do
                    if m[1] == name then
                        found = true
                        local z = m[4] or ""
                        if z:find("%(Dungeon%)") or z:find("%(Raid%)") then
                            instanceZone = instanceZone or z:gsub("%s*%((%a+)%)%s*$", "")
                        else
                            onlyInstances = false
                        end
                    end
                end
            end
        end
        if found and onlyInstances and instanceZone then
            cached = {
                name = name,
                zone = instanceZone,
                isDungeon = true,
                description = "Found inside " .. instanceZone .. ", so it can't be tracked on the world map.",
            }
        end
        Tame.dungeonCache[name] = cached
    end
    return cached or nil
end

-- Exported for the other PetSmart files.
ns.IsTrackedRare = IsTrackedRare
ns.Tame = Tame
