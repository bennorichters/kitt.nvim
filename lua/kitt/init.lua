local buffer_helper = require("kitt.buffer_helper")
local send_request_factory = require("kitt.send_request")
local template_sender_factory = require("kitt.template_sender")

local tpl_body_grammar = require("kitt.templates.grammar")
local tpl_body_interact = require("kitt.templates.interact_with_content")
local tpl_body_minutes = require("kitt.templates.minutes")
local tpl_body_recognize_language = require("kitt.templates.recognize_language")

local log = require("kitt.log")
log.trace("kitt log here")

local CFG = {
  post = "curl",
  timeout = 6000
}

local template_sender

local M = {}

M.setup = function(user_cfg)
  CFG = vim.tbl_extend('force', CFG, user_cfg or {})

  local post

  if CFG.post == "curl" then
    post = require("plenary.curl").post
  elseif CFG.post == "mock" then
    post = require("kitt.mock_post")
  else
    log.fmt_error("Unknown 'post' option")
    error("Unknown 'post' option")
  end

  local endpoint = os.getenv("OPENAI_ENDPOINT")
  local key = os.getenv("OPENAI_API_KEY")

  local send_request = send_request_factory(post, endpoint, key)
  template_sender = template_sender_factory(send_request, CFG.timeout)
end

M.ai_improve_grammar = function()
  template_sender(tpl_body_grammar, true, buffer_helper.current_line())
end

M.ai_set_spelllang = function()
  local content = template_sender(tpl_body_recognize_language, false, buffer_helper.current_line())
  if (content) then
    vim.cmd("set spelllang=" .. content)
  end
end

M.ai_write_minutes = function()
  template_sender(tpl_body_minutes, true, buffer_helper.visual_selection())
end

M.ai_interactive = function()
  vim.ui.input({ prompt = "Give instructions" }, function(command)
    if command then
      template_sender(tpl_body_interact, true, command, buffer_helper.visual_selection())
    end
  end)
end

return M
