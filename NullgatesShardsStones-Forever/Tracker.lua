-- Nullgate's Shards & Stones: who holds your Soulstone. When you use a Soulstone, the target's name
-- (from UNIT_SPELLCAST_SENT) and the buff's end time are saved, so it survives a /reload or relog
-- (times are real clock seconds).
local _, ns = ...

local Tracker = {}
ns.Tracker = Tracker

local sentTarget
local buffSpells

local function IsSoulstoneBuff(spellID)
    if not buffSpells then
        buffSpells = {}
        for _, id in ipairs(ns.STONES.soulstone.buffSpells or {}) do buffSpells[id] = true end
    end
    return buffSpells[spellID] == true
end
Tracker.IsSoulstoneBuff = IsSoulstoneBuff

-- The tracked Soulstone: name and seconds left, or nil when none is up.
function Tracker.Current(now)
    local s = ns.db.soulstone
    now = now or time()
    if not s or not s.expires then return nil end
    local left = s.expires - now
    if left <= 0 then
        ns.db.soulstone = nil
        return nil
    end
    return s.name, left
end

-- 1799 -> "29:59"; 61 -> "1:01".
function Tracker.Format(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

function Tracker.OnSent(unit, target, _, spellID)
    if unit == "player" and IsSoulstoneBuff(spellID) then sentTarget = target end
end

function Tracker.OnSucceeded(unit, _, spellID, now)
    if unit ~= "player" or not IsSoulstoneBuff(spellID) then return false end
    local name = sentTarget
    if not name or name == "" then name = UnitName("player") end
    ns.db.soulstone = { name = name, expires = (now or time()) + (ns.STONES.soulstone.buffDuration or 1800) }
    sentTarget = nil
    return true
end
