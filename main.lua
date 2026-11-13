local constants = require("constants")
local statusView = require("status-view")
local destroyViews = {}

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
    local ok, result = pcall(statusView.build, host)
    if ok then
        destroyViews[kind] = result
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
    Event.SettingsLayerReady.Unsubscribe(constants.EVENT_PREFIX .. ".settings")
    Event.ContentLayerReady.Unsubscribe(constants.EVENT_PREFIX .. ".content")
    closeView("settings")
    closeView("content")
end
