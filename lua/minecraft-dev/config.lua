local M = {}

---@class MinecraftDev.Config
---@field filetypes string[] filetypes to which jdtls will attach
---@field statusline string? If given statusline will be set with all occurrences of `%f`, `%F`, or `%t` if expanded to a `jdt://` URI will resolve into the fully qualified class name.
---@field quickfixtextfunc boolean If `true` will resolve `jdt://` to the fully qualified class name.
---@field win_config vim.api.keyset.win_config? If set, asmify() and bytecode() will open in a split window with the provided config.
---@field env table<string,string|number> Set environment variables for launching Minecraft
---@field jdtls_config vim.lsp.Config config passed to jdtls. Default: { cmd = { 'jdtls', '-data', '{root_dir}-{hash}' } }
M.options = {
  filetypes = { 'java', 'groovy', 'kotlin', 'jproperties' },
  statusline = nil,
  quickfixtextfunc = true,
  win_config = nil,
  env = {},
  jdtls_config = {},
}

return M
