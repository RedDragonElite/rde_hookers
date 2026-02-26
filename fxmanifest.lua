fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author      'RDE | SerpentsByte'
description 'Next-Gen Hooker System – Ultra-Realistic, Statebag-Synced, Immersive UI, Vehicle Integration'
version     '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@ox_core/lib/init.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',   -- keep for future DB logging / stats persistence
    'server.lua',
}

dependencies {
    'ox_core',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
}

-- Optional: logging via rde_nostr_log (script works fine without it)
optional_dependencies {
    'rde_nostr_log',
}