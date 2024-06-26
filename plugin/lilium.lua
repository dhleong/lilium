if vim.fn.has("nvim") then
  local ok, _ = pcall(require, "null-ls.helpers")
  if ok and vim.g.lilium_enable_source ~= 0 then
    require("null-ls").enable(require("lilium.source"))
  end

  local is_lazy, _ = pcall(require, "lazy")
  if not is_lazy then
    require("lilium").setup_common()
  end
end
