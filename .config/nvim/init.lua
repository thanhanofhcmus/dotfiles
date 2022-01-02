vim.cmd [[ source ~/.config/nvim/plugins.vim ]]
vim.cmd [[ source ~/.config/nvim/keymap.vim ]]
vim.cmd [[ source ~/.config/nvim/settings.vim ]]

require('tree')
require('lsp')
require('toggle-term')
require('buffer-line')

require('lualine').setup({ options = { theme = 'auto' } })
require('github-theme').setup({ transparent = true })
require('nvim-autopairs').setup({ map_cr = true })

-- vim.cmd [[ source ~/.config/nvim/theme.vim ]]
