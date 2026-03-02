local tracker = { progress = 0, required = 0, complete = false }

RegisterNetEvent('zrp_contracts:client:updateProgress', function(progress, required, complete)
    tracker.progress = progress
    tracker.required = required
    tracker.complete = complete
end)

CreateThread(function()
    while true do
        Wait(0)
        local raid = exports['zrp_raids']:GetCurrentRaid()
        if raid and tracker.required > 0 then
            local msg = ('Contract: %d/%d %s'):format(tracker.progress, tracker.required, tracker.complete and '(Complete)' or '')
            SetTextFont(0)
            SetTextScale(0.33, 0.33)
            SetTextColour(130, 200, 255, 220)
            SetTextEntry('STRING')
            AddTextComponentString(msg)
            DrawText(0.84, 0.1)
        else
            Wait(500)
        end
    end
end)
