-- Run from the project root: lua tests/settings-view.lua
local tasks = { "Short", "Longest boss name", "Third", "Fourth", "Fifth", "Sixth" }
package.loaded["tasks/reaper/catalogue"] = tasks
local longSlayerName = "A very long slayer task name that should wrap across multiple lines"
package.loaded["tasks/slayer/catalogue"] = { "Slayer one", longSlayerName }
package.loaded["tasks/settings"] = { save = function() return true end }
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, StyleSheet = { CHECKBOX_DEFAULT = 1, BUTTON_DEFAULT = 2 } }
config = { Font = { FromID = function()
    return { GetStringWidth = function(_, name) return name == tasks[2] and 200 or #name * 7 end }
end } }
local layers, labels, buttons, inputs = {}, {}, {}, {}
local function control(parent)
    return { parent = parent, SetPos = function(self, ...)
            self.pos = { ... }; self.positionWrites = (self.positionWrites or 0) + 1
        end,
        SetSize = function(self, ...) self.size = { ... } end,
        Subscribe = function(self, hook, name, callback)
            self.callbacks = self.callbacks or {}
            self.callbacks[hook] = callback or name
        end, Setup = function() end }
end
ui = { Hook = { ONSCROLLWHEEL = 1, ONBUTTONPRESSED = 2 }, AlignMode = { CENTRE = 1 } }
ui.Margin = { new = function(...) return { ... } end }
ui.TextContentVisibilityMode = { VISIBLE = 1 }
ui.InputFieldFilterMode = { NONE = 1 }
for _, kind in ipairs({ "Layer", "Rectangle", "Button", "Text", "Check", "InputField" }) do
    ui[kind] = { new = function(parent)
        local result = control(parent)
        if kind == "Layer" then layers[#layers + 1] = result end
        if kind == "Text" then labels[#labels + 1] = result end
        if kind == "Button" then buttons[#buttons + 1] = result end
        if kind == "InputField" then inputs[#inputs + 1] = result end
        if kind == "InputField" then
            setmetatable(result, { __newindex = function(self, key, value)
                assert(key ~= "font", "Native InputField does not expose a font property")
                rawset(self, key, value)
            end })
        end
        return result
    end }
end
local host = { width = 800, height = 240 }
local pages, active, destroyed = {}, 1, false
local definitions, tabOptions
local pretty = { Tabs = { new = function(_, defs, options)
    tabOptions = options
    active = options.activeIndex or 1
    definitions = defs
    pages = {}
     for i = 1, #defs do
        local page = { content = {}, contentHeight = 0 }
        local function refresh()
            page.scrollbarVisible = page.contentHeight > host.height - 80
            page.content.width = host.width - (page.scrollbarVisible and 18 or 0)
            page._scroll.contentWidth = page.content.width
        end
        page._scroll = { Refresh = refresh }
        function page:SetContentHeight(value) self.contentHeight = value; refresh() end
        function page:ScrollBy() end
        refresh()
        pages[i] = page
    end
    return { GetPage = function(_, i) return pages[i] end,
        GetActiveIndex = function() return active end,
        Destroy = function() destroyed = true end }
end } }
pretty.ComboBox = require("tests/support/combo-box-mock")(control)
pretty.CheckboxButton = require("tests/support/checkbox-mock")(control)
local rules = { reaper = {} }
for _, name in ipairs(tasks) do rules.reaper[name] = true end
local view = require("ui/settings-view")
local refresh, destroy = view.build(host, rules, pretty, "auto")
local function assertButtonColumns()
    local first = 1
    for _, button in ipairs(buttons) do
        if button.label == "Enable all" or button.label == "Disable all" then
            local card = layers[first]
            assert(button.size[1] == card.size[1] and button.size[3] == card.size[3],
                "Bulk buttons must have exactly the task column width")
            if button.label == "Disable all" then first = #tasks + 1 end
        end
    end
end
assertButtonColumns()
local information = labels[#labels]
assert(information.content:find("does not block", 1, true), "General tab must explain that tasks are not blocked")
assert(information.content:gsub("<br>", " "):find("accidental clicks", 1, true),
    "General tab must explain accidental-click protection")
assert(layers[1].size[3] == 1 / 3, "Wide ribbon should fit three columns")
assert(layers[4].pos[2] == 126 and pages[2].contentHeight == 174)
local writes = layers[1].positionWrites
for _ = 1, 10 do refresh() end
assert(layers[1].positionWrites == writes, "Idle view refreshes must not relayout cards")
host.width = 540
refresh()
assertButtonColumns()
assert(layers[1].size[3] == 1 / 2, "Resize should fit two columns")
assert(layers[#tasks + 1].size[3] == 1 / 2,
    "A long Slayer name must not prevent two columns")
assert(labels[#tasks + 2].content:find("<br>", 1, true), "Long Slayer names must use client line breaks")
assert(layers[#tasks + 2].size[2] > 36, "Wrapped cards must grow to fit their labels")
host.width = 520
refresh()
assertButtonColumns()
assert(layers[1].size[3] == 1, "Scrollbar width must be included at a column threshold")
host.width = 300
refresh()
assertButtonColumns()
assert(layers[2].pos[2] == 160, "Narrow settings should have one column below stacked buttons")
assert(buttons[#tasks + 1].pos[2] == 8 and buttons[#tasks + 2].pos[2] == 42,
    "Single-column bulk buttons must stack without overlapping")
assert(inputs[1].pos[2] == 81, "Single-column search must sit below both bulk buttons")
host.width = 1100
refresh()
assertButtonColumns()
assert(layers[1].size[3] == 1 / 4, "Growing the ribbon should add columns again")
local cardWidth = pages[2]._scroll.contentWidth / 4 + layers[1].size[1]
local secondCardRight = layers[2].pos[1] + layers[2].pos[3] * pages[2]._scroll.contentWidth + cardWidth
assert(inputs[1].pos[1] + inputs[1].size[1] == secondCardRight,
    "Search must align exactly with the right edge of the second task column")
assert(inputs[1].pos[2] - (buttons[#tasks + 1].pos[2] + 30)
    == layers[1].pos[2] - (inputs[1].pos[2] + 30),
    "Search must have equal spacing above and below")
active = 3
refresh()
assert(layers[1].hidden)
assert(not layers[#tasks + 1].hidden and pages[3].contentHeight > 0,
    "Slayer tab must show its own task cards")
active = 2
refresh()
assert(not layers[1].hidden)
assert(#inputs == 2, "Settings must have separate Reaper and Slayer search fields")
inputs[1].content = "  LONGEST  "
refresh()
assert(layers[1].hidden and not layers[2].hidden and layers[3].hidden,
    "Search must filter case-insensitively and trim whitespace")
assert(layers[2].pos[2] == 86, "Search results must pack into the first row")
buttons[#tasks + 2].callbacks[ui.Hook.ONBUTTONPRESSED]()
assert(not rules.reaper[tasks[2]] and rules.reaper[tasks[1]] and rules.reaper[tasks[3]],
    "Disable all must only change search matches")
buttons[#tasks + 1].callbacks[ui.Hook.ONBUTTONPRESSED]()
assert(rules.reaper[tasks[2]], "Enable all must restore matching tasks")
inputs[1].content = "no match"
buttons[#tasks + 2].callbacks[ui.Hook.ONBUTTONPRESSED]()
for _, name in ipairs(tasks) do assert(rules.reaper[name], "No matches must leave preferences unchanged") end
inputs[1].content = "  LONGEST  "
active = 3
refresh()
assert(not layers[#tasks + 1].hidden, "Reaper search must not filter Slayer")
inputs[2].content = "no match"
refresh()
assert(layers[#tasks + 1].hidden and layers[#tasks + 2].hidden,
    "Unmatched searches must hide all task cards")
active = 2
inputs[1].content = ""
refresh()
assert(not layers[1].hidden and not layers[3].hidden, "Clearing search must restore tasks")
buttons[#tasks + 2].callbacks[ui.Hook.ONBUTTONPRESSED]()
for _, name in ipairs(tasks) do assert(not rules.reaper[name], "Empty search must disable everything") end
buttons[#tasks + 1].callbacks[ui.Hook.ONBUTTONPRESSED]()
for _, name in ipairs(tasks) do assert(rules.reaper[name], "Empty search must enable everything") end
destroy()
assert(destroyed)
layers = {}
buttons = {}
view.build(host, rules, pretty, 2)
assertButtonColumns()
assert(layers[1].size[3] == 1 / 2 and layers[2].pos[1] == 4,
    "Settings menu must retain its existing fixed layout")
layers = {}
active = 1
rules.general.enabledFirst = true
rules.reaper[tasks[1]] = false
local ribbonState = {}
local inputCount = #inputs
local refreshRibbon = view.build(host, rules, pretty, "auto", false, ribbonState)
assert(#inputs == inputCount + 2, "Ribbon must have separate Reaper and Slayer search fields")
assert(inputs[#inputs - 1].pos[2] == 47, "Search must sit below the bulk buttons")
assert(#definitions == 2 and definitions[1].text == "Reaper" and definitions[2].text == "Slayer",
    "Ribbon must not include General settings")
assert(not layers[1].hidden and layers[1].pos[2] > layers[2].pos[2],
    "Ribbon must still apply saved ordering preferences")
rules.reaper[tasks[1]] = true
refreshRibbon()
assert(layers[1].pos[2] == 86, "Shared enabled-first changes must trigger layout")
active = 2
tabOptions.onChange(nil, 2)
assert(ribbonState.activeIndex == 2, "Tab clicks must immediately remember Slayer before a resize")
refreshRibbon()
assert(layers[1].hidden)
host.width = 540
refreshRibbon()
assert(active == 2 and layers[1].hidden and not layers[#tasks + 1].hidden,
    "Shrinking the ribbon must keep the Slayer tab selected")
host.width, host.height = 1100, 400
refreshRibbon()
assert(active == 2 and layers[1].hidden and not layers[#tasks + 1].hidden,
    "Growing the ribbon must keep the Slayer tab selected")
layers = {}
view.build(host, rules, pretty, "auto", false, ribbonState)
assert(active == 2 and layers[1].hidden and not layers[#tasks + 1].hidden,
    "Rebuilding cleared ribbon components must restore the Slayer tab")
print("Task Guard settings view tests passed")
