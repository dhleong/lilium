local h = require'null-ls.helpers'
local methods = require'null-ls.methods'

local COMPLETION = methods.internal.COMPLETION

---@param ticket Ticket
local function create_item(ticket)
  return {
    insertText = ticket.ref,
    kind = vim.lsp.protocol.CompletionItemKind["Text"],
    label = ticket.title,
  }
end

return h.make_builtin{
  name = 'lilium',
  method = COMPLETION,
  filetypes = { 'gitcommit' },
  generator = {
    fn = function(params, done)
      local source = require'lilium.completion'.get_source(params)
      local completions = source:gather_completions(params)

      local items = {}
      for i, v in ipairs(completions) do
        items[i] = create_item(v)
      end

      done{ { items = items, isIncomplete = false } }
    end,
    async = true,
  },
}
