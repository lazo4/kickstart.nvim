vim.pack.add { 'https://github.com/supermaven-inc/supermaven-nvim' }

-- Configure Supermaven
require('supermaven-nvim').setup {
  keymaps = {
    accept_suggestion = '<Tab>',
    clear_suggestion = '<C-]>',
    accept_word = '<C-j>',
  },
  ignore_filetypes = { cpp = true }, -- disable for specific filetypes if needed
  color = {
    suggestion_color = '#808080',
    cterm = 244,
  },
  disable_inline_completion = false, -- keep inline ghost text active
  disable_keymaps = false, -- use keymaps defined above
}
