-- Run from the project root: lua tests/slayer-catalogue.lua
local tasks = require("tasks/slayer/catalogue")
local known = {}
for _, name in ipairs(tasks) do
    assert(not known[name], "Duplicate global Slayer setting: " .. name)
    known[name] = true
end
for _, name in ipairs({ "Sanguine crawlers", "Sanguine werewolves", "Beastmaster's hounds",
    "Volcanic creatures", "Zemouregal's undead", "Greater demon berserkers and ash lords",
    "Kalphite", "Profane scabarites", "Ravenous strigoi" }) do assert(known[name], name) end
local aliases = { Kalphites = "Kalphite", Kurasks = "Kurask", Turoths = "Turoth",
    Zombie = "Zombies", ["Cave slime"] = "Cave slimes",
    ["Profane Scabarites"] = "Profane scabarites", ["Ravenous Strigoi"] = "Ravenous strigoi" }
local saved = { nameVersion = 2, reaper = { Helwyr = false }, slayer = {} }
for old in pairs(aliases) do saved.slayer[old] = false; assert(not known[old]) end
PersistentDB = {
    GetStructuredData = function() return saved end,
    SetStructuredData = function(_, _, value) saved = value; return true end,
}
local settings = require("tasks/settings")
local rules = settings.load()
for old, native in pairs(aliases) do
    assert(rules.slayer[native] == false and saved.slayer[native] == false)
    assert(saved.slayer[old] == nil)
end
assert(rules.slayer["Sanguine crawlers"] and rules.slayer["Sanguine werewolves"],
    "Crawlers and werewolves must remain independent tasks, enabled by default")
rules.slayer["Sanguine werewolves"] = false
assert(settings.save(rules))
rules = settings.load()
assert(not rules.slayer["Sanguine werewolves"] and rules.slayer["Sanguine crawlers"])
assert(not rules.reaper.Helwyr, "Catalogue migration must preserve Reaper preferences")
print("Global Slayer catalogue tests passed")
