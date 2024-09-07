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

-- NOTE: We don't have any options... yet
---@alias LiliumLspConfig {}

---@class LiliumConfig
local DEFAULT_CONFIG = {
  ---@type LiliumLspConfig|nil
  setup_lsp = nil,

  ---@deprecated
  install_fugitive_browse = false,
}

---@param config LiliumConfig
function M.setup(config)
  config = vim.tbl_deep_extend("force", DEFAULT_CONFIG, config)

  -- You're either lsp or common; not both
  if config.setup_lsp then
    M._lsp_config = config.setup_lsp
    require("lilium.lsp").setup(config.setup_lsp)
  else
    M.setup_common()
  end

  -- We can probably still provide this if requested in lsp mode
  -- (although we can probably deprecate in favor of rhubarb since
  -- actually rhubarb worked just fine)
  ---@diagnostic disable-next-line: deprecated
  if config.install_fugitive_browse then
    print("[lilium] install_fugitive_browse has been removed in favor of rhubarb")
  end
end

return M
