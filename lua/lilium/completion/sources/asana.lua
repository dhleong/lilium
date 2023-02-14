local fs = require 'lilium.fs'
local http = require 'lilium.http'

local asana_config_filename = '.lilium.asana.json'
local api_base = 'https://app.asana.com/api/1.0'
local issue_url_base = 'https://app.asana.com/0/0/'

local typeahead_by_prefix = {
  ['#'] = {
    type = 'task',
    format = function(task)
      return {
        title = task.name,
        ref = issue_url_base .. task.gid,
      }
    end,
  },
}

---@alias AsanaConfig {token:string, workspace:string}

---@class AsanaSource : CompletionSource
---@field config AsanaConfig
local AsanaSource = {}

function AsanaSource:new(config)
  local obj = { name = 'Asana', config = config }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function AsanaSource:_get_json(opts)
  local response = http.get_json {
    url = api_base .. opts.path,
    params = opts.params,
    headers = {
      authorization = 'Bearer ' .. self.config.token,
    },
  }

  if response then
    return response.data
  end
end

---@param type 'user'|'task'
function AsanaSource:_typeahead(type)
  return self:_get_json {
    path = '/workspaces/' .. self.config.workspace .. '/typeahead',
    params = {
      resource_type = type,
    }
  }
end

function AsanaSource:describe_state()
  local user = self:_get_json {
    path = '/users/me',
  }

  if user then
    return { 'Signed in as: *' .. user.email .. '*.' }
  else
    return { 'Signed out; update credentials in ' .. asana_config_filename }
  end
end

function AsanaSource:gather_completions(params)
  local typeahead = typeahead_by_prefix[params.prefix]
  if typeahead then
    local tasks = self:_typeahead(typeahead.type)
    if tasks then
      return vim.tbl_map(typeahead.format, tasks)
    end
  end
end

---@class AsanaSourceFactory : CompletionSourceFactory
local M = {
  name = 'asana',
}

---@param params Params
function M.create(params)
  local config = fs.find_json(params, asana_config_filename)
  if not config then
    return
  end

  return AsanaSource:new(config)
end

return M
