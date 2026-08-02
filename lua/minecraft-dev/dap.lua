local cfg = require('minecraft-dev.config')
local util = require('minecraft-dev.util')

local dap = require('dap')

local M = {}

function M.setup()
  dap.adapters['fabric-loom'] = function(callback, config)
    local root_dir = util.find_root(0)

    local name = '[minecraft-dev] ' .. config.taskName
    local buf = vim.fn.bufnr(name, 1)
    local old_win = vim.api.nvim_get_current_win()
    local win = vim.iter(vim.api.nvim_list_wins())
        :find(function(winid)
          return vim.startswith(vim.fn.bufname(vim.api.nvim_win_get_buf(winid)), '[minecraft-dev] ')
        end)

    if win then
      vim.api.nvim_set_current_win(win)
    else
      if cfg.options.win_config then
        win = vim.api.nvim_open_win(buf, true, cfg.options.win_config)
      else
        win = old_win
      end
      vim.api.nvim_win_set_buf(win, buf)
    end

    local last = ''
    local chan_id = vim.fn.jobstart({ './gradlew', '--console', 'colored', config.taskName, '--debug-jvm' }, {
      env = cfg.options.env,
      cwd = root_dir,
      stdout_buffered = false,
      on_stdout = function(chan_id, data, name)
        for _, line in ipairs(data) do
          line = last .. line
          local port = line:match('Listening for transport dt_socket at address: (%d+)')
          if port then
            config.request = 'attach'
            config.port = port
            config.cwd = root_dir
            dap.adapters.java(callback, config)
          elseif not line:match('\r$') and not line:match('\n$') then
            last = line
          end
        end
      end,
      term = true,
    })

    if chan_id == 0 then
      vim.notify('Could not start fabric-loom debugee: invalid arguments')
    elseif chan_id == -1 then
      vim.notify('Could not start fabric-loom debugee: ./gradlew is not executable')
    else
      vim.api.nvim_buf_set_name(buf, name)
      if not dap.defaults.fallback.focus_terminal then
        vim.api.nvim_set_current_win(old_win)
      end
    end
  end

  dap.providers.configs['minecraft-dev'] = function(bufnr)
    if not vim.list_contains(cfg.options.filetypes, vim.bo[bufnr].filetype) then
      return {}
    end

    local launch, errmsg = io.open(util.find_root(bufnr) .. '/.nvim/launch.json', "r")
    if not launch then
      vim.notify(errmsg, vim.log.levels.WARN)
      return {}
    end

    local object = vim.json.decode(launch:read("*a"), {
      luanil = { object = true, array = true },
    })
    launch:close()

    return object.configurations or {}
  end

  for _, filetype in ipairs(cfg.options.filetypes) do
    dap.configurations[filetype] = dap.configurations[filetype] or {}
  end
end

return M
