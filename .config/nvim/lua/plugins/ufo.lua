vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldcolumn = '0'

require('ufo').setup({
    provider_selector = function() return { 'lsp', 'indent' } end
})
