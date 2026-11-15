-- Static popup: one canvas, no sprite/text children or extra target hooks.
local tooltip = {}
local cleanup = require("ui/cleanup")

function tooltip.new(parent, options)
    local width, height = 240, 38
    local measured, textWidth, textHeight = pcall(function()
        local font = config.Font.MUSEO_SANS_15PT_REGULAR
        local w = math.min(300, font:GetStringWidth(options.text, false) + 16)
        local h = font:GetStringHeightAndLineCount(options.text, w - 16, font.baseline, false, false, false) + 10
        return w, h
    end)
    if measured then width, height = math.max(24, textWidth), math.max(24, textHeight) end
    local root = ui.Canvas.new(parent)
    local destroyRoot = cleanup.owned(root)
    local ok, err = pcall(function()
        root:SetSize(width, height)
        root.clickthrough, root.hidden = true, true
        root:AddRectangle(0, 0, width, height, 0x181710FF)
        root:AddOutline(0, 0, width, height, 1, 0x806C3EFF)
        local text = ui.TextDataConfig.new()
        text.font = id.Font.MUSEO_SANS_15PT_REGULAR
        text.alignHorizontal, text.alignVertical = ui.AlignMode.CENTRE, ui.AlignMode.CENTRE
        text.colour = Vector4.new(1, 1, 1, 1)
        root:AddText(8, 5, width - 16, height - 10, options.text, text)
    end)
    if not ok then pcall(destroyRoot); error(err) end
    local shown = false
    local result = { root = root, options = options, width = width, height = height }
    function result:Show()
        if not self.root then return end
        if shown then return end
        shown = true
        root.hidden = false
        root:MoveToFront()
    end
    function result:Hide()
        if not self.root then return end
        if not shown then return end
        shown = false
        root.hidden = true
    end
    function result:Destroy()
        if not self.root then return end
        self.root = nil
        shown = false
        destroyRoot()
    end
    return result
end

return tooltip
