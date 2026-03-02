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

local function openAdminPanel()
    local data = lib.callback.await('zrp_core:server:getAdminPanelData', false)
    if not data then
        TriggerEvent('zrp_core:client:notify', 'Admin permissions required.', 'error')
        return
    end

    lib.registerContext({
        id = 'zrp_admin_panel',
        title = 'ZRP Admin Panel',
        options = {
            {
                title = 'Set Max Party Size',
                onSelect = function()
                    local input = lib.inputDialog('Set Max Party Size', { { type = 'number', label = 'Value', required = true, default = data.maxParty or 4 } })
                    if input and input[1] then
                        TriggerServerEvent('zrp_core:server:adminSetConfigPath', 'MaxPartySize', tonumber(input[1]))
                    end
                end
            },
            {
                title = 'Set Safezone Radius',
                onSelect = function()
                    local input = lib.inputDialog('Set Safezone Radius', { { type = 'number', label = 'Radius', required = true, default = data.hub and data.hub.Safezone and data.hub.Safezone.radius or 90.0 } })
                    if input and input[1] then
                        TriggerServerEvent('zrp_core:server:adminSetConfigPath', 'Hub.Safezone.radius', tonumber(input[1]))
                    end
                end
            },
            {
                title = 'Set Threat Gunshot Value',
                onSelect = function()
                    local input = lib.inputDialog('Set Threat.Gunshot', { { type = 'number', label = 'Gunshot Threat', required = true, default = data.threat and data.threat.Gunshot or 4 } })
                    if input and input[1] then
                        TriggerServerEvent('zrp_core:server:adminSetConfigPath', 'Threat.Gunshot', tonumber(input[1]))
                    end
                end
            },
            {
                title = 'Add Vendor',
                onSelect = function()
                    local input = lib.inputDialog('Add Vendor', {
                        { type = 'input', label = 'Vendor ID', required = true },
                        { type = 'input', label = 'Label', required = true },
                        { type = 'input', label = 'Ped Model', required = true, default = 's_m_m_armoured_02' },
                        { type = 'number', label = 'X', required = true },
                        { type = 'number', label = 'Y', required = true },
                        { type = 'number', label = 'Z', required = true },
                        { type = 'number', label = 'Heading', required = true, default = 0.0 }
                    })
                    if not input then return end
                    TriggerServerEvent('zrp_core:server:adminAddVendor', {
                        id = tostring(input[1]),
                        label = tostring(input[2]),
                        ped = tostring(input[3]),
                        coords = vec4(tonumber(input[4]), tonumber(input[5]), tonumber(input[6]), tonumber(input[7])),
                        interactionDistance = 2.0,
                        stock = { buy = {}, sell = {} }
                    })
                end
            },
            {
                title = 'Remove Vendor',
                onSelect = function()
                    local input = lib.inputDialog('Remove Vendor', { { type = 'input', label = 'Vendor ID', required = true } })
                    if input and input[1] then
                        TriggerServerEvent('zrp_core:server:adminRemoveVendor', tostring(input[1]))
                    end
                end
            },
            {
                title = 'Add Contract',
                onSelect = function()
                    local input = lib.inputDialog('Add Contract', {
                        { type = 'input', label = 'Contract ID', required = true },
                        { type = 'input', label = 'Label', required = true },
                        { type = 'select', label = 'Type', options = {
                            { value = 'collect', label = 'collect' },
                            { value = 'kill', label = 'kill' },
                            { value = 'kill_special', label = 'kill_special' },
                            { value = 'activate', label = 'activate' },
                            { value = 'defend', label = 'defend' }
                        }, required = true },
                        { type = 'number', label = 'Required', required = true, default = 5 },
                        { type = 'number', label = 'Cash Reward', required = true, default = 1000 },
                        { type = 'number', label = 'XP Reward', required = true, default = 100 },
                        { type = 'number', label = 'REP Reward', required = true, default = 10 }
                    })
                    if not input then return end
                    TriggerServerEvent('zrp_core:server:adminAddContract', {
                        id = tostring(input[1]),
                        label = tostring(input[2]),
                        type = tostring(input[3]),
                        required = tonumber(input[4]),
                        reward = { cash = tonumber(input[5]), xp = tonumber(input[6]), rep = tonumber(input[7]) },
                        extractionGated = true
                    })
                end
            },
            {
                title = 'Remove Contract',
                onSelect = function()
                    local input = lib.inputDialog('Remove Contract', { { type = 'input', label = 'Contract ID', required = true } })
                    if input and input[1] then
                        TriggerServerEvent('zrp_core:server:adminRemoveContract', tostring(input[1]))
                    end
                end
            }
        }
    })
    lib.showContext('zrp_admin_panel')
end

RegisterNetEvent('zrp_core:client:openSkillsMenu', openSkillsMenu)
RegisterCommand('zrp_skills', openSkillsMenu)
RegisterCommand('zrp_admin', openAdminPanel)

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
