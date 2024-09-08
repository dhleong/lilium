local Window = require("lilium.window")
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

function M.lilium_info()
  local output = {
    "# Lilium",
    "",
    "Loading...",
  }
  local function render()
    return output
  end

  local bufnr = vim.fn.bufnr("%")
  local info_window = Window:open({ render = render })

  vim.lsp.buf_request(bufnr, "workspace/executeCommand", {
    command = "lilium.info",
    arguments = {
      vim.uri_from_bufnr(bufnr),
    },
  }, function(err, result)
    if err then
      output = { "# Lilium: Error", "", vim.inspect(err) }
    elseif type(result) == "string" then
      output = {
        "# Lilium",
        "",
        unpack(vim.fn.split(result, "\n")),
      }
    else
      output = { "unexpected response type: " .. type(result) }
    end
    info_window:refresh()
  end)
end

function M.setup(opts)
  M.install()

  opts = opts or {}
  local user_on_attach = opts.on_attach
  opts.on_attach = function(client, bufnr)
    if user_on_attach then
      user_on_attach(client, bufnr)
    end

    if client.name == "lilium" then
      vim.api.nvim_buf_create_user_command(bufnr, "LiliumInfo", M.lilium_info, {
        desc = "Lilium Info",
      })
    end
  end

  require("lspconfig").lilium.setup(opts)
end

return M
