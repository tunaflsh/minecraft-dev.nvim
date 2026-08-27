local cfg = require('minecraft-dev.config')
local util = require('minecraft-dev.util')
local dap = require('minecraft-dev.dap')

local jdtls = require('jdtls')

local M = {}

---@param opts MinecraftDev.Config
function M.setup(opts)
  cfg.options = vim.tbl_deep_extend('force', cfg.options, opts or {})

  if cfg.options.statusline then
    vim.o.statusline = cfg.options.statusline:gsub('%%[fFt]', "%%{v:lua.require('minecraft-dev').format_fname('%0')}")
  end

  if cfg.options.quickfixtextfunc then
    _G.mcqftf = M.quickfixtextfunc
    vim.o.quickfixtextfunc = "v:lua.mcqftf"
  end

  dap.setup()

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('minecraft-dev', { clear = true }),
    pattern = cfg.options.filetypes,
    callback = function(a)
      local root_dir = util.find_root(a.buf)
      if root_dir then
        local project_dir = vim.fn.fnamemodify(root_dir, ':t')
        local hash = vim.fn.sha256(root_dir):sub(1, 16)
        local config = vim.deepcopy(cfg.options.jdtls_config)
        if type(config.cmd) == 'table' then
          vim.list_extend(config.cmd, { '-data', vim.fn.stdpath('cache') .. '/jdtls/' .. project_dir .. '-' .. hash })
        end
        jdtls.start_or_attach(config)
      end
    end,
  })
end

---@param fname string `jdt://` URI or `%f`, `%F`, `%t`
---@return string classname resolved from `jdt://` URI
function M.format_fname(fname)
  if fname == '%f' then
    fname = vim.fn.expand("%")
  elseif fname == '%F' then
    fname = vim.fn.expand("%:p")
  elseif fname == '%t' then
    fname = vim.fn.expand("%:t")
  end
  local fullname = vim.fn.fnamemodify(fname, ':p')
  return fullname:match('^jdt://.*/([^/]*/[^/]*)?=')
      or fullname:match('^%w+://.*')
      or fullname:match('java/(.*%.java)$')
      or fullname:match('java/(.*%.class)$')
      or fname
end

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
    local fname = M.format_fname(vim.fn.bufname(item.bufnr))
    local lnum = item.lnum or ''
    local col = item.col or ''
    local text = vim.trim(item.text or '')
    table.insert(lines, ('%s|%s col %s| %s'):format(fname, lnum, col, text))
  end

  return lines
end

---View ASM API calls
---@type function
M.asmify = util.asm('asmify', 'org.objectweb.asm.util.ASMifier', 'java')

---View bytecode
---@type function
M.bytecode = util.asm('bytecode', 'org.objectweb.asm.util.Textifier', 'asm-java')

M.setup_new_project = function()
  local root_dir = util.find_root(0)
  if root_dir then
    local args = { "./gradlew", "genSources" }
    vim.system(args, { cwd = root_dir, text = true, }, function(obj)
      if obj.code ~= 0 then
        vim.schedule_wrap(vim.notify)(table.concat(args, " ") .. "\n" .. obj.stderr, vim.log.levels.ERROR)
        return
      end
      args = { "./gradlew", "eclipse" }
      local obj = vim.system(args, { cwd = root_dir, text = true }):wait()
      if obj.code ~= 0 then
        vim.schedule_wrap(vim.notify)(table.concat(args, " ") .. "\n" .. obj.stderr, vim.log.levels.ERROR)
      end
    end)
  end
end

return M
