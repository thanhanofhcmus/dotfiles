vim.opt.wrap = false
vim.opt.ruler = true
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
vim.opt.smarttab = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.spelllang = 'en_us'
vim.opt.spell = true

vim.opt.list = true
vim.opt.listchars = { tab = '| ', trail = '•', nbsp = '~' }

-- use plugin widler instead
vim.cmd [[ set nowildmenu ]]
-- vim.cmd [[ set wildmode=full ]]


vim.o.mouse = 'a'
vim.o.termguicolors = true
vim.o.hidden = true
vim.o.encoding = 'utf-8'
vim.o.fileencoding = 'utf-8'
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.eadirection = 'hor'
vim.o.t_Co = '256'

vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false

vim.api.nvim_create_autocmd({ "FileType" }, {
    callback = function()
        vim.opt.formatoptions:remove('c')
        vim.opt.formatoptions:remove('r')
        vim.opt.formatoptions:remove('o')
    end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*.go", "*.lua" },
    callback = function()
        vim.lsp.buf.format()
    end
})
