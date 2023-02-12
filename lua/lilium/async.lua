local a = require 'plenary.async'

local M = {}

function M.main_thread()
  a.util.scheduler()
end

-- Given a coroutine function `f` and list of `items`, - return a list of
-- "futures", created by calling `f` with - each item in `items`. This is
-- basically just a convenience around vim.tbl_map
function M.futures_map(f, items)
  return vim.tbl_map(function(item)
    return function()
      return f(item)
    end
  end, items)
end

-- Given a list of "futures" (a function that might be a coroutine), asynchronously
-- wait for them all the complete, returning a list of the resolved values of each
-- future, in the same order they were given.
function M.await_all(futures)
  if vim.tbl_isempty(futures) then
    return {}
  end

  local results = a.util.join(futures)

  -- It's unclear why, but each `result` is wrapped in a list...
  local output = {}
  for _, result in ipairs(results) do
    table.insert(output, result[1])
  end

  return output
end

function M.await_all_concat(futures)
  local results = M.await_all(futures)

  local output = {}
  for _, result_set in ipairs(results) do
    vim.list_extend(output, result_set)
  end

  return output
end

return M
