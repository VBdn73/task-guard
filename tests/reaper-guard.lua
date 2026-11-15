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
nativeBlocked = false
rules.reaper.Helwyr = true
helwyr.isMouseOver = true
local function menu()
    return {
        entries = { { verbText = "Cancel" }, { verbText = "Select" } },
        Add = function(self, text, callback, taskID)
            assert(type(taskID) == "number" and taskID > 0, "Actions need task-specific user data")
            table.insert(self.entries, 1, { overrideText = text,
                callback = function() callback(taskID) end, dispatch = callback, taskID = taskID })
        end,
        Swap = function(self, a, b) self.entries[a], self.entries[b] = self.entries[b], self.entries[a] end,
    }
end
local actions = menu()
guard.addMenu(actions)
assert(actions.entries[3].verbText == "Select", "Keep the native left-click default last")
assert(actions.entries[2].overrideText == "Disable task")
actions.entries[2].callback()
assert(rules.reaper.Helwyr == false and created.Helwyr.isShown())
actions = menu()
guard.addMenu(actions)
assert(actions.entries[2].overrideText == "Enable task")
PersistentDB.SetStructuredData = function() return false end
actions.entries[2].callback()
assert(rules.reaper.Helwyr == false, "Failed saves must roll back")
PersistentDB.SetStructuredData = function() return true end
actions.entries[2].callback()
assert(rules.reaper.Helwyr == true and not created.Helwyr.isShown())
actions = menu()
guard.addMenu(actions)
nativeBlocked = true
actions.entries[2].callback()
assert(rules.reaper.Helwyr == true, "Recheck requirements when selecting a stale action")
actions = menu()
guard.addMenu(actions)
assert(#actions.entries == 2, "Requirement-blocked tasks must not offer toggles")
nativeBlocked = false
actions = menu()
guard.addMenu(actions)
list.visibleGlobal = false
actions.entries[2].callback()
assert(rules.reaper.Helwyr == true, "Closed dialogs must invalidate menu actions")
guard.remove()
print("Task Guard task menu tests passed")
list.visibleGlobal = true
nativeBlocked = false
helwyr.isMouseOver = false
local barrows, chaos = label("The Barrows Brothers"), label("Chaos Elemental")
choices = { barrows, chaos }
rules.reaper[barrows.content], rules.reaper[chaos.content] = true, true
barrows.isMouseOver = true
local barrowsMenu = menu()
guard.addMenu(barrowsMenu)
barrows.isMouseOver, chaos.isMouseOver = false, true
local chaosMenu = menu()
guard.addMenu(chaosMenu)
local barrowsAction, chaosAction = barrowsMenu.entries[2], chaosMenu.entries[2]
assert(barrowsAction.taskID ~= chaosAction.taskID)
-- Simulate dispatch to retained callbacks: only the matching action may save.
barrowsAction.dispatch(barrowsAction.taskID)
chaosAction.dispatch(barrowsAction.taskID)
assert(rules.reaper[barrows.content] == false)
assert(rules.reaper[chaos.content] == true, "Disabling Barrows must leave Chaos Elemental enabled")
guard.remove()
print("Task Guard independent menu dispatch tests passed")
