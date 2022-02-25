---@alias Ticket {title:string, ref:string}

local M = {}

---@return CompletionSource
function M.create_source(_)
  -- TODO
  return require'lilium.completion.sources.dummy'
end

---@return CompletionSource
function M.get_source(params)
  -- TODO cache sources
  return M.create_source(params)
end

return M
