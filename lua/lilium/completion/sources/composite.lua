local async = require 'lilium.async'

---@class CompositeSource : CompletionSource
---@field sources CompletionSource[]
local CompositeSource = {}

---@param sources CompletionSource[]
function CompositeSource:new(sources)
  local obj = { sources = sources }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function CompositeSource:gather_completions(params)
  local futures = async.futures_map(function(source)
    return source:gather_completions(params)
  end, self.sources)

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
  local source_promises = async.futures_map(function(module)
    local factory = require(module)
    local instance = factory.create(params)
    if instance then
      instance.module = module
    end
    return instance
  end, self.modules)
  local sources = async.await_all(source_promises)
  return CompositeSource:new(sources)
end

return M
