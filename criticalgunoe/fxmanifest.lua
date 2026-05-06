fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'criticalgunoe'
author 'CriticalGunOE'
description 'Standalone GunGame resource met arena matchmaking, weapon progression, HUD en admin commands.'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua',
    'shared/locales.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
