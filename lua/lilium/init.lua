local M = {
  _installed_browse_handler = nil,
}

local can_complete, completer = pcall(require, "lilium.completer")
M.completer = completer

function M._trigger_completion()
  local ok, cmp = pcall(require, "cmp")
  if ok then
    cmp.complete()
  end
end

function M.maybe_init_completion()
  if can_complete and require("null-ls").is_registered("lilium") then
    vim.cmd([[
      inoremap <buffer> # #<cmd>lua require'lilium'._trigger_completion()<cr>
      inoremap <buffer> @ @<cmd>lua require'lilium'._trigger_completion()<cr>
    ]])
  end
end

function M.setup_common()
  if vim.api.nvim_create_user_command and require("lilium.info").is_available() then
    vim.api.nvim_create_user_command("LiliumInfo", function()
      require("lilium.info").open()
    end, {})
  end
end

---@class LiliumConfig
local DEFAULT_CONFIG = {
  install_fugitive_browse = true,
}

---@param config LiliumConfig
function M.setup(config)
  config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, config)
  M.setup_common()

  if config.install_fugitive_browse then
    local f = require("lilium.browse").handle_browse
    M._installed_browse_handler = f

    local handlers = (vim.g.fugitive_browse_handlers or {})
    handlers[#handlers + 1] = f
    vim.g.fugitive_browse_handlers = handlers
  end
end

function M.deactivate()
  if M._installed_browse_handler then
    local handlers = (vim.g.fugitive_browse_handlers or {})
    for i, f in ipairs(handlers) do
      if f == M._installed_browse_handler then
        table.remove(handlers, i)
        vim.g.fugitive_browse_handlers = handlers
        break
      end
    end
  end
end

return M
