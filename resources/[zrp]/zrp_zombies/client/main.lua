local zombiesByRaid = {}

local function loadModel(model)
    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(0)
    end
    return hash
end

RegisterNetEvent('zrp_zombies:client:spawnZombie', function(raidId, special)
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local offset = vec3(math.random(-35, 35) + 0.0, math.random(-35, 35) + 0.0, 0.0)
    local spawn = pCoords + offset

    local model = ZRPConfig.Zombies.Models[math.random(1, #ZRPConfig.Zombies.Models)]
    local hash = loadModel(model)
    local zombie = CreatePed(4, hash, spawn.x, spawn.y, spawn.z, 0.0, true, true)

    SetPedAsEnemy(zombie, true)
    SetEntityHealth(zombie, special and math.floor(200 * ZRPConfig.Zombies.Special.hpMultiplier) or 200)
    SetPedAccuracy(zombie, 10)
    SetPedFleeAttributes(zombie, 0, false)
    SetPedDropsWeaponsWhenDead(zombie, false)
    SetPedCanRagdollFromPlayerImpact(zombie, false)
    SetPedRelationshipGroupHash(zombie, `HATES_PLAYER`)
    SetPedCombatAttributes(zombie, 46, true)
    SetPedCombatRange(zombie, 2)
    SetPedAlertness(zombie, 3)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)

    if special then
        SetPedMoveRateOverride(zombie, ZRPConfig.Zombies.Special.speedMultiplier)
        SetEntityMaxHealth(zombie, math.floor(200 * ZRPConfig.Zombies.Special.hpMultiplier))
    end

    zombiesByRaid[raidId] = zombiesByRaid[raidId] or {}
    zombiesByRaid[raidId][zombie] = { special = special }
end)

CreateThread(function()
    while true do
        Wait(350)
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)

        for raidId, zombies in pairs(zombiesByRaid) do
            for zombie, data in pairs(zombies) do
                if not DoesEntityExist(zombie) or IsEntityDead(zombie) then
                    if DoesEntityExist(zombie) then DeleteEntity(zombie) end
                    zombies[zombie] = nil
                    TriggerServerEvent('zrp_zombies:server:onZombieKilled', raidId, data.special)
                else
                    local zCoords = GetEntityCoords(zombie)
                    local dist = #(myCoords - zCoords)
                    if dist <= ZRPConfig.Zombies.EngageDistance then
                        TaskCombatPed(zombie, myPed, 0, 16)
                    end
                    if dist > ZRPConfig.Zombies.DespawnDistance then
                        DeleteEntity(zombie)
                        zombies[zombie] = nil
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('zrp_zombies:client:cleanupRaid', function(raidId)
    local zombies = zombiesByRaid[raidId]
    if not zombies then return end

    for zombie in pairs(zombies) do
        if DoesEntityExist(zombie) then
            DeleteEntity(zombie)
        end
    end

    zombiesByRaid[raidId] = nil
end)
