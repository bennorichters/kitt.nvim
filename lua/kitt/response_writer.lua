local log = require("kitt.log")

local M = { buffer = nil, line = 0, content = "" }

function M:new(obj)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self

  return obj
end

function M:ensure_buf_win()
  local buf = vim.api.nvim_create_buf(true, true)

  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo.wrap = true
  vim.wo.linebreak = true

  return buf
end

function M:write(delta, buf)
  log.fmt_trace("response_writer delta=%s", delta)

  delta:gsub(".", function(c)
    if c == "\n" then
      log.fmt_trace("response_writer line=%s content=%s", self.line, self.content)
      vim.api.nvim_buf_set_lines(buf, self.line, -1, false, { self.content })
      self.line = self.line + 1
      self.content = ""
    else
      self.content = self.content .. c
    end
  end)

  if self.content then
    log.fmt_trace("response_writer -write rest- line=%s content=%s", self.line, self.content)
    vim.api.nvim_buf_set_lines(buf, self.line, -1, false, { self.content })
  end
end

return M
