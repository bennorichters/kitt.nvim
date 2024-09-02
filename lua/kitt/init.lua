local curl = require("plenary.curl")
local ResponseWriter = require("kitt.response_writer")

local template_body_grammar = require("kitt.templates.grammar")
local template_body_interact = require("kitt.templates.interact_with_content")
local template_body_minutes = require("kitt.templates.minutes")
local template_body_recognize_language = require("kitt.templates.recognize_language")

local log = require("kitt.log")
log.trace("kitt log here")

local M = { target_buffer = nil, target_line = nil, ai_buffer = nil }

local function new_buffer()
  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, buffer)
  vim.wo.wrap = true
  vim.wo.linebreak = true

  return buffer
end

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
  vim.ui.select({ "replace", "ignore" }, {
    prompt = "Choose what to do with the generated text"
  }, function(choice)
    if choice == "replace" then
      local content = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
      local txt = table.concat(content, "\n")
      vim.api.nvim_buf_set_lines(M.target_buffer, M.target_line - 1, M.target_line, false, { txt })
    end
  end)
end

local function table_concat(...)
  local result = {}

  for _, tbl in ipairs({ ... }) do
    for k, v in pairs(tbl) do
      if type(k) ~= "number" then
        result[k] = v
      else
        table.insert(result, v)
      end
    end
  end

  return result
end

local function send_request(body_content, extra_opts)
  local endpoint = os.getenv("OPENAI_ENDPOINT")
  local key = os.getenv("OPENAI_API_KEY")

  local opts = {
    body = body_content,
    headers = {
      content_type = "application/json",
      api_key = key,
    },
  }
  if extra_opts then
    opts = table_concat(opts, extra_opts)
  end

  return curl.post(endpoint, opts)
end

local function send_plain_request(body_content)
  local response = send_request(body_content, { timeout = 6000 })

  if (response.status == 200) then
    local response_body = vim.fn.json_decode(response.body)
    local content = response_body.choices[1].message.content
    return content
  else
    print(vim.inspect(response))
  end
end

local function send_stream_request(body_content)
  M.target_line = vim.fn.line(".")
  M.target_buffer = vim.fn.bufnr()

  M.ai_buffer = M.ai_buffer or new_buffer()
  local rw = ResponseWriter:new(nil, M.ai_buffer)
  local on_delta = function(response)
    if response
        and response.choices
        and response.choices[1]
        and response.choices[1].delta
        and response.choices[1].delta.content then
      rw:write(response.choices[1].delta.content)
    end
  end

  local stream = {
    stream = vim.schedule_wrap(
      function(_, data, _)
        local raw_message = string.gsub(data, "^data: ", "")
        if raw_message == "[DONE]" then
          show_options()
        elseif (string.len(data) > 6) then
          on_delta(vim.fn.json_decode(string.sub(data, 6)))
        end
      end)
  }

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
