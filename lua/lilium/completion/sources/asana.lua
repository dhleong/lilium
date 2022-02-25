local fs = require'lilium.fs'

local asana_config_filename = '.lilium.asana.json'

---@alias AsanaConfig {token:string, workspace:string}

---@class AsanaSource : CompletionSource
---@field config AsanaConfig
local AsanaSource = {}

function AsanaSource:new(config)
  local obj = { config = config }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function AsanaSource:gather_completions(_)
  return {
    { title = 'Asana ' .. self.config.token, ref = 'http' }
  }
end

---@class AsanaSourceFactory : CompletionSourceFactory
local M = {}

M.AsanaSource = AsanaSource

---@param params Params
function M.create(params)
  local config = fs.find_json(params.bufnr, asana_config_filename)
  if not config then
    return
  end

  return AsanaSource:new(config)
end

return M
