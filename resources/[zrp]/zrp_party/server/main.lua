local Config = exports['zrp_core']:GetConfig()

local parties = {}
local playerParty = {}
local invites = {}
local readyChecks = {}

local function sendPartyState(partyId)
    local party = parties[partyId]
    if not party then return end
    for _, src in ipairs(party.members) do
        TriggerClientEvent('zrp_party:client:updateParty', src, party)
    end
end

local function removeFromParty(src)
    local partyId = playerParty[src]
    if not partyId then return end
    local party = parties[partyId]
    if not party then
        playerParty[src] = nil
        return
    end

    for i = #party.members, 1, -1 do
        if party.members[i] == src then table.remove(party.members, i) end
    end

    party.ready[src] = nil
    playerParty[src] = nil
    TriggerClientEvent('zrp_party:client:updateParty', src, nil)

    if #party.members == 0 then
        parties[partyId] = nil
        return
    end

    if party.leader == src then
        party.leader = party.members[1]
    end

    sendPartyState(partyId)
end

local function partyCreate(source)
    if source == 0 then return end
    if exports['zrp_raids']:IsPlayerInRaid(source) then
        TriggerClientEvent('zrp_core:client:notify', source, 'Cannot create party while in raid.', 'error')
        return
    end
    if playerParty[source] then
        TriggerClientEvent('zrp_core:client:notify', source, 'You are already in a party.', 'error')
        return
    end

    local partyId = ('p_%s_%s'):format(source, os.time())
    parties[partyId] = { id = partyId, leader = source, members = { source }, ready = {} }
    playerParty[source] = partyId
    sendPartyState(partyId)
    TriggerClientEvent('zrp_core:client:notify', source, 'Party created.', 'success')
end

local function partyInvite(source, target)
    if source == 0 or not target then return end

    local partyId = playerParty[source]
    local party = partyId and parties[partyId]
    if not party or party.leader ~= source then
        TriggerClientEvent('zrp_core:client:notify', source, 'Only leader can invite.', 'error')
        return
    end
    if #party.members >= Config.MaxPartySize then
        TriggerClientEvent('zrp_core:client:notify', source, 'Party is full.', 'error')
        return
    end
    if playerParty[target] or exports['zrp_raids']:IsPlayerInRaid(target) then
        TriggerClientEvent('zrp_core:client:notify', source, 'Target already in party/raid.', 'error')
        return
    end

    invites[target] = { from = source, partyId = partyId, expires = os.time() + 30 }
    TriggerClientEvent('zrp_party:client:receiveInvite', target, source)
end

local function partyLeave(source)
    if source == 0 then return end
    removeFromParty(source)
end

local function partyKick(source, target)
    if source == 0 or not target then return end

    local party = exports['zrp_party']:GetPartyByPlayer(source)
    if not party or party.leader ~= source then return end
    if playerParty[target] ~= party.id then return end

    removeFromParty(target)
    TriggerClientEvent('zrp_core:client:notify', target, 'You were kicked from party.', 'error')
    sendPartyState(party.id)
end

RegisterCommand('party_create', function(source)
    partyCreate(source)
end)

RegisterCommand('party_invite', function(source, args)
    partyInvite(source, tonumber(args[1] or ''))
end)

RegisterCommand('party_leave', function(source)
    partyLeave(source)
end)

RegisterCommand('party_kick', function(source, args)
    partyKick(source, tonumber(args[1] or ''))
end)

RegisterNetEvent('zrp_party:server:create', function()
    partyCreate(source)
end)

RegisterNetEvent('zrp_party:server:invite', function(target)
    partyInvite(source, tonumber(target))
end)

RegisterNetEvent('zrp_party:server:leave', function()
    partyLeave(source)
end)

RegisterNetEvent('zrp_party:server:kick', function(target)
    partyKick(source, tonumber(target))
end)

RegisterNetEvent('zrp_party:server:respondInvite', function(accepted)
    local src = source
    local invite = invites[src]
    if not invite or invite.expires < os.time() then invites[src] = nil return end
    invites[src] = nil
    if not accepted then return end

    local party = parties[invite.partyId]
    if not party or #party.members >= Config.MaxPartySize then return end
    if playerParty[src] or exports['zrp_raids']:IsPlayerInRaid(src) then return end

    table.insert(party.members, src)
    playerParty[src] = party.id
    sendPartyState(party.id)
end)

RegisterNetEvent('zrp_party:server:readyCheckResponse', function(accepted)
    local src = source
    local partyId = playerParty[src]
    if not partyId then return end
    local active = readyChecks[partyId]
    if not active then return end
    active.responses[src] = accepted == true
end)

exports('RunReadyCheck', function(leaderSrc)
    local party = exports['zrp_party']:GetPartyByPlayer(leaderSrc)
    if not party or party.leader ~= leaderSrc then return false, 'Not party leader.' end

    local partyId = party.id
    readyChecks[partyId] = { responses = {} }
    for _, member in ipairs(party.members) do
        TriggerClientEvent('zrp_party:client:readyCheckPrompt', member, Config.ReadyCheckTimeout)
    end

    local endAt = GetGameTimer() + (Config.ReadyCheckTimeout * 1000)
    while GetGameTimer() < endAt do
        Wait(250)
        local all = true
        for _, member in ipairs(party.members) do
            if readyChecks[partyId].responses[member] ~= true then
                all = false
                break
            end
        end
        if all then
            readyChecks[partyId] = nil
            return true
        end
    end

    readyChecks[partyId] = nil
    return false, 'Ready-check failed or timed out.'
end)

AddEventHandler('playerDropped', function()
    local src = source
    invites[src] = nil
    removeFromParty(src)
end)

exports('GetPartyByPlayer', function(src)
    local id = playerParty[src]
    return id and parties[id] or nil
end)

exports('GetPartyMembers', function(src)
    local party = exports['zrp_party']:GetPartyByPlayer(src)
    return party and party.members or { src }
end)

lib.callback.register('zrp_party:server:getParty', function(source)
    return exports['zrp_party']:GetPartyByPlayer(source)
end)
