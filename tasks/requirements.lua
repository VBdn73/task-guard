-- Captured native disabled background, not a direct requirements API.
local requirements = {}
local constants = require("tasks/picker-constants")
local SPRITE_X = { 0, 8, 222 }
local SPRITE_Y = { 0, 8, 12 }
local SPRITE_WIDTH = { 8, 214, 8 }
local SPRITE_HEIGHT = { 8, 4, 8 }
local owned = setmetatable({}, { __mode = "k" })

function requirements.markOwned(c)
    owned[c] = true
end

function requirements.isOwned(c)
    return owned[c] == true
end

-- Copy native sprite properties once during the guard's existing list traversal.
function requirements.capture(c, parent, sprites)
    if c and not owned[c] and c.type == 3 and not c.isRestricted and c.visibleGlobal and c.parent == parent then
        sprites[#sprites + 1] = { parent = parent, type = 3, visibleGlobal = true,
            x = c.x, y = c.y, width = c.width, height = c.height, spriteID = c.spriteID }
    end
end

function requirements.isBlocked(label, sprites)
    local ok, blocked = pcall(function()
        local parent = label.parent
        if not parent or parent.isRestricted then return false end
        local x, y, w, h = label.x, label.y, label.width, label.height
        if type(x) ~= "number" or type(y) ~= "number"
            or w ~= constants.ROW_WIDTH or h ~= constants.ROW_HEIGHT then return false end
        local seen, count, ambiguous = {}, 0, false
        local function inspect(c)
            if c and not owned[c] and not c.isRestricted and c.visibleGlobal and c.parent == parent
                and c.type == 3 and c.x < x + w and c.x + c.width > x
                and c.y < y + h and c.y + c.height > y then
                local index = c.spriteID and c.spriteID - constants.DISABLED_SPRITE_FIRST
                if type(index) ~= "number" or index < 0 or index >= constants.ROW_SPRITE_COUNT or index % 1 ~= 0 then
                    ambiguous = true
                else
                    local column, row = index % 3 + 1, math.floor(index / 3) + 1
                    if seen[index] or c.x ~= x + SPRITE_X[column] or c.y ~= y + SPRITE_Y[row]
                        or c.width ~= SPRITE_WIDTH[column] or c.height ~= SPRITE_HEIGHT[row] then
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
        return not ambiguous and count == constants.ROW_SPRITE_COUNT
    end)
    return ok and blocked == true
end

return requirements
