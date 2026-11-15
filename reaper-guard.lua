-- Resolve fresh, exact labels only in the captured choice list, never globally.
local factory = require("reaper-overlay")
local tasks = require("reaper-tasks")
local settings = require("task-settings")
local requirements = require("reaper-requirements")
local guard = {}

function guard.new(rules, pretty)
    local known, shields, matches, failures = {}, {}, {}, {}
    local blocked, modes = {}, {}
    for _, name in ipairs(tasks) do known[name] = name end
    local function clear()
        matches, failures = {}, {}
        blocked, modes = {}, {}
        for name, shield in pairs(shields) do
            shield.remove()
            shields[name] = nil
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
        for name, c in pairs(found) do
            if requirements.isBlocked(c, sprites) then blocked[name] = true end
        end
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
        end,
    }
end

return guard
