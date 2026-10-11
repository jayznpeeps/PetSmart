--------------------------------------------------------------------------
-- PetSmart: Core/Init.lua
-- Shared setup: saved-variable profiles, constants and small API helpers.
--------------------------------------------------------------------------
local addonName, ns = ...
local addonName, ns = ...

local FEED_PET_SPELL_ID  = 6991
local FALLBACK_SPELL     = "Feed Pet"
local FALLBACK_ICON      = "Interface\\Icons\\Ability_Hunter_BeastCall"
local BUTTON_SIZE        = 36
local PADDING            = 4
local COLUMNS            = 8
local MAX_BUTTONS        = 48

local defaults = {
    locked = false, showAll = false, custom = {}, panelShownByChar = {},
}
-- Range of the Icon Size slider on the Options panel.
local ICON_SIZE_MIN, ICON_SIZE_MAX = 20, 64

----------------------------------------------------------------------
-- Profiles: Options settings and the Compendium panel's size/position
-- are stored per-profile rather than as flat top-level SavedVariables,
-- and each character independently picks which profile it uses (so two
-- characters can share one profile, or keep entirely separate setups).
-- "Default" always exists and can't be deleted.
----------------------------------------------------------------------
local PROFILE_DEFAULTS = {
    tooltipShowName = true,
    tooltipShowLoyalty = true,
    tooltipShowHappiness = true,
    iconSize = 40,
    -- Pet experience bar (separate movable/resizable element).
    xpBarEnabled = true,
    xpBarShowText = true,
    xpBarLocked = false,
    xpBarWidth = 280,
    xpBarHeight = 22,
    xpBarPos = nil,
    showMinimapIcon = true,
    showMinimapRarePin = true,
    showWorldMapRarePin = true,
    abilitiesPanelLocked = false,
    abilitiesPanelPos = nil,
    abilitiesPanelSize = nil, -- pre-1.61.0 single-panel size; no longer applied
    compendiumSize = nil,     -- {w, h} of the three-panel Compendium window
    -- Which section the Compendium reopens on (the root mode of the last
    -- section icon used): "learned", "training", "types", "spawns" or
    -- "options". nil means the default (Pet Abilities).
    lastSection = nil,
    -- Whether more than one rare can be tracked on the minimap/world map
    -- at once. Off by default (one rare at a time); see the Options
    -- panel's "Multi-Tracking" note about the trade-off against immersion.
    multiTrackingEnabled = false,
    -- Which rare(s) (by name) this profile is currently tracking on the
    -- minimap/world map - nil for none, otherwise a list (just ever one
    -- entry while multiTrackingEnabled is off). Profile-scoped (not
    -- account-wide) so two characters never see each other's tracked
    -- rares unless they deliberately share one profile - see
    -- RestoreTrackedRareFromProfile. (Replaces the pre-multi-tracking
    -- singular `trackedRareName` field - ApplyProfileDefaults migrates
    -- any old save on load.)
    trackedRareNames = nil,
}
local DEFAULT_PROFILE_NAME = "Default"

-- The active profile's settings table - an upvalue so every part of the
-- addon reads/writes through the same live reference. Assigned for real
-- by RefreshActiveProfile() at PLAYER_LOGIN (and again on switching
-- profiles); nil until then, same as the forward-declared `panel`
-- elsewhere in this file.


local function GetCharKey()
    return UnitName("player") .. " - " .. GetRealmName()
end

-- Fills in any key PROFILE_DEFAULTS has that this profile table doesn't
-- (a fresh profile, or one saved by an older version before a setting
-- existed) without touching anything the profile already has set.
local function ApplyProfileDefaults(p)
    for k, v in pairs(PROFILE_DEFAULTS) do
        if p[k] == nil then p[k] = v end
    end
    -- Migrate a save from before multi-tracking existed: the old
    -- single-rare field becomes a one-element list in the new one.
    if p.trackedRareNames == nil and p.trackedRareName then
        p.trackedRareNames = { p.trackedRareName }
    end
    p.trackedRareName = nil
    return p
end

