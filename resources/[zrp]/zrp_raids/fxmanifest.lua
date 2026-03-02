fx_version 'cerulean'
game 'gta5'

name 'zrp_raids'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua'
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
    'zrp_core',
    'zrp_party',
    'zrp_inventory',
    'zrp_contracts',
    'zrp_extract',
    'zrp_zombies'
}
