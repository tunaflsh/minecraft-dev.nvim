local cfg = require('minecraft-dev.config')

local M = {}

---@param opts MinecraftDev.Config
function M.setup(opts)
  cfg.options = vim.tbl_deep_extend('force', cfg.options, opts or {})

  if cfg.options.statusline then
    vim.o.statusline = cfg.options.statusline:gsub('%%[fFt]', "%%{v:lua.require('minecraft-dev').format_jdt('%0')}")
  end

  if cfg.options.quickfixtextfunc then
    vim.o.quickfixtextfunc = "v:lua.require('minecraft-dev').quickfixtextfunc"
  end
end

---@param fname string `jdt://` URI or `%f`, `%F`, `%t`
---@return string classname resolved from `jdt://` URI
function M.format_jdt(fname)
  if fname == '%f' then
    fname = vim.fn.expand("%")
  elseif fname == '%F' then
    fname = vim.fn.expand("%:p")
  elseif fname == '%t' then
    fname = vim.fn.expand("%:t")
  end
  return fname:match('^jdt://.*/([^/]*/[^/]*)?=') or fname
end

---@class quickfixtextfunc.arg
---@field quickfix 0 | 1 set to 1 when called for a quickfix list and 0 when called for a location list.
---@field winid number for a location list, set to the id of the window with the location list.  For a quickfix list, set to 0.  Can be used in getloclist() to get the location list entry.
---@field id number quickfix or location list identifier
---@field start_idx number index of the first entry for which text should be returned
---@field end_idx number index of the last entry for which text should be returned

---@param arg quickfixtextfunc.arg
function M.quickfixtextfunc(arg)
  local items
  if arg.quickfix == 1 then
    items = vim.fn.getqflist({ id = arg.id, items = 1 }).items
  else
    items = vim.fn.getloclist(arg.winid, { id = arg.id, items = 1 }).items
  end

  local lines = {}
  for i = arg.start_idx, arg.end_idx do
    local item = items[i]
    local fname = M.format_jdt(vim.fn.bufname(item.bufnr))
    local lnum = item.lnum or ''
    local col = item.col or ''
    local text = vim.trim(item.text or '')
    table.insert(lines, ('%s|%s col %s| %s'):format(fname, lnum, col, text))
  end

  return lines
end

return M
