local curl = require("plenary.curl")
local Popup = require("nui.popup")
local Input = require("nui.input")
local event = require("nui.utils.autocmd").event

local template_body_follow_up = require("kitt.templates.follow_up")
local template_body_grammar = require("kitt.templates.grammar")
local template_body_interact = require("kitt.templates.interact_with_content")
local template_body_minutes = require("kitt.templates.minutes")
local template_body_recognize_language = require("kitt.templates.recognize_language")

local open_interactive_popup

local function split_lines(text)
  text = text .. "\n"
  local lines = {}
  for str in string.gmatch(text, "(.-)\n") do
    table.insert(lines, str)
  end

  return lines
end

local function open_popup(content)
  local popup = Popup({
    enter = true,
    focusable = false,
    border = {
      style = "rounded",
      text = {
        top = "Suggestion",
        top_align = "center",
        bottom = " q - cancel | r - replace | i - insert | f - follow up",
        bottom_align = "left",
      }
    },
    position = "50%",
    size = {
      width = "80%",
      height = "60%",
    },
    buf_options = {
      readonly = true,
      modifiable = false,
    },
  })

  local lines = split_lines(content)
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, lines)

  popup:map("n", "q", function()
    popup:unmount()
  end, {})

  popup:map("n", "r", function()
    popup:unmount()
    local line_number = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(0, line_number, line_number, false, lines)
    vim.cmd "normal dd"
  end, {})

  popup:map("n", "i", function()
    popup:unmount()
    local line_number = vim.fn.line(".")
    vim.api.nvim_buf_set_lines(0, line_number, line_number, false, lines)
  end, {})

  popup:map("n", "f", function()
    popup:unmount()
    open_interactive_popup(template_body_follow_up)
  end, {})

  popup:mount()
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

local function send_request(body_content)
  local endpoint = os.getenv("OPENAI_ENDPOINT")
  local key = os.getenv("OPENAI_API_KEY")

  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_win_set_buf(win, buffer)

  local currentLine = 0
  local currentLineContents = ""

  local on_delta = function(response)
    if response
        and response.choices
        and response.choices[1]
        and response.choices[1].delta
        and response.choices[1].delta.content then
      local delta = response.choices[1].delta.content
      if delta == "\n" then
        vim.api.nvim_buf_set_lines(buffer, currentLine, currentLine, false,
          { currentLineContents })
        currentLine = currentLine + 1
        currentLineContents = ""
      elseif delta:match("\n") then
        for line in delta:gmatch("[^\n]+") do
          vim.api.nvim_buf_set_lines(buffer, currentLine, currentLine, false,
            { currentLineContents .. line })
          currentLine = currentLine + 1
          currentLineContents = ""
        end
      elseif delta ~= nil then
        currentLineContents = currentLineContents .. delta
      end
    end
  end

  local response = curl.post(endpoint,
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
            print("done")
          elseif (string.len(data) > 6) then
            on_delta(vim.fn.json_decode(string.sub(data, 6)))
          end
        end)
    })

  if (response.status == 200) then
    local response_body = vim.fn.json_decode(response.body)
    local content = response_body.choices[1].message.content
    return content
  else
    print(vim.inspect(response))
  end
end

local function send_template(template, ...)
  local subts = {}
  local count = select("#", ...)
  for i = 1, count do
    local text = select(i, ...)
    table.insert(subts, encode_text(text))
  end

  local body_content = string.format(vim.fn.json_encode(template), unpack(subts))
  return send_request(body_content)
end

local function pass_instructions(template, instructions, text)
  local content = send_template(template, instructions, text)

  if (content) then
    open_popup(content)
  end
end

open_interactive_popup = function(template, text)
  local input = Input({
    enter = true,
    border = {
      style = "rounded",
      text = {
        top = "Give instructions",
        top_align = "center",
        bottom_align = "left",
      }
    },
    position = "50%",
    size = {
      width = "80%",
      height = "60%",
    },
  }, {
    prompt = "> ",
    keymap = {
      close = { "<Esc>", "<C-c>" },
    },
    on_submit = function(instructions)
      pass_instructions(template, instructions, text)
    end,
  })

  input:mount()

  input:on(event.BufLeave, function()
    input:unmount()
  end)

  input:map("i", "<Esc>", function()
    input:unmount()
  end, {})
end

local M = {}

M.ai_improve_grammar = function()
  local content = send_template(template_body_grammar, current_line())
  if (content) then
    open_popup(content)
  end
end

M.ai_set_spelllang = function()
  local content = send_template(template_body_recognize_language, current_line())
  if (content) then
    vim.cmd("set spelllang=" .. content)
  end
end

M.ai_write_minutes = function()
  local content = send_template(template_body_minutes, visual_selection())
  if (content) then
    open_popup(content)
  end
end

M.ai_interactive = function()
  open_interactive_popup(template_body_interact, visual_selection())
end

return M
