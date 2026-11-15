local order = {}

function order.alphabetical(a, b)
    local left, right = a:lower(), b:lower()
    local leftKey, rightKey = left:gsub("^the%s+", ""), right:gsub("^the%s+", "")
    if leftKey ~= rightKey then return leftKey < rightKey end
    -- Keep names with the same article-free key in a deterministic order.
    return left < right
end

function order.alphabeticalDescending(a, b)
    return order.alphabetical(b, a)
end

return order
