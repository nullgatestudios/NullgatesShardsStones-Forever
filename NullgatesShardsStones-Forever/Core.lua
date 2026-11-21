-- Nullgate's Shards & Stones: saved data, events, the out-of-combat queue and slash commands.
local addonName, ns = ...

local L = ns.L

ns.DEFAULTS = {
    locked = false,
    vertical = false,
    scale = 1,
    show = { healthstone = true, soulstone = true, spellstone = false, firestone = false },
    shardLimit = 0,                             -- 0 = no limit, no Trim
    lowShards = { enabled = true, threshold = 3 },
    language = "auto",
}

local function Merge(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            Merge(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function ns.Print(text)
    print("|cff00c0ffShards & Stones:|r " .. tostring(text))
end

function ns.IsWarlock()
    local _, class = UnitClass("player")
    return class == "WARLOCK"
end

-- Runs fn now when out of combat; in combat it runs once combat ends (the latest fn per key wins).
-- Returns true when fn ran now.
local pending = {}
function ns.WhenSafe(key, fn)
    if InCombatLockdown() then
        pending[key] = fn
        return false
    end
    pending[key] = nil
    fn()
    return true
end

BINDING_HEADER_NULLGATESSHARDSSTONES = "Nullgate's Shards & Stones"
local function NameBindings()
    _G["BINDING_NAME_CLICK NullgatesShardsStonesHealthstone:LeftButton"] = L["Use or create a Healthstone"]
    _G["BINDING_NAME_CLICK NullgatesShardsStonesSoulstone:LeftButton"] = L["Use or create a Soulstone"]
    _G["BINDING_NAME_CLICK NullgatesShardsStonesSpellstone:LeftButton"] = L["Use or create a Spellstone"]
    _G["BINDING_NAME_CLICK NullgatesShardsStonesFirestone:LeftButton"] = L["Use or create a Firestone"]
end

local events = CreateFrame("Frame")
local active = false

local function OnEvent(_, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            if type(NullgatesShardsStonesDB) ~= "table" then NullgatesShardsStonesDB = {} end
            Merge(NullgatesShardsStonesDB, ns.DEFAULTS)
            ns.db = NullgatesShardsStonesDB
            ns.SetLanguage(ns.db.language)
            NameBindings()
        end
        if arg1 == addonName or arg1 == "NullgatesAddonConfig-Forever" then ns.Options.RegisterHub() end
    elseif event == "PLAYER_LOGIN" then
        active = ns.IsWarlock()
        if active then
            ns.Buttons.Create()
            ns.Shards.Check()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for key, fn in pairs(pending) do
            pending[key] = nil
            fn()
        end
    elseif not active then
        return
    elseif event == "BAG_UPDATE_DELAYED" then
        ns.Buttons.Update()
        ns.Shards.Check()
    elseif event == "BAG_UPDATE_COOLDOWN" then
        ns.Buttons.UpdateCounts()
    elseif event == "UNIT_SPELLCAST_SENT" then
        ns.Tracker.OnSent(...)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        ns.Tracker.OnSucceeded(...)
    else -- new spells learned
        ns.Buttons.Update()
    end
end

events:SetScript("OnEvent", OnEvent)
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB",
    "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED" }) do
    events:RegisterEvent(event)
end

local function Help()
    ns.Print(L["commands:"])
    print("  /nshard - " .. L["open the settings"])
    print("  /nshard lock | unlock - " .. L["lock or unlock the bar"])
    print("  /nshard reset - " .. L["reset the bar's position"])
    print("  /nshard check - " .. L["test what the addon needs in this client (results are saved)"])
end

SLASH_NULLGATESSHARDSSTONES1 = "/nshard"
SLASH_NULLGATESSHARDSSTONES2 = "/shards"
SlashCmdList["NULLGATESSHARDSSTONES"] = function(msg)
    local command = string.lower((msg or ""):match("^%s*(%S*)") or "")
    if command == "check" then
        ns.Check.Run()
    elseif command == "help" then
        Help()
    elseif not active then
        ns.Print(L["This addon is for warlocks; only /nshard check works on other classes."])
    elseif command == "" or command == "options" or command == "config" then
        ns.Options.Open()
    elseif command == "lock" or command == "unlock" then
        ns.db.locked = command == "lock"
        ns.Buttons.Layout()
    elseif command == "reset" then
        ns.Buttons.ResetPosition()
    else
        Help()
    end
end
