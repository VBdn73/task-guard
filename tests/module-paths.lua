-- The client loads literal paths; standard Lua also accepts dotted names,
-- which can hide broken client imports in mocked tests.
local visited = {}
local function validate(path)
    if visited[path] then return end
    visited[path] = true
    assert(not path:find(".", 1, true), "Client module paths must use slashes: " .. path)
    local file = assert(io.open(path .. ".lua", "r"), "Missing client module: " .. path)
    local source = file:read("*a")
    file:close()
    for dependency in source:gmatch('require%("([^"]+)"%)') do
        validate(dependency)
    end
end
validate("main")
print("Task Guard client module path tests passed")
