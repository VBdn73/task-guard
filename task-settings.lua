local tasks = require("reaper-tasks")
local settings = {}
local key = "taskGuard.tasks.v1"
local function validOrder(value)
    if value == "alphabetical" or value == "alphabeticalDescending" then return value end
    return "default"
end
local function validName(name)
    return type(name) == "string" and #name > 0 and #name <= 120
        and not name:find("[%c<>]") and name:find("%S") ~= nil
end

function settings.load()
    local ok, saved = pcall(function() return PersistentDB:GetStructuredData(key) end)
    local migrated = ok and type(saved) == "table" and saved.nameVersion ~= 2
    if migrated then
        -- Legacy storage migration only. Runtime matching uses exact native names.
        local oldNames = { ["Telos, the Warden"] = "Telos",
            ["Black stone dragon"] = "Black Stone Dragon", ["Giant mole"] = "Giant Mole" }
        local data = { reaper = {}, discovered = {}, general = saved.general }
        if type(saved.reaper) == "table" then
            for name, value in pairs(saved.reaper) do
                local native = oldNames[name] or name
                if data.reaper[native] == nil or value == false then data.reaper[native] = value end
            end
        end
        if type(saved.discovered) == "table" then
            for _, name in ipairs(saved.discovered) do
                data.discovered[#data.discovered + 1] = oldNames[name] or name
            end
        end
        saved = data
    end
    local reaper = ok and type(saved) == "table" and saved.reaper or nil
    local general = ok and type(saved) == "table" and saved.general or nil
    local rules = { reaper = {}, general = {
        taskOrder = validOrder(type(general) == "table" and general.taskOrder),
        enabledFirst = type(general) == "table" and general.enabledFirst == true or false,
    } }
    for _, name in ipairs(tasks) do
        -- Enabled means allowed. No unwanted tasks are configured by default.
        rules.reaper[name] = not (type(reaper) == "table" and reaper[name] == false)
    end
    local known = {}
    for _, name in ipairs(tasks) do known[name] = true end
    local discovered = ok and type(saved) == "table" and saved.discovered or nil
    if type(discovered) == "table" then
        for _, name in ipairs(discovered) do
            if validName(name) and not known[name] then
                tasks[#tasks + 1], known[name] = name, true
                rules.reaper[name] = not (type(reaper) == "table" and reaper[name] == false)
            end
        end
    end
    if migrated and not settings.save(rules) then
        print("[task-guard] Could not save native task-name migration; preferences retained for this session.")
    end
    return rules
end

function settings.save(rules)
    local general = rules.general or {}
    local data = { nameVersion = 2, reaper = {}, discovered = {}, general = {
        taskOrder = validOrder(general.taskOrder),
        enabledFirst = general.enabledFirst == true,
    } }
    for _, name in ipairs(tasks) do data.reaper[name] = rules.reaper[name] ~= false end
    -- Persist the complete catalogue so dynamically discovered names survive reloads.
    for _, name in ipairs(tasks) do data.discovered[#data.discovered + 1] = name end
    local ok, result = pcall(function() return PersistentDB:SetStructuredData(key, data) end)
    return ok and result ~= false
end

function settings.discover(rules, names)
    local known, added = {}, {}
    for _, name in ipairs(tasks) do known[name] = true end
    for _, name in ipairs(names) do
        if validName(name) and not known[name] then
            known[name] = true
            tasks[#tasks + 1] = name
            rules.reaper[name] = true
            added[#added + 1] = name
        end
    end
    if #added == 0 then return true end
    if settings.save(rules) then return true end
    for i = #added, 1, -1 do
        rules.reaper[added[i]] = nil
        table.remove(tasks)
    end
    return false
end

return settings
