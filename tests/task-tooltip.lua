local created, destroyed, writes, frontWrites = 0, 0, 0, 0
local host = {}
ui = { Canvas = {}, AlignMode = { CENTRE = 1 }, TextDataConfig = { new = function() return {} end } }
id = { Font = { MUSEO_SANS_15PT_REGULAR = 1 } }
Vector4 = { new = function(...) return { ... } end }
function ui.Canvas.new(parent)
    assert(parent == host)
    created = created + 1
    return setmetatable({
        SetSize = function() end,
        AddRectangle = function() end,
        AddOutline = function() end,
        AddText = function() end,
        MoveToFront = function() frontWrites = frontWrites + 1 end,
        Destroy = function() destroyed = destroyed + 1 end,
    }, { __newindex = function(self, key, value)
        writes = writes + 1
        rawset(self, key, value)
    end })
end
local popup = require("ui/task-tooltip").new(host, { text = "Blocked by Task Guard plugin" })
assert(created == 1, "A tooltip must allocate exactly one canvas and no child components")
popup:Show()
local before = writes
for _ = 1, 100 do popup:Show() end
assert(frontWrites == 1 and writes == before, "Stable hover must not rewrite visibility or front ordering")
popup:Hide()
popup:Hide()
popup:Show()
assert(frontWrites == 2, "Reentering hover must bring the retained popup forward only once")
popup:Destroy()
popup:Destroy()
assert(destroyed == 1, "Popup cleanup must be idempotent")
print("Task Guard lightweight tooltip tests passed")
