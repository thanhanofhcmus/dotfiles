local opts = { noremap = true, silent = true }

local Snacks = require('snacks')

vim.g.mapleader = vim.keycode('<Space>')

vim.keymap.set('n', 'gd', Snacks.picker.lsp_definitions, opts)
vim.keymap.set('n', 'gt', Snacks.picker.lsp_type_definitions, opts)
vim.keymap.set('n', 'gD', Snacks.picker.lsp_declarations, opts)
vim.keymap.set('n', 'gr', Snacks.picker.lsp_references, opts)
vim.keymap.set('n', 'gI', Snacks.picker.lsp_implementations, opts)
vim.keymap.set('n', 'gp', Snacks.picker.diagnostics, opts)

vim.keymap.set('n', 'g]', function() vim.diagnostic.jump({ count = 1 }) end, opts)
vim.keymap.set('n', 'g[', function() vim.diagnostic.jump({ count = -1 }) end, opts)
vim.keymap.set('n', 'gh', vim.lsp.buf.hover, opts)
vim.keymap.set('n', 'gj', vim.diagnostic.open_float, opts)

vim.keymap.set('n', '<leader>lr', vim.lsp.buf.rename, opts)
vim.keymap.set('n', '<leader>la', vim.lsp.buf.code_action, opts)

vim.keymap.set('n', '<leader>ff', Snacks.picker.files, opts)
vim.keymap.set('n', '<leader>fb', Snacks.picker.buffers, opts)
vim.keymap.set('n', '<leader>fw', Snacks.picker.grep, opts)
vim.keymap.set('n', '<leader>fo', Snacks.picker.recent, opts)
vim.keymap.set('n', '<leader>fm', Snacks.picker.marks, opts)
vim.keymap.set('n', '<leader>fr', Snacks.picker.resume, opts)

vim.keymap.set('n', '<leader>e', Snacks.explorer.open, opts)
