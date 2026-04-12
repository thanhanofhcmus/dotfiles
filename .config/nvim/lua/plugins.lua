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
            'nvim-treesitter/nvim-treesitter',
            branch = 'main',
            lazy = false,
            build = ':TSUpdate'
        },
        {
            'nvim-treesitter/nvim-treesitter-context',
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
            version = "^2.0.0",
            priority = 1000,
            lazy = false,
            opts = require('snack-configs')
        },
        {
            'nvim-lualine/lualine.nvim',
            dependencies = { 'nvim-tree/nvim-web-devicons' },
            opts = {
                options = {
                    component_separators = { left = '|', right = '|' },
                    section_separators = { left = '', right = '' },
                }
            },
        },
        {
            'mikesmithgh/kitty-scrollback.nvim',
            enabled = true,
            lazy = true,
            cmd = { 'KittyScrollbackGenerateKittens', 'KittyScrollbackCheckHealth', 'KittyScrollbackGenerateCommandLineEditing' },
            event = { 'User KittyScrollbackLaunch' },
            version = '^6.0.0',
            config = function()
                require('kitty-scrollback').setup()
            end,
        },

        --- THEMES ---

        {
            "catppuccin/nvim",
            name = "catppuccin",
            opts = {
                flavour = "auto",
                background = {
                    light = "latte",
                    dark = "mocha",
                },
                transparent_background = true,
                float = {
                    transparent = true,
                    solid = false,
                },
                auto_integrations = true,
            }
        },
    },
});
