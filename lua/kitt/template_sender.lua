local text_prompt = require("kitt.text_prompt")
local stream_handler = require("kitt.stream")
local response_writer = require("kitt.response_writer")

local function encode_text(text)
  local encoded_text = vim.fn.json_encode(text)
  return string.sub(encoded_text, 2, string.len(encoded_text) - 1)
end

return function(send_request, timeout)
  local send_plain_request = function(body_content)
    local response = send_request(body_content, { timeout = timeout })

    if (response.status == 200) then
      local response_body = vim.fn.json_decode(response.body)
      local content = response_body.choices[1].message.content
      return content
    else
      print(vim.inspect(response))
    end
  end

  local send_stream_request = function(body_content)
    local ui_select = text_prompt.process_buf_text(text_prompt.prompt)
    local rw = response_writer:new()
    local buf = rw:ensure_buf_win()
    local write = function(content) rw:write(content, buf) end
    local process_stream = stream_handler.process_wrap(stream_handler.parse, ui_select, write)
    local stream = { stream = vim.schedule_wrap(process_stream) }

    send_request(body_content, stream)
  end

  return function(template, stream, ...)
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
end
