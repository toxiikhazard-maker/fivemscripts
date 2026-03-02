fx_version 'cerulean'
game 'gta5'

name 'zrp_core'
author 'zrp'
description 'Core shared config and utilities for Zombie Raid Project'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

files {
    'data/runtime_overrides.json'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'oxmysql'
}
