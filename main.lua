local constants = require("constants")
local settingsView = require("settings-view")
local rules = require("task-settings").load()
local refreshViews = {}
local destroyViews = {}
local hosts = {}
local viewStates = { settings = {}, content = {} }
local openView
local closeView
local stopped = false
local taskCount = #require("reaper-tasks")
local overlay = require("reaper-guard").new(rules, prettyui)
local slayerOverlay = require("slayer-guard").new(rules, prettyui)
Event.MiniMenuReady.Subscribe(constants.EVENT_PREFIX .. ".menu", function(event)
    overlay.addMenu(event.miniMenu)
    slayerOverlay.addMenu(event.miniMenu)
end)
Event.MiniMenuOpened.Subscribe(constants.EVENT_PREFIX .. ".slayerMenuOpened", function(event)
    slayerOverlay.menuOpened(event.miniMenu)
end)
Event.Logic.Subscribe(constants.EVENT_PREFIX .. ".overlay", function()
    if stopped then return end
    overlay.update()
    slayerOverlay.update()
    local count = #require("reaper-tasks")
    if count ~= taskCount then
        taskCount = count
        for kind, host in pairs(hosts) do openView(kind, host) end
    end
    for kind, refresh in pairs(refreshViews) do
        local ok, err = pcall(refresh)
        if not ok then
            closeView(kind)
            print("[task-guard] " .. kind .. " refresh failed: " .. tostring(err))
        end
    end
end)

closeView = function(kind)
    hosts[kind] = nil
    refreshViews[kind] = nil
    local destroy = destroyViews[kind]
    destroyViews[kind] = nil
    if destroy then
        local ok, err = pcall(destroy)
        if not ok then
            print("[task-guard] Could not close " .. kind .. ": " .. tostring(err))
        end
    end
end

openView = function(kind, host)
    closeView(kind)
    hosts[kind] = host
    local columns = kind == "settings" and 2 or "auto"
    local ok, result, destroy = pcall(settingsView.build, host, rules, prettyui, columns, kind == "settings", viewStates[kind])
    if ok then
        refreshViews[kind], destroyViews[kind] = result, destroy
    else
        print("[task-guard] Could not open " .. kind .. ": " .. tostring(result))
    end
end

Event.SettingsLayerReady.Subscribe(constants.EVENT_PREFIX .. ".settings", function(event)
    openView("settings", event.component)
end)

Event.ContentLayerReady.Subscribe(constants.EVENT_PREFIX .. ".content", function(event)
    openView("content", event.component)
end)

function PluginShutdown()
    if stopped then return end
    stopped = true
    Event.Logic.Unsubscribe(constants.EVENT_PREFIX .. ".overlay")
    Event.MiniMenuReady.Unsubscribe(constants.EVENT_PREFIX .. ".menu")
    Event.MiniMenuOpened.Unsubscribe(constants.EVENT_PREFIX .. ".slayerMenuOpened")
    Event.SettingsLayerReady.Unsubscribe(constants.EVENT_PREFIX .. ".settings")
    Event.ContentLayerReady.Unsubscribe(constants.EVENT_PREFIX .. ".content")
    local ok, err = pcall(overlay.shutdown)
    if not ok then print("[task-guard] Could not shut down overlays: " .. tostring(err)) end
    local slayerOK, slayerError = pcall(slayerOverlay.shutdown)
    if not slayerOK then print("[task-guard] Could not shut down Slayer overlays: " .. tostring(slayerError)) end
    closeView("settings")
    closeView("content")
end
