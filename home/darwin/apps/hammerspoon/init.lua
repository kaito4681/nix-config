require('hs.ipc')
require('reload').start()

local appToggle = require('app_toggle')
appToggle.bind({ 'cmd' }, 'space', 'com.mitchellh.ghostty')
appToggle.bind({ 'cmd', 'shift' }, 'space', 'com.github.wez.wezterm')
appToggle.bind({ 'ctrl', 'alt', 'cmd' }, 'space', 'com.stablyai.orca')

local appCommand = require('app_command')
appCommand.bind({ 'cmd', 'shift' }, 'o', 'com.mitchellh.ghostty',
  'exec python3 "$HOME/.config/ghostty/vscode_bridge.py" current')
