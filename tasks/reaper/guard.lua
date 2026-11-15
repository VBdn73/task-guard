-- Resolve fresh, exact labels only in the captured choice list, never globally.
local factory = require("ui/task-overlay")
local tasks = require("tasks/reaper/catalogue")
local settings = require("tasks/settings")
local requirements = require("tasks/requirements")
local ordering = require("tasks/native-order")
local hover = require("ui/task-hover")
local guard = {}

function guard.new(rules, pretty)
    local nativeOrder = ordering.new(rules)
    local known, shields, matches, failures = {}, {}, {}, {}
    local blocked, modes = {}, {}
    local stopped = false
    for _, name in ipairs(tasks) do known[name] = name end
    local function clear()
        matches, failures = {}, {}
        blocked, modes = {}, {}
        for name, shield in pairs(shields) do
            shields[name] = nil
            local ok, err = pcall(shield.remove)
            if not ok then print("[task-guard] Could not remove " .. name .. " overlay: " .. tostring(err)) end
        end
    end
    local function discover()
        blocked = {}
        local found, duplicate, count, candidates, sprites = {}, {}, 0, {}, {}
        local list = ui.Interfaces:GetComponent(1761, 1)
        local title = ui.Interfaces:GetComponent(1761, 7, 0, 14)
        if not list or list.isRestricted or not list.visibleGlobal
            or not title or title.isRestricted or not title.visibleGlobal
            or title.type ~= ui.ComponentType.LABEL or title.content ~= "Pick A task" then
            return found
        end
        -- Snapshot before creating owned components. Never match our own grey text.
        list:IterateDynamicComponents(function(c)
            if c and requirements.isOwned(c) then return false end
            requirements.capture(c, list, sprites)
            if c and not c.isRestricted and c.visibleGlobal and c.parent == list
                and c.type == ui.ComponentType.LABEL
                and c.width > 0 and c.height > 0 then
                local name = known[c.content]
                if name then
                    if found[name] then duplicate[name] = true else count = count + 1 end
                    found[name] = c
                else
                    candidates[#candidates + 1] = c
                end
            end
            return false
        end)
        -- The generic title alone is not Reaper-specific. Require multiple
        -- distinct catalogue labels in the captured list; ambiguous names are ignored.
        if count < 2 then return {} end
        local names, occurrences = {}, {}
        for _, c in ipairs(candidates) do occurrences[c.content] = (occurrences[c.content] or 0) + 1 end
        for _, c in ipairs(candidates) do
            if occurrences[c.content] == 1 then names[#names + 1] = c.content end
        end
        assert(settings.discover(rules, names), "Could not save discovered Reaper tasks")
        for _, name in ipairs(tasks) do if not known[name] then known[name] = name end end
        for _, c in ipairs(candidates) do
            if occurrences[c.content] == 1 and known[c.content] then found[known[c.content]] = c end
        end
        for name in pairs(duplicate) do found[name] = nil end
        -- Reuse the native snapshot: never traverse the list once per task.
        local rowSprites = requirements.index(sprites)
        for name, c in pairs(found) do
            -- Unknown label geometry is already rejected by requirements.
            local candidates = sprites
            if type(c.y) == "number" and type(c.height) == "number" then candidates = rowSprites(c) end
            if requirements.isBlocked(c, candidates) then blocked[name] = true end
        end
        return found
    end
    local lastError
    local controller
    controller = {
        remove = clear,
        shutdown = function()
            stopped = true
            clear()
            nativeOrder.restore()
        end,
        addMenu = function(menu, useSnapshot)
            if stopped then return end
            -- MiniMenuReady runs for ordinary hover every tick. Main supplies
            -- the reconciled logic snapshot; do not scan/create UI a second time.
            -- Standalone callers can still request a fresh reconciliation.
            if not useSnapshot then controller.update() end
            hover.begin()
            local selected
            for name, c in pairs(matches) do
                local hovered = c.isMouseOver or (shields[name] and shields[name].isMouseOver
                    and shields[name].isMouseOver())
                local cursorHover = hover.contains(c, c.parent and c.parent.parent)
                for _, entry in ipairs(menu.entries) do
                    if entry.componentData and entry.componentData.component == c then hovered = true end
                end
                if cursorHover ~= nil then hovered = cursorHover end
                if hovered then
                    if selected then hover.finish(); return end
                    selected = name
                end
            end
            hover.finish()
            if not selected or blocked[selected] then return end
            local target = matches[selected]
            local enabled = rules.reaper[selected] ~= false
            local text = enabled and "Disable task" or "Enable task"
            local count, cancelIndex = #menu.entries
            for index, entry in ipairs(menu.entries) do
                if entry.verbText == "Cancel"
                    or (MiniMenuActionType and entry.actionType == MiniMenuActionType.CANCEL) then
                    cancelIndex = index
                    break
                end
            end
            local taskID
            for index, name in ipairs(tasks) do
                if name == selected then taskID = index; break end
            end
            -- MiniMenu dispatches callbacks with the action's user data. The
            -- default (zero) is shared by every action without an explicit ID.
            menu:Add(text, function(selectedID)
                if stopped then return end
                if selectedID ~= taskID then return end
                controller.update()
                -- A menu may outlive its dialog or the requirement state.
                if matches[selected] ~= target or blocked[selected] then return end
                local old = rules.reaper[selected]
                rules.reaper[selected] = not enabled
                if not settings.save(rules) then
                    rules.reaper[selected] = old
                    print("[task-guard] Could not save " .. selected .. " setting.")
                end
                controller.update()
            end, taskID)
            -- Native menus store low-priority entries first, with the default
            -- left-click action last. Keep our action beside Cancel, not last.
            local actionIndex, currentCancel
            local entries = menu.entries
            for index, entry in ipairs(entries) do
                if entry.overrideText == text or entry.verbText == text or entry.label == text then
                    actionIndex = index
                end
                if entry.verbText == "Cancel"
                    or (MiniMenuActionType and entry.actionType == MiniMenuActionType.CANCEL) then
                    currentCancel = index
                end
            end
            if actionIndex and currentCancel then
                local destination = currentCancel + (actionIndex > currentCancel and 1 or 0)
                if destination < #entries then
                    while actionIndex < destination do
                        menu:Swap(actionIndex, actionIndex + 1)
                        actionIndex = actionIndex + 1
                    end
                    while actionIndex > destination do
                        menu:Swap(actionIndex - 1, actionIndex)
                        actionIndex = actionIndex - 1
                    end
                end
            elseif #entries == count and cancelIndex == 1 then
                -- Some clients retain the pre-Add entries snapshot.
                menu:Swap(1, 2)
            end
        end,
        update = function()
            if stopped then return end
            hover.begin()
            nativeOrder.update()
            local ok, result = pcall(discover)
            if not ok then
                hover.finish()
                clear()
                local message = tostring(result)
                if message ~= lastError then print("[task-guard] Reaper protection unavailable: " .. message) end
                lastError = message
                return
            end
            lastError, matches = nil, result
            if next(matches) == nil then
                hover.finish()
                clear()
                return
            end
            for name, shield in pairs(shields) do
                if not matches[name] or (rules.reaper[name] ~= false and not blocked[name])
                    or modes[name] ~= (blocked[name] == true) then
                    shield.remove()
                    shields[name] = nil
                    modes[name] = nil
                else
                    shield.update()
                end
            end
            for name in pairs(matches) do
                if rules.reaper[name] == false or blocked[name] then
                    local shield = shields[name]
                    if not shield then
                        shield = factory.new({ name = matches[name].content,
                            requirements = blocked[name] == true,
                            isHovered = function()
                                local c = matches[name]
                                if not c then return false end
                                return hover.contains(c, c.parent and c.parent.parent)
                            end,
                            resolve = function() return matches[name] end }, pretty)
                        shields[name] = shield
                        modes[name] = blocked[name] == true
                    end
                    if not shield.isShown() then
                        local message = shield.show()
                        if not shield.isShown() then
                            if failures[name] ~= message then print("[task-guard] " .. message) end
                            failures[name] = message
                            shields[name] = nil
                        else
                            failures[name] = nil
                        end
                    end
                end
            end
            hover.finish()
        end,
    }
    return controller
end

return guard
