local curl = require("plenary.curl")

local resource_name = os.getenv("OPENAI_RESOURCE_NAME")
-- local model = os.getenv("OPENAI_MODEL")
local api_version = os.getenv("OPENAI_API_VERSION")
local api_key = os.getenv("OPENAI_API_KEY")

local end_point_start = "https://" .. resource_name .. ".openai.azure.com/openai/"
local end_point_end = "?api-version=" .. api_version

local function aap()
  local end_point = end_point_start .. "files" .. end_point_end

  local opts = {
    headers = {
      content_type = "multipart/form-",
      api_key = api_key,
    },
    form = {
      file = "@~/tmp/test.md",
      purpose = "assistants",
    },
    timeout = 120000
  }

  local response = curl.post(end_point, opts)
  return response
end

local res = aap()
print(res)
