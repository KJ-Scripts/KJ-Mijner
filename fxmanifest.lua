fx_version 'cerulean'
game 'gta5'
lua54 'on'

author 'KJ Scripts'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'es_extended',
    'ox_inventory',
    'ox_lib',
    'ox_target'
}
