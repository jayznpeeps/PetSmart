--------------------------------------------------------------------------
-- PetSmart: ExperienceBar/ExperienceBar.lua
-- The free-floating pet experience bar (movable, resizable, per-profile),
-- plus the Width/Height sliders its Options block uses.
--------------------------------------------------------------------------
local addonName, ns = ...

-- Shared from earlier files (see the ns.<name> exports at the end of each).
local panelTemplate = ns.panelTemplate
local scrollChild = ns.scrollChild

local XP = {} -- pet experience bar API, shared with the other files as ns.XP

----------------------------------------------------------------------
-- Pet experience bar: its own free-floating element (not part of the
-- feed icon or the Compendium). Drag it to move, drag the corner grip
-- (or use the Width/Height sliders in Options) to resize it. Everything
-- is per-profile: xpBarEnabled / xpBarShowText / xpBarLocked / xpBarWidth /
-- xpBarHeight / xpBarPos in PROFILE_DEFAULTS.
----------------------------------------------------------------------
XP.MIN_W, XP.MAX_W, XP.MIN_H, XP.MAX_H = 60, 600, 12, 60
XP.DEFAULT_W, XP.DEFAULT_H = 280, 22

-- Same look as the experience bar on the Compendium's pet page: a dark
-- box with the gold-brown rounded border, and a status bar inset inside it
-- with the shared blue gradient fill (gold at max level). The border is
-- drawn again on a frame above the fill, so the fill's square ends sit
-- under the rounded corners instead of over them.
do
    local LAYOUT = ns.LAYOUT
    local f = CreateFrame("Frame", "PetSmartXPBar", UIParent, panelTemplate)
    XP.frame = f
    f:SetSize(XP.DEFAULT_W, XP.DEFAULT_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -100)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetResizable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:Hide()
    if f.SetResizeBounds then
        pcall(f.SetResizeBounds, f, XP.MIN_W, XP.MIN_H, XP.MAX_W, XP.MAX_H)
    elseif f.SetMinResize then
        pcall(f.SetMinResize, f, XP.MIN_W, XP.MIN_H)
        if f.SetMaxResize then pcall(f.SetMaxResize, f, XP.MAX_W, XP.MAX_H) end
    end
    if f.SetBackdrop then
        f:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
            insets = { left = 2, right = 2, top = 2, bottom = 2 } })
        f:SetBackdropColor(0, 0, 0, 0.75)
    end

    f.bar = CreateFrame("StatusBar", nil, f)
    f.bar:SetPoint("TOPLEFT", 3, -3)
    f.bar:SetPoint("BOTTOMRIGHT", -3, 3)
    f.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.bar:SetMinMaxValues(0, 1)
    f.bar:SetValue(0)

    f.edge = CreateFrame("Frame", nil, f, panelTemplate)
    f.edge:SetAllPoints()
    f.edge:SetFrameLevel(f.bar:GetFrameLevel() + 1)
    if f.edge.SetBackdrop then
        f.edge:SetBackdrop({ edgeFile = LAYOUT.SUBPANEL_BACKDROP.edgeFile, edgeSize = 10 })
        f.edge:SetBackdropBorderColor(0.55, 0.45, 0.3, 1)
    end

    f.text = f.edge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.text:SetPoint("CENTER", 0, 0)
    f.text:SetJustifyH("CENTER")
    f.text:SetWordWrap(false)
    do
        local path, size, flags = f.text:GetFont()
        XP.fontPath, XP.fontSize, XP.fontFlags = path, size or 10, flags
    end

    f.grip = CreateFrame("Button", nil, f)
    f.grip:SetSize(10, 10)
    f.grip:SetPoint("BOTTOMRIGHT", -1, 1)
    f.grip:SetFrameLevel(f.edge:GetFrameLevel() + 5)
    f.grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    f.grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    f.grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
end

-- Fill gradient for the floating bar: the player's chosen colour (Options)
-- shading from a darker version of it on the left to the colour itself on
-- the right, or the default blue; gold at max level either way.
function XP.FillColors(atMax)
    if atMax then return ns.BAR_COLORS.max end
    local c = ns.profile and ns.profile.xpBarColor
    if type(c) == "table" and c[1] then
        return { c[1] * 0.4, c[2] * 0.4, c[3] * 0.4, c[1], c[2], c[3] }
    end
    return ns.BAR_COLORS.xp
end

-- The colour shown on the Options swatch (the bright end of the fill).
function XP.CurrentColor()
    local c = XP.FillColors(false)
    return c[4], c[5], c[6]
end

function XP.Num(n)
    n = math.floor((n or 0) + 0.5)
    if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
    return tostring(n)
