local plenary_ok, plenary = pcall(require, "plenary.window.float")

---@class Window
---@field _bufnr number|nil
---@field _render fun(): string[]
local Window = {}

function Window:_mount()
  local bufnr = self._bufnr
  if bufnr then
    local lines = self._render()

    local to_render = vim.tbl_map(function(line)
      return "  " .. line
    end, lines)

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, to_render)
  end
end

---@param params {filetype: string|nil, render: fun(): string[]}
function Window:open(params)
  if not plenary_ok then
    error("Missing dependency: plenary")
  end

  local source_bufnr = vim.fn.bufnr("%")
  local float = plenary.centered({
    winblend = 0,
  })

  local obj = {
    source_bufnr = source_bufnr,
    _bufnr = float.bufnr,
    _render = params.render,
  }

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = float.bufnr,
    once = true,
    callback = function()
      obj._bufnr = nil
    end,
  })

  vim.api.nvim_set_option_value("filetype", params.filetype or "markdown", {
    buf = float.bufnr,
  })

  setmetatable(obj, self)
  self.__index = self

  obj:refresh()
  return obj
end

function Window:refresh()
  self:_mount()
end

return Window
