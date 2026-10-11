--------------------------------------------------------------------------
-- PetSmart: Tracking/MapPins.lua
-- World map and minimap pins for tracked rares and the tracked tame-teacher pet.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local Print = ns.Print
local Tame = ns.Tame

----------------------------------------------------------------------
-- Rare pet map OVERLAY (world map + minimap). Shows every known spawn
-- point for whichever ONE rare is currently tracked - most rares have
-- just one camp, but a few roam between several named spots
-- (ns.RARE_SPAWNS[i].points is always an array, with more than one
-- entry for those) - and nothing at all for every other rare, so
-- tracking a different rare (or untracking) swaps/clears the whole set
-- at once rather than ever piling up multiple rares' markers together.
-- The custom dragon-head graphic lives at Media\Rare-Elements\RarePinWorldMap and
-- Media\Rare-Elements\RarePinMinimap (two pre-scaled sizes of the same artwork).
--
-- The user supplied SilverDragon_Overlay's own working source for this
-- client (worldmap.lua/pins.lua/module.lua/minimap.lua). It shows the
-- world map and minimap are two genuinely different systems there, and
-- the three earlier attempts here had been trying to force both through
-- HereBeDragons, which SilverDragon only ever uses for the MINIMAP half
-- (HBDPins:AddMinimapIconMap) plus a couple of coordinate-math helpers.
-- Its world map half never touches HereBeDragons at all: it registers a
-- MapCanvasDataProviderMixin-based provider with WorldMapFrame (the same
-- native Blizzard system Blizzard's own quest/vignette pins use) and
-- acquires pins through it, which is the only thing confirmed to work
-- on this client by that reference file actually working in-game. This
-- rewrite follows that split:
--   * World map  -> a MapCanvasDataProviderMixin provider added with
--     WorldMapFrame:AddDataProvider, drawing pins via a real pin
--     template (PetSmartRarePinTemplate, in PetSmart.xml) that inherits
--     Blizzard's own MapCanvasPinTemplate - not copied from SilverDragon,
--     since no pin template of theirs was supplied, just built the only
--     other way a pin can attach to this system at all.
--   * Minimap    -> HereBeDragons-Pins-2.0's AddMinimapIconMap, exactly
--     as SilverDragon's minimap.lua uses it, since that part was never
--     SilverDragon's own code to begin with (a bundled public-domain
--     library) and is the normal way any addon drives the minimap.
-- Like SilverDragon's own provider, this only shows pins while the
-- world map is actually open to the rare's own zone (no continent-wide
-- translation) - that matches what worldmap.lua does too.
----------------------------------------------------------------------
local WORLD_PIN_TEXTURE   = "Interface\\AddOns\\PetSmart\\Media\\Rare-Elements\\RarePinWorldMap"
local MINIMAP_PIN_TEXTURE = "Interface\\AddOns\\PetSmart\\Media\\Rare-Elements\\RarePinMinimap"
-- Source art is 35x40 (world) / 17x20 (minimap) - these sizes keep each
-- one's aspect ratio while fitting comfortably on its respective map.
local WORLD_PIN_WIDTH, WORLD_PIN_HEIGHT = 36, 40 -- +20% then +25% from the original 24x27
local MINIMAP_PIN_WIDTH, MINIMAP_PIN_HEIGHT = 25, 28 -- +75% from the original 14x16
-- Generous ceiling on simultaneous markers, shared across every tracked
-- rare combined (not per rare) - no single rare in the data needs more
-- than a handful of points, and multi-tracking a few such rares at once
-- still comfortably fits under this.
local MAX_OVERLAY_POINTS = 8

