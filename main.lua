local constants = require("constants")
local statusView = require("status-view")
local settingsView = require("settings-view")
local rules = require("task-settings").load()
local refreshSettings
local destroyViews = {}
local overlay = require("reaper-overlay").new(require("reaper-config"), prettyui)
Event.Logic.Subscribe(constants.EVENT_PREFIX .. ".overlay", function()
    overlay.update()
    if refreshSettings then
        local ok, err = pcall(refreshSettings)
        if not ok then
            refreshSettings = nil
            print("[task-guard] Settings refresh failed: " .. tostring(err))
        end
    end
end)

local function closeView(kind)
    local destroy = destroyViews[kind]
    destroyViews[kind] = nil
    if destroy then
        local ok, err = pcall(destroy)
        if not ok then
            print("[task-guard] Could not close " .. kind .. ": " .. tostring(err))
        end
    end
end

local function openView(kind, host)
    closeView(kind)
    local ok, result, destroy
    if kind == "settings" then
        refreshSettings = nil
        ok, result, destroy = pcall(settingsView.build, host, rules, prettyui)
    else
        ok, result = pcall(statusView.build, host, overlay)
    end
    if ok then
        if kind == "settings" then
            refreshSettings, destroyViews[kind] = result, destroy
        else
            destroyViews[kind] = result
        end
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
    refreshSettings = nil
    print("[task-guard] " .. overlay.remove())
    Event.Logic.Unsubscribe(constants.EVENT_PREFIX .. ".overlay")
    Event.SettingsLayerReady.Unsubscribe(constants.EVENT_PREFIX .. ".settings")
    Event.ContentLayerReady.Unsubscribe(constants.EVENT_PREFIX .. ".content")
    closeView("settings")
    closeView("content")
end
