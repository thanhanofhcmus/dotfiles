-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    install = { colorscheme = { 'default' } },
    checker = { enabled = true },
    spec = {
        {
            'nvim-telescope/telescope.nvim',
            -- the current release have some bugs with neovim 0.11.4
            -- branch = '0.1.x',
            commit = 'b4da76be54691e854d3e0e02c36b0245f945c2c7',
            dependencies = { 'nvim-lua/plenary.nvim' },
            opts = {
                defaults = {
                    layout_config = { horizontal = { width = 0.9 } },
                    file_ignore_patterns = { "node_modules", "build*" }
                }
            }
        },
        {
            'nvim-treesitter/nvim-treesitter',
            branch = 'master',
            lazy = false,
            build = ':TSUpdate'
        },
        {
            "kylechui/nvim-surround",
            version = "^3.0.0",
            event = "VeryLazy",
            opts = {},
        },
        {
            'windwp/nvim-autopairs',
            event = "InsertEnter",
            opts = {}
        },
        {
            'kevinhwang91/nvim-ufo',
            dependencies = { "kevinhwang91/promise-async" },
            opts = {
                provider_selector = function() return { 'lsp', 'indent' } end,
            },
        },
        {
            'neovim/nvim-lspconfig',
        },
        {
            'hrsh7th/nvim-cmp',
            dependencies = {
                'hrsh7th/cmp-nvim-lsp',
                'hrsh7th/cmp-buffer',
                'hrsh7th/cmp-path',
                'hrsh7th/cmp-cmdline',
                'hrsh7th/cmp-nvim-lsp-signature-help',
            }
        },
        {
            'folke/snacks.nvim',
            priority = 1000,
            lazy = false,
            opts = require('snack-configs')
        }
    },
});
