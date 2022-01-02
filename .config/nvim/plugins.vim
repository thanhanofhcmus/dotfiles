call plug#begin('~/.config/nvim/plugins')

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'windwp/nvim-autopairs'
Plug 'tpope/vim-endwise'
Plug 'terrortylor/nvim-comment'

Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'kyazdani42/nvim-tree.lua'
Plug 'akinsho/bufferline.nvim'

Plug 'akinsho/toggleterm.nvim'

Plug 'jackguo380/vim-lsp-cxx-highlight'
Plug 'danilo-augusto/vim-afterglow'

Plug 'projekt0n/github-nvim-theme'
Plug 'nvim-lualine/lualine.nvim'

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'

Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }

call plug#end()
