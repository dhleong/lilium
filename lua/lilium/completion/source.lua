---@alias Params {bufnr:number, bufname:string, cwd:string}
---@alias Ticket {title:string, ref:string, textEdit:string|nil}

---@class CompletionSource
---@field name string
local CompletionSource = {}

---@return string[]|nil
function CompletionSource:describe_state()
  return {}
end

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
