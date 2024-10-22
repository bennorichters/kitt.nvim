return function(buf, win)
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
