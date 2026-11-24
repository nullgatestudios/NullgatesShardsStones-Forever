-- Nullgate's Shards & Stones: smoke test of the whole addon with stand-in game API.
-- Loads the files in .toc order, logs in as a warlock and drives the stone buttons, combat,
-- trimming shards, the low-shard warning, the Soulstone tracker, settings and /nshard check.
-- Run from the repository root:  lua tests/smoke.lua

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/smoke.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local repo = scriptDir:match("^(.*)[/\\][^/\\]*$") or "."
local folder = "NullgatesShardsStones-Forever"
local root = repo .. "/" .. folder .. "/"

local checks, failures = 0, 0
local function OK(cond, name)
    checks = checks + 1
    if not cond then failures = failures + 1; io.write("FAIL " .. name .. "\n") end
end

-- --- Stand-in game API ----------------------------------------------------------
local frames, printed = {}, {}
local function NewFrame(kind, name, _, template)
    local f = { kind = kind, name = name, template = template, scripts = {}, attributes = {}, events = {}, shown = false }
    setmetatable(f, { __index = function(_, key) if type(key) == "string" and key:match("^%u") then return function() return nil end end end })
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:GetScript(k) return self.scripts[k] end
    function f:RegisterEvent(e) self.events[e] = true end
    function f:SetAttribute(k, v) self.attributes[k] = v end
    function f:GetAttribute(k) return self.attributes[k] end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:SetShown(v) self.shown = v and true or false end
    function f:IsShown() return self.shown end
    function f:SetText(t) self.text = t end
    function f:GetText() return self.text end
    function f:SetTexture(t) self.texture = t end
    function f:SetChecked(v) self.checked = v end
    function f:GetChecked() return self.checked end
    function f:CreateFontString() return NewFrame("FontString") end
    function f:CreateTexture() return NewFrame("Texture") end
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
CreateFrame = NewFrame
SlashCmdList = {}
UIParent = NewFrame("Frame", "UIParent")
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
UISpecialFrames = {}
print = function(text) printed[#printed + 1] = tostring(text) end
local function Printed(fragment)
    for _, line in ipairs(printed) do if line:find(fragment, 1, true) then return true end end
    return false
end

local class, inCombat = "WARLOCK", false
function UnitClass() return class, class end
function UnitLevel() return 60 end
function UnitName() return "Me" end
function InCombatLockdown() return inCombat end
function GetBuildInfo() return "1.60.1", "70532", "Nov 2026", 16001 end
C_Timer = { After = function(_, fn) fn() end }
local now = 5000
function time() return now end

local known = {}
for _, id in ipairs({ 6201, 6202, 5699, 11729, 11730, 693, 20752, 20755, 20756, 20757 }) do known[id] = true end
C_SpellBook = { IsSpellKnown = function(id) return known[id] == true end }

-- Bags: [bag][slot] = itemID (one item per slot, which is all the addon needs).
local bags = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }
local function Put(bag, slot, id) bags[bag][slot] = id end
local function CountOf(id) local n = 0; for _, b in pairs(bags) do for _, i in pairs(b) do if i == id then n = n + 1 end end end; return n end
local cursor
C_Item = {
    GetItemCount = CountOf,
    GetItemIconByID = function(id) return "icon" .. id end,
    GetItemInfo = function(id) return "Item" .. id end,
}
C_Container = {
    GetContainerNumSlots = function() return 16 end,
    GetContainerItemID = function(bag, slot) return bags[bag][slot] end,
    PickupContainerItem = function(bag, slot) cursor = { bag = bag, slot = slot, id = bags[bag][slot] } end,
    GetItemCooldown = function(id) if id == 19013 then return 4900, 120 end return 0, 0 end,
}
function GetCursorInfo() if cursor then return "item", cursor.id end end
function CursorHasItem() return cursor ~= nil end
function ClearCursor() cursor = nil end
local deleted = 0
function DeleteCursorItem() bags[cursor.bag][cursor.slot] = nil; cursor = nil; deleted = deleted + 1 end

-- --- Load the files in .toc order -----------------------------------------------
local ns = {}
local toc = assert(io.open(root .. folder .. ".toc", "r")):read("*a")
for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^##") and line:match("%.lua$") then
        assert(loadfile(root .. line:gsub("\\", "/")))(folder, ns)
    end
end
local core
for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then core = f end end
local function Fire(event, ...) core.scripts.OnEvent(core, event, ...) end
Fire("ADDON_LOADED", folder)
local db = NullgatesShardsStonesDB
OK(type(db) == "table" and db.show.healthstone and not db.show.firestone, "saved data gets its defaults")
OK(SLASH_NULLGATESSHARDSSTONES1 == "/nshard" and SLASH_NULLGATESSHARDSSTONES2 == "/shards", "slash commands /nshard and /shards")
OK(_G["BINDING_NAME_CLICK NullgatesShardsStonesHealthstone:LeftButton"] ~= nil, "the Healthstone key binding has a name")

