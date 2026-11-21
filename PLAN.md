# Nullgate's Shards & Stones - Forever: Plan

Status: phases 0 to 4 built as 1.0.0-beta.1 on 2026-11-20; the in-game checks wait for testers (`/nshard check`). Planned on 2026-11-20.

Forever data notes: Create Healthstone picks its item when cast (Improved Healthstone variants), so ranks map to three items each; Spellstones and Firestones are used from the bags in Forever (new use spells), so all four buttons are use-or-create. Healthstone cooldown 2 min; Soulstone buff and cooldown 30 min.

- **Folder:** `NullgatesShardsStones-Forever`
- **Saved variables:** `NullgatesShardsStonesDB` (per character)
- **Commands:** `/nshard` and `/shards`

## Decisions made

- Warlock only: the addon stays off for other classes.
- Shards are never deleted without a click: one click deletes one extra shard.
- Stone and spell data is generated from Forever client data (wago.tools), never typed by hand.
- Ships as 1.0.0-beta.1 for testers, like Food & Water.

## The constraint that shapes the design

Each stone button is a **secure button** that either uses the stone item or casts the create spell. Which one it does can only change **out of combat**, so the addon decides whenever your bags change and queues a switch made in combat until it ends. This is the same approach as Food & Water.

---

## Phase 0: Repo and checks

- Repo, README, plan, license, logo, CurseForge workflow, `/zips` packaging, tests.
- `/nshard check` in-game self test. Confirm in the Forever client:
  - Casting a create spell by numeric spell ID makes that rank.
  - Deleting an item from addon code on a click works (`PickupContainerItem` then `DeleteCursorItem`). If not, Trim picks the shard up for the player to destroy.
  - The Soulstone Resurrection aura shows in the combat log for tracking.

## Phase 1: Data and shard count

- Generator script: every Healthstone, Soulstone, Spellstone and Firestone item and create spell by rank, including Improved Healthstone variants.
- Shard counter and optional low-shard warning.
- Unit tests for rank picking.

## Phase 2: Healthstone and Soulstone buttons

- Use-or-create secure buttons with key bindings, icons and counts; movable, lockable bar.
- Soulstone use targets your target, or yourself with no target.
- Soulstone cooldown shown on the button.

## Phase 3: Shard limit and Soulstone tracker

- Shard limit setting; clicking the shard counter trims one extra shard.
- Soulstone tracker: who holds your Soulstone, with a 30-minute timer.

## Phase 4: More stones, settings, languages, beta

- Spellstone and Firestone buttons using the same logic.
- Settings window and Nullgate's Addon Config page.
- The 10 client languages.
- DESCRIPTION.md, CHANGELOG.md, 1.0.0-beta.1.
