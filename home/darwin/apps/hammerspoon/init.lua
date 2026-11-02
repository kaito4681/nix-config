require('hs.ipc')
require('reload').start()

local appToggle = require('app_toggle')
appToggle.bind({ 'cmd' }, 'space', 'com.mitchellh.ghostty')
appToggle.bind({ 'cmd', 'shift' }, 'space', 'com.github.wez.wezterm')
appToggle.bind({ 'ctrl', 'alt', 'cmd' }, 'space', 'com.stablyai.orca')
