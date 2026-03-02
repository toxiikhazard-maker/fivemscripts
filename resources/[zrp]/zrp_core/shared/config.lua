ZRPConfig = {}

ZRPConfig.Version = '1.2.0'
ZRPConfig.MaxPartySize = 4
ZRPConfig.ReadyCheckTimeout = 30
ZRPConfig.RaidDurationLimit = 3600

ZRPConfig.Character = {
    MultiCharacter = {
        enabled = true,
        switchCommand = 'zrp_switchchar',
        triggerEvent = 'qb-multicharacter:client:chooseChar'
    },
    Customization = {
        command = 'zrp_customize',
        saveCommand = 'zrp_saveappearance',
        providers = {
            illenium = true,
            fivemAppearance = true
        }
    }
}

ZRPConfig.Hub = {
    Safezone = {
        center = vec3(-548.72, -201.31, 38.22),
        radius = 90.0,
        disableWeapons = true,
        invincible = true
    },
    Vendors = {
        {
            id = 'hub_quartermaster',
            label = 'Quartermaster',
            ped = 's_m_m_armoured_02',
            coords = vec4(-552.91, -195.25, 38.22, 180.0),
            interactionDistance = 2.0,
            stock = {
                buy = {
                    { item = 'bandage', price = 50, amount = 1 },
                    { item = 'water_bottle', price = 20, amount = 1 },
                    { item = 'lockpick', price = 180, amount = 1 },
                    { item = 'pistol_ammo', price = 90, amount = 24 }
                },
                sell = {
                    { item = 'repairkit', price = 120, amount = 1 },
                    { item = 'radio', price = 70, amount = 1 },
                    { item = 'advancedlockpick', price = 250, amount = 1 }
                }
            }
        },
        {
            id = 'hub_medic',
            label = 'Medic Supplier',
            ped = 's_f_y_scrubs_01',
            coords = vec4(-544.55, -206.01, 38.22, 15.0),
            interactionDistance = 2.0,
            stock = {
                buy = {
                    { item = 'medikit', price = 250, amount = 1 },
                    { item = 'ifaks', price = 180, amount = 1 },
                    { item = 'armor_plate_light', price = 600, amount = 1 }
                },
                sell = {
                    { item = 'medic_jacket', price = 350, amount = 1 },
                    { item = 'combat_uniform', price = 200, amount = 1 }
                }
            }
        }
    }
}

ZRPConfig.Threat = {
    Gunshot = 4,
    SprintTick = 1,
    Loot = 2,
    Alarm = 8,
    DecayPerTick = 1,
    TickSeconds = 10,
    Max = 100,
    PartyScale = {
        [1] = 1.0,
        [2] = 1.2,
        [3] = 1.45,
        [4] = 1.7
    }
}

ZRPConfig.Extraction = {
    HoldSeconds = 12,
    HordeMultiplier = 1.8,
    AllExtractWindowBonusSeconds = 120,
    PartyBonusRep = 10
}

ZRPConfig.WeaponAttachments = {
    pistol = { 'at_suppressor_light', 'at_pi_flsh', 'at_pi_comp' },
    smg = { 'at_scope_macro', 'at_ar_supp_02', 'at_ar_afgrip' },
    rifle = { 'at_scope_medium', 'at_ar_supp', 'at_ar_afgrip', 'at_clip_drum_rif' }
}

ZRPConfig.AmmoTypes = {
    pistol = {
        { label = 'FMJ', key = 'fmj', damageMult = 1.0, threatMult = 1.0 },
        { label = 'Hollow Point', key = 'hp', damageMult = 1.12, threatMult = 1.05 },
        { label = 'Subsonic', key = 'subsonic', damageMult = 0.9, threatMult = 0.75 }
    },
    rifle = {
        { label = 'Ball', key = 'ball', damageMult = 1.0, threatMult = 1.0 },
        { label = 'Armor Piercing', key = 'ap', damageMult = 1.15, threatMult = 1.2 },
        { label = 'Incendiary', key = 'incendiary', damageMult = 1.25, threatMult = 1.35 }
    },
    shotgun = {
        { label = 'Buckshot', key = 'buck', damageMult = 1.0, threatMult = 1.1 },
        { label = 'Slug', key = 'slug', damageMult = 1.18, threatMult = 1.2 }
    }
}

