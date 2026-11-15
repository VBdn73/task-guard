-- Run from the project root: lua tests/settings-view.lua
local tasks = { "Short", "Longest boss name", "Third", "Fourth", "Fifth", "Sixth" }
package.loaded["reaper-tasks"] = tasks
package.loaded["task-settings"] = { save = function() return true end }
id = { Font = { MUSEO_SANS_11PT_REGULAR = 1 }, StyleSheet = { CHECKBOX_DEFAULT = 1, BUTTON_DEFAULT = 2 } }
config = { Font = { FromID = function()
    return { GetStringWidth = function(_, name) return name == tasks[2] and 200 or 40 end }
end } }
local layers = {}
local function control(parent)
    return { parent = parent, SetPos = function(self, ...) self.pos = { ... } end,
        SetSize = function(self, ...) self.size = { ... } end,
        Subscribe = function() end }
end
ui = { Hook = { ONSCROLLWHEEL = 1, ONBUTTONPRESSED = 2 }, AlignMode = { CENTRE = 1 } }
for _, kind in ipairs({ "Layer", "Rectangle", "Button", "Text", "Check" }) do
    ui[kind] = { new = function(parent)
        local result = control(parent)
        if kind == "Layer" then layers[#layers + 1] = result end
        return result
    end }
end
local host = { width = 800, height = 240 }
local pages, active, destroyed = {}, 1, false
local pretty = { Tabs = { new = function()
    pages = {}
    for i = 1, 2 do
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
local rules = { reaper = {} }
for _, name in ipairs(tasks) do rules.reaper[name] = true end
local view = require("settings-view")
local refresh, destroy = view.build(host, rules, pretty, "auto")
assert(layers[1].size[3] == 1 / 3, "Wide ribbon should fit three columns")
assert(layers[4].pos[2] == 88 and pages[1].contentHeight == 136)
host.width = 540
refresh()
assert(layers[1].size[3] == 1 / 2, "Resize should fit two columns")
host.width = 520
refresh()
assert(layers[1].size[3] == 1, "Scrollbar width must be included at a column threshold")
host.width = 300
refresh()
assert(layers[2].pos[2] == 88, "Narrow ribbon should have one column")
host.width = 1100
refresh()
assert(layers[1].size[3] == 1 / 4, "Growing the ribbon should add columns again")
active = 2
refresh()
assert(layers[1].hidden)
active = 1
refresh()
assert(not layers[1].hidden)
destroy()
assert(destroyed)
layers = {}
view.build(host, rules, pretty, 2)
assert(layers[1].size[3] == 1 / 2 and layers[2].pos[1] == 4,
    "Settings menu must retain its existing fixed layout")
print("Task Guard settings view tests passed")
