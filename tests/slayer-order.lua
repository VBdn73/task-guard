-- Run from the project root: lua tests/slayer-order.lua
local root = { visibleGlobal = true }
local container = { parent = root }
local viewport = { parent = container, type = 20, width = 480, visibleGlobal = true }
local function list()
    return { parent = viewport, type = 20, x = 0, y = 0, width = 480, height = 677,
        visibleGlobal = true, children = {}, IterateDynamicComponents = function(self, callback)
            for _, c in ipairs(self.children) do callback(c) end
        end }
end
local native, companion = list(), list()
local title = { parent = container, type = 2, content = "Select your Slayer task", visibleGlobal = true }
local components = { [0] = root, [3] = viewport, [4] = companion, [5] = native, [7] = title }
ui = { Interfaces = { GetComponent = function(_, interface, static)
    assert(interface == 201)
    return components[static]
end } }
local function component(parent, kind, x, y, width, height, content, sprite)
    local c = { parent = parent, type = kind, x = x, y = y, width = width, height = height,
        content = content, spriteID = sprite, visibleGlobal = true, moves = 0 }
    function c:SetPos(x, y) self.x, self.y, self.moves = x, y, self.moves + 1 end
    parent.children[#parent.children + 1] = c
    return c
end
local function row(name, x, y, blocked)
    for part = 0, 8 do
        local col, band = part % 3 + 1, math.floor(part / 3) + 1
        component(native, 3, x + ({ 0, 8, 222 })[col], y + ({ 0, 8, 12 })[band],
            ({ 8, 214, 8 })[col], ({ 8, 4, 8 })[band], nil, (blocked and 18504 or 18468) + part)
    end
    component(native, 2, x, y, 230, 20, "")
    component(companion, 2, x, y, 230, 20, "")
    return component(native, 2, x, y, 230, 20, name)
end
local wolves = row("Wolves", 8, 5)
local birds = row("Birds", 248, 5, true)
local raven1 = row("Ravenous strigoi", 8, 28)
local raven2 = row("Ravenous strigoi", 248, 28)
local rules = { general = { taskOrder = "alphabetical", enabledFirst = false },
    slayer = { Wolves = true, Birds = false, ["Ravenous strigoi"] = true } }
local order = require("slayer-order").new(rules)
order.update()
assert(birds.x == 8 and birds.y == 5 and wolves.x == 248 and wolves.y == 28)
assert(raven1.x == 248 and raven1.y == 5 and raven2.x == 8 and raven2.y == 28,
    "Known duplicate rows must retain stable ordering")
local moves = wolves.moves
order.update()
assert(wolves.moves == moves, "Idle updates must not move rows")
rules.general.taskOrder = "alphabeticalDescending"
order.update()
assert(wolves.x == 8 and wolves.y == 5 and birds.y == 28)
rules.general.enabledFirst = true
rules.slayer.Birds = true
order.update()
assert(birds.y == 28 and birds.x == 248,
    "Game-blocked tasks must sort after available tasks even when plugin-enabled")
-- Becoming available must invalidate sorting without a preference change.
for _, c in ipairs(native.children) do
    if c.type == 3 and c.spriteID >= 18504 and c.spriteID <= 18512 then
        c.spriteID = c.spriteID - 18504 + 18468
    end
end
rules.general.taskOrder = "alphabetical"
order.update()
assert(birds.x == 8 and birds.y == 5, "Newly available tasks must rejoin enabled tasks")
for _, c in ipairs(native.children) do
    if c.type == 3 and c.x >= birds.x and c.x < birds.x + 230
        and c.y >= birds.y and c.y < birds.y + 20 then
        c.spriteID = c.spriteID - 18468 + 18504
    end
end
order.update()
assert(birds.x == 248 and birds.y == 28, "Live requirement changes must trigger sorting")
rules.general.taskOrder = "alphabeticalDescending"
rules.slayer.Wolves = false
order.update()
assert(raven1.x == 8 and raven1.y == 5 and raven2.x == 248 and raven2.y == 5)
rules.general.taskOrder, rules.general.enabledFirst = "default", false
order.update()
assert(wolves.x == 8 and wolves.y == 5 and birds.x == 248 and birds.y == 5)
rules.general.taskOrder = "alphabetical"
order.update()
title.visibleGlobal = false
order.update()
assert(wolves.x == 8 and wolves.y == 5, "Closure must restore native positions")
title.visibleGlobal = true
order.update()
order.restore()
assert(birds.x == 248 and birds.y == 5, "Shutdown must restore native positions")
-- Reject unknown/incomplete layouts before any movement.
local unknown = row("Unknown task", 8, 51)
moves = wolves.moves
order = require("slayer-order").new(rules)
order.update()
assert(unknown.moves == 0 and wolves.moves == moves)
print("Task Guard native Slayer ordering tests passed")
