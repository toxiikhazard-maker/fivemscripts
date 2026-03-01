fx_version 'cerulean'
game 'gta5'

name 'zrp_zombies'
version '1.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'zrp_core',
    'zrp_raids',
    'zrp_contracts'
}
