local tasks = require("reaper-tasks")
local settings = {}
local key = "taskGuard.tasks.v1"

function settings.load()
    local ok, saved = pcall(function() return PersistentDB:GetStructuredData(key) end)
    local reaper = ok and type(saved) == "table" and saved.reaper or nil
    local rules = { reaper = {} }
    for _, name in ipairs(tasks) do
        -- Enabled means allowed. No unwanted tasks are configured by default.
        rules.reaper[name] = not (type(reaper) == "table" and reaper[name] == false)
    end
    return rules
end

function settings.save(rules)
    local data = { reaper = {} }
    for _, name in ipairs(tasks) do data.reaper[name] = rules.reaper[name] ~= false end
    local ok, result = pcall(function() return PersistentDB:SetStructuredData(key, data) end)
    return ok and result ~= false
end

return settings
