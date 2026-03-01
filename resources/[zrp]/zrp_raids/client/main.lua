local currentRaid
local currentThreat = 0
local activeContainers = {}

local function getZoneContainers(zoneId)
    local zone = ZRPConfig.Zones[zoneId]
    return zone and zone.containers or {}
end

RegisterNetEvent('zrp_raids:client:raidStarted', function(raidId, zoneId, contractId)
    currentRaid = { id = raidId, zoneId = zoneId, contractId = contractId }
    currentThreat = 0
    activeContainers = getZoneContainers(zoneId)
    TriggerEvent('zrp_core:client:notify', ('Raid %s started in %s'):format(raidId, zoneId), 'success')
end)

RegisterNetEvent('zrp_raids:client:raidEnded', function()
    currentRaid = nil
    currentThreat = 0
    activeContainers = {}
    TriggerEvent('zrp_core:client:notify', 'Raid ended, returned to hub.', 'inform')
end)

RegisterNetEvent('zrp_raids:client:threatUpdate', function(raidId, value)
    if currentRaid and currentRaid.id == raidId then
        currentThreat = value
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if currentRaid then
            local ped = PlayerPedId()
            if IsPedSprinting(ped) then
                TriggerServerEvent('zrp_raids:server:addThreat', ZRPConfig.Threat.SprintTick)
            end
            if IsPedShooting(ped) then
                TriggerServerEvent('zrp_raids:server:addThreat', ZRPConfig.Threat.Gunshot)
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if currentRaid then
            SetTextFont(0)
            SetTextScale(0.33, 0.33)
            SetTextColour(255, 80, 80, 220)
            SetTextEntry('STRING')
            AddTextComponentString(('THREAT: %d'):format(currentThreat))
            DrawText(0.89, 0.07)

            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)
            local near = false

            for _, container in ipairs(activeContainers) do
                local dist = #(pCoords - container.coords)
                if dist < 18.0 then
                    DrawMarker(2, container.coords.x, container.coords.y, container.coords.z + 0.2, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.35, 0.35, 0.35, 255, 165, 0, 200, false, false, 2, false, nil, nil, false)
                end

                if dist < 1.8 then
                    near = true
                    lib.showTextUI('[E] Search Container')
                    if IsControlJustPressed(0, 38) then
                        local success, rewards = lib.callback.await('zrp_raids:server:lootContainer', false, container.id)
                        if success then
                            if #rewards == 0 then
                                TriggerEvent('zrp_core:client:notify', 'Container empty.', 'inform')
                            else
                                local lines = {}
                                for _, reward in ipairs(rewards) do
                                    lines[#lines + 1] = ('%sx %s'):format(reward.amount, reward.item)
                                end
                                TriggerEvent('zrp_core:client:notify', 'Loot sent to raid stash: ' .. table.concat(lines, ', '), 'success')
                            end
                        else
                            TriggerEvent('zrp_core:client:notify', rewards or 'Unable to loot.', 'error')
                        end
                    end
                end
            end

            if not near then
                lib.hideTextUI()
            end
        else
            Wait(500)
        end
    end
end)

AddEventHandler('baseevents:onPlayerDied', function()
    if currentRaid then TriggerServerEvent('zrp_raids:server:markDeadOrLost') end
end)

AddEventHandler('baseevents:onPlayerKilled', function()
    if currentRaid then TriggerServerEvent('zrp_raids:server:markDeadOrLost') end
end)

exports('GetCurrentRaid', function()
    return currentRaid
end)
