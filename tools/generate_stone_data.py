"""Builds Data/Stones.lua from the Forever client's tables on wago.tools.

For each warlock stone (Healthstone, Soulstone, Spellstone, Firestone): every trainer rank of its
Create spell (skill line 354, Demonology) with the level it's learned at, the items that rank makes,
and from the items' use effects the cooldown and, for Soulstones, the buff they put on the target.

Create Healthstone picks its item when cast (the Improved Healthstone talent gives a better
variant), so its items are matched by tier: the Create Healthstone item variants are grouped by
name, sorted by required level, and paired with the trainer ranks in order.

Usage:
  python tools/generate_stone_data.py [--build 1.60.1.70532] [--data DIR]
"""
import argparse
import csv
import io
import json
import os
import sys
import urllib.request
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "NullgatesShardsStones-Forever", "Data", "Stones.lua")
TABLES = ("SpellName", "SpellLevels", "SpellEffect", "SpellMisc", "SpellDuration", "SkillLineAbility",
          "ItemSparse", "ItemEffect", "ItemXItemEffect")
DEMONOLOGY = "354"
CREATE_ITEM = "24"
KINDS = {"Create Healthstone": "healthstone", "Create Soulstone": "soulstone",
         "Create Spellstone": "spellstone", "Create Firestone": "firestone"}
SOUL_SHARD = 6265


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "NullgatesShardsStones-generator"})
    with urllib.request.urlopen(req, timeout=300) as resp:
        return resp.read().decode("utf-8")


def latest_build():
    return json.loads(fetch("https://wago.tools/api/builds/latest"))["wow_classic_beta"]["version"]


def load(name, build, data_dir):
    if data_dir:
        with open(os.path.join(data_dir, name + ".csv"), encoding="utf-8") as f:
            text = f.read()
    else:
        text = fetch("https://wago.tools/db2/%s/csv?build=%s" % (name, build))
    return list(csv.DictReader(io.StringIO(text)))


def to_int(value):
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return 0


def build(t):
    names = {r["ID"]: r["Name_lang"] for r in t["SpellName"]}
    levels = {r["SpellID"]: to_int(r.get("SpellLevel")) or to_int(r.get("BaseLevel")) for r in t["SpellLevels"]}
    lines = {r["Spell"]: r["SkillLine"] for r in t["SkillLineAbility"]}
    creates = defaultdict(list)
    for r in t["SpellEffect"]:
        if r["Effect"] == CREATE_ITEM and to_int(r["EffectItemType"]):
            creates[r["SpellID"]].append(to_int(r["EffectItemType"]))
    sparse = {to_int(r["ID"]): r for r in t["ItemSparse"]}
    misc = {r["SpellID"]: r for r in t["SpellMisc"]}
    durations = {r["ID"]: to_int(r["Duration"]) for r in t["SpellDuration"]}
    effects = {r["ID"]: r for r in t["ItemEffect"]}
    item_effect = {}
    for r in t["ItemXItemEffect"]:
        e = effects.get(r["ItemEffectID"])
        if e:
            item_effect[to_int(r["ItemID"])] = e

    # Trainer ranks per kind.
    ranks = defaultdict(list)
    for spell, name in names.items():
        kind = KINDS.get(name)
        if kind and lines.get(spell) == DEMONOLOGY and levels.get(spell):
            ranks[kind].append({"spell": to_int(spell), "level": levels[spell], "items": creates.get(spell, [])})
    for kind in KINDS.values():
        ranks[kind].sort(key=lambda r: r["level"])
        if not ranks[kind]:
            sys.exit("no trainer ranks found for " + kind)

    # Healthstone items by tier: every item any "Create Healthstone*" spell makes, grouped by name.
    tiers = defaultdict(set)
    for spell, name in names.items():
        if name.startswith("Create Healthstone"):
            for item in creates.get(spell, []):
                s = sparse.get(item)
                if s and s.get("Display_lang", "").endswith("Healthstone"):
                    tiers[s["Display_lang"]].add(item)
    ordered = sorted(tiers.values(), key=lambda ids: min(to_int(sparse[i]["RequiredLevel"]) for i in ids))
    if len(ordered) != len(ranks["healthstone"]):
        sys.exit("%d healthstone tiers for %d ranks" % (len(ordered), len(ranks["healthstone"])))
    for rank, ids in zip(ranks["healthstone"], ordered):
        rank["items"] = sorted(ids)

    out = {}
    for kind, list_ in ranks.items():
        cooldown, buff_spells, buff_duration = 0, [], 0
        for rank in list_:
            if not rank["items"]:
                sys.exit("rank %d of %s makes no item" % (rank["spell"], kind))
            for item in rank["items"]:
                e = item_effect.get(item)
                if not e:
                    continue
                cooldown = max(cooldown, to_int(e.get("CategoryCoolDownMSec")), to_int(e.get("CoolDownMSec")))
                if kind == "soulstone":
                    spell = e["SpellID"]
                    m = misc.get(spell)
                    buff_spells.append(to_int(spell))
                    buff_duration = max(buff_duration, durations.get(m["DurationIndex"], 0) if m else 0)
        out[kind] = {"ranks": list_, "cooldown": cooldown // 1000,
                     "buffSpells": sorted(set(buff_spells)), "buffDuration": buff_duration // 1000,
                     "names": {i: sparse[i]["Display_lang"] for r in list_ for i in r["items"]}}
    return out


def write(build_id, data):
    lines = [
        "-- Generated by tools/generate_stone_data.py from the Forever client data. Do not edit by hand.",
        "local _, ns = ...",
        "",
        'ns.STONE_DATA_BUILD = "%s"' % build_id,
        "ns.SOUL_SHARD = %d" % SOUL_SHARD,
        "",
        "-- Per stone: trainer ranks (Create spell, level learned, items it makes), the item cooldown in",
        "-- seconds and, for Soulstones, the buff spells and their duration in seconds.",
        "ns.STONES = {",
    ]
    for kind in ("healthstone", "soulstone", "spellstone", "firestone"):
        d = data[kind]
        lines.append("    %s = {" % kind)
        lines.append("        cooldown = %d," % d["cooldown"])
        if d["buffSpells"]:
            lines.append("        buffSpells = { %s }," % ", ".join(str(s) for s in d["buffSpells"]))
            lines.append("        buffDuration = %d," % d["buffDuration"])
        lines.append("        ranks = {")
        for r in d["ranks"]:
            names = ", ".join(sorted(set(d["names"][i] for i in r["items"])))
            lines.append("            { spell = %d, level = %d, items = { %s } }, -- %s" % (
                r["spell"], r["level"], ", ".join(str(i) for i in r["items"]), names))
        lines.append("        },")
        lines.append("    },")
    lines.append("}")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--build")
    parser.add_argument("--data")
    args = parser.parse_args()
    build_id = args.build or latest_build()
    data = build({name: load(name, build_id, args.data) for name in TABLES})
    write(build_id, data)
    for kind, d in data.items():
        print("%-12s %d ranks, cooldown %ds%s" % (kind, len(d["ranks"]), d["cooldown"],
              (", buff %ds" % d["buffDuration"]) if d["buffSpells"] else ""))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
