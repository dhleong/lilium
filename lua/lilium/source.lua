local null_ls = require'null-ls'

return {
  method = null_ls.methods.COMPLETION,
  filetypes = { 'gitcommit' },
}

