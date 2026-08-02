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

  local dap_ok, dap = pcall(require, 'dap')
  local jdtls_ok, jdtls = pcall(require, 'jdtls')
  local _, jdtls_util = pcall(require, 'jdtls.util')

  if not dap_ok or not jdtls_ok then
    return
  end

  ---@return ASMutil
  local function asm_util(mainClass, name)
    return function()
      local classname = (
        M.format_jdt(vim.fn.bufname(), true)
        or jdtls_util.resolve_classname()
      ):gsub('/', '.'):gsub('%.java$', ''):gsub('%.class$', '')

      dap.run({
        type = 'java',
        request = 'launch',
        console = 'internalConsole',
        mainClass = mainClass,
        name = name,
        args = classname,
      })

      local buf = vim.fn.bufnr('[' .. name .. '] ' .. classname, 1)
      vim.bo[buf].buflisted = true
      vim.bo[buf].buftype = 'nofile'
      vim.bo[buf].filetype = name == 'bytecode' and 'asm-java' or 'java'

      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
      vim.bo[buf].modifiable = false

      local win = vim.fn.bufwinid(buf)
      if not cfg.options.win_config then
        vim.api.nvim_win_set_buf(0, buf)
      elseif win ~= -1 then
        vim.api.nvim_win_set_buf(win, buf)
      else
        vim.api.nvim_open_win(buf, dap.defaults.fallback.focus_terminal, cfg.options.win_config)
      end
    end
  end

  dap.listeners.after.event_output.minecraftdev = function(session, response)
    if vim.list_contains({ 'asmify', 'bytecode' }, session.config.name) then
      local buf = vim.fn.bufnr('[' .. session.config.name .. '] ' .. session.config.args, 1)
      local lines = vim.split(response.output, '\n')
      lines[1] = vim.api.nvim_buf_get_lines(buf, -2, -1, false)[1] .. lines[1]

      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, -2, -1, false, lines)
      vim.bo[buf].modifiable = false
    end
  end

  M.asmify = asm_util('org.objectweb.asm.util.ASMifier', 'asmify')
  M.bytecode = asm_util('org.objectweb.asm.util.Textifier', 'bytecode')

  vim.api.nvim_create_autocmd('FileType', {
    pattern = cfg.options.filetypes,
    callback = function(a)
      local root_dir = vim.fs.root(a.buf, {
        { "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts", ".git" },
        { "build.xml", "pom.xml", "build.gradle", "build.gradle.kts" },
      }) or vim.uv.cwd() or ''
      local project_dir = vim.fn.fnamemodify(root_dir, ':t')
      local hash = vim.fn.sha256(root_dir):sub(1, 16)
      local config = vim.deepcopy(cfg.options.jdtls_config)
      if type(config.cmd) == 'table' then
        vim.list_extend(config.cmd, { '-data', vim.fn.stdpath('cache') .. '/jdtls/' .. project_dir .. '-' .. hash })
      end
      jdtls.start_or_attach(config)
    end,
  })
end

---@param fname string `jdt://` URI or `%f`, `%F`, `%t`
---@param strict boolean? if `true` return nil when not a `jdt://` URI
---@return string classname resolved from `jdt://` URI
function M.format_jdt(fname, strict)
  if fname == '%f' then
    fname = vim.fn.expand("%")
  elseif fname == '%F' then
    fname = vim.fn.expand("%:p")
  elseif fname == '%t' then
    fname = vim.fn.expand("%:t")
  end
  local match = fname:match('^jdt://.*/([^/]*/[^/]*)?=')
  return match or not strict and fname or nil
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

---@alias ASMutil function

---View ASM API calls
---@type ASMutil
function M.asmify() end

---View bytecode
---@type ASMutil
function M.bytecode() end

return M
