-- Nullgate's Shards & Stones: /nshard check, the in-game self test (phase 0 of PLAN.md).
-- Every result goes to chat and to NullgatesShardsStonesDB.check, so the log can be copied from
-- WTF\Account\<account>\<realm>\<character>\SavedVariables\NullgatesShardsStones-Forever.lua.
--
--   1. Which calls exist, which Create ranks are known, what's carried, each stone item's
--      cooldown, and what each button would do.
--   2. Whether deleting one shard from a click works (only when you're over your shard limit).
--   3. Whether using a Soulstone is seen (cast events), so the tracker can record it.
local _, ns = ...

local Check = {}
ns.Check = Check

local LOG_LIMIT = 400
local panel, watching

local function Log(text)
    local db = ns.db
    if db then
        db.check = db.check or {}
        if #db.check >= LOG_LIMIT then table.remove(db.check, 1) end
        db.check[#db.check + 1] = text
    end
    print("|cff00c0ffNullgate's Shards & Stones check:|r " .. text)
    if NullgateReport then NullgateReport.Update("shards-stones") end
end
Check.Log = Log

-- Opens the report window every Nullgate addon shares (NullgateReport.lua) with this check's log,
-- ready to copy and paste into the report form on our website.
function Check.ShowReport()
    local L = ns.L
    return NullgateReport.Show({
        slug = "shards-stones", name = "Nullgate's Shards & Stones", addon = "NullgatesShardsStones-Forever", command = "/nshard check",
        lines = function() return ns.db and ns.db.check end,
        title = L["Bug report"], selectAll = L["Select all"], selectLink = L["Select link"],
        help = L["Press Ctrl+C to copy this report, then paste it into a new report at the link below, with a few words on what happened."],
    })
end

local function Exists(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return false end
        value = value[part]
    end
    return type(value) == "function"
end

local function StaticChecks()
    local _, class = UnitClass("player")
    Log(string.format("client %s, build %s, interface %s; class %s, level %s; data build %s",
        tostring(GetBuildInfo and select(1, GetBuildInfo())), tostring(GetBuildInfo and select(2, GetBuildInfo())),
        tostring(GetBuildInfo and select(4, GetBuildInfo())), tostring(class), tostring(UnitLevel("player")),
        tostring(ns.STONE_DATA_BUILD)))
    local calls = {}
    for _, name in ipairs({ "C_SpellBook.IsSpellKnown", "IsSpellKnown", "IsPlayerSpell", "C_Item.GetItemCount",
        "C_Container.GetItemCooldown", "GetItemCooldown", "C_Container.PickupContainerItem", "PickupContainerItem",
        "DeleteCursorItem", "GetCursorInfo", "C_Container.GetContainerItemID" }) do
        calls[#calls + 1] = name .. "=" .. (Exists(name) and "yes" or "no")
    end
    Log("calls: " .. table.concat(calls, " "))
    Log("soul shards: " .. ns.Shards.Count() .. ", limit " .. tostring(ns.db.shardLimit) .. ", over " .. ns.Shards.Excess())
    for _, kind in ipairs(ns.Stones.KINDS) do
        local known = {}
        for _, rank in ipairs(ns.STONES[kind].ranks) do
            known[#known + 1] = rank.spell .. "=" .. (ns.Stones.IsKnown(rank.spell) and "known" or "no")
        end
        local item, total = ns.Stones.Carried(kind)
        local cdText = "-"
        if item then
            local cd = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
            local start, duration = cd and cd(item)
            cdText = string.format("start %s duration %s (data %ds)", tostring(start), tostring(duration), ns.STONES[kind].cooldown)
        end
        local d = ns.Stones.Decide(kind)
        Log(string.format("%s: ranks %s | carrying %d (best %s) | cooldown %s | button: %s %s", kind, table.concat(known, " "),
            total, tostring(item), cdText, d.action, tostring(d.item or d.spell or "")))
    end
    local name, left = ns.Tracker.Current()
    Log("tracked soulstone: " .. (name and (name .. ", " .. ns.Tracker.Format(left) .. " left") or "none"))
end

local function BuildPanel()
    panel = CreateFrame("Frame", "NullgatesShardsStonesCheck", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(300, 150)
    panel:SetPoint("TOPLEFT", NullgateReport.Frame(), "TOPRIGHT", 4, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    local title = "Shards & Stones check"
    if type(panel.SetTitle) == "function" then panel:SetTitle(title)
    elseif type(panel.TitleText) == "table" then panel.TitleText:SetText(title) end
    local trim = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    trim:SetSize(260, 22)
    trim:SetPoint("TOP", panel, "TOP", 0, -36)
    trim:SetText("1. Delete one extra shard")
    trim:SetScript("OnClick", function()
        local before = ns.Shards.Count()
        if ns.Shards.Excess() <= 0 then
            Log("trim: you're not over your shard limit; set a limit below your shard count first")
            return
        end
        local ok, deleted = pcall(ns.Shards.TrimOne)
        C_Timer.After(0.5, function()
            Log(string.format("trim: %s, shards %d -> %d", ok and (deleted and "deleted" or "nothing deleted") or ("error " .. tostring(deleted)),
                before, ns.Shards.Count()))
        end)
    end)
    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOP", trim, "BOTTOM", 0, -10)
    note:SetWidth(270)
    note:SetText("2. Use a Soulstone (on anyone) while this window is open; the result goes to chat. Results are saved.")
end

-- While the window is open: report cast events and blocked actions.
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UNIT_SPELLCAST_SENT")
watcher:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
watcher:RegisterEvent("ADDON_ACTION_BLOCKED")
watcher:RegisterEvent("ADDON_ACTION_FORBIDDEN")
watcher:SetScript("OnEvent", function(_, event, a, b, c, d)
    if not (panel and panel:IsShown()) then return end
    if event == "UNIT_SPELLCAST_SENT" then
        if a == "player" then watching = { target = b, spell = d } end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if a == "player" and ns.Tracker.IsSoulstoneBuff(c) then
            Log(string.format("soulstone: cast %s seen, sent target %s -> tracker %s", tostring(c),
                tostring(watching and watching.target), ns.Tracker.Current() and "recorded" or "NOT recorded"))
        end
    else
        Log(event .. ": " .. tostring(a) .. " tried " .. tostring(b))
    end
end)

function Check.Run()
    if ns.db then ns.db.check = {} end
    StaticChecks()
    if not panel then BuildPanel() end
    panel:Show()
    Check.ShowReport()
end