-- Same two textures/sizes, but the paw-print pin used only for a tracked
-- Abilities Index "teacher" pet (see trackedTameTeacher above) - visually
-- distinct from the dragon-head rare pin so the two tracking systems
-- never look like the same thing on the map.
-- A tame teacher's own pin budget, separate from MAX_OVERLAY_POINTS above.
-- That constant is sized for several *different* rares sharing the map at
-- once under Multi-Tracking; a tame teacher is always just the one
-- creature, so it gets a roomier ceiling of its own - each point here is
-- meant to be one general "cluster" area the species is known to spawn
-- in (per the Abilities Index tame-teacher feature's design), not a
-- precise individual sighting, so a species documented across up to a
-- dozen distinct areas of its zone can still show every cluster at once.

-- Soft "spawn area" highlight drawn on the world map behind each tame-
-- teacher pin: a light-blue fill with a darker-blue outline ring, baked
-- into one square texture (TameSpawnAreaOverlay.tga, a radial gradient -
-- flat fill out to ~80% of the image, blending to the darker outline
-- color through ~96%, then fading to fully transparent) so it reads as
-- one soft blob rather than a hard-edged square. Reused for every overlay
-- instance; only its on-screen size changes, from each point's own
-- `r` (radius, in the same 0-100 zone-percent units as x/y) or this
-- default when a point doesn't specify one.

-- ns.UpdateRarePin is defined further down in this file.
-- ns.UpdateMinimapIconShown / ns.UpdateMinimapIconPosition live in Core/Launchers.lua (minimap button).
-- ns.RegisterDataBrokerObject lives in Core/Launchers.lua (LibDataBroker launcher).

local loggedFlags = {}
local function LogOnce(flagName, what, err)
    if loggedFlags[flagName] then return end
    loggedFlags[flagName] = true
    Print(what .. " failed: " .. tostring(err))
end

----------------------------------------------------------------------
-- World map half - hand-rolled, no Blizzard pin template at all.
--
-- The native MapCanvasDataProviderMixin/AcquirePin route (what the last
-- build used, and what Blizzard's own quest/vignette pins use on normal
-- clients) turned out not to work here: "PetSmart.xml:11 Couldn't find
-- inherited node: MapCanvasPinTemplate" - this client's Blizzard_MapCanvas
-- doesn't ship a template by that name, so every pin AcquirePin handed
-- back was missing methods its own internals expect, and calling into
-- one of them crashed inside Blizzard_MapCanvas.lua itself.
--
-- This replaces that with plain frames, parented directly to the map's
-- canvas and positioned by hand from its denormalized width/height
-- (WorldMapFrame:DenormalizeHorizontalSize/VerticalSize - already
-- confirmed working on this client, since the SilverDragon_Overlay
-- reference file uses exactly these two calls). Repositioning runs on
-- every OnShow/zone-change (existing hooks) plus the canvas's own
-- OnSizeChanged (zoom), so it stays correct without depending on any
-- pin-pool machinery at all - the only Blizzard API surface this now
-- touches is CreateFrame, SetPoint, and those two Denormalize calls.
----------------------------------------------------------------------
local PETSMART_RARE_DEBUG = false
local function Trace(msg)
    if PETSMART_RARE_DEBUG then Print("|cff66ccff[rare-debug]|r " .. msg) end
end

local function GetMapCanvas()
    if WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
        return WorldMapFrame.ScrollContainer.Child
    end
    if WorldMapFrame.GetCanvas then
        local ok, canvas = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
        if ok and canvas then return canvas end
    end
    return WorldMapFrame
end

local worldPinPool = {}
local function GetWorldPin(i)
    local p = worldPinPool[i]
    if p then return p end
    local canvas = GetMapCanvas()
    p = CreateFrame("Frame", "PetSmartRareWorldPin" .. i, canvas)
    p:SetSize(WORLD_PIN_WIDTH, WORLD_PIN_HEIGHT)
    p:SetFrameStrata("TOOLTIP")
    p.tex = p:CreateTexture(nil, "OVERLAY")
    p.tex:SetAllPoints()
    p.tex:SetTexture(WORLD_PIN_TEXTURE)
    p:EnableMouse(true)
    -- `p.rare` is set fresh by RefreshWorldMapPins every time this pin is
    -- (re)assigned to a point, so with multiple rares tracked at once each
    -- pin's tooltip still names the right one instead of always the same
    -- single tracked rare.
    p:SetScript("OnEnter", function(self)
        if not self.rare then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.rare.level and (self.rare.name .. " (Lv " .. tostring(self.rare.level) .. ")") or self.rare.name, 1, 0.82, 0)
        if self.rare.zone then
            GameTooltip:AddLine(self.rare.zone, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    p:SetScript("OnLeave", function() GameTooltip:Hide() end)
    p:Hide()
    worldPinPool[i] = p
    return p
end

local function PositionWorldPin(pin, x, y)
    local canvas = GetMapCanvas()
    local ok, width = pcall(WorldMapFrame.DenormalizeHorizontalSize, WorldMapFrame, 1.0)
    local ok2, height = pcall(WorldMapFrame.DenormalizeVerticalSize, WorldMapFrame, 1.0)
    if not (ok and ok2 and width and height and width > 0 and height > 0) then
        -- Falls back to the canvas's own raw size if the Denormalize
        -- calls aren't available for some reason - still correct as
        -- long as the canvas frame's size tracks the visible map.
        width, height = canvas:GetWidth(), canvas:GetHeight()
    end
    -- Anchored by its own BOTTOM (not CENTER): the artwork comes to a
    -- point at the bottom of the image, so that point - not the image's
    -- middle - should land exactly on the spawn coordinate.
    pin:ClearAllPoints()
    pin:SetPoint("BOTTOM", canvas, "TOPLEFT", x * width, -(y * height))
end

-- Same positioning math as PositionWorldPin, but anchored by CENTER (the
-- overlay texture is a symmetrical blob, no "point" to it like a pin has)
-- and sized from a radius instead of a fixed pin size - the radius is in
-- the same 0-100 zone-percent units as x/y, so it scales independently on
-- each axis exactly like the point itself does, staying centered on the
-- same spot through pan/zoom.

local worldMapProviderOk = true -- always true now; nothing to register up front

local function RefreshWorldMapPins()
    for i = 1, MAX_OVERLAY_POINTS do
        if worldPinPool[i] then worldPinPool[i]:Hide() end
    end
    if #ns.trackedRares == 0 then
        Trace("RefreshWorldMapPins: nothing tracked")
        return
    end
    if ns.profile and ns.profile.showWorldMapRarePin == false then
        Trace("RefreshWorldMapPins: world map rare pin disabled in Options")
        return
    end
    if not (WorldMapFrame.GetMapID) then
        Trace("RefreshWorldMapPins: WorldMapFrame has no GetMapID method")
        return
    end
    local uiMapID = WorldMapFrame:GetMapID()

    -- Every tracked rare that has points on the zone currently being
    -- viewed contributes pins here, up to the shared MAX_OVERLAY_POINTS
    -- ceiling - a rare whose own map isn't the one on screen just stays
    -- invisible until the player switches to its zone, same as the
    -- single-rare behavior this replaces.
    local pinIndex = 0
    for _, rare in ipairs(ns.trackedRares) do
        if rare.mapID and rare.points and uiMapID == rare.mapID then
            for _, point in ipairs(rare.points) do
                pinIndex = pinIndex + 1
                if pinIndex > MAX_OVERLAY_POINTS then break end
                local pin = GetWorldPin(pinIndex)
                pin.rare = rare
                local ok, err = pcall(PositionWorldPin, pin, point.x / 100, point.y / 100)
                if ok then
                    pin:Show()
                    Trace(("RefreshWorldMapPins: placed pin #%d for '%s' at %.2f, %.2f"):format(pinIndex, rare.name, point.x, point.y))
                else
                    LogOnce("loggedWorldMapError", "PositionWorldPin", err)
                    Trace(("RefreshWorldMapPins: pin #%d positioning errored: %s"):format(pinIndex, tostring(err)))
                end
            end
        end
        if pinIndex >= MAX_OVERLAY_POINTS then break end
    end
end

-- Keeps pins correctly placed across zoom (the canvas frame's size
-- changes, but a fixed-pixel SetPoint offset doesn't rescale on its
-- own) without needing any pin-pool/provider refresh callback.
do
    local canvas = GetMapCanvas()
    if canvas and canvas.HookScript then
        canvas:HookScript("OnSizeChanged", function()
            Trace("Map canvas OnSizeChanged fired")
            RefreshWorldMapPins()
        end)
    end
end

----------------------------------------------------------------------
-- Minimap half - HereBeDragons-Pins-2.0, same library/API SilverDragon's
-- own minimap.lua uses (AddMinimapIconMap). Loaded defensively since
-- this is still a custom client, but nothing about this part changed
-- architecture - earlier builds' minimap pins may already have been
-- fine, with the world map half being the actual problem all along.
----------------------------------------------------------------------
local HBD_OK, HBD = pcall(function() return LibStub and LibStub("PetSmart-HereBeDragons-2.0", false) end)
local HBDP_OK, HBDP
if HBD_OK and HBD then
    HBDP_OK, HBDP = pcall(function() return LibStub("PetSmart-HereBeDragons-Pins-2.0", false) end)
else
    HBDP_OK, HBDP = false, nil
end
if not (HBDP_OK and HBDP) then
    HBDP = nil
    local warned = false
    local warnFrame = CreateFrame("Frame")
    warnFrame:RegisterEvent("PLAYER_LOGIN")
    warnFrame:SetScript("OnEvent", function()
        if warned then return end
        warned = true
        if not HBD_OK then
            Print("HereBeDragons-2.0 failed to load (" .. tostring(HBD) .. ") - rare minimap markers are disabled.")
        elseif not HBD then
            Print("HereBeDragons-2.0 library not found - rare minimap markers are disabled.")
        elseif not HBDP_OK then
            Print("HereBeDragons-Pins-2.0 failed to load (" .. tostring(HBDP) .. ") - rare minimap markers are disabled.")
        else
            Print("HereBeDragons-Pins-2.0 library not found - rare minimap markers are disabled.")
        end
    end)
end

local minimapPinPool = {}
local function GetMinimapPin(i)
    if not HBDP then return nil end
    local p = minimapPinPool[i]
    if not p then
        p = CreateFrame("Frame", "PetSmartRareMinimapPin" .. i, UIParent)
        p:SetSize(MINIMAP_PIN_WIDTH, MINIMAP_PIN_HEIGHT)
        p:SetFrameStrata("TOOLTIP")
        p.tex = p:CreateTexture(nil, "OVERLAY")
        -- HereBeDragons positions this frame by its CENTER, which it owns
        -- (AddMinimapIconMap), so unlike the world map pin above this one
        -- can't just be re-anchored. Instead the texture is pinned by its
        -- own BOTTOM to the frame's CENTER and sized separately, so the
        -- artwork's point - not its middle - sits on the frame's (and so
        -- the real) position.
        p.tex:SetSize(MINIMAP_PIN_WIDTH, MINIMAP_PIN_HEIGHT)
        p.tex:ClearAllPoints()
        p.tex:SetPoint("BOTTOM", p, "CENTER", 0, 0)
        p.tex:SetTexture(MINIMAP_PIN_TEXTURE)
        p:EnableMouse(true)
        -- `p.rare` is set fresh by UpdateMinimapPins every time this pin is
        -- (re)assigned, so each one's tooltip names the right rare even
        -- with several tracked at once.
        p:SetScript("OnEnter", function(self)
            if not self.rare then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.rare.level and (self.rare.name .. " (Lv " .. tostring(self.rare.level) .. ")") or self.rare.name, 1, 0.82, 0)
            GameTooltip:Show()
        end)
        p:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- The BOTTOM-anchored tip above is correct while the rare is in
        -- range (floatOnEdge's own 90%-of-radius clamp keeps it well
        -- inside the minimap), but once the rare goes out of range and
        -- HereBeDragons slides the pin's position onto the edge circle,
        -- that same tip-shaped offset pushes the artwork's body further
        -- outward from the clamped point - past the minimap's edge - in
        -- any direction except straight down. Re-anchoring by CENTER
        -- instead while on the edge keeps the whole icon symmetric around
        -- the clamped point, which is what the library's clamp math
        -- actually assumes, so it stays fully inside the minimap no
        -- matter which direction it's clamped toward. Polled rather than
        -- event-driven since HBDP updates pin positions on its own timer,
        -- not through any callback this addon can hook.
        p.edgeCheckElapsed = 0
        p:SetScript("OnUpdate", function(self, elapsed)
            self.edgeCheckElapsed = self.edgeCheckElapsed + elapsed
            if self.edgeCheckElapsed < 0.1 then return end
            self.edgeCheckElapsed = 0
            local onEdge = HBDP and HBDP:IsMinimapIconOnEdge(self) or false
            if onEdge ~= self.onMinimapEdge then
                self.onMinimapEdge = onEdge
                self.tex:ClearAllPoints()
                if onEdge then
                    self.tex:SetPoint("CENTER", self, "CENTER", 0, 0)
                else
                    self.tex:SetPoint("BOTTOM", self, "CENTER", 0, 0)
                end
            end
        end)
        p:Hide()
        minimapPinPool[i] = p
    end
    return p
end

local function UpdateMinimapPins()
    if not HBDP then
        Trace("UpdateMinimapPins: HBDP not loaded, skipping")
        return
    end
    for i = 1, MAX_OVERLAY_POINTS do
        if minimapPinPool[i] then
            local ok, err = pcall(HBDP.RemoveMinimapIcon, HBDP, ns, minimapPinPool[i])
            if not ok then LogOnce("loggedMinimapError", "RemoveMinimapIcon", err) end
        end
    end
    if not (ns.profile and ns.profile.showMinimapRarePin == false) then
        -- Unlike the world map half, HereBeDragons translates between
        -- zones/continents on its own (each AddMinimapIconMap call takes
        -- its own mapID), so every tracked rare contributes pins here
        -- regardless of which zone the player is actually in - up to the
        -- shared MAX_OVERLAY_POINTS ceiling.
        local pinIndex = 0
        for _, rare in ipairs(ns.trackedRares) do
            if rare.mapID and rare.points then
                for _, point in ipairs(rare.points) do
                    pinIndex = pinIndex + 1
                    if pinIndex > MAX_OVERLAY_POINTS then break end
                    local mp = GetMinimapPin(pinIndex)
                    if mp then
                        mp.rare = rare
                        local ok, err = pcall(HBDP.AddMinimapIconMap, HBDP, ns, mp, rare.mapID, point.x / 100, point.y / 100, false, true)
                        if not ok then
                            LogOnce("loggedMinimapError", "AddMinimapIconMap", err)
                            Trace("AddMinimapIconMap errored: " .. tostring(err))
                        else
                            Trace(("AddMinimapIconMap #%d placed for '%s' (mapID %s)"):format(pinIndex, rare.name, tostring(rare.mapID)))
                        end
                    end
                end
            end
            if pinIndex >= MAX_OVERLAY_POINTS then break end
        end
    end
end

-- Rebuilds both halves of the overlay to match whatever `trackedRares`
-- currently holds (or clears both if nothing is tracked).
ns.UpdateRarePin = function()
    Trace(("UpdateRarePin: worldMapProviderOk=%s, WorldMapFrame shown=%s"):format(
        tostring(worldMapProviderOk), tostring(WorldMapFrame and WorldMapFrame:IsShown())))
    if worldMapProviderOk and WorldMapFrame:IsShown() then
        local ok, err = pcall(RefreshWorldMapPins)
        if not ok then
            LogOnce("loggedWorldMapError", "World map RefreshWorldMapPins", err)
            Trace("World map RefreshWorldMapPins errored: " .. tostring(err))
        end
    end
    UpdateMinimapPins()
end

----------------------------------------------------------------------
-- Tame-teacher pin half - same two systems as the rare pins above
-- (hand-positioned world-map frames + HereBeDragons-Pins-2.0 for the
-- minimap), just driven by the single `trackedTameTeacher` instead of
-- the `trackedRares` array, always showing every one of its points
-- regardless of the Multi-Tracking option (that setting only governs
-- how many different RARES can be tracked at once - it has no bearing
-- on a single teacher pet's own spawn points, so there's nothing here
-- for it to even apply to). World-map positioning reuses PositionWorldPin
-- above unchanged; only the pin pool and texture are separate.
----------------------------------------------------------------------
-- ns.UpdateTamePin is assigned inside the do-block below.
-- Everything tame-teacher-pin-specific lives inside this do-block so its
-- locals stay private to it.
do
local TAME_WORLD_PIN_TEXTURE   = "Interface\\AddOns\\PetSmart\\Media\\Tame-Elements\\TameTeacherPinWorldMap"
local TAME_MINIMAP_PIN_TEXTURE = "Interface\\AddOns\\PetSmart\\Media\\Tame-Elements\\TameTeacherPinMinimap"
-- Own pin budget (see design note): one creature at a time, up to 12 cluster areas.
local TAME_MAX_OVERLAY_POINTS = 12
-- Soft light-blue/dark-blue-outline spawn-area highlight drawn behind each pin.
local TAME_AREA_TEXTURE = "Interface\\AddOns\\PetSmart\\Media\\Tame-Elements\\TameSpawnAreaOverlay"
local TAME_AREA_DEFAULT_RADIUS = 3.5

-- A teacher pet that is also one of the listed rare spawns (Timber, Bjarn,
-- Leech Widow...) gets the rare dragon-head pin instead of the bronze paw,
-- so it reads the same as when it's tracked from the Rare Pet Spawns list.
-- Matched by name against ns.RARE_SPAWNS, cached per name.
local rareNameCache = {}
local function IsRareSpawnName(name)
    if not name then return false end
    local hit = rareNameCache[name]
    if hit == nil then
        hit = false
        for _, rare in ipairs(ns.RARE_SPAWNS or {}) do
            if rare.name == name then hit = true; break end
        end
        rareNameCache[name] = hit
    end
    return hit
end

-- Stretches an overlay across the zone-percent bounding box (x1,y1)-(x2,y2).
local function PositionAreaBox(overlay, x1, y1, x2, y2)
    local canvas = GetMapCanvas()
    local ok, width = pcall(WorldMapFrame.DenormalizeHorizontalSize, WorldMapFrame, 1.0)
    local ok2, height = pcall(WorldMapFrame.DenormalizeVerticalSize, WorldMapFrame, 1.0)
    if not (ok and ok2 and width and height and width > 0 and height > 0) then
        width, height = canvas:GetWidth(), canvas:GetHeight()
    end
    overlay:SetSize(math.max((x2 - x1) * width, 1), math.max((y2 - y1) * height, 1))
    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT", canvas, "TOPLEFT", x1 * width, -(y1 * height))
end

local function PositionAreaOverlay(overlay, x, y, radiusPercent)
    local canvas = GetMapCanvas()
    local ok, width = pcall(WorldMapFrame.DenormalizeHorizontalSize, WorldMapFrame, 1.0)
    local ok2, height = pcall(WorldMapFrame.DenormalizeVerticalSize, WorldMapFrame, 1.0)
    if not (ok and ok2 and width and height and width > 0 and height > 0) then
        width, height = canvas:GetWidth(), canvas:GetHeight()
    end
    local diameterX = 2 * (radiusPercent / 100) * width
    local diameterY = 2 * (radiusPercent / 100) * height
    overlay:SetSize(math.max(diameterX, 1), math.max(diameterY, 1))
    overlay:ClearAllPoints()
    overlay:SetPoint("CENTER", canvas, "TOPLEFT", x * width, -(y * height))
end

local tameWorldPinPool = {}
local function GetTameWorldPin(i)
    local p = tameWorldPinPool[i]
    if p then return p end
    local canvas = GetMapCanvas()
    p = CreateFrame("Frame", "PetSmartTameWorldPin" .. i, canvas)
    p:SetSize(WORLD_PIN_WIDTH, WORLD_PIN_HEIGHT)
    p:SetFrameStrata("TOOLTIP")
    p.tex = p:CreateTexture(nil, "OVERLAY")
    p.tex:SetAllPoints()
    p.tex:SetTexture(TAME_WORLD_PIN_TEXTURE)
    p:EnableMouse(true)
    p:SetScript("OnEnter", function(self)
        if not self.teacherName then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.teacherLabel or self.teacherName, 1, 0.82, 0)
        if self.teacherZone then
            GameTooltip:AddLine(self.teacherZone, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    p:SetScript("OnLeave", function() GameTooltip:Hide() end)
    p:Hide()
    tameWorldPinPool[i] = p
    return p
end

-- The soft "spawn area" highlight behind each pin above (see
-- TAME_AREA_TEXTURE's own comment) - a plain, mouse-transparent frame so
-- it never steals the pin's own tooltip, drawn at a lower frame strata
-- than the "TOOLTIP"-strata pins so it always sits visually behind them.
local tameAreaOverlayPool = {}
local function GetTameAreaOverlay(i)
    local p = tameAreaOverlayPool[i]
    if p then return p end
    local canvas = GetMapCanvas()
    p = CreateFrame("Frame", "PetSmartTameAreaOverlay" .. i, canvas)
    p:SetFrameStrata("HIGH")
    p.tex = p:CreateTexture(nil, "OVERLAY")
    p.tex:SetAllPoints()
    p.tex:SetTexture(TAME_AREA_TEXTURE)
    p:EnableMouse(false)
    p:Hide()
    tameAreaOverlayPool[i] = p
    return p
end

local function RefreshTameWorldMapPins()
    for i = 1, TAME_MAX_OVERLAY_POINTS do
        if tameWorldPinPool[i] then tameWorldPinPool[i]:Hide() end
        if tameAreaOverlayPool[i] then tameAreaOverlayPool[i]:Hide() end
    end
    if not ns.trackedTameTeacher then
        Trace("RefreshTameWorldMapPins: nothing tracked")
        return
    end
    if ns.profile and ns.profile.showWorldMapRarePin == false then
        Trace("RefreshTameWorldMapPins: world map pin disabled in Options")
        return
    end
    if not WorldMapFrame.GetMapID then return end
    local uiMapID = WorldMapFrame:GetMapID()
    local info = ns.trackedTameTeacher.spawnInfo
    if not (info and info.mapID and info.points and uiMapID == info.mapID) then return end

    local pinIndex = 0
    for _, point in ipairs(info.points) do
        pinIndex = pinIndex + 1
        if pinIndex > TAME_MAX_OVERLAY_POINTS then break end
        local pin = GetTameWorldPin(pinIndex)
        pin.teacherName = ns.trackedTameTeacher.name
        pin.teacherLabel = Tame.GetLabel(ns.trackedTameTeacher.name, info)
        pin.teacherZone = info.zone
        pin.tex:SetTexture(IsRareSpawnName(ns.trackedTameTeacher.name) and WORLD_PIN_TEXTURE or TAME_WORLD_PIN_TEXTURE)
        local ok, err = pcall(PositionWorldPin, pin, point.x / 100, point.y / 100)
        if ok then
            pin:Show()
        else
            LogOnce("loggedTameWorldMapError", "PositionWorldPin (tame teacher)", err)
        end

        -- The highlighted area behind this same point, in the middle of
        -- which the pin above now sits.
        local overlay = GetTameAreaOverlay(pinIndex)
        local area = info.areas and info.areas[pinIndex]
        if area then
            -- Traced polygon zone: a baked texture stretched over its bounding box.
            overlay.tex:SetTexture(area.tex)
            local okArea, errArea = pcall(PositionAreaBox, overlay, area.x1 / 100, area.y1 / 100, area.x2 / 100, area.y2 / 100)
            if okArea then
                overlay:Show()
            else
                LogOnce("loggedTameAreaError", "PositionAreaBox (tame teacher)", errArea)
            end
        else
            -- Single-spawn creatures with no traced area get just the pin -
            -- no circular highlight.
            overlay:Hide()
        end
    end
end

do
    local canvas = GetMapCanvas()
    if canvas and canvas.HookScript then
        canvas:HookScript("OnSizeChanged", function() RefreshTameWorldMapPins() end)
    end
end

local tameMinimapPinPool = {}
local function GetTameMinimapPin(i)
    if not HBDP then return nil end
    local p = tameMinimapPinPool[i]
    if not p then
        p = CreateFrame("Frame", "PetSmartTameMinimapPin" .. i, UIParent)
        p:SetSize(MINIMAP_PIN_WIDTH, MINIMAP_PIN_HEIGHT)
        p:SetFrameStrata("TOOLTIP")
        p.tex = p:CreateTexture(nil, "OVERLAY")
        p.tex:SetSize(MINIMAP_PIN_WIDTH, MINIMAP_PIN_HEIGHT)
        p.tex:ClearAllPoints()
        p.tex:SetPoint("BOTTOM", p, "CENTER", 0, 0)
        p.tex:SetTexture(TAME_MINIMAP_PIN_TEXTURE)
        p:EnableMouse(true)
        p:SetScript("OnEnter", function(self)
            if not self.teacherName then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.teacherLabel or self.teacherName, 1, 0.82, 0)
            GameTooltip:Show()
        end)
        p:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- Same edge-clamp re-anchor fix as the rare minimap pin above.
        p.edgeCheckElapsed = 0
        p:SetScript("OnUpdate", function(self, elapsed)
            self.edgeCheckElapsed = self.edgeCheckElapsed + elapsed
            if self.edgeCheckElapsed < 0.1 then return end
            self.edgeCheckElapsed = 0
            local onEdge = HBDP and HBDP:IsMinimapIconOnEdge(self) or false
            if onEdge ~= self.onMinimapEdge then
                self.onMinimapEdge = onEdge
                self.tex:ClearAllPoints()
                if onEdge then
                    self.tex:SetPoint("CENTER", self, "CENTER", 0, 0)
                else
                    self.tex:SetPoint("BOTTOM", self, "CENTER", 0, 0)
                end
            end
        end)
        p:Hide()
        tameMinimapPinPool[i] = p
    end
    return p
end

local function UpdateTameMinimapPins()
    if not HBDP then return end
    for i = 1, TAME_MAX_OVERLAY_POINTS do
        if tameMinimapPinPool[i] then
            local ok, err = pcall(HBDP.RemoveMinimapIcon, HBDP, ns, tameMinimapPinPool[i])
            if not ok then LogOnce("loggedTameMinimapError", "RemoveMinimapIcon (tame teacher)", err) end
        end
    end
    if ns.trackedTameTeacher and not (ns.profile and ns.profile.showMinimapRarePin == false) then
        local info = ns.trackedTameTeacher.spawnInfo
        if info and info.mapID and info.points then
            local pinIndex = 0
            for _, point in ipairs(info.points) do
                pinIndex = pinIndex + 1
                if pinIndex > TAME_MAX_OVERLAY_POINTS then break end
                local mp = GetTameMinimapPin(pinIndex)
                if mp then
                    mp.teacherName = ns.trackedTameTeacher.name
                    mp.teacherLabel = Tame.GetLabel(ns.trackedTameTeacher.name, info)
                    mp.tex:SetTexture(IsRareSpawnName(ns.trackedTameTeacher.name) and MINIMAP_PIN_TEXTURE or TAME_MINIMAP_PIN_TEXTURE)
                    local ok, err = pcall(HBDP.AddMinimapIconMap, HBDP, ns, mp, info.mapID, point.x / 100, point.y / 100, false, true)
                    if not ok then LogOnce("loggedTameMinimapError", "AddMinimapIconMap (tame teacher)", err) end
                end
            end
        end
    end
end

-- Hover tooltip for the highlighted areas themselves. The overlay frames stay
-- mouse-transparent (so map clicks/panning are untouched); instead this
-- frame hit-tests the cursor against each area's real outline, so only the
-- highlighted shape (not its bounding box) triggers the tooltip.
local function PointInPoly(poly, x, y)
    local inside = false
    local j = #poly
    for i = 1, #poly do
        local xi, yi, xj, yj = poly[i][1], poly[i][2], poly[j][1], poly[j][2]
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function CursorOverTameArea()
    local info = ns.trackedTameTeacher and ns.trackedTameTeacher.spawnInfo
    if not (info and info.points) then return false end
    local canvas = GetMapCanvas()
    if not (canvas and canvas.GetLeft and WorldMapFrame:IsMouseOver()) then return false end
    if WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() ~= info.mapID then return false end
    local ok, width = pcall(WorldMapFrame.DenormalizeHorizontalSize, WorldMapFrame, 1.0)
    local ok2, height = pcall(WorldMapFrame.DenormalizeVerticalSize, WorldMapFrame, 1.0)
    if not (ok and ok2 and width and height and width > 0 and height > 0) then
        width, height = canvas:GetWidth(), canvas:GetHeight()
    end
    local left, top, scale = canvas:GetLeft(), canvas:GetTop(), canvas:GetEffectiveScale()
    if not (left and top and scale and scale > 0) then return false end
    local cx, cy = GetCursorPosition()
    local px = (cx / scale - left) / width * 100
    local py = (top - cy / scale) / height * 100
    if px < 0 or px > 100 or py < 0 or py > 100 then return false end
    for i, point in ipairs(info.points) do
        if i > TAME_MAX_OVERLAY_POINTS then break end
        local area = info.areas and info.areas[i]
        if area then
            if px >= area.x1 and px <= area.x2 and py >= area.y1 and py <= area.y2
                and (not area.poly or PointInPoly(area.poly, px, py)) then
                return true
            end
        end
    end
    return false
end

local areaHover = CreateFrame("Frame", nil, UIParent)
areaHover.elapsed, areaHover.shown = 0, false
areaHover:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.05 then return end
    self.elapsed = 0
    if not (ns.trackedTameTeacher and WorldMapFrame and WorldMapFrame:IsShown()) then
        if self.shown then GameTooltip:Hide(); self.shown = false end
        return
    end
    if GameTooltip:IsShown() and not GameTooltip:IsOwned(self) then
        self.shown = false -- a pin's own tooltip has the cursor; leave it alone
        return
    end
    local ok, over = pcall(CursorOverTameArea)
    if ok and over then
        if not self.shown then
            local info = ns.trackedTameTeacher.spawnInfo
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetText(Tame.GetLabel(ns.trackedTameTeacher.name, info), 1, 0.82, 0)
            if info and info.zone then GameTooltip:AddLine(info.zone, 1, 1, 1) end
            GameTooltip:Show()
            self.shown = true
        end
    elseif self.shown then
        GameTooltip:Hide()
        self.shown = false
    end
end)

-- Rebuilds both halves of the tame-teacher overlay, mirroring
-- UpdateRarePin above exactly except for which pin pool it touches.
ns.UpdateTamePin = function()
    if worldMapProviderOk and WorldMapFrame:IsShown() then
        local ok, err = pcall(RefreshTameWorldMapPins)
        if not ok then LogOnce("loggedTameWorldMapError", "World map RefreshTameWorldMapPins", err) end
    end
    UpdateTameMinimapPins()
end
end -- do (tame-teacher pins)

-- Exported for the other PetSmart files.
ns.LogOnce = LogOnce
ns.Trace = Trace
