-- Experimental mouse-only guard for the captured Spria/Laniakea picker.
-- Never changes native actions or game block/prefer lists.
local factory = require("reaper-overlay")
local requirements = require("reaper-requirements")
local tasks = require("slayer-tasks")
local settings = require("task-settings")
local guard = {}
local spriteXs, spriteYs = { 0, 8, 222 }, { 0, 8, 12 }
local spriteWidths, spriteHeights = { 8, 214, 8 }, { 8, 4, 8 }
local spriteBases = { 18468, 18477, 18504 }

function guard.new(rules, pretty)
    local nativeOrder = require("slayer-order").new(rules)
    local known, shields = {}, {}
    for _, name in ipairs(tasks) do known[name] = true end
    local stopped, lastError = false, nil
    local matches = {}
    local activeAction
    local function remove(c)
        local entry = shields[c]
        shields[c] = nil
        if entry then
            local ok, err = pcall(entry.shield.remove)
            if not ok then print("[task-guard] Slayer overlay cleanup failed: " .. tostring(err)) end
        end
    end
    local function clear()
        matches = {}
        activeAction = nil
        for c in pairs(shields) do remove(c) end
    end
    local function available(c)
        return c and not c.isRestricted and c.visibleGlobal
    end
    local function rowKey(c)
        -- API enumerations may return fresh Lua wrappers. Table keys use raw
        -- wrapper identity, even when native component equality is supported.
        return table.concat({ c.interfaceID, c.staticID, c.categoryID, c.dynamicID }, ":")
    end
    local function validBackground(c, sprites)
        local seen, count, base = {}, 0, nil
        for _, sprite in ipairs(sprites) do
            if sprite.x < c.x + c.width and sprite.x + sprite.width > c.x
                and sprite.y < c.y + c.height and sprite.y + sprite.height > c.y then
                local index, spriteBase
                for _, start in ipairs(spriteBases) do
                    if sprite.spriteID >= start and sprite.spriteID <= start + 8 then
                        index, spriteBase = sprite.spriteID - start, start
                    end
                end
                if not index or index % 1 ~= 0 or seen[index] or (base and base ~= spriteBase) then return false end
                local col, row = index % 3 + 1, math.floor(index / 3) + 1
                if sprite.x ~= c.x + spriteXs[col] or sprite.y ~= c.y + spriteYs[row]
                    or sprite.width ~= spriteWidths[col] or sprite.height ~= spriteHeights[row] then return false end
                base, seen[index], count = spriteBase, true, count + 1
            end
        end
        return count == 9
    end
    local function inside(c, viewport)
        -- Native scroll offsets are not necessarily included in xyGlobal.
        local x, y = c.xyGlobal.x, c.xyGlobal.y
        local ancestor = c.parent
        for _ = 1, 16 do
            if not available(ancestor) then return false end
            x, y = x - (ancestor.scrollX or 0), y - (ancestor.scrollY or 0)
            if ancestor == viewport then
                local origin = viewport.xyGlobal
                -- Owned shields remain children of the native scrolling list,
                -- so the viewport clips them exactly like the original row.
                return x < origin.x + viewport.width and y < origin.y + viewport.height
                    and x + c.width > origin.x and y + c.height > origin.y
            end
            ancestor = ancestor.parent
        end
        return false
    end
    local function discover()
        local title = ui.Interfaces:GetComponent(201, 7, 0, 14)
        local list = ui.Interfaces:GetComponent(201, 5)
        local companion = ui.Interfaces:GetComponent(201, 4)
        local viewport = ui.Interfaces:GetComponent(201, 3)
        local root = ui.Interfaces:GetComponent(201, 0)
        if not available(title) or title.type ~= ui.ComponentType.LABEL
            or title.content ~= "Select your Slayer task" then return {} end
        if not available(root) or not available(list) or not available(companion) or not available(viewport)
            or list.type ~= 20 or companion.type ~= 20 or viewport.type ~= 20
            or list.parent ~= viewport or companion.parent ~= viewport
            or not available(viewport.parent) or viewport.parent.parent ~= root
            or not available(title.parent) or title.parent.parent ~= root
            or list.width ~= 480 or companion.width ~= 480 or viewport.width ~= 480
            or list.x ~= companion.x or list.y ~= companion.y then return {} end
        local labels, sprites, empty, companionLabels, occurrences, distinct = {}, {}, {}, {}, {}, 0
        list:IterateDynamicComponents(function(c)
            if available(c) and c.parent == list and not requirements.isOwned(c) then
                requirements.capture(c, list, sprites)
                if c.type == ui.ComponentType.LABEL and c.content ~= "" then
                    labels[#labels + 1] = c
                    occurrences[c.content] = (occurrences[c.content] or 0) + 1
                    if known[c.content] and occurrences[c.content] == 1 then distinct = distinct + 1 end
                end
            end
            return false
        end)
        companion:IterateDynamicComponents(function(c)
            if available(c) and c.parent == companion and c.type == ui.ComponentType.LABEL
                and c.content == "" and c.width == 230 and c.height == 20 then
                local key = c.x .. ":" .. c.y
                empty[key] = (empty[key] or 0) + 1
                companionLabels[key] = c
            end
            return false
        end)
        if distinct < 2 then return {} end
        -- Bucket the snapshot by captured row slot once. Each row now examines
        -- its own nine sprites rather than the complete picker twice per tick.
        local spriteRows = {}
        for _, sprite in ipairs(sprites) do
            local first = math.max(0, math.floor((sprite.y - 5) / 23))
            local last = math.floor((sprite.y + sprite.height - 5) / 23)
            -- Preserve rejection of malformed artwork overlapping neighbouring
            -- slots, not just well-formed sprites in their expected slot.
            for row = first, last do
                local y = 5 + row * 23
                for column = 0, 1 do
                    local x = 8 + column * 240
                    if sprite.x < x + 230 and sprite.x + sprite.width > x
                        and sprite.y < y + 20 and sprite.y + sprite.height > y then
                        local key = x .. ":" .. y
                        spriteRows[key] = spriteRows[key] or {}
                        local bucket = spriteRows[key]
                        bucket[#bucket + 1] = sprite
                    end
                end
            end
        end
        local found = {}
        for _, c in ipairs(labels) do
            local name = c.content
            local rowSprites = spriteRows[c.x .. ":" .. c.y] or {}
            local blocked = requirements.isBlocked(c, rowSprites)
            local companionCount = empty[c.x .. ":" .. c.y]
            if known[name] and (occurrences[name] == 1 or name == "Ravenous strigoi")
                and c.width == 230 and c.height == 20 and (c.x == 8 or c.x == 248)
                and c.y >= 5 and (c.y - 5) % 23 == 0
                -- Native disabled rows can omit/hide their companion hit label.
                -- Only complete disabled artwork permits that missing label;
                -- available rows and ambiguous duplicate companions stay strict.
                and (companionCount == 1 or (blocked and companionCount == nil))
                and inside(c, viewport)
                and validBackground(c, rowSprites) then
                found[rowKey(c)] = { component = c, name = name,
                    companion = companionLabels[c.x .. ":" .. c.y],
                    blocked = blocked, viewport = viewport }
            end
        end
        return found
    end
    local controller
    controller = {
        menuOpened = function(menu)
            if stopped or not activeAction then return end
            -- MiniMenuReady also runs for ordinary hover/default left clicks.
            -- Only an action actually presented in an explicit right-click
            -- menu may alter preferences. Newly rebuilt hover actions stay inert.
            for _, entry in ipairs(menu.entries) do
                if entry.overrideText == activeAction.text or entry.fullText == activeAction.text
                    or entry.verbText == activeAction.text or entry.label == activeAction.text then
                    activeAction.presented = true
                    return
                end
            end
        end,
        addMenu = function(menu)
            if stopped then return end
            -- Native dispatch may retain callbacks from previous menu builds.
            -- Only the most recently offered action is eligible to change rules.
            activeAction = nil
            controller.update()
            local selected, target, selectedKey
            for key, row in pairs(matches) do
                local c = row.component
                local entry = shields[key]
                local hovered = c.isMouseOver or (entry and entry.shield.isMouseOver
                    and entry.shield.isMouseOver())
                for _, action in ipairs(menu.entries) do
                    if action.componentData and action.componentData.component == c then hovered = true end
                end
                if hovered then
                    if selected then return end
                    selected, target, selectedKey = row.name, c, key
                end
            end
            if not selected or matches[selectedKey].blocked then return end
            local enabled = rules.slayer[selected] ~= false
            local text = enabled and "Disable task" or "Enable task"
            local taskID
            -- Keep callback dispatch IDs separate from Reaper's catalogue IDs.
            for index, name in ipairs(tasks) do if name == selected then taskID = 10000 + index; break end end
            local actionToken = { text = text, presented = false }
            activeAction = actionToken
            local beforeCount = menu.entryCount or #menu.entries
            local cancelIndex
            for index, entry in ipairs(menu.entries) do
                if entry.verbText == "Cancel"
                    or (MiniMenuActionType and entry.actionType == MiniMenuActionType.CANCEL) then
                    cancelIndex = index
                    break
                end
            end
            menu:Add(text, function(selectedID)
                if stopped or selectedID ~= taskID or activeAction ~= actionToken
                    or not actionToken.presented then return end
                activeAction = nil
                -- Never reconcile shields during native menu dispatch. Creating
                -- or destroying controls under that click can rebuild the menu
                -- and dispatch a second task action. Validate a read-only fresh
                -- snapshot, then let the next normal logic tick update shields.
                local ok, current = pcall(discover)
                if not ok then return end
                local row = current[selectedKey]
                if not row or row.component ~= target or row.name ~= selected or row.blocked then return end
                local old = rules.slayer[selected]
                rules.slayer[selected] = not enabled
                if not settings.save(rules) then
                    rules.slayer[selected] = old
                    print("[task-guard] Could not save " .. selected .. " Slayer setting.")
                end
            end, taskID)
            -- Locate the added action rather than assuming Add appends: clients
            -- may insert it at the front. Swapping from an assumed append index
            -- then moves native Choose away from the left-click default.
            -- Keep the toggle before Cancel, including Cancel-only shield menus.
            local actionIndex, currentCancel
            for index, entry in ipairs(menu.entries) do
                if entry.overrideText == text or entry.fullText == text
                    or entry.verbText == text or entry.label == text then actionIndex = index end
                if entry.verbText == "Cancel"
                    or (MiniMenuActionType and entry.actionType == MiniMenuActionType.CANCEL) then
                    currentCancel = index
                end
            end
            -- Retain the append fallback for clients exposing a stale snapshot.
            local destination
            if actionIndex then
                destination = currentCancel or 1
                if currentCancel and actionIndex < currentCancel then destination = currentCancel - 1 end
            else
                actionIndex = menu.entryCount or (beforeCount + 1)
                destination = cancelIndex or 1
            end
            while actionIndex < destination do
                menu:Swap(actionIndex, actionIndex + 1)
                actionIndex = actionIndex + 1
            end
            while actionIndex > destination do
                menu:Swap(actionIndex - 1, actionIndex)
                actionIndex = actionIndex - 1
            end
        end,
        update = function()
            if stopped then return end
            nativeOrder.update()
            local ok, found = pcall(discover)
            if not ok then
                clear()
                local message = tostring(found)
                if message ~= lastError then print("[task-guard] Slayer protection unavailable: " .. message) end
                lastError = message
                return
            end
            lastError, matches = nil, found
            for key, entry in pairs(shields) do
                local row = found[key]
                if not row or row.component ~= entry.component or row.name ~= entry.name or row.blocked ~= entry.blocked
                    or (rules.slayer[row.name] ~= false and not row.blocked) then remove(key) end
            end
            for key, row in pairs(found) do
                if rules.slayer[row.name] == false or row.blocked then
                    local entry = shields[key]
                    if not entry then
                        local name, viewport = row.name, row.viewport
                        entry = { component = row.component, name = name, blocked = row.blocked,
                            shield = factory.new({ name = name, requirements = row.blocked,
                                tooltipText = row.blocked and "Blocked by in-game requirements or your personal Slayer block list" or nil,
                                isHovered = row.blocked and function()
                                    local current = matches[key]
                                    if not current then return false end
                                    local c = current.component
                                    if c.isMouseOver or (current.companion and current.companion.isMouseOver) then return true end
                                    local ok, mouse = pcall(function() return Mouse.GetPosition() end)
                                    if not ok or not mouse then return nil end
                                    local scale = (game and game.options and game.options.InterfaceScale
                                        and tonumber(game.options.InterfaceScale.setting) or 100) / 100
                                    if scale <= 0 then scale = 1 end
                                    local mouseX, mouseY = mouse.x / scale, mouse.y / scale
                                    local x, y = c.xyGlobal.x, c.xyGlobal.y
                                    local ancestor = c.parent
                                    while ancestor do
                                        x, y = x - (ancestor.scrollX or 0), y - (ancestor.scrollY or 0)
                                        ancestor = ancestor.parent
                                    end
                                    local origin = viewport.xyGlobal
                                    return mouseX >= x and mouseX < x + c.width
                                        and mouseY >= y and mouseY < y + c.height
                                        and mouseX >= origin.x and mouseX < origin.x + viewport.width
                                        and mouseY >= origin.y and mouseY < origin.y + viewport.height
                                end or nil,
                                resolve = function()
                                    local current = matches[key]
                                    local c = current and current.component
                                    assert(c, "Slayer row unavailable")
                                    assert(c.content == name and inside(c, viewport), "Slayer row changed or clipped")
                                    return c
                                end }, pretty) }
                        shields[key] = entry
                    end
                    entry.shield.update()
                    if not entry.shield.isShown() then
                        local message = entry.shield.show()
                        if not entry.shield.isShown() and message ~= entry.failure then
                            print("[task-guard] " .. message)
                            entry.failure = message
                        end
                    end
                end
            end
        end,
        remove = clear,
        shutdown = function() stopped = true; clear(); nativeOrder.restore() end,
    }
    return controller
end

return guard
