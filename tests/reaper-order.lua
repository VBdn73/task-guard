-- Native actions and rendering still require live-client verification.
local requirements = require("reaper-requirements")
local list, alternate, title, native, companions
local function setup()
    native, companions = {}, {}
    local parent = {}
    list = { parent = parent, x = 0, y = 0, width = 480, height = 677, visibleGlobal = true }
    alternate = { parent = parent, x = 0, y = 0, width = 480, height = 677, visibleGlobal = true }
    function list:IterateDynamicComponents(callback) for _, c in ipairs(native) do callback(c) end end
    function alternate:IterateDynamicComponents(callback) for _, c in ipairs(companions) do callback(c) end end
    title = { type = 2, content = "Pick A task", visibleGlobal = true }
end
local function component(parent, kind, x, y, w, h, text, sprite)
    local c = { parent = parent, type = kind, x = x, y = y, width = w, height = h,
        visibleGlobal = true, content = text, spriteID = sprite, moves = 0 }
    function c:SetPos(newX, newY) self.x, self.y, self.moves = newX, newY, self.moves + 1 end
    return c
end
local function row(name, x, y, blocked)
    local result = {}
    for part = 0, 8 do
        local column, band = part % 3 + 1, math.floor(part / 3) + 1
        local c = component(list, 3, x + ({ 0, 8, 222 })[column], y + ({ 0, 8, 12 })[band],
            ({ 8, 214, 8 })[column], ({ 8, 4, 8 })[band], nil, (blocked and 18504 or 18468) + part)
        native[#native + 1], result[#result + 1] = c, c
    end
    local label = component(list, 2, x, y, 230, 20, name)
    native[#native + 1], result[#result + 1] = label, label
    local empty = component(list, 2, x, y, 230, 20, "")
    native[#native + 1], result[#result + 1] = empty, empty
    local companion = component(alternate, 2, x, y, 230, 20, "")
    companions[#companions + 1], result[#result + 1] = companion, companion
    return result, label
end
setup()
ui = { Interfaces = { GetComponent = function(_, _, static)
    if static == 0 then return alternate elseif static == 1 then return list else return title end
end } }
local helwyr, helwyrLabel = row("Helwyr", 8, 10)
local araxxi, araxxiLabel = row("Araxxi", 248, 10, true)
local owned = component(list, 9, 8, 10, 230, 20)
requirements.markOwned(owned)
native[#native + 1] = owned
local rules = { general = { taskOrder = "alphabetical", enabledFirst = false },
    reaper = { Helwyr = true, Araxxi = false } }
local order = require("reaper-order").new(rules)
order.update()
assert(helwyrLabel.x == 248 and araxxiLabel.x == 8, "Alphabetical ordering must swap complete rows")
for _, c in ipairs(helwyr) do assert(c.x >= 248 and c.x < 478 and c.moves == 1) end
assert(owned.moves == 0, "Do not move plugin-owned overlays as native controls")
local moves = helwyrLabel.moves
local sort, sorts = table.sort, 0
table.sort = function(...) sorts = sorts + 1; return sort(...) end
order.update()
table.sort = sort
assert(helwyrLabel.moves == moves, "Unchanged preferences must not rewrite positions")
assert(sorts == 0, "Unchanged native preferences must not sort rows every tick")
rules.general.taskOrder = "alphabeticalDescending"
order.update()
assert(helwyrLabel.x == 8 and araxxiLabel.x == 248, "Descending ordering must reverse alphabetical rows")
rules.general.taskOrder = "alphabetical"
order.update()
rules.general.enabledFirst = true
order.update()
assert(helwyrLabel.x == 8 and araxxiLabel.x == 248, "Enabled-first must take priority over alphabetic order")
rules.reaper.Helwyr, rules.reaper.Araxxi = false, true
order.update()
assert(araxxiLabel.x == 8)
rules.general.taskOrder = "alphabeticalDescending"
order.update()
assert(araxxiLabel.x == 8, "Enabled-first must also take priority over descending order")
rules.general.taskOrder, rules.general.enabledFirst = "default", false
order.update()
assert(helwyrLabel.x == 8 and araxxiLabel.x == 248, "Client default must restore original positions")
rules.general.taskOrder = "alphabetical"
order.update()
title.visibleGlobal = false
order.update()
assert(helwyrLabel.x == 8, "Dialog closure must restore surviving native components")
title.visibleGlobal = true
order.update()
order.restore()
assert(helwyrLabel.x == 8 and araxxiLabel.x == 248, "Shutdown restoration")
-- Refuse an unknown native component before moving any row.
setup()
local _, first = row("Helwyr", 8, 10)
row("Araxxi", 248, 10)
native[#native + 1] = component(list, 9, 8, 10, 230, 20)
order = require("reaper-order").new(rules)
order.update()
assert(first.moves == 0, "Unrecognised native components must leave the picker untouched")
-- Refuse partial backgrounds and duplicate names.
setup()
local _, partial = row("Helwyr", 8, 10)
row("Araxxi", 248, 10)
table.remove(native, 1)
order = require("reaper-order").new(rules)
order.update()
assert(partial.moves == 0)
setup()
local _, duplicate = row("Helwyr", 8, 10)
row("Helwyr", 248, 10)
order = require("reaper-order").new(rules)
order.update()
assert(duplicate.moves == 0)
-- External client changes must not be overwritten during cleanup.
setup()
local _, changed = row("Helwyr", 8, 10)
row("Araxxi", 248, 10)
order = require("reaper-order").new(rules)
order.update()
changed.x = 99
order.update()
assert(changed.x == 99, "Preserve external native layout changes")
-- If one position write fails, undo the earlier successful writes.
setup()
local originalRow, originalLabel = row("Helwyr", 8, 10)
local otherRow, otherLabel = row("Araxxi", 248, 10)
function originalLabel:SetPos() error("Native position write rejected") end
order = require("reaper-order").new(rules)
order.update()
assert(originalRow[1].x == 8 and otherRow[1].x == 248 and otherLabel.x == 248,
    "Partial ordering failure must restore earlier writes")
print("Task Guard native task ordering tests passed")
