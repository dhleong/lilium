local M = {}

function M.install()
  local configs = require("lspconfig.configs")

  if not configs.lilium then
    local lspconfig = require("lspconfig")
    local plugin_root = vim.fn["lilium#util#path#PluginRoot"]()

    configs.lilium = {
      default_config = {
        cmd = {
          plugin_root .. "/target/debug/lilium-lsp",
        },
        filetypes = { "gitcommit", "markdown" },
        root_dir = lspconfig.util.find_git_ancestor,
      },
    }
  end
end

function M.setup(opts)
  M.install()
  require("lspconfig").lilium.setup(opts or {})
end

return M
