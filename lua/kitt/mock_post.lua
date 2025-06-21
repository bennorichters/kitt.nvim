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
    local content = '"[' ..
        '{\\"start\\":12,\\"end\\":23,\\"suggestion\\":\\"brighter\\"},' ..
        '{\\"start\\":24,\\"end\\":28,\\"suggestion\\":\\"than\\"},' ..
        '{\\"start\\":36,\\"end\\":46,\\"suggestion\\":\\"yesterday\\"}' ..
        ']"'

    return {
      status = 200,
      body = '{ "choices": [ { "message": { "content": ' .. content .. ' } } ] }',
    }
  end
end
