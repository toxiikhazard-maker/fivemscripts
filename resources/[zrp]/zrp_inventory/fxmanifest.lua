fx_version 'cerulean'
game 'gta5'

name 'zrp_inventory'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'zrp_core'
}
