local CompositeSourceFactory = require 'lilium.completion.sources.composite'
local PrefixedSource = require 'lilium.completion.sources.prefixed'

local source_modules = {
  'lilium.completion.sources.asana',
  'lilium.completion.sources.github',
}

local M = {}

function M.create_composite_factory()
  return CompositeSourceFactory:new(source_modules)
end

---@return CompletionSource|nil
function M.create_source(params)
  local composite_factory = M.create_composite_factory()
  local composite = composite_factory:create(params)
  return PrefixedSource:new({ '#', '@' }, composite)
end

---@return CompletionSource|nil
function M.get_source(params)
  -- TODO cache sources (?)
  return M.create_source(params)
end

return M
