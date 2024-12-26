local data = 'data: {"choices":[{"delta":{"content":"Stream Mock\\n"}}]}'
local last = 'data: {"choices":[{"delta":{"content":"end"}}]}'
local done = "data: [DONE]"

return function(_, opts)
  if opts.stream then
    for _ = 1, 10 do
      opts.stream(nil, data)
    end
    opts.stream(nil, last)
    opts.stream(nil, done)
  else
    return "Mock"
  end
end
