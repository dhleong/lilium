local a = require'plenary.async'
local Path = require'plenary.path'

local read_path = a.wrap(function(path, callback)
  if not path:exists() then
    callback(nil)
    return
  end
  path:read(callback)
end, 2)

local M = {}

---@param bufnr number
---@param filename string
function M.find_config(bufnr, filename)
  local path = Path:new(vim.fn.fnamemodify('#' .. bufnr, ':p:h'))
  for _, parent in ipairs(path:parents()) do
    local read = read_path(Path:new(parent) / filename)
    if read then
      return read
    end
  end
end

---@param bufnr number
---@param filename string
function M.find_json(bufnr, filename)
  local text = M.find_config(bufnr, filename)
  if text then
    a.util.scheduler()
    return vim.fn.json_decode(text)
  end
end

return M
