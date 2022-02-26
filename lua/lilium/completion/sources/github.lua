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

function GithubSource:gather_completions(params)
  local cwd = vim.fn.expand('#' .. params.bufnr .. ':h')
  if params.prefix == '#' then
    -- TODO
    local output = command.exec_json {
      command = 'gh',
      args = { 'issue', 'list', '--json', 'number,title' },
      cwd = cwd,
    }
    if output then
      return vim.tbl_map(format_issue, output)
    end
  end
end

---@class GithubSourceFactory : CompletionSourceFactory
local M = {}

---@param params Params
function M.create(params)
  local repo_url = command.exec {
    command = 'gh',
    args = { 'browse', '--no-browser' },
    cwd = params.bufname,
  }

  if repo_url then
    return GithubSource:new {}
  end
end

return M
