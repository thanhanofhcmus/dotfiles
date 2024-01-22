local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.g.mapleader = ' '

map('', '<C-O>', ':Telescope find_files<CR>')
map('', '<leader>ff', ':Telescope find_files<CR>')
map('', '<leader>fb', ':Telescope buffers<CR>')
map('', '<leader>fw', ':Telescope live_grep<CR>')

map('n', '<leader>te', ':Neotree toggle<CR>')
map('n', '<leader>tr', ':Neotree reveal<CR>')

map('n', '<leader>tk', '<C-w>t<C-w>K') -- change vertical to horizontal

map('n', '<leader>gh', '<cmd>Gitsigns preview_hunk<CR>')
map('n', '<leader>gj', '<cmd>Gitsigns next_hunk<CR>')
map('n', '<leader>gh', '<cmd>Gitsigns prev_hunk<CR>')
map('n', '<leader>gd', '<cmd>Gitsigns diffthis<CR>')

map('n', '<leader>gst', '<cmd>Telescope git_status<CR>')
map('n', '<leader>glo', '<cmd>Telescope git_commits<CR>')
map('n', '<leader>gbr', '<cmd>Telescope git_branches<CR>')
map('n', '<leader>gsl', '<cmd>Telescope git_stash<CR>')
