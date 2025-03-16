local result = {}

result.select = function(target_buffer, target_line, content)
  vim.ui.select({ "replace", "ignore" }, {
    prompt = "Choose what to do with the generated text"
  }, function(choice)
    if choice == "replace" then
      vim.api.nvim_buf_set_lines(target_buffer, target_line, target_line + 1, false, content)
    end
  end)
end


result.prepare_select = function(select)
  local target_line = vim.fn.line(".") - 1
  local target_buffer = vim.fn.bufnr()

  local aap = function()
    vim.cmd("redraw")
    local buffer_text = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
    select(target_buffer, target_line, buffer_text)
  end

  return aap
end

return result
