local textWrap = {}

-- Keep whole words intact; native labels interpret <br> as a line break.
-- The caller supplies measurement because font APIs differ between views.
function textWrap.lines(text, width, measure)
    local lines, line = {}, ""
    for word in text:gmatch("%S+") do
        local candidate = line == "" and word or line .. " " .. word
        if line ~= "" and measure(candidate) > width then
            lines[#lines + 1] = line
            line = word
        else
            line = candidate
        end
    end
    lines[#lines + 1] = line
    return lines
end

return textWrap
