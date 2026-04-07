require('neovim-p')

local is_tty = vim.env.TERM == "linux"
vim.o.termguicolors = not is_tty

vim.cmd("colorscheme neovim-p")
