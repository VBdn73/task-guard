local current, made
local parent = {}
local label = { type = 2, content = "Helwyr", visibleGlobal = true, parent = parent,
    x = 248, y = 263, width = 230, height = 20, xyGlobal = { x = 426, y = 710 } }
current = label
ui = { ComponentType = { LABEL = 2 }, Hook = { ONBUTTONPRESSED = 1 },
    Interfaces = { GetComponent = function() return current end }, Button = {} }
id = { Font = { MUSEO_SANS_15PT_REGULAR = 1 } }
function ui.Button.new(host)
    assert(host == parent)
    local textValues = {}
    local text = setmetatable({}, {
        __index = textValues,
        __newindex = function(_, key, value)
            assert(key == "font" or key == "rgba", "Unsupported TextData property: " .. key)
            textValues[key] = value
        end,
    })
    made = { visibleGlobal = true, text = text,
        SetPos = function(_, x, y) assert(x == label.x and y == label.y) end,
        SetSize = function(_, w, h) assert(w == 230 and h == 20) end,
        Subscribe = function() end, MoveToFront = function() end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    return made
end
local background
ui.Rectangle = { new = function(host)
    assert(host == parent)
    background = { SetPos = function() end, SetSize = function() end,
        MoveToFront = function() end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    return background
end }
local probe = require("reaper-overlay").new({ label = {
    interfaceID = 1761, staticID = 1, categoryID = 0, dynamicID = 262 } })
assert(probe.show():find("shown", 1, true))
assert(made.enabled == true and made.clickthrough == false)
assert(made.stylesheetID == -1, "Shield must not use animated button styling")
assert(made.text.rgba == 0x888888FF)
assert(background.fill and background.clickthrough)
probe.update()
assert(not made.dead)
label.xyGlobal.y = 711
probe.update()
assert(made.dead, "Moving target must remove shield")
assert(background.dead, "Moving target must remove background")
probe.remove()
probe.show()
current = nil
probe.update()
assert(made.dead, "Closed dialog must remove shield")
current = label
label.content = "Another boss"
assert(probe.show():find("failed", 1, true))
assert(label.enabled == nil, "Must not mutate native enabled state")
print("Task Guard overlay tests passed")
