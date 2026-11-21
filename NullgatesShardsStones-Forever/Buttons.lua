-- Nullgate's Shards & Stones: the bar. One secure button per stone (use it if carried, create it
-- if not), the shard counter and the Trim button. What a stone button does can only change out
-- of combat; changes made in combat wait for it to end and the button shows a red mark.
local _, ns = ...

local L = ns.L
local Buttons = {}
ns.Buttons = Buttons

local SIZE, GAP = 36, 4
local ICONS = {
    healthstone = "Interface\\Icons\\INV_Stone_04",
    soulstone = "Interface\\Icons\\Spell_Shadow_SoulGem",
    spellstone = "Interface\\Icons\\INV_Misc_Gem_Sapphire_01",
    firestone = "Interface\\Icons\\INV_Ammo_FireTar",
    shard = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02",
}
local NAMES -- set on first use, after the language is known
local bar
local buttons = {}
Buttons.buttons = buttons

local function Names()
    NAMES = NAMES or {
        healthstone = L["Healthstone"], soulstone = L["Soulstone"],
        spellstone = L["Spellstone"], firestone = L["Firestone"],
    }
    return NAMES
end

local function ItemIcon(itemID)
    local icon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    return icon and icon(itemID) or nil
end

local function ItemName(itemID)
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    return info and (info(itemID)) or nil
end

local function ItemCooldown(itemID)
    local cd = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    if not cd then return 0, 0 end
    local start, duration = cd(itemID)
    return start or 0, duration or 0
end

local function ShowTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    local kind, d = button.kind, button.decision
    if kind == "shard" then
        GameTooltip:AddLine(L["Soul Shards"], 1, 0.82, 0)
        GameTooltip:AddLine(string.format(L["Carrying %d."], ns.Shards.Count()), 1, 1, 1)
        local limit = ns.db.shardLimit or 0
        if limit > 0 then
            GameTooltip:AddLine(string.format(L["Keeping at most %d."], limit), 0.8, 0.8, 0.8)
            if ns.Shards.Excess() > 0 then
                GameTooltip:AddLine(string.format(L["Click to delete one extra shard (%d over)."], ns.Shards.Excess()), 1, 0.5, 0.3, true)
            end
        end
    elseif d and d.action == "use" then
        GameTooltip:AddLine(ItemName(d.item) or Names()[kind], 1, 0.82, 0)
        GameTooltip:AddLine(kind == "soulstone" and L["Click to put it on your target (or yourself with no friendly target)."]
            or L["Click to use it."], 1, 1, 1, true)
        GameTooltip:AddLine(string.format(L["Carrying %d."], d.total), 0.8, 0.8, 0.8)
    elseif d and d.action == "create" then
        GameTooltip:AddLine(Names()[kind], 1, 0.82, 0)
        GameTooltip:AddLine(L["You have none: click to create one."], 1, 1, 1, true)
    else
        GameTooltip:AddLine(Names()[kind], 1, 0.82, 0)
        GameTooltip:AddLine(L["You don't know how to create this stone yet."], 1, 0.3, 0.3, true)
    end
    if kind == "soulstone" then
        local name, left = ns.Tracker.Current()
        if name then
            GameTooltip:AddLine(string.format(L["Your Soulstone is on %s (%s left)."], name, ns.Tracker.Format(left)), 0.6, 0.8, 1, true)
        end
    end
    if button.stale then GameTooltip:AddLine(L["In combat: updates when combat ends."], 1, 0.3, 0.3, true) end
    GameTooltip:Show()
end

local function NewButton(name, kind, template)
    local button = CreateFrame("Button", name, bar, template)
    button.kind = kind
    button:SetSize(SIZE, SIZE)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(ICONS[kind])
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button)
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)
    button.staleMark = button:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    button.staleMark:SetPoint("TOPLEFT", 2, -2)
    button.staleMark:SetText("*")
    button.staleMark:Hide()
    button.plus = button:CreateFontString(nil, "OVERLAY", "GameFontGreenSmall")
    button.plus:SetPoint("TOPRIGHT", -2, -2)
    button.plus:SetText("+")
    button.plus:Hide()
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.15)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    buttons[kind] = button
    return button
end

local function SavePosition()
    local point, _, relativePoint, x, y = bar:GetPoint()
    ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function RestorePosition()
    bar:ClearAllPoints()
    local p = ns.db.point
    if p and p.point then
        bar:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    end
end

