local M = {
  _paths = {},
}

---@param path string
function M.get_project_path_for_file(path)
  local project = M._paths[path]
  if project then
    return project.cwd
  end
end

---@param config {path: string, project: {cwd: string}}
function M.prepare(config)
  -- NOTE: config.path might not be the canonical path (esp on macOS)
  -- which would prevent us from looking in the right place when calling
  -- `get_project_path_for_file`. Using resolve() seems to fix this.
  local path = vim.fn.resolve(config.path)
  M._paths[path] = config.project
end

return M
