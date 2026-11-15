-- Run from the project root: lua tests/cleanup.lua
local loaded = true
ui = { Interfaces = { GetInterface = function(_, interfaceID)
    assert(interfaceID == 201)
    return loaded and {} or nil
end } }
local cleanup = require("ui/cleanup")
local parent = {}
local function component()
    return { interfaceID = 201, parent = parent, destroys = 0,
        Destroy = function(self) self.destroys = self.destroys + 1 end }
end
local live = component()
local destroy = cleanup.owned(live)
destroy(); destroy()
assert(live.destroys == 1, "Live controls must be destroyed exactly once")
local unloaded = component()
destroy = cleanup.owned(unloaded)
loaded = false
destroy()
loaded = true
destroy()
assert(unloaded.destroys == 0, "Unloaded controls must not be retried after reopening")
local restricted = component()
destroy = cleanup.owned(restricted)
restricted.isRestricted = true
destroy()
assert(restricted.destroys == 0)
local moved = component()
destroy = cleanup.owned(moved)
moved.parent = {}
destroy()
assert(moved.destroys == 0, "Reparented controls no longer belong to the captured host")
local child = component()
destroy = cleanup.owned(child)
parent.isRestricted = true
destroy()
assert(child.destroys == 0)
parent.isRestricted = false
local invalid = setmetatable({}, { __index = function() error("Disposed handle") end })
-- A handle captured alive may later start throwing on property access.
local stale = component()
destroy = cleanup.owned(stale)
stale.interfaceID, stale.parent = nil, nil
setmetatable(stale, getmetatable(invalid))
destroy()
assert(rawget(stale, "destroys") == 0)
print("Task Guard owned UI cleanup tests passed")
