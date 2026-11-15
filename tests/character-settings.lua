local name, available = "First Character", true
Player = { IsAvailable = function() return available end,
    GetEntity = function() return { isValid = true, displayName = name } end }
local data, writes = {}, 0
PersistentDB = {
    GetStructuredData = function(_, key) return data[key] end,
    SetStructuredData = function(_, key, value)
        data[key], writes = value, writes + 1
        return true
    end,
}
data["taskGuard.tasks.v1"] = { reaper = { Helwyr = false } }
local settings = require("tasks/settings")
local tasks = require("tasks/reaper/catalogue")
local rules = settings.load()
assert(rules.reaper.Helwyr, "Shared settings must not leak into a character profile")
rules.reaper.Helwyr = false
rules.slayer.Aberrants = false
rules.general.taskOrder = "alphabetical"
assert(settings.discover(rules, { "First Character Boss" }))
local first = rules
name = "Second Character"
assert(not settings.save(first), "Stale rules must not save to another character")
assert(settings.refresh(rules) and rules == first)
assert(rules.reaper.Helwyr and rules.general.taskOrder == "default")
assert(rules.reaper["First Character Boss"] == nil)
for _, task in ipairs(tasks) do assert(task ~= "First Character Boss") end
rules.reaper.Telos = false
assert(settings.save(rules))
name = "  FIRST CHARACTER  "
assert(settings.refresh(rules))
assert(not rules.reaper.Helwyr and rules.reaper.Telos)
assert(rules.general.taskOrder == "alphabetical" and rules.reaper["First Character Boss"])
assert(not settings.refresh(rules), "Unchanged character must not reload")
available = false
assert(settings.refresh(rules) and rules.reaper.Helwyr)
local before = writes
assert(not settings.save(rules) and writes == before)
available = true
assert(settings.refresh(rules) and not rules.reaper.Helwyr)
assert(not settings.load().reaper.Helwyr, "Profile must survive reload")
for _, invalid in ipairs({ "", "   ", 123 }) do
    name = invalid
    settings.refresh(rules)
    assert(not settings.save(rules))
end
assert(data["taskGuard.tasks.v1"].reaper.Helwyr == false)
print("Task Guard character settings tests passed")
