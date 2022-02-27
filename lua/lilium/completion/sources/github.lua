local async = require'lilium.async'
local command = require'lilium.command'

local function format_issue(issue)
  return {
    title = issue.title,
    ref = '#' .. issue.number,
  }
end

---@alias GithubConfig {token:string, workspace:string}

---@class GithubSource : CompletionSource
---@field config GithubConfig
local GithubSource = {}

function GithubSource:new(config)
  local obj = { config = config }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function GithubSource:_list(type)
  local output = command.exec_json {
    command = 'gh',
    args = { type, 'list', '--json', 'number,title' },
    cwd = self.config.cwd,
  }
  return output or {}
end

function GithubSource:gather_completions(params)
  if params.prefix == '#' then
    local output = async.await_all_concat {
      function() return self:_list('issue') end,
      function() return self:_list('pr') end,
    }

    return vim.tbl_map(format_issue, output)
  end
end

---@class GithubSourceFactory : CompletionSourceFactory
local M = {
  name = 'github',
}

---@param params Params
function M.create(params)
  local cwd = vim.fn.expand('#' .. params.bufnr .. ':p:h')
  local repo_url = command.exec {
    command = 'gh',
    args = { 'browse', '--no-browser' },
    cwd = cwd,
  }

  if repo_url then
    return GithubSource:new { cwd = cwd }
  end
end

return M
