-- [[ Treesitter ]]
-- Parser installation, syntax highlighting, folds, indentation, textobjects

local gh = require('custom.util').gh

-- [[ Configure Treesitter ]]
--  Used to highlight, edit, and navigate code
--
--  See `:help nvim-treesitter-intro`

-- NOTE: You can also specify a branch or a specific commit
vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' } }

-- Ensure basic parsers are installed
local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'hcl', 'terraform', 'java' }
require('nvim-treesitter').install(parsers)

---@param buf integer
---@param language string
local function treesitter_try_attach(buf, language)
  -- Check if the buffer is valid (might not be after install completes)
  if not vim.api.nvim_buf_is_valid(buf) then return end

  -- Check if a parser exists and load it
  if not vim.treesitter.language.add(language) then return end

  -- Enable syntax highlighting and other treesitter features
  vim.treesitter.start(buf, language)

  -- Enable treesitter based folds
  -- For more info on folds see `:help folds`
  -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  -- vim.wo.foldmethod = 'expr'

  -- Check if treesitter indentation is available for this language, and if so enable it
  -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
  local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil

  -- Enable treesitter based indentation
  if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available_parsers = require('nvim-treesitter').get_available()
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local buf, filetype = args.buf, args.match

    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end

    local installed_parsers = require('nvim-treesitter').get_installed 'parsers'

    if vim.tbl_contains(installed_parsers, language) then
      -- Enable the parser if it is already installed
      treesitter_try_attach(buf, language)
    elseif vim.tbl_contains(available_parsers, language) then
      -- If a parser is available in `nvim-treesitter`, auto-install it and enable it after the installation is done
      require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
    else
      -- Try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
      treesitter_try_attach(buf, language)
    end
  end,
})

-- [[ Treesitter Textobjects ]]
--  Custom textobjects (functions, classes, comments, assignments, ...)
--  and motions to jump between them.
--
--  NOTE: The `main` branch of nvim-treesitter-textobjects (required by the
--  `main` branch of nvim-treesitter above) no longer uses the old
--  `textobjects` module tables; keymaps are set with `vim.keymap.set` instead.
vim.pack.add { { src = gh 'nvim-treesitter/nvim-treesitter-textobjects', version = 'main' } }

require('nvim-treesitter-textobjects').setup {
  select = {
    -- Automatically jump forward to textobj, similar to targets.vim
    lookahead = true,
    -- You can choose the select mode (default is charwise 'v')
    selection_modes = {
      ['@parameter.outer'] = 'v', -- charwise
      ['@function.outer'] = 'V', -- linewise
      ['@class.outer'] = '<c-v>', -- blockwise
    },
    -- Extend textobjects to include preceding or succeeding whitespace.
    include_surrounding_whitespace = false,
  },
  move = {
    -- Whether to set jumps in the jumplist
    set_jumps = true,
  },
}

local ts_select = require 'nvim-treesitter-textobjects.select'
local function select_map(keys, query, desc, query_group)
  vim.keymap.set({ 'x', 'o' }, keys, function() ts_select.select_textobject(query, query_group or 'textobjects') end, { desc = desc })
end

select_map('af', '@function.outer', 'Select outer function')
select_map('if', '@function.inner', 'Select inner function')
select_map('ac', '@class.outer', 'Select outer class')
select_map('ic', '@class.inner', 'Select inner part of a class region')
select_map('ag', '@comment.outer', 'Select outer comment')
select_map('ig', '@comment.inner', 'Select inner comment')
select_map('il', '@assignment.lhs', 'Select left of assigment')
select_map('ir', '@assignment.rhs', 'Select right of assigment')
select_map('ia', '@attribute.inner', 'Select inner attribute')
-- NOTE: 'aa' shadows mini.ai's `around_next` mapping configured earlier.
select_map('aa', '@attribute.outer', 'Select outer attribute')
-- You can also use captures from other query groups like `locals.scm`
select_map('as', '@scope', 'Select language scope', 'locals')

local ts_move = require 'nvim-treesitter-textobjects.move'
local function move_map(keys, fn, query, desc, query_group)
  vim.keymap.set({ 'n', 'x', 'o' }, keys, function() ts_move[fn](query, query_group or 'textobjects') end, { desc = desc })
end

-- æ = jump to next, ø = jump to previous (lowercase = start, uppercase = end)
move_map('æf', 'goto_next_start', '@function.outer', 'Next function start')
move_map('æc', 'goto_next_start', '@class.outer', 'Next class start')
-- You can pass a list of queries to group multiple queries.
move_map('æo', 'goto_next_start', { '@loop.inner', '@loop.outer' }, 'Next loop start')
-- You can use query groups from `queries/<lang>/<query_group>.scm` files in
-- your runtime path, e.g. nvim-treesitter's `locals.scm` and `folds.scm`.
move_map('æs', 'goto_next_start', '@scope', 'Next scope', 'locals')
move_map('æz', 'goto_next_start', '@fold', 'Next fold', 'folds')
move_map('æd', 'goto_next', '@conditional.outer', 'Next conditional')
move_map('æa', 'goto_next', '@attribute.outer', 'Next attribute')
move_map('øf', 'goto_previous_start', '@function.outer', 'Previous function start')
move_map('øc', 'goto_previous_start', '@class.outer', 'Previous class start')
move_map('øF', 'goto_previous_end', '@function.outer', 'Previous function end')
move_map('øC', 'goto_previous_end', '@class.outer', 'Previous class end')
move_map('ød', 'goto_previous', '@conditional.outer', 'Previous conditional')
move_map('øa', 'goto_previous', '@attribute.outer', 'Previous attribute')
