local tasks = require("tasks/reaper/catalogue")
local slayerTasks = require("tasks/slayer/catalogue")
local settings = require("tasks/settings")
local taskOrder = require("tasks/ordering")
local MINIMUM_CARD_WIDTH = 246
local SCROLL_STEP = 32
local ENABLED_COLOR = 0x23412DE8
local DISABLED_COLOR = 0x492626E8
local view = {}

function view.build(host, rules, pretty, columns, showGeneral, state)
    state = state or {}
    showGeneral = showGeneral ~= false
    local reaperIndex = showGeneral and 2 or 1
    rules.general = rules.general or { taskOrder = "default", enabledFirst = false }
    assert(pretty and pretty.Tabs and pretty.Tabs.new, "PrettyUI Tabs is required")
    local tabDefinitions = { { text = "Reaper" }, { text = "Slayer" } }
    if showGeneral then table.insert(tabDefinitions, 1, { text = "General" }) end
    local tabs = pretty.Tabs.new(host, tabDefinitions, { width = 0, height = 0, widthAnchor = 1, heightAnchor = 1,
        contentLayout = { startY = 80 }, activeIndex = state.activeIndex or 1,
        onChange = function(_, index) state.activeIndex = index end })
    local shortNames = { General = "Gen", Reaper = "Reap", Slayer = "Slay" }
    local function measureTabText(text)
        local ok, measured = pcall(function()
            return config.Font.MUSEO_SANS_15PT_REGULAR:GetStringWidth(text, false)
        end)
        return ok and measured or #text * 7
    end
    local fullTabWidth = 2 * (#tabDefinitions - 1)
    for _, definition in ipairs(tabDefinitions) do
        fullTabWidth = fullTabWidth + math.max(90, math.floor(measureTabText(definition.text) + 24))
    end
    local function resizeTabs()
        -- PrettyUI's text tabs have a fixed 90px minimum and no padding option.
        -- Adjust only this view's tab surfaces; leave the shared library untouched.
        if not tabs.GetTab then return end
        local compact = host.width < fullTabWidth
        local x = tabs.tabInset or 0
        for index, definition in ipairs(tabDefinitions) do
            local tab = tabs:GetTab(index)
            local text = compact and shortNames[definition.text] or definition.text
            local tabWidth = compact and math.max(60, math.ceil(measureTabText(text) + 16))
                or math.max(90, math.floor(measureTabText(text) + 24))
            tab.text = text
            tab.label.content = text
            tab.width = tabWidth
            tab.visual:SetPos(x, 0)
            tab.visual:SetSize(tabWidth, 60)
            -- The native left sprite is 60px wide, overlapping the right cap
            -- below 90px. Keep both caps within their own 30px sections.
            tab.left:SetSize(compact and 30 or 60, 60)
            tab.hit:SetPos(x, 0)
            tab.hit:SetSize(tabWidth, 42)
            x = x + tabWidth + (compact and 0 or 2)
        end
    end
    local generalPage = showGeneral and tabs:GetPage(1) or nil
    local function buildTaskPage(tasks, preferences, pageIndex)
    local page = tabs:GetPage(pageIndex)
    local columns = columns or 2
    local automatic = columns == "auto"
    local minimumCardWidth = MINIMUM_CARD_WIDTH
    local font = config.Font.FromID(id.Font.MUSEO_SANS_11PT_REGULAR)
    if automatic then
        -- Long names wrap instead of dictating the width of every card.
        columns = 1
    end
    local entries = {}
    local layout
    local query = ""
    local activePage
    local searchHeight = 38
    local search = ui.InputField.new(page.content)
    search.stylesheetID = id.StyleSheet.INPUT_DEFAULT
    search:Setup(ui.TextContentVisibilityMode.VISIBLE, ui.InputFieldFilterMode.NONE, 100)
    search.content = ""
    search.emptyText = "Search " .. tabDefinitions[pageIndex].text .. " tasks..."
    local function searchQuery()
        return (search.content or ""):lower():match("^%s*(.-)%s*$")
    end
    local function matchesSearch(name, text)
        return name:lower():find(text, 1, true) ~= nil
    end
    local lastOrderKey
    local function orderKey()
        local parts = { rules.general.taskOrder, tostring(rules.general.enabledFirst) }
        if rules.general.enabledFirst then
            for _, name in ipairs(tasks) do parts[#parts + 1] = preferences[name] and "1" or "0" end
        end
        return table.concat(parts, ":")
    end
    local function wheel(_, delta)
        if not page.scrollbarVisible then return true end
        page:ScrollBy(delta * SCROLL_STEP)
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
            local enabled = preferences[name]
            if enabled == lastEnabled then return end
            lastEnabled = enabled
            switch.value = enabled
            background.rgba = enabled and ENABLED_COLOR or DISABLED_COLOR
        end
        local function toggle()
            local old = preferences[name]
            preferences[name] = not old
            if not settings.save(rules) then
                preferences[name] = old
                print("[task-guard] Could not save " .. name .. " setting.")
            end
            update()
            layout()
            return false
        end
        switch:Subscribe(ui.Hook.ONBUTTONPRESSED, toggle)
        hitTarget:Subscribe(ui.Hook.ONBUTTONPRESSED, toggle)
        update()
        entries[#entries + 1] = { layer = layer, update = update, name = name, index = index,
            frame = frame, background = background, hitTarget = hitTarget, label = label, switch = switch }
    end
    local function setAll(enabled)
        local old = {}
        local currentQuery = searchQuery()
        for _, name in ipairs(tasks) do
            if matchesSearch(name, currentQuery) then
                old[name] = preferences[name]
                preferences[name] = enabled
            end
        end
        if next(old) == nil then return false end
        if not settings.save(rules) then
            for name, value in pairs(old) do preferences[name] = value end
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
        button.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        button.label = action.label
        button:Subscribe(ui.Hook.ONBUTTONPRESSED, function() return setAll(action.enabled) end)
        allButtons[#allButtons + 1] = button
    end
    layout = function()
        local visibleEntries = {}
        table.sort(entries, function(a, b)
            if rules.general.enabledFirst and preferences[a.name] ~= preferences[b.name] then
                return preferences[a.name] == true
            end
            if rules.general.taskOrder == "alphabetical" then
                return taskOrder.alphabetical(a.name, b.name)
            end
            if rules.general.taskOrder == "alphabeticalDescending" then
                return taskOrder.alphabeticalDescending(a.name, b.name)
            end
            return a.index < b.index
        end)
        for _, entry in ipairs(entries) do
            entry.matches = matchesSearch(entry.name, query)
            entry.layer.hidden = activePage ~= pageIndex or not entry.matches
            if entry.matches then visibleEntries[#visibleEntries + 1] = entry end
        end
        local available = page._scroll.contentWidth or page.content.width
        if automatic then
            -- Ten-pixel outside margins and six-pixel gaps between cards.
            columns = math.max(1, math.min(#tasks, math.floor((available - 14) / (minimumCardWidth + 6))))
        end
        local cardWidth = automatic and (available - 14) / columns - 6
            or available / columns - (columns == 1 and 20 or 14)
        local searchColumns = math.min(2, columns)
        local columnGap = automatic and 6 + 20 / columns or 8
        local searchY = columns == 1 and 81 or 47
        search:SetPos(10, searchY)
        search:SetSize(searchColumns * cardWidth + (searchColumns - 1) * columnGap, 30)
        local function placeColumn(control, column, y, height)
            if automatic then
                control:SetPos(10 + column * 6 / columns, y, column / columns, 0)
                control:SetSize(-6 - 14 / columns, height, 1 / columns, 0)
            else
                control:SetPos(column == 0 and 10 or 4, y, column / columns, 0)
                control:SetSize(columns == 1 and -20 or -14, height, 1 / columns, 0)
            end
        end
        for index, button in ipairs(allButtons) do
            placeColumn(button, (index - 1) % columns,
                8 + math.floor((index - 1) / columns) * 34, 30)
        end
        local heights = {}
        for index, entry in ipairs(visibleEntries) do
            local lines, line = {}, ""
            for word in entry.name:gmatch("%S+") do
                local candidate = line == "" and word or line .. " " .. word
                if line ~= "" and font:GetStringWidth(candidate, true) > math.max(1, cardWidth - 46) then
                    lines[#lines + 1], line = line, word
                else
                    line = candidate
                end
            end
            lines[#lines + 1] = line
            entry.label.content = table.concat(lines, "<br>")
            local row = math.floor((index - 1) / columns) + 1
            heights[row] = math.max(heights[row] or 36, #lines * 18 + 4)
        end
        local y = searchY + searchHeight + 1
        for index, entry in ipairs(visibleEntries) do
            local column = (index - 1) % columns
            local row = math.floor((index - 1) / columns) + 1
            local height = heights[row]
            entry.frame:SetSize(0, height, 1, 0)
            entry.background:SetSize(-2, height - 2, 1, 0)
            entry.hitTarget:SetSize(0, height, 1, 0)
            entry.label:SetSize(-46, height - 4, 1, 0)
            entry.switch:SetPos(-30, (height - 22) / 2, 1, 0)
            placeColumn(entry.layer, column, y, height)
            if column == columns - 1 or index == #visibleEntries then y = y + height + 4 end
        end
        page:SetContentHeight(y + 8)
        lastOrderKey = orderKey()
    end
    local contentWidth
    return { layout = layout, refresh = function(active, resized)
        activePage = active
        search.hidden = active ~= pageIndex
        local nextQuery = searchQuery()
        local searchChanged = nextQuery ~= query
        query = nextQuery
        for _, entry in ipairs(entries) do
            entry.layer.hidden = active ~= pageIndex or entry.matches == false
            entry.update()
        end
        for _, button in ipairs(allButtons) do button.hidden = active ~= pageIndex end
        if resized or searchChanged or orderKey() ~= lastOrderKey then layout() end
        local available = page._scroll.contentWidth or page.content.width
        if available ~= contentWidth then
            layout()
            if (page._scroll.contentWidth or page.content.width) ~= available then layout() end
            contentWidth = page._scroll.contentWidth or page.content.width
        end
    end }
    end
    rules.slayer = rules.slayer or {}
    for _, name in ipairs(slayerTasks) do
        if rules.slayer[name] == nil then rules.slayer[name] = true end
    end
    local taskPages = {
        buildTaskPage(tasks, rules.reaper, reaperIndex),
        buildTaskPage(slayerTasks, rules.slayer, reaperIndex + 1),
    }
    local function layout()
        for _, taskPage in ipairs(taskPages) do taskPage.layout() end
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
    local information = generalControl("Text", 10, 96, 360, 100)
    information.font, information.clickthrough = id.Font.MUSEO_SANS_11PT_REGULAR, true
    local informationText = "Task Guard does not block tasks in-game or change which tasks you can receive. "
        .. "It helps prevent accidental clicks on unwanted tasks in the Reaper's Choice and Slayer cape choice menus "
        .. "and makes your preferred tasks easier to find."
    local informationFont = config.Font.FromID(id.Font.MUSEO_SANS_11PT_REGULAR)
    local informationWidth
    updateGeneral = function()
        local selectedID = orderIDs[rules.general.taskOrder] or 1
        if dropdown:GetSelectedID() ~= selectedID then dropdown:Select(selectedID, false) end
        enabledCheckbox:SetSelected("enabledFirst", rules.general.enabledFirst, false)
        local available = math.max(100, (generalPage._scroll.contentWidth or generalPage.content.width) - 20)
        if available ~= informationWidth then
            informationWidth = available
            local stacked = available < 335
            dropdown.root:SetPos(stacked and 10 or 95, stacked and 42 or 8)
            dropdown.root:SetSize(stacked and available or 250, 34)
            enabledCheckbox.root:SetPos(10, stacked and 84 or 50)
            local informationY = stacked and 130 or 96
            information:SetPos(10, informationY)
            local lines, line = {}, ""
            for word in informationText:gmatch("%S+") do
                local candidate = line == "" and word or line .. " " .. word
                if line ~= "" and informationFont:GetStringWidth(candidate) > available then
                    lines[#lines + 1], line = line, word
                else
                    line = candidate
                end
            end
            lines[#lines + 1] = line
            information.content = table.concat(lines, "<br>")
            information:SetSize(available, #lines * 20)
            generalPage:SetContentHeight(informationY + 10 + #lines * 20)
        end
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
    updateGeneral()
    end
    local width, height, active
    local function refresh()
        assert(not host.isRestricted, "Settings host is no longer available")
        if host.visibleGlobal == false then return end
        local selected = tabs:GetActiveIndex()
        state.activeIndex = selected
        if selected ~= active then
            active = selected
            for _, control in ipairs(generalControls) do control.hidden = active ~= 1 end
        end
        local resized = host.width ~= width or host.height ~= height
        if resized then
            width, height = host.width, host.height
            resizeTabs()
            for i = 1, #tabDefinitions do tabs:GetPage(i)._scroll:Refresh() end
        end
        if showGeneral and active == 1 then updateGeneral() end
        for _, taskPage in ipairs(taskPages) do taskPage.refresh(active, resized) end
    end
    refresh()
    return refresh, function()
        if dropdown then dropdown:Destroy() end
        if enabledCheckbox then enabledCheckbox:Destroy() end
        tabs:Destroy()
    end
end

return view
