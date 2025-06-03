local tpl_grammar = require("kitt.templates.grammar")
local tpl_interact = require("kitt.templates.interact_with_content")
local tpl_minutes = require("kitt.templates.minutes")
local tpl_recognize_language = require("kitt.templates.recognize_language")

local M = {}

M.setup = function(buffer_helper, template_sender)
  M.buffer_helper = buffer_helper
  M.template_sender = template_sender
end

M.ai_improve_grammar = function()
  M.template_sender(tpl_grammar, true, M.buffer_helper.current_line())
end

M.ai_set_spelllang = function()
  local content = M.template_sender(tpl_recognize_language, false, M.buffer_helper.current_line())
  if (content) then
    vim.cmd("set spelllang=" .. content)
  end
end

M.ai_write_minutes = function()
  M.template_sender(tpl_minutes, true, M.buffer_helper.visual_selection())
end

M.ai_interactive = function()
  vim.ui.input({ prompt = "Give instructions: " }, function(command)
    if command then
      M.template_sender(tpl_interact, true, command, M.buffer_helper.visual_selection())
    end
  end)
end

return M
