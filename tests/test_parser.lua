local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local p = require("kitt.parser")

local T = new_set()

T["parser"] = function()
  eq({ p(nil) }, { false, nil })
  eq({ p("") }, { false, nil })
  eq({ p("data: [DONE]") }, { true, nil })
  eq({ p("[DONE]") }, { false, nil })
  eq({ p("data: [READY]") }, { false, nil })
  eq({ p('data: {"choices":[{"delta":{"content":"abc"}}]}') }, { false, "abc" })
  eq({ p('data: {"choices":[{"delta":{"content":"abc"}}]') }, { false, nil })
end

return T
