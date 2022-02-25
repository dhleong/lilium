local loop = require'null-ls.loop'
local a = require'plenary.async'

---@alias Req {url:string, params:{}, headers:{}, json:boolean}

local M = {}

---@param req Req
M.get = a.wrap(function (req, done)
  -- TODO: Plenary's Job causes eslint_d to hang for some reason...
  -- so we use null-ls's job spawning for now.

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

  loop.spawn('curl', args, {
    handler = a.void(function (_, stdout)
      done(stdout)
    end),
  })
end, 2)

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
