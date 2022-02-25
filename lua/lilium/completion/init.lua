local PrefixedSource = require'lilium.completion.sources.prefixed'

---@alias Ticket {title:string, ref:string}

local M = {}

---@return CompletionSource|nil
function M.create_source(params)
  local asana = require'lilium.completion.sources.asana'.create(params)
  return PrefixedSource:new({'#', '@'}, asana)
end

---@return CompletionSource|nil
function M.get_source(params)
  -- TODO cache sources
  return M.create_source(params)
end

return M
