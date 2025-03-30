require("tests.helpers").disable_log()

local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local stream = require("kitt.stream")

local p = stream.parse
local w = stream.process_wrap

local T = new_set()
T["stream"] = new_set()

T["stream"]["parser"] = function()
  eq({ p(nil) }, { false, nil })
  eq({ p("") }, { false, nil })
  eq({ p("data: [DONE]") }, { true, nil })
  eq({ p("[DONE]") }, { false, nil })
  eq({ p("data: [READY]") }, { false, nil })
  eq({ p('data: {"choices":[{"delta":{"content":"abc"}}]}') }, { false, "abc" })
  eq({ p('data: {"choices":[{"delta":{"content":"abc"}}]') }, { false, nil })
end

T["stream"]["process_wrap"] = new_set()
T["stream"]["process_wrap"]["should_not_write_without_content"] = function()
  local parse_no_error_no_content = function(_) return false, nil end
  local ui_select = function() end
  local write = function(content)
    if not content then
      error("no content")
    end
  end

  local f = w(parse_no_error_no_content, ui_select, write)
  f(false, "")
end

return T
