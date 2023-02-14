if vim.fn.has('nvim') then
  local ok, null_ls = pcall(require, 'null-ls')
  if ok and vim.g.lilium_enable_source ~= 0 then
    null_ls.enable(require 'lilium.source')
  end

  require 'lilium'.setup_common()
end
