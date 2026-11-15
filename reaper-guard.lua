-- Resolve fresh, exact labels only in the captured choice list, never globally.
local factory = require("reaper-overlay")
local tasks = require("reaper-tasks")
local guard = {}

function guard.new(rules, pretty)
    local known, shields, matches, failures = {}, {}, {}, {}
    for _, name in ipairs(tasks) do known[name] = name end
    for label, name in pairs(require("reaper-task-aliases")) do
        assert(known[name], "Unknown Reaper preference key: " .. name)
        known[label] = name
    end
    local function clear()
        matches, failures = {}, {}
        for name, shield in pairs(shields) do
            shield.remove()
            shields[name] = nil
        end
    end
    local function discover()
        local found, duplicate, count = {}, {}, 0
        local list = ui.Interfaces:GetComponent(1761, 1)
        local title = ui.Interfaces:GetComponent(1761, 7, 0, 14)
        if not list or list.isRestricted or not list.visibleGlobal
            or not title or title.isRestricted or not title.visibleGlobal
            or title.type ~= ui.ComponentType.LABEL or title.content ~= "Pick A task" then
            return found
        end
        -- Snapshot before creating owned components. Never match our own grey text.
        list:IterateDynamicComponents(function(c)
            if c and not c.isRestricted and c.visibleGlobal and c.parent == list
                and c.type == ui.ComponentType.LABEL and known[c.content]
                and c.width > 0 and c.height > 0 then
                local name = known[c.content]
                if found[name] then duplicate[name] = true else count = count + 1 end
                found[name] = c
            end
            return false
        end)
        -- The generic title alone is not Reaper-specific. Require multiple
        -- distinct catalogue labels in the captured list; ambiguous names are ignored.
        if count < 2 then return {} end
        for name in pairs(duplicate) do found[name] = nil end
        return found
    end
    local lastError
    return {
        remove = clear,
        update = function()
            local ok, result = pcall(discover)
            if not ok then
                clear()
                local message = tostring(result)
                if message ~= lastError then print("[task-guard] Reaper protection unavailable: " .. message) end
                lastError = message
                return
            end
            lastError, matches = nil, result
            for name, shield in pairs(shields) do
                if rules.reaper[name] ~= false or not matches[name] then
                    shield.remove()
                    shields[name] = nil
                else
                    shield.update()
                end
            end
            for name in pairs(matches) do
                if rules.reaper[name] == false then
                    local shield = shields[name]
                    if not shield then
                        shield = factory.new({ name = matches[name].content,
                            resolve = function() return matches[name] end }, pretty)
                        shields[name] = shield
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
        end,
    }
end

return guard
