local log        = require("kitt.log")
local start_data = "data: "
local done_data  = start_data .. "[DONE]"

local M          = {}

M.parse          = function(stream_data)
  if stream_data == nil or stream_data == "" then
    log.trace("parse_stream_data: empty stream_data")
    return false, nil
  end

  if string.sub(stream_data, 1, 6) ~= start_data then
    log.fmt_debug("parse_stream_data: doesn't start with 'data: ', stream_data=%s", stream_data)
    return false, nil
  end

  if stream_data == done_data then
    log.fmt_trace("parse_stream_data: DONE")
    return true, nil
  end

  local status, json = pcall(vim.fn.json_decode, string.sub(stream_data, #start_data + 1))

  if not status then
    log.fmt_debug("parse_stream_data: error parsing json. stream_data=%s", stream_data)
    return false, nil
  end

  if not (json.choices and json.choices[1]) then
    log.fmt_debug("parse_stream_data: unexpected json. stream_data=%s", stream_data)
    return false, nil
  end

  if json.choices[1].finish_reason and json.choices[1].finish_reason ~= vim.NIL then
    log.fmt_trace("parse_stream_data: finished with reason: %s", json.choices[1].finish_reason)
    return false, nil
  end

  if not json.choices[1].delta or not json.choices[1].delta.content then
    log.fmt_debug("parse_stream_data: no delta.content", stream_data)
    return false, nil
  end

  return false, json.choices[1].delta.content
end

M.process_wrap   = function(parse, ui_select, write)
  return function(error, stream_data)
    if error then
      log.fmt_debug("error in stream call back: error=%s, stream_data=%s", error, stream_data)
      return
    end

    local done, content = parse(stream_data)
    if done then
      ui_select()
    elseif content then
      write(content)
    end
  end
end

return M