-- Creates PetSmartDB.profiles/profileKeys if this is the first time
-- profiles have existed for this SavedVariables file, seeding "Default"
-- from whatever flat top-level option values already exist (so upgrading
-- from before profiles existed doesn't silently reset anyone's options)
-- before falling back to PROFILE_DEFAULTS for the rest.
local function EnsureProfiles()
    PetSmartDB.profiles = PetSmartDB.profiles or {}
    PetSmartDB.profileKeys = PetSmartDB.profileKeys or {}

    if not PetSmartDB.profiles[DEFAULT_PROFILE_NAME] then
        local seed = {}
        for k, v in pairs(PROFILE_DEFAULTS) do
            seed[k] = (PetSmartDB[k] ~= nil) and PetSmartDB[k] or v
        end
        -- abilitiesPanelPos/Size are nil in PROFILE_DEFAULTS (so pairs()
        -- above never visits them) but still need carrying over from a
        -- pre-profile save if one exists.
        seed.abilitiesPanelPos = PetSmartDB.abilitiesPanelPos
        seed.abilitiesPanelSize = PetSmartDB.abilitiesPanelSize
        -- Tracked-rare state is deliberately NOT carried over from any old
        -- top-level save here, even if one exists - tracking used to be
        -- account-wide, and the freshly-created Default profile should
        -- start with nothing tracked rather than inheriting whatever any
        -- one character happened to be tracking before.
        PetSmartDB.profiles[DEFAULT_PROFILE_NAME] = seed
    end

    local charKey = GetCharKey()
    local assigned = PetSmartDB.profileKeys[charKey]
    if assigned == nil then
        -- This character has never used PetSmart before (no assignment at
        -- all, not even a stale one) - give it its own profile named after
        -- the character instead of dropping it into the shared Default
        -- profile. In Forever, UnitName("player") is the full first-and-
        -- surname name, which is unique account-wide, so it doubles as a
        -- sensible, human-readable profile name.
        local personalName = UnitName("player") or DEFAULT_PROFILE_NAME
        if PetSmartDB.profiles[personalName] then
            -- Extremely unlikely collision (e.g. a profile already made by
            -- that exact name) - disambiguate rather than silently sharing it.
            local n = 2
            while PetSmartDB.profiles[personalName .. " (" .. n .. ")"] do
                n = n + 1
            end
            personalName = personalName .. " (" .. n .. ")"
        end
        local seed = {}
        for k, v in pairs(PROFILE_DEFAULTS) do seed[k] = v end
        -- First time this character has ever used PetSmart: pop the
        -- Compendium panel open, centered on screen, so a brand-new player
        -- actually notices the addon exists instead of only finding it if
        -- they happen to click the toggle icon.
        seed.abilitiesPanelPos = { "CENTER", "CENTER", 0, 0 }
        PetSmartDB.profiles[personalName] = seed
        PetSmartDB.profileKeys[charKey] = personalName
        PetSmartDB.panelShownByChar = PetSmartDB.panelShownByChar or {}
        PetSmartDB.panelShownByChar[charKey] = true
    elseif not PetSmartDB.profiles[assigned] then
        -- Assigned to a profile that no longer exists (e.g. the save got
        -- corrupted) - fall back to Default rather than losing the
        -- assignment entirely. This is a repair path, not a first-time
        -- setup, so it does NOT create another personal profile.
        PetSmartDB.profileKeys[charKey] = DEFAULT_PROFILE_NAME
    end
end

-- Re-points the `profile` upvalue at this character's currently-assigned
-- profile. Called at login and immediately after switching/creating/
-- deleting a profile so every already-open bit of UI starts reading the
-- new one right away.
local function RefreshActiveProfile()
    local charKey = GetCharKey()
    local name = PetSmartDB.profileKeys[charKey] or DEFAULT_PROFILE_NAME
    ns.profile = ApplyProfileDefaults(PetSmartDB.profiles[name] or PetSmartDB.profiles[DEFAULT_PROFILE_NAME])
end

