local Config = exports['zrp_core']:GetConfig()

local extractionState = {}

exports('InitRaidExtraction', function(raidId, zoneId)
    extractionState[raidId] = { zoneId = zoneId }
end)

exports('CleanupRaidExtraction', function(raidId)
    extractionState[raidId] = nil
end)

lib.callback.register('zrp_extract:server:getPoints', function(source)
    local raid = exports['zrp_raids']:GetRaidByPlayer(source)
    if not raid then return nil end
    local zone = Config.Zones[raid.zoneId]
    return zone and zone.extractionPoints or nil
end)

RegisterNetEvent('zrp_extract:server:attemptExtract', function()
    local src = source
    local raid = exports['zrp_raids']:GetRaidByPlayer(src)
    if not raid then return end

    if not exports['zrp_contracts']:CanExtractRaid(raid.id) then
        TriggerClientEvent('zrp_core:client:notify', src, 'Extraction locked: complete contract objective.', 'error')
        return
    end

    exports['zrp_raids']:AddThreatByRaid(raid.id, math.floor(10 * Config.Extraction.HordeMultiplier))
    exports['zrp_raids']:PlayerExtracted(src)
end)
