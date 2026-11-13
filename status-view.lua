-- Manual development controls, not automatic task protection.
local constants = require("constants")
local view = {}

function view.build(host, overlay)
    local text = ui.Text.new(host)
    text:SetSize(-32, -104, 1, 1)
    text:SetPos(16, 88)
    text.font = id.Font.MUSEO_SANS_15PT_REGULAR
    text.content = constants.TITLE .. "<br><br>"
        .. "Manual Helwyr overlay. Automatic task protection is NOT active.<br><br>"
        .. "Show the overlay with Helwyr visible, then remove when finished. "
        .. "Edges, context menus and keyboard selection are not verified."

    local buttons = {}
    local labels = { show = "Overlay Helwyr", remove = "Remove overlay" }
    for index, action in ipairs({ "show", "remove" }) do
        local button = ui.Button.new(host)
        buttons[#buttons + 1] = button
        button:SetPos(16, 16 + (index - 1) * 36)
        button:SetSize(180, 30)
        button.stylesheetID = id.StyleSheet.BUTTON_DEFAULT
        button.label = labels[action]
        button:Subscribe(ui.Hook.ONBUTTONPRESSED, function()
            local message = overlay[action]()
            text.content = constants.TITLE .. "<br><br>" .. message
            print("[task-guard] " .. message)
        end)
    end

    return function()
        for _, button in ipairs(buttons) do button:Destroy() end
        text:Destroy()
    end
end

return view
