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
assert(#tasks == 48 and tasks[1] == "Araxxi" and tasks[2] == "The Barrows Brothers")
assert(tasks[23] == "Gregorovic" and tasks[24] == "Helwyr")
assert(tasks[43] == "The Gate of Elidinis" and tasks[44] == "Amascut, the Devourer")
assert(tasks[47] == "Silverquill, the Dreadhog" and tasks[48] == "The Ghrazi Blood Knights",
    "Default catalogue must match the captured client row order")
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
ui.Margin = { new = function(...) return { ... } end }
for _, kind in ipairs({ "Layer", "Rectangle", "Text", "Check", "Button" }) do ui[kind] = { new = control } end
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, StyleSheet = { CHECKBOX_DEFAULT = 1, BUTTON_DEFAULT = 2 } }
local active, destroyed = 1, false
local pretty = { Tabs = { new = function(_, defs)
    assert(#defs == 3 and defs[1].text == "General" and defs[2].text == "Reaper" and defs[3].text == "Slayer")
    for i = 1, 3 do pages[i] = { content = {}, _scroll = { Refresh = function() end }, SetContentHeight = function() end } end
    return { GetPage = function(_, i) return pages[i] end,
        GetActiveIndex = function() return active end,
        Destroy = function() destroyed = true end }
end } }
pretty.ComboBox = dofile("tests/combo-box-mock.lua")(control)
pretty.CheckboxButton = dofile("tests/checkbox-mock.lua")(control)
local refresh, destroy = require("settings-view").build({ width = 800, height = 600 }, rules, pretty)
assert(#controls == #tasks * 6 + 6)
assert(controls[1].y == controls[7].y and controls[7].ax == 0.5)
assert(controls[13].y == controls[1].y + 40)
for _, c in ipairs(controls) do assert(c.parent ~= pages[3].content) end
local background, switch, hitTarget = controls[3], controls[6], controls[4]
assert(background.rgba == 0x23412DE8 and switch.value)
switch.callbacks[1]()
assert(not rules.reaper[tasks[1]] and not switch.value and background.rgba == 0x492626E8)
assert(hitTarget.callbacks[1]() == false)
assert(rules.reaper[tasks[1]] and switch.value and background.rgba == 0x23412DE8)
local enableAll, allButton = controls[#tasks * 6 + 1], controls[#tasks * 6 + 2]
assert(enableAll.label == "Enable all" and enableAll.y == allButton.y)
assert(enableAll.ax == 0 and allButton.ax == 0.5)
assert(allButton.label == "Disable all")
assert(allButton.callbacks[1]() == false)
for _, name in ipairs(tasks) do assert(rules.reaper[name] == false) end
assert(allButton.label == "Disable all" and not switch.value)
assert(settings.load().reaper[tasks[1]] == false)
enableAll.callbacks[1]()
for _, name in ipairs(tasks) do assert(rules.reaper[name] == true) end
assert(allButton.label == "Disable all" and switch.value)
hitTarget.callbacks[1]()
fail = true
allButton.callbacks[1]()
assert(not rules.reaper[tasks[1]] and rules.reaper[tasks[2]], "Failed bulk saves must restore mixed preferences")
assert(allButton.label == "Disable all" and not switch.value)
local generalStart = #tasks * 6 + 3
local dropdown = controls[generalStart + 1]
local enabledFirst = controls[generalStart + 2].checkbox
local combo = dropdown.combo
assert(combo.contentMargin[2] == 8,
    "Dropdown selection must use the vertical inset for its 30px field")
assert(dropdown.x == 95, "Dropdown must sit close to its label")
assert(controls[generalStart + 3].alignVertical == ui.AlignMode.CENTRE,
    "Checkbox label must be vertically centred")
assert(controls[generalStart].y == dropdown.y and controls[generalStart].alignVertical == ui.AlignMode.CENTRE,
    "Dropdown must sit beside its vertically centred label")
fail = false
combo:Select(2, true)
assert(rules.general.taskOrder == "alphabetical" and settings.load().general.taskOrder == "alphabetical")
assert(controls[1].y > controls[43 * 6 + 1].y, "Alphabetical order must reposition existing cards")
assert(controls[7].y < controls[37].y, "The Barrows Brothers must sort under B, before Dagannoth Kings")
enabledFirst:SetSelected("enabledFirst", true)
assert(rules.general.enabledFirst and settings.load().general.enabledFirst)
assert(controls[1].y >= controls[(#tasks - 1) * 6 + 1].y, "Disabled tasks must follow enabled tasks")
fail = true
enabledFirst:SetSelected("enabledFirst", false)
assert(rules.general.enabledFirst and enabledFirst.selected, "Failed ordering saves must restore preferences")
combo:Select(1, true)
assert(rules.general.taskOrder == "alphabetical" and combo:GetSelectedID() == 2,
    "Failed dropdown saves must restore the displayed selection")
fail = false
combo:Select(3, true)
assert(rules.general.taskOrder == "alphabeticalDescending"
    and settings.load().general.taskOrder == "alphabeticalDescending")
assert(controls[7].y > controls[37].y, "Descending order must put Barrows after Dagannoth Kings")
assert(controls[1].y >= controls[(#tasks - 1) * 6 + 1].y,
    "Descending order must keep disabled tasks after enabled tasks")
fail = true
combo:Select(2, true)
assert(rules.general.taskOrder == "alphabeticalDescending" and combo:GetSelectedID() == 3,
    "Failed saves must restore the descending selection")
fail = false
combo:Select(1, true)
enabledFirst:SetSelected("enabledFirst", false)
assert(rules.general.taskOrder == "default" and not rules.general.enabledFirst)
fail = true
switch.callbacks[1]()
assert(not switch.value and not rules.reaper[tasks[1]])
active = 3; refresh(); assert(controls[1].hidden and allButton.hidden and enableAll.hidden)
destroy(); assert(destroyed and combo.destroyed and enabledFirst.destroyed)
controls = {}
fail = false
local refreshRibbon, destroyRibbon = require("settings-view").build({ width = 300, height = 600 }, rules, pretty, 1)
assert(controls[7].y == controls[1].y + 40 and controls[7].ax == 0)
rules.reaper[tasks[1]] = true
refreshRibbon()
assert(controls[6].value and controls[3].rgba == 0x23412DE8, "Views must reflect shared preferences")
controls[4].callbacks[1]()
assert(not controls[6].value and not rules.reaper[tasks[1]], "Ribbon cards must toggle too")
local ribbonAll = controls[#tasks * 6 + 2]
ribbonAll.callbacks[1]()
for _, name in ipairs(tasks) do assert(rules.reaper[name] == false) end
assert(ribbonAll.label == "Disable all")
controls[#tasks * 6 + 1].callbacks[1]()
for _, name in ipairs(tasks) do assert(rules.reaper[name] == true) end
assert(ribbonAll.label == "Disable all")
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
