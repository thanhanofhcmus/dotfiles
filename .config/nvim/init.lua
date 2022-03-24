
vim.cmd [[ source ~/.config/nvim/plugins.vim ]]
vim.cmd [[ source ~/.config/nvim/keymap.vim ]]
vim.cmd [[ source ~/.config/nvim/settings.vim ]]

require('tree')
require('lsp')
require('toggle-term')
require('buffer-line')
require('telescope-nvim')

require('nvim-autopairs').setup({ map_cr = true })
require('indent_blankline').setup({ show_end_of_line = true })
require('Comment').setup({ toggler = { line = '<C-_>' }})
require('nvim-treesitter.configs').setup({
    ensure_installed = 'all',
    highlight = {
        enable = true,
        disable = { 'lua' }
    },
})
require('github-theme').setup({
	transparent = true,
})
require('lualine').setup({ options = { theme = 'github' } })

-- vim.cmd [[ source ~/.config/nvim/theme.vim ]]
