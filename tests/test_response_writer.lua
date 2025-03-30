local Helpers = require("tests.helpers")
local eq = MiniTest.expect.equality
local child, T = Helpers.new_child_with_set([[
  rwf = require("kitt.response_writer")
  rw = rwf:new()
]])

local get_lines = function(buf) return child.api.nvim_buf_get_lines(buf, 0, -1, true) end

T["response_writer.write"] = function()
  local buf = child.api.nvim_create_buf(true, true)

  child.lua("rw:write('abc', " .. buf .. ")")
  eq(get_lines(buf), { "abc" })

  child.lua("rw:write('def', " .. buf .. ")")
  eq(get_lines(buf), { "abcdef" })

  child.lua("rw:write('g\\nhi', " .. buf .. ")")
  eq(get_lines(buf), { "abcdefg", "hi" })
end

return T