end

function XP.Save()
    local f = XP.frame
    if not (f and ns.profile) then return end
    local point, _, relPoint, x, y = f:GetPoint()
    if point then ns.profile.xpBarPos = { point, relPoint, x, y } end
    ns.profile.xpBarWidth = math.floor(f:GetWidth() + 0.5)
    ns.profile.xpBarHeight = math.floor(f:GetHeight() + 0.5)
end

function XP.Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- XP.Update for when the client hands back secret XP values: they can be
-- passed straight to the status bar and to SetFormattedText, but the
-- percentage, the max-level check and the text-fitting maths can't be
-- done, so the text is chosen by the bar's width instead.
function XP.UpdateSecret(f, cur, max)
    f.bar:SetMinMaxValues(0, max)
    f.bar:SetValue(cur)
    ns.SetBarGradient(f.bar, unpack(XP.FillColors(false)))
    local w, h = f:GetWidth(), f:GetHeight()
    if XP.fontPath then
        f.text:SetFont(XP.fontPath, XP.Clamp(math.floor(h - 12), XP.fontSize, 16), XP.fontFlags)
    end
    local name, level = UnitName("pet") or "Pet", UnitLevel("pet") or 0
    if ns.profile.xpBarShowText == false then
        f.text:SetText("")
    elseif w >= 240 then
        f.text:SetFormattedText("%s - %s - XP: %s/%s", name, level, cur, max)
    elseif w >= 130 then
        f.text:SetFormattedText("%s - %s", name, level)
    else
        f.text:SetFormattedText("%s", level)
    end
    f.grip:SetShown(not ns.profile.xpBarLocked)
end

