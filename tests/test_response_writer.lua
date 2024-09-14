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
  local buf = child.api.nvim_create_buf(true, true)
  child.lua("rw = ResponseWriter:new(nil, " .. buf .. ")")
  MiniTest.expect.equality(child.lua("return rw.buffer"), buf)
end

return T
