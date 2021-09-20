fx_version 'cerulean'
name 'joehud'
author 'CosmoKramer / joerogan#0001'
description 'HUD & Seatbelt & Speedlimiter System'
game 'gta5'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/script.js',
    'html/style.css',
}

shared_script '@es_extended/imports.lua'

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua'
}
