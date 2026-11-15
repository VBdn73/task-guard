local requirements = require("tasks/requirements")
local parent, choices = {}, {}
function parent:IterateDynamicComponents(callback)
    for _, c in ipairs(choices) do callback(c) end
end
local label = { parent = parent, x = 248, y = 263, width = 230, height = 20 }
local function background(base)
    choices = {}
    local xs, ys, widths, heights = { 0, 8, 222 }, { 0, 8, 12 }, { 8, 214, 8 }, { 8, 4, 8 }
    for index = 0, 8 do
        local col, row = index % 3 + 1, math.floor(index / 3) + 1
        choices[#choices + 1] = { parent = parent, visibleGlobal = true, type = 3,
            spriteID = base + index, x = label.x + xs[col], y = label.y + ys[row],
            width = widths[col], height = heights[row] }
    end
end
background(18468)
assert(not requirements.isBlocked(label), "Normal row must retain protection")
background(18477)
assert(not requirements.isBlocked(label), "Hover row must retain protection")
background(18504)
assert(requirements.isBlocked(label))
local snapshot = {}
for _, c in ipairs(choices) do requirements.capture(c, parent, snapshot) end
local iterate = parent.IterateDynamicComponents
parent.IterateDynamicComponents = function() error("Unexpected repeated native traversal") end
assert(requirements.isBlocked(label, snapshot), "Snapshot checks must not traverse native UI")
parent.IterateDynamicComponents = iterate
choices[9] = nil
assert(not requirements.isBlocked(label), "Partial row is not proof")
background(18504)
choices[10] = choices[1]
assert(not requirements.isBlocked(label), "Duplicate pieces are ambiguous")
background(18504)
choices[1].x = choices[1].x + 1
assert(not requirements.isBlocked(label), "Require matching piece geometry")
background(18504)
choices[1].isRestricted = true
assert(not requirements.isBlocked(label))
background(18504)
label.width = 231
assert(not requirements.isBlocked(label), "Unknown scaling retains protection")
assert(not requirements.isBlocked({}), "Unavailable data retains protection")
print("Task Guard native requirements tests passed")
