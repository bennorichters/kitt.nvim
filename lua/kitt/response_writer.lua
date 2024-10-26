local log = require("kitt.log")

local function ensure_buf_win(buf, win)
  buf = buf or vim.api.nvim_create_buf(true, true)
  if win and vim.api.nvim_win_get_buf(win) == buf then
    return buf, win
  end

  vim.cmd("vsplit")
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo.wrap = true
  vim.wo.linebreak = true

  return buf, win
end

local ResponseWriter = { line = 0, content = "" }
function ResponseWriter:new(obj)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self

  obj.buffer = nil
  obj.win = nil

  return obj
end

function ResponseWriter:write(delta)
  log.fmt_trace("ResponseWriter:write delta=%s", delta)

  self.buffer, self.win = ensure_buf_win(self.buffer, self.win)

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
