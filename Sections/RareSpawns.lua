--------------------------------------------------------------------------
-- PetSmart: Sections/RareSpawns.lua
-- Section: Rare Pet Spawns and each rare's detail page.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local IsTrackedRare = ns.IsTrackedRare
local LAYOUT = ns.LAYOUT
local SetAbilitiesMode = ns.SetAbilitiesMode
local SetTrackedRare = ns.SetTrackedRare
local TrackAllInZone = ns.TrackAllInZone
local TrackedRaresFromOtherZone = ns.TrackedRaresFromOtherZone
local UntrackAllRares = ns.UntrackAllRares
local abilitiesPanel = ns.abilitiesPanel
local rareTrackBtn = ns.rareTrackBtn

StaticPopupDialogs["PETSMART_TRACK_ALL_ZONE"] = {
    text = "Tracking All in this zone will untrack the previous zone.",
    button1 = "Continue",
    button2 = "Cancel",
    OnAccept = function(self, data)
        TrackAllInZone(data.zoneRares)
        ns.RefreshAbilitiesPanel()
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}


ns.Pages.spawns = function(ctx)
    abilitiesPanel.title:SetText("Rare Pet Spawns")
    if #ns.trackedRares == 1 then
        local only = ns.trackedRares[1]
        rareTrackBtn:SetState(true, nil, function()
            SetTrackedRare(only)
            ns.RefreshAbilitiesPanel()
        end)
    elseif #ns.trackedRares > 1 then
        rareTrackBtn:SetState(true, "Untrack All", function()
            UntrackAllRares()
            ns.RefreshAbilitiesPanel()
        end)
    end
    if not ns.RARE_SPAWNS or #ns.RARE_SPAWNS == 0 then
        ctx.AddLine("No rare spawn data loaded.", 0.7, 0.7, 0.7)
    else
        -- "Current Zone" section: whichever rares share the player's
        -- real zone (GetRealZoneText - the zone itself, not a
        -- subzone), surfaced at the top so "what's here right now" is
        -- a glance instead of a scroll through the full by-family
        -- list below. Same click behavior as every other rare line.
        local currentZone = GetRealZoneText()
        local inZone = {}
        if currentZone and currentZone ~= "" then
            for _, rare in ipairs(ns.RARE_SPAWNS) do
                if rare.zone == currentZone then
                    inZone[#inZone + 1] = rare
                end
            end
            table.sort(inZone, function(a, b) return a.name < b.name end)
        end
        ctx.AddLine("Current Zone" .. ((currentZone and currentZone ~= "") and (": " .. currentZone) or ""), 1, 0.82, 0)
        if #inZone == 0 then
            ctx.AddLine("No known rares in this zone.", 0.7, 0.7, 0.7)
        else
            -- Multi-tracking only (tracking several rares at once
            -- doesn't mean anything with it off), and only when
            -- there's actually something here to track.
            if ns.profile and ns.profile.multiTrackingEnabled then
                ctx.AddLine("Track All", 0.6, 0.8, 1, function()
                    if TrackedRaresFromOtherZone(currentZone) then
                        StaticPopup_Show("PETSMART_TRACK_ALL_ZONE", nil, nil, { zoneRares = inZone })
                    else
                        TrackAllInZone(inZone)
                        ns.RefreshAbilitiesPanel()
                    end
                end)
            end
            for _, rare in ipairs(inZone) do
                local label = rare.name .. "  (Lvl " .. tostring(rare.level) .. ")"
                if IsTrackedRare(rare) then label = label .. "  " .. LAYOUT.TRACKED_INLINE end
                ctx.AddLine(label, 1, 1, 1, function() SetAbilitiesMode("raredetail", rare) end)
            end
        end
        ctx.AddLine(" ", 1, 1, 1)

        local sorted = {}
        for _, rare in ipairs(ns.RARE_SPAWNS) do sorted[#sorted + 1] = rare end
        table.sort(sorted, function(a, b)
            local fa = (a.familyId and ns.PET_FAMILIES and ns.PET_FAMILIES[a.familyId]) or "?"
            local fb = (b.familyId and ns.PET_FAMILIES and ns.PET_FAMILIES[b.familyId]) or "?"
            if fa ~= fb then return fa < fb end
            return a.name < b.name
        end)
        local lastFamily = nil
        for _, rare in ipairs(sorted) do
            local familyName = (rare.familyId and ns.PET_FAMILIES and ns.PET_FAMILIES[rare.familyId]) or "Unknown Family"
            if familyName ~= lastFamily then
                ctx.AddLine(familyName, 1, 0.82, 0)
                lastFamily = familyName
            end
            local label = rare.name .. "  (Lvl " .. tostring(rare.level) .. ")"
            if IsTrackedRare(rare) then label = label .. "  " .. LAYOUT.TRACKED_INLINE end
            ctx.AddLine(label, 1, 1, 1, function() SetAbilitiesMode("raredetail", rare) end)
        end
    end
end

ns.Pages.raredetail = function(ctx)
    local rare = ns.selectedRare
    -- Keep the main header on "Rare Pet Spawns" and put the rare's
    -- own name in the subheader instead of replacing it, same as the
    -- Abilities Index/Pet Types detail pages above.
    abilitiesPanel.title:SetText("Rare Pet Spawns")
    abilitiesPanel.subtitle:SetText(rare and rare.name or "Rare Pet")
    abilitiesPanel.subtitle:Show()
    do
        local tracked = (rare and IsTrackedRare(rare)) or false
        rareTrackBtn:SetState(tracked,
            nil,
            function()
                if rare then
                    SetTrackedRare(rare)
                    ns.RefreshAbilitiesPanel()
                end
            end)
    end
    if not rare then
        ctx.AddLine("No rare selected.", 0.8, 0.8, 0.8)
    else
        local familyName = (rare.familyId and ns.PET_FAMILIES and ns.PET_FAMILIES[rare.familyId]) or "Unknown"
        ctx.AddLine("Family: " .. familyName, 0.8, 0.8, 0.8)
        ctx.AddLine("Level: " .. tostring(rare.level), 0.8, 0.8, 0.8)
        local pointCount = rare.points and #rare.points or 0
        local zoneLine = "Zone: " .. tostring(rare.zone)
        if pointCount > 1 then
            zoneLine = zoneLine .. "  (" .. pointCount .. " known locations)"
        end
        ctx.AddLine(zoneLine, 0.8, 0.8, 0.8)
        ctx.AddLine(" ", 1, 1, 1)
        ctx.AddLine(rare.description or "No description available.", 0.9, 1, 0.9)
        if not rare.mapID then
            ctx.AddLine(" ", 1, 1, 1)
            ctx.AddLine("(Map tracking unavailable for this zone.)", 0.6, 0.6, 0.6)
        end
    end
end
