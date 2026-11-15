local constants = require("constants")
local settingsView = require("ui/settings-view")
local settings = require("tasks/settings")
local rules = settings.load()
local tasks = require("tasks/reaper/catalogue")
local refreshViews = {}
local destroyViews = {}
local hosts = {}
local viewStates = { settings = {}, content = {} }
local openView
local closeView
local stopped = false
local taskCount = #tasks
local reaperGuard = require("tasks/reaper/guard").new(rules, prettyui)
local slayerGuard = require("tasks/slayer/guard").new(rules, prettyui)
local subscriptions = {}

-- Keep failure reporting while allowing independent cleanup to continue.
local function try(action, callback)
    local ok, result, extra = pcall(callback)
    if not ok then
        print("[task-guard] " .. action .. ": " .. tostring(result))
    end
    return ok, result, extra
end

local function subscribe(event, suffix, callback)
    local name = constants.EVENT_PREFIX .. suffix
    event.Subscribe(name, function(...)
        if not stopped then return callback(...) end
    end)
    subscriptions[#subscriptions + 1] = { event = event, name = name }
end

closeView = function(kind)
    hosts[kind] = nil
    refreshViews[kind] = nil
    local destroy = destroyViews[kind]
    destroyViews[kind] = nil
    if destroy then
        try("Could not close " .. kind, destroy)
    end
end

openView = function(kind, host)
    closeView(kind)
    hosts[kind] = host
    local columns = kind == "settings" and 2 or "auto"
    local ok, result, destroy = try("Could not open " .. kind, function()
        return settingsView.build(host, rules, prettyui, columns, true, viewStates[kind])
    end)
    if ok then
        refreshViews[kind], destroyViews[kind] = result, destroy
    end
end

subscribe(Event.MiniMenuReady, ".menu", function(event)
    reaperGuard.addMenu(event.miniMenu, true)
    slayerGuard.addMenu(event.miniMenu, true)
end)

subscribe(Event.MiniMenuOpened, ".slayerMenuOpened", function(event)
    slayerGuard.menuOpened(event.miniMenu)
end)

subscribe(Event.Logic, ".overlay", function()
    local characterChanged = settings.refresh(rules)
    reaperGuard.update()
    slayerGuard.update()
    local count = #tasks
    if characterChanged or count ~= taskCount then
        taskCount = count
        -- Character changes replace preference tables; rebuild both views even
        -- when the newly loaded catalogue has the same number of tasks.
        for kind, host in pairs(hosts) do openView(kind, host) end
    end
    for kind, refresh in pairs(refreshViews) do
        if not try(kind .. " refresh failed", refresh) then closeView(kind) end
    end
end)

subscribe(Event.SettingsLayerReady, ".settings", function(event)
    openView("settings", event.component)
end)

subscribe(Event.ContentLayerReady, ".content", function(event)
    openView("content", event.component)
end)

function PluginShutdown()
    if stopped then return end
    stopped = true
    for _, subscription in ipairs(subscriptions) do
        try("Could not unsubscribe " .. subscription.name, function()
            subscription.event.Unsubscribe(subscription.name)
        end)
    end
    subscriptions = {}
    try("Could not shut down Reaper overlays", reaperGuard.shutdown)
    try("Could not shut down Slayer overlays", slayerGuard.shutdown)
    closeView("settings")
    closeView("content")
end
