---@alias Ticket {title:string, ref:string}

local M = {}

---@return CompletionSource|nil
function M.create_source(params)
  -- TODO
  return require'lilium.completion.sources.dummy'.create(params)
end

---@return CompletionSource|nil
function M.get_source(params)
  -- TODO cache sources
  return M.create_source(params)
end

return M
