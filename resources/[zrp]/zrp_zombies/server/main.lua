local Config = exports['zrp_core']:GetConfig()

local activeRaids = {}

local function getSpawnCount(raidId)
    local members = exports['zrp_raids']:GetRaidMembers(raidId)
    local threat = exports['zrp_raids']:GetRaidThreat(raidId)
    local partyScale = Config.Threat.PartyScale[#members] or 1.0
    local count = math.floor((Config.Zombies.BaseSpawnPerTick + (threat / 25)) * partyScale)
    return math.max(1, count)
end

exports('StartRaidLoop', function(raidId)
    if activeRaids[raidId] then return end
    activeRaids[raidId] = { spawned = 0 }

    CreateThread(function()
        while activeRaids[raidId] do
            Wait(Config.Zombies.SpawnTickMs)
            local members = exports['zrp_raids']:GetRaidMembers(raidId)
            if #members == 0 then
                activeRaids[raidId] = nil
                return
            end

            local raidCap = math.min(Config.Zombies.MaxPerRaid, #members * Config.Zombies.MaxPerPlayer)
            local spawnCount = getSpawnCount(raidId)
            local remaining = raidCap - activeRaids[raidId].spawned
            if remaining <= 0 then goto continue end

            spawnCount = math.min(spawnCount, remaining)
            local zoneId = exports['zrp_raids']:GetRaidZone(raidId)
            local zoneTier = (Config.Zones[zoneId] and Config.Zones[zoneId].lootTier) or 1
            local specialChance = Config.Zombies.Special.chanceByTier[zoneTier] or 0.05

            for _ = 1, spawnCount do
                local target = members[math.random(1, #members)]
                local special = (math.random() <= specialChance)
                TriggerClientEvent('zrp_zombies:client:spawnZombie', target, raidId, special)
                activeRaids[raidId].spawned = activeRaids[raidId].spawned + 1
            end

            ::continue::
        end
    end)
end)

exports('EndRaidLoop', function(raidId)
    activeRaids[raidId] = nil
    TriggerClientEvent('zrp_zombies:client:cleanupRaid', -1, raidId)
end)

RegisterNetEvent('zrp_zombies:server:onZombieKilled', function(raidId, special)
    local src = source
    if not exports['zrp_raids']:IsPlayerInRaid(src) then return end

    if activeRaids[raidId] then
        activeRaids[raidId].spawned = math.max(0, activeRaids[raidId].spawned - 1)
    end

    TriggerEvent('zrp_contracts:server:addProgress', raidId, special and 'kill_special' or 'kill', 1)
end)
