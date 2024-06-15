local M = {}

function M.install()
  local configs = require("lspconfig.configs")

  if not configs.lilium then
    local lspconfig = require("lspconfig")
    local plugin_root = vim.fn["lilium#util#path#PluginRoot"]()

    configs.lilium = {
      default_config = {
        cmd = {
          plugin_root .. "/target/debug/lilium",
          "lsp",
        },
        filetypes = { "gitcommit", "markdown" },
        root_dir = function(startpath)
          -- Use the enhanced editor path, if set. This lets us provide LSP completion
          -- to `gh pr` tmp files for the appropriate project!
          local enhanced_editor_path = require("lilium.lsp.enhanced_editor").get_project_path_for_file(startpath)
          return enhanced_editor_path or lspconfig.util.find_git_ancestor(startpath)
        end,
      },
    }
  end
end

function M.setup(opts)
  M.install()
  require("lspconfig").lilium.setup(opts or {})
end

return M
