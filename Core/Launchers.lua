--------------------------------------------------------------------------
-- PetSmart: Core/Launchers.lua
-- Icon/launcher behaviour: Feed Pet icon clicks, click-off, LibDataBroker, minimap button.
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
            panel:Hide()
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
        panel:Hide()
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
    if panel:IsShown() then
        panel:Hide()
    end
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
-- LibDataBroker-1.1 integration: lets broker-display addons (Titan
-- Panel, Bazooka, ChocolateBar, and similar) show PetSmart on their own
-- bar instead of (or alongside) the free-floating on-screen icon.
-- Registered once, from ActivateAddon, so it only ever shows up for
-- eligible Hunters, same as the icon itself. No PetSmart option controls
-- whether it's shown from here on - that's left to the broker-display
-- addon itself, same as it is for every other addon's data object.
----------------------------------------------------------------------
ns.RegisterDataBrokerObject = function()
    if brokerRegistered then return end
    local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
    if not LDB then return end

    LDB:NewDataObject("PetSmart", {
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
end

----------------------------------------------------------------------
-- Minimap launcher icon: a draggable button on the minimap mirroring
-- the broker launcher above - same icon, same two actions. Hand-rolled
-- rather than built on LibDBIcon-1.0: the orbit-position math it needs
-- is small and self-contained enough not to be worth pulling in a whole
-- extra library for. Its angle around the minimap is account-wide (like
-- the on-screen icon's own dragged position), while whether it's shown
-- at all is the per-profile "Show Minimap Icon" option.
----------------------------------------------------------------------
local minimapIcon = CreateFrame("Button", "PetSmartMinimapButton", Minimap)
minimapIcon:SetSize(31, 31)
minimapIcon:SetFrameStrata("MEDIUM")
minimapIcon:SetFrameLevel(8)
minimapIcon:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
minimapIcon:RegisterForDrag("LeftButton")
minimapIcon:SetHighlightTexture(136477) -- Interface\Minimap\UI-Minimap-ZoomButton-Highlight
minimapIcon:Hide()

local miOverlay = minimapIcon:CreateTexture(nil, "OVERLAY")
miOverlay:SetSize(53, 53)
miOverlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
miOverlay:SetPoint("TOPLEFT", 0, 0)

local miBackground = minimapIcon:CreateTexture(nil, "BACKGROUND")
miBackground:SetSize(20, 20)
miBackground:SetTexture(136467) -- Interface\Minimap\UI-Minimap-Background
miBackground:SetPoint("TOPLEFT", 7, -5)

local miIcon = minimapIcon:CreateTexture(nil, "ARTWORK")
miIcon:SetSize(18, 18)
miIcon:SetTexture("Interface\\AddOns\\PetSmart\\Media\\UI-Elements\\BrokerIcon")
miIcon:SetPoint("TOPLEFT", 7, -6)

ns.UpdateMinimapIconPosition = function()
    local angle = math.rad(PetSmartDB.minimapIconAngle or 225)
    local radius = (Minimap:GetWidth() / 2) + 5
    minimapIcon:ClearAllPoints()
    minimapIcon:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

minimapIcon:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        if not mx then return end
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        PetSmartDB.minimapIconAngle = math.deg(math.atan2(py - my, px - mx))
        ns.UpdateMinimapIconPosition()
    end)
end)
minimapIcon:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)
minimapIcon:SetScript("OnClick", function(self, button) LauncherOnClick(button, self) end)
minimapIcon:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    LauncherOnTooltipShow(GameTooltip)
    GameTooltip:Show()
end)
minimapIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- Shown/hidden per the active profile's "Show Minimap Icon" option. Only
-- ever called from ActivateAddon (so it only ever appears for eligible
-- Hunters) and from the Options toggle, both of which only run once
-- `profile` is already set - never before login/activation.
ns.UpdateMinimapIconShown = function()
    minimapIcon:SetShown(ns.profile and ns.profile.showMinimapIcon ~= false)
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------

-- Exported for the other PetSmart files.
ns.LauncherOnClick = LauncherOnClick
