local log = require("kitt.log")

local buf = nil
local win = nil
local line = 0
local content = ""

local function ensure_buf_win()
  buf = buf or vim.api.nvim_create_buf(true, true)
  if win and vim.api.nvim_win_get_buf(win) == buf then
    return
  end

  vim.cmd("vsplit")
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo.wrap = true
  vim.wo.linebreak = true
end

return function(delta)
  log.fmt_trace("response_writer delta=%s", delta)

  ensure_buf_win()
  assert(buf ~= nil)
  assert(win ~= nil)

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
