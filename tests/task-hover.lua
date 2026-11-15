local hover = require("ui/task-hover")
local viewport = { xyGlobal = { x = 100, y = 100 }, width = 480, height = 100 }
local list = { parent = viewport, scrollY = 23 }
local row = { parent = list, xyGlobal = { x = 108, y = 128 },
    width = 230, height = 20, visibleGlobal = true, isMouseOver = true }
local mouse = { x = 110, y = 110 }
Mouse = { GetPosition = function() return mouse end }
assert(hover.contains(row, viewport))
list.scrollY = 46
assert(not hover.contains(row, viewport), "Scroll must clear hover even when native flag stays set")
list.scrollY = 23
game = { options = { InterfaceScale = { setting = "200" } } }
mouse = { x = 220, y = 220 }
assert(hover.contains(row, viewport), "Hover must account for interface scaling")
mouse = { x = 220, y = 190 }
assert(not hover.contains(row, viewport), "Rows outside the viewport cannot receive hover")
Mouse = nil
assert(hover.contains(row, viewport) == nil, "Unavailable mouse API must allow hook fallback")
game = nil
local reads = 0
Mouse = { GetPosition = function() reads = reads + 1; return { x = 110, y = 110 } end }
hover.begin()
for _ = 1, 100 do assert(hover.contains(row, viewport)) end
assert(reads == 1, "A guard update must read the pointer once, not once per row or hover check")
list.scrollY = 46
assert(hover.contains(row, viewport), "One reconciliation must retain a consistent geometry snapshot")
hover.finish()
assert(not hover.contains(row, viewport), "Callbacks outside reconciliation must use fresh scroll geometry")
hover.begin()
assert(not hover.contains(row, viewport), "The next update must discard cached row hover")
hover.finish()
print("Task Guard scroll-adjusted hover tests passed")
