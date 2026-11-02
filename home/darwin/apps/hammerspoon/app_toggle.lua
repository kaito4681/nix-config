-- アプリの表示・非表示を切り替える。
local launchTimers = {}

local function launch(bundleID)
  local startedAt = hs.timer.absoluteTime()
  launchTimers[bundleID] = hs.timer.doEvery(0.1, function()
    local app = hs.application.get(bundleID)
    local win = app and app:mainWindow()
    if win then
      win:maximize(0)
    end
    if win or hs.timer.absoluteTime() - startedAt >= 30 * 1e9 then
      launchTimers[bundleID]:stop()
      launchTimers[bundleID] = nil
    end
  end)
  hs.application.launchOrFocusByBundleID(bundleID)
end

local M = {}

function M.bind(mods, key, bundleID)
  hs.hotkey.bind(mods, key, function()
    if launchTimers[bundleID] then
      return
    end

    local app = hs.application.get(bundleID)
    if not app or not app:mainWindow() then
      launch(bundleID)
    elseif not app:isHidden() then
      app:hide()
    else
      -- 起動要求を送り直さず、既存のアプリを前面に出す。
      app:unhide()
      app:activate()
    end
  end)
end

return M