function XP.Update()
    local f = XP.frame
    if not (f and ns.profile) then return end
    local _, class = UnitClass("player")
    if ns.profile.xpBarEnabled == false or class ~= "HUNTER" or not UnitExists("pet") then
        f:Hide()
        return
    end
    f:Show()
    local cur, max = 0, 0
    if GetPetExperience then cur, max = GetPetExperience() end
    if ns.AnySecret(cur, max, UnitLevel("pet")) then
        XP.UpdateSecret(f, cur or 0, max or 0)
        return
    end
    cur, max = tonumber(cur) or 0, tonumber(max) or 0
    local level = UnitLevel("pet") or 0
    local atMax = (max <= 0)
    local frac = atMax and 1 or XP.Clamp(cur / max, 0, 1)
    f.bar:SetMinMaxValues(0, 1)
    f.bar:SetValue(frac)
    ns.SetBarGradient(f.bar, unpack(XP.FillColors(atMax)))

    -- Text grows with the bar's height, like the bar itself.
    local w, h = f:GetWidth(), f:GetHeight()
    if XP.fontPath then
        f.text:SetFont(XP.fontPath, XP.Clamp(math.floor(h - 12), XP.fontSize, 16), XP.fontFlags)
    end
    if ns.profile.xpBarShowText == false then
        f.text:SetText("")
    else
        -- Pet name, level and XP; on a bar too narrow for all of it, drop
        -- the numbers first, then the name, keeping the percentage.
        local name = UnitName("pet") or "Pet"
        local pct = atMax and 100 or math.floor(cur / max * 100)
        local options
        -- "<name> - <level> - XP: <current>/<max> (<pct>%)"
        if atMax then
            options = {
                ("%s - %d - XP: Max Level"):format(name, level),
                ("%s - %d - Max"):format(name, level),
                ("%d - Max"):format(level),
                "Max",
            }
        else
            options = {
                ("%s - %d - XP: %s/%s (%d%%)"):format(name, level, XP.Num(cur), XP.Num(max), pct),
                ("%s - %d - XP: %d%%"):format(name, level, pct),
                ("%d - XP: %d%%"):format(level, pct),
                ("XP: %d%%"):format(pct),
                ("%d%%"):format(pct),
            }
        end
        local room = w - 14
        local chosen = options[#options]
        for _, t in ipairs(options) do
            f.text:SetText(t)
            if (f.text:GetStringWidth() or 0) <= room then chosen = t; break end
        end
        f.text:SetText(chosen)
    end
    f.grip:SetShown(not ns.profile.xpBarLocked)
end

-- Restore saved size/position and refresh; called at login and whenever
-- the active profile changes.
function XP.Apply()
    local f = XP.frame
    if not (f and ns.profile) then return end
    f:SetSize(XP.Clamp(ns.profile.xpBarWidth or XP.DEFAULT_W, XP.MIN_W, XP.MAX_W), XP.Clamp(ns.profile.xpBarHeight or XP.DEFAULT_H, XP.MIN_H, XP.MAX_H))
    if ns.profile.xpBarPos then
        f:ClearAllPoints()
        f:SetPoint(ns.profile.xpBarPos[1], UIParent, ns.profile.xpBarPos[2], ns.profile.xpBarPos[3], ns.profile.xpBarPos[4])
    end
    XP.Update()
end

-- Width/Height from the Options sliders.
function XP.SetSize(w, h)
    local f = XP.frame
    if not (f and ns.profile) then return end
    w = XP.Clamp(w or ns.profile.xpBarWidth or XP.DEFAULT_W, XP.MIN_W, XP.MAX_W)
    h = XP.Clamp(h or ns.profile.xpBarHeight or XP.DEFAULT_H, XP.MIN_H, XP.MAX_H)
    ns.profile.xpBarWidth, ns.profile.xpBarHeight = w, h
    f:SetSize(w, h)
    XP.Update()
end

do
    local f = XP.frame
    f:SetScript("OnDragStart", function(self)
        if ns.profile and not ns.profile.xpBarLocked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        XP.Save()
    end)
    f:SetScript("OnSizeChanged", function() XP.Update() end)
    f.grip:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or (ns.profile and ns.profile.xpBarLocked) then return end
        -- Same trick as the Compendium's grip: anchor via TOPLEFT first so
        -- StartSizing("BOTTOMRIGHT") always grows down/right with the mouse.
        local left, top = f:GetLeft(), f:GetTop()
        if left and top then
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        end
        f:StartSizing("BOTTOMRIGHT")
    end)
    f.grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        XP.Save()
        if ns.abilitiesMode == "options" and ns.RefreshAbilitiesPanel then ns.RefreshAbilitiesPanel() end
    end)
    f:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        local name = UnitName("pet") or "Pet"
        local level = UnitLevel("pet") or 0
        if ns.AnySecret(level) then
            GameTooltip:SetText(name, 1, 0.82, 0)
        else
            GameTooltip:SetText(("%s  (Level %d)"):format(name, level), 1, 0.82, 0)
        end
        local cur, max = 0, 0
        if GetPetExperience then cur, max = GetPetExperience() end
        if ns.AnySecret(cur, max, level) then
            -- Secret values: no maths; show them as-is if the client allows
            -- formatting them into tooltip text, otherwise just the name.
            pcall(function() GameTooltip:AddLine(("XP: %s / %s"):format(cur, max), 1, 1, 1) end)
            if ns.profile and not ns.profile.xpBarLocked then
                GameTooltip:AddLine("Drag to move. Drag the corner to resize.", 0.6, 0.8, 1)
            end
            GameTooltip:Show()
            return
        end
        cur, max = tonumber(cur) or 0, tonumber(max) or 0
        if max > 0 then
            GameTooltip:AddLine(("XP: %s / %s  (%d%%)"):format(XP.Num(cur), XP.Num(max), math.floor(cur / max * 100)), 1, 1, 1)
            GameTooltip:AddLine(("%s XP to level %d"):format(XP.Num(max - cur), level + 1), 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("XP: Max Level (the highest your pet can be at your level)", 1, 1, 1)
        end
        if ns.profile and not ns.profile.xpBarLocked then
            GameTooltip:AddLine("Drag to move. Drag the corner to resize.", 0.6, 0.8, 1)
        end
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local evf = CreateFrame("Frame")
    for _, e in ipairs({ "UNIT_PET_EXPERIENCE", "UNIT_PET", "UNIT_LEVEL", "PET_UI_UPDATE", "PET_BAR_UPDATE", "PLAYER_ENTERING_WORLD" }) do
        pcall(evf.RegisterEvent, evf, e)
    end
    evf:SetScript("OnEvent", function() XP.Update() end)

    -- Options-panel sliders (persistent widgets, positioned by hand like
    -- the Icon Size slider).
    local function MakeSlider(name, lo, hi, labelFmt, key)
        local sl = CreateFrame("Slider", name, scrollChild)
        sl:SetOrientation("HORIZONTAL")
        sl:SetHeight(16)
        sl:SetHitRectInsets(0, 0, -8, -8)
        sl:SetMinMaxValues(lo, hi)
        sl:SetValueStep(1)
        if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
        sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        sl:GetThumbTexture():SetSize(24, 24)
        local track = sl:CreateTexture(nil, "BACKGROUND")
        track:SetColorTexture(0, 0, 0, 0.6)
        track:SetPoint("TOPLEFT", 0, -5)
        track:SetPoint("BOTTOMRIGHT", 0, 5)
        sl.label = sl:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        sl.label:SetPoint("BOTTOMLEFT", sl, "TOPLEFT", 0, 2)
        sl.label:SetJustifyH("LEFT")
        sl.low = sl:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sl.low:SetPoint("TOPLEFT", sl, "BOTTOMLEFT", 0, -1)
        sl.low:SetText(tostring(lo))
        sl.high = sl:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sl.high:SetPoint("TOPRIGHT", sl, "BOTTOMRIGHT", 0, -1)
        sl.high:SetText(tostring(hi))
        sl.labelFmt, sl.key = labelFmt, key
        sl:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value + 0.5)
            self.label:SetText(self.labelFmt:format(value))
            if not ns.profile or ns.profile[self.key] == value then return end
            if self.key == "xpBarWidth" then XP.SetSize(value, nil) else XP.SetSize(nil, value) end
        end)
        sl:Hide()
        return sl
    end
    -- Options-panel "Bar Color" row: a colour swatch that opens the game's
    -- colour picker, plus a Reset link back to the default blue. Positioned
    -- by hand on the Options page, like the sliders.
    do
        local row = CreateFrame("Button", "PetSmartXPColorButton", scrollChild)
        row:SetHeight(22)
        row.border = row:CreateTexture(nil, "BACKGROUND")
        row.border:SetSize(18, 18)
        row.border:SetPoint("LEFT", 2, 0)
        row.border:SetColorTexture(0.55, 0.45, 0.3, 1)
        row.swatch = row:CreateTexture(nil, "ARTWORK")
        row.swatch:SetSize(14, 14)
        row.swatch:SetPoint("CENTER", row.border, "CENTER", 0, 0)
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("LEFT", row.border, "RIGHT", 8, 0)
        row.label:SetText("Bar Color  |cff999999(click to change)|r")
        row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight", "ADD")
        row:SetScript("OnClick", function() XP.OpenColorPicker() end)
        row.reset = CreateFrame("Button", "PetSmartXPColorReset", row)
        row.reset:SetSize(50, 18)
        row.reset:SetPoint("RIGHT", -8, 0)
        row.reset.text = row.reset:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.reset.text:SetAllPoints()
        row.reset.text:SetJustifyH("RIGHT")
        row.reset.text:SetText("Reset")
        row.reset.text:SetTextColor(0.6, 0.8, 1)
        row.reset:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 1, 1) end)
        row.reset:SetScript("OnLeave", function(self) self.text:SetTextColor(0.6, 0.8, 1) end)
        row.reset:SetScript("OnClick", function() XP.SetColor(nil) end)
        row:Hide()
        XP.colorRow = row
    end

    XP.widthSlider = MakeSlider("PetSmartXPWidthSlider", XP.MIN_W, XP.MAX_W, "Bar Width: %dpx", "xpBarWidth")
    XP.heightSlider = MakeSlider("PetSmartXPHeightSlider", XP.MIN_H, XP.MAX_H, "Bar Height: %dpx", "xpBarHeight")
