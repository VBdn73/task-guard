-- Manual mouse-shield experiment. Never selects a native game action.
local overlay = {}

function overlay.new(config)
    local shield, background, target, parent, geometry
    local function remove()
        local old = shield
        local oldBackground = background
        shield, target, parent, geometry = nil, nil, nil, nil
        background = nil
        local errors = {}
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
        local t = assert(config.label, "No verified label configured")
        local c = ui.Interfaces:GetComponent(t.interfaceID, t.staticID, t.categoryID, t.dynamicID)
        assert(c and not c.isRestricted and c.visibleGlobal, "Helwyr label unavailable")
        assert(c.type == ui.ComponentType.LABEL and c.content == "Helwyr", "Label is not exactly Helwyr")
        assert(c.parent and not c.parent.isRestricted, "Label parent unavailable/restricted")
        assert(c.width > 0 and c.height > 0, "Label has no usable bounds")
        return c
    end
    local function bounds(c)
        return table.concat({ c.x, c.y, c.width, c.height, c.xyGlobal.x, c.xyGlobal.y }, ":")
    end
    return {
        show = function()
            if shield then return "Overlay already present; remove it before another test." end
            local ok, err = pcall(function()
                target = resolve()
                parent, geometry = target.parent, bounds(target)
                background = ui.Rectangle.new(parent)
                background:SetPos(target.x, target.y)
                background:SetSize(target.width, target.height)
                background.fill = true
                background.rgba = 0x292929FF
                background.clickthrough = true
                background:MoveToFront()
                shield = ui.Button.new(parent)
                -- Match the verified label rectangle, not guessed padding into nearby choices.
                shield:SetPos(target.x, target.y)
                shield:SetSize(target.width, target.height)
                -- No stylesheet/sprites: no hover or pressed-state visuals.
                -- Keep inputs enabled to avoid risking click-through.
                shield.stylesheetID = -1
                shield.text.font = id.Font.MUSEO_SANS_15PT_REGULAR
                shield.text.rgba = 0x888888FF
                shield.label = "Helwyr — blocked (test)"
                shield.enabled = true
                shield.clickthrough = false
                shield:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
                    print("[task-guard] Test overlay received a press. Verify no native task was selected.")
                    return false
                end)
                shield:MoveToFront()
            end)
            if not ok then return "Overlay failed: " .. tostring(err) .. " | " .. remove() end
            return "Test overlay shown over Helwyr label bounds only. Mouse blocking NOT verified; edges, right-click and keyboard may bypass it."
        end,
        remove = remove,
        update = function()
            if not shield then return end
            local ok, valid = pcall(function()
                local c = resolve()
                return c == target and c.parent == parent and bounds(c) == geometry and shield.visibleGlobal
            end)
            if not ok or not valid then
                print("[task-guard] Target changed or overlay unavailable. " .. remove())
            end
        end,
    }
end

return overlay
