local M = {}

---@class MinecraftDev.Config
---@field filetypes string[] filetypes to which jdtls will attach
---@field statusline string? If given statusline will be set with all occurrences of `%f`, `%F`, or `%t` if expanded to a `jdt://` URI will resolve into the fully qualified class name.
---@field quickfixtextfunc boolean If `true` will resolve `jdt://` to the fully qualified class name.
M.options = {
  filetypes = { 'java', 'groovy', 'kotlin', 'jproperties' },
  statusline = nil,
  quickfixtextfunc = true,
}

return M
