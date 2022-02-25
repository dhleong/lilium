local PrefixedSource = {}

function PrefixedSource:new(prefixes, delegate)
  local obj = {
    prefixes = prefixes,
    delegate = delegate,
  }

  setmetatable(obj, self)
  self.__index = self

  return obj
end

function PrefixedSource:_handle_prefix(params, tickets)
  if not tickets then
    return
  end

  return vim.tbl_map(function (ticket)
    -- If the replacement doesn't include the prefix, delete the prefix!
    local replacement = ticket.ref or ticket.title

    if params.prefix and
      string.sub(replacement, 1, #params.prefix) ~= params.prefix and
      #params.word_to_complete == 0
    then
      ticket.textEdit = {
        range = {
          start = {
            line = params.row - 1,
            character = params.col - #params.word_to_complete - #params.prefix,
          },
          ['end'] = {
            line = params.row - 1,
            character = params.col,
          },
        },
        newText = replacement,
      }
    end

    return ticket
  end, tickets)
end

function PrefixedSource:gather_completions(params)
  local prefix_col = params.col - #params.word_to_complete
  local line = params.content[params.row]

  for _, prefix in ipairs(self.prefixes) do
    local prefix_len = #prefix
    local actual_prefix = string.sub(line, prefix_col - prefix_len + 1, prefix_col)
    if actual_prefix == prefix then
      params.prefix = actual_prefix
      return self:_handle_prefix(params, self.delegate:gather_completions(params))
    end
  end
end

return PrefixedSource
