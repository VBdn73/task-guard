return function(control)
    return { new = function(parent, options)
        local combo = { root = control(parent), selectedID = options.selectedID,
            input = { text = {} }, contentMargin = options.contentMargin }
        combo.root:SetPos(options.x, options.y)
        combo.root:SetSize(options.width, options.height)
        function combo:GetSelectedID() return self.selectedID end
        function combo:Select(value, triggerEvents)
            self.selectedID = value
            if triggerEvents and self.onChange then self.onChange(self, value) end
        end
        function combo:Destroy() self.destroyed = true end
        combo.root.combo = combo
        return combo
    end }
end
