local Config = exports['zrp_core']:GetConfig()

local raids = {}
local playerRaid = {}
local raidCounter = 1000

local function randomInsertion(zone)
    return zone.insertions[math.random(1, #zone.insertions)]
end

local function getPlayerLevel(src)
    local profile = exports['zrp_core']:GetProfileBySource(src)
    return profile and profile.level or 1
end

local function setRaidThreat(raidId, value)
    local raid = raids[raidId]
    if not raid then return end
    raid.threat = math.min(Config.Threat.Max, math.max(0, math.floor(value)))
    for _, member in ipairs(raid.members) do
        TriggerClientEvent('zrp_raids:client:threatUpdate', member, raidId, raid.threat)
    end
end

local function addThreatBySource(src, amount)
    local raidId = playerRaid[src]
    if not raidId then return end
    local raid = raids[raidId]
    if not raid then return end
    setRaidThreat(raidId, raid.threat + amount)
end

local function finalizeRaidIfDone(raidId)
    local raid = raids[raidId]
    if not raid then return end

    for _, src in ipairs(raid.members) do
        if not raid.extracted[src] and not raid.deadOrLost[src] then
            return
        end
    end

    exports['zrp_zombies']:EndRaidLoop(raidId)
    exports['zrp_contracts']:CleanupRaidContract(raidId)
    exports['zrp_extract']:CleanupRaidExtraction(raidId)
    raids[raidId] = nil
end

local function markDeadOrLost(actor)
    local raidId = playerRaid[actor]
    if not raidId then return end
    local raid = raids[raidId]
    if not raid then return end

    raid.deadOrLost[actor] = true
    exports['zrp_inventory']:ClearRaidStash(raidId, actor)
    SetPlayerRoutingBucket(actor, 0)
    playerRaid[actor] = nil
    TriggerClientEvent('zrp_raids:client:raidEnded', actor)
    finalizeRaidIfDone(raidId)
end

local function playerExtracted(src)
    local raidId = playerRaid[src]
    if not raidId then return false end
    local raid = raids[raidId]
    if not raid then return false end

    raid.extracted[src] = os.time()
    exports['zrp_inventory']:TransferRaidStashToPlayer(raidId, src)
    exports['zrp_inventory']:ClearRaidStash(raidId, src)

    if exports['zrp_contracts']:IsRaidContractComplete(raidId) then
        exports['zrp_contracts']:RewardPlayerForRaid(raidId, src)
    end

    local earliest, latest = nil, nil
    local allExtracted = true
    for _, member in ipairs(raid.members) do
        if not raid.extracted[member] then
            allExtracted = false
            break
        end
        earliest = earliest and math.min(earliest, raid.extracted[member]) or raid.extracted[member]
        latest = latest and math.max(latest, raid.extracted[member]) or raid.extracted[member]
    end

    if allExtracted and earliest and latest and (latest - earliest) <= Config.Extraction.AllExtractWindowBonusSeconds then
        for _, member in ipairs(raid.members) do
            exports['zrp_core']:AddProgression(member, 0, Config.Extraction.PartyBonusRep)
        end
    end

    SetPlayerRoutingBucket(src, 0)
    playerRaid[src] = nil
    TriggerClientEvent('zrp_raids:client:raidEnded', src)
    finalizeRaidIfDone(raidId)
    return true
end

local function startRaidForMembers(leaderSrc, members, zoneId, contractId)
    raidCounter = raidCounter + 1
    local raidId = raidCounter

    local zone = Config.Zones[zoneId]
    local insertion = randomInsertion(zone)

    raids[raidId] = {
        id = raidId,
        leader = leaderSrc,
        members = members,
        zoneId = zoneId,
        contractId = contractId,
        startedAt = os.time(),
        threat = 0,
        extracted = {},
        deadOrLost = {},
        containerCooldowns = {}
    }

    exports['zrp_contracts']:InitRaidContract(raidId, contractId, members)
    exports['zrp_extract']:InitRaidExtraction(raidId, zoneId)

    for _, src in ipairs(members) do
        SetPlayerRoutingBucket(src, raidId)
        local ped = GetPlayerPed(src)
        SetEntityCoords(ped, insertion.x, insertion.y, insertion.z, false, false, false, false)
        SetEntityHeading(ped, insertion.w)
        playerRaid[src] = raidId
        exports['zrp_inventory']:CreateRaidStash(raidId, src)
        TriggerClientEvent('zrp_raids:client:raidStarted', src, raidId, zoneId, contractId)
    end

    exports['zrp_zombies']:StartRaidLoop(raidId)
end

local function canStartRaid(members, zoneId, contractId)
    local zone = Config.Zones[zoneId]
    if not zone then return false, 'Invalid zone.' end
    if not Config.Contracts[contractId] then return false, 'Invalid contract.' end

    for _, member in ipairs(members) do
        if playerRaid[member] then
            return false, ('Player %s already in raid.'):format(member)
        end
        if getPlayerLevel(member) < zone.minLevel then
            return false, ('Player %s does not meet zone level requirement.'):format(member)
        end
    end
    return true
end

local function startSoloRaid(source, zoneId, contractId)
    if source == 0 then return end

    if exports['zrp_party']:GetPartyByPlayer(source) then
        TriggerClientEvent('zrp_core:client:notify', source, 'Leave your party to run solo.', 'error')
        return
    end

    local ok, reason = canStartRaid({ source }, zoneId, contractId)
    if not ok then
        TriggerClientEvent('zrp_core:client:notify', source, reason, 'error')
        return
    end

    startRaidForMembers(source, { source }, zoneId, contractId)
end

local function startPartyRaid(source, zoneId, contractId)
    if source == 0 then return end

    local party = exports['zrp_party']:GetPartyByPlayer(source)
    if not party or party.leader ~= source then
        TriggerClientEvent('zrp_core:client:notify', source, 'Only party leader can start.', 'error')
        return
    end

    local readyOk, readyReason = exports['zrp_party']:RunReadyCheck(source)
    if not readyOk then
        TriggerClientEvent('zrp_core:client:notify', source, readyReason or 'Ready-check failed.', 'error')
        return
    end

    local ok, reason = canStartRaid(party.members, zoneId, contractId)
    if not ok then
        TriggerClientEvent('zrp_core:client:notify', source, reason, 'error')
        return
    end

    startRaidForMembers(source, party.members, zoneId, contractId)
end

RegisterCommand('raid_solo', function(source, args)
    startSoloRaid(source, args[1], args[2])
end)

RegisterCommand('raid_party', function(source, args)
    startPartyRaid(source, args[1], args[2])
end)

RegisterNetEvent('zrp_raids:server:startSolo', function(zoneId, contractId)
    startSoloRaid(source, zoneId, contractId)
end)

RegisterNetEvent('zrp_raids:server:startParty', function(zoneId, contractId)
    startPartyRaid(source, zoneId, contractId)
end)

RegisterNetEvent('zrp_raids:server:addThreat', function(amount)
    addThreatBySource(source, tonumber(amount) or 0)
end)

RegisterNetEvent('zrp_raids:server:markDeadOrLost', function(targetSrc)
    markDeadOrLost(targetSrc or source)
end)

RegisterNetEvent('zrp_raids:server:playerExtracted', function()
    playerExtracted(source)
end)

CreateThread(function()
    while true do
        Wait(Config.Threat.TickSeconds * 1000)
        for raidId, raid in pairs(raids) do
            setRaidThreat(raidId, raid.threat - Config.Threat.DecayPerTick)
        end
    end
end)

AddEventHandler('playerDropped', function()
    markDeadOrLost(source)
end)

exports('GetRaidByPlayer', function(src)
    local raidId = playerRaid[src]
    if not raidId then return nil end
    return raids[raidId]
end)

exports('IsPlayerInRaid', function(src)
    return playerRaid[src] ~= nil
end)

exports('GetRaidThreat', function(raidId)
    return raids[raidId] and raids[raidId].threat or 0
end)

exports('GetRaidMembers', function(raidId)
    return raids[raidId] and raids[raidId].members or {}
end)

exports('GetRaidZone', function(raidId)
    return raids[raidId] and raids[raidId].zoneId or nil
end)

exports('AddThreatByRaid', function(raidId, amount)
    local raid = raids[raidId]
    if raid then
        setRaidThreat(raidId, raid.threat + amount)
    end
end)

exports('PlayerExtracted', function(src)
    return playerExtracted(src)
end)

lib.callback.register('zrp_raids:server:getSelfRaid', function(source)
    return exports['zrp_raids']:GetRaidByPlayer(source)
end)

lib.callback.register('zrp_raids:server:lootContainer', function(source, containerId)
    local raid = exports['zrp_raids']:GetRaidByPlayer(source)
    if not raid then return false, 'Not in raid.' end

    local now = os.time()
    local cd = raid.containerCooldowns[containerId]
    if cd and cd > now then
        return false, 'Container already looted.'
    end

    local zone = Config.Zones[raid.zoneId]
    local container
    for _, c in ipairs(zone.containers) do
        if c.id == containerId then container = c break end
    end
    if not container then return false, 'Invalid container.' end

    raid.containerCooldowns[containerId] = now + 300
    local entries = Config.LootTables[container.tier] or {}
    local rewards = {}

    local scavengerBonus = exports['zrp_core']:GetSkillBonus(source, 'survival', 'scavenger')
    for _, entry in ipairs(entries) do
        local rollChance = math.min(0.95, entry.chance + scavengerBonus)
        if math.random() <= rollChance then
            local amount = math.random(entry.min, entry.max)
            local metadata = exports['zrp_core']:GetLootMetadataForItem(entry.item, container.tier)
            metadata.zone = raid.zoneId
            if exports['zrp_inventory']:AddFoundInRaidItem(raid.id, source, entry.item, amount, metadata) then
                rewards[#rewards + 1] = { item = entry.item, amount = amount }
            end
        end
    end

    local ghostStep = exports['zrp_core']:GetSkillBonus(source, 'survival', 'ghost_step')
    addThreatBySource(source, math.max(0, Config.Threat.Loot - math.floor(ghostStep * 10)))
    exports['zrp_contracts']:HandleCollectProgress(raid.id, rewards)
    return true, rewards
end)
