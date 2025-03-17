local send

local function encode_text(text)
  local encoded_text = vim.fn.json_encode(text)
  return string.sub(encoded_text, 2, string.len(encoded_text) - 1)
end

local ts = {}

ts.init = function(send_request)
  send = send_request
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

ts.send_template = function(template, stream, ...)
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


return ts
