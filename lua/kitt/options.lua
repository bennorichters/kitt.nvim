local result = {}

result.prompt = function(target_buffer, target_line, content)
  vim.ui.select({ "replace", "ignore" }, {
    prompt = "Choose what to do with the generated text"
  }, function(choice)
    if choice == "replace" then
      vim.api.nvim_buf_set_lines(target_buffer, target_line, target_line + 1, false, content)
    end
  end)
end


result.process_buf_text = function(prompt)
  local target_line = vim.fn.line(".") - 1
  local target_buffer = vim.fn.bufnr()

  local select_with_result = function()
    vim.cmd("redraw")
    local buffer_text = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
    prompt(target_buffer, target_line, buffer_text)
  end

  return select_with_result
end

return result
