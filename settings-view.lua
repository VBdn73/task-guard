local tasks = require("reaper-tasks")
local settings = require("task-settings")
local view = {}

function view.build(host, rules, pretty)
    assert(pretty and pretty.Tabs and pretty.Tabs.new, "PrettyUI Tabs is required")
    local tabs = pretty.Tabs.new(host, {
        { text = "Reaper" }, { text = "Slayer" },
    }, { width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        contentLayout = { startY = 80 } })
    local page = tabs:GetPage(1)
    local entries = {}
    local function wheel(_, delta)
        if not page.scrollbarVisible then return true end
        page:ScrollBy(delta * 32)
        return false
    end
    local function track(control)
        control:Subscribe(ui.Hook.ONSCROLLWHEEL, "taskGuard.settingsScroll", wheel)
        return control
    end
    for index, name in ipairs(tasks) do
        local column = (index - 1) % 2
        local y = 8 + math.floor((index - 1) / 2) * 40
        local layer = track(ui.Layer.new(page.content))
        layer:SetPos(column == 0 and 10 or 4, y, column * 0.5, 0)
        layer:SetSize(-14, 36, 0.5, 0)
        layer.clickthrough = true
        local frame = track(ui.Rectangle.new(layer))
        frame:SetSize(0, 36, 1, 0)
        frame.fill, frame.rgba, frame.clickthrough = true, 0x514D45C0, true
        local background = track(ui.Rectangle.new(layer))
        background:SetPos(1, 1); background:SetSize(-2, 34, 1, 0)
        background.fill, background.clickthrough = true, true
        local label = track(ui.Text.new(layer))
        label:SetPos(8, 2); label:SetSize(-46, 32, 1, 0)
        label.font = id.Font.MUSEO_SANS_11PT_REGULAR
        label.content = name
        label.alignVertical, label.clickthrough = ui.AlignMode.CENTRE, true
        local switch = track(ui.Check.new(layer))
        switch:SetPos(-30, 7, 1, 0); switch:SetSize(22, 22)
        switch.stylesheetID, switch.buttonSize = id.StyleSheet.CHECKBOX_DEFAULT, 22
        local function update()
            local enabled = rules.reaper[name]
            switch.value = enabled
            background.rgba = enabled and 0x23412DE8 or 0x492626E8
        end
        switch:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            local old = rules.reaper[name]
            rules.reaper[name] = not old
            if not settings.save(rules) then
                rules.reaper[name] = old
                print("[task-guard] Could not save " .. name .. " setting.")
            end
            update()
            return true
        end)
        update()
        entries[#entries + 1] = layer
    end
    page:SetContentHeight(16 + math.ceil(#tasks / 2) * 40)
    local width, height, active
    local function refresh()
        local selected = tabs:GetActiveIndex()
        if selected ~= active then
            active = selected
            for _, layer in ipairs(entries) do layer.hidden = active ~= 1 end
        end
        if host.width ~= width or host.height ~= height then
            width, height = host.width, host.height
            for i = 1, 2 do tabs:GetPage(i)._scroll:Refresh() end
        end
    end
    refresh()
    return refresh, function() tabs:Destroy() end
end

return view
