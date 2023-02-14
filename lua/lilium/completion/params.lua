local M = {}

function M.inflate_params(params)
  if not params.ft then
    params.ft = vim.api.nvim_buf_get_option(params.bufnr, 'filetype')
  end

  if params.ft == 'markdown' then
    -- In markdown files, we might be editing a PR body; in such cases,
    -- we should rely on the lilium project-detected cwd (since the current
    -- cwd is *probably* in some temp directory).
    local ok, project = pcall(vim.api.nvim_buf_get_var, params.bufnr, '_lilium_project')
    if ok and project and project.cwd then
      params.cwd = project.cwd
    end
  end

  if not params.cwd then
    params.cwd = vim.fn.expand('#' .. params.bufnr .. ':p:h')
  end
end

return M
