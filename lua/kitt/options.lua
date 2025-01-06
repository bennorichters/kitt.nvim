return function(target_buffer, target_line, content)
  vim.ui.select({ "replace", "ignore" }, {
    prompt = "Choose what to do with the generated text"
  }, function(choice)
    if choice == "replace" then
      vim.api.nvim_buf_set_lines(target_buffer, target_line, target_line + 1, false, content)
    end
  end)
end
