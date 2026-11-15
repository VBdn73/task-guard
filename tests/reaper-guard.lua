-- Reconciliation tests; native mouse interception still needs client testing.
local created, removed = {}, {}
PersistentDB = { SetStructuredData = function() return true end }
package.loaded["reaper-overlay"] = { new = function(config)
    local target, shown
    local shield = {
        requirements = config.requirements,
        isShown = function() return shown end,
        show = function() target = config.resolve(); assert(target); shown = true; return "shown" end,
        remove = function() shown = false; removed[config.name] = true end,
        update = function() if target ~= config.resolve() then shown = false end end,
    }
    created[config.name] = shield
    return shield
end }
local list = { visibleGlobal = true }
local traversals = 0
local title = { visibleGlobal = true, type = 2, content = "Pick A task" }
local function label(name)
    return { content = name, type = 2, visibleGlobal = true, parent = list, width = 230, height = 20 }
end
local helwyr, nex = label("Helwyr"), label("Nex")
local choices = { helwyr, nex, label("Unknown task") }
function list:IterateDynamicComponents(callback)
    traversals = traversals + 1
    for _, c in ipairs(choices) do callback(c) end
end
ui = { ComponentType = { LABEL = 2 }, Interfaces = { GetComponent = function(_, interface, static)
    assert(interface == 1761)
    return static == 1 and list or title
end } }
local rules = { reaper = { Helwyr = false, Nex = false } }
local guard = require("reaper-guard").new(rules)
guard.update()
assert(created.Helwyr.isShown() and created.Nex.isShown())
assert(traversals == 1, "All disabled-task checks must share one native list traversal")
assert(rules.reaper["Unknown task"] == true, "New native tasks default to allowed")
rules.reaper["Unknown task"] = false
guard.update()
assert(created["Unknown task"].isShown(), "Discovered tasks must support overlays")
rules.reaper.Helwyr = true
guard.update()
assert(removed.Helwyr and created.Nex.isShown())
rules.reaper.Helwyr = false
guard.update()
assert(created.Helwyr.isShown())
choices[1] = label("Helwyr")
guard.update()
assert(created.Helwyr.isShown(), "Replaced labels must be re-resolved")
choices[#choices + 1] = label("Helwyr")
guard.update()
assert(not created.Helwyr.isShown(), "Ambiguous choices must be untouched")
title.content = "Unrelated dialog"
choices[#choices + 1] = label("Not a Reaper task")
guard.update()
assert(not created.Nex.isShown())
assert(rules.reaper["Not a Reaper task"] == nil, "Never discover from unrelated dialogs")
title.content = "Pick A task"
choices = { helwyr, nex }
guard.update()
assert(created.Nex.isShown())
list.visibleGlobal = false
guard.update()
assert(not created.Nex.isShown())
list.visibleGlobal = true
guard.update()
guard.remove()
assert(not created.Helwyr.isShown() and not created.Nex.isShown())
rules.reaper["Telos"] = false
rules.reaper["Black Stone Dragon"] = false
rules.reaper["Solak, Guardian of the Grove"] = false
choices = { label("Telos"), label("Black Stone Dragon"), label("Solak, Guardian of the Grove") }
guard.update()
assert(created.Telos.isShown(), "Native names must be used directly")
assert(created["Black Stone Dragon"].isShown())
assert(created["Solak, Guardian of the Grove"].isShown())
rules.reaper["Telos"] = true
guard.update()
assert(not created.Telos.isShown(), "Enabling the native-name preference must remove the shield")
guard.remove()
local requirements = require("reaper-requirements")
local nativeBlocked = false
requirements.isBlocked = function() return nativeBlocked end
choices = { helwyr, nex }
rules.reaper.Helwyr = false
guard.update()
assert(created.Helwyr.isShown())
nativeBlocked = true
guard.update()
assert(created.Helwyr.isShown() and created.Helwyr.requirements,
    "Replace blocking overlays with requirement tooltips when the game blocks the row")
assert(rules.reaper.Helwyr == false, "Keep the saved preference")
nativeBlocked = false
guard.update()
assert(created.Helwyr.isShown() and not created.Helwyr.requirements,
    "Restore protection when native blocking disappears")
nativeBlocked = true
rules.reaper.Helwyr = true
guard.update()
assert(created.Helwyr.isShown() and created.Helwyr.requirements,
    "Requirement tooltips must also work for plugin-allowed tasks")
guard.remove()
print("Task Guard reaper guard tests passed")
