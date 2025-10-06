local opts = { noremap = true, silent = true }

vim.g.mapleader = vim.keycode('<Space>')

local telescope_builtin = require('telescope.builtin')

vim.keymap.set('n', 'gd', telescope_builtin.lsp_definitions, opts)
vim.keymap.set('n', 'gr', telescope_builtin.lsp_references, opts)
vim.keymap.set('n', 'gi', telescope_builtin.lsp_implementations, opts)
vim.keymap.set('n', 'gp', telescope_builtin.diagnostics, opts)

vim.keymap.set('n', 'g]', function() vim.diagnostic.jump({ count = 1 }) end, opts)
vim.keymap.set('n', 'g[', function() vim.diagnostic.jump({ count = -1 }) end, opts)
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, opts)
vim.keymap.set('n', 'gj', vim.diagnostic.open_float, opts)

vim.keymap.set('n', '<leader>ff', telescope_builtin.find_files, opts)
vim.keymap.set('n', '<leader>fb', telescope_builtin.buffers, opts)
vim.keymap.set('n', '<leader>fw', telescope_builtin.live_grep, opts)
vim.keymap.set('n', '<leader>fo', telescope_builtin.oldfiles, opts)
vim.keymap.set('n', '<leader>fm', telescope_builtin.marks, opts)
vim.keymap.set('n', '<leader>fr', telescope_builtin.resume, opts)

vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts);
