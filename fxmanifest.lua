fx_version 'cerulean'
games { 'gta5' }

author 'qwezert'
description 'NPC Guardians system'
version '1.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua', -- change en to your language
    'config.lua'
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

lua54 'yes'