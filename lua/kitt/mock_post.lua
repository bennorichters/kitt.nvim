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
        '{\\"start\\":0,\\"end\\":3,\\"suggestion\\":\\"Zij\\"},' ..
        '{\\"start\\":11,\\"end\\":22,\\"suggestion\\":\\"onmiddellijk\\"},' ..
        '{\\"start\\":35,\\"end\\":39,\\"suggestion\\":\\"zeg\\"}' ..
        ']"'

    return {
      status = 200,
      body = '{ "choices": [ { "message": { "content": ' .. content .. ' } } ] }',
    }
  end
end
