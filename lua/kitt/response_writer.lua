local log = require("kitt.log")

local line = 0
local content = ""

local buf_win_state = { buf = nil, win = nil }

local M = {}

M.ensure_buf_win = function()
  buf_win_state.buf = buf_win_state.buf or vim.api.nvim_create_buf(true, true)
  if buf_win_state.win and vim.api.nvim_win_get_buf(buf_win_state.win) == buf_win_state.buf then
    return buf_win_state.buf
  end

  vim.cmd("vsplit")
  buf_win_state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(buf_win_state.win, buf_win_state.buf)
  vim.wo.wrap = true
  vim.wo.linebreak = true

  return buf_win_state.buf
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
