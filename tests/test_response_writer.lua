local child = MiniTest.new_child_neovim()
local eq = MiniTest.expect.equality

local get_lines = function(buf) return child.api.nvim_buf_get_lines(buf, 0, -1, true) end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      child.lua([[rw = require("kitt.response_writer")]])
    end,
    post_once = child.stop,
  },
})

T["response_writer.write"] = function()
  local buf = child.api.nvim_create_buf(true, true)

  child.lua("rw.write('abc', " .. buf .. ")")
  eq(get_lines(buf), { "abc" })

  child.lua("rw.write('def', " .. buf .. ")")
  eq(get_lines(buf), { "abcdef" })

  child.lua("rw.write('g\\nhi', " .. buf .. ")")
  eq(get_lines(buf), { "abcdefg", "hi" })
end

return T
