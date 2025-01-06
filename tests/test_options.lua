local child = MiniTest.new_child_neovim()
local eq = MiniTest.expect.equality

local get_lines = function(buf) return child.api.nvim_buf_get_lines(buf, 0, -1, true) end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua("opts = require('kitt.options')")
    end,
    post_once = child.stop,
  },
})

T["options"] = function()
  local buf = child.api.nvim_create_buf(true, true)

  child.api.nvim_buf_set_lines(buf, 0, -1, false, { "a", "b", "c", "d", "e" })
  child.lua_notify("opts(" .. buf .. ", 0, {'1', '2', '3'})")
  child.type_keys("1<CR>")
  eq(get_lines(buf), { "1", "2", "3", "b", "c", "d", "e" })
end

return T
