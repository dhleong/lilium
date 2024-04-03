---@class BrowseOpts
---@field commit string
---@field line1 number
---@field line2 number
---@field path string
---@field remote string
---@field type 'blob'

---@param opts BrowseOpts
local function format_user_at_github(opts)
  local _, repo = opts.remote:match("(.-)github[.]com[:/](.+/.-)[.]")
  if not repo then
    return nil
  end

  if opts.type == "blob" then
    -- https://github.com/discord/discord/blob/b001acc4bcff20bc2b4fbf86cc090373b622b9e7/discord_api/discord/modules/content_inventory/models/inbox_v2.py
    local url = table.concat({
      "https://github.com",
      repo,
      "blob",
      opts.commit,
      opts.path,
    }, "/")

    if opts.line1 ~= 0 then
      url = url .. "#L" .. opts.line1
    end

    if opts.line1 ~= opts.line2 then
      url = url .. "-L" .. opts.line2
    end

    return url
  end
end

local formatters = { format_user_at_github }

local M = {}

---@param opts BrowseOpts
function M.handle_browse(opts)
  -- NOTE: We've typed remote to be required for convenience, and we
  -- do a sanity check here to ensure that's "true"
  if opts.remote then
    for _, format in ipairs(formatters) do
      local url = format(opts)
      if url then
        return url
      end
    end
  end
  return ""
end

return M
