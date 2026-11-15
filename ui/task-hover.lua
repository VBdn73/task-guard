-- Native hover flags can remain set when scrolling moves a row away.
local hover = {}
local batch

local function pointer()
    local mouse = Mouse.GetPosition()
    if not mouse then return nil end
    local scale = (game and game.options and game.options.InterfaceScale
        and tonumber(game.options.InterfaceScale.setting) or 100) / 100
    if scale <= 0 then scale = 1 end
    return { x = mouse.x / scale, y = mouse.y / scale }
end

-- Start a fresh snapshot for a guard reconciliation/menu build, not per row.
function hover.begin()
    local ok, mouse = pcall(pointer)
    batch = { mouse = ok and mouse or nil, parents = {}, clips = {}, rows = {} }
end

function hover.finish()
    batch = nil -- Native hover callbacks must see the current pointer, not an old tick.
end

local function scrollOffset(parent)
    if batch then
        for _, entry in ipairs(batch.parents) do
            if entry.parent == parent then return entry.x, entry.y end
        end
    end
    local x, y, ancestor = 0, 0, parent
    for _ = 1, 16 do
        if not ancestor then break end
        x, y = x + (ancestor.scrollX or 0), y + (ancestor.scrollY or 0)
        ancestor = ancestor.parent
    end
    if batch then batch.parents[#batch.parents + 1] = { parent = parent, x = x, y = y } end
    return x, y
end

local function clipBounds(viewport)
    if batch then
        for _, entry in ipairs(batch.clips) do
            if entry.viewport == viewport then return entry end
        end
    end
    local origin = viewport.xyGlobal
    local clip = { viewport = viewport, x = origin.x, y = origin.y,
        width = viewport.width, height = viewport.height }
    if batch then batch.clips[#batch.clips + 1] = clip end
    return clip
end

function hover.contains(component, viewport)
    if batch and batch.rows[component] ~= nil then return batch.rows[component] end
    local ok, result = pcall(function()
        local mouse
        if batch then mouse = batch.mouse else mouse = pointer() end
        if not mouse then return nil end
        local mx, my = mouse.x, mouse.y
        local origin = component.xyGlobal
        local scrollX, scrollY = scrollOffset(component.parent)
        local x, y = origin.x - scrollX, origin.y - scrollY
        if mx < x or mx >= x + component.width or my < y or my >= y + component.height then return false end
        if viewport then
            local clip = clipBounds(viewport)
            if mx < clip.x or mx >= clip.x + clip.width
                or my < clip.y or my >= clip.y + clip.height then return false end
        end
        return component.visibleGlobal == true
    end)
    if ok then
        if batch and result ~= nil then batch.rows[component] = result end
        return result
    end
    return nil -- Retain hook fallback when the mouse API is unavailable.
end

return hover
