---@class DummySource : CompletionSource
local M = {}

function M:gather_completions(_)
  return {
    { title = 'Fancy Tix', ref = 'https://asana.com/1234' },
  }
end

return M
