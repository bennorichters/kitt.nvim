local config = require("kitt.config")
local buffer_helper = require("kitt.buffer_helper")
local send_request_factory = require("kitt.send_request")
local template_sender_factory = require("kitt.template_sender")
local commands = require("kitt.commands")

local log = require("kitt.log")

local M = {}

M.setup = function(user_cfg)
  config.setup(user_cfg)
  log.new({ level = config.get().log_level }, true)
  log.trace("kitt.nvim log started")
  log.debug("user config: ", user_cfg)

  local post
  local cfg_post = config.get().post
  if cfg_post == "curl" then
    post = require("plenary.curl").post
  elseif cfg_post == "mock" then
    post = require("kitt.mock_post")
  else
    log.fmt_error("Unknown 'post' option: " .. cfg_post)
    error("Unknown 'post' option")
  end

  local endpoint = os.getenv("OPENAI_ENDPOINT")
  local key = os.getenv("OPENAI_API_KEY")

  local send_request = send_request_factory(post, endpoint, key)
  local template_sender = template_sender_factory(send_request, config.get().timeout)

  commands.setup(buffer_helper, template_sender)
end

M.ai_improve_grammar = function() commands.ai_improve_grammar() end
M.ai_suggest_grammar = function() commands.ai_suggest_grammar() end
M.ai_set_spelllang = function() commands.ai_set_spelllang() end
M.ai_write_minutes = function() commands.ai_write_minutes() end
M.ai_interactive = function() commands.ai_interactive() end

return M
