local tasks = require("reaper-tasks")
local settings = require("task-settings")
local view = {}

function view.build(host, rules, pretty, columns)
    columns = columns or 2
    local automatic = columns == "auto"
    local minimumCardWidth = 0
    if automatic then
        local font = config.Font.FromID(id.Font.MUSEO_SANS_11PT_REGULAR)
        for _, name in ipairs(tasks) do
            -- Label inset plus space for the checkbox and right-hand padding.
            minimumCardWidth = math.max(minimumCardWidth, math.ceil(font:GetStringWidth(name, true)) + 46)
        end
        columns = 1
    end
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
        local layer = track(ui.Layer.new(page.content))
        layer.clickthrough = true
        local frame = track(ui.Rectangle.new(layer))
        frame:SetSize(0, 36, 1, 0)
        frame.fill, frame.rgba, frame.clickthrough = true, 0x514D45C0, true
        local background = track(ui.Rectangle.new(layer))
        background:SetPos(1, 1); background:SetSize(-2, 34, 1, 0)
        background.fill, background.clickthrough = true, true
        -- Static hit target behind the label and checkbox: clicking the card
        -- uses the same saved-setting toggle without introducing hover visuals.
        local hitTarget = track(ui.Button.new(layer))
        hitTarget:SetPos(0, 0); hitTarget:SetSize(0, 36, 1, 0)
        hitTarget.stylesheetID = -1
        hitTarget.enabled, hitTarget.clickthrough = true, false
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
        local function toggle()
            local old = rules.reaper[name]
            rules.reaper[name] = not old
            if not settings.save(rules) then
                rules.reaper[name] = old
                print("[task-guard] Could not save " .. name .. " setting.")
            end
            update()
            return false
        end
        switch:Subscribe(ui.Hook.ONBUTTONPRESSED, toggle)
        hitTarget:Subscribe(ui.Hook.ONBUTTONPRESSED, toggle)
        update()
        entries[#entries + 1] = { layer = layer, update = update }
    end
    local function setAll(enabled)
        local old = {}
        for _, name in ipairs(tasks) do
            old[name] = rules.reaper[name]
            rules.reaper[name] = enabled
        end
        if not settings.save(rules) then
            for _, name in ipairs(tasks) do rules.reaper[name] = old[name] end
            print("[task-guard] Could not save all task settings.")
        end
        for _, entry in ipairs(entries) do entry.update() end
        return false
    end
    local allButtons = {}
    for index, action in ipairs({ { label = "Enable all", enabled = true },
        { label = "Disable all", enabled = false } }) do
        local button = track(ui.Button.new(page.content))
        button:SetPos(index == 1 and 10 or 4, 8, (index - 1) / 2, 0)
        button:SetSize(-14, 30, 0.5, 0)
        button.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        button.label = action.label
        button:Subscribe(ui.Hook.ONBUTTONPRESSED, function() return setAll(action.enabled) end)
        allButtons[#allButtons + 1] = button
    end
    local function layout()
        if automatic then
            local available = page._scroll.contentWidth or page.content.width
            -- Ten-pixel outside margins and six-pixel gaps between cards.
            columns = math.max(1, math.min(#tasks, math.floor((available - 14) / (minimumCardWidth + 6))))
        end
        for index, entry in ipairs(entries) do
            local column = (index - 1) % columns
            local y = 48 + math.floor((index - 1) / columns) * 40
            if automatic then
                entry.layer:SetPos(10 + column * 6 / columns, y, column / columns, 0)
                entry.layer:SetSize(-6 - 14 / columns, 36, 1 / columns, 0)
            else
                entry.layer:SetPos(column == 0 and 10 or 4, y, column / columns, 0)
                entry.layer:SetSize(columns == 1 and -20 or -14, 36, 1 / columns, 0)
            end
        end
        page:SetContentHeight(56 + math.ceil(#tasks / columns) * 40)
    end
    local width, height, contentWidth, active
    local function refresh()
        local selected = tabs:GetActiveIndex()
        if selected ~= active then
            active = selected
            for _, entry in ipairs(entries) do entry.layer.hidden = active ~= 1 end
            for _, button in ipairs(allButtons) do button.hidden = active ~= 1 end
        end
        for _, entry in ipairs(entries) do entry.update() end
        if host.width ~= width or host.height ~= height then
            width, height = host.width, host.height
            for i = 1, 2 do tabs:GetPage(i)._scroll:Refresh() end
            layout()
        end
        local available = page._scroll.contentWidth or page.content.width
        if available ~= contentWidth then
            layout()
            -- Adding a scrollbar can reduce the width across a column threshold.
            if (page._scroll.contentWidth or page.content.width) ~= available then layout() end
            contentWidth = page._scroll.contentWidth or page.content.width
        end
    end
    refresh()
    return refresh, function() tabs:Destroy() end
end

return view
