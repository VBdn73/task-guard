local current, made
local popupHost = { xyGlobal = { x = 100, y = 100 } }
local parent = { parent = popupHost }
local label = { type = 2, content = "Helwyr", visibleGlobal = true, parent = parent, rgba = 0xD0CDC5FF,
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
assert(made.text.rgba == label.rgba, "Shield text must use the native label colour")
assert(made.label == "Helwyr", "Shield must redraw readable text above the dark background")
assert(background.rgba == 0x181818FF, "Cover must be opaque so native highlights cannot show through")
assert(#artwork == 9)
local xs, ys, widths, heights = { 0, 8, 222 }, { 0, 8, 12 }, { 8, 214, 8 }, { 8, 4, 8 }
for index = 0, 8 do
    local sprite = artwork[index + 1]
    local column, row = index % 3 + 1, math.floor(index / 3) + 1
    assert(sprite.sprite == 18504 + index and sprite.rgba == 0xFFFFFFFF)
    assert(sprite.x == label.x + xs[column] and sprite.y == label.y + ys[row])
    assert(sprite.width == widths[column] and sprite.height == heights[row])
    assert(sprite.clickthrough and sprite.enabled == false)
    sprite.spriteID = sprite.sprite
end
local captured = {}
for _, sprite in ipairs(artwork) do require("reaper-requirements").capture(sprite, parent, captured) end
assert(#captured == 0, "Owned artwork must not be mistaken for native requirements")
assert(not require("reaper-requirements").isBlocked(label, artwork))
made.hooks[ui.Hook.ONBUTTONPRESSED]()
assert(background.rgba == 0x181818FF and made.stylesheetID == -1)
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
for _, sprite in ipairs(artwork) do assert(sprite.dead, "Moving target must remove disabled artwork") end
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
artwork = {}
local requirementProbe = require("reaper-overlay").new({ name = "Helwyr", requirements = true,
    resolve = function() return label end })
assert(requirementProbe.show():find("shown", 1, true))
assert(made.clickthrough == true and made.label == "", "Requirements hover target must be transparent and click-through")
assert(background == nil, "Preserve the native disabled background")
assert(#artwork == 0, "Requirements-only mode must preserve native artwork")
assert(made.hooks[ui.Hook.ONBUTTONPRESSED] == nil, "Never intercept native clicks in tooltip-only mode")
assert(popup.options.text == "Blocked by requirements")
made.hooks[ui.Hook.ONMOUSEOVER]()
assert(not popup.hidden)
requirementProbe.remove()
assert(made.dead and popup.dead)
print("Task Guard overlay tests passed")
