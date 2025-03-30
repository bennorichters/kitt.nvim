local Helpers = {}

Helpers.new_child_with_set = function(code)
  local child = MiniTest.new_child_neovim()

  local T = MiniTest.new_set({
    hooks = {
      pre_case = function()
        child.restart({ "-u", "scripts/minimal_init.lua" })
        child.lua("log = require('kitt.log')")
        child.lua("log.new({}, true)")
        child.lua("log:disable()")
        child.lua(code)
      end,
      post_once = child.stop,
    },
  })

  return child, T
end

Helpers.disable_log = function()
  local log = require("kitt.log")
  log.new({}, true)
  log:disable()
end

return Helpers
