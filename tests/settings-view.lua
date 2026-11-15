-- Run from the project root: lua tests/settings-view.lua
local tasks = { "Short", "Longest boss name", "Third", "Fourth", "Fifth", "Sixth" }
package.loaded["reaper-tasks"] = tasks
local longSlayerName = "A very long slayer task name that should wrap across multiple lines"
package.loaded["slayer-tasks"] = { "Slayer one", longSlayerName }
package.loaded["task-settings"] = { save = function() return true end }
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, StyleSheet = { CHECKBOX_DEFAULT = 1, BUTTON_DEFAULT = 2 } }
config = { Font = { FromID = function()
    return { GetStringWidth = function(_, name) return name == tasks[2] and 200 or #name * 7 end }
end } }
local layers, labels = {}, {}
local function control(parent)
    return { parent = parent, SetPos = function(self, ...)
            self.pos = { ... }; self.positionWrites = (self.positionWrites or 0) + 1
        end,
        SetSize = function(self, ...) self.size = { ... } end,
        Subscribe = function() end }
end
ui = { Hook = { ONSCROLLWHEEL = 1, ONBUTTONPRESSED = 2 }, AlignMode = { CENTRE = 1 } }
ui.Margin = { new = function(...) return { ... } end }
for _, kind in ipairs({ "Layer", "Rectangle", "Button", "Text", "Check" }) do
    ui[kind] = { new = function(parent)
        local result = control(parent)
        if kind == "Layer" then layers[#layers + 1] = result end
        if kind == "Text" then labels[#labels + 1] = result end
        return result
    end }
end
local host = { width = 800, height = 240 }
local pages, active, destroyed = {}, 1, false
local definitions
local pretty = { Tabs = { new = function(_, defs)
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
pretty.ComboBox = dofile("tests/combo-box-mock.lua")(control)
pretty.CheckboxButton = dofile("tests/checkbox-mock.lua")(control)
local rules = { reaper = {} }
for _, name in ipairs(tasks) do rules.reaper[name] = true end
local view = require("settings-view")
local refresh, destroy = view.build(host, rules, pretty, "auto")
local information = labels[#labels]
assert(information.content:find("does not block", 1, true), "General tab must explain that tasks are not blocked")
assert(information.content:gsub("<br>", " "):find("accidental clicks", 1, true),
    "General tab must explain accidental-click protection")
assert(layers[1].size[3] == 1 / 3, "Wide ribbon should fit three columns")
assert(layers[4].pos[2] == 88 and pages[2].contentHeight == 136)
local writes = layers[1].positionWrites
for _ = 1, 10 do refresh() end
assert(layers[1].positionWrites == writes, "Idle view refreshes must not relayout cards")
host.width = 540
refresh()
assert(layers[1].size[3] == 1 / 2, "Resize should fit two columns")
assert(layers[#tasks + 1].size[3] == 1 / 2,
    "A long Slayer name must not prevent two columns")
assert(labels[#tasks + 2].content:find("<br>", 1, true), "Long Slayer names must use client line breaks")
assert(layers[#tasks + 2].size[2] > 36, "Wrapped cards must grow to fit their labels")
host.width = 520
refresh()
assert(layers[1].size[3] == 1, "Scrollbar width must be included at a column threshold")
host.width = 300
refresh()
assert(layers[2].pos[2] == 88, "Narrow ribbon should have one column")
host.width = 1100
refresh()
assert(layers[1].size[3] == 1 / 4, "Growing the ribbon should add columns again")
active = 3
refresh()
assert(layers[1].hidden)
assert(not layers[#tasks + 1].hidden and pages[3].contentHeight > 0,
    "Slayer tab must show its own task cards")
active = 2
refresh()
assert(not layers[1].hidden)
destroy()
assert(destroyed)
layers = {}
view.build(host, rules, pretty, 2)
assert(layers[1].size[3] == 1 / 2 and layers[2].pos[1] == 4,
    "Settings menu must retain its existing fixed layout")
layers = {}
active = 1
rules.general.enabledFirst = true
rules.reaper[tasks[1]] = false
local refreshRibbon = view.build(host, rules, pretty, "auto", false)
assert(#definitions == 2 and definitions[1].text == "Reaper" and definitions[2].text == "Slayer",
    "Ribbon must not include General settings")
assert(not layers[1].hidden and layers[1].pos[2] > layers[2].pos[2],
    "Ribbon must still apply saved ordering preferences")
rules.reaper[tasks[1]] = true
refreshRibbon()
assert(layers[1].pos[2] == 48, "Shared enabled-first changes must trigger layout")
active = 2
refreshRibbon()
assert(layers[1].hidden)
print("Task Guard settings view tests passed")
