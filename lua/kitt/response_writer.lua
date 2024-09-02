local log = require("kitt.log")

local ResponseWriter = { line = 0, content = "" }
function ResponseWriter:new(obj, buffer)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self

  obj.buffer = buffer
  return obj
end

function ResponseWriter:write(delta)
  log.fmt_trace("ResponseWriter:write delta=%s", delta)

  delta:gsub(".", function(c)
    if c == "\n" then
      log.fmt_trace("ResponseWriter:write line=%s content=%s", self.line, self.content)
      vim.api.nvim_buf_set_lines(self.buffer, self.line, -1, false, { self.content })
      self.line = self.line + 1
      self.content = ""
    else
      self.content = self.content .. c
    end
  end)

  if self.content then
    log.fmt_trace("ResponseWriter:write -write rest- line=%s content=%s", self.line, self.content)
    vim.api.nvim_buf_set_lines(self.buffer, self.line, -1, false, { self.content })
  end
end

return ResponseWriter
