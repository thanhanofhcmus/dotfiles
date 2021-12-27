call plug#begin('~/.config/nvim/plugins')

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'airblade/vim-rooter'
" Plug '9mm/vim-closer'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-endwise'
Plug 'terrortylor/nvim-comment'

Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'kyazdani42/nvim-tree.lua'
Plug 'akinsho/bufferline.nvim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'akinsho/toggleterm.nvim'

Plug 'jackguo380/vim-lsp-cxx-highlight'

Plug 'danilo-augusto/vim-afterglow'

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'

Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'

call plug#end()
