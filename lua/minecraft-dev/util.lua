local cfg = require('minecraft-dev.config')

local dap = require('dap')
local jdtls_util = require('jdtls.util')

local M = {}

---@param bufnr number
---@return string? root_dir
function M.find_root(bufnr)
  return vim.fs.root(bufnr, {
    { "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts" },
    { "build.xml", "pom.xml", "build.gradle", "build.gradle.kts" },
  }) or nil
end

---@param name string
---@param mainClass 'org.objectweb.asm.util.ASMifier'|'org.objectweb.asm.util.Textifier'
---@param filetype 'java'|'asm-java'
---@return function dumper
function M.asm(name, mainClass, filetype)
  dap.listeners.after.event_output['minecraft-dev.' .. name] = function(session, response)
    if name == session.config.name then
      local buf = vim.fn.bufnr('[' .. session.config.name .. '] ' .. session.config.args, 1)
      local lines = vim.split(response.output, '\n')
      lines[1] = vim.api.nvim_buf_get_lines(buf, -2, -1, false)[1] .. lines[1]

      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, -2, -1, false, lines)
      vim.bo[buf].modifiable = false
    end
  end

  return function()
    local classname = (
      vim.fn.bufname():match('^jdt://.*/([^/]*/[^/]*)?=')
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
    vim.bo[buf].filetype = filetype

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

return M
