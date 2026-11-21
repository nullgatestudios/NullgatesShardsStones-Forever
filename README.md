# Nullgate's Shards & Stones - Forever

> **Status: beta** (1.0.0-beta.1). Looking for warlocks to test it. See [CHANGELOG.md](CHANGELOG.md).

**Nullgate's Shards & Stones** is a warlock addon for **World of Warcraft: Forever**. It counts your soul shards, helps you keep only as many as you want, and gives you one button each for Healthstones and Soulstones: use the stone if you have one, make one if you don't.

---

## How It Works

- **Healthstone button**: if you carry a Healthstone, clicking uses it. If you don't, clicking casts Create Healthstone at the highest rank you know.
- **Soulstone button**: if you carry a Soulstone, clicking puts it on your target (or yourself with no target). If you don't, clicking creates one.
- **Shard limit**: set how many shards to keep. When you have more, the shard counter shows how many are extra, and each click on it deletes one. Nothing is ever deleted without a click.

Buttons can't change in combat, so a button that should switch from "make" to "use" mid-fight switches as soon as combat ends.

---

## Features

- **Shard counter** with an optional low-shard warning.
- **Healthstone and Soulstone buttons** with key bindings and a movable bar. Stones from Improved Healthstone count too.
- **Soulstone tracker**: who holds your Soulstone, with its 30-minute timer and your cooldown.
- **Shard limit** (off by default): click the shard counter to delete one shard above it.
- **Spellstone and Firestone buttons** that work the same way (off by default; turn them on in the settings).
- **Settings** in its own window or inside Nullgate's Addon Config.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/nshard` or `/shards` | Open the settings. |
| `/nshard lock` / `/nshard unlock` | Lock or unlock the bar. |
| `/nshard reset` | Reset the bar's position. |
| `/nshard check` | Test what the addon needs in your game client and save the results. |

---

## Installation

Not released yet. Once it is:

1. Download the latest release from CurseForge or the GitHub releases page.
2. Extract the `NullgatesShardsStones-Forever` folder into the `Interface\AddOns` folder of your World of Warcraft: Forever installation.
3. Log in on a warlock and type `/nshard`.

---

## Part of the Nullgate Addon Suite

- **Nullgate's Addon Config**: one settings hub and profile manager for the whole suite.
- **Nullgate's Restock**, **Quest Tracker**, **Unit Toggles**, **Blacklist** and more.

---

## Development

| Task | Command |
| :--- | :--- |
| Refresh the stone data after a client patch | `python tools/generate_stone_data.py` (reads the latest Forever build from wago.tools) |
| Run the tests | `lua tests/run.lua`, `lua tests/smoke.lua` and `lua tests/locales.lua` |
| Build `zips/NullgatesShardsStones-Forever-<version>.zip` | `.\package.ps1` (or `.\package.ps1 -Version 1.0.0` to set the version first) |

Publishing a GitHub release uploads that version to CurseForge (`.github/workflows/curseforge.yml`); pushes only run the tests.

---

## License

Source-available, all rights reserved. See [LICENSE.md](LICENSE.md).
