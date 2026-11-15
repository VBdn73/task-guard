local tasks = require("tasks/reaper/catalogue")
local slayerTasks = require("tasks/slayer/catalogue")
local settings = {}
local STORAGE_KEY = "taskGuard.tasks.v1.displayName."
local contexts = setmetatable({}, { __mode = "k" })
local defaultTasks = {}
for i, name in ipairs(tasks) do defaultTasks[i] = name end
local function getCharacterContext()
    if Player and Player.IsAvailable() then
        local player = Player.GetEntity()
        if player and player.isValid and type(player.displayName) == "string" then
            local name = player.displayName:match("^%s*(.-)%s*$"):lower()
            if name ~= "" then return name end
        end
    end
end
local NAME_VERSION = 2
local MAX_NAME_LENGTH = 120
local LEGACY_REAPER_NAMES = { ["Telos, the Warden"] = "Telos",
    ["Black stone dragon"] = "Black Stone Dragon", ["Giant mole"] = "Giant Mole" }
local LEGACY_SLAYER_NAMES = { ["Kalphite"] = "Kalphites", ["Kurask"] = "Kurasks",
    ["Turoth"] = "Turoths", ["Zombies"] = "Zombie", ["Cave slimes"] = "Cave slime",
    ["Profane scabarites"] = "Profane Scabarites", ["Ravenous strigoi"] = "Ravenous Strigoi" }
local function validOrder(value)
    if value == "alphabetical" or value == "alphabeticalDescending" then return value end
    return "default"
end
local function validName(name)
    return type(name) == "string" and #name > 0 and #name <= MAX_NAME_LENGTH
        and not name:find("[%c<>]") and name:find("%S") ~= nil
end

function settings.load()
    local context = getCharacterContext()
    local ok, saved = false, nil
    if context then
        ok, saved = pcall(function() return PersistentDB:GetStructuredData(STORAGE_KEY .. context) end)
    end
    -- Discovered tasks belong to the character too, not the previous session.
    for i = #tasks, 1, -1 do tasks[i] = nil end
    for i, name in ipairs(defaultTasks) do tasks[i] = name end
    local migrated = ok and type(saved) == "table" and saved.nameVersion ~= NAME_VERSION
    if migrated then
        -- Legacy storage migration only. Runtime matching uses exact native names.
        local oldNames = LEGACY_REAPER_NAMES
        local data = { reaper = {}, slayer = saved.slayer, discovered = {}, general = saved.general }
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
    local slayer = ok and type(saved) == "table" and saved.slayer or nil
    -- Catalogue spelling migration only; no runtime fuzzy-name matching.
    local oldSlayerNames = LEGACY_SLAYER_NAMES
    local rules = { reaper = {}, slayer = {}, general = {
        taskOrder = validOrder(type(general) == "table" and general.taskOrder),
        enabledFirst = type(general) == "table" and general.enabledFirst == true or false,
    } }
    for _, name in ipairs(slayerTasks) do
        local oldName = oldSlayerNames[name]
        rules.slayer[name] = not (type(slayer) == "table"
            and (slayer[name] == false or (oldName and slayer[oldName] == false)))
        if type(slayer) == "table" and oldName and slayer[oldName] ~= nil then migrated = true end
    end
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
    contexts[rules] = context
    if migrated and not settings.save(rules) then
        print("[task-guard] Could not save native task-name migration; preferences retained for this session.")
    end
    return rules
end

function settings.save(rules)
    local context = getCharacterContext()
    if not context or contexts[rules] ~= context then return false end
    local general = rules.general or {}
    local data = { nameVersion = NAME_VERSION, reaper = {}, slayer = {}, discovered = {}, general = {
        taskOrder = validOrder(general.taskOrder),
        enabledFirst = general.enabledFirst == true,
    } }
    for _, name in ipairs(tasks) do data.reaper[name] = rules.reaper[name] ~= false end
    for _, name in ipairs(slayerTasks) do
        data.slayer[name] = not rules.slayer or rules.slayer[name] ~= false
    end
    -- Persist the complete catalogue so dynamically discovered names survive reloads.
    for _, name in ipairs(tasks) do data.discovered[#data.discovered + 1] = name end
    local ok, result = pcall(function() return PersistentDB:SetStructuredData(STORAGE_KEY .. context, data) end)
    return ok and result ~= false
end

function settings.refresh(rules)
    if contexts[rules] == getCharacterContext() then return false end
    local loaded = settings.load()
    rules.reaper, rules.slayer, rules.general = loaded.reaper, loaded.slayer, loaded.general
    contexts[rules] = contexts[loaded]
    return true
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
