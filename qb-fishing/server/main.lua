local QBCore = exports['qb-core']:GetCoreObject()

-- src -> os.time() of last allowed action, used as a hard anti-spam floor
local lastAction = {}

local function onCooldown(src, key, seconds)
    local now = os.time()
    local last = lastAction[src] and lastAction[src][key]

    if last and (now - last) < seconds then
        return true
    end

    lastAction[src] = lastAction[src] or {}
    lastAction[src][key] = now
    return false
end

AddEventHandler('playerDropped', function()
    lastAction[source] = nil
end)

-- ============ WEBHOOK LOGGING ============

local function logRareCatch(name, fish, weight)
    if Config.Webhook == '' then return end

    PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
        username = Config.WebhookName,
        embeds = {
            {
                title = 'Rare catch!',
                description = ('**%s** just caught a **%s** (%.1fkg)'):format(name, fish.label, weight),
                color = 65280
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end

-- ============ CATCH FISH ============

RegisterNetEvent('qb-fishing:server:catchFish', function()
    local src = source

    if onCooldown(src, 'catch', Config.ServerCooldowns.catch) then
        return -- silently drop, this only fires naturally from a slower client-side flow anyway
    end

    local ped = GetPlayerPed(src)

    if Config.BlockInVehicle and IsPedInAnyVehicle(ped, false) then
        TriggerClientEvent('qb-fishing:client:notify', src, 'You can\'t fish from a vehicle.', 'error')
        return
    end

    if Config.BlockWhileSwimming and IsPedSwimming(ped) then
        TriggerClientEvent('qb-fishing:client:notify', src, 'You can\'t fish while swimming.', 'error')
        return
    end

    local hasRod = exports.ox_inventory:Search(src, 'count', Config.RodItem) > 0
    local hasBait = exports.ox_inventory:Search(src, 'count', Config.BaitItem) > 0

    if not hasRod or not hasBait then
        return
    end

    local removed = exports.ox_inventory:RemoveItem(src, Config.BaitItem, 1)
    if not removed then
        TriggerClientEvent('qb-fishing:client:notify', src, 'Something went wrong with your bait.', 'error')
        return
    end

    -- line-snap roll happens before the catch table roll
    if Config.BiteFailChance > 0 and math.random(1, 100) <= Config.BiteFailChance then
        TriggerClientEvent('qb-fishing:client:fishResult', src, 'snapped')
        return
    end

    local roll = math.random(1, 100)
    local cumulative = 0
    local caught = nil

    for _, fish in ipairs(Config.Fish) do
        cumulative = cumulative + fish.chance
        if roll <= cumulative then
            caught = fish
            break
        end
    end

    if not caught then
        TriggerClientEvent('qb-fishing:client:fishResult', src, 'escaped')
        return
    end

    local weight = caught.weightRange and (math.random(caught.weightRange[1] * 10, caught.weightRange[2] * 10) / 10) or nil
    local metadata = weight and {
        weight = weight,
        label = ('%s (%.1fkg)'):format(caught.label, weight)
    } or nil

    local added = exports.ox_inventory:AddItem(src, caught.item, 1, metadata)

    if not added then
        TriggerClientEvent('qb-fishing:client:fishResult', src, 'full')
        return
    end

    if caught.price > 0 then
        TriggerClientEvent('qb-fishing:client:fishResult', src, 'catch', caught.label, weight)

        if caught.isRare then
            local Player = QBCore.Functions.GetPlayer(src)
            local name = Player and (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname) or ('Player ' .. src)
            logRareCatch(name, caught, weight)
        end

        -- friendly nudge if they're stacking up a lot of fish
        local totalFish = 0
        for _, f in ipairs(Config.Fish) do
            if f.price > 0 then
                totalFish = totalFish + exports.ox_inventory:GetItemCount(src, f.item)
            end
        end

        if totalFish >= Config.MaxFishWarning then
            TriggerClientEvent('qb-fishing:client:notify', src, 'Your bag is getting heavy with fish - might be worth selling some.', 'inform')
        end
    else
        TriggerClientEvent('qb-fishing:client:fishResult', src, 'junk', caught.label)
    end
end)

-- ============ SELL FISH ============

RegisterNetEvent('qb-fishing:server:sellFish', function()
    local src = source

    if onCooldown(src, 'sell', Config.ServerCooldowns.sell) then
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local total = 0
    local soldAny = false

    for _, fish in ipairs(Config.Fish) do
        local count = exports.ox_inventory:GetItemCount(src, fish.item)
        if count > 0 and fish.price > 0 then
            exports.ox_inventory:RemoveItem(src, fish.item, count)
            total = total + (count * fish.price)
            soldAny = true
        end
    end

    if soldAny and total > 0 then
        Player.Functions.AddMoney('cash', total, 'fish-sold')
        TriggerClientEvent('qb-fishing:client:notify', src, ('Sold your fish for $%d'):format(total), 'success')
    else
        TriggerClientEvent('qb-fishing:client:notify', src, 'You have no sellable fish on you.', 'error')
    end
end)
