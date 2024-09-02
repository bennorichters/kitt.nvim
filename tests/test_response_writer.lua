local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[ResponseWriter = require("kitt.response_writer")]])
    end,
    post_once = child.stop,
  },
})

T["ResponseWriter"] = function()
  child.lua("local rw = ResponseWriter:new()")
  child.type_keys()
end

return T
