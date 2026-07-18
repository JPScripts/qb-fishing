# qb-fishing

Custom fishing script for QBCore, using **ox_target** for interactions and **ox_inventory** for items.
No skill progression, no minigame skill check — just a simple "cast and wait" progress bar, then a
weighted random catch. Fish are sold to an NPC for cash.

## Dependencies
- qb-core
- ox_target
- ox_inventory
- ox_lib

Make sure these are started **before** `qb-fishing` in your `server.cfg`.

```cfg
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qb-core
ensure qb-fishing
```

## Install

1. Drop this `qb-fishing` folder into your `resources` directory.
2. Add the item definitions below to your `ox_inventory/data/items.lua`.
3. Add matching image files (30x30 or 64x64 png) to `ox_inventory/web/images/`, named exactly
   like the item name (e.g. `fishing_rod.png`, `bait.png`, `fish_trout.png`, etc). Any placeholder
   icon works to start.
4. Edit `config.lua`:
   - Move `Config.FishingZones` coords to wherever you actually want fishing spots (docks, lakes, piers).
   - Move `Config.SellPed.coords` to where you want the buyer to stand.
   - Adjust `Config.Fish` chances/prices to taste (chances should add up to 100).
5. Restart your server / `ensure qb-fishing`.

## ox_inventory items to add

Paste into `ox_inventory/data/items.lua` inside the `Items = {}` table:

```lua
['fishing_rod'] = {
    label = 'Fishing Rod',
    weight = 1000,
    stack = false,
    close = true,
    description = 'Used to catch fish. Needs bait.'
},

['bait'] = {
    label = 'Fishing Bait',
    weight = 50,
    stack = true,
    close = true,
    description = 'A handful of bait for your rod.'
},

['fish_shark'] = {
    label = 'Shark',
    weight = 8000,
    stack = true,
    close = true,
    description = 'A rare catch. Worth a lot.'
},

['fish_tuna'] = {
    label = 'Tuna',
    weight = 4000,
    stack = true,
    close = true,
    description = 'A solid catch.'
},

['fish_salmon'] = {
    label = 'Salmon',
    weight = 2000,
    stack = true,
    close = true,
    description = 'A decent catch.'
},

['fish_trout'] = {
    label = 'Trout',
    weight = 1000,
    stack = true,
    close = true,
    description = 'A common catch.'
},

['fish_boot'] = {
    label = 'Old Boot',
    weight = 1500,
    stack = true,
    close = true,
    description = 'Junk. Not worth anything.'
},
```

## How it works

- **Fishing spots**: `ox_target` sphere zones give a "Go Fishing" option near water. Player needs
  a `fishing_rod` (not consumed) and `bait` (consumed 1 per cast) in their `ox_inventory` to start.
- **Casting**: plays a fishing animation and shows the custom NUI progress bar for a random
  duration (`Config.CatchTime`). No skill check — just wait it out.
- **Catch roll**: handled entirely server-side (`server/main.lua`) so it can't be manipulated
  client-side. Weighted random pick from `Config.Fish`, including a junk item chance.
- **Selling**: an NPC ped (`Config.SellPed`) gets an `ox_target` "Sell Fish" option that sells
  every sellable fish in your inventory for cash in one go.

## Customizing the UI

The NUI is plain HTML/CSS/JS in `html/`. It's just a progress bar card that fades in on
`startFishing` and out on `stopFishing` — no dependencies, no build step, so it's easy to
reskin (colors, fonts, position) in `html/style.css` without touching any Lua.

## Notes / things you may want to tweak

- Notifications use `ox_lib`'s `lib.notify`. If you don't use ox_lib for notifications, swap
  the `notify()` calls in `client/main.lua` for `QBCore.Functions.Notify` instead.
- The animation dict used is `amb@world_human_stand_fishing@idle_a` / `idle_c` — a real GTA anim,
  but feel free to swap for another one you prefer.
- This script intentionally has **no rod/bait tiers and no XP/leveling** per your spec — easy to
  extend later (e.g. multiple rod items each with their own `Config.CatchTime` or catch table)
  if you ever want to add that.

t. Leave `Config.Webhook = ''` to disable.
