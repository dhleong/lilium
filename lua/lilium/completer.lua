local h = require'null-ls.helpers'
local methods = require'null-ls.methods'
local a = require'plenary.async'

local COMPLETION = methods.internal.COMPLETION

---@param ticket Ticket
local function create_item(ticket)
  return {
    insertText = ticket.ref,
    kind = vim.lsp.protocol.CompletionItemKind.Text,
    label = ticket.title,

    textEdit = ticket.textEdit,
  }
end

return h.make_builtin{
  name = 'lilium',
  method = COMPLETION,
  filetypes = { 'gitcommit', 'markdown' },
  generator = {
    fn = function(params, done)
      if params.ft == 'markdown' then
        -- In markdown files, we might be editing a PR body; in such cases,
        -- we should rely on the lilium project-detected cwd (since the current
        -- cwd is *probably* in some temp directory).
        local project = vim.api.nvim_buf_get_var(params.bufnr, '_lilium_project')
        if project and project.cwd then
          params.cwd = project.cwd
        end
      end

      if not params.cwd then
        params.cwd = vim.fn.expand('#' .. params.bufnr .. ':p:h')
      end

      a.run(function ()
        local items = {}
        local source = require'lilium.completion'.get_source(params)

        if source then
          a.util.scheduler()

          local completions = source:gather_completions(params)
          if completions then
            items = vim.tbl_map(create_item, completions)
          end
        end

        done{ { items = items, isIncomplete = #items == 0 } }
      end)
    end,
    async = true,
  },
}