ZRPConfig.ArmorAndClothes = {
    armor_plate_light = { armor = 15, movePenalty = 0.0, staminaBonus = 0.02, damageReduce = 0.03 },
    armor_plate_heavy = { armor = 35, movePenalty = 0.05, staminaBonus = -0.05, damageReduce = 0.08 },
    combat_uniform = { sprintMult = 1.05, lootSpeedMult = 1.10, zombieDetectRangeMult = 0.95 },
    recon_suit = { sprintMult = 1.08, lootSpeedMult = 1.15, zombieDetectRangeMult = 0.88 },
    medic_jacket = { healBonus = 0.20, damageReduce = 0.02 },
    hazmat_suit = { infectionResist = 0.30, sprintMult = 0.95, damageReduce = 0.04 }
}

ZRPConfig.SkillTrees = {
    assault = {
        label = 'Assault',
        nodes = {
            recoil_control = { maxRank = 5, bonusPerRank = 0.03, description = 'Reduced recoil / spread penalty' },
            heavy_hitter = { maxRank = 5, bonusPerRank = 0.03, description = 'Weapon damage bonus' },
            breach_tactics = { maxRank = 3, bonusPerRank = 0.05, description = 'Faster interaction speed' }
        }
    },
    survival = {
        label = 'Survival',
        nodes = {
            pack_mule = { maxRank = 5, bonusPerRank = 2500, description = 'Extra carry capacity during raids' },
            scavenger = { maxRank = 5, bonusPerRank = 0.04, description = 'Increased loot roll chance' },
            ghost_step = { maxRank = 5, bonusPerRank = 0.05, description = 'Reduced threat gain from movement' }
        }
    },
    support = {
        label = 'Support',
        nodes = {
            medic = { maxRank = 5, bonusPerRank = 0.04, description = 'Improved healing effects' },
            armorer = { maxRank = 5, bonusPerRank = 0.03, description = 'Additional passive armor' },
            field_commander = { maxRank = 3, bonusPerRank = 0.05, description = 'Party contract XP bonus' }
        }
    }
}

ZRPConfig.LootTables = {
    [1] = {
        { item = 'bandage', min = 1, max = 3, chance = 0.35 },
        { item = 'water_bottle', min = 1, max = 2, chance = 0.30 },
        { item = 'bread', min = 1, max = 2, chance = 0.30 },
        { item = 'pistol_ammo', min = 12, max = 36, chance = 0.22, ammoClass = 'pistol' },
        { item = 'lockpick', min = 1, max = 1, chance = 0.18 },
        { item = 'weapon_pistol', min = 1, max = 1, chance = 0.08, weaponClass = 'pistol' },
        { item = 'combat_uniform', min = 1, max = 1, chance = 0.07 }
    },
    [2] = {
        { item = 'medikit', min = 1, max = 2, chance = 0.20 },
        { item = 'smg_ammo', min = 24, max = 48, chance = 0.22, ammoClass = 'rifle' },
        { item = 'armor', min = 1, max = 1, chance = 0.15 },
        { item = 'repairkit', min = 1, max = 1, chance = 0.18 },
        { item = 'radio', min = 1, max = 1, chance = 0.15 },
        { item = 'weapon_smg', min = 1, max = 1, chance = 0.06, weaponClass = 'smg' },
        { item = 'armor_plate_light', min = 1, max = 1, chance = 0.10 },
        { item = 'medic_jacket', min = 1, max = 1, chance = 0.07 }
    },
    [3] = {
        { item = 'rifle_ammo', min = 30, max = 60, chance = 0.24, ammoClass = 'rifle' },
        { item = 'advancedlockpick', min = 1, max = 1, chance = 0.20 },
        { item = 'thermite', min = 1, max = 2, chance = 0.14 },
        { item = 'weapon_flashlight', min = 1, max = 1, chance = 0.12 },
        { item = 'ifaks', min = 1, max = 2, chance = 0.18 },
        { item = 'weapon_carbinerifle', min = 1, max = 1, chance = 0.05, weaponClass = 'rifle' },
        { item = 'armor_plate_heavy', min = 1, max = 1, chance = 0.08 },
        { item = 'recon_suit', min = 1, max = 1, chance = 0.06 },
        { item = 'hazmat_suit', min = 1, max = 1, chance = 0.05 }
    }
}

