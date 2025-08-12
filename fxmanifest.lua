fx_version 'cerulean'
games { 'gta5' }

lua54 'yes'

author 'JadaDev'
description 'jd-carspawner a simple car spawner for qbcore jobs and car rental'
version '0.1.9'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
    'locales/*.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/countdown.html',
    'html/css/style.css',
    'html/js/script.js'
}