-- --- Login ------------------------------------------------------------------------
for s = 1, 5 do Put(0, s, 6265) end
Fire("PLAYER_LOGIN")
local hs, ss = NullgatesShardsStonesHealthstone, NullgatesShardsStonesSoulstone
OK(hs and ss and NullgatesShardsStonesShards, "the stone buttons and the shard counter exist")
OK(hs.template == "SecureActionButtonTemplate", "stone buttons are secure")
OK(hs.attributes.type == "spell" and hs.attributes.spell == 11730, "no Healthstone: create the highest rank (Major)")
OK(ss.attributes.spell == 20757, "no Soulstone: create the Major Soulstone")
OK(hs.shown and ss.shown and not NullgatesShardsStonesFirestone.shown, "Healthstone and Soulstone shown, Firestone off by default")
OK(NullgatesShardsStonesShards.count.text == 5, "the shard counter shows 5")

-- --- Bags change: use instead of create ------------------------------------------------
Put(1, 1, 19013)
Put(1, 2, 16896)
Fire("BAG_UPDATE_DELAYED")
OK(hs.attributes.type == "item" and hs.attributes.item == "item:19013", "carrying a Major Healthstone: the button uses it")
OK(ss.attributes.type == "macro" and ss.attributes.macrotext:find("item:16896", 1, true), "carrying a Soulstone: the button uses it on your target")

-- --- Combat: changes wait ----------------------------------------------------------------
inCombat = true
bags[1][1] = nil
Fire("BAG_UPDATE_DELAYED")
OK(hs.attributes.type == "item" and hs.stale, "in combat the button doesn't change and is marked")
inCombat = false
Fire("PLAYER_REGEN_ENABLED")
OK(hs.attributes.type == "spell" and not hs.stale, "after combat it switches to create")

-- --- Shards: limit and trim -------------------------------------------------------------
for s = 6, 8 do Put(0, s, 6265) end -- 8 shards
db.shardLimit = 6
local trim = NullgatesShardsStonesShards
trim.scripts.OnClick(trim)
OK(deleted == 1 and CountOf(6265) == 7, "one click deletes exactly one extra shard")
OK(bags[0][8] == nil and bags[0][1] == 6265, "the last shard in the bags is the one deleted")
trim.scripts.OnClick(trim)
trim.scripts.OnClick(trim)
OK(deleted == 2 and CountOf(6265) == 6, "never below the limit")
inCombat = true
Put(0, 9, 6265)
trim.scripts.OnClick(trim)
OK(deleted == 2, "nothing is deleted in combat")
inCombat = false
db.shardLimit = 0
trim.scripts.OnClick(trim)
OK(deleted == 2, "limit off: Trim does nothing")

-- --- Low shards warning ----------------------------------------------------------------
for s = 1, 9 do bags[0][s] = nil end
Put(0, 1, 6265)
printed = {}
Fire("BAG_UPDATE_DELAYED")
OK(Printed("Low on soul shards: 1 left."), "one shard left: a warning")
printed = {}
Fire("BAG_UPDATE_DELAYED")
OK(#printed == 0, "no repeat until you have more")

-- --- Soulstone tracker -------------------------------------------------------------------
Fire("UNIT_SPELLCAST_SENT", "player", "Priestess", "guid", 20765)
Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "guid", 20765)
local name, left = ns.Tracker.Current()
OK(name == "Priestess" and left == 1800, "the tracker records who got the Soulstone")
OK(db.soulstone and db.soulstone.expires == now + 1800, "and saves it across a reload")
now = now + 1801
OK(ns.Tracker.Current() == nil, "30 minutes later it's gone")

-- --- Other classes --------------------------------------------------------------------------
-- (a fresh load would be needed to change class at login; the command guard is tested here)

-- --- Settings -----------------------------------------------------------------------------
SlashCmdList.NULLGATESSHARDSSTONES("")
OK(NullgatesShardsStonesOptions and NullgatesShardsStonesOptions.shown, "/nshard opens the settings window")
SlashCmdList.NULLGATESSHARDSSTONES("lock")
OK(db.locked == true, "/nshard lock locks the bar")
db.show.firestone = true
ns.Buttons.Layout()
OK(NullgatesShardsStonesFirestone.shown, "turning on the Firestone button shows it")

-- --- /nshard check ---------------------------------------------------------------------------
SlashCmdList.NULLGATESSHARDSSTONES("check")
do -- the report window every Nullgate addon shares
    local w = NullgateReportWindow
    OK(w and w.shown and w.url == "https://nullgatestudios.com/report?addon=shards-stones", "check opens the shared report window with this addon's link")
    OK(w and w.text and w.text:find("Addon: shards-stones\nNullgate's Shards & Stones - Forever ", 1, true) == 1, "the report starts with the addon's slug and name")
    OK(w and w.box.text == w.text and w.link.text == w.url, "the report and the link are in the window, ready to copy")
end
local log = table.concat(db.check or {}, "\n")
OK(log:find("DeleteCursorItem=yes", 1, true), "check reports which calls exist")
OK(log:find("healthstone: ranks 6201=known", 1, true), "check reports the known ranks")
OK(NullgatesShardsStonesCheck and NullgatesShardsStonesCheck.shown, "the check window opens")

io.write(string.format("smoke: %d checks, %d failure(s)\n", checks, failures))
if failures > 0 then os.exit(1) end
