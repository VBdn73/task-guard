-- Owned mouse shield. Never selects or modifies a native game action.
local overlay = {}
local requirements = require("reaper-requirements")

function overlay.new(config, prettyUILibrary)
    local name = config.name or "Helwyr"
    local shield, background, tooltip, target, parent, geometry, refreshTooltipPosition
    local localX, localY, width, height
    local function remove()
        local old = shield
        local oldBackground = background
        local oldTooltip = tooltip
        shield, target, parent, geometry = nil, nil, nil, nil
        background = nil
        tooltip = nil
        refreshTooltipPosition = nil
        local errors = {}
        if oldTooltip then
            local ok, err = pcall(function() oldTooltip:Destroy() end)
            if not ok then errors[#errors + 1] = tostring(err) end
        end
        if old then
            local ok, err = pcall(function() old:Destroy() end)
            if not ok then errors[#errors + 1] = tostring(err) end
        end
        if oldBackground then
            local ok, err = pcall(function() oldBackground:Destroy() end)
            if not ok then errors[#errors + 1] = tostring(err) end
        end
        if #errors > 0 then return "Overlay cleanup failed: " .. table.concat(errors, "; ") .. ". Close/reopen the choice dialog." end
        return "Test overlay removed."
    end
    local function resolve()
        local c
        if config.resolve then
            c = config.resolve()
        else
            local t = assert(config.label, "No verified label configured")
            c = ui.Interfaces:GetComponent(t.interfaceID, t.staticID, t.categoryID, t.dynamicID)
        end
        assert(c and not c.isRestricted and c.visibleGlobal, name .. " label unavailable")
        assert(c.type == ui.ComponentType.LABEL and c.content == name, "Label is not exactly " .. name)
        assert(c.parent and not c.parent.isRestricted, "Label parent unavailable/restricted")
        assert(c.width > 0 and c.height > 0, "Label has no usable bounds")
        return c
    end
    local function bounds(c)
        return table.concat({ c.x, c.y, c.width, c.height, c.xyGlobal.x, c.xyGlobal.y }, ":")
    end
    return {
        isShown = function() return shield ~= nil end,
        isMouseOver = function() return shield ~= nil and shield.isMouseOver == true end,
        show = function()
            if shield then return "Overlay already present; remove it before another test." end
            local ok, err = pcall(function()
                target = resolve()
                local pretty = prettyUILibrary or prettyui
                assert(pretty and pretty.Tooltip and pretty.Tooltip.attach, "PrettyUI Tooltip is required")
                parent, geometry = target.parent, bounds(target)
                localX, localY, width, height = target.x, target.y, target.width, target.height
                if not config.requirements then
                    background = ui.Button.new(parent)
                    requirements.markOwned(background)
                    background:SetPos(target.x, target.y)
                    background:SetSize(target.width, target.height)
                    -- Let the native stylesheet render its disabled background
                    -- in one component instead of nine separate sprite children.
                    -- This is only decoration: the enabled shield owns input.
                    background.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
                    background.label = ""
                    background.enabled = false
                    background.clickthrough = true
                    background:MoveToFront()
                end
                shield = ui.Button.new(parent)
                requirements.markOwned(shield)
                -- Match the verified label rectangle, not guessed padding into nearby choices.
                shield:SetPos(target.x, target.y)
                shield:SetSize(target.width, target.height)
                -- No stylesheet/sprites: no hover or pressed-state visuals.
                -- Keep inputs enabled to avoid risking click-through.
                shield.stylesheetID = -1
                shield.text.font = target.font or id.Font.MUSEO_SANS_15PT_REGULAR
                shield.text.rgba = target.rgba or 0xBDB8AEFF
                shield.label = config.requirements and "" or target.content
                shield.enabled = true
                -- Click-through controls do not reliably receive native hover
                -- hooks. Requirement-blocked rows need the same hit target, but
                -- no decoration or text. Never dispatch a native task action.
                shield.clickthrough = false
                shield:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
                    return false
                end)
                shield:MoveToFront()
                -- Owned, click-through popup: never changes native task requirements.
                -- Render outside the native scrolling list, which may clip owned children.
                local popupHost = parent
                for _ = 1, 16 do
                    local ancestor = popupHost.parent
                    if not ancestor or ancestor.isRestricted then break end
                    popupHost = ancestor
                end
                local function positionTooltip()
                    if not tooltip then return end
                    local origin, hostOrigin = target.xyGlobal, popupHost.xyGlobal
                    -- Like the icon picker: item position minus scroll origin,
                    -- never cursor position. Include nested native scroll regions.
                    local scrollX, scrollY = 0, 0
                    local ancestor = parent
                    while ancestor do
                        scrollX = scrollX + (ancestor.scrollX or 0)
                        scrollY = scrollY + (ancestor.scrollY or 0)
                        if ancestor == popupHost then break end
                        ancestor = ancestor.parent
                    end
                    local x = math.max(0, math.floor(origin.x - hostOrigin.x - scrollX + (target.width - tooltip.width) / 2))
                    local y = math.max(0, math.floor(origin.y - hostOrigin.y - scrollY - tooltip.height - 6))
                    if tooltip.options.x ~= x or tooltip.options.y ~= y then
                        tooltip.options.x, tooltip.options.y = x, y
                        if tooltip.root then tooltip.root:SetPos(x, y) end
                    end
                end
                -- Most rows are never hovered. Do not allocate a PrettyUI popup
                -- and its hover hooks for every disabled task at picker-open.
                refreshTooltipPosition = positionTooltip
                local function hover()
                    if not shield then return true end
                    if not tooltip then
                        tooltip = pretty.Tooltip.attach(shield, popupHost, {
                            text = config.requirements and "Blocked by requirements" or "Blocked by Task Guard plugin",
                            placement = "above", constrainToParent = false,
                        })
                        -- Keep our placement after PrettyUI's automatic hover
                        -- placement on subsequent entries as well.
                        shield:Subscribe(ui.Hook.ONMOUSEOVER, "taskGuard.tooltipPosition", hover)
                    end
                    if tooltip then
                        tooltip:Show()
                        positionTooltip()
                        if tooltip.root then
                            tooltip.root:SetPos(tooltip.options.x, tooltip.options.y)
                        end
                    end
                    return true
                end
                shield:Subscribe(ui.Hook.ONMOUSEOVER, "taskGuard.tooltipPosition", hover)
            end)
            if not ok then return "Overlay failed: " .. tostring(err) .. " | " .. remove() end
            if config.requirements then return "Requirements tooltip shown over " .. name .. "." end
            return "Overlay shown over " .. name .. " label bounds only. Edges, right-click and keyboard may bypass it."
        end,
        remove = remove,
        update = function()
            if not shield then return end
            local ok, valid = pcall(function()
                local c = resolve()
                if c ~= target or c.parent ~= parent or c.width ~= width or c.height ~= height then return false end
                local current = bounds(c)
                if current ~= geometry then
                    -- Ordering/scrolling can move the same native row. Keep
                    -- its shield and tooltip rather than rebuilding them.
                    if c.x ~= localX or c.y ~= localY then
                        shield:SetPos(c.x, c.y)
                        if background then background:SetPos(c.x, c.y) end
                        localX, localY = c.x, c.y
                    end
                    geometry = current
                end
                return shield.visibleGlobal
            end)
            if not ok or not valid then
                print("[task-guard] Target changed or overlay unavailable. " .. remove())
            elseif refreshTooltipPosition and shield.isMouseOver then
                local positioned, err = pcall(refreshTooltipPosition)
                if not positioned then
                    print("[task-guard] Tooltip positioning failed: " .. tostring(err) .. " | " .. remove())
                end
            end
        end,
    }
end

return overlay
