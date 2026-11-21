# Changelog

All notable changes to Nullgate's Shards & Stones - Forever.

## [1.0.0-beta.1] - 2026-11-20

First test version, looking for warlocks to try it.

### New

- **Healthstone, Soulstone, Spellstone and Firestone buttons**: each uses your best stone if you carry one, or creates one at the highest rank you know. Healthstone and Soulstone are on the bar by default; Spellstone and Firestone can be turned on in the settings.
- **Soulstones go where you want**: on your mouseover or target when it's a friendly player, otherwise on you.
- **Soul shard counter**, with a warning when you're running low.
- **Shard limit** (off by default): when you have more, each click on the shard counter deletes one extra shard. Nothing is ever deleted without a click, and never below your limit.
- **Soulstone tracker**: who holds your Soulstone and how long is left, in the Soulstone button's tooltip. It survives a reload or relog.
- **Cooldowns** shown on the stone buttons, and key bindings for every stone under Key Bindings > AddOns.
- **Settings** in its own window or inside Nullgate's Addon Config.
- **`/nshard check`**: tests what the addon needs in your client, including deleting a shard and tracking a Soulstone. Results are saved for bug reports.
- Ranks, items and cooldowns are read from the Forever client data.
- Available in English, Deutsch, Español, Français, Italiano, Português (Brasil), Русский, 한국어, 简体中文 and 繁體中文.

### Good to know

- Buttons can't change during combat. If a button should switch from "create" to "use" mid-fight, it shows a small red mark and switches as soon as combat ends.
