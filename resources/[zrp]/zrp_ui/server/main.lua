local Config = exports['zrp_core']:GetConfig()

lib.callback.register('zrp_ui:server:getMenuData', function(source)
    local party = exports['zrp_party']:GetPartyByPlayer(source)
    local profile = exports['zrp_core']:GetProfileBySource(source)
    local raid = exports['zrp_raids']:GetRaidByPlayer(source)
    local roster = exports['zrp_core']:GetCharacterRosterBySource(source) or {}

    local zoneOptions = {}
    for id, zone in pairs(Config.Zones) do
        zoneOptions[#zoneOptions + 1] = {
            id = id,
            label = zone.label,
            minLevel = zone.minLevel
        }
    end

    local contractOptions = {}
    for id, c in pairs(Config.Contracts) do
        contractOptions[#contractOptions + 1] = {
            id = id,
            label = c.label,
            type = c.type
        }
    end

    return {
        party = party,
        profile = profile,
        raid = raid,
        zones = zoneOptions,
        contracts = contractOptions,
        roster = roster
    }
end)
