--[[-----------------------------------------------------------------------
CallbackHandler-1.0 (fallback copy, bundled with PetSmart)

A minimal, standards-compatible CallbackHandler-1.0: supports the standard
:New/:RegisterCallback/:UnregisterCallback/:UnregisterAllCallbacks/:Fire
surface that LibDataBroker-1.1 (and broker-display addons that talk to it)
expect. Registered under a deliberately LOW minor version so that if any
other addon on the system provides the real, full-featured CallbackHandler-
1.0 (used by Ace3 and dozens of other libraries), LibStub keeps that one
active instead of this one - this copy only matters when nothing else on
the system has already provided it. Public domain, like the original
(Hjortshoej/Hazzard Ace3 team).
-------------------------------------------------------------------------]]
local MAJOR, MINOR = "CallbackHandler-1.0", 1
local CallbackHandler = LibStub:NewLibrary(MAJOR, MINOR)
if not CallbackHandler then return end

local meta = { __index = function(tbl, key) tbl[key] = {} return tbl[key] end }

local function errorhandler(err)
    return geterrorhandler and geterrorhandler()(err) or print(err)
end

local function Dispatch(handlers, ...)
    local index, method = next(handlers)
    if not method then return end
    repeat
        local ok, err = pcall(method, ...)
        if not ok then errorhandler(err) end
        index, method = next(handlers, index)
    until not method
end

function CallbackHandler:New(target, registerName, unregisterName, unregisterAllName)
    target = target or {}
    registerName = registerName or "RegisterCallback"
    unregisterName = unregisterName or "UnregisterCallback"
    if unregisterAllName == nil then
        unregisterAllName = "UnregisterAllCallbacks"
    end

    local events = setmetatable({}, meta)
    local registry = { recurse = 0, events = events }

    target[registerName] = function(self, eventname, method, ...)
        if type(eventname) ~= "string" then
            error("Usage: " .. registerName .. "(eventname, method[, ...]): 'eventname' must be a string.", 2)
        end
        method = method or eventname

        local first = next(events[eventname]) == nil
        if type(method) == "string" then
            if type(self) ~= "table" then
                error("Usage: " .. registerName .. "(eventname, methodname): self was not a table.", 2)
            elseif self == target then
                error("Usage: " .. registerName .. "(eventname, methodname): do not pass self as target.", 2)
            elseif type(self[method]) ~= "function" then
                error("Usage: " .. registerName .. "(eventname, methodname): '" .. tostring(method) .. "' is not a method on self.", 2)
            end
            events[eventname][self] = function(...) return self[method](self, ...) end
        elseif type(method) == "function" then
            events[eventname][self or method] = method
        else
            error("Usage: " .. registerName .. "(eventname, method): 'method' must be a string or function.", 2)
        end

        if registry.OnUsed and first then
            registry.OnUsed(registry, target, eventname)
        end
    end

    target[unregisterName] = function(self, eventname)
        if events[eventname] and events[eventname][self] then
            events[eventname][self] = nil
            if registry.OnUnused and next(events[eventname]) == nil then
                registry.OnUnused(registry, target, eventname)
            end
        end
    end

    if unregisterAllName then
        target[unregisterAllName] = function(self, ...)
            if select("#", ...) == 0 then
                for eventname, handlers in pairs(events) do
                    if handlers[self] then
                        handlers[self] = nil
                        if registry.OnUnused and next(handlers) == nil then
                            registry.OnUnused(registry, target, eventname)
                        end
                    end
                end
            else
                for i = 1, select("#", ...) do
                    local eventname = select(i, ...)
                    if events[eventname] and events[eventname][self] then
                        events[eventname][self] = nil
                        if registry.OnUnused and next(events[eventname]) == nil then
                            registry.OnUnused(registry, target, eventname)
                        end
                    end
                end
            end
        end
    end

    registry.Fire = function(_, eventname, ...)
        if not events[eventname] or not next(events[eventname]) then return end
        local oldrecurse = registry.recurse
        registry.recurse = oldrecurse + 1

        -- snapshot the handler list so Fire is safe against handlers that
        -- register/unregister mid-dispatch
        local snapshot = {}
        for key, method in pairs(events[eventname]) do
            snapshot[key] = method
        end
        Dispatch(snapshot, eventname, ...)

        registry.recurse = oldrecurse
    end

    return registry
end
