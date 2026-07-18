local QBCore = exports['qb-core']:GetCoreObject()

local isFishing = false
local sellPed = nil

-- ============ HELPERS ============

local function notify(msg, type)
    lib.notify({ description = msg, type = type or 'inform' })
end

local function hasItem(item)
    return exports.ox_inventory:Search('count', item) > 0
end

-- tell the NUI once whether sound is enabled, so script.js doesn't need to poll config
CreateThread(function()
    SendNUIMessage({ action = 'init', sound = Config.Sound })
end)

-- ============ FISHING FLOW ============

local function playFishingAnim()
    local ped = PlayerPedId()
    local dict = 'amb@world_human_stand_fishing@idle_a'
    lib.requestAnimDict(dict, 3000)
    TaskPlayAnim(ped, dict, 'idle_c', 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function stopFishingAnim()
    ClearPedTasks(PlayerPedId())
end

local function canFishHere()
    local ped = PlayerPedId()

    if Config.BlockInVehicle and IsPedInAnyVehicle(ped, false) then
        notify('You can\'t fish from a vehicle.', 'error')
        return false
    end

    if Config.BlockWhileSwimming and IsPedSwimming(ped) then
        notify('You can\'t fish while swimming.', 'error')
        return false
    end

    return true
end

local function StartFishing()
    if isFishing then return end

    if not hasItem(Config.RodItem) then
        notify('You need a fishing rod to do that.', 'error')
        return
    end

    if not hasItem(Config.BaitItem) then
        notify('You need bait to fish.', 'error')
        return
    end

    if not canFishHere() then return end

    isFishing = true

    playFishingAnim()

    local duration = math.random(Config.CatchTime.min, Config.CatchTime.max)

    SendNUIMessage({
        action = 'startFishing',
        duration = duration
    })

    -- flash a "something's biting!" cue partway through the wait, purely visual/audio flavor
    CreateThread(function()
        Wait(duration * 1000 * 0.65)
        if isFishing then
            SendNUIMessage({ action = 'bite' })
        end
    end)

    Wait(duration * 1000)

    stopFishingAnim()

    SendNUIMessage({ action = 'stopFishing' })

    TriggerServerEvent('qb-fishing:server:catchFish')

    Wait(Config.CastCooldown * 1000)

    isFishing = false
end

-- ============ TARGET ZONES (fishing spots) ============

CreateThread(function()
    for i, zone in ipairs(Config.FishingZones) do
        exports.ox_target:addSphereZone({
            coords = zone.coords,
            radius = zone.radius,
            debug = Config.Debug,
            options = {
                {
                    name = 'fishing_zone_' .. i,
                    icon = 'fa-solid fa-fish',
                    label = 'Go Fishing',
                    distance = 2.5,
                    canInteract = function()
                        return not isFishing
                    end,
                    onSelect = function()
                        StartFishing()
                    end
                }
            }
        })
    end
end)

-- ============ SELL PED ============

CreateThread(function()
    local model = Config.SellPed.model
    lib.requestModel(model, 5000)

    sellPed = CreatePed(4, model, Config.SellPed.coords.x, Config.SellPed.coords.y, Config.SellPed.coords.z - 1.0, Config.SellPed.coords.w, false, true)
    FreezeEntityPosition(sellPed, true)
    SetEntityInvincible(sellPed, true)
    SetBlockingOfNonTemporaryEvents(sellPed, true)

    if Config.SellPed.scenario then
        TaskStartScenarioInPlace(sellPed, Config.SellPed.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(sellPed, {
        {
            name = 'sell_fish',
            icon = 'fa-solid fa-sack-dollar',
            label = 'Sell Fish',
            onSelect = function()
                TriggerServerEvent('qb-fishing:server:sellFish')
            end
        }
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and sellPed then
        DeleteEntity(sellPed)
    end
end)

-- ============ SERVER -> CLIENT NOTIFY / RESULT ============

RegisterNetEvent('qb-fishing:client:notify', function(msg, type)
    notify(msg, type)
end)

-- outcome: 'catch' | 'junk' | 'snapped' | 'escaped' | 'full'
RegisterNetEvent('qb-fishing:client:fishResult', function(outcome, label, weight)
    if outcome == 'catch' then
        SendNUIMessage({ action = 'result', outcome = 'catch' })
        notify(('You caught a %s (%.1fkg)!'):format(label, weight or 0), 'success')
    elseif outcome == 'junk' then
        SendNUIMessage({ action = 'result', outcome = 'junk' })
        notify(('You reeled in... %s. Worthless.'):format(label), 'inform')
    elseif outcome == 'snapped' then
        SendNUIMessage({ action = 'result', outcome = 'fail' })
        notify('The line snapped! It got away.', 'error')
    elseif outcome == 'escaped' then
        SendNUIMessage({ action = 'result', outcome = 'fail' })
        notify('The fish got away...', 'error')
    elseif outcome == 'full' then
        SendNUIMessage({ action = 'result', outcome = 'fail' })
        notify('Your inventory is too full to carry that.', 'error')
    end
end)
