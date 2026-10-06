-- [[ Java ]]
-- Java LSP is handled by nvim-jdtls (instead of the `servers` table in `custom.plugins.lsp`),
-- which starts/attaches its own eclipse.jdt.ls instance per project.

local gh = require('custom.util').gh

vim.pack.add { gh 'mfussenegger/nvim-jdtls' }

-- Setup Workspace: each project gets its own jdtls workspace directory
local home = os.getenv 'HOME'
local workspace_path = home .. '/.local/share/nvim/jdtls-workspace/'
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = workspace_path .. project_name

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function()
    require('jdtls').start_or_attach {
      cmd = { '/bin/eclipse-jdtls/bin/jdtls', '-data', workspace_dir },
      -- root_dir = vim.fs.dirname(vim.fs.find({ '.git' }, { upward = true })[1]),
      root_dir = require('jdtls.setup').find_root { 'pom.xml' },
      settings = {
        java = {
          inlayHints = { parameterNames = { enabled = 'all' } },
          signatureHelp = { enabled = true },
          contentProvider = { preferred = 'fernflower' },
          format = {
            -- onType = {
            --   enabled = true,
            -- },
            enabled = false,
            -- settings = {
            --   url = 'https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml',
            -- },
          },
        },
      },
    }
  end,
})
