local saved, fail
PersistentDB = {
    GetStructuredData = function() return saved end,
    SetStructuredData = function(_, _, data)
        if fail then return false end
        saved = data
        return true
    end,
}
local settings = require("task-settings")
local tasks = require("reaper-tasks")
local rules = settings.load()
local seen = {}
for _, name in ipairs(tasks) do
    assert(not seen[name]); seen[name] = true
    assert(rules.reaper[name])
end
rules.reaper.Helwyr = false
assert(settings.save(rules))
assert(settings.load().reaper.Helwyr == false)
rules = settings.load()
local controls, pages = {}, {}
local function control(parent)
    local c = { parent = parent, callbacks = {} }
    function c:SetPos(x, y, ax) self.x, self.y, self.ax = x, y, ax end
    function c:SetSize() end
    function c:Subscribe(hook, name, callback) self.callbacks[hook] = callback or name end
    controls[#controls + 1] = c
    return c
end
ui = { Hook = { ONBUTTONPRESSED = 1, ONSCROLLWHEEL = 2 }, AlignMode = { CENTRE = 1 } }
for _, kind in ipairs({ "Layer", "Rectangle", "Text", "Check" }) do ui[kind] = { new = control } end
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, StyleSheet = { CHECKBOX_DEFAULT = 1 } }
local active, destroyed = 1, false
local pretty = { Tabs = { new = function(_, defs)
    assert(#defs == 2 and defs[1].text == "Reaper" and defs[2].text == "Slayer")
    for i = 1, 2 do pages[i] = { content = {}, _scroll = { Refresh = function() end }, SetContentHeight = function() end } end
    return { GetPage = function(_, i) return pages[i] end,
        GetActiveIndex = function() return active end,
        Destroy = function() destroyed = true end }
end } }
local refresh, destroy = require("settings-view").build({ width = 800, height = 600 }, rules, pretty)
assert(#controls == #tasks * 5)
assert(controls[1].y == controls[6].y and controls[6].ax == 0.5)
assert(controls[11].y == controls[1].y + 40)
for _, c in ipairs(controls) do assert(c.parent ~= pages[2].content) end
local background, switch = controls[3], controls[5]
assert(background.rgba == 0x23412DE8 and switch.value)
switch.callbacks[1]()
assert(not rules.reaper[tasks[1]] and not switch.value and background.rgba == 0x492626E8)
fail = true
switch.callbacks[1]()
assert(not switch.value and not rules.reaper[tasks[1]])
active = 2; refresh(); assert(controls[1].hidden)
destroy(); assert(destroyed)
print("Task Guard settings tests passed")
