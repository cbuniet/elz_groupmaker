fx_version "adamant"
games {"rdr3"}
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'

author 'Elzetia'
description 'Adds a temporary group system for players - Adds leader/member blips'

client_script {
    "client/native.lua",
	"client/client.lua",
}
server_script {
	"server/server.lua",
}
shared_script {
    'config.lua',
    'locale.lua',
    'languages/*.lua',
}