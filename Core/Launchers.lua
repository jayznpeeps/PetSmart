--------------------------------------------------------------------------
-- PetSmart: Core/Launchers.lua
-- Icon/launcher behaviour: Feed Pet icon clicks, click-off, LibDataBroker, LibDBIcon minimap button.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local Print = ns.Print
local SetAbilitiesMode = ns.SetAbilitiesMode
local ShowToggleTooltip = ns.ShowToggleTooltip
local Tame = ns.Tame
local UntrackAllRares = ns.UntrackAllRares
local abilitiesPanel = ns.abilitiesPanel
-- Set true once RegisterDataBrokerObject actually creates the LDB object,
-- so it is never registered twice.
local brokerRegistered = false
local panel = ns.panel
local toggle = ns.toggle

----------------------------------------------------------------------
-- Toggle behaviour
----------------------------------------------------------------------
toggle:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        if abilitiesPanel:IsShown() then
            abilitiesPanel:Hide()
        else
            ns.HideFoodPanel()
            -- Free-floating now - leave it wherever it was last put. Only
            -- the very first time, with nothing saved yet, does it default
            -- to popping up next to the icon.
            if not ns.profile.abilitiesPanelPos then
                abilitiesPanel:ClearAllPoints()
                abilitiesPanel:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
            end
            abilitiesPanel:Show()
        end
        return
    end

    if button == "MiddleButton" then
        if Tame.UntrackTarget() > 0 then
            UntrackAllRares() -- clears whichever one (or several) are tracked
            Tame.Clear()
            if abilitiesPanel:IsShown() then ns.RefreshAbilitiesPanel() end
            -- The mouse is still over the icon (this is its own click
            -- handler), so the tooltip is still showing the stale
            -- "Middle-click: Untrack ..." line from before the untrack -
            -- redraw it now instead of waiting for OnLeave/OnEnter.
            if GameTooltip:IsOwned(self) then ShowToggleTooltip(self) end
        end
        return
    end

    if InCombatLockdown() then
        Print("Can't feed your pet while in combat.")
        return
    end
    if not UnitExists("pet") then
        Print("You have no active pet out.")
        return
    end
    if panel:IsShown() then
        ns.HideFoodPanel()
    elseif #ns.BuildFoodList() == 0 then
        -- Nothing in the bags this pet will eat: say so instead of opening an empty panel.
        local petName = UnitName("pet")
        if not petName or (issecretvalue and issecretvalue(petName)) then petName = "your pet" end
        local msg = ("You have no food that %s will eat."):format(petName)
        Print(msg)
        if UIErrorsFrame and UIErrorsFrame.AddMessage then UIErrorsFrame:AddMessage(msg, 1, 0.1, 0.1) end
    else
        abilitiesPanel:Hide()
        panel:ClearAllPoints()
        panel:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 4)
        panel:Show()
    end
end)

toggle:SetScript("OnDragStart", function(self)
    if not PetSmartDB.locked and IsShiftKeyDown() then self:StartMoving() end
end)
toggle:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    PetSmartDB.pos = { point, relPoint, x, y }
end)

----------------------------------------------------------------------
-- Click-off-to-close: clicking out in the game world closes whichever
-- panel is open, the same as right-clicking the icon while the abilities
-- panel is already open.
--
-- The first attempt at this used a full-screen, mouse-enabled frame
-- sitting beneath the panels to catch that click - but a frame like that
-- intercepts every click over the 3D world anywhere on screen (not just
-- clicks that would've reached the world), which is what was blocking
-- clicking on NPCs/interactables entirely while a panel was open.
--
-- Hooking WorldFrame's own OnMouseDown instead avoids that: WorldFrame
-- only ever receives a mouse event when a click actually lands on the
-- 3D world (clicking an NPC, a mob, the ground, etc.) rather than on
-- some other UI frame, and HookScript adds our handler alongside
-- WorldFrame's existing one instead of replacing it - so targeting/
-- interacting with whatever was clicked still happens exactly as normal,
-- and closing the panel is just an extra side effect of that same click.
----------------------------------------------------------------------
-- Only the food panel closes on an outside click - the Compendium panel
-- is now a free-floating, moveable/resizable window the player positions
-- themselves, so dismissing it on every click into the world would fight
-- that (e.g. clicking an NPC while reading the Rare Pet Spawns list would
-- close it). It still closes via right-clicking the icon again or Esc.
WorldFrame:HookScript("OnMouseDown", function(_, button)
    -- Right-click in the world is camera/mouselook, not a "click off the
    -- panel to dismiss it" gesture - only left-click (targeting/
    -- interacting) should close the panel.
    if button ~= "LeftButton" then return end
    ns.HideFoodPanel()
end)

