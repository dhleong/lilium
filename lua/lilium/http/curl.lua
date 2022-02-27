local a = require'plenary.async'

local command = require'lilium.command'

---@alias Req {url:string, params:{}, headers:{}, json:boolean}

local M = {}

---@param req Req
function M.get(req)
  local args = {
    '--silent', '-X', 'GET',
    '-L', req.url,
  }

  if req.params then
    table.insert(args, '-G')
    for k, v in pairs(req.params) do
      table.insert(args, '--data-urlencode')
      table.insert(args, k .. '=' .. v)
    end
  end

  if req.json then
    table.insert(args, '-H')
    table.insert(args, 'Content-Type: application/json')
  end

  if req.headers then
    for k, v in pairs(req.headers) do
      table.insert(args, '-H')
      table.insert(args, k .. ': ' .. v)
    end
  end

  return command.exec {
    command = 'curl',
    args = args,
  }
end

---@param req Req
function M.get_json(req)
  req.json = true

  local result = M.get(req)
  a.util.scheduler()
  if result then
    return vim.fn.json_decode(result)
  end
end

return M
