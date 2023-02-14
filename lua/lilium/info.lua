local async = require 'lilium.async'

local plenary_ok, plenary = pcall(require, 'plenary.window.float')
local _, a = pcall(require, 'plenary.async')

local M = {}

function M._create(opts)
  local float = plenary.centered {
    winblend = 0,
  }
  float.source_bufnr = opts.source_bufnr

  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = float.bufnr,
    once = true,
    callback = function()
      M._active_float = nil
    end,
  })

  vim.api.nvim_buf_set_option(float.bufnr, 'filetype', 'markdown')

  return float
end

function M._refresh()
  local float = M._active_float
  if not float then
    return
  end

  a.run(function()
    local params = { bufnr = float.source_bufnr }
    require 'lilium.completion.params'.inflate_params(params)

    local factory = require 'lilium.completion'.create_composite_factory()
    local composite = factory:create(params)
    if not composite then
      a.util.scheduler()
      M._state = { status = 'unavailable' }
      M._mount()
      return
    end

    M._refresh_sources(factory, composite)

    M._state.status = 'done'
    M._mount()
  end)
end

function M._refresh_sources(factory, composite)
  local state = { status = 'loading', sources = {} }
  M._state = state
  M._mount()

  -- Prepare initial state; composite only has successfully inflated sources
  for _, module_name in ipairs(factory.modules) do
    state.sources[module_name] = { name = module_name, status = 'Unavailable in buffer' }
  end
  for _, source in ipairs(composite.sources) do
    state.sources[source.module].status = 'loading'
  end
  M._mount()

  -- Load state for each source in parallel
  local futures = async.futures_map(function(source)
    local source_state = source:describe_state()
    a.util.scheduler()
    state.sources[source.module].name = source.name
    state.sources[source.module].state = source_state
    state.sources[source.module].status = 'done'
    M._mount()
  end, composite.sources)
  async.await_all(futures)
end

function M._render()
  local lines = { '', '# lilium', '' }

  if M._state and M._state.sources then
    for name, source in pairs(M._state.sources) do
      table.insert(lines, '## ' .. source.name or name)
      table.insert(lines, '')
      if source.status == 'done' then
        vim.list_extend(lines, source.state)
      else
        table.insert(lines, '`' .. source.status .. '`')
      end
      table.insert(lines, '')
      table.insert(lines, '')
    end
  end

  return vim.tbl_map(function(line)
    return '  ' .. line
  end, lines)
end

function M._mount()
  local float = M._active_float
  if float then
    local lines = M._render()
    vim.api.nvim_buf_set_lines(float.bufnr, 0, -1, false, lines)
  end
end

function M.is_available()
  return plenary_ok
end

function M.open()
  local bufnr = vim.fn.bufnr('%')
  if not M._active_float then
    M._active_float = M._create { source_bufnr = bufnr }
    M._refresh()
  end

  M._mount()
end

return M
