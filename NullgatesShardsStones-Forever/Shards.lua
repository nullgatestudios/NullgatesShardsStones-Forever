-- Nullgate's Shards & Stones: soul shard count, the low-shard warning and trimming extra shards.
-- Trimming deletes exactly one shard per click, never below the limit, and only from a click.
local _, ns = ...

local L = ns.L
local Shards = {}
ns.Shards = Shards

local warned = false

function Shards.Count()
    return ns.Stones.Count(ns.SOUL_SHARD)
end

function Shards.Excess()
    return ns.Stones.Excess(Shards.Count(), ns.db.shardLimit)
end

local function SlotItem(bag, slot)
    if C_Container and C_Container.GetContainerItemID then return C_Container.GetContainerItemID(bag, slot) end
    if GetContainerItemID then return GetContainerItemID(bag, slot) end
end

-- The last shard in the bags (shards fill bags from the front, so trimming from the back keeps
-- the soul bag's order).
function Shards.Find()
    local numSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    if not numSlots then return nil end
    for bag = 4, 0, -1 do
        for slot = (numSlots(bag) or 0), 1, -1 do
            if SlotItem(bag, slot) == ns.SOUL_SHARD then return bag, slot end
        end
    end
end

-- Deletes one shard when over the limit. Call only from a click. Returns true when one was deleted.
function Shards.TrimOne()
    if InCombatLockdown() or Shards.Excess() <= 0 then return false end
    local bag, slot = Shards.Find()
    if not bag then return false end
    if CursorHasItem and CursorHasItem() then ClearCursor() end
    local pickup = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
    pickup(bag, slot)
    local kind, id = GetCursorInfo()
    if kind == "item" and id == ns.SOUL_SHARD then
        DeleteCursorItem()
        return true
    end
    ClearCursor()
    return false
end

function Shards.Check()
    local settings = ns.db.lowShards
    local low, warnNow = ns.Stones.LowShards(Shards.Count(), settings.enabled and settings.threshold or 0, warned)
    if warnNow then ns.Print(string.format(L["Low on soul shards: %d left."], Shards.Count())) end
    warned = low
end
