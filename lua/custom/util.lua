local M = {}

--- Because most plugins are hosted on GitHub, you can use this helper
--- function to have less repetition when calling `vim.pack.add`.
---@param repo string
---@return string
function M.gh(repo) return 'https://github.com/' .. repo end

return M
