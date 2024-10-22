local curl = require("plenary.curl")

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

return function(body_content, extra_opts)
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
