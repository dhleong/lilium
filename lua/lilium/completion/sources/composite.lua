local async = require'lilium.async'

---@class CompositeSource : CompletionSource
---@field sources CompletionSource[]
local CompositeSource = {}

function CompositeSource:new(sources)
  local obj = { sources = sources }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function CompositeSource:gather_completions(params)
  local futures = {}
  for i, source in ipairs(self.sources) do
    futures[i] = function ()
      return source:gather_completions(params)
    end
  end

  return async.await_all_concat(futures)
end

---@class CompositeSourceFactory : CompletionSourceFactory
---@field modules string[]
local M = {}

function M:new(modules)
  local obj = { modules = modules }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

---@param params Params
function M:create(params)
  local source_promises = {}
  for i, module in ipairs(self.modules) do
    source_promises[i] = function ()
      local factory = require(module)
      return factory.create(params)
    end
  end
  local sources = async.await_all(source_promises)
  return CompositeSource:new(sources)
end

return M