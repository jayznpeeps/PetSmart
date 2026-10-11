--[[-----------------------------------------------------------------------
LibDataBroker-1.1 (fallback copy, bundled with PetSmart)

A minimal, standards-compatible LibDataBroker-1.1: data objects created
with :NewDataObject are plain tables (icon/text/type/OnClick/OnEnter/
OnLeave/OnTooltipShow etc, exactly like the original) proxied through a
metatable so attribute writes fire "LibDataBroker_AttributeChanged..."
messages on lib.callbacks, and :DataObjectIterator/:GetDataObjectByName/
:GetNameByDataObject work exactly as broker-display addons (Titan Panel,
Bazooka, ChocolateBar, etc.) expect.

Registered under a deliberately LOW minor version so that if the user has
any other addon that already provides the real LibDataBroker-1.1, LibStub
keeps that one active and this copy sits dormant - this fallback only
matters when nothing else on the system has provided it yet. Public
domain, like the original (written by Tekkub).
-------------------------------------------------------------------------]]
assert(LibStub, "LibDataBroker-1.1 requires LibStub")
assert(LibStub:GetLibrary("CallbackHandler-1.0", true), "LibDataBroker-1.1 requires CallbackHandler-1.0")

local lib, oldminor = LibStub:NewLibrary("LibDataBroker-1.1", 1)
if not lib then return end
oldminor = oldminor or 0

lib.callbacks = lib.callbacks or LibStub:GetLibrary("CallbackHandler-1.0"):New(lib)
lib.attributestorage, lib.namestorage, lib.proxystorage =
    lib.attributestorage or {}, lib.namestorage or {}, lib.proxystorage or {}
local attributestorage, namestorage, proxystorage = lib.attributestorage, lib.namestorage, lib.proxystorage

lib.domt = lib.domt or {
    __metatable = "access denied",
    __index = function(self, key) return attributestorage[self] and attributestorage[self][key] end,
    __newindex = function(self, key, value)
        if not attributestorage[self] then attributestorage[self] = {} end
        local oldvalue = attributestorage[self][key]
        if oldvalue ~= value then
            attributestorage[self][key] = value
            local name = namestorage[self]
            if name then
                lib.callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, self)
                lib.callbacks:Fire("LibDataBroker_AttributeChanged_" .. name, name, key, value, self)
                lib.callbacks:Fire("LibDataBroker_AttributeChanged_" .. key, name, key, value, self)
                lib.callbacks:Fire("LibDataBroker_AttributeChanged_" .. name .. "_" .. key, name, key, value, self)
            end
        end
    end,
}

function lib:NewDataObject(name, dataobj)
    if proxystorage[name] then
        return
    elseif dataobj then
        assert(type(dataobj) == "table", "Invalid dataobj, must be nil or table")
        proxystorage[name] = setmetatable(dataobj, lib.domt)
    else
        proxystorage[name] = setmetatable({}, lib.domt)
    end
    namestorage[proxystorage[name]] = name

    lib.callbacks:Fire("LibDataBroker_DataObjectCreated", name, proxystorage[name])
    return proxystorage[name]
end

function lib:DataObjectIterator()
    return pairs(proxystorage)
end

function lib:GetDataObjectByName(dataobjectname)
    return proxystorage[dataobjectname]
end

function lib:GetNameByDataObject(dataobject)
    return namestorage[dataobject]
end

lib.pairs = lib.pairs or pairs
lib.ipairs = lib.ipairs or ipairs
