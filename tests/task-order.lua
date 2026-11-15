local order = require("task-order")
local names = { "The Twin Furies", "Vorago", "The Ambassador", "Araxxi",
    "The Barrows Brothers", "Black Stone Dragon", "The Magister", "Nex" }
table.sort(names, order.alphabetical)
local expected = { "The Ambassador", "Araxxi", "The Barrows Brothers", "Black Stone Dragon",
    "The Magister", "Nex", "The Twin Furies", "Vorago" }
for index, name in ipairs(expected) do assert(names[index] == name) end
assert(order.alphabetical("THE Ambassador", "araxxi"), "Comparison must be case-insensitive")
assert(order.alphabetical("Therion", "Vorago"), "Only a leading whole-word The is ignored")
assert(order.alphabetical("Ambassador", "The Ambassador"), "Equal keys need deterministic ordering")
assert(not order.alphabetical("The Ambassador", "The Ambassador"))
table.sort(names, order.alphabeticalDescending)
for index, name in ipairs(expected) do assert(names[#names - index + 1] == name) end
assert(order.alphabeticalDescending("The Ambassador", "Ambassador"))
assert(not order.alphabeticalDescending("The Ambassador", "The Ambassador"))
print("Task Guard alphabetical ordering tests passed")