----------------------------------------------------------------------
-- Small helpers / API shims (Mainline-style API with Classic fallbacks)
----------------------------------------------------------------------
local function Print(msg)
    print("|cff33ff99PetSmart:|r " .. tostring(msg))
end

local function GetFeedSpellName()
    if C_Spell and C_Spell.GetSpellName then
        local n = C_Spell.GetSpellName(FEED_PET_SPELL_ID)
        if n then return n end
    end
    if GetSpellInfo then
        local n = GetSpellInfo(FEED_PET_SPELL_ID)
        if type(n) == "string" then return n end
    end
    return FALLBACK_SPELL
end

local function GetFeedSpellIcon()
    local tex
    if C_Spell and C_Spell.GetSpellTexture then
        tex = C_Spell.GetSpellTexture(FEED_PET_SPELL_ID)
    elseif GetSpellTexture then
        tex = GetSpellTexture(FEED_PET_SPELL_ID)
    end
    return tex or FALLBACK_ICON
end

local function NumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    end
    return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

-- returns itemID, icon, stackCount, hyperlink
local function SlotInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then return info.itemID, info.iconFileID, info.stackCount, info.hyperlink end
    elseif GetContainerItemInfo then
        local icon, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
        if link then return tonumber(link:match("item:(%d+)")), icon, count, link end
    end
end

local function ItemClassIDs(itemID)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if f then
        local _, _, _, _, _, classID, subClassID = f(itemID)
        return classID, subClassID
    end
end

local LAST_BAG = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4

-- Midnight (12.x) "secret values": some unit stats (e.g. health) can come
-- back as protected values an addon may display - FontString
-- SetFormattedText, StatusBar values - but not do maths on, compare or
-- concatenate. True when any of the given values is one of those.
function ns.AnySecret(...)
    if not issecretvalue then return false end
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil and issecretvalue(v) then return true end
    end
    return false
end

-- Experience-bar look shared by the pet page's bar and the floating pet
-- XP bar: left-to-right fill gradients (blue while levelling, gold at max).
ns.BAR_COLORS = {
    xp  = { 0.04, 0.18, 0.55, 0.25, 0.62, 1.0 },
    max = { 0.55, 0.38, 0.08, 0.95, 0.75, 0.25 },
}

-- Paints a left-to-right gradient on a status bar's fill. Newer clients
-- take colour objects, older ones plain numbers - try both, falling back
-- to a flat mid colour.
function ns.SetBarGradient(bar, r1, g1, b1, r2, g2, b2)
    local tex = bar:GetStatusBarTexture()
    if not tex then return end
    bar:SetStatusBarColor(1, 1, 1)
    local ok = CreateColor and pcall(tex.SetGradient, tex, "HORIZONTAL", CreateColor(r1, g1, b1, 1), CreateColor(r2, g2, b2, 1))
    if not ok then ok = pcall(tex.SetGradient, tex, "HORIZONTAL", r1, g1, b1, r2, g2, b2) end
    if not ok then bar:SetStatusBarColor((r1 + r2) / 2, (g1 + g2) / 2, (b1 + b2) / 2) end
end

-- Exported for the other PetSmart files.
ns.BUTTON_SIZE = BUTTON_SIZE
ns.COLUMNS = COLUMNS
ns.DEFAULT_PROFILE_NAME = DEFAULT_PROFILE_NAME
ns.EnsureProfiles = EnsureProfiles
ns.GetCharKey = GetCharKey
ns.GetFeedSpellIcon = GetFeedSpellIcon
ns.GetFeedSpellName = GetFeedSpellName
ns.ICON_SIZE_MAX = ICON_SIZE_MAX
ns.ICON_SIZE_MIN = ICON_SIZE_MIN
ns.ItemClassIDs = ItemClassIDs
ns.LAST_BAG = LAST_BAG
ns.MAX_BUTTONS = MAX_BUTTONS
ns.NumSlots = NumSlots
ns.PADDING = PADDING
ns.PROFILE_DEFAULTS = PROFILE_DEFAULTS
ns.Print = Print
ns.RefreshActiveProfile = RefreshActiveProfile
ns.SlotInfo = SlotInfo
ns.defaults = defaults
