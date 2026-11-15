return function(control)
    return { new = function(parent, choices, options)
        local checkbox = { root = control(parent), selected = choices[1].selected }
        checkbox.root:SetPos(options.x, options.y)
        checkbox.root:SetSize(options.width, 22)
        local label = control(checkbox.root)
        label.alignVertical = ui.AlignMode.CENTRE
        checkbox.items = { { label = label } }
        checkbox.root.checkbox = checkbox
        function checkbox:SetSelected(key, value, notify)
            if self.selected == value then return end
            self.selected = value
            if notify ~= false and self.onChange then self.onChange(self, {}, key, value) end
        end
        function checkbox:Destroy() self.destroyed = true end
        return checkbox
    end }
end
