--------------------------------------------------------------------------
-- PetSmart: Tracking/Tracking.lua
-- Track/untrack logic for rares and tame-teacher pets, saved per profile.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local LogOnce = ns.LogOnce
local Print = ns.Print
local Tame = ns.Tame
local Trace = ns.Trace
local rareTrackBtn = ns.rareTrackBtn

-- Persists the current `trackedRares` list onto the active profile - just
-- the rares' names, since ns.RARE_SPAWNS itself is static data loaded
-- fresh every time. Stored on the active profile (not top-level/account-
-- wide) so tracking stays with whichever character/profile set it -
-- another character using a different profile never sees it.
local function SaveTrackedRaresToProfile()
    if not ns.profile then return end
    if #ns.trackedRares == 0 then
        ns.profile.trackedRareNames = nil
        return
    end
    local names = {}
    for _, r in ipairs(ns.trackedRares) do names[#names + 1] = r.name end
    ns.profile.trackedRareNames = names
end

-- Toggles tracking for one rare. Clicking an already-tracked rare always
-- untracks just that one. Clicking a new rare either adds it alongside
-- whatever else is tracked (multi-tracking on) or replaces the single
-- previously-tracked rare (multi-tracking off) - see multiTrackingEnabled
-- in the Options panel.
local function SetTrackedRare(rare)
    if not rare then return end
    local trackedIndex
    for i, r in ipairs(ns.trackedRares) do
        if r == rare then trackedIndex = i; break end
    end
    local wasTracking = trackedIndex ~= nil
    -- Dungeon/raid rares have no world map on Forever at all, so their
    -- mapID is unusable (handing it to WorldMapFrame:SetMapID crashes
    -- Blizzard's own world-quest code). Refuse to track these outright
    -- rather than letting that happen - untracking is unaffected since
    -- a dungeon rare can never become tracked in the first place.
    if not wasTracking and rare.isDungeon then
        Print(rare.name .. " spawns inside a dungeon and cannot be tracked on the map.")
        return
    end

    if wasTracking then
        table.remove(ns.trackedRares, trackedIndex)
    elseif ns.profile and ns.profile.multiTrackingEnabled then
        table.insert(ns.trackedRares, rare)
    else
        ns.trackedRares = { rare }
    end

    Trace(("SetTrackedRare: %s '%s' (now tracking %d total)"):format(
        wasTracking and "untracked" or "tracking", rare.name, #ns.trackedRares))
    SaveTrackedRaresToProfile()
    ns.UpdateRarePin()

    -- Newly tracking (this is a "Track" click, not "Untrack"): jump the
    -- world map straight to that rare's own zone so the pin just placed
    -- is immediately visible, without the player hunting for the zone
    -- themselves. Untracking never touches the map.
    if not wasTracking and rare.mapID and WorldMapFrame then
        if not WorldMapFrame:IsShown() and ShowUIPanel then
            local ok, err = pcall(ShowUIPanel, WorldMapFrame)
            if not ok then LogOnce("showworldmap", "ShowUIPanel(WorldMapFrame)", err) end
        end
        local ok, err = pcall(WorldMapFrame.SetMapID, WorldMapFrame, rare.mapID)
        if not ok then
            LogOnce("openmap", "WorldMapFrame:SetMapID on track", err)
        else
            Trace(("SetTrackedRare: opened world map to mapID=%s"):format(tostring(rare.mapID)))
        end
    end
end

-- Clears every currently-tracked rare at once - the quick action on the
-- icon's middle-click, and the "Untrack All" button on the Rare Pet
-- Spawns list when more than one rare is tracked.
local function UntrackAllRares()
    if #ns.trackedRares == 0 then return end
    ns.trackedRares = {}
    SaveTrackedRaresToProfile()
    ns.UpdateRarePin()
end

-- True if any currently-tracked rare belongs to a zone other than
-- `zoneName`. Used by "Track All" (Current Zone section, multi-tracking
-- only) to decide whether swapping to the current zone's rares would
-- silently drop tracking on rares from somewhere else, which needs a
-- confirmation first rather than just happening.
local function TrackedRaresFromOtherZone(zoneName)
    for _, r in ipairs(ns.trackedRares) do
        if r.zone ~= zoneName then return true end
    end
    return false
end

-- Replaces whatever is currently tracked with ONLY the given list of
-- rares (the Current Zone section's "Track All") - dungeon rares are
-- skipped since they can never be tracked on the map at all (see
-- SetTrackedRare). Jumps the world map to the zone the same way a single
-- Track click does, using whichever of the newly-tracked rares has a
-- usable mapID first.
local function TrackAllInZone(zoneRares)
    local newTracked = {}
    for _, rare in ipairs(zoneRares) do
        if not rare.isDungeon then
            newTracked[#newTracked + 1] = rare
        end
    end
    ns.trackedRares = newTracked
    SaveTrackedRaresToProfile()
    ns.UpdateRarePin()

    for _, rare in ipairs(newTracked) do
        if rare.mapID and WorldMapFrame then
            if not WorldMapFrame:IsShown() and ShowUIPanel then
                local ok, err = pcall(ShowUIPanel, WorldMapFrame)
                if not ok then LogOnce("showworldmap", "ShowUIPanel(WorldMapFrame)", err) end
            end
            local ok, err = pcall(WorldMapFrame.SetMapID, WorldMapFrame, rare.mapID)
            if not ok then LogOnce("openmap", "WorldMapFrame:SetMapID on track all", err) end
            break
        end
    end
end

-- Resolves the active profile's `trackedRareNames` (if any) back into
-- live rare references by name-matching into the static rare-spawn data,
-- and refreshes the minimap/world map pins to match. Called at login and
-- any time the active profile changes (switch/create/delete/reset), so
-- each character only ever shows the rare(s) ITS profile has tracked.
local function RestoreTrackedRareFromProfile()
    ns.trackedRares = {}
    if ns.profile and ns.profile.trackedRareNames and ns.RARE_SPAWNS then
        local resolved = {}
        local anyDropped = false
        for _, name in ipairs(ns.profile.trackedRareNames) do
            for _, rare in ipairs(ns.RARE_SPAWNS) do
                if rare.name == name then
                    -- A dungeon rare should never be trackable (see
                    -- SetTrackedRare), but guard against restoring one
                    -- anyway from a save made before that rule existed.
                    if not rare.isDungeon then
                        resolved[#resolved + 1] = rare
                    else
                        anyDropped = true
                    end
                    break
                end
            end
        end
        -- If multi-tracking got disabled (in Options, or by a profile
        -- switch) since this was saved, only the most recently tracked
        -- one survives restoring - same rule SetTrackedRare enforces
        -- when adding a new rare while multi-tracking is off.
        if #resolved > 1 and not (ns.profile.multiTrackingEnabled) then
            resolved = { resolved[#resolved] }
            anyDropped = true
        end
        ns.trackedRares = resolved
        if anyDropped then
            SaveTrackedRaresToProfile()
        end
    end
    ns.UpdateRarePin()
end

-- Persists trackedTameTeacher onto the active profile, same idea as
-- SaveTrackedRaresToProfile (just the name - spawnInfo is re-resolved
-- from ns.RARE_SPAWNS on restore, same as everything else here).
function Tame.Save()
    if not ns.profile then return end
    ns.profile.trackedTameTeacherName = ns.trackedTameTeacher and ns.trackedTameTeacher.name or nil
end

-- Toggles tracking for one tameable "teacher" pet. Unlike SetTrackedRare,
-- there's no multi-tracking variant to consider at all - clicking a new
-- teacher always replaces whichever one was tracked before, and this is
-- deliberately not gated behind the Multi-Tracking option (see the pin
-- system's own header comment above for why).
function Tame.Set(name, spawnInfo)
    if not name then return end
    if Tame.IsTracking(name) then
        ns.trackedTameTeacher = nil
    elseif spawnInfo and spawnInfo.isDungeon then
        -- Same refusal SetTrackedRare applies to dungeon rares: no usable
        -- world map for a dungeon's mapID on Forever, so this never
        -- becomes tracked in the first place (untracking is unaffected).
        Print(name .. " spawns inside a dungeon and cannot be tracked on the map.")
        return
    elseif spawnInfo then
        ns.trackedTameTeacher = { name = name, spawnInfo = spawnInfo }
    else
        return -- no location on record: nothing to track
    end
    Tame.Save()
    ns.UpdateTamePin()

    if ns.trackedTameTeacher and spawnInfo.mapID and WorldMapFrame then
        if not WorldMapFrame:IsShown() and ShowUIPanel then
            local ok, err = pcall(ShowUIPanel, WorldMapFrame)
            if not ok then LogOnce("showworldmap", "ShowUIPanel(WorldMapFrame)", err) end
        end
        local ok, err = pcall(WorldMapFrame.SetMapID, WorldMapFrame, spawnInfo.mapID)
        if not ok then LogOnce("openmap", "WorldMapFrame:SetMapID on tame-teacher track", err) end
        -- Re-place pins/highlights now that the map is on the right zone,
        -- rather than relying only on the SetMapID hook (which doesn't
        -- fire if the map was already on that zone).
        ns.UpdateTamePin()
    end
end

-- Drops the tracked teacher (if any) without touching the map.
function Tame.Clear()
    if not ns.trackedTameTeacher then return end
    ns.trackedTameTeacher = nil
    Tame.Save()
    ns.UpdateTamePin()
end

-- Subheader "Untrack" button for the Abilities Index pages while a teacher
-- is tracked, mirroring the one on the Rare Pet Spawns list.
function Tame.ShowUntrackButton(refresh)
    if not ns.trackedTameTeacher then return end
    rareTrackBtn:SetState(true, nil, function()
        Tame.Clear()
        refresh()
    end)
end

-- Resolves the active profile's `trackedTameTeacherName` (if any) back
-- into a live spawnInfo reference, same pattern as
-- RestoreTrackedRareFromProfile. Called at the same points that function
-- is (login, profile switch/create/delete/reset).
function Tame.Restore()
    ns.trackedTameTeacher = nil
    if ns.profile and ns.profile.trackedTameTeacherName then
        local info = Tame.GetSpawnInfo(ns.profile.trackedTameTeacherName)
        if info then
            ns.trackedTameTeacher = { name = ns.profile.trackedTameTeacherName, spawnInfo = info }
        else
            -- No longer resolvable (e.g. the spawn data it depended on
            -- changed) - drop the stale save instead of leaving a tracked
            -- teacher with no way to ever show a pin again.
            Tame.Save()
        end
    end
    ns.UpdateTamePin()
end

-- Belt-and-suspenders: don't rely solely on Blizzard's own data-provider
-- refresh timing to redraw when the map is opened or the player
-- navigates to a different zone while it's already open - call our own
-- refresh on both, guarded so a missing API just skips quietly.
if WorldMapFrame then
    if WorldMapFrame.HookScript then
        WorldMapFrame:HookScript("OnShow", function()
            Trace("WorldMapFrame OnShow fired")
            ns.UpdateRarePin()
            ns.UpdateTamePin()
        end)
    end
    if WorldMapFrame.SetMapID then
        hooksecurefunc(WorldMapFrame, "SetMapID", function()
            Trace("WorldMapFrame:SetMapID fired")
            ns.UpdateRarePin()
            ns.UpdateTamePin()
        end)
    end
end

-- Exported for the other PetSmart files.
ns.RestoreTrackedRareFromProfile = RestoreTrackedRareFromProfile
ns.SaveTrackedRaresToProfile = SaveTrackedRaresToProfile
ns.SetTrackedRare = SetTrackedRare
ns.TrackAllInZone = TrackAllInZone
ns.TrackedRaresFromOtherZone = TrackedRaresFromOtherZone
ns.UntrackAllRares = UntrackAllRares
