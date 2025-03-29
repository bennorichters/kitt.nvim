local log = require("kitt.log")

local line = 0
local content = ""

local M = {}

M.ensure_buf_win = function()
  local buf = vim.api.nvim_create_buf(true, true)

  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo.wrap = true
  vim.wo.linebreak = true

  return buf
end

M.write = function(delta, buf)
  log.fmt_trace("response_writer delta=%s", delta)

  delta:gsub(".", function(c)
    if c == "\n" then
      log.fmt_trace("response_writer line=%s content=%s", line, content)
      vim.api.nvim_buf_set_lines(buf, line, -1, false, { content })
      line = line + 1
      content = ""
    else
      content = content .. c
    end
  end)

  if content then
    log.fmt_trace("response_writer -write rest- line=%s content=%s", line, content)
    vim.api.nvim_buf_set_lines(buf, line, -1, false, { content })
  end
end

return M
