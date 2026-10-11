--------------------------------------------------------------------------
-- PetSmart: Sections/Options.lua
-- Section: Options and Manage Profiles (profile switching/creating/deleting).
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local ABILITIES_PANEL_HEIGHT = ns.ABILITIES_PANEL_HEIGHT
local ABILITIES_PANEL_WIDTH = ns.ABILITIES_PANEL_WIDTH
local ApplyIconSize = ns.ApplyIconSize
local DEFAULT_PROFILE_NAME = ns.DEFAULT_PROFILE_NAME
local GetCharKey = ns.GetCharKey
local PROFILE_DEFAULTS = ns.PROFILE_DEFAULTS
local Print = ns.Print
local ROW_PADDING = ns.ROW_PADDING
local RefreshActiveProfile = ns.RefreshActiveProfile
local RestoreTrackedRareFromProfile = ns.RestoreTrackedRareFromProfile
local SaveTrackedRaresToProfile = ns.SaveTrackedRaresToProfile
local SetAbilitiesMode = ns.SetAbilitiesMode
local Tame = ns.Tame
local UpdateAbilitiesPanelLockState = ns.UpdateAbilitiesPanelLockState
local abilitiesPanel = ns.abilitiesPanel
local iconSizeSlider = ns.iconSizeSlider
local scrollChild = ns.scrollChild
local toggle = ns.toggle
local XP = ns.XP

----------------------------------------------------------------------
-- Profile manager: switching, creating (blank or copied), and deleting.
----------------------------------------------------------------------

-- Re-points `profile` at the named profile for THIS character and applies
-- everything it controls immediately: icon size, panel lock state, the
-- panel's own saved position/size (or the built-in default, if this
-- profile has never set one), and the rare-tracking map/minimap pins.
local function SwitchToProfile(name)
    PetSmartDB.profileKeys[GetCharKey()] = name
    RefreshActiveProfile()
    ApplyIconSize()
    UpdateAbilitiesPanelLockState()
    XP.Apply()

    abilitiesPanel:ClearAllPoints()
    if ns.profile.abilitiesPanelPos then
        abilitiesPanel:SetPoint(ns.profile.abilitiesPanelPos[1], UIParent,
            ns.profile.abilitiesPanelPos[2], ns.profile.abilitiesPanelPos[3], ns.profile.abilitiesPanelPos[4])
    else
        abilitiesPanel:SetPoint("BOTTOMLEFT", toggle, "TOPLEFT", 0, 4)
    end
    abilitiesPanel:SetSize(
        ns.profile.compendiumSize and ns.profile.compendiumSize[1] or ABILITIES_PANEL_WIDTH,
        ns.profile.compendiumSize and ns.profile.compendiumSize[2] or ABILITIES_PANEL_HEIGHT)

    -- Tracking is profile-scoped: swap `trackedRares` (and the tracked
    -- tame teacher, if any) to match whatever THIS profile has tracked,
    -- rather than leaving whatever the previous profile was tracking
    -- still showing.
    RestoreTrackedRareFromProfile()
    Tame.Restore()
    ns.RefreshAbilitiesPanel()

    -- Minimap icon visibility is also per-profile; refresh it (and its
    -- on-screen position) to match whatever profile we just switched to.
    if ns.UpdateMinimapIconShown then ns.UpdateMinimapIconShown() end
    if ns.UpdateMinimapIconPosition then ns.UpdateMinimapIconPosition() end
end

-- Deep-copies a profile's settings table (abilitiesPanelPos/Size are the
-- only nested values - plain {point, relPoint, x, y} / {w, h} arrays).
local function CopyProfileTable(source)
    local copy = {}
    for k, v in pairs(source) do
        if type(v) == "table" then
            local inner = {}
            for i, vv in ipairs(v) do inner[i] = vv end
            copy[k] = inner
        else
            copy[k] = v
        end
    end
    return copy
end

-- Creates a new profile (blank/default, or copied from `copyFrom` if
-- given and it exists) and immediately switches this character to it.
-- Returns true, or false plus a reason a popup can show.
local function CreateProfile(name, copyFrom)
    name = name and name:match("^%s*(.-)%s*$") -- trim
    if not name or name == "" then
        return false, "Profile name can't be empty."
    end
    if PetSmartDB.profiles[name] then
        return false, "A profile named '" .. name .. "' already exists."
    end
    if copyFrom and PetSmartDB.profiles[copyFrom] then
        PetSmartDB.profiles[name] = CopyProfileTable(PetSmartDB.profiles[copyFrom])
    else
        PetSmartDB.profiles[name] = CopyProfileTable(PROFILE_DEFAULTS)
    end
    SwitchToProfile(name)
    return true
end

