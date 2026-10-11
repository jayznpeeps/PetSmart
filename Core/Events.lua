--------------------------------------------------------------------------
-- PetSmart: Core/Events.lua
-- Game events (login, pet changes, combat, logout) and the /petsmart slash command.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local ApplyIconSize = ns.ApplyIconSize
local EnsureProfiles = ns.EnsureProfiles
local GetCharKey = ns.GetCharKey
local GetFeedSpellIcon = ns.GetFeedSpellIcon
local LAYOUT = ns.LAYOUT
local LauncherOnClick = ns.LauncherOnClick
local RefreshActiveProfile = ns.RefreshActiveProfile
local RefreshPanel = ns.RefreshPanel
local RestoreTrackedRareFromProfile = ns.RestoreTrackedRareFromProfile
local Tame = ns.Tame
local Trace = ns.Trace
local UpdateAbilitiesPanelLockState = ns.UpdateAbilitiesPanelLockState
local UpdateHappiness = ns.UpdateHappiness
local abilitiesPanel = ns.abilitiesPanel
local defaults = ns.defaults
local panel = ns.panel
local toggle = ns.toggle
local XP = ns.XP

-- Hunter-only: the icon shows as soon as the character logs in, regardless
-- of level or whether a pet is currently active/known - UpdateHappiness()
-- already greys the icon out and hides the happiness border when there's
-- no pet summoned, so there's nothing level or pet-state gates need to
-- protect against showing early.
local function IsEligible()
    local _, class = UnitClass("player")
    return class == "HUNTER"
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_LOGOUT")

-- Whether the Compendium panel was actually open right as combat started,
-- so leaving combat only reopens it if it was showing beforehand - not
-- every time combat ends regardless of what the player had open.
local abilitiesPanelShownBeforeCombat = false

local activated = false
local function ActivateAddon(self)
    if activated then return end
    activated = true

    if PetSmartDB.pos then
        toggle:ClearAllPoints()
        toggle:SetPoint(PetSmartDB.pos[1], UIParent, PetSmartDB.pos[2], PetSmartDB.pos[3], PetSmartDB.pos[4])
    end
    toggle.icon:SetTexture(GetFeedSpellIcon())
    toggle:Show()
    UpdateHappiness()
    ns.RegisterDataBrokerObject()
    ns.UpdateMinimapIconPosition()
    ns.UpdateMinimapIconShown()

    -- Reproduce whatever this character's Compendium panel state was when
    -- they last logged out. Position/size were already restored earlier in
    -- PLAYER_LOGIN, so showing it here opens it exactly where it was left.
    if PetSmartDB.panelShownByChar and PetSmartDB.panelShownByChar[GetCharKey()] then
        abilitiesPanel:Show()
    end

    self:RegisterEvent("BAG_UPDATE_DELAYED")
    self:RegisterEvent("UNIT_PET")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    self:RegisterEvent("UNIT_HAPPINESS")
    self:RegisterEvent("PET_UI_UPDATE")
    self:RegisterEvent("PET_BAR_UPDATE")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")

    -- GetPetHappiness has no reliable change event on every client
    -- version, so poll it lightly as a safety net.
    local elapsedSince = 0
    self.pollFrame = self.pollFrame or CreateFrame("Frame")
    self.pollFrame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSince = elapsedSince + elapsed
        if elapsedSince >= 2 then
            elapsedSince = 0
            UpdateHappiness()
        end
    end)
