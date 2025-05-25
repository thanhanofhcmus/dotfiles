local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
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

require("lazy").setup(
    {
        { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
        {
            "lewis6991/gitsigns.nvim",
        },
        {
            'romgrk/fzy-lua-native',
        },
        {
            "lukas-reineke/indent-blankline.nvim",
            main = "ibl",
            opts = {},
            setup = function() require('ibl').setup({}) end
        },
        {
            'nvim-telescope/telescope.nvim',
            tag = '0.1.3',
            dependencies = { 'nvim-lua/plenary.nvim' }
        },
        {
            "kylechui/nvim-surround",
            version = "^3.0.0",
            event = "VeryLazy",
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
            config = function() end
        },
        {
            'hrsh7th/cmp-nvim-lsp',
            dependencies = {
                'hrsh7th/nvim-cmp',
                'hrsh7th/cmp-buffer',
                'hrsh7th/cmp-path',
                'hrsh7th/cmp-cmdline',
                'hrsh7th/cmp-nvim-lsp-signature-help',
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
    },
    {}
)
