local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local p = require("kitt.parser")

local T = new_set()

T["parser"] = function()
  eq({ p(nil) }, { false, nil })
  eq({ p("") }, { false, nil })
end


return T
