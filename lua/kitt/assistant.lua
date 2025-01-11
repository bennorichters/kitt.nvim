local curl = require("plenary.curl")

local resource_name = os.getenv("OPENAI_RESOURCE_NAME")
local model = os.getenv("OPENAI_MODEL")
local api_version = os.getenv("OPENAI_API_VERSION")
local api_key = os.getenv("OPENAI_API_KEY")

local end_point_start = "https://" .. resource_name .. ".openai.azure.com/openai/"
local end_point_end = "?api-version=" .. api_version

local function create_assistant()
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

  local response = curl.post(end_point, opts)
  local response_body = vim.fn.json_decode(response.body)
  return response_body.id
end

local function create_thread()
  local end_point = end_point_start .. "threads" .. end_point_end

  local opts = {
    body = "",
    headers = {
      content_type = "application/json",
      api_key = api_key,
    },
  }

  local response = curl.post(end_point, opts)
  local response_body = vim.fn.json_decode(response.body)
  return response_body.id
end

local function create_message(thread_id)
  local end_point = end_point_start .. "threads/" .. thread_id .. "/messages" .. end_point_end

  local body_content_table = {
    role = "user",
    content = "I need to solve the equation `3x + 11 = 14`. Can you help me?"
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
  print(vim.inspect(response_body))
  return response_body.id
end

local function create_run(assistant_id, thread_id)
  local end_point = end_point_start .. "threads/" .. thread_id .. "/runs" .. end_point_end

  local body_content_table = {
    assistant_id = assistant_id
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
  print(vim.inspect(response_body))
  return response_body.id
end

local function retrieve_run(thread_id, run_id)
  local end_point = end_point_start .. "threads/" .. thread_id .. "/runs/" .. run_id .. end_point_end

  local opts = {
    body = "",
    headers = {
      content_type = "application/json",
      api_key = api_key,
    },
  }

  local response = curl.post(end_point, opts)
  local response_body = vim.fn.json_decode(response.body)
  print(vim.inspect(response_body))
end

local function list_messages(thread_id)
  local end_point = end_point_start .. "threads/" .. thread_id .. "/messages" .. end_point_end

  local opts = {
    body = "",
    headers = {
      content_type = "application/json",
      api_key = api_key,
    },
  }

  local response = curl.get(end_point, opts)
  local response_body = vim.fn.json_decode(response.body)
  print(vim.inspect(response_body))
end

print("start------------")
local assistant_id = create_assistant()
print("1------------ assistant_id=" ..assistant_id)
local thread_id = create_thread()
print("2------------ thread_id=" .. thread_id)
local message_id = create_message(thread_id)
print("3------------ message_id=" .. message_id)
local run_id = create_run(assistant_id, thread_id)
print("4------------ run_id=" .. run_id)
retrieve_run(thread_id, run_id)
print("5------------")
list_messages(thread_id)
print("end------------")
