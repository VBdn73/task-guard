-- Capture ownership while a control is live. Never destroy a retained control
-- after its interface disappears, it becomes restricted, or it is reparented.
local cleanup = {}

function cleanup.capture(component)
    if not component then return function() return false end end
    local interfaceID, parent = component.interfaceID, component.parent
    return function()
        local ok, valid = pcall(function()
            if interfaceID ~= nil and ui.Interfaces:GetInterface(interfaceID) == nil then return false end
            if component.isRestricted then return false end
            if parent then
                if parent.isRestricted or component.parent ~= parent then return false end
            end
            return true
        end)
        return ok and valid
    end
end

function cleanup.owned(component)
    local valid = cleanup.capture(component)
    local disposed = false
    return function()
        if disposed then return end
        disposed = true
        if valid() then component:Destroy() end
    end
end

return cleanup
