-- 指定したアプリが前面にあるときだけ、キー操作でシェルコマンドを実行する。
local bindings = {}

local function update()
  local app = hs.application.frontmostApplication()
  local bundleID = app and app:bundleID()
  for _, binding in ipairs(bindings) do
    if binding.bundleID == bundleID then
      binding.hotkey:enable()
    else
      binding.hotkey:disable()
    end
  end
end

local watcher = hs.application.watcher.new(function(_, event)
  if event == hs.application.watcher.activated or event == hs.application.watcher.deactivated then
    update()
  end
end)

local M = {}

function M.bind(mods, key, bundleID, command)
  local binding = { bundleID = bundleID }
  binding.hotkey = hs.hotkey.new(mods, key, function()
    if binding.task and binding.task:isRunning() then return end
    -- PATH を通すためにログインシェル経由で実行する。
    binding.task = hs.task.new('/bin/zsh', function(code, _, stderr)
      if code ~= 0 then
        hs.alert.show(stderr:match('([^\n]+)') or ('failed: ' .. command))
      end
      binding.task = nil
    end, { '-lc', command })
    if binding.task then binding.task:start() end
  end)
  table.insert(bindings, binding)
  watcher:start()
  update()
end

return M
