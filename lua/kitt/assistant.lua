local curl = require("plenary.curl")

local resource_name = os.getenv("OPENAI_RESOURCE_NAME")
-- local deployment_name = os.getenv("OPENAI_DEPLOYMENT_NAME")
local api_version = os.getenv("OPENAI_API_VERSION")
local api_key = os.getenv("OPENAI_API_KEY")

local function start()
  local end_point = "https://" ..
      resource_name ..
      ".openai.azure.com/openai/assistants?api-version=" ..
      api_version

  local body_content_table = {
    instructions = "You are an AI assistant that can write code to help answer math questions.",
    name = "Math Assist",
    tools = { { type = "code_interpreter" } },
    model = "gpt-4o"
  }
  local body_content = vim.fn.json_encode(body_content_table)

  local opts = {
    body = body_content,
    headers = {
      content_type = "application/json",
      api_key = api_key,
    },
  }

  local response = curl.post(end_point, opts)
  local response_body = vim.fn.json_decode(response.body)
  return response_body.id
end

local assistant_id = start()
print(assistant_id)