-- Deletes a profile other than "Default", reassigning any character
-- (this one included) that was using it back to "Default".
local function DeleteProfile(name)
    if name == DEFAULT_PROFILE_NAME or not PetSmartDB.profiles[name] then return false end
    local wasActive = (PetSmartDB.profileKeys[GetCharKey()] == name)
    PetSmartDB.profiles[name] = nil
    for charKey, assigned in pairs(PetSmartDB.profileKeys) do
        if assigned == name then
            PetSmartDB.profileKeys[charKey] = DEFAULT_PROFILE_NAME
        end
    end
    if wasActive then
        SwitchToProfile(DEFAULT_PROFILE_NAME)
    else
        ns.RefreshAbilitiesPanel()
    end
    return true
end

--- Resets a profile's settings (tooltip toggles, icon size, pin visibility,
--- panel lock/position/size) back to PROFILE_DEFAULTS, without deleting the
--- profile itself or reassigning any character away from it.
local function ResetProfile(name)
    if not (name and PetSmartDB.profiles[name]) then return false end
    PetSmartDB.profiles[name] = CopyProfileTable(PROFILE_DEFAULTS)
    if PetSmartDB.profileKeys[GetCharKey()] == name then
        SwitchToProfile(name)
    else
        ns.RefreshAbilitiesPanel()
    end
    return true
end

