local QBCore = exports['qb-core']:GetCoreObject()
local Config = ZRPConfig
local runtimeOverridePath = 'data/runtime_overrides.json'

local function isAdmin(src)
    if src == 0 then return true end
    if QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') then
        return true
    end
    return IsPlayerAceAllowed(src, 'command') or IsPlayerAceAllowed(src, 'zrp.admin')
end

local function deepMerge(base, override)
    for k, v in pairs(override or {}) do
        if type(v) == 'table' and type(base[k]) == 'table' then
            deepMerge(base[k], v)
        else
            base[k] = v
        end
    end
end

local function loadRuntimeOverrides()
    local raw = LoadResourceFile(GetCurrentResourceName(), runtimeOverridePath)
    if not raw or raw == '' then return end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == 'table' then
        deepMerge(Config, decoded)
    end
end

local function saveRuntimeOverrides(override)
    SaveResourceFile(GetCurrentResourceName(), runtimeOverridePath, json.encode(override, { indent = true }), -1)
end

local function setByPath(tbl, path, value)
    local target = tbl
    for i = 1, #path - 1 do
        local key = path[i]
        if type(target[key]) ~= 'table' then target[key] = {} end
        target = target[key]
    end
    target[path[#path]] = value
end

local runtimeOverrides = {}
do
    local raw = LoadResourceFile(GetCurrentResourceName(), runtimeOverridePath)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            runtimeOverrides = decoded
        end
    end
    loadRuntimeOverrides()
end

local function ensurePlayerRow(citizenid)
    local row = MySQL.single.await('SELECT citizenid FROM zrp_players WHERE citizenid = ?', { citizenid })
    if not row then
        MySQL.insert.await('INSERT INTO zrp_players (citizenid, xp, level, rep) VALUES (?, 0, 1, 0)', { citizenid })
    end

    local skillRow = MySQL.single.await('SELECT citizenid FROM zrp_skills WHERE citizenid = ?', { citizenid })
    if not skillRow then
        MySQL.insert.await('INSERT INTO zrp_skills (citizenid, points, trees) VALUES (?, 0, ?)', { citizenid, json.encode({}) })
    end

    local charRow = MySQL.single.await('SELECT citizenid FROM zrp_characters WHERE citizenid = ?', { citizenid })
    if not charRow then
        local pdata = MySQL.single.await('SELECT license, charinfo FROM players WHERE citizenid = ?', { citizenid })
        local license = pdata and pdata.license or 'unknown'
        local charinfo = pdata and json.decode(pdata.charinfo or '{}') or {}
        local display = (charinfo.firstname and charinfo.lastname) and (charinfo.firstname .. ' ' .. charinfo.lastname) or citizenid
        MySQL.insert.await('INSERT INTO zrp_characters (citizenid, license, display_name, appearance) VALUES (?, ?, ?, ?)', {
            citizenid,
            license,
            display,
            json.encode({})
        })
    end
end

local function getPlayerProfile(citizenid)
    ensurePlayerRow(citizenid)
    return MySQL.single.await('SELECT citizenid, xp, level, rep FROM zrp_players WHERE citizenid = ?', { citizenid })
end

local function getSkillState(citizenid)
    ensurePlayerRow(citizenid)
    local row = MySQL.single.await('SELECT points, trees FROM zrp_skills WHERE citizenid = ?', { citizenid })
    local trees = row and json.decode(row.trees or '{}') or {}
    return { points = row and row.points or 0, trees = trees }
end

local function saveSkillState(citizenid, points, trees)
    MySQL.update.await('UPDATE zrp_skills SET points = ?, trees = ? WHERE citizenid = ?', { points, json.encode(trees), citizenid })
end

local function getCharacterAppearance(citizenid)
    local row = MySQL.single.await('SELECT appearance FROM zrp_characters WHERE citizenid = ?', { citizenid })
    if not row then return nil end
    return json.decode(row.appearance or '{}')
end

local function saveCharacterAppearance(citizenid, appearance)
    ensurePlayerRow(citizenid)
    MySQL.update.await('UPDATE zrp_characters SET appearance = ? WHERE citizenid = ?', {
        json.encode(appearance or {}), citizenid
    })
end

local function getCharacterListByLicense(license)
    return MySQL.query.await('SELECT citizenid, display_name, updated_at FROM zrp_characters WHERE license = ? ORDER BY updated_at DESC', { license }) or {}
end

local function getRankBonus(trees, treeKey, nodeKey)
    local treeCfg = Config.SkillTrees[treeKey]
    if not treeCfg then return 0 end
    local nodeCfg = treeCfg.nodes[nodeKey]
    if not nodeCfg then return 0 end

    local rank = (((trees or {})[treeKey] or {})[nodeKey] or 0)
    return rank * (nodeCfg.bonusPerRank or 0)
end

local function getPlayerBySource(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return nil end
    ensurePlayerRow(Player.PlayerData.citizenid)
    return Player
end

local function addProgressionBySource(src, xp, rep)
    local Player = getPlayerBySource(src)
    if not Player then return false end

    xp = math.max(0, tonumber(xp) or 0)
    rep = math.max(0, tonumber(rep) or 0)

    local profile = getPlayerProfile(Player.PlayerData.citizenid)
    local oldLevel = profile.level
    local newXp = profile.xp + xp
    local newRep = profile.rep + rep
    local nextLevel = math.floor(newXp / 500) + 1

    MySQL.update.await('UPDATE zrp_players SET xp = ?, rep = ?, level = ? WHERE citizenid = ?', {
        newXp, newRep, nextLevel, Player.PlayerData.citizenid
    })

    if nextLevel > oldLevel then
        local skillState = getSkillState(Player.PlayerData.citizenid)
        local gained = nextLevel - oldLevel
        saveSkillState(Player.PlayerData.citizenid, skillState.points + gained, skillState.trees)
        TriggerClientEvent('zrp_core:client:notify', src, ('Level up! +%d skill point(s)'):format(gained), 'success')
    end

    TriggerClientEvent('zrp_core:client:notify', src, ('+%d XP | +%d REP'):format(xp, rep), 'success')
    return true
end

local function getLootMetadataForItem(itemName, tier)
    local metadata = { fir = true, tier = tier, foundAt = os.time() }

    for _, ammoList in pairs(Config.AmmoTypes) do
        for _, ammo in ipairs(ammoList) do
            if itemName:find('ammo') then
                metadata.ammoType = ammo.key
                metadata.damageMult = ammo.damageMult
                metadata.threatMult = ammo.threatMult
                return metadata
            end
        end
    end

    if itemName:find('weapon_') then
        local pool = Config.WeaponAttachments.rifle
        if itemName:find('pistol') then pool = Config.WeaponAttachments.pistol end
        if itemName:find('smg') then pool = Config.WeaponAttachments.smg end

        metadata.attachments = {}
        local picks = math.random(1, math.min(2, #pool))
        local used = {}
        for _ = 1, picks do
            local candidate = pool[math.random(1, #pool)]
            if not used[candidate] then
                used[candidate] = true
                metadata.attachments[#metadata.attachments + 1] = candidate
            end
        end
    end

    if Config.ArmorAndClothes[itemName] then
        metadata.benefits = Config.ArmorAndClothes[itemName]
    end

    return metadata
end

AddEventHandler('QBCore:Server:OnPlayerLoaded', function(player)
    ensurePlayerRow(player.PlayerData.citizenid)
    local appearance = getCharacterAppearance(player.PlayerData.citizenid)
    if appearance and next(appearance) then
        TriggerClientEvent('zrp_core:client:applyAppearance', player.PlayerData.source, appearance)
    end
end)

RegisterNetEvent('zrp_core:server:addProgression', function(xp, rep)
    addProgressionBySource(source, xp, rep)
end)

RegisterNetEvent('zrp_core:server:saveAppearance', function(appearance)
    local src = source
    local Player = getPlayerBySource(src)
    if not Player then return end

    if type(appearance) ~= 'table' then
        TriggerClientEvent('zrp_core:client:notify', src, 'Invalid appearance payload.', 'error')
        return
    end

    saveCharacterAppearance(Player.PlayerData.citizenid, appearance)
    TriggerClientEvent('zrp_core:client:notify', src, 'Appearance saved for this character.', 'success')
end)

lib.callback.register('zrp_core:server:getProfile', function(source)
    local Player = getPlayerBySource(source)
    if not Player then return nil end
    return getPlayerProfile(Player.PlayerData.citizenid)
end)

lib.callback.register('zrp_core:server:getSkillState', function(source)
    local Player = getPlayerBySource(source)
    if not Player then return nil end
    return getSkillState(Player.PlayerData.citizenid)
end)

lib.callback.register('zrp_core:server:getAppearance', function(source)
    local Player = getPlayerBySource(source)
    if not Player then return nil end
    return getCharacterAppearance(Player.PlayerData.citizenid)
end)

lib.callback.register('zrp_core:server:getCharacterRoster', function(source)
    local Player = getPlayerBySource(source)
    if not Player then return {} end
    local license = Player.PlayerData.license
    return getCharacterListByLicense(license)
end)

RegisterNetEvent('zrp_core:server:spendSkillPoint', function(treeKey, nodeKey)
    local src = source
    local Player = getPlayerBySource(src)
    if not Player then return end

    local treeCfg = Config.SkillTrees[treeKey]
    if not treeCfg or not treeCfg.nodes[nodeKey] then return end

    local skillState = getSkillState(Player.PlayerData.citizenid)
    if skillState.points <= 0 then
        TriggerClientEvent('zrp_core:client:notify', src, 'No available skill points.', 'error')
        return
    end

    skillState.trees[treeKey] = skillState.trees[treeKey] or {}
    local currentRank = skillState.trees[treeKey][nodeKey] or 0
    local maxRank = treeCfg.nodes[nodeKey].maxRank or 1
    if currentRank >= maxRank then
        TriggerClientEvent('zrp_core:client:notify', src, 'Node already maxed.', 'error')
        return
    end

    skillState.trees[treeKey][nodeKey] = currentRank + 1
    skillState.points = skillState.points - 1
    saveSkillState(Player.PlayerData.citizenid, skillState.points, skillState.trees)

    TriggerClientEvent('zrp_core:client:notify', src, ('Upgraded %s/%s to rank %d'):format(treeKey, nodeKey, currentRank + 1), 'success')
end)

exports('GetProfileBySource', function(src)
    local Player = getPlayerBySource(src)
    if not Player then return nil end
    return getPlayerProfile(Player.PlayerData.citizenid)
end)

exports('GetSkillStateBySource', function(src)
    local Player = getPlayerBySource(src)
    if not Player then return { points = 0, trees = {} } end
    return getSkillState(Player.PlayerData.citizenid)
end)

exports('GetSkillBonus', function(src, treeKey, nodeKey)
    local state = exports['zrp_core']:GetSkillStateBySource(src)
    return getRankBonus(state.trees, treeKey, nodeKey)
end)

exports('GetCharacterRosterBySource', function(src)
    local Player = getPlayerBySource(src)
    if not Player then return {} end
    return getCharacterListByLicense(Player.PlayerData.license)
end)

exports('GetLootMetadataForItem', function(itemName, tier)
    return getLootMetadataForItem(itemName, tier)
end)

exports('AddProgression', function(src, xp, rep)
    return addProgressionBySource(src, xp, rep)
end)

exports('GetConfig', function()
    return ZRPConfig
end)

lib.callback.register('zrp_core:server:getAdminPanelData', function(source)
    if not isAdmin(source) then return nil end
    return {
        hub = Config.Hub,
        threat = Config.Threat,
        extraction = Config.Extraction,
        contracts = Config.Contracts,
        zones = Config.Zones,
        maxParty = Config.MaxPartySize
    }
end)

RegisterNetEvent('zrp_core:server:adminSetConfigPath', function(pathKey, value)
    local src = source
    if not isAdmin(src) then return end
    if type(pathKey) ~= 'string' or pathKey == '' then return end

    local path = {}
    for segment in string.gmatch(pathKey, '[^%.]+') do
        path[#path + 1] = segment
    end
    if #path == 0 then return end

    setByPath(Config, path, value)
    setByPath(runtimeOverrides, path, value)
    saveRuntimeOverrides(runtimeOverrides)
    TriggerClientEvent('zrp_core:client:notify', src, ('Updated config: %s'):format(pathKey), 'success')
end)

RegisterNetEvent('zrp_core:server:adminAddVendor', function(vendor)
    local src = source
    if not isAdmin(src) then return end
    if type(vendor) ~= 'table' or not vendor.id or not vendor.label or not vendor.coords then return end

    Config.Hub.Vendors = Config.Hub.Vendors or {}
    Config.Hub.Vendors[#Config.Hub.Vendors + 1] = vendor

    runtimeOverrides.Hub = runtimeOverrides.Hub or {}
    runtimeOverrides.Hub.Vendors = Config.Hub.Vendors
    saveRuntimeOverrides(runtimeOverrides)
    TriggerClientEvent('zrp_core:client:notify', src, ('Vendor added: %s'):format(vendor.label), 'success')
end)

RegisterNetEvent('zrp_core:server:adminAddContract', function(contract)
    local src = source
    if not isAdmin(src) then return end
    if type(contract) ~= 'table' or not contract.id or not contract.label or not contract.type or not contract.required then return end

    contract.reward = contract.reward or { cash = 0, xp = 0, rep = 0 }
    Config.Contracts[contract.id] = contract

    runtimeOverrides.Contracts = runtimeOverrides.Contracts or {}
    runtimeOverrides.Contracts[contract.id] = contract
    saveRuntimeOverrides(runtimeOverrides)
    TriggerClientEvent('zrp_core:client:notify', src, ('Contract added: %s'):format(contract.id), 'success')
end)

RegisterNetEvent('zrp_core:server:adminRemoveVendor', function(vendorId)
    local src = source
    if not isAdmin(src) then return end
    if type(vendorId) ~= 'string' then return end

    local nextList = {}
    for _, v in ipairs(Config.Hub.Vendors or {}) do
        if v.id ~= vendorId then nextList[#nextList + 1] = v end
    end
    Config.Hub.Vendors = nextList

    runtimeOverrides.Hub = runtimeOverrides.Hub or {}
    runtimeOverrides.Hub.Vendors = nextList
    saveRuntimeOverrides(runtimeOverrides)
    TriggerClientEvent('zrp_core:client:notify', src, ('Vendor removed: %s'):format(vendorId), 'success')
end)

RegisterNetEvent('zrp_core:server:adminRemoveContract', function(contractId)
    local src = source
    if not isAdmin(src) then return end
    if type(contractId) ~= 'string' then return end

    Config.Contracts[contractId] = nil

    runtimeOverrides.Contracts = runtimeOverrides.Contracts or {}
    runtimeOverrides.Contracts[contractId] = nil
    saveRuntimeOverrides(runtimeOverrides)
    TriggerClientEvent('zrp_core:client:notify', src, ('Contract removed: %s'):format(contractId), 'success')
end)
