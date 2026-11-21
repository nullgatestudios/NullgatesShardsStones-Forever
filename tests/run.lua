-- Nullgate's Shards & Stones: tests for the stone data, use-or-create decisions, shards and the tracker.
-- Run from the repository root:  lua tests/run.lua   (Lua 5.1 or newer)

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/run.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local root = (scriptDir:match("^(.*)[/\\][^/\\]*$") or ".") .. "/NullgatesShardsStones-Forever/"

local ns = { db = {} }
local function Load(file) assert(loadfile(root .. file), "cannot load " .. file)("NullgatesShardsStones-Forever", ns) end
Load("Data/Stones.lua")
Load("Stones.lua")
Load("Tracker.lua")
local S, T = ns.Stones, ns.Tracker

local checks, failures = 0, 0
local function EQ(got, want, name)
    checks = checks + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL %s: expected %s, got %s", name, tostring(want), tostring(got)))
    end
end

-- --- The data ---------------------------------------------------------------------
EQ(type(ns.STONE_DATA_BUILD), "string", "the data names its client build")
for _, kind in ipairs(S.KINDS) do
    local ranks = ns.STONES[kind].ranks
    EQ(#ranks >= 3, true, kind .. ": at least three ranks")
    for i, rank in ipairs(ranks) do
        EQ(#rank.items >= 1 and rank.level >= 1, true, kind .. " rank " .. rank.spell .. " is complete")
        if i > 1 then EQ(rank.level > ranks[i - 1].level, true, kind .. " ranks are in level order") end
    end
end
EQ(#ns.STONES.healthstone.ranks[1].items, 3, "each Healthstone rank has its three talent variants")
EQ(ns.STONES.healthstone.cooldown, 120, "Healthstones share a 2 minute cooldown")
EQ(ns.STONES.soulstone.buffDuration, 1800, "the Soulstone buff lasts 30 minutes")

-- --- Use or create ------------------------------------------------------------------
local known, bags = {}, {}
S.IsKnown = function(id) return known[id] == true end
S.Count = function(id) return bags[id] or 0 end

EQ(S.Decide("healthstone").action, "none", "knows nothing, carries nothing: nothing to do")
known[6201], known[6202], known[5699] = true, true, true
local d = S.Decide("healthstone")
EQ(d.action, "create", "no Healthstone carried: create one")
EQ(d.spell, 5699, "with the highest rank known (Create Healthstone, level 34)")
EQ(S.Attributes("healthstone", d).type, "spell", "create is a spell button")
EQ(S.Attributes("healthstone", d).spell, 5699, "casting that rank's spell ID")

bags[5511] = 1      -- a Lesser Healthstone
bags[19009] = 1     -- a Healthstone (best talent variant)
d = S.Decide("healthstone")
EQ(d.action, "use", "carrying Healthstones: use one")
EQ(d.item, 19009, "the best one carried")
EQ(d.total, 2, "counting every Healthstone carried")
local a = S.Attributes("healthstone", d)
EQ(a.type == "item" and a.item == "item:19009", true, "use is an item button")

known[693] = true
bags[5232] = 1
a = S.Attributes("soulstone", S.Decide("soulstone"))
EQ(a.type, "macro", "Soulstones use a macro to pick the target")
EQ(a.macrotext, "/use [@mouseover,help][help][@player] item:5232", "mouseover, then a friendly target, then yourself")
EQ(next(S.Attributes("firestone", S.Decide("firestone"))), nil, "nothing known: no attributes")

-- --- Shards -------------------------------------------------------------------------
EQ(S.Excess(25, 20), 5, "25 shards with a limit of 20: 5 over")
EQ(S.Excess(18, 20), 0, "under the limit: none over")
EQ(S.Excess(30, 0), 0, "limit 0 is off")
local low, warn = S.LowShards(2, 3, false)
EQ(low and warn, true, "below the threshold warns")
low, warn = S.LowShards(2, 3, true)
EQ(low == true and warn == false, true, "but only once")
low = S.LowShards(2, 0, false)
EQ(low, false, "threshold 0 never warns")

-- --- Soulstone tracker ---------------------------------------------------------------
UnitName = function() return "Me" end
T.OnSent("player", "Healer", "guid", 20765)
EQ(T.OnSucceeded("player", "guid", 20765, 1000), true, "a Soulstone use is recorded")
local name, left = T.Current(1000 + 60)
EQ(name, "Healer", "on the target it was sent to")
EQ(left, 1800 - 60, "with 29 minutes left after a minute")
EQ(T.Format(left), "29:00", "formatted as minutes and seconds")
EQ(T.Current(1000 + 1800), nil, "gone after 30 minutes")
EQ(ns.db.soulstone, nil, "and cleared from the saved data")
EQ(T.OnSucceeded("player", "guid", 6201, 1000), false, "other casts are ignored")
EQ(T.OnSucceeded("party1", "guid", 20765, 1000), false, "other players' Soulstones are ignored")
T.OnSucceeded("player", "guid", 20707, 2000)
EQ((T.Current(2000)), "Me", "no target sent: it's on you")

print(string.format("%d checks, %d failure(s)", checks, failures))
if failures > 0 then os.exit(1) end