ZRPConfig.Contracts = {
    c_collect_med = { id = 'c_collect_med', label = 'Medical Sweep', type = 'collect', required = 5, item = 'bandage', reward = { cash = 1000, xp = 100, rep = 15 }, extractionGated = true },
    c_collect_parts = { id = 'c_collect_parts', label = 'Salvage Run', type = 'collect', required = 4, item = 'repairkit', reward = { cash = 1400, xp = 140, rep = 20 }, extractionGated = false },
    c_kill_30 = { id = 'c_kill_30', label = 'Cull the Horde', type = 'kill', required = 30, reward = { cash = 1300, xp = 125, rep = 20 }, extractionGated = true },
    c_kill_special = { id = 'c_kill_special', label = 'Priority Target', type = 'kill_special', required = 4, reward = { cash = 1900, xp = 180, rep = 28 }, extractionGated = true },
    c_activate_3 = { id = 'c_activate_3', label = 'Power Relay Reboot', type = 'activate', required = 3, reward = { cash = 1600, xp = 160, rep = 24 }, extractionGated = true },
    c_defend = { id = 'c_defend', label = 'Defend Uplink', type = 'defend', required = 1, defendSeconds = 60, reward = { cash = 1750, xp = 170, rep = 26 }, extractionGated = true }
}

ZRPConfig.Zombies = {
    SpawnTickMs = 4500,
    BaseSpawnPerTick = 2,
    MaxPerPlayer = 12,
    MaxPerRaid = 44,
    DespawnDistance = 180.0,
    EngageDistance = 50.0,
    AttackDistance = 1.6,
    AttackDamage = 7,
    Models = { 'u_m_y_zombie_01', 'a_m_m_tramp_01', 'a_m_m_salton_01', 'a_m_m_skidrow_01' },
    Special = {
        chanceByTier = { [1] = 0.05, [2] = 0.10, [3] = 0.18 },
        hpMultiplier = 2.4,
        speedMultiplier = 1.25,
        damageMultiplier = 1.6
    }
}

ZRPConfig.Zones = {
    docks = {
        id = 'docks', label = 'Port Docks', minLevel = 1, lootTier = 1,
        insertions = { vec4(1197.53, -2976.31, 5.9, 80.0), vec4(1244.24, -3107.44, 5.53, 270.0) },
        extractionPoints = { vec3(1080.4, -3099.2, 5.9), vec3(1386.1, -2956.4, 5.8) },
        containers = {
            { id = 'docks_c1', coords = vec3(1211.9, -3002.1, 5.87), tier = 1 },
            { id = 'docks_c2', coords = vec3(1166.2, -3195.5, 5.8), tier = 1 },
            { id = 'docks_c3', coords = vec3(1286.9, -3298.2, 5.9), tier = 1 },
            { id = 'docks_c4', coords = vec3(1039.8, -3207.1, 5.9), tier = 2 }
        }
    },
    prison = {
        id = 'prison', label = 'Bolingbroke Prison', minLevel = 3, lootTier = 2,
        insertions = { vec4(1842.4, 2596.5, 45.95, 90.0), vec4(1678.2, 2515.2, 45.56, 180.0) },
        extractionPoints = { vec3(1764.2, 2559.8, 45.56), vec3(1657.7, 2610.5, 45.56), vec3(1818.1, 2481.4, 45.8) },
        containers = {
            { id = 'prison_c1', coords = vec3(1772.3, 2498.7, 45.82), tier = 2 },
            { id = 'prison_c2', coords = vec3(1707.4, 2586.0, 45.56), tier = 2 },
            { id = 'prison_c3', coords = vec3(1644.2, 2491.6, 45.56), tier = 3 },
            { id = 'prison_c4', coords = vec3(1848.2, 2691.4, 45.97), tier = 2 }
        }
    }
}

return ZRPConfig
