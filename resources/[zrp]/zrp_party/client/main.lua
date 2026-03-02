local currentParty

RegisterNetEvent('zrp_party:client:updateParty', function(party)
    currentParty = party
end)

RegisterNetEvent('zrp_party:client:receiveInvite', function(fromSrc)
    local alert = lib.alertDialog({
        header = 'Party Invite',
        content = ('Player %s invited you to a party.'):format(fromSrc),
        centered = true,
        cancel = true
    })
    TriggerServerEvent('zrp_party:server:respondInvite', alert == 'confirm')
end)

RegisterNetEvent('zrp_party:client:readyCheckPrompt', function(timeoutSeconds)
    local result = lib.alertDialog({
        header = 'Raid Ready Check',
        content = ('Accept raid start? You have %s seconds.'):format(timeoutSeconds),
        centered = true,
        cancel = true
    })
    TriggerServerEvent('zrp_party:server:readyCheckResponse', result == 'confirm')
end)

exports('GetCurrentParty', function()
    return currentParty
end)
