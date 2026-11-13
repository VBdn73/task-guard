-- A deliberately read-only placeholder until task guarding is implemented.
local constants = require("constants")
local view = {}

function view.build(host)
    local text = ui.Text.new(host)
    text:SetSize(-32, 180, 1, 0)
    text:SetPos(16, 16)
    text.font = id.Font.MUSEO_SANS_15PT_REGULAR
    text.content = constants.TITLE .. "<br><br>"
        .. "Development scaffold only. Task protection is not active.<br><br>"
        .. "Planned: separate Slayer cape choice and Reaper's Choice guard lists."

    return function()
        text:Destroy()
    end
end

return view
