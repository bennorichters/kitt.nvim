local curl = require("plenary.curl")

local resource_name = os.getenv("OPENAI_RESOURCE_NAME")
local model = os.getenv("OPENAI_MODEL")
local api_version = os.getenv("OPENAI_API_VERSION")
local api_key = os.getenv("OPENAI_API_KEY")

local end_point_start = "https://" .. resource_name .. ".openai.azure.com/openai/"
local end_point_end = "?api-version=" .. api_version

local function start()
  local end_point = end_point_start .. "assistants" .. end_point_end

  local body_content_table = {
    instructions = "You are an AI assistant that can write code to help answer math questions.",
    name = "Math Assist",
    tools = { { type = "code_interpreter" } },
    model = model
  }
  local body_content = vim.fn.json_encode(body_content_table)

  local opts = {
    body = body_content,
    headers = {
      content_type = "application/json",
      api_key = api_key,
    },
  }

  print(vim.inspect(opts))
  local response = curl.post(end_point, opts)
  local response_body = vim.fn.json_decode(response.body)
  print(response.body)
  return response_body.id
end

function create_thread()
end

local assistant_id = start()
print(assistant_id)
