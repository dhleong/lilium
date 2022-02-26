local loop = require'null-ls.loop'
local a = require'plenary.async'

local M = {}

---@alias ExecArgs {command:string, args:string[], cwd:string}

---@type fun(args:ExecArgs):string
M.exec = a.wrap(function (args, done)
  -- TODO: Plenary's Job causes eslint_d to hang for some reason...
  -- so we use null-ls's job spawning for now.
  loop.spawn(args.command, args.args, {
    cwd = args.cwd,
    handler = a.void(function (_, stdout)
      done(stdout)
    end),
  })
end, 2)

---@param args ExecArgs
function M.exec_json(args)
  local output = M.exec(args)

  if output then
    a.util.scheduler()
    return vim.fn.json_decode(output)
  end
end

return M
