local current, made
local buttons = {}
local popupHost = { xyGlobal = { x = 100, y = 100 } }
local parent = { parent = popupHost }
local label = { type = 2, content = "Helwyr", visibleGlobal = true, parent = parent, rgba = 0xD0CDC5FF,
    x = 248, y = 263, width = 230, height = 20, xyGlobal = { x = 426, y = 710 } }
current = label
ui = { ComponentType = { LABEL = 2 }, Hook = { ONBUTTONPRESSED = 1, ONMOUSEOVER = 2, ONMOUSELEAVE = 3, ONMOUSEREPEAT = 4 },
    Interfaces = { GetComponent = function() return current end }, Button = {} }
id = { Font = { MUSEO_SANS_15PT_REGULAR = 1 }, StyleSheet = { BUTTON_DEFAULT = 96 } }
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
        SetPos = function(self, x, y)
            assert(x == label.x and y == label.y)
            self.x, self.y = x, y
            self.positionWrites = (self.positionWrites or 0) + 1
        end,
        SetSize = function(_, w, h) assert(w == 230 and h == 20) end,
        Subscribe = function(self, hook, name, callback) self.hooks[hook] = callback or name end, MoveToFront = function() end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    buttons[#buttons + 1] = made
    return made
end
local background, popup
local tooltipCount = 0
local artwork = {}
ui.Sprite = { new = function(host)
    assert(host == parent)
    local sprite = { type = 3, parent = host, visibleGlobal = true,
        SetPos = function(self, x, y) self.x, self.y = x, y end,
        SetSize = function(self, w, h) self.width, self.height = w, h end,
        MoveToFront = function() end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    artwork[#artwork + 1] = sprite
    return sprite
end }
prettyui = { Tooltip = { attach = function(target, host, options)
    tooltipCount = tooltipCount + 1
    assert(target == made)
    assert(host == popupHost, "Popup must render outside the native choice list")
    popup = { options = options,
        Show = function(self) self.width, self.height = 230, 60; self.hidden = false end,
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
background = buttons[1]
assert(made.enabled == true and made.clickthrough == false)
assert(made.stylesheetID == -1, "Shield must not use animated button styling")
assert(made.text.rgba == label.rgba, "Shield text must use the native label colour")
assert(made.label == "Helwyr", "Shield must redraw readable text above the dark background")
-- The first button is the disabled decoration; the second is the input shield.
assert(background.stylesheetID == 96 and background.enabled == false)
assert(#artwork == 0, "Disabled rows must not allocate decorative sprites")
assert(require("reaper-requirements").isOwned(made))
assert(require("reaper-requirements").isOwned(background))
local captured = {}
for _, sprite in ipairs(artwork) do require("reaper-requirements").capture(sprite, parent, captured) end
assert(#captured == 0, "Owned artwork must not be mistaken for native requirements")
assert(not require("reaper-requirements").isBlocked(label, artwork))
made.hooks[ui.Hook.ONBUTTONPRESSED]()
assert(background.enabled == false and made.stylesheetID == -1)
assert(popup == nil, "Opening a disabled row must not allocate a tooltip")
made.hooks[ui.Hook.ONMOUSEOVER]()
made.isMouseOver = true
assert(popup.options.placement == "above")
assert(popup.options.constrainToParent == false)
assert(popup.options.x == 326 and popup.options.y == 544)
assert(popup.options.text == "Blocked by Task Guard plugin")
assert(not popup.hidden)
made.hooks[ui.Hook.ONMOUSEOVER]()
assert(tooltipCount == 1, "Repeated hover must reuse the row's tooltip")
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
parent.scrollY = 301
Mouse = { GetPosition = function() return { x = 0, y = 0 } end }
for _ = 1, 5 do
    probe.update()
    assert(popup.options.y == 244, "Unhovered tooltips must not recalculate position")
    assert(not popup.hidden, "Logic ticks must not override PrettyUI hover visibility")
end
made.hooks[ui.Hook.ONMOUSELEAVE]()
assert(popup.hidden, "PrettyUI mouse leave must hide the popup")
Mouse = nil
assert(background.clickthrough)
probe.update()
assert(not made.dead)
label.xyGlobal.y = 711
probe.update()
assert(not made.dead and not background.dead and not popup.dead,
    "Moving the same row must reuse its shield, background and tooltip")
local count, positions = #buttons, made.positionWrites
probe.update()
assert(#buttons == count and made.positionWrites == positions, "Stable overlays must not rewrite positions")
label.x, label.y = 8, 10
probe.update()
assert(not made.dead and made.x == 8 and made.y == 10 and background.x == 8 and background.y == 10,
    "Existing shield and background must follow a reordered task")
assert(#buttons == count and tooltipCount == 1, "Reordering must not rebuild owned controls")
probe.remove()
assert(made.dead and background.dead and popup.dead)
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
artwork = {}
local requirementProbe = require("reaper-overlay").new({ name = "Helwyr", requirements = true,
    resolve = function() return label end })
assert(requirementProbe.show():find("shown", 1, true))
assert(made.clickthrough == false and made.enabled == true and made.label == "",
    "Requirements hover target must receive input without redrawing native text")
assert(background == nil, "Preserve the native disabled background")
assert(#artwork == 0, "Requirements-only mode must preserve native artwork")
assert(made.hooks[ui.Hook.ONBUTTONPRESSED]() == false,
    "Requirements hover target must consume clicks without selecting a task")
made.hooks[ui.Hook.ONMOUSEOVER]()
assert(popup.options.text == "Blocked by requirements")
assert(not popup.hidden)
assert(tooltipCount == 2, "Requirement tooltips must also be allocated only on hover")
made.isMouseOver = true
requirementProbe.update()
assert(not popup.hidden, "Requirement popup must remain available while hovered")
made.hooks[ui.Hook.ONMOUSELEAVE]()
assert(popup.hidden, "Leaving a requirement-blocked row must hide its popup")
requirementProbe.remove()
assert(made.dead and popup.dead)
print("Task Guard overlay tests passed")