function Buttons.Create()
    if bar then return end
    bar = CreateFrame("Frame", "NullgatesShardsStonesBar", UIParent)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        if not ns.db.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    bar.background = bar:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints(bar)
    bar.background:SetColorTexture(0.08, 0.1, 0.13, 0.75)

    local shard = NewButton("NullgatesShardsStonesShards", "shard")
    shard:RegisterForClicks("LeftButtonUp")
    shard:SetScript("OnClick", function(self)
        if ns.Shards.TrimOne() then
            C_Timer.After(0.2, Buttons.UpdateCounts)
        end
        if GameTooltip:IsOwned(self) then ShowTooltip(self) end
    end)
    for _, kind in ipairs(ns.Stones.KINDS) do
        local name = "NullgatesShardsStones" .. kind:sub(1, 1):upper() .. kind:sub(2)
        local button = NewButton(name, kind, "SecureActionButtonTemplate")
        button:RegisterForClicks("AnyUp", "AnyDown")
        button:RegisterForDrag("LeftButton")
        button:SetScript("OnDragStart", function() bar:GetScript("OnDragStart")(bar) end)
        button:SetScript("OnDragStop", function() bar:GetScript("OnDragStop")(bar) end)
    end
    RestorePosition()
    Buttons.Layout()
    Buttons.Update()
end

-- The buttons shown, in order: the shard counter, then the stones that are turned on.
function Buttons.Order()
    local order = { buttons.shard }
    for _, kind in ipairs(ns.Stones.KINDS) do
        if ns.db.show[kind] then order[#order + 1] = buttons[kind] end
    end
    return order
end

function Buttons.Layout()
    if not bar then return end
    ns.WhenSafe("layout", function()
        local order = Buttons.Order()
        for _, kind in ipairs(ns.Stones.KINDS) do buttons[kind]:Hide() end
        for i, button in ipairs(order) do
            button:ClearAllPoints()
            local offset = GAP + (i - 1) * (SIZE + GAP)
            if ns.db.vertical then
                button:SetPoint("TOP", bar, "TOP", 0, -offset)
            else
                button:SetPoint("LEFT", bar, "LEFT", offset, 0)
            end
            button:Show()
        end
        local long, short = GAP + #order * (SIZE + GAP), SIZE + 2 * GAP
        if ns.db.vertical then bar:SetSize(short, long) else bar:SetSize(long, short) end
        bar:SetScale(ns.db.scale or 1)
        bar.background:SetShown(not ns.db.locked)
        bar:Show()
    end)
    Buttons.UpdateCounts()
end

-- Sets each stone button to use or create, out of combat.
function Buttons.Update()
    if not bar then return end
    local applied = ns.WhenSafe("stones", function()
        for _, kind in ipairs(ns.Stones.KINDS) do
            local button = buttons[kind]
            local decision = ns.Stones.Decide(kind)
            button.decision = decision
            local attrs = ns.Stones.Attributes(kind, decision)
            for _, key in ipairs({ "type", "item", "spell", "macrotext" }) do button:SetAttribute(key, attrs[key]) end
            button.icon:SetTexture((decision.item and ItemIcon(decision.item)) or ICONS[kind])
            button.icon:SetDesaturated(decision.action ~= "use")
            button.plus:SetShown(decision.action == "create")
            button.stale = false
            button.staleMark:Hide()
        end
    end)
    if not applied then
        for _, kind in ipairs(ns.Stones.KINDS) do
            buttons[kind].stale = true
            buttons[kind].staleMark:Show()
        end
    end
    Buttons.UpdateCounts()
end

-- Counts and cooldowns aren't protected, so they update any time.
function Buttons.UpdateCounts()
    if not bar then return end
    local shards = ns.Shards.Count()
    buttons.shard.count:SetText(shards)
    local excess = ns.Shards.Excess()
    buttons.shard.plus:SetText(excess > 0 and ("-" .. excess) or "")
    buttons.shard.plus:SetShown(excess > 0)
    for _, kind in ipairs(ns.Stones.KINDS) do
        local button = buttons[kind]
        local d = button.decision
        local _, total = ns.Stones.Carried(kind)
        button.count:SetText(total > 0 and total or "")
        if d and d.item then
            local start, duration = ItemCooldown(d.item)
            if duration > 1.5 then button.cooldown:SetCooldown(start, duration) else button.cooldown:Clear() end
        else
            button.cooldown:Clear()
        end
    end
end

function Buttons.ResetPosition()
    if not bar then return end
    ns.db.point = nil
    ns.WhenSafe("position", RestorePosition)
end
