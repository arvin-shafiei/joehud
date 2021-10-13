fx_version 'cerulean'
game 'gta5'

name 'joehud'
author 'joerogan#0001 / CosmoKramer'
description 'HUD, Seatbelt & Speedlimiter System'
version '1.07'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/script.js',
    'html/style.css',
}

client_scripts {
    'config.lua',
    'client/client.lua'
}

server_scripts {
    'config.lua',
    'server/server.lua'
}

dependencies {
    'es_extended',
    'esx_status',
    'esx_society'
}
