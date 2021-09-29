fx_version 'cerulean'
game 'gta5'

name 'joehud'
author 'joerogan#0001 / CosmoKramer'
description 'HUD, Seatbelt & Speedlimiter System'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/script.js',
    'html/style.css',
}

client_scripts {
 'client.lua'
}

server_scripts {
 'server.lua'
}

dependencies {
    'es_extended',
    'esx_status',
    'esx_society'
}
