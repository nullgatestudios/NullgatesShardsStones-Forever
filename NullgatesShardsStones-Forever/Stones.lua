-- Nullgate's Shards & Stones: what each stone button does. No game calls except through
-- Stones.IsKnown and Stones.Count, which the tests replace.
local _, ns = ...

local Stones = {}
ns.Stones = Stones

Stones.KINDS = { "healthstone", "soulstone", "spellstone", "firestone" }

function Stones.IsKnown(spellID)
    local known = (C_SpellBook and C_SpellBook.IsSpellKnown) or IsSpellKnown or IsPlayerSpell
    return known ~= nil and known(spellID) == true
end

function Stones.Count(itemID)
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    return (count and count(itemID)) or 0
end

-- The best stone of a kind in the bags (highest rank, then the best talent variant), and how many
-- of that kind are carried in total.
function Stones.Carried(kind)
    local data = ns.STONES[kind]
    local best, total = nil, 0
    for _, rank in ipairs(data.ranks) do
        for _, item in ipairs(rank.items) do
            local n = Stones.Count(item)
            if n > 0 then
                total = total + n
                best = item -- ranks and variants are in ascending order, so the last one found is best
            end
        end
    end
    return best, total
end

-- The highest rank of a kind's Create spell the player knows, or nil.
function Stones.BestCreate(kind)
    local best
    for _, rank in ipairs(ns.STONES[kind].ranks) do
        if Stones.IsKnown(rank.spell) then best = rank end
    end
    return best
end

-- What the button should do: { action = "use", item = itemID, total = n }, or
-- { action = "create", spell = spellID, rank = rank }, or { action = "none" } (nothing known).
function Stones.Decide(kind)
    local item, total = Stones.Carried(kind)
    if item then return { action = "use", item = item, total = total } end
    local rank = Stones.BestCreate(kind)
    if rank then return { action = "create", spell = rank.spell, rank = rank, total = 0 } end
    return { action = "none", total = 0 }
end

-- The secure attributes for a decision. Soulstones go on your mouseover or target when it's a
-- friendly player, otherwise on you.
function Stones.Attributes(kind, decision)
    if decision.action == "use" then
        if kind == "soulstone" then
            return { type = "macro", macrotext = "/use [@mouseover,help][help][@player] item:" .. decision.item }
        end
        return { type = "item", item = "item:" .. decision.item }
    elseif decision.action == "create" then
        return { type = "spell", spell = decision.spell }
    end
    return {}
end

-- --- Soul shards ---------------------------------------------------------------------

-- How many shards are over the limit (0 when the limit is off).
function Stones.Excess(count, limit)
    if not limit or limit <= 0 then return 0 end
    return math.max(0, count - limit)
end

-- Pure low-shard decision, like the other warnings: returns (isLow, shouldWarnNow).
function Stones.LowShards(count, threshold, alreadyWarned)
    local low = threshold > 0 and count < threshold
    return low, low and not alreadyWarned
end
