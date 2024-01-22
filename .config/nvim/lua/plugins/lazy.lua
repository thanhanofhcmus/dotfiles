local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
    {
        "lewis6991/gitsigns.nvim",
    },
    {
        'gelguy/wilder.nvim',
    },
    {
        'romgrk/fzy-lua-native',
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {},
        setup = function()
            require('ibl').setup({})
        end
    },
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.3',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {
        "kylechui/nvim-surround",
        tag = "v2.1.0",
        lazy = false,
        config = function()
            require("nvim-surround").setup({})
        end,
    },
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        opts = {}
    },
    {
        'nvim-treesitter/nvim-treesitter'
    },
    {
        'neovim/nvim-lspconfig',
        config = function()
            -- Add your LSP configuration here if needed
        end
    },
    {
        'hrsh7th/cmp-nvim-lsp',
        dependencies = {
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-vsnip',
            'hrsh7th/vim-vsnip',
        }
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        }
    },
    {
        "catppuccin/nvim", name = "catppuccin", priority = 1000 }
}, {})
