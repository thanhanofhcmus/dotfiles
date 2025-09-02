local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.g.mapleader = ' '

map('', '<leader>ff', ':Telescope find_files<CR>')
map('', '<leader>fb', ':Telescope buffers<CR>')
map('', '<leader>fw', ':Telescope live_grep<CR>')
map('', '<leader>fo', ':Telescope oldfiles<CR>')
map('', '<leader>fm', ':Telescope marks<CR>')
map('', '<leader>fr', ':Telescope resume<CR>')

map('', '<leader>e', ':Yazi<CR>')

map('n', '<leader>gh', '<cmd>Gitsigns preview_hunk<CR>')
map('n', '<leader>gn', '<cmd>Gitsigns next_hunk<CR>')
map('n', '<leader>gp', '<cmd>Gitsigns prev_hunk<CR>')
map('n', '<leader>gd', '<cmd>Gitsigns diffthis<CR>')

map('n', '<leader>la', '<cmd>lua require("actions-preview").code_actions()<CR>')
