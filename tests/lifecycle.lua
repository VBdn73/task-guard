-- Run from the project root: lua tests/lifecycle.lua
local handlers = {}
local created, destroyed = 0, 0
local refreshFails = false
local slayerUpdates, slayerShutdowns = 0, 0
package.loaded["slayer-guard"] = { new = function()
    local stopped = false
    return { menuOpened = function() end, addMenu = function() end, update = function() assert(not stopped); slayerUpdates = slayerUpdates + 1 end,
        shutdown = function() assert(not stopped); stopped = true; slayerShutdowns = slayerShutdowns + 1 end }
end }

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
Event.MiniMenuReady = event()
Event.MiniMenuOpened = event()
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
    return function() assert(not refreshFails, "Disposed host") end, function() control:Destroy() end
end }

dofile("main.lua")
assert(type(PluginShutdown) == "function")

local host = {}
handlers[1]["taskGuard.settings"]({ component = host })
handlers[2]["taskGuard.content"]({ component = host })
assert(created == 2 and destroyed == 0)

handlers[1]["taskGuard.settings"]({ component = host })
assert(created == 3 and destroyed == 1, "Reopening must clean up the old view")

refreshFails = true
handlers[3]["taskGuard.overlay"]()
assert(slayerUpdates == 1, "Logic ticks must update the independent Slayer guard")
assert(destroyed == created, "Failed refreshes must destroy their views")
refreshFails = false
handlers[1]["taskGuard.settings"]({ component = host })
handlers[2]["taskGuard.content"]({ component = host })

PluginShutdown()
PluginShutdown()
assert(slayerShutdowns == 1, "Shutdown must clean up Slayer exactly once")
assert(destroyed == created, "Shutdown must clean up all views")
for _, callbacks in ipairs(handlers) do
    assert(next(callbacks) == nil, "Shutdown must unsubscribe all events")
end

for _ = 1, 3 do
    dofile("main.lua")
    handlers[1]["taskGuard.settings"]({ component = host })
    handlers[2]["taskGuard.content"]({ component = host })
    PluginShutdown()
    assert(destroyed == created, "Repeated reloads must not retain views")
    for _, callbacks in ipairs(handlers) do assert(next(callbacks) == nil) end
end

print("Task Guard lifecycle tests passed")
