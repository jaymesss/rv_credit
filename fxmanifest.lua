fx_version 'cerulean'
game 'gta5'
description 'Credit & Loans for QBCore'
version '1.0.0'
ui_page 'html/index.html'
client_scripts {
    'client/*.lua'
}
server_scripts {
    'server/*.lua',
    '@oxmysql/lib/MySQL.lua'
}
shared_script {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'locale/en.lua'
}
escrow_ignore {
    "images/**",
    "shared/**.lua",
    "locale/**.lua",
    "README.md",
}
files {
    'html/*.js',
    'html/*.html',
    'html/*.css'
}
lua54 'yes'