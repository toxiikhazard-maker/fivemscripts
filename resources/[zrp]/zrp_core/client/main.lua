local appliedArmorBonus = 0

RegisterNetEvent('zrp_core:client:notify', function(msg, nType)
    lib.notify({ title = 'ZRP', description = msg, type = nType or 'inform' })
end)

local function getSkillRank(state, tree, node)
    if not state or not state.trees then return 0 end
    return ((state.trees[tree] or {})[node] or 0)
end

local function applyArmorAndClothingBenefits()
    if not exports.ox_inventory then return end

    local bonus = 0
    local sprintMult = 1.0
    for itemName, benefit in pairs(ZRPConfig.ArmorAndClothes) do
        local count = exports.ox_inventory:Search('count', itemName)
        if count and count > 0 then
            bonus = math.max(bonus, benefit.armor or 0)
            if benefit.sprintMult then sprintMult = math.max(sprintMult, benefit.sprintMult) end
        end
    end

    local ped = PlayerPedId()
    if bonus ~= appliedArmorBonus then
        local armor = GetPedArmour(ped)
        SetPedArmour(ped, math.min(100, armor + (bonus - appliedArmorBonus)))
        appliedArmorBonus = bonus
    end

    SetRunSprintMultiplierForPlayer(PlayerId(), sprintMult)
end

local function getAppearanceProvider()
    if ZRPConfig.Character.Customization.providers.illenium and GetResourceState('illenium-appearance') == 'started' then
        return 'illenium'
    end
    if ZRPConfig.Character.Customization.providers.fivemAppearance and GetResourceState('fivem-appearance') == 'started' then
        return 'fivem'
    end
    return nil
end

local function openCustomization()
    local provider = getAppearanceProvider()
    if provider == 'illenium' then
        TriggerEvent('illenium-appearance:client:openClothingShopMenu')
        return true
    elseif provider == 'fivem' then
        TriggerEvent('fivem-appearance:client:openOutfitMenu')
        return true
    end

    TriggerEvent('zrp_core:client:notify', 'No appearance resource found (illenium-appearance/fivem-appearance).', 'error')
    return false
end

local function captureCurrentAppearance()
    local provider = getAppearanceProvider()
    if provider == 'illenium' then
        return exports['illenium-appearance']:getPedAppearance(PlayerPedId())
    elseif provider == 'fivem' then
        return exports['fivem-appearance']:getPedAppearance(PlayerPedId())
    end
    return nil
end

RegisterNetEvent('zrp_core:client:applyAppearance', function(appearance)
    if type(appearance) ~= 'table' or not next(appearance) then return end

    local provider = getAppearanceProvider()
    if provider == 'illenium' then
        exports['illenium-appearance']:setPedAppearance(PlayerPedId(), appearance)
    elseif provider == 'fivem' then
        exports['fivem-appearance']:setPedAppearance(PlayerPedId(), appearance)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        applyArmorAndClothingBenefits()
    end
end)

local function openSkillsMenu()
    local state = lib.callback.await('zrp_core:server:getSkillState', false)
    if not state then return end

    local options = {}
    for treeKey, tree in pairs(ZRPConfig.SkillTrees) do
        for nodeKey, node in pairs(tree.nodes) do
            local rank = getSkillRank(state, treeKey, nodeKey)
            options[#options + 1] = {
                title = ('%s / %s [%d/%d]'):format(tree.label, nodeKey, rank, node.maxRank),
                description = node.description,
                onSelect = function()
                    TriggerServerEvent('zrp_core:server:spendSkillPoint', treeKey, nodeKey)
                end
            }
        end
    end

    lib.registerContext({
        id = 'zrp_skills_menu',
        title = ('Skill Trees (Points: %d)'):format(state.points or 0),
        options = options
    })
    lib.showContext('zrp_skills_menu')
end

RegisterNetEvent('zrp_core:client:openSkillsMenu', openSkillsMenu)
RegisterCommand('zrp_skills', openSkillsMenu)

RegisterCommand(ZRPConfig.Character.Customization.command, function()
    openCustomization()
end)

RegisterCommand(ZRPConfig.Character.Customization.saveCommand, function()
    local appearance = captureCurrentAppearance()
    if not appearance then
        TriggerEvent('zrp_core:client:notify', 'Could not capture appearance. Check provider.', 'error')
        return
    end
    TriggerServerEvent('zrp_core:server:saveAppearance', appearance)
end)

RegisterCommand(ZRPConfig.Character.MultiCharacter.switchCommand, function()
    if not ZRPConfig.Character.MultiCharacter.enabled then
        TriggerEvent('zrp_core:client:notify', 'Multi-character switching disabled.', 'error')
        return
    end

    local raid = exports['zrp_raids'] and exports['zrp_raids']:GetCurrentRaid() or nil
    if raid then
        TriggerEvent('zrp_core:client:notify', 'Cannot switch character while in raid.', 'error')
        return
    end

    TriggerServerEvent('QBCore:Server:OnPlayerUnload')
    TriggerEvent(ZRPConfig.Character.MultiCharacter.triggerEvent)
end)

exports('GetConfig', function()
    return ZRPConfig
end)
