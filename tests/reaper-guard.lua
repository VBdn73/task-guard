-- Reconciliation tests; native mouse interception still needs client testing.
local created, removed = {}, {}
package.loaded["reaper-overlay"] = { new = function(config)
    local target, shown
    local shield = {
        isShown = function() return shown end,
        show = function() target = config.resolve(); assert(target); shown = true; return "shown" end,
        remove = function() shown = false; removed[config.name] = true end,
        update = function() if target ~= config.resolve() then shown = false end end,
    }
    created[config.name] = shield
    return shield
end }
local list = { visibleGlobal = true }
local title = { visibleGlobal = true, type = 2, content = "Pick A task" }
local function label(name)
    return { content = name, type = 2, visibleGlobal = true, parent = list, width = 230, height = 20 }
end
local helwyr, nex = label("Helwyr"), label("Nex")
local choices = { helwyr, nex, label("Unknown task") }
function list:IterateDynamicComponents(callback) for _, c in ipairs(choices) do callback(c) end end
ui = { ComponentType = { LABEL = 2 }, Interfaces = { GetComponent = function(_, interface, static)
    assert(interface == 1761)
    return static == 1 and list or title
end } }
local rules = { reaper = { Helwyr = false, Nex = false } }
local guard = require("reaper-guard").new(rules)
guard.update()
assert(created.Helwyr.isShown() and created.Nex.isShown())
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
guard.update()
assert(not created.Nex.isShown())
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
rules.reaper["Telos, the Warden"] = false
rules.reaper["Black stone dragon"] = false
rules.reaper["Solak, Guardian of the Grove"] = false
choices = { label("Telos"), label("Black Stone Dragon"), label("Solak, Guardian of the Grove") }
guard.update()
assert(created.Telos.isShown(), "Short native names must use the existing saved preference")
assert(created["Black Stone Dragon"].isShown())
assert(created["Solak, Guardian of the Grove"].isShown())
rules.reaper["Telos, the Warden"] = true
guard.update()
assert(not created.Telos.isShown(), "Enabling the canonical preference must remove the alias shield")
guard.remove()
print("Task Guard reaper guard tests passed")
