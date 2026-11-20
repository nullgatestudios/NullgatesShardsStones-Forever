# Nullgate's Shards & Stones - Forever

> **Status: planning.** No code yet. See [PLAN.md](PLAN.md).

**Nullgate's Shards & Stones** is a warlock addon for **World of Warcraft: Forever**. It counts your soul shards, helps you keep only as many as you want, and gives you one button each for Healthstones and Soulstones: use the stone if you have one, make one if you don't.

---

## How It Works

- **Healthstone button**: if you carry a Healthstone, clicking uses it. If you don't, clicking casts Create Healthstone at the highest rank you know.
- **Soulstone button**: if you carry a Soulstone, clicking puts it on your target (or yourself with no target). If you don't, clicking creates one.
- **Shard limit**: set how many shards to keep. When you have more, the Trim button deletes one extra shard per click. Nothing is ever deleted without a click.

Buttons can't change in combat, so a button that should switch from "make" to "use" mid-fight switches as soon as combat ends.

---

## Features

- **Shard counter** with an optional low-shard warning.
- **Healthstone and Soulstone buttons** with key bindings and a movable bar. Stones from Improved Healthstone count too.
- **Soulstone tracker**: who holds your Soulstone, with its 30-minute timer and your cooldown.
- **Trim button** for shards above your limit.
- **Spellstone and Firestone buttons** (planned) that work the same way.
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

## License

Source-available, all rights reserved. See [LICENSE.md](LICENSE.md).
