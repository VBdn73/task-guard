-- Captured native disabled background, not a direct requirements API.
local requirements = {}

-- Copy native sprite properties once during the guard's existing list traversal.
function requirements.capture(c, parent, sprites)
    if c and c.type == 3 and not c.isRestricted and c.visibleGlobal and c.parent == parent then
        sprites[#sprites + 1] = { parent = parent, type = 3, visibleGlobal = true,
            x = c.x, y = c.y, width = c.width, height = c.height, spriteID = c.spriteID }
    end
end

function requirements.isBlocked(label, sprites)
    local ok, blocked = pcall(function()
        local parent = label.parent
        if not parent or parent.isRestricted then return false end
        local x, y, w, h = label.x, label.y, label.width, label.height
        if type(x) ~= "number" or type(y) ~= "number" or w ~= 230 or h ~= 20 then return false end
        local xs, ys, widths, heights = { 0, 8, 222 }, { 0, 8, 12 }, { 8, 214, 8 }, { 8, 4, 8 }
        local seen, count, ambiguous = {}, 0, false
        local function inspect(c)
            if c and not c.isRestricted and c.visibleGlobal and c.parent == parent
                and c.type == 3 and c.x < x + w and c.x + c.width > x
                and c.y < y + h and c.y + c.height > y then
                local index = c.spriteID and c.spriteID - 18504
                if type(index) ~= "number" or index < 0 or index > 8 or index % 1 ~= 0 then
                    ambiguous = true
                else
                    local column, row = index % 3 + 1, math.floor(index / 3) + 1
                    if seen[index] or c.x ~= x + xs[column] or c.y ~= y + ys[row]
                        or c.width ~= widths[column] or c.height ~= heights[row] then
                        ambiguous = true
                    end
                    seen[index], count = true, count + 1
                end
            end
            return false
        end
        if sprites then
            for _, c in ipairs(sprites) do inspect(c) end
        else
            parent:IterateDynamicComponents(inspect)
        end
        return not ambiguous and count == 9
    end)
    return ok and blocked == true
end

return requirements
