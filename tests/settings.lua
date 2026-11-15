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
for _, kind in ipairs({ "Layer", "Rectangle", "Text", "Check", "Button" }) do ui[kind] = { new = control } end
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
assert(#controls == #tasks * 6)
assert(controls[1].y == controls[7].y and controls[7].ax == 0.5)
assert(controls[13].y == controls[1].y + 40)
for _, c in ipairs(controls) do assert(c.parent ~= pages[2].content) end
local background, switch, hitTarget = controls[3], controls[6], controls[4]
assert(background.rgba == 0x23412DE8 and switch.value)
switch.callbacks[1]()
assert(not rules.reaper[tasks[1]] and not switch.value and background.rgba == 0x492626E8)
assert(hitTarget.callbacks[1]() == false)
assert(rules.reaper[tasks[1]] and switch.value and background.rgba == 0x23412DE8)
hitTarget.callbacks[1]()
fail = true
switch.callbacks[1]()
assert(not switch.value and not rules.reaper[tasks[1]])
active = 2; refresh(); assert(controls[1].hidden)
destroy(); assert(destroyed)
controls = {}
fail = false
local refreshRibbon, destroyRibbon = require("settings-view").build({ width = 300, height = 600 }, rules, pretty, 1)
assert(controls[7].y == controls[1].y + 40 and controls[7].ax == 0)
rules.reaper[tasks[1]] = true
refreshRibbon()
assert(controls[6].value and controls[3].rgba == 0x23412DE8, "Views must reflect shared preferences")
controls[4].callbacks[1]()
assert(not controls[6].value and not rules.reaper[tasks[1]], "Ribbon cards must toggle too")
destroyRibbon()
local count = #tasks
assert(settings.discover(rules, { "New Reaper Boss", "New Reaper Boss", "<invalid>" }))
assert(#tasks == count + 1 and rules.reaper["New Reaper Boss"] == true)
rules.reaper["New Reaper Boss"] = false
assert(settings.save(rules))
assert(settings.load().reaper["New Reaper Boss"] == false, "Discovered preferences survive reloads")
fail = true
assert(not settings.discover(rules, { "Unsaved Boss" }))
assert(#tasks == count + 1 and rules.reaper["Unsaved Boss"] == nil)
fail = false
saved = { reaper = { ["Telos, the Warden"] = false, ["Black stone dragon"] = false,
    ["Giant mole"] = false }, discovered = { "Telos, the Warden", "Black stone dragon", "Giant mole" } }
local migrated = settings.load()
assert(migrated.reaper.Telos == false and migrated.reaper["Black Stone Dragon"] == false
    and migrated.reaper["Giant Mole"] == false)
assert(migrated.reaper["Telos, the Warden"] == nil and migrated.reaper["Black stone dragon"] == nil)
assert(saved.nameVersion == 2 and saved.reaper["Telos, the Warden"] == nil)
for _, name in ipairs(tasks) do
    assert(name ~= "Telos, the Warden" and name ~= "Black stone dragon" and name ~= "Giant mole")
end
assert(settings.load().reaper.Telos == false, "Migrated preferences must survive subsequent loads")
print("Task Guard settings tests passed")
