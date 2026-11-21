**Nullgate's Shards & Stones** is a warlock addon for **World of Warcraft: Forever**. It counts your soul shards, helps you keep only as many as you want, and gives you one button each for Healthstones and Soulstones: use the stone if you have one, make one if you don't.

No more bags full of shards you'll never use, hunting for the right rank of Create Healthstone, or forgetting who has your Soulstone.

> **Beta:** this is an early test version and we're looking for warlocks to try it. If something doesn't work, run `/nshard check`, then send us the results with a short description.

---

## Features

- **Shard counter** on the bar, with an optional warning when you're running low.
- **Shard limit**: choose how many shards to keep. When you have more, the shard counter shows how many are extra, and each click on it deletes one. Nothing is ever deleted without a click.
- **Healthstone button**: uses your Healthstone if you have one, or creates one at the highest rank you know. Stones from Improved Healthstone count too.
- **Soulstone button**: puts your Soulstone on your target (or yourself with no target) if you have one, or creates one. The cooldown is shown on the button.
- **Soulstone tracker**: who holds your Soulstone, with its 30-minute timer.
- **Spellstone and Firestone buttons** that work the same way, if you want them on your bar.
- **Key bindings** for every button, under Key Bindings > AddOns.
- **Simple settings**: lock and move the bar, vertical or horizontal layout, scale, which buttons to show, the shard limit and the language.

---

## How It Works

- **Have a stone?** Clicking its button uses it.
- **No stone?** Clicking casts the create spell at the highest rank you know.
- **Too many shards?** The shard counter shows how many are over your limit. Each click on it deletes one.

The game doesn't allow buttons to change during combat. If a button should switch from "create" to "use" mid-fight, it shows a small red mark and switches as soon as combat ends.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/nshard` or `/shards` | Open the settings. |
| `/nshard lock` / `/nshard unlock` | Lock or unlock the bar. |
| `/nshard reset` | Reset the bar's position. |
| `/nshard check` | Test what the addon needs in your game client and save the results (for bug reports). |

---

## Installation

1. Download the latest file.
2. Extract the `NullgatesShardsStones-Forever` folder into the `Interface\AddOns` folder of your World of Warcraft: Forever installation.
3. Log in on a warlock. The bar appears near the bottom of the screen; type `/nshard` for the settings.

---

## Good to Know

- The addon only runs for warlocks.
- Shards are only deleted when you click the shard counter, one per click, and never below your limit. The limit is off until you set one.
- Available in 10 languages: English, Deutsch, Español, Français, Italiano, Português (Brasil), Русский, 한국어, 简体中文 and 繁體中文 (every language the game client runs in). The game's language is used automatically, and you can pick another in the settings. The translations were made with machine assistance; corrections are welcome.
