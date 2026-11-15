local textWrap = require("ui/text-wrap")

local function wrapped(text, width)
    return table.concat(textWrap.lines(text, width, function(value) return #value end), "|")
end

assert(wrapped("", 10) == "", "Empty text retains one empty line")
assert(wrapped("  one   two  ", 7) == "one two", "Whitespace is normalised")
assert(wrapped("one two three", 7) == "one two|three", "Exact-width lines fit")
assert(wrapped("one two", 6) == "one|two", "Words wrap before exceeding the width")
assert(wrapped("longword next", 3) == "longword|next", "Long words are not split")
assert(wrapped("one two", 0) == "one|two", "Narrow layouts still retain every word")

print("Task Guard text wrapping tests passed")
