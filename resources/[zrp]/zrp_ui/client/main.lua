local radialRegistered = false
local vendorPeds = {}

local function pickZoneAndContract(mode)
    local data = lib.callback.await('zrp_ui:server:getMenuData', false)
    if not data then return end

    local zoneInput = lib.inputDialog('Select Zone & Contract', {
        {
            type = 'select',
            label = 'Zone',
            options = (function()
                local opts = {}
                for _, z in ipairs(data.zones) do
                    opts[#opts + 1] = { value = z.id, label = ('%s (Lvl %d+)'):format(z.label, z.minLevel) }
                end
                return opts
            end)()
        },
        {
            type = 'select',
            label = 'Contract',
            options = (function()
                local opts = {}
                for _, c in ipairs(data.contracts) do
                    opts[#opts + 1] = { value = c.id, label = ('%s [%s]'):format(c.label, c.type) }
                end
                return opts
            end)()
        }
    })

    if not zoneInput then return end
    if mode == 'party' then
        TriggerServerEvent('zrp_raids:server:startParty', zoneInput[1], zoneInput[2])
    else
        TriggerServerEvent('zrp_raids:server:startSolo', zoneInput[1], zoneInput[2])
    end
end

local function showCharacterRoster()
    local data = lib.callback.await('zrp_ui:server:getMenuData', false)
    if not data then return end

    local opts = {}
    for _, c in ipairs(data.roster or {}) do
        opts[#opts + 1] = {
            title = c.display_name or c.citizenid,
            description = ('Citizen ID: %s'):format(c.citizenid)
        }
    end

    if #opts == 0 then
        opts[#opts + 1] = { title = 'No characters found', description = 'Create one in qb-multicharacter.' }
    end

    lib.registerContext({ id = 'zrp_char_roster', title = 'Character Roster', options = opts })
    lib.showContext('zrp_char_roster')
end

local function openVendorMenu(vendor)
    local stock = lib.callback.await('zrp_ui:server:getVendorStock', false, vendor.id)
    if not stock then
        TriggerEvent('zrp_core:client:notify', 'Vendor unavailable.', 'error')
        return
    end

    local options = {}
    for _, item in ipairs(stock.buy or {}) do
        options[#options + 1] = {
            title = ('Buy %sx %s'):format(item.amount or 1, item.item),
            description = ('$%s'):format(item.price or 0),
            icon = 'cart-shopping',
            onSelect = function()
                TriggerServerEvent('zrp_ui:server:vendorBuy', stock.id, item.item)
            end
        }
    end

    for _, item in ipairs(stock.sell or {}) do
        options[#options + 1] = {
            title = ('Sell %sx %s'):format(item.amount or 1, item.item),
            description = ('$%s'):format(item.price or 0),
            icon = 'money-bill-transfer',
            onSelect = function()
                TriggerServerEvent('zrp_ui:server:vendorSell', stock.id, item.item)
            end
        }
    end

    lib.registerContext({
        id = 'zrp_vendor_menu',
        title = stock.label or 'Vendor',
        options = options
    })
    lib.showContext('zrp_vendor_menu')
end

local function registerRadial()
    if radialRegistered then return end
    radialRegistered = true

    lib.addRadialItem({
        {
            id = 'zrp_party_create',
            label = 'Party Create',
            icon = 'users',
            onSelect = function() TriggerServerEvent('zrp_party:server:create') end
        },
        {
            id = 'zrp_party_invite',
            label = 'Party Invite',
            icon = 'user-plus',
            onSelect = function()
                local input = lib.inputDialog('Invite Player', { { type = 'number', label = 'Server ID', required = true } })
                if input and input[1] then
                    TriggerServerEvent('zrp_party:server:invite', tonumber(input[1]))
                end
            end
        },
        {
            id = 'zrp_party_leave',
            label = 'Party Leave',
            icon = 'person-walking-arrow-right',
            onSelect = function() TriggerServerEvent('zrp_party:server:leave') end
        },
        {
            id = 'zrp_party_kick',
            label = 'Party Kick',
            icon = 'user-minus',
            onSelect = function()
                local input = lib.inputDialog('Kick Player', { { type = 'number', label = 'Server ID', required = true } })
                if input and input[1] then
                    TriggerServerEvent('zrp_party:server:kick', tonumber(input[1]))
                end
            end
        },
        {
            id = 'zrp_raid_solo',
            label = 'Start Solo Raid',
            icon = 'person-rifle',
            onSelect = function() pickZoneAndContract('solo') end
        },
        {
            id = 'zrp_raid_party',
            label = 'Start Party Raid',
            icon = 'people-group',
            onSelect = function() pickZoneAndContract('party') end
        },
        {
            id = 'zrp_skills',
            label = 'Skill Trees',
            icon = 'diagram-project',
            onSelect = function() TriggerEvent('zrp_core:client:openSkillsMenu') end
        },
        {
            id = 'zrp_customize',
            label = 'Customize',
            icon = 'shirt',
            onSelect = function() ExecuteCommand(ZRPConfig.Character.Customization.command) end
        },
        {
            id = 'zrp_saveappearance',
            label = 'Save Appearance',
            icon = 'floppy-disk',
            onSelect = function() ExecuteCommand(ZRPConfig.Character.Customization.saveCommand) end
        },
        {
            id = 'zrp_chars',
            label = 'My Characters',
            icon = 'id-card',
            onSelect = showCharacterRoster
        },
        {
            id = 'zrp_switchchar',
            label = 'Switch Character',
            icon = 'right-left',
            onSelect = function() ExecuteCommand(ZRPConfig.Character.MultiCharacter.switchCommand) end
        }
    })
end

local function loadVendorPed(model)
    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end
    return hash
end

local function spawnVendors()
    for _, ped in ipairs(vendorPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    vendorPeds = {}

    for _, vendor in ipairs(ZRPConfig.Hub.Vendors or {}) do
        local hash = loadVendorPed(vendor.ped)
        local ped = CreatePed(4, hash, vendor.coords.x, vendor.coords.y, vendor.coords.z - 1.0, vendor.coords.w or 0.0, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        vendorPeds[#vendorPeds + 1] = ped
    end
end

CreateThread(function()
    Wait(1000)
    registerRadial()
    spawnVendors()
end)

CreateThread(function()
    while true do
        Wait(0)
        local raid = exports['zrp_raids'] and exports['zrp_raids']:GetCurrentRaid() or nil
        if not raid then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local safe = ZRPConfig.Hub.Safezone
            local dist = #(coords - safe.center)

            if dist <= safe.radius then
                DrawMarker(1, safe.center.x, safe.center.y, safe.center.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, safe.radius * 2.0, safe.radius * 2.0, 1.0, 40, 180, 255, 45, false, false, 2, false, nil, nil, false)
                if safe.disableWeapons then
                    DisablePlayerFiring(PlayerId(), true)
                    DisableControlAction(0, 24, true)
                    DisableControlAction(0, 25, true)
                end
                if safe.invincible then
                    SetEntityInvincible(ped, true)
                end
            else
                SetEntityInvincible(ped, false)
            end

            local near = false
            for _, vendor in ipairs(ZRPConfig.Hub.Vendors or {}) do
                local vPos = vec3(vendor.coords.x, vendor.coords.y, vendor.coords.z)
                local vDist = #(coords - vPos)
                if vDist < 20.0 then
                    DrawMarker(2, vPos.x, vPos.y, vPos.z + 1.05, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.18, 0.18, 0.18, 120, 220, 140, 220, false, false, 2, false, nil, nil, false)
                end
                if vDist <= (vendor.interactionDistance or 2.0) then
                    near = true
                    lib.showTextUI(('[E] Talk to %s'):format(vendor.label))
                    if IsControlJustPressed(0, 38) then
                        openVendorMenu(vendor)
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

RegisterCommand('zrp_menu', function()
    registerRadial()
    lib.notify({ title = 'ZRP', description = 'Use the radial menu (default: F1) for ZRP actions.', type = 'inform' })
end)
