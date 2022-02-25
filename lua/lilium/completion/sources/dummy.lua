---@class DummySource : CompletionSource
local DummySource = {}

function DummySource:gather_completions(_)
  return {
    { title = 'Fancy Tix', ref = 'https://asana.com/1234' },
  }
end


---@class DummySourceFactory : CompletionSourceFactory
local M = {}

function M.create(_)
  return DummySource
end

return M
