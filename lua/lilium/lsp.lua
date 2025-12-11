local Window = require("lilium.window")
local M = {}

local function build_config()
  local plugin_root = vim.fn["lilium#util#path#PluginRoot"]()

  return {
    cmd = {
      plugin_root .. "/target/debug/lilium",
      "lsp",
    },
    filetypes = { "gitcommit", "markdown" },
    root_dir = function(startpath, on_dir)
      -- Possibly unncessary backwards compat:
      if not on_dir then
        on_dir = function(dir)
          return dir
        end
      end
      if type(startpath) == "number" then
        startpath = vim.fn.expand("#" .. startpath .. ":p")
      end

      -- Use the enhanced editor path, if set. This lets us provide LSP completion
      -- to `gh pr` tmp files for the appropriate project!
      local enhanced_editor_path = require("lilium.lsp.enhanced_editor").get_project_path_for_file(startpath)
      if enhanced_editor_path then
        return on_dir(enhanced_editor_path)
      end

      local git_dir = vim.fs.dirname(vim.fs.find(".git", { path = startpath, upward = true })[1])
      return on_dir(git_dir)
    end,
  }
end

function M.install_legacy(opts)
  local configs = require("lspconfig.configs")
  if not configs.lilium then
    configs.lilium = {
      default_config = build_config(),
    }
  end

  opts = opts or {}

  require("lspconfig").lilium.setup(opts)
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
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lilium_lsp", { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client and client.name == "lilium" then
        vim.api.nvim_buf_create_user_command(ev.buf, "LiliumInfo", M.lilium_info, {
          desc = "Lilium Info",
        })
      end
    end,
  })

  if not vim.lsp or not vim.lsp.config then
    M.install_legacy(opts)
  else
    vim.lsp.config("lilium", build_config())
    vim.lsp.enable("lilium")
  end
end

return M
