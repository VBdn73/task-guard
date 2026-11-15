-- Run from the project root: lua tests/slayer-guard.lua
local made, removed, entries = 0, 0, {}
local freshWrappers = false
local componentMeta = { __eq = function(a, b) return a.nativeID == b.nativeID end }
local saveFails = false
package.loaded["task-settings"] = { save = function() return not saveFails end }
package.loaded["reaper-overlay"] = { new = function(options)
    made = made + 1
    local shown = false
    local entry = { options = options }
    entries[#entries + 1] = entry
    return { show = function() options.resolve(); shown = true end,
        update = function() if shown then options.resolve() end end,
        isShown = function() return shown end,
        remove = function() assert(shown); shown = false; removed = removed + 1 end }
end }
ui = { ComponentType = { LABEL = 2 }, Interfaces = {} }
local function layer(parent, height)
    return { parent = parent, type = 20, visibleGlobal = true, width = 480,
        height = height or 500, x = 0, y = 0, xyGlobal = { x = 100, y = 100 }, children = {},
        IterateDynamicComponents = function(self, callback)
            for _, child in ipairs(self.children) do
                if freshWrappers and child.nativeID then
                    local wrapper = {}
                    for key, value in pairs(child) do wrapper[key] = value end
                    callback(setmetatable(wrapper, componentMeta))
                else callback(child) end
            end
        end }
end
local root = layer()
local container = layer(root)
local viewport = layer(container, 286)
local list, companion = layer(viewport), layer(viewport)
local title = { parent = layer(root), type = 2, visibleGlobal = true, content = "Select your Slayer task" }
local components = { [0] = root, [3] = viewport, [4] = companion, [5] = list, [7] = title }
function ui.Interfaces:GetComponent(interface, static)
    assert(interface == 201, "Slayer guard must never scan other interfaces")
    return components[static]
end
local function row(name, x, y, base)
    local c = { parent = list, type = 2, visibleGlobal = true, content = name,
        x = x, y = y, width = 230, height = 20, xyGlobal = { x = 100 + x, y = 100 + y } }
    c.interfaceID, c.staticID, c.categoryID, c.dynamicID = 201, 5, 0, #list.children
    c.nativeID = c.dynamicID
    setmetatable(c, componentMeta)
    list.children[#list.children + 1] = c
    companion.children[#companion.children + 1] = { parent = companion, type = 2,
        visibleGlobal = true, content = "", x = x, y = y, width = 230, height = 20 }
    for index = 0, 8 do
        local col, r = index % 3 + 1, math.floor(index / 3) + 1
        list.children[#list.children + 1] = { parent = list, type = 3, visibleGlobal = true,
            spriteID = (base or 18468) + index, x = x + ({ 0, 8, 222 })[col],
            y = y + ({ 0, 8, 12 })[r], width = ({ 8, 214, 8 })[col], height = ({ 8, 4, 8 })[r] }
    end
    return c
end
local birds = row("Birds", 8, 5)
row("Cave bugs", 248, 5)
local rules = { slayer = { Birds = false, ["Cave bugs"] = true, ["Ravenous strigoi"] = false } }
local controller = require("slayer-guard").new(rules, {})
local function menu(c)
    local result = { entries = { { verbText = "Cancel" }, { verbText = "Choose", componentData = { component = c } } } }
    function result:Add(text, callback, taskID)
        self.callback, self.taskID = callback, taskID
        self.entries[#self.entries + 1] = { overrideText = text }
    end
    function result:Swap(a, b) self.entries[a], self.entries[b] = self.entries[b], self.entries[a] end
    return result
end
controller.update()
assert(made == 1 and entries[1].options.name == "Birds")
controller.update(); assert(made == 1, "Idle ticks must retain shields")
freshWrappers = true
for _ = 1, 5 do controller.update() end
assert(made == 1 and removed == 0, "Fresh wrappers of the same native row must not churn shields")
rules.slayer.Birds = true
controller.update(); assert(removed == 1)
local action = menu(birds)
controller.addMenu(action)
assert(action.entries[1].overrideText == "Disable task" and action.entries[3].verbText == "Choose")
local prepended = menu(birds)
function prepended:Add(text, callback, taskID)
    self.callback, self.taskID = callback, taskID
    table.insert(self.entries, 1, { overrideText = text })
end
controller.addMenu(prepended)
assert(prepended.entries[1].overrideText == "Disable task"
    and prepended.entries[2].verbText == "Cancel" and prepended.entries[3].verbText == "Choose",
    "Front-inserted plugin actions must preserve native Choose as the left-click default")
action = menu(birds)
controller.addMenu(action)
action.callback(action.taskID)
assert(rules.slayer.Birds, "Hover/left-click menu actions must never toggle preferences")
controller.menuOpened(action)
action.callback(0); assert(rules.slayer.Birds, "Foreign dispatch must do nothing")
saveFails = true
action.callback(action.taskID); assert(rules.slayer.Birds, "Failed save must roll back")
saveFails = false
action = menu(birds)
controller.addMenu(action)
controller.menuOpened(action)
action.callback(action.taskID)
assert(not rules.slayer.Birds, "Menu callbacks must resolve fresh wrappers of the selected native row")
assert(made == 1, "Menu dispatch must not create shields under the active input event")
local enableAction = menu(birds)
controller.addMenu(enableAction)
controller.menuOpened(enableAction)
assert(enableAction.entries[1].overrideText == "Enable task")
enableAction.callback(enableAction.taskID)
assert(rules.slayer.Birds)
assert(removed == 1, "Menu dispatch must not destroy shields under the active input event")
controller.update()
-- Keep later lifecycle counts independent of these extra toggle tests.
made, removed, entries = 1, 1, { entries[1] }
rules.slayer.Birds = false
title.content = "Unrelated dialog"
controller.update(); assert(made == 1)
title.content = "Select your Slayer task"
controller.update(); assert(made == 2)
birds.content = "Abyssal demons"
controller.update(); assert(removed == 2, "Master changes must not reuse old task identity")
rules.slayer["Abyssal demons"] = false
controller.update(); assert(made == 3)
local first = row("Ravenous strigoi", 8, 28)
local second = row("Ravenous strigoi", 248, 28)
controller.update(); assert(made == 5, "Both known duplicate Strigoi rows must share the global preference")
row("Cave bugs", 8, 51)
rules.slayer["Cave bugs"] = false
controller.update(); assert(made == 5, "Other duplicate names must be left untouched")
row("Cows", 248, 51, 18504)
rules.slayer.Cows = true
controller.update(); assert(made == 6 and entries[6].options.requirements,
    "Native blocked rows must use transparent requirement targets, not extra dimming")
local blockedOptions = entries[6].options
assert(blockedOptions.tooltipText:find("personal Slayer block list", 1, true))
Mouse = { GetPosition = function() return { x = 350, y = 155 } end }
assert(blockedOptions.isHovered(), "Native disabled rows need cursor-based hover detection")
Mouse.GetPosition = function() return { x = 350, y = 180 } end
assert(not blockedOptions.isHovered(), "Cursor fallback must stay within the task row")
game = { options = { InterfaceScale = { setting = 150 } } }
Mouse.GetPosition = function() return { x = 525, y = 232.5 } end
assert(blockedOptions.isHovered(), "Raw cursor coordinates must be converted for interface scaling")
game = nil
Mouse.GetPosition = function() return { x = 0, y = 0 } end
companion.children[#companion.children].isMouseOver = true
controller.update()
assert(blockedOptions.isHovered(), "The native companion label must also provide hover detection")
companion.children[#companion.children].isMouseOver = false
Mouse = nil
local blockedMenu = menu(list.children[#list.children - 9])
controller.addMenu(blockedMenu)
assert(not blockedMenu.callback, "Native requirements must not offer toggles")
row("Unknown task", 8, 74)
rules.slayer["Unknown task"] = false
controller.update(); assert(made == 6)
viewport.scrollY = 35
controller.update(); assert(removed == 3, "Fully hidden rows lose shields; partially visible Strigoi rows keep theirs")
viewport.scrollY = 0
controller.update(); assert(made == 7)
companion.width = 400
controller.update(); assert(removed == 7, "Unknown layout must remove every shield")
companion.width = 480
list.children[2].spriteID = 99999
controller.update(); assert(made == 10, "Unknown row artwork must leave that row untouched")
title.isRestricted = true
controller.update(); assert(removed == 10)
title.isRestricted = false
controller.update()
controller.shutdown()
action.callback(action.taskID)
assert(removed == made)
controller.shutdown(); controller.update(); assert(removed == made)
-- Simulate native dispatch retaining actions from multiple previous menu builds,
-- each invoked with its own user data. Only the current action may change rules.
list.children, companion.children = {}, {}
local a = row("Abyssal demons", 8, 5)
local b = row("Adamant dragons", 8, 28)
rules.slayer[a.content], rules.slayer[b.content] = false, false
local dispatchGuard = require("slayer-guard").new(rules, {})
-- A shielded row can have only Cancel. The plugin toggle must NEVER become
-- the default left-click entry, including when entries is a stale snapshot.
local cancelOnly = menu(a)
cancelOnly.entries = { { verbText = "Cancel", componentData = { component = a } } }
dispatchGuard.addMenu(cancelOnly)
assert(cancelOnly.entries[1].overrideText == "Enable task" and cancelOnly.entries[2].verbText == "Cancel",
    "A disabled task's default left-click action must remain Cancel, never Enable")
local snapshotMenu = { entries = { { verbText = "Cancel", componentData = { component = a } } } }
local liveEntries = { snapshotMenu.entries[1] }
function snapshotMenu:Add(text, callback, taskID)
    liveEntries[#liveEntries + 1] = { overrideText = text }
end
function snapshotMenu:Swap(a, b) liveEntries[a], liveEntries[b] = liveEntries[b], liveEntries[a] end
dispatchGuard.addMenu(snapshotMenu)
assert(liveEntries[1].overrideText == "Enable task" and liveEntries[2].verbText == "Cancel",
    "Stale entry snapshots must not leave a toggle as the left-click default")
local firstMenu, secondMenu = menu(a), menu(b)
dispatchGuard.addMenu(firstMenu)
dispatchGuard.menuOpened(firstMenu)
dispatchGuard.addMenu(secondMenu)
dispatchGuard.menuOpened(secondMenu)
firstMenu.callback(firstMenu.taskID)
secondMenu.callback(secondMenu.taskID)
assert(not rules.slayer[a.content] and rules.slayer[b.content],
    "Enabling Adamant must not run an older Abyssal demons callback")
rules.slayer[b.content] = false
secondMenu.callback(secondMenu.taskID)
assert(not rules.slayer[b.content], "A menu selection may save at most once")
-- Match the reported Ascension/Camel sequence: after one explicit menu action,
-- a newly built hover action must not execute when the closing click reaches it.
list.children, companion.children = {}, {}
local ascension = row("Ascension members", 8, 5)
local camel = row("Camel warriors", 8, 28)
rules.slayer[ascension.content], rules.slayer[camel.content] = true, false
local chosenMenu, rebuiltMenu = menu(ascension), menu(camel)
dispatchGuard.addMenu(chosenMenu)
dispatchGuard.menuOpened(chosenMenu)
chosenMenu.callback(chosenMenu.taskID)
dispatchGuard.addMenu(rebuiltMenu)
rebuiltMenu.callback(rebuiltMenu.taskID)
assert(not rules.slayer[ascension.content] and not rules.slayer[camel.content],
    "A closing Ascension menu click must not enable Camel through a rebuilt hover action")
dispatchGuard.shutdown()
-- Captured native-blocked Dagannoth has no visible companion hit label.
list.children, companion.children = {}, {}
local dagannoth = row("Dagannoth", 8, 5, 18504)
companion.children = {}
row("Cave bugs", 248, 5)
local blockedGuard = require("slayer-guard").new({ slayer = { Dagannoth = true } }, {})
local before = made
blockedGuard.update()
assert(made == before + 1 and entries[#entries].options.name == "Dagannoth"
    and entries[#entries].options.requirements,
    "Complete native disabled rows must receive tooltips without companion labels")
local nativeMenu = menu(dagannoth)
blockedGuard.addMenu(nativeMenu)
assert(not nativeMenu.callback, "Native blocks without companions must still reject preference toggles")
blockedGuard.shutdown()
-- Missing companions must not loosen matching for ordinary available rows.
for _, c in ipairs(list.children) do
    if c.type == 3 and c.x < 248 then c.spriteID = c.spriteID - 18504 + 18468 end
end
blockedGuard = require("slayer-guard").new({ slayer = { Dagannoth = false } }, {})
before = made
blockedGuard.update()
assert(made == before, "Available rows must still require a visible companion label")
blockedGuard.shutdown()
print("Experimental Slayer guard tests passed")
