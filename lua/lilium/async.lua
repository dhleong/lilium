local a = require'plenary.async'

local M = {}

function M.main_thread()
  a.util.scheduler()
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
  for i, result in ipairs(results) do
    output[i] = result[1]
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