end

ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGOUT" then
        -- Remember whether the Compendium panel was actually on screen for
        -- THIS character, independent of profile (a shared profile
        -- shouldn't force the panel open/closed for every character using
        -- it), so logging back in reproduces exactly what was left showing.
        if PetSmartDB then
            PetSmartDB.panelShownByChar = PetSmartDB.panelShownByChar or {}
            PetSmartDB.panelShownByChar[GetCharKey()] = abilitiesPanel:IsShown()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        PetSmartDB = PetSmartDB or {}
        for k, v in pairs(defaults) do
            if PetSmartDB[k] == nil then
                PetSmartDB[k] = (type(v) == "table") and {} or v
            end
        end
        EnsureProfiles()
        RefreshActiveProfile()
        ApplyIconSize()
        UpdateAbilitiesPanelLockState()
        XP.Apply()

        -- Restore the Compendium panel's own remembered position/size (it's
        -- a free-floating, resizable window now) before it's ever shown,
        -- so it reopens exactly where/how it was left last time rather than
        -- back at its default spot next to the icon.
        if ns.profile.compendiumSize then
            abilitiesPanel:SetSize(math.max(ns.profile.compendiumSize[1], LAYOUT.ABILITIES_PANEL_MIN_WIDTH),
                math.max(ns.profile.compendiumSize[2], LAYOUT.ABILITIES_PANEL_MIN_HEIGHT))
        end
        if ns.profile.abilitiesPanelPos then
            abilitiesPanel:ClearAllPoints()
            abilitiesPanel:SetPoint(ns.profile.abilitiesPanelPos[1], UIParent,
                ns.profile.abilitiesPanelPos[2], ns.profile.abilitiesPanelPos[3], ns.profile.abilitiesPanelPos[4])
        end

        -- Resolve each rare's real map id now that the world is loading
        -- (C_Map data wasn't populated yet back when RareSpawnData.lua
        -- itself ran at addon-load time - that's why the very first
        -- attempt at this left everything on the old, wrong, hardcoded
        -- ids). Then report how it went - the hardcoded Classic-era ids
        -- turned out not to match this client at all, so this is the
        -- thing to check if a zone still won't show a pin.
        if ns.ResolveRareMapIDs then
            ns.ResolveRareMapIDs()
        end
        if ns.RareZoneResolveLog then
            Trace(("Scanned %d map ids on this client"):format(ns.RareZoneResolveLog.scanned or 0))
            local unresolvedCount = 0
            for zoneName in pairs(ns.RareZoneResolveLog.unresolved) do
                unresolvedCount = unresolvedCount + 1
                Trace("Zone '" .. zoneName .. "' could not be resolved to any map id (dynamic or fallback) - its rares can't be tracked on the map.")
            end
            local dynamicCount, fallbackCount = 0, 0
            for _ in pairs(ns.RareZoneResolveLog.dynamic) do dynamicCount = dynamicCount + 1 end
            for _ in pairs(ns.RareZoneResolveLog.fallback) do fallbackCount = fallbackCount + 1 end
            Trace(("Zone map ids: %d resolved dynamically, %d fell back to the hardcoded table, %d unresolved"):format(
                dynamicCount, fallbackCount, unresolvedCount))
        end

        -- Restore whichever rare (and tame teacher) THIS profile was
        -- tracking last session (if any) by name-matching back into the
        -- static rare-spawn data. Profile-scoped, so another character on
        -- a different profile never sees it.
        RestoreTrackedRareFromProfile()
        Tame.Restore()

        local _, class = UnitClass("player")
        if class ~= "HUNTER" then
            -- Not a hunter: this character will never be eligible, nothing
            -- more to do.
            return
        end

        -- A hunter is eligible immediately at login now (no level or
        -- known-spell requirement), but keep watching PLAYER_LEVEL_UP and
        -- SPELLS_CHANGED as a harmless safety net in case ActivateAddon
        -- ever gets skipped here for some other reason.
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("SPELLS_CHANGED")

        if IsEligible() then
            ActivateAddon(self)
        end

    elseif not activated then
        -- Not yet activated: only re-check eligibility, ignore everything else.
        if event == "PLAYER_LEVEL_UP" or event == "SPELLS_CHANGED" then
            if IsEligible() then ActivateAddon(self) end
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        panel:Hide()
        abilitiesPanelShownBeforeCombat = abilitiesPanel:IsShown()
        if abilitiesPanelShownBeforeCombat then abilitiesPanel:Hide() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if abilitiesPanelShownBeforeCombat then
            abilitiesPanel:Show()
        end
        abilitiesPanelShownBeforeCombat = false
        -- Preserves the food panel's own pre-existing behavior (queued
        -- refreshes made in RefreshPanel() while InCombatLockdown() was
        -- true get applied the moment combat ends) now that this event has
        -- its own branch instead of falling into the catch-all below.
        if panel:IsShown() or ns.pendingRefresh then RefreshPanel() end
    elseif event == "SPELLS_CHANGED" then
        toggle.icon:SetTexture(GetFeedSpellIcon())
    elseif event == "UNIT_HAPPINESS" or event == "PET_UI_UPDATE" or event == "PET_BAR_UPDATE" then
        UpdateHappiness()
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- Only the Rare Pet Spawns panel's "Current Zone" section depends
        -- on where the player actually is, so only bother refreshing the
        -- Compendium when that's the page actually on screen.
        if abilitiesPanel:IsShown() and ns.abilitiesMode == "spawns" then
            ns.RefreshAbilitiesPanel()
        end
    elseif event == "UNIT_PET" and arg1 ~= "player" then
        return
    else
        if event == "UNIT_PET" then UpdateHappiness() end
        if panel:IsShown() or ns.pendingRefresh then RefreshPanel() end
    end
end)

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
SLASH_PETSMART1, SLASH_PETSMART2 = "/petsmart", "/ps"
SlashCmdList["PETSMART"] = function(msg)
    local cmd = ((msg or ""):match("^%s*(%S+)") or ""):lower()
    if cmd == "options" then
        -- Same as the launcher's right-click: straight to the Options page.
        LauncherOnClick("RightButton")
    else
        -- Same as the launcher's left-click: show/hide the Compendium.
        LauncherOnClick("LeftButton")
    end
end
