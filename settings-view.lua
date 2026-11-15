local tasks = require("reaper-tasks")
local settings = require("task-settings")
local taskOrder = require("task-order")
local view = {}

function view.build(host, rules, pretty, columns, showGeneral)
    showGeneral = showGeneral ~= false
    local reaperIndex = showGeneral and 2 or 1
    rules.general = rules.general or { taskOrder = "default", enabledFirst = false }
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
    local tabDefinitions = { { text = "Reaper" }, { text = "Slayer" } }
    if showGeneral then table.insert(tabDefinitions, 1, { text = "General" }) end
    local tabs = pretty.Tabs.new(host, tabDefinitions, { width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        contentLayout = { startY = 80 } })
    local generalPage = showGeneral and tabs:GetPage(1) or nil
    local page = tabs:GetPage(reaperIndex)
    local entries = {}
    local layout
    local lastOrderKey
    local function orderKey()
        local parts = { rules.general.taskOrder, tostring(rules.general.enabledFirst) }
        if rules.general.enabledFirst then
            for _, name in ipairs(tasks) do parts[#parts + 1] = rules.reaper[name] and "1" or "0" end
        end
        return table.concat(parts, ":")
    end
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
        local lastEnabled
        local function update()
            local enabled = rules.reaper[name]
            if enabled == lastEnabled then return end
            lastEnabled = enabled
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
            layout()
            return false
        end
        switch:Subscribe(ui.Hook.ONBUTTONPRESSED, toggle)
        hitTarget:Subscribe(ui.Hook.ONBUTTONPRESSED, toggle)
        update()
        entries[#entries + 1] = { layer = layer, update = update, name = name, index = index }
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
        layout()
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
    layout = function()
        table.sort(entries, function(a, b)
            if rules.general.enabledFirst and rules.reaper[a.name] ~= rules.reaper[b.name] then
                return rules.reaper[a.name] == true
            end
            if rules.general.taskOrder == "alphabetical" then
                return taskOrder.alphabetical(a.name, b.name)
            end
            if rules.general.taskOrder == "alphabeticalDescending" then
                return taskOrder.alphabeticalDescending(a.name, b.name)
            end
            return a.index < b.index
        end)
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
        lastOrderKey = orderKey()
    end
    local generalControls = {}
    local updateGeneral
    local dropdown
    local enabledCheckbox
    if showGeneral then
    local function generalControl(kind, x, y, w, h)
        local control = ui[kind].new(generalPage.content)
        control:SetPos(x, y); control:SetSize(w, h)
        generalControls[#generalControls + 1] = control
        return control
    end
    local orderLabel = generalControl("Text", 10, 8, 80, 30)
    orderLabel.font, orderLabel.content = id.Font.MUSEO_SANS_11PT_REGULAR, "Task order"
    orderLabel.alignVertical, orderLabel.clickthrough = ui.AlignMode.CENTRE, true
    assert(pretty.ComboBox and pretty.ComboBox.new, "PrettyUI ComboBox is required")
    local orderIDs = { default = 1, alphabetical = 2, alphabeticalDescending = 3 }
    local orders = { "default", "alphabetical", "alphabeticalDescending" }
    dropdown = pretty.ComboBox.new(generalPage.content, {
        x = 95, y = 8, width = 250, height = 34,
        -- PrettyUI's input text does not centre within the ComboBox height;
        -- inset the 11pt text explicitly within this 34px field instead.
        contentMargin = ui.Margin.new(8, 8, 4, 0),
        font = id.Font.MUSEO_SANS_11PT_REGULAR,
        entries = { { label = "Client default", id = 1, order = 1 },
            { label = "Alphabetical ascending (A-Z)", id = 2, order = 2 },
            { label = "Alphabetical descending (Z-A)", id = 3, order = 3 } },
        selectedID = orderIDs[rules.general.taskOrder] or 1,
    })
    generalControls[#generalControls + 1] = dropdown.root
    assert(pretty.CheckboxButton and pretty.CheckboxButton.new, "PrettyUI CheckboxButton is required")
    enabledCheckbox = pretty.CheckboxButton.new(generalPage.content, {
        { text = "Sort enabled tasks first", value = "enabledFirst", selected = rules.general.enabledFirst },
    }, { x = 10, y = 50, width = 360 })
    enabledCheckbox.items[1].label.font = id.Font.MUSEO_SANS_11PT_REGULAR
    generalControls[#generalControls + 1] = enabledCheckbox.root
    updateGeneral = function()
        local selectedID = orderIDs[rules.general.taskOrder] or 1
        if dropdown:GetSelectedID() ~= selectedID then dropdown:Select(selectedID, false) end
        enabledCheckbox:SetSelected("enabledFirst", rules.general.enabledFirst, false)
    end
    local function saveGeneral(key, value)
        local old = rules.general[key]
        rules.general[key] = value
        if not settings.save(rules) then
            rules.general[key] = old
            print("[task-guard] Could not save task ordering setting.")
        end
        updateGeneral()
        layout()
        return false
    end
    enabledCheckbox.onChange = function(_, _, _, selected)
        return saveGeneral("enabledFirst", selected)
    end
    dropdown.onChange = function(_, entryID)
        return saveGeneral("taskOrder", orders[entryID] or "default")
    end
    generalPage:SetContentHeight(90)
    end
    local width, height, contentWidth, active
    local function refresh()
        assert(not host.isRestricted, "Settings host is no longer available")
        if host.visibleGlobal == false then return end
        local selected = tabs:GetActiveIndex()
        if selected ~= active then
            active = selected
            for _, entry in ipairs(entries) do entry.layer.hidden = active ~= reaperIndex end
            for _, button in ipairs(allButtons) do button.hidden = active ~= reaperIndex end
            for _, control in ipairs(generalControls) do control.hidden = active ~= 1 end
        end
        if showGeneral and active == 1 then updateGeneral() end
        for _, entry in ipairs(entries) do entry.update() end
        if orderKey() ~= lastOrderKey then layout() end
        if host.width ~= width or host.height ~= height then
            width, height = host.width, host.height
            for i = 1, #tabDefinitions do tabs:GetPage(i)._scroll:Refresh() end
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
    return refresh, function()
        if dropdown then dropdown:Destroy() end
        if enabledCheckbox then enabledCheckbox:Destroy() end
        tabs:Destroy()
    end
end

return view
