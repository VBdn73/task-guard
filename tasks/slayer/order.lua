-- Reuse complete-row movement with the captured Slayer picker geometry.
local ordering = {}
local nativeOrder = require("tasks/native-order")
local tasks = require("tasks/slayer/catalogue")

function ordering.new(rules)
    return nativeOrder.new(rules, {
        interface = 201, list = 5, companion = 4,
        title = "Select your Slayer task", firstY = 5,
        tasks = tasks, preferences = "slayer",
        duplicateName = "Ravenous strigoi",
        validate = function(list, title)
            local viewport = ui.Interfaces:GetComponent(201, 3)
            local root = ui.Interfaces:GetComponent(201, 0)
            assert(viewport and not viewport.isRestricted and viewport.visibleGlobal
                and root and not root.isRestricted and root.visibleGlobal
                and list.type == 20 and viewport.type == 20 and list.parent == viewport
                and list.width == 480 and viewport.width == 480
                and viewport.parent and not viewport.parent.isRestricted and viewport.parent.parent == root
                and title.parent and not title.parent.isRestricted and title.parent.parent == root,
                "Slayer picker structure changed")
        end,
    })
end

return ordering
