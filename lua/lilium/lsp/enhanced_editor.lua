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
  M._paths[config.path] = config.project
end

return M
