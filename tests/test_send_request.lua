local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local factory = require("kitt.send_request")

local T = new_set()

T["send_request"] = function()
  local function post(endpoint, opts)
    eq(endpoint, "endpoint")
    eq(opts.body, "body_content")
    eq(opts.timeout, 100)
  end

  local sr = factory(post, "endpoint", "key")

  sr("body_content", { timeout = 100 })
end

return T
