local points = {}
local inRaid = false

RegisterNetEvent('zrp_raids:client:raidStarted', function()
    inRaid = true
    points = lib.callback.await('zrp_extract:server:getPoints', false) or {}
end)

RegisterNetEvent('zrp_raids:client:raidEnded', function()
    inRaid = false
    points = {}
end)

CreateThread(function()
    while true do
        Wait(0)
        if inRaid and #points > 0 then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local near = false

            for _, point in ipairs(points) do
                local dist = #(coords - vec3(point.x, point.y, point.z))
                if dist < 30.0 then
                    DrawMarker(1, point.x, point.y, point.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.2, 2.2, 1.2, 50, 180, 255, 130, false, false, 2, false, nil, nil, false)
                end
                if dist < 2.2 then
                    near = true
                    lib.showTextUI(('Hold [E] to extract (%ss)'):format(ZRPConfig.Extraction.HoldSeconds))
                    if IsControlJustPressed(0, 38) then
                        local ok = lib.progressCircle({
                            duration = ZRPConfig.Extraction.HoldSeconds * 1000,
                            label = 'Extracting...',
                            canCancel = true,
                            disable = { move = true, combat = true }
                        })
                        lib.hideTextUI()
                        if ok then
                            TriggerServerEvent('zrp_extract:server:attemptExtract')
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
