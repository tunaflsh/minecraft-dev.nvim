local cfg = require('minecraft-dev.config')
local util = require('minecraft-dev.util')

local M = {}

---@param bundles string[]
---@param plugins string|string[]
local function found(bundles, plugins)
  if type(plugins) == 'string' then
    plugins = { plugins }
  end

  return vim.iter(plugins):all(function(plugin)
    return vim.iter(bundles):any(function(b)
      return b:match(vim.pesc(plugin))
    end)
  end)
end

function M.check()
  local bundles = (cfg.options.jdtls_config.init_options or {}).bundles
  ---@cast bundles string[]|vim.NIL
  local ok ---@type boolean

  if vim.uv.fs_stat(util.find_root(0) .. '/.nvim/launch.json') then
    vim.health.ok('run configurations: .nvim/launch.json')
  else
    vim.health.warn('missing run configurations: Execute `./gradlew neovim`')
  end

  vim.health.start('minecraft-dev: nvim-jdtls')
  if not pcall(require, 'jdtls') then
    vim.health.error(table.concat({
      '*nvim-jdtls* not found',
      'https://codeberg.org/mfussenegger/nvim-jdtls',
    }, '\n'))
  end
  if vim.fn.executable('jdtls') == 1 then
    vim.health.ok('*jdtls*')
  else
    vim.health.error(table.concat(vim.iter({
      '*jdtls* not found',
      'Install via mason.nvim or directly',
      'https://github.com/eclipse/eclipse.jdt.ls',
    }):totable(), '\n'))
  end

  vim.health.start('minecraft-dev: nvim-dap')
  if not pcall(require, 'dap') then
    vim.health.error(table.concat({
      '*nvim-dap* not found',
      'https://codeberg.org/mfussenegger/nvim-dap',
    }, '\n'))
  else
    ok = bundles and found(bundles, 'com.microsoft.java.debug.plugin')
    vim.health.info(table.concat(vim.iter({
      '*java-debug-adapter*' .. (ok and ' ' or ' not ') .. 'found',
      not ok and 'Install via mason.nvim or directly' or nil,
      not ok and 'https://github.com/microsoft/java-debug' or nil,
      'This plugin lets you use .vscode/launch.json (not recommended).',
      'The built-in debug adapter launches the game via gradlew directly to ensure',
      'consistency with Gradle.',
    }):totable(), '\n'))

    ok = bundles
        and found(bundles, {
          'com.microsoft.java.test.plugin',
          'junit-jupiter-api',
          'junit-jupiter-engine',
          'junit-jupiter-migrationsupport',
          'junit-jupiter-params',
          'junit-platform-commons',
          'junit-platform-engine',
          'junit-platform-launcher',
          'junit-platform-runner',
          'junit-platform-suite-api',
          'junit-platform-suite-commons',
          'junit-platform-suite-engine',
          'junit-vintage-engine',
          'org.apiguardian.api',
          'org.eclipse.jdt.junit',
          'org.jacoco.core',
          'org.opentest4j',
        })
        and not found(bundles, 'com.microsoft.java.test.runner-jar-with-dependencies.jar')
        and not found(bundles, 'jacocoagent.jar')
    vim.health.info(table.concat(vim.iter({
      '*java-test*' .. (ok and ' ' or ' not ') .. 'found',
      not ok and 'Install via mason.nvim or directly' or nil,
      not ok and 'https://github.com/microsoft/vscode-java-test' or nil,
      'https://codeberg.org/mfussenegger/nvim-jdtls#vscode-java-test-configuration',
    }):totable(), '\n'))
  end

  vim.health.start('minecraft-dev: java-deps.nvim')
  if not pcall(require, 'java-deps') then
    vim.health.info(table.concat({
      '*java-deps.nvim* not found',
      'https://github.com/JavaHello/java-deps.nvim',
      'https://github.com/g0ne150/java-deps.nvim',
    }, '\n'))
  elseif bundles and found(bundles, 'com.microsoft.jdtls.ext.core') then
    vim.health.ok('*vscode-java-dependency*')
  else
    vim.health.warn(table.concat({
      '*vscode-java-dependency*' .. (ok and '' or ' not found'),
      'Install via mason.nvim or directly',
      'https://github.com/Microsoft/vscode-java-dependency',
    }, '\n'))
  end
end

return M