end

-- Sets the bar's colour (nil = back to the default blue), repaints the
-- bar and the Options swatch.
function XP.SetColor(r, g, b)
    if not ns.profile then return end
    ns.profile.xpBarColor = r and { r, g, b } or nil
    XP.Update()
    XP.UpdateSwatch()
end

function XP.UpdateSwatch()
    local row = XP.colorRow
    if not row then return end
    row.swatch:SetColorTexture(XP.CurrentColor())
    row.reset:SetShown(ns.profile and ns.profile.xpBarColor ~= nil)
end

-- Opens the game's colour picker on the bar's current colour. Dragging in
-- the picker recolours the bar live; Cancel puts the previous colour back.
-- Newer clients use SetupColorPickerAndShow, older ones the field API.
function XP.OpenColorPicker()
    local cp = ColorPickerFrame
    if not (cp and ns.profile) then return end
    local had = ns.profile.xpBarColor
    local before = had and { had[1], had[2], had[3] } or nil
    local r, g, b = XP.CurrentColor()
    local function picked()
        local nr, ng, nb = cp:GetColorRGB()
        XP.SetColor(nr, ng, nb)
    end
    local function cancelled()
        if before then XP.SetColor(before[1], before[2], before[3]) else XP.SetColor(nil) end
    end
    if cp.SetupColorPickerAndShow then
        cp:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false,
            swatchFunc = picked, cancelFunc = cancelled })
    else
        cp.hasOpacity = false
        cp.previousValues = { r, g, b }
        cp.func, cp.swatchFunc, cp.cancelFunc = picked, picked, cancelled
        cp:SetColorRGB(r, g, b)
        cp:Hide()
        cp:Show()
    end
end

-- Exported for the other PetSmart files.
ns.XP = XP
