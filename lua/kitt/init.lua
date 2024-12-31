local CFG = {
  post = "curl",
  timeout = 6000
}

local parse_stream_data = require("kitt.parser")
local response_writer = require("kitt.response_writer")
local send_request_factory = require("kitt.send_request")
local SEND_REQUEST

local template_body_grammar = require("kitt.templates.grammar")
local template_body_interact = require("kitt.templates.interact_with_content")
local template_body_minutes = require("kitt.templates.minutes")
local template_body_recognize_language = require("kitt.templates.recognize_language")

local log = require("kitt.log")
log.trace("kitt log here")

local target_buffer = nil
local target_line = nil

local function current_line()
  local line_number = vim.fn.line(".")
  return vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]
end

local function visual_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end

  return table.concat(lines, "\n")
end

local function encode_text(text)
  local encoded_text = vim.fn.json_encode(text)
  return string.sub(encoded_text, 2, string.len(encoded_text) - 1)
end

local function show_options()
  assert(target_buffer ~= nil)
  assert(target_line ~= nil)
  vim.ui.select({ "replace", "ignore" }, {
    prompt = "Choose what to do with the generated text"
  }, function(choice)
    if choice == "replace" then
      local content = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
      vim.api.nvim_buf_set_lines(target_buffer, target_line, target_line, false, content)
    end
  end)
end

local function send_plain_request(body_content)
  local response = SEND_REQUEST(body_content, { timeout = CFG.timeout })

  if (response.status == 200) then
    local response_body = vim.fn.json_decode(response.body)
    local content = response_body.choices[1].message.content
    return content
  else
    print(vim.inspect(response))
  end
end

local function send_stream_request(body_content)
  target_line = vim.fn.line(".")
  target_buffer = vim.fn.bufnr()

  local buf = response_writer.ensure_buf_win()
  local stream = {
    stream = vim.schedule_wrap(
      function(error, stream_data)
        if error then
          log.fmt_debug("error in stream call back: error=%s, stream_data=%s", error, stream_data)
          return
        end

        local done, content = parse_stream_data(stream_data)
        if done then
          show_options()
        elseif content ~= nil then
          response_writer.write(content, buf)
        end
      end)
  }

  SEND_REQUEST(body_content, stream)
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

  SEND_REQUEST = send_request_factory(post)
end

M.ai_improve_grammar = function()
  send_template(template_body_grammar, true, current_line())
end

M.ai_set_spelllang = function()
  local content = send_template(template_body_recognize_language, false, current_line())
  if (content) then
    vim.cmd("set spelllang=" .. content)
  end
end

M.ai_write_minutes = function()
  send_template(template_body_minutes, true, visual_selection())
end

M.ai_interactive = function()
  vim.ui.input({ prompt = "Give instructions" }, function(command)
    if command then
      send_template(template_body_interact, true, command, visual_selection())
    end
  end)
end

return M
