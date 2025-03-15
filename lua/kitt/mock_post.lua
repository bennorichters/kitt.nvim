local data = 'data: {"choices":[{"delta":{"content":"%d Stream Mock\\n"}}]}'
local last = 'data: {"choices":[{"delta":{"content":"end"}}]}'
local done = "data: [DONE]"

return function(_, opts)
  if opts.stream then
    for i = 1, 5 do
      opts.stream(nil, string.format(data, i))
    end
    opts.stream(nil, last)
    opts.stream(nil, done)
  else
    return "Mock"
  end
end
