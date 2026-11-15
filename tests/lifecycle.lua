-- Run from the project root: lua tests/lifecycle.lua
local handlers = {}
local created, destroyed = 0, 0

local function event()
    local callbacks = {}
    handlers[#handlers + 1] = callbacks
    return {
        Subscribe = function(name, callback)
            assert(callbacks[name] == nil, "Duplicate subscription")
            callbacks[name] = callback
        end,
        Unsubscribe = function(name)
            assert(callbacks[name], "Missing subscription")
            callbacks[name] = nil
        end,
    }
end

Event = { SettingsLayerReady = event(), ContentLayerReady = event() }
Event.Logic = event()
id = { Font = { MUSEO_SANS_15PT_REGULAR = 1 }, StyleSheet = { BUTTON_DEFAULT = 1 } }
ui = { Text = {}, Button = {}, Hook = { ONBUTTONPRESSED = 1 }, ComponentType = { BUTTON = 1 } }

function ui.Text.new(host)
    assert(host, "Expected a host component")
    created = created + 1
    local dead = false
    return {
        SetSize = function() end,
        SetPos = function() end,
        Subscribe = function() end,
        Destroy = function()
            assert(not dead, "View destroyed twice")
            dead = true
            destroyed = destroyed + 1
        end,
    }
end
ui.Button.new = ui.Text.new
package.loaded["settings-view"] = { build = function(host)
    local control = ui.Text.new(host)
    return function() end, function() control:Destroy() end
end }

dofile("main.lua")
assert(type(PluginShutdown) == "function")

local host = {}
handlers[1]["taskGuard.settings"]({ component = host })
handlers[2]["taskGuard.content"]({ component = host })
assert(created == 2 and destroyed == 0)

handlers[1]["taskGuard.settings"]({ component = host })
assert(created == 3 and destroyed == 1, "Reopening must clean up the old view")

PluginShutdown()
assert(destroyed == created, "Shutdown must clean up all views")
for _, callbacks in ipairs(handlers) do
    assert(next(callbacks) == nil, "Shutdown must unsubscribe all events")
end

print("Task Guard lifecycle tests passed")
