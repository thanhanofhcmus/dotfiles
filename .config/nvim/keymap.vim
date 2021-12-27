nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

tnoremap <C-[> <C-\><C-n>
nnoremap <space>e :NvimTreeToggle<CR>
nnoremap <tab> :BufferLineCycleNext<CR>
nnoremap <c-q> :bp<CR>:bd#<CR>

nnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>
inoremap <silent><c-t> <Esc><Cmd>exe v:count1 . "ToggleTerm"<CR>

" inoremap <C-j> <C-n>
" inoremap <C-k> <C-p>
