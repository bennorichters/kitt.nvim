local defaults = {
  post = "curl",
  timeout = 6000
}

local M = {}

M.setup = function(config)
  M.options = vim.tbl_deep_extend("force", defaults, config or {})
end

M.get = function()
  return M.options
end

return M
