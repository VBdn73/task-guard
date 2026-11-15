local current, made, frontmost
local buttons = {}
local popupHost = { xyGlobal = { x = 100, y = 100 } }
local parent = { parent = popupHost }
local label = { type = 2, content = "Helwyr", visibleGlobal = true, parent = parent, rgba = 0xD0CDC5FF,
    x = 248, y = 263, width = 230, height = 20, xyGlobal = { x = 426, y = 710 } }
current = label
ui = { ComponentType = { LABEL = 2 }, Hook = { ONBUTTONPRESSED = 1, ONMOUSEOVER = 2, ONMOUSELEAVE = 3, ONMOUSEREPEAT = 4 },
    Interfaces = { GetComponent = function() return current end }, Button = {} }
id = { Font = { MUSEO_SANS_15PT_REGULAR = 1 }, StyleSheet = { BUTTON_DEFAULT = 96 } }
Vector4 = { new = function(r, g, b, a) return { r, g, b, a } end }
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
        Subscribe = function(self, hook, name, callback) self.hooks[hook] = callback or name end,
        MoveToFront = function(self) frontmost = self end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    buttons[#buttons + 1] = made
    return made
end
local background, popup, caption
ui.AlignMode = { CENTRE = 1 }
ui.Text = { new = function(host)
    assert(host == parent)
    caption = { SetPos = function(self, x, y) self.x, self.y = x, y end,
        SetSize = function(self, w, h) self.width, self.height = w, h end,
        MoveToFront = function(self) frontmost = self end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    return caption
end }
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
    popup = { options = options, width = 230, height = 60,
        Show = function(self) self.width, self.height = 230, 60; self.hidden = false end,
        Hide = function(self) self.hidden = true end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    return popup
end } }
ui.Rectangle = { new = function(host)
    assert(host == parent or host == popup)
        local rectangle = { SetPos = function(self, x, y) self.x, self.y = x, y end, SetSize = function() end,
        MoveToFront = function() end,
        Destroy = function(self) assert(not self.dead); self.dead = true end }
    if host == parent then background = rectangle end
    return rectangle
end }
ui.TextDataConfig = { new = function() return {} end }
-- Isolate overlay lifecycle from the renderer, tested in task-tooltip.lua.
package.loaded["ui/task-tooltip"] = { new = function(host, options)
    return prettyui.Tooltip.attach(made, host, options)
end }
ui.Canvas = { new = function(host)
    local canvas = ui.Rectangle.new(host)
    canvas.commands = {}
    function canvas:AddRectangle(...) self.commands[#self.commands + 1] = { kind = "rectangle", ... } end
    function canvas:AddSprite(...) self.commands[#self.commands + 1] = { kind = "sprite", ... } end
    function canvas:AddText(...) self.commands[#self.commands + 1] = { kind = "text", ... } end
    return canvas
end }
local probe = require("ui/task-overlay").new({ name = "Helwyr", resolve = function() return current end })
assert(probe.show():find("shown", 1, true))
assert(made.enabled == true and made.clickthrough == false)
assert(made.stylesheetID == -1, "Shield must not use animated button styling")
assert(made.label == "" and background.label == nil,
    "Neither the shield nor the decoration should draw a button label")
assert(caption == nil, "Canvas text must not allocate a separate decorative text component")
assert(frontmost == made, "Input shield must stay above the decorative text to retain click interception")
assert(#buttons == 1, "Each plugin-disabled row needs only one input button")
assert(#background.commands == 11 and background.commands[1][5] == 0x201F1BFF,
    "One canvas must cover native visuals and draw nine disabled pieces plus static text")
assert(background.commands[2][5] == 18504 and background.commands[10][5] == 18512)
assert(background.commands[11][5] == "Helwyr" and background.commands[11][6].colour[4] == 1)
assert(#artwork == 0, "Disabled rows must not allocate decorative sprites")
assert(require("tasks/requirements").isOwned(made))
assert(require("tasks/requirements").isOwned(background))
local captured = {}
for _, sprite in ipairs(artwork) do require("tasks/requirements").capture(sprite, parent, captured) end
assert(#captured == 0, "Owned artwork must not be mistaken for native requirements")
assert(not require("tasks/requirements").isBlocked(label, artwork))
made.hooks[ui.Hook.ONBUTTONPRESSED]()
assert(background.stylesheetID == nil and made.stylesheetID == -1)
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
made.hooks[ui.Hook.ONMOUSELEAVE]()
parent.scrollY = 301
Mouse = { GetPosition = function() return { x = 0, y = 0 } end }
for _ = 1, 5 do
    probe.update()
    assert(popup.options.y == 244, "Unhovered tooltips must not recalculate position")
    assert(popup.hidden, "Logic ticks must not reopen a tooltip after mouse leave")
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
made.visibleGlobal = false
probe.update()
assert(probe.isShown() and not made.dead and not background.dead,
    "A clipped shield must remain allocated while its verified native row exists")
made.visibleGlobal = true
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
local requirementProbe = require("ui/task-overlay").new({ name = "Helwyr", requirements = true,
    resolve = function() return label end })
assert(requirementProbe.show():find("shown", 1, true))
assert(tooltipCount == 1, "Requirement rows must not allocate tooltips at picker open")
assert(made.clickthrough == false and made.enabled == true and made.label == "",
    "Requirements hover target must receive input without redrawing native text")
assert(background and #background.commands == 11 and background.clickthrough,
    "Native requirement blocks must use the same static canvas as plugin blocks")
assert(#artwork == 0, "Requirements-only mode must preserve native artwork")
assert(made.hooks[ui.Hook.ONBUTTONPRESSED]() == false,
    "Requirements hover target must consume clicks without selecting a task")
made.hooks[ui.Hook.ONMOUSEOVER]()
assert(tooltipCount == 1, "Requirement hover dispatch must defer tooltip attachment")
made.isMouseOver = false
requirementProbe.update()
assert(requirementProbe.isMouseOver(), "Hover events must work even when the native mouse-over property stays false")
assert(popup.options.text == "Blocked by requirements")
assert(not popup.hidden)
assert(tooltipCount == 2, "Only the hovered requirement row should allocate a tooltip")
made.isMouseOver = true
requirementProbe.update()
assert(not popup.hidden, "Requirement popup must remain available while hovered")
made.hooks[ui.Hook.ONMOUSELEAVE]()
assert(popup.hidden, "Leaving a requirement-blocked row must hide its popup")
made.isMouseOver = false
made.hooks[ui.Hook.ONMOUSEREPEAT]()
requirementProbe.update()
assert(not popup.hidden and popup.options.text == "Blocked by requirements",
    "Requirement mouse-repeat events must show the same popup as Reaper hover")
requirementProbe.remove()
assert(made.dead and popup.dead and background.dead)
local cursorHovered = false
local slayerProbe = require("ui/task-overlay").new({ name = "Helwyr", requirements = true,
    tooltipText = "Blocked by in-game requirements or your personal Slayer block list",
    isHovered = function() return cursorHovered end, resolve = function() return label end })
slayerProbe.show()
slayerProbe.update()
assert(tooltipCount == 2, "Unhovered native Slayer blocks must not allocate popups")
cursorHovered = true
slayerProbe.update()
assert(not popup.hidden and popup.options.text:find("personal Slayer block list", 1, true),
    "Cursor fallback must show the Slayer explanation without native hover events")
cursorHovered = false
made.isMouseOver = true -- Native scroll can retain this flag without a leave hook.
slayerProbe.update()
assert(popup.hidden, "Cursor fallback must hide the popup after leaving the row")
assert(not slayerProbe.isMouseOver(), "Stale hover must not make right-click targeting ambiguous")
cursorHovered = true
slayerProbe.update()
assert(not popup.hidden and tooltipCount == 3, "Returning to the row must reuse and reopen its popup")
slayerProbe.remove()
-- All-disabled menus must not multiply styled buttons, text or tooltips.
local many = {}
local beforeButtons, beforeTooltips = #buttons, tooltipCount
for index = 1, 100 do
    local row = require("ui/task-overlay").new({ name = "Helwyr", resolve = function() return label end })
    assert(row.show():find("shown", 1, true))
    many[index] = row
end
assert(#buttons - beforeButtons == 100, "100 disabled rows must allocate only 100 unstyled input buttons")
assert(tooltipCount == beforeTooltips, "An all-disabled menu must not eagerly allocate popups")
-- Idle geometry checks should not cross the native API for global coordinates.
local origin = label.xyGlobal
label.xyGlobal = nil
for _, row in ipairs(many) do
    row.update()
    assert(row.isShown(), "Unhovered rows must not read global geometry")
    row.remove()
end
label.xyGlobal = origin
local staticProbe = require("ui/task-overlay").new({ name = "Helwyr", resolve = function() return label end })
staticProbe.show()
local commands, staticBackground = background.commands, background
label.rgba = 0xFFFFFFFF
made.hooks[ui.Hook.ONBUTTONPRESSED]()
staticProbe.update()
assert(background == staticBackground and background.commands == commands and #commands == 11,
    "Native colour changes and clicks must not rebuild canvas artwork")
assert(commands[11][6].colour[1] == 0.74, "Canvas text colour must not follow native hover colour")
staticProbe.remove()
print("Task Guard overlay tests passed")
