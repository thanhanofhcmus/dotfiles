local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.g.mapleader = ' '

map('', '<C-O>', ':Telescope find_files<CR>')
map('n', '<leader>e', ':Neotree toggle<CR>')

map('n', '<leader>tk', '<C-w>t<C-w>K')             -- change vertical to horizontal

map('n', '<C-t>', ':Term<CR>', { noremap = true }) -- open
map('t', '<Esc>', '<C-\\><C-n>')                   -- exit
