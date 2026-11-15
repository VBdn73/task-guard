local current, made
local popupHost = { xyGlobal = { x = 100, y = 100 } }
local parent = { parent = popupHost }
local label = { type = 2, content = "Helwyr", visibleGlobal = true, parent = parent,
    x = 248, y = 263, width = 230, height = 20, xyGlobal = { x = 426, y = 710 } }
current = label
ui = { ComponentType = { LABEL = 2 }, Hook = { ONBUTTONPRESSED = 1, ONMOUSEOVER = 2, ONMOUSELEAVE = 3, ONMOUSEREPEAT = 4 },
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
    made = { visibleGlobal = true, text = text, hooks = {},
        SetPos = function(_, x, y) assert(x == label.x and y == label.y) end,
        SetSize = function(_, w, h) assert(w == 230 and h == 20) end,
        Subscribe = function(self, hook, name, callback) self.hooks[hook] = callback or name end, MoveToFront = function() end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    return made
end
local background, popup
prettyui = { Tooltip = { attach = function(target, host, options)
    assert(target == made)
    assert(host == popupHost, "Popup must render outside the native choice list")
    popup = { options = options, width = 230, height = 60,
        Show = function(self) self.hidden = false end,
        Hide = function(self) self.hidden = true end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    target:Subscribe(ui.Hook.ONMOUSELEAVE, function() popup:Hide() end)
    return popup
end } }
ui.Rectangle = { new = function(host)
    assert(host == parent or host == popup)
    local rectangle = { SetPos = function() end, SetSize = function() end,
        MoveToFront = function() end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    if host == parent then background = rectangle end
    return rectangle
end }
local probe = require("reaper-overlay").new({ label = {
    interfaceID = 1761, staticID = 1, categoryID = 0, dynamicID = 262 } })
assert(probe.show():find("shown", 1, true))
assert(made.enabled == true and made.clickthrough == false)
assert(made.stylesheetID == -1, "Shield must not use animated button styling")
assert(made.text.rgba == 0xBDB8AEFF)
assert(made.label == "Helwyr", "Shield must redraw readable text above the dark background")
assert(background.rgba == 0x00000080, "Blocked row must darken the background at 50% opacity")
assert(popup.hidden and popup.options.placement == "above")
assert(popup.options.constrainToParent == false)
assert(popup.options.x == 326 and popup.options.y == 544)
assert(popup.options.text == "Blocked by Task Guard plugin")
made.hooks[ui.Hook.ONMOUSEOVER]()
assert(not popup.hidden)
Mouse = { GetPosition = function() return { x = 440, y = 415 } end }
parent.scrollY = 300
probe.update()
assert(popup.options.x == 326 and popup.options.y == 244,
    "Tooltip must follow the rendered row despite stale unscrolled xyGlobal")
assert(not popup.hidden, "Repositioning must not change visibility")
Mouse = { GetPosition = function() return { x = 470, y = 420 } end }
probe.update()
assert(popup.options.x == 326 and popup.options.y == 244,
    "Moving the cursor must not move the tooltip")
made.isMouseOver = false
Mouse = { GetPosition = function() return { x = 0, y = 0 } end }
for _ = 1, 5 do
    probe.update()
    assert(not popup.hidden, "Logic ticks must not override PrettyUI hover visibility")
end
made.hooks[ui.Hook.ONMOUSELEAVE]()
assert(popup.hidden, "PrettyUI mouse leave must hide the popup")
Mouse = nil
assert(background.fill and background.clickthrough)
probe.update()
assert(not made.dead)
label.xyGlobal.y = 711
probe.update()
assert(made.dead, "Moving target must remove shield")
assert(background.dead, "Moving target must remove background")
assert(popup.dead, "Moving target must remove hover popup")
probe.remove()
probe.show()
current = nil
probe.update()
assert(made.dead, "Closed dialog must remove shield")
current = label
label.content = "Another boss"
assert(probe.show():find("failed", 1, true))
assert(label.enabled == nil, "Must not mutate native enabled state")
label.content = "Helwyr"
background = nil
local requirementProbe = require("reaper-overlay").new({ name = "Helwyr", requirements = true,
    resolve = function() return label end })
assert(requirementProbe.show():find("shown", 1, true))
assert(made.clickthrough == true and made.label == "", "Requirements hover target must be transparent and click-through")
assert(background == nil, "Preserve the native disabled background")
assert(made.hooks[ui.Hook.ONBUTTONPRESSED] == nil, "Never intercept native clicks in tooltip-only mode")
assert(popup.options.text == "Blocked by requirements")
made.hooks[ui.Hook.ONMOUSEOVER]()
assert(not popup.hidden)
requirementProbe.remove()
assert(made.dead and popup.dead)
print("Task Guard overlay tests passed")
