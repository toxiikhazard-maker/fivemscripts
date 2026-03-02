local QBCore = exports['qb-core']:GetCoreObject()
local Config = exports['zrp_core']:GetConfig()

local raidContracts = {}

local function getContract(contractId)
    return Config.Contracts[contractId]
end

exports('InitRaidContract', function(raidId, contractId, members)
    local contract = getContract(contractId)
    if not contract then return end

    raidContracts[raidId] = {
        id = contractId,
        progress = 0,
        required = contract.required,
        complete = false,
        members = members,
        defendEndsAt = nil
    }
end)

exports('CleanupRaidContract', function(raidId)
    raidContracts[raidId] = nil
end)

local function setProgress(raidId, amount)
    local rc = raidContracts[raidId]
    if not rc or rc.complete then return end

    rc.progress = math.min(rc.required, rc.progress + amount)
    if rc.progress >= rc.required then
        rc.complete = true
    end

    for _, member in ipairs(rc.members) do
        TriggerClientEvent('zrp_contracts:client:updateProgress', member, rc.progress, rc.required, rc.complete)
    end
end

exports('HandleCollectProgress', function(raidId, rewards)
    local rc = raidContracts[raidId]
    if not rc then return end
    local contract = getContract(rc.id)
    if not contract or contract.type ~= 'collect' then return end

    local amount = 0
    for _, reward in ipairs(rewards) do
        if reward.item == contract.item then
            amount = amount + reward.amount
        end
    end
    if amount > 0 then
        setProgress(raidId, amount)
    end
end)

RegisterNetEvent('zrp_contracts:server:addProgress', function(raidId, progressType, amount)
    local rc = raidContracts[raidId]
    if not rc then return end
    local contract = getContract(rc.id)
    if not contract then return end

    if contract.type == progressType then
        setProgress(raidId, amount or 1)
    elseif contract.type == 'kill_special' and progressType == 'kill_special' then
        setProgress(raidId, amount or 1)
    end
end)

RegisterNetEvent('zrp_contracts:server:startDefend', function(raidId)
    local src = source
    local raid = exports['zrp_raids']:GetRaidByPlayer(src)
    if not raid or raid.id ~= raidId then return end

    local rc = raidContracts[raidId]
    if not rc then return end
    local contract = getContract(rc.id)
    if not contract or contract.type ~= 'defend' then return end

    if rc.defendEndsAt then return end
    rc.defendEndsAt = os.time() + (contract.defendSeconds or 60)

    CreateThread(function()
        while os.time() < rc.defendEndsAt do
            Wait(1000)
            if not raidContracts[raidId] then return end
        end
        setProgress(raidId, 1)
    end)
end)

exports('IsRaidContractComplete', function(raidId)
    local rc = raidContracts[raidId]
    return rc and rc.complete or false
end)

exports('CanExtractRaid', function(raidId)
    local rc = raidContracts[raidId]
    if not rc then return true end
    local contract = getContract(rc.id)
    if not contract then return true end
    if contract.extractionGated then
        return rc.complete
    end
    return true
end)

exports('RewardPlayerForRaid', function(raidId, src)
    local rc = raidContracts[raidId]
    if not rc then return end
    local contract = getContract(rc.id)
    if not contract then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if contract.reward.cash and contract.reward.cash > 0 then
        Player.Functions.AddMoney('cash', contract.reward.cash, 'zrp-contract')
    end
    if contract.reward.xp or contract.reward.rep then
        TriggerClientEvent('zrp_core:client:notify', src, 'Contract reward received.', 'success')
        exports['zrp_core']:AddProgression(src, contract.reward.xp or 0, contract.reward.rep or 0)
    end
end)

lib.callback.register('zrp_contracts:server:getRaidContract', function(source)
    local raid = exports['zrp_raids']:GetRaidByPlayer(source)
    if not raid then return nil end
    local rc = raidContracts[raid.id]
    if not rc then return nil end
    return {
        id = rc.id,
        progress = rc.progress,
        required = rc.required,
        complete = rc.complete
    }
end)
