-- Move complete captured native rows, never replace text or dispatch actions.
local tasks = require("reaper-tasks")
local requirements = require("reaper-requirements")
local taskOrder = require("task-order")
local ordering = {}

function ordering.new(rules)
    local snapshot, rejected
    local function restore()
        if not snapshot then return end
        local old = snapshot
        snapshot = nil
        for _, item in ipairs(old.items) do
            pcall(function()
                local c = item.control
                -- Do not overwrite client changes or recycled components.
                if not c.isRestricted and c.parent == item.parent and c.type == item.kind
                    and c.x == item.appliedX and c.y == item.appliedY
                    and (item.text == nil or c.content == item.text) then
                    c:SetPos(item.x, item.y)
                end
            end)
        end
    end
    local function capture(list, alternate)
        assert(alternate and not alternate.isRestricted and alternate.parent == list.parent,
            "Companion list unavailable")
        assert(list.x == alternate.x and list.y == alternate.y
            and list.width == alternate.width and list.height == alternate.height,
            "Companion list geometry changed")
        local known, components, rows = {}, {}, {}
        for _, name in ipairs(tasks) do known[name] = true end
        for _, parent in ipairs({ list, alternate }) do
            parent:IterateDynamicComponents(function(c)
                if not c or requirements.isOwned(c) then return false end
                assert(not c.isRestricted, "Restricted row component")
                if c.parent == parent and c.width > 0 and c.height > 0 then
                    assert(c.type == 2 or c.type == 3, "Unrecognised native row component")
                    local item = { control = c, parent = parent, kind = c.type,
                        x = c.x, y = c.y, width = c.width, height = c.height,
                        appliedX = c.x, appliedY = c.y }
                    if c.type == 2 then item.text = c.content end
                    components[#components + 1] = item
                    if parent == list and c.type == 2 and c.content ~= "" then
                        assert(known[c.content], "Unknown native task")
                        assert(c.width == 230 and c.height == 20, "Task dimensions changed")
                        assert(c.x == 8 or c.x == 248, "Task columns changed")
                        assert(c.y >= 10 and (c.y - 10) % 23 == 0, "Task spacing changed")
                        item.name = c.content
                        rows[#rows + 1] = { name = c.content, x = c.x, y = c.y, items = {} }
                    end
                end
                return false
            end)
        end
        assert(#rows >= 2, "Not a recognised task list")
        table.sort(rows, function(a, b) return a.y == b.y and a.x < b.x or a.y < b.y end)
        local names, slots = {}, {}
        for index, row in ipairs(rows) do
            assert(not names[row.name], "Duplicate task name")
            names[row.name] = true
            slots[index] = { x = row.x, y = row.y }
            if index > 1 then
                local previous = rows[index - 1]
                assert(previous.x ~= row.x or previous.y ~= row.y, "Duplicate task slot")
            end
        end
        for _, item in ipairs(components) do
            local matched
            for _, row in ipairs(rows) do
                if item.x >= row.x and item.y >= row.y
                    and item.x + item.width <= row.x + 230 and item.y + item.height <= row.y + 20 then
                    assert(not matched, "Ambiguous row component")
                    matched = row
                end
            end
            assert(matched, "Component outside task rows")
            matched.items[#matched.items + 1] = item
        end
        for _, row in ipairs(rows) do
            local sprites, labels, companion, seen = 0, 0, 0, {}
            for _, item in ipairs(row.items) do
                local c = item.control
                if item.kind == 2 then
                    assert(item.x == row.x and item.y == row.y and item.width == 230 and item.height == 20,
                        "Label geometry changed")
                    if item.parent == list then labels = labels + 1 else companion = companion + 1 end
                else
                    assert(item.parent == list, "Unexpected companion sprite")
                    local part
                    for _, base in ipairs({ 18468, 18477, 18504 }) do
                        if c.spriteID >= base and c.spriteID <= base + 8 then part = c.spriteID - base end
                    end
                    assert(part and not seen[part], "Unrecognised background")
                    local column, band = part % 3 + 1, math.floor(part / 3) + 1
                    assert(item.x == row.x + ({ 0, 8, 222 })[column]
                        and item.y == row.y + ({ 0, 8, 12 })[band]
                        and item.width == ({ 8, 214, 8 })[column]
                        and item.height == ({ 8, 4, 8 })[band], "Background geometry changed")
                    sprites, seen[part] = sprites + 1, true
                end
            end
            assert(sprites == 9 and labels == 2 and companion <= 1, "Incomplete task row")
        end
        return { list = list, alternate = alternate, rows = rows, slots = slots, items = components }
    end
    local function update()
        local general = rules.general or {}
        if general.taskOrder ~= "alphabetical" and general.taskOrder ~= "alphabeticalDescending"
            and not general.enabledFirst then
            restore(); rejected = nil; return
        end
        local list = ui.Interfaces:GetComponent(1761, 1)
        local title = ui.Interfaces:GetComponent(1761, 7, 0, 14)
        if not list or list.isRestricted or not list.visibleGlobal or not title or title.isRestricted
            or not title.visibleGlobal or title.type ~= 2 or title.content ~= "Pick A task" then
            restore(); rejected = nil; return
        end
        if snapshot and snapshot.list ~= list then restore() end
        if rejected == list then return end
        if not snapshot then snapshot = capture(list, ui.Interfaces:GetComponent(1761, 0)) end
        assert(ui.Interfaces:GetComponent(1761, 0) == snapshot.alternate
            and not snapshot.alternate.isRestricted and snapshot.alternate.parent == list.parent,
            "Client replaced companion list")
        local changed = snapshot.taskOrder ~= general.taskOrder or snapshot.enabledFirst ~= general.enabledFirst
        if not changed and general.enabledFirst then
            for _, row in ipairs(snapshot.rows) do
                if snapshot.enabled[row.name] ~= (rules.reaper[row.name] ~= false) then changed = true; break end
            end
        end
        for _, item in ipairs(snapshot.items) do
            -- Named labels are live identity/position sentinels. Recheck all
            -- background/companion components only before an actual reorder.
            if changed or item.name then
            local c = item.control
            assert(not c.isRestricted and c.parent == item.parent and c.type == item.kind
                and c.width == item.width and c.height == item.height
                and c.x == item.appliedX and c.y == item.appliedY
                and (item.text == nil or c.content == item.text), "Client changed task layout")
            end
        end
        if not changed then return end
        table.sort(snapshot.rows, function(a, b)
            local aEnabled, bEnabled = rules.reaper[a.name] ~= false, rules.reaper[b.name] ~= false
            if general.enabledFirst and aEnabled ~= bEnabled then return aEnabled end
            if general.taskOrder == "alphabetical" then return taskOrder.alphabetical(a.name, b.name) end
            if general.taskOrder == "alphabeticalDescending" then
                return taskOrder.alphabeticalDescending(a.name, b.name)
            end
            return a.y == b.y and a.x < b.x or a.y < b.y
        end)
        for index, row in ipairs(snapshot.rows) do
            local slot = snapshot.slots[index]
            for _, item in ipairs(row.items) do
                local x, y = slot.x + item.x - row.x, slot.y + item.y - row.y
                if item.appliedX ~= x or item.appliedY ~= y then
                    item.control:SetPos(x, y)
                    item.appliedX, item.appliedY = x, y
                end
            end
        end
        snapshot.taskOrder, snapshot.enabledFirst = general.taskOrder, general.enabledFirst
        snapshot.enabled = {}
        for _, row in ipairs(snapshot.rows) do snapshot.enabled[row.name] = rules.reaper[row.name] ~= false end
    end
    return {
        restore = restore,
        update = function()
            local ok, err = pcall(update)
            if not ok then
                local list = snapshot and snapshot.list
                restore()
                if not list then
                    pcall(function() list = ui.Interfaces:GetComponent(1761, 1) end)
                end
                if rejected ~= list then print("[task-guard] Native task ordering unavailable: " .. tostring(err)) end
                rejected = list
            end
        end,
    }
end

return ordering
