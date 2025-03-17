local buffer_helper = require("kitt.buffer_helper")
local text_prompt = require("kitt.text_prompt")
local stream_handler = require("kitt.stream")
local response_writer = require("kitt.response_writer")
local send_request_factory = require("kitt.send_request")

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

local send_request

local function encode_text(text)
  local encoded_text = vim.fn.json_encode(text)
  return string.sub(encoded_text, 2, string.len(encoded_text) - 1)
end

local function send_plain_request(body_content)
  local response = send_request(body_content, { timeout = CFG.timeout })

  if (response.status == 200) then
    local response_body = vim.fn.json_decode(response.body)
    local content = response_body.choices[1].message.content
    return content
  else
    print(vim.inspect(response))
  end
end

local function send_stream_request(body_content)
  local select = text_prompt.process_buf_text(text_prompt.prompt)
  local buf = response_writer.ensure_buf_win()
  local process_stream = stream_handler.process_wrap(
    stream_handler.parse, select, response_writer.write, buf
  )

  local stream = { stream = vim.schedule_wrap(process_stream) }

  send_request(body_content, stream)
end

local function send_template(template, stream, ...)
  local subts = {}
  local count = select("#", ...)
  for i = 1, count do
    local text = select(i, ...)
    table.insert(subts, encode_text(text))
  end

  if stream then
    template.stream = true
  end

  local body_content = string.format(vim.fn.json_encode(template), unpack(subts))

  if stream then
    return send_stream_request(body_content)
  else
    return send_plain_request(body_content)
  end
end

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

  send_request = send_request_factory(post)
end

M.ai_improve_grammar = function()
  send_template(tpl_body_grammar, true, buffer_helper.current_line())
end

M.ai_set_spelllang = function()
  local content = send_template(tpl_body_recognize_language, false, buffer_helper.current_line())
  if (content) then
    vim.cmd("set spelllang=" .. content)
  end
end

M.ai_write_minutes = function()
  send_template(tpl_body_minutes, true, buffer_helper.visual_selection())
end

M.ai_interactive = function()
  vim.ui.input({ prompt = "Give instructions" }, function(command)
    if command then
      send_template(tpl_body_interact, true, command, buffer_helper.visual_selection())
    end
  end)
end

return M
