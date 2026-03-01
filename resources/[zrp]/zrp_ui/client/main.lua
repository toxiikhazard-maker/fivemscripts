local radialRegistered = false

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

CreateThread(function()
    Wait(1000)
    registerRadial()
end)

RegisterCommand('zrp_menu', function()
    registerRadial()
    lib.notify({ title = 'ZRP', description = 'Use the radial menu (default: F1) for ZRP actions.', type = 'inform' })
end)
