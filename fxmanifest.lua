fx_version 'cerulean'
game 'gta5'

name 'joehud'
author 'joerogan#0001 / CosmoKramer'
description 'HUD, Seatbelt & Speedlimiter System'
version '1.08'

ui_page 'html/ui.html'

files {
    'html/ui.html',
    'html/script.js',
    'html/style.css',
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

shared_script {
    'config.lua'
}

dependencies {
    'es_extended',
    'esx_basicneeds'
}