StaticPopupDialogs["PETSMART_NEW_PROFILE"] = {
    text = "Enter a name for the new profile:",
    hasEditBox = true,
    maxLetters = 32,
    button1 = "Create",
    button2 = "Cancel",
    OnShow = function(self)
        -- Newer clients expose these as self.EditBox / self.Text instead of
        -- the classic self.editBox / self.text - support either.
        local textFS = self.Text or self.text
        local editBox = self.EditBox or self.editBox
        local copyFrom = self.data and self.data.copyFrom
        if textFS then
            textFS:SetText(copyFrom
                and ("Copy '" .. copyFrom .. "' as a new profile named:")
                or "Enter a name for the new profile:")
        end
        if editBox then
            editBox:SetText("")
            editBox:SetFocus()
        end
    end,
    OnAccept = function(self)
        local editBox = self.EditBox or self.editBox
        local ok, err = CreateProfile(editBox and editBox:GetText(), self.data and self.data.copyFrom)
        if not ok then Print(err) end
    end,
    EditBoxOnEnterPressed = function(self)
        -- Newer clients route the edit box's owning dialog through
        -- self.owningDialog rather than self:GetParent().
        local dialog = self.owningDialog or self:GetParent()
        if dialog and dialog.button1 then dialog.button1:Click() end
    end,
    EditBoxOnEscapePressed = function(self)
        local dialog = self.owningDialog or self:GetParent()
        if dialog then dialog:Hide() end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["PETSMART_DELETE_PROFILE"] = {
    text = "Delete profile '%s'? This can't be undone.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(self, data) DeleteProfile(data) end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

StaticPopupDialogs["PETSMART_RESET_PROFILE"] = {
    text = "Reset profile '%s' to its default settings? This can't be undone.",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function(self, data) ResetProfile(data) end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
ns.Pages.options = function(ctx)
    abilitiesPanel.title:SetText("Options")

    local function AddToggle(label, dbKey, onToggle)
        local on = (ns.profile[dbKey] ~= false)
        local r, g, b = on and 0.2 or 0.6, on and 1 or 0.6, on and 0.2 or 0.6
        ctx.AddLine(label .. ": " .. (on and "ON" or "OFF"), r, g, b, function()
            ns.profile[dbKey] = not on
            if onToggle then onToggle(not on) end
            ns.RefreshAbilitiesPanel()
        end)
    end

    ctx.AddLine("Profile: " .. PetSmartDB.profileKeys[GetCharKey()] .. "  (manage...)", 0.6, 0.8, 1, function()
        SetAbilitiesMode("profiles")
    end)

    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("Tooltip", 1, 0.82, 0)
    AddToggle("Show Pet Name", "tooltipShowName")
    AddToggle("Show Pet Loyalty", "tooltipShowLoyalty")
    AddToggle("Show Pet Happiness", "tooltipShowHappiness")

    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("Icon", 1, 0.82, 0)
    do
        -- The slider is a persistent widget, not a pooled text row, so
        -- it's positioned by hand at the current scroll position (same
        -- spot AddLine would place its next row) and advances yCursor
        -- itself to push everything after it further down.
        local sliderHeight = 44 -- label above + track + min/max labels below
        iconSizeSlider:ClearAllPoints()
        iconSizeSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 6, -(ctx.y + 14))
        iconSizeSlider:SetWidth(math.max(120, ctx.rowWidth - 70))
        iconSizeSlider:SetValue(ns.profile.iconSize or 40)
        iconSizeSlider.label:SetText(("Icon Size: %dpx"):format(ns.profile.iconSize or 40))
        iconSizeSlider:Show()
        ctx.y = ctx.y + sliderHeight + ROW_PADDING
    end

    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("Pet Experience Bar", 1, 0.82, 0)
    AddToggle("Show Experience Bar", "xpBarEnabled", function() XP.Update() end)
    AddToggle("Show Bar Text", "xpBarShowText", function() XP.Update() end)
    AddToggle("Lock Bar (Move/Resize)", "xpBarLocked", function() XP.Update() end)
    do
        local sliderHeight = 44
        for _, sl in ipairs({ XP.widthSlider, XP.heightSlider }) do
            local val = ns.profile[sl.key] or (sl.key == "xpBarWidth" and XP.DEFAULT_W or XP.DEFAULT_H)
            sl:ClearAllPoints()
            sl:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 6, -(ctx.y + 14))
            sl:SetWidth(math.max(120, ctx.rowWidth - 70))
            sl:SetValue(val)
            sl.label:SetText(sl.labelFmt:format(val))
            sl:Show()
            ctx.y = ctx.y + sliderHeight + ROW_PADDING
        end
    end
    ctx.AddLine("The bar can also be moved by dragging it and resized by dragging its corner.", 0.7, 0.7, 0.7)

    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("Minimap", 1, 0.82, 0)
    AddToggle("Show Minimap Icon", "showMinimapIcon", function() ns.UpdateMinimapIconShown() end)

    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("Rare Spawn Tracking", 1, 0.82, 0)
    AddToggle("Show World Map Icon While Tracking", "showWorldMapRarePin", function() ns.UpdateRarePin() end)
    AddToggle("Show Minimap Icon While Tracking", "showMinimapRarePin", function() ns.UpdateRarePin() end)
    AddToggle("Multi-Tracking", "multiTrackingEnabled", function(enabled)
        -- Turning it off mid-session doesn't leave several rares
        -- tracked in a mode that no longer allows it - trim down to
        -- just the most recently tracked one, same rule SetTrackedRare
        -- enforces whenever it adds a new rare while this is off.
        if not enabled and #ns.trackedRares > 1 then
            ns.trackedRares = { ns.trackedRares[#ns.trackedRares] }
            SaveTrackedRaresToProfile()
            ns.UpdateRarePin()
        end
    end)
    ctx.AddLine("Multi-tracking can be immersion breaking.", 0.7, 0.7, 0.7)

    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("Compendium Panel", 1, 0.82, 0)
    AddToggle("Lock Panel (Move/Resize)", "abilitiesPanelLocked", function() UpdateAbilitiesPanelLockState() end)

    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("PetSmart v1.61.0", 0.6, 0.6, 0.6)
    ctx.AddLine("Author: Yellmourn", 0.6, 0.6, 0.6)
    ctx.AddLine("Credit: wowhead.com, wow-petopia.com", 0.6, 0.6, 0.6)
    ctx.AddLine("Special thanks to Nosferatu.", 0.6, 0.6, 0.6)
    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("Dedicated to my first WoW pets, Muddles and Puddles, and to Full Murloc of Zul'jin.", 1, 0.82, 0)
end

ns.Pages.profiles = function(ctx)
    abilitiesPanel.title:SetText("Options")
    abilitiesPanel.subtitle:SetText("Manage Profiles")
    abilitiesPanel.subtitle:Show()

    local charKey = GetCharKey()
    local activeName = PetSmartDB.profileKeys[charKey]
    ctx.AddLine("This character is using:", 0.8, 0.8, 0.8)
    ctx.AddLine(activeName, 1, 0.82, 0)
    ctx.AddLine("    Reset this profile to defaults", 1, 0.6, 0.2, function()
        StaticPopup_Show("PETSMART_RESET_PROFILE", activeName, nil, activeName)
    end)
    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("Click a profile to switch this character to it.", 0.7, 0.7, 0.7)
    ctx.AddLine(" ", 1, 1, 1)

    local names = {}
    for name in pairs(PetSmartDB.profiles) do names[#names + 1] = name end
    table.sort(names, function(a, b)
        if a == DEFAULT_PROFILE_NAME then return true end
        if b == DEFAULT_PROFILE_NAME then return false end
        return a < b
    end)

    for _, name in ipairs(names) do
        local isActive = (name == activeName)
        if isActive then
            ctx.AddLine(name .. "  [Active]", 1, 0.82, 0)
        else
            ctx.AddLine(name, 1, 1, 1, function()
                SwitchToProfile(name)
            end)
        end
        ctx.AddLine("    Copy to a new profile...", 0.6, 0.8, 1, function()
            StaticPopup_Show("PETSMART_NEW_PROFILE", nil, nil, { copyFrom = name })
        end)
        if name ~= DEFAULT_PROFILE_NAME then
            ctx.AddLine("    Delete this profile", 1, 0.4, 0.4, function()
                StaticPopup_Show("PETSMART_DELETE_PROFILE", name, nil, name)
            end)
        end
    end

    ctx.AddLine(" ", 1, 1, 1)
    ctx.AddLine("+ Create New Profile", 0.2, 1, 0.2, function()
        StaticPopup_Show("PETSMART_NEW_PROFILE")
    end)
end
