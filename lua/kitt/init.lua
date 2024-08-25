local curl = require("plenary.curl")

local template_body_grammar = require("kitt.templates.grammar")
local template_body_interact = require("kitt.templates.interact_with_content")
local template_body_minutes = require("kitt.templates.minutes")
local template_body_recognize_language = require("kitt.templates.recognize_language")

local log = require("kitt.log")
log.trace("kitt log here")

local line = -1
local buffer = -1

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

local ResponseWriter = { buffer = nil, line = 0, content = "" }
function ResponseWriter:new(obj)
  obj = obj or {}
  setmetatable(obj, self)
  self.__index = self

  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  obj.buffer = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, obj.buffer)
  vim.wo.wrap = true
  vim.wo.linebreak = true

  return obj
end

function ResponseWriter:write(delta)
  log.trace("ResponseWriter:write delta=", delta)

  delta:gsub(".", function(c)
    if c == "\n" then
      log.trace("ResponseWriter:write line=", self.line, " content=", self.content)
      vim.api.nvim_buf_set_lines(self.buffer, self.line, -1, false, { self.content })
      self.line = self.line + 1
      self.content = ""
    else
      self.content = self.content .. c
    end
  end)

  if self.content then
    log.trace("ResponseWriter:write -write rest- line=", self.line, " content=", self.content)
    vim.api.nvim_buf_set_lines(self.buffer, self.line, -1, false, { self.content })
  end
end

local function show_options()
  vim.ui.select({ "replace", "ignore" }, {
    prompt = "Choose what to do with the generated text"
  }, function(choice)
    if choice == "replace" then
      local content = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
      local txt = table.concat(content, "\n")
      vim.api.nvim_buf_set_lines(buffer, line - 1, line, false, { txt })
    end
  end)
end

local function send_request(body_content)
  local endpoint = os.getenv("OPENAI_ENDPOINT")
  local key = os.getenv("OPENAI_API_KEY")

  line = vim.fn.line(".")
  buffer = vim.fn.bufnr()

  local rw = ResponseWriter:new()
  local on_delta = function(response)
    if response
        and response.choices
        and response.choices[1]
        and response.choices[1].delta
        and response.choices[1].delta.content then
      rw:write(response.choices[1].delta.content)
    end
  end

  curl.post(endpoint,
    {
      body = body_content,
      headers = {
        content_type = "application/json",
        api_key = key,
      },
      stream = vim.schedule_wrap(
        function(_, data, _)
          local raw_message = string.gsub(data, "^data: ", "")
          if raw_message == "[DONE]" then
            show_options()
          elseif (string.len(data) > 6) then
            on_delta(vim.fn.json_decode(string.sub(data, 6)))
          end
        end)
    })
end

local function send_template(template, ...)
  local subts = {}
  local count = select("#", ...)
  for i = 1, count do
    local text = select(i, ...)
    table.insert(subts, encode_text(text))
  end

  template.stream = true
  local body_content = string.format(vim.fn.json_encode(template), unpack(subts))
  return send_request(body_content)
end

local M = {}

M.ai_improve_grammar = function()
  send_template(template_body_grammar, current_line())
end

M.ai_set_spelllang = function()
  local content = send_template(template_body_recognize_language, current_line())
  if (content) then
    vim.cmd("set spelllang=" .. content)
  end
end

M.ai_write_minutes = function()
  send_template(template_body_minutes, visual_selection())
end

M.ai_interactive = function()
  vim.ui.input({ prompt = "Give instructions" }, function(command)
    if command then
      send_template(template_body_interact, command, visual_selection())
    end
  end)
end

return M
