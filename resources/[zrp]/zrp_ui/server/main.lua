local QBCore = exports['qb-core']:GetCoreObject()
local Config = exports['zrp_core']:GetConfig()

local function getVendorById(id)
    for _, vendor in ipairs(Config.Hub.Vendors or {}) do
        if vendor.id == id then return vendor end
    end
    return nil
end

local function nearVendor(src, vendor)
    local ped = GetPlayerPed(src)
    if ped <= 0 then return false end
    local coords = GetEntityCoords(ped)
    local v = vec3(vendor.coords.x, vendor.coords.y, vendor.coords.z)
    return #(coords - v) <= ((vendor.interactionDistance or 2.0) + 2.0)
end

lib.callback.register('zrp_ui:server:getMenuData', function(source)
    local party = exports['zrp_party']:GetPartyByPlayer(source)
    local profile = exports['zrp_core']:GetProfileBySource(source)
    local raid = exports['zrp_raids']:GetRaidByPlayer(source)
    local roster = exports['zrp_core']:GetCharacterRosterBySource(source) or {}

    local zoneOptions = {}
    for id, zone in pairs(Config.Zones) do
        zoneOptions[#zoneOptions + 1] = {
            id = id,
            label = zone.label,
            minLevel = zone.minLevel
        }
    end

    local contractOptions = {}
    for id, c in pairs(Config.Contracts) do
        contractOptions[#contractOptions + 1] = {
            id = id,
            label = c.label,
            type = c.type
        }
    end

    return {
        party = party,
        profile = profile,
        raid = raid,
        zones = zoneOptions,
        contracts = contractOptions,
        roster = roster,
        hub = Config.Hub
    }
end)

lib.callback.register('zrp_ui:server:getVendorStock', function(source, vendorId)
    local vendor = getVendorById(vendorId)
    if not vendor or not nearVendor(source, vendor) then return nil end
    return {
        id = vendor.id,
        label = vendor.label,
        buy = vendor.stock.buy or {},
        sell = vendor.stock.sell or {}
    }
end)

RegisterNetEvent('zrp_ui:server:vendorBuy', function(vendorId, itemName)
    local src = source
    local vendor = getVendorById(vendorId)
    if not vendor or not nearVendor(src, vendor) then return end

    local listing
    for _, entry in ipairs(vendor.stock.buy or {}) do
        if entry.item == itemName then listing = entry break end
    end
    if not listing then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local price = tonumber(listing.price) or 0
    local amount = tonumber(listing.amount) or 1
    if price <= 0 or amount <= 0 then return end

    if Player.Functions.RemoveMoney('cash', price, 'zrp-vendor-buy') then
        local ok = exports.ox_inventory:AddItem(src, listing.item, amount, { vendor = vendorId })
        if ok then
            TriggerClientEvent('zrp_core:client:notify', src, ('Purchased %sx %s'):format(amount, listing.item), 'success')
        else
            Player.Functions.AddMoney('cash', price, 'zrp-vendor-refund')
            TriggerClientEvent('zrp_core:client:notify', src, 'Inventory full.', 'error')
        end
    else
        TriggerClientEvent('zrp_core:client:notify', src, 'Not enough cash.', 'error')
    end
end)

RegisterNetEvent('zrp_ui:server:vendorSell', function(vendorId, itemName)
    local src = source
    local vendor = getVendorById(vendorId)
    if not vendor or not nearVendor(src, vendor) then return end

    local listing
    for _, entry in ipairs(vendor.stock.sell or {}) do
        if entry.item == itemName then listing = entry break end
    end
    if not listing then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local price = tonumber(listing.price) or 0
    local amount = tonumber(listing.amount) or 1
    if price <= 0 or amount <= 0 then return end

    local removed = exports.ox_inventory:RemoveItem(src, listing.item, amount)
    if removed then
        Player.Functions.AddMoney('cash', price, 'zrp-vendor-sell')
        TriggerClientEvent('zrp_core:client:notify', src, ('Sold %sx %s'):format(amount, listing.item), 'success')
    else
        TriggerClientEvent('zrp_core:client:notify', src, ('You need %sx %s'):format(amount, listing.item), 'error')
    end
end)
