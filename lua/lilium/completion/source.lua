---@alias Params {bufnr:number, bufname:string}

---@class CompletionSource
local CompletionSource = {}

---@return Ticket[]
function CompletionSource:gather_completions(_)
  return {}
end

---@class CompletionSourceFactory
local CompletionSourceFactory = {}

---@param _ Params
---@return CompletionSource|nil
function CompletionSourceFactory.create(_)
end