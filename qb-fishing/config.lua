Config = {}

Config.Debug = false -- shows zone markers in-game for placement testing

-- Items required from ox_inventory (add these to ox_inventory/data/items.lua, see README)
Config.RodItem = 'fishing_rod'   -- not consumed, just needs to be owned
Config.BaitItem = 'bait'         -- consumed 1 per cast

-- How long the "reeling" progress bar takes (seconds), randomized between the two
Config.CatchTime = { min = 6, max = 12 }

-- Cooldown after a cast before you can fish again
Config.CastCooldown = 3 -- seconds

-- Minimum seconds that must pass between server-side catch/sell events per player.
-- This is a hard anti-spam floor, independent of CastCooldown - protects against
-- a modified client firing the events directly.
Config.ServerCooldowns = {
    catch = 4,
    sell = 2,
}

-- Block fishing while in a vehicle or swimming
Config.BlockInVehicle = true
Config.BlockWhileSwimming = true

-- Chance (%) that the line just snaps / fish escapes right at the end of a full bar,
-- even before the catch-table roll happens. Makes waiting out the bar not a 100%
-- guaranteed catch. Set to 0 to disable.
Config.BiteFailChance = 12

-- Enable simple synthesized UI sound cues (bite cue, catch cue, fail cue).
-- No sound files needed - generated in the browser via the Web Audio API.
Config.Sound = true

-- Notify the player once their sellable fish count on-hand crosses this number,
-- as a friendly nudge to go sell rather than a hard inventory-full failure.
Config.MaxFishWarning = 15

-- Discord webhook URL for logging rare catches. Leave blank ('') to disable.
Config.Webhook = ''
Config.WebhookName = 'Fishing Log'

-- Fishing spots. Add as many as you want. radius is in meters.
-- These are just example coastal/lake coords near Los Santos - move them to wherever you want.
Config.FishingZones = {
    { coords = vec3(-1626.86, 5346.7, 3.2),  radius = 20.0 }, -- Paleto Bay pier
    { coords = vec3(-1820.0, -1218.0, 13.0), radius = 20.0 }, -- Vespucci canals
    { coords = vec3(3868.0, 4507.0, 3.5),    radius = 20.0 }, -- Grapeseed lake
}

-- Ped who buys your fish
Config.SellPed = {
    model = `a_m_m_hillbilly_01`,
    coords = vec4(-1618.6, 5347.9, 2.2, 250.0),
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
}

-- Fish table. "chance" values must add up to 100.
-- item      = ox_inventory item name
-- label     = display name
-- price     = sell value each
-- weightRange = {min, max} kg, randomized per catch and stamped into item metadata
-- isRare    = if true and Config.Webhook is set, posts a webhook log on catch
Config.Fish = {
    { item = 'fish_shark',  label = 'Shark',    chance = 5,  price = 250, weightRange = {20, 90},  isRare = true },
    { item = 'fish_tuna',   label = 'Tuna',     chance = 15, price = 120, weightRange = {5, 25} },
    { item = 'fish_salmon', label = 'Salmon',   chance = 25, price = 60,  weightRange = {1.5, 6} },
    { item = 'fish_trout',  label = 'Trout',    chance = 30, price = 35,  weightRange = {0.5, 2.5} },
    { item = 'fish_boot',   label = 'Old Boot', chance = 25, price = 0,   weightRange = {0.5, 1} }, -- junk, worthless
}
