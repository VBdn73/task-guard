-- Owned mouse shield. Never selects or modifies a native game action.
local overlay = {}
local requirements = require("tasks/requirements")
local tooltipFactory = require("ui/task-tooltip")
local constants = require("tasks/picker-constants")
local MAX_TOOLTIP_ANCESTORS = 16
local TOOLTIP_GAP = 6
local activeTooltip

local function destroyComponent(component, errors)
    if not component then return end
    local ok, err = pcall(function() component:Destroy() end)
    if not ok then errors[#errors + 1] = tostring(err) end
end

function overlay.new(config, prettyUILibrary)
    local name = assert(config.name, "Task name is required")
    local shield, background, tooltip, target, parent, refreshTooltipPosition, activateTooltip
    local localX, localY, width, height
    local hovering = false
    local function remove()
        local old = shield
        local oldBackground = background
        local oldTooltip = tooltip
        if activeTooltip == oldTooltip then activeTooltip = nil end
        shield, target, parent = nil, nil, nil
        background = nil
        tooltip = nil
        refreshTooltipPosition = nil
        activateTooltip = nil
        hovering = false
        local errors = {}
        destroyComponent(oldTooltip, errors)
        destroyComponent(old, errors)
        destroyComponent(oldBackground, errors)
        if #errors > 0 then return "Overlay cleanup failed: " .. table.concat(errors, "; ") .. ". Close/reopen the choice dialog." end
        return "Overlay removed."
    end
    local function resolve()
        local c
        if config.resolve then
            c = config.resolve()
        else
            error("Task resolver is required")
        end
        assert(c and not c.isRestricted and c.visibleGlobal, name .. " label unavailable")
        assert(c.type == ui.ComponentType.LABEL and c.content == name, "Label is not exactly " .. name)
        assert(c.parent and not c.parent.isRestricted, "Label parent unavailable/restricted")
        assert(c.width > 0 and c.height > 0, "Label has no usable bounds")
        return c
    end
    return {
        isShown = function() return shield ~= nil end,
        isMouseOver = function()
            if not shield then return false end
            if config.isHovered then
                local current = config.isHovered()
                if current ~= nil then return current end
            end
            return hovering or shield.isMouseOver == true
        end,
        show = function()
            if shield then return "Overlay already present." end
            local ok, err = pcall(function()
                target = resolve()
                parent = target.parent
                localX, localY, width, height = target.x, target.y, target.width, target.height
                -- One canvas replaces the tint: draw commands are not dynamic
                -- components, so text cannot become a separate native hit target.
                do
                    background = ui.Canvas.new(parent)
                    requirements.markOwned(background)
                    background:SetPos(target.x, target.y)
                    background:SetSize(target.width, target.height)
                    -- Cover the underlying enabled/hover/pressed appearance,
                    -- including any transparent pixels in the disabled artwork.
                    background:AddRectangle(0, 0, width, height, 0x201F1BFF)
                    if width == constants.ROW_WIDTH and height == constants.ROW_HEIGHT then
                        for index = 0, constants.ROW_SPRITE_COUNT - 1 do
                            local column, row = index % 3 + 1, math.floor(index / 3) + 1
                            background:AddSprite(constants.SPRITE_X[column], constants.SPRITE_Y[row],
                                constants.SPRITE_WIDTH[column], constants.SPRITE_HEIGHT[row],
                                constants.DISABLED_SPRITE_FIRST + index, 0xFFFFFFFF)
                        end
                    end
                    local text = ui.TextDataConfig.new()
                    text.font = target.font or id.Font.MUSEO_SANS_15PT_REGULAR
                    text.alignHorizontal, text.alignVertical = ui.AlignMode.CENTRE, ui.AlignMode.CENTRE
                    text.colour = Vector4.new(0.74, 0.72, 0.68, 1)
                    background:AddText(0, 0, width, height, name, text)
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
                -- Keep text off the enabled input catcher: native buttons can
                -- brighten their label on press even with no stylesheet.
                shield.label = ""
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
                for _ = 1, MAX_TOOLTIP_ANCESTORS do
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
                    local y = math.max(0, math.floor(origin.y - hostOrigin.y - scrollY - tooltip.height - TOOLTIP_GAP))
                    if tooltip.options.x ~= x or tooltip.options.y ~= y then
                        tooltip.options.x, tooltip.options.y = x, y
                        if tooltip.root then tooltip.root:SetPos(x, y) end
                    end
                end
                -- Most rows are never hovered. Allocate a single-canvas popup
                -- only on first hover, with no additional target hooks.
                refreshTooltipPosition = positionTooltip
                local hover
                local function leave()
                    hovering = false
                    if tooltip then tooltip:Hide() end
                    return true
                end
                local function ensureTooltip()
                    if not tooltip then
                        tooltip = tooltipFactory.new(popupHost, {
                            text = config.tooltipText or (config.requirements and "Blocked by requirements" or "Blocked by Task Guard plugin"),
                            placement = "above", constrainToParent = false,
                        })
                    end
                end
                hover = function()
                    if not shield then return true end
                    if config.isHovered and config.isHovered() == false then return leave() end
                    hovering = true
                    -- Defer requirement popup creation to the next logic tick.
                    if config.requirements and not tooltip then return true end
                    ensureTooltip()
                    if tooltip then
                        if activeTooltip and activeTooltip ~= tooltip then activeTooltip:Hide() end
                        activeTooltip = tooltip
                        positionTooltip()
                        tooltip:Show()
                    end
                    return true
                end
                shield:Subscribe(ui.Hook.ONMOUSEOVER, "taskGuard.tooltipPosition", hover)
                shield:Subscribe(ui.Hook.ONMOUSELEAVE, "taskGuard.tooltipLeave", leave)
                if config.requirements and ui.Hook.ONMOUSEREPEAT then
                    shield:Subscribe(ui.Hook.ONMOUSEREPEAT, "taskGuard.tooltipRepeat", hover)
                end
                activateTooltip = function()
                    ensureTooltip()
                    hover()
                end
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
                if c.x ~= localX or c.y ~= localY then
                    -- Ordering/scrolling can move the same native row. Keep
                    -- its shield and tooltip rather than rebuilding them.
                    shield:SetPos(c.x, c.y)
                    if background then background:SetPos(c.x, c.y) end
                    localX, localY = c.x, c.y
                end
                if config.isHovered then
                    local cursorHover = config.isHovered()
                    if cursorHover == true or (cursorHover == nil
                        and (hovering or shield.isMouseOver or target.isMouseOver)) then
                        activateTooltip()
                    elseif cursorHover == false then
                        hovering = false
                        if tooltip then tooltip:Hide() end
                    end
                end
                -- Do not remove a verified row's controls just because native
                -- scrolling clips the shield. Resolve still validates the target
                -- and guards remove stale rows when the dialog/layout changes.
                return true
            end)
            if not ok or not valid then
                remove()
            elseif refreshTooltipPosition and (hovering or (not config.isHovered and shield.isMouseOver)
                or (not config.isHovered and config.requirements and target.isMouseOver)) then
                local positioned, err = pcall(refreshTooltipPosition)
                if positioned and not tooltip and activateTooltip then
                    positioned, err = pcall(activateTooltip)
                end
                if not positioned then
                    print("[task-guard] Tooltip positioning failed: " .. tostring(err) .. " | " .. remove())
                end
            end
        end,
    }
end

return overlay
