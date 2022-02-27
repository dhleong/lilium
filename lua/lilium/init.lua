
local M = {}

local can_complete, completer = pcall(require, 'lilium.completer')
M.completer = completer

function M._trigger_completion()
  local ok, cmp = pcall(require, 'cmp')
  if ok then
    cmp.complete()
  end
end

function M.maybe_init_completion()
  if can_complete and require'null-ls'.is_registered('lilium') then
    vim.cmd [[
      inoremap <buffer> # #<cmd>lua require'lilium'._trigger_completion()<cr>
      inoremap <buffer> @ @<cmd>lua require'lilium'._trigger_completion()<cr>
    ]]
  end
end

return M
