local QBCore = exports['qb-core']:GetCoreObject()

local function getCitizenId(src)
    local Player = QBCore.Functions.GetPlayer(src)
    return Player and Player.PlayerData.citizenid or nil
end

local function stashId(raidId, src)
    local citizenid = getCitizenId(src)
    if not citizenid then return nil end
    return ('raid:%s:%s'):format(raidId, citizenid)
end

exports('CreateRaidStash', function(raidId, src)
    local id = stashId(raidId, src)
    if not id then return nil end
    exports.ox_inventory:RegisterStash(id, ('Raid Loot %s'):format(raidId), 60, 180000, false)
    return id
end)

exports('AddFoundInRaidItem', function(raidId, src, item, amount, metadata)
    local id = stashId(raidId, src)
    if not id then return false end
    local added = exports.ox_inventory:AddItem(id, item, amount, metadata or {})
    return added and true or false
end)

exports('TransferRaidStashToPlayer', function(raidId, src)
    local id = stashId(raidId, src)
    if not id then return false end

    local inv = exports.ox_inventory:GetInventory(id)
    if not inv or not inv.items then return true end

    for _, item in pairs(inv.items) do
        if item and item.name and item.count and item.count > 0 then
            local moved = exports.ox_inventory:AddItem(src, item.name, item.count, item.metadata or {})
            if moved then
                exports.ox_inventory:RemoveItem(id, item.name, item.count, item.metadata, item.slot)
            end
        end
    end

    return true
end)

exports('ClearRaidStash', function(raidId, src)
    local id = stashId(raidId, src)
    if not id then return false end

    local inv = exports.ox_inventory:GetInventory(id)
    if inv and inv.items then
        for _, item in pairs(inv.items) do
            if item and item.name and item.count and item.count > 0 then
                exports.ox_inventory:RemoveItem(id, item.name, item.count, item.metadata, item.slot)
            end
        end
    end

    return true
end)

lib.callback.register('zrp_inventory:server:openRaidStash', function(source)
    local raid = exports['zrp_raids']:GetRaidByPlayer(source)
    if not raid then return false end
    local id = stashId(raid.id, source)
    if not id then return false end
    TriggerClientEvent('ox_inventory:openInventory', source, 'stash', id)
    return true
end)
