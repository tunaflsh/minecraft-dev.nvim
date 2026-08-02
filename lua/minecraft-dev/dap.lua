local cfg = require('minecraft-dev.config')
local util = require('minecraft-dev.util')

local dap = require('dap')

local M = {}

function M.setup()
  dap.adapters['fabric-loom'] = function(callback, config)
    vim.system({ './gradlew', '--console', 'plain', config.taskName, '--debug-jvm' }, {
      env = cfg.options.env,
      cwd = util.find_root(0),
      stdout = function(err, data)
        local port = data and data:match('Listening for transport dt_socket at address: (%d+)')
        if port then
          callback({ type = 'server', port = port })
        end
      end,
    })
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
