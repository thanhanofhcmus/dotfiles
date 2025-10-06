require('commands')
require('plugins')
require('options')

-- must be load after plugins to
-- get all the plugins objects like telescope, nvim-cmp, ...
require('keymaps')
require('lsp')

-- TODO: move to a separate file
vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'none' })
vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'none' })
