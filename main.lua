local constants = require("constants")
local settingsView = require("settings-view")
local rules = require("task-settings").load()
local refreshViews = {}
local destroyViews = {}
local overlay = require("reaper-overlay").new(require("reaper-config"), prettyui)
Event.Logic.Subscribe(constants.EVENT_PREFIX .. ".overlay", function()
    overlay.update()
    for kind, refresh in pairs(refreshViews) do
        local ok, err = pcall(refresh)
        if not ok then
            refreshViews[kind] = nil
            print("[task-guard] " .. kind .. " refresh failed: " .. tostring(err))
        end
    end
end)

local function closeView(kind)
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

local function openView(kind, host)
    closeView(kind)
    local columns = kind == "settings" and 2 or 1
    local ok, result, destroy = pcall(settingsView.build, host, rules, prettyui, columns)
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
    refreshViews = {}
    print("[task-guard] " .. overlay.remove())
    Event.Logic.Unsubscribe(constants.EVENT_PREFIX .. ".overlay")
    Event.SettingsLayerReady.Unsubscribe(constants.EVENT_PREFIX .. ".settings")
    Event.ContentLayerReady.Unsubscribe(constants.EVENT_PREFIX .. ".content")
    closeView("settings")
    closeView("content")
end