----------------------------------------------------------------------
-- Shared launcher behavior: both the LibDataBroker object below and the
-- minimap icon further down are just different buttons for the same two
-- actions, so they share one click handler instead of duplicating it.
-- Left-click shows/hides the Compendium panel (opening it at its default
-- spot next to the on-screen icon the very first time, same as that
-- icon's own right-click); right-click jumps straight to Options,
-- showing the panel first if it was closed.
----------------------------------------------------------------------
local function ShowAbilitiesPanelAtDefault()
    if not ns.profile.abilitiesPanelPos then
        abilitiesPanel:ClearAllPoints()
        abilitiesPanel:SetPoint("BOTTOMLEFT", toggle, "TOPLEFT", 0, 4)
    end
    abilitiesPanel:Show() -- OnShow opens the last section used
end

local function LauncherOnTooltipShow(tooltip)
    tooltip:AddLine("|cff33ff99PetSmart|r")
    tooltip:AddLine("|cffffff00Left-click|r to show/hide the Compendium", 1, 1, 1)
    tooltip:AddLine("|cffffff00Right-click|r to open/close Options", 1, 1, 1)
    local untrackCount, untrackName = Tame.UntrackTarget()
    if untrackCount == 1 then
        tooltip:AddLine("|cffffff00Middle-click|r to untrack " .. untrackName, 1, 1, 1)
    elseif untrackCount > 1 then
        tooltip:AddLine(("|cffffff00Middle-click|r to untrack all (%d)"):format(untrackCount), 1, 1, 1)
    end
end

-- `callerFrame` is whichever actual button was clicked - the display
-- addon's own button for the broker object, or the minimap icon itself -
-- so a middle-click can tell whether that same frame currently owns an
-- open GameTooltip and refresh it in place, same as the on-screen icon's
-- own middle-click already does for itself.
local function LauncherOnClick(button, callerFrame)
    if button == "RightButton" then
        -- Toggles the same way left-click toggles the panel generally:
        -- a right-click while it's already open ON the Options page closes
        -- it again; otherwise (closed, or open on some other page) it
        -- opens/switches straight to Options, same as before.
        if abilitiesPanel:IsShown() and ns.abilitiesMode == "options" then
            abilitiesPanel:Hide()
        else
            if not abilitiesPanel:IsShown() then
                ShowAbilitiesPanelAtDefault()
            end
            SetAbilitiesMode("options")
        end
    elseif button == "MiddleButton" then
        -- Quick clear, mirroring the on-screen icon's own middle-click.
        if Tame.UntrackTarget() > 0 then
            UntrackAllRares()
            Tame.Clear()
            if abilitiesPanel:IsShown() then ns.RefreshAbilitiesPanel() end
            -- The mouse may still be hovering whichever button was just
            -- clicked, with its tooltip still showing the stale
            -- "Middle-click: ..." line from before the untrack - rebuild
            -- it now instead of waiting for OnLeave/OnEnter, same fix as
            -- the on-screen icon's own tooltip gets.
            if callerFrame and GameTooltip:IsOwned(callerFrame) then
                GameTooltip:ClearLines()
                LauncherOnTooltipShow(GameTooltip)
                GameTooltip:Show()
            end
        end
    else
        if abilitiesPanel:IsShown() then
            abilitiesPanel:Hide()
        else
            ShowAbilitiesPanelAtDefault()
        end
    end
end

----------------------------------------------------------------------
-- LibDataBroker-1.1 launcher + LibDBIcon-1.0 minimap button.
--
-- The broker object lets broker-display addons (Titan Panel, Bazooka,
-- ChocolateBar, ...) show PetSmart on their own bar. The minimap button
-- is that same object registered with LibDBIcon-1.0, the standard
-- minimap-button library, so minimap managers (Leatrix Plus's button bag,
-- MinimapButtonButton, SexyMap, square minimaps, ...) can find, move and
-- group it like any other addon's button. Its position around the
-- minimap is account-wide (PetSmartDB.minimapIcon); whether it's shown is
-- the per-profile "Show Minimap Icon" option.
-- Registered once, from ActivateAddon, so both only appear for eligible
-- Hunters.
----------------------------------------------------------------------
local BROKER_NAME = "PetSmart"
local dataObject

-- LibDBIcon's saved table ({ hide, minimapPos, ... }). Carries over the
-- angle the old hand-made minimap button was dragged to (same 0-360
-- degree convention, 225 = bottom-left by default).
local function MinimapIconDB()
    PetSmartDB.minimapIcon = PetSmartDB.minimapIcon or {}
    local db = PetSmartDB.minimapIcon
    if db.minimapPos == nil and PetSmartDB.minimapIconAngle then
        db.minimapPos = PetSmartDB.minimapIconAngle % 360
    end
    PetSmartDB.minimapIconAngle = nil
    return db
end

local function GetDBIcon()
    return LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
end

ns.RegisterDataBrokerObject = function()
    if brokerRegistered then return end
    local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
    if not LDB then return end

    dataObject = LDB:NewDataObject(BROKER_NAME, {
        type = "launcher",
        text = "PetSmart",
        icon = "Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\BrokerIcon",
        OnClick = function(self, button) LauncherOnClick(button, self) end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            LauncherOnTooltipShow(tooltip)
        end,
    })
    brokerRegistered = true

    local DBIcon = GetDBIcon()
    if DBIcon and dataObject and not DBIcon:IsRegistered(BROKER_NAME) then
        local db = MinimapIconDB()
        db.hide = not (ns.profile and ns.profile.showMinimapIcon ~= false)
        DBIcon:Register(BROKER_NAME, dataObject, db)
    end
end

-- Shown/hidden per the active profile's "Show Minimap Icon" option (Options
-- toggle, profile switches, and login).
ns.UpdateMinimapIconShown = function()
    local DBIcon = GetDBIcon()
    if not (DBIcon and DBIcon:IsRegistered(BROKER_NAME)) then return end
    local show = ns.profile and ns.profile.showMinimapIcon ~= false
    MinimapIconDB().hide = not show
    if show then DBIcon:Show(BROKER_NAME) else DBIcon:Hide(BROKER_NAME) end
end

-- LibDBIcon positions (and remembers) the button itself; kept so older
-- callers still work.
ns.UpdateMinimapIconPosition = function()
    local DBIcon = GetDBIcon()
    if DBIcon and DBIcon:IsRegistered(BROKER_NAME) and DBIcon.Refresh then
        DBIcon:Refresh(BROKER_NAME, MinimapIconDB())
    end
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------

-- Exported for the other PetSmart files.
ns.LauncherOnClick = LauncherOnClick
