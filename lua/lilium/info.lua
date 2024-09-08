local async = require("lilium.async")
local Window = require("lilium.window")

local plenary_ok, a = pcall(require, "plenary.async")

local M = {}

function M._refresh()
  local float = M._active_float
  if not float then
    return
  end

  a.run(function()
    local params = { bufnr = float.source_bufnr }
    require("lilium.completion.params").inflate_params(params)

    local factory = require("lilium.completion").create_composite_factory()
    local composite = factory:create(params)
    if not composite then
      a.util.scheduler()
      M._state = { status = "unavailable" }
      M._mount()
      return
    end

    M._refresh_sources(factory, composite)

    M._state.status = "done"
    M._mount()
  end)
end

function M._refresh_sources(factory, composite)
  local state = { status = "loading", sources = {} }
  M._state = state
  M._mount()

  -- Prepare initial state; composite only has successfully inflated sources
  for _, module_name in ipairs(factory.modules) do
    state.sources[module_name] = { name = module_name, status = "Unavailable in buffer" }
  end
  for _, source in ipairs(composite.sources) do
    state.sources[source.module].status = "loading"
  end
  M._mount()

  -- Load state for each source in parallel
  local futures = async.futures_map(function(source)
    local source_state = source:describe_state()
    a.util.scheduler()
    state.sources[source.module].name = source.name
    state.sources[source.module].state = source_state
    state.sources[source.module].status = "done"
    M._mount()
  end, composite.sources)
  async.await_all(futures)
end

function M._render()
  local lines = { "", "# lilium", "" }

  if M._state and M._state.sources then
    for name, source in pairs(M._state.sources) do
      table.insert(lines, "## " .. source.name or name)
      table.insert(lines, "")
      if source.status == "done" then
        vim.list_extend(lines, source.state)
      else
        table.insert(lines, "`" .. source.status .. "`")
      end
      table.insert(lines, "")
      table.insert(lines, "")
    end
  end

  return lines
end

function M._mount()
  local float = M._active_float
  if float then
    float:refresh()
  end
end

function M.is_available()
  return plenary_ok
end

function M.open()
  if not M._active_float then
    M._active_float = Window:open({ render = M._render })
    M._refresh()
  end

  M._mount()
end

return M
