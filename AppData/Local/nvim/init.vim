"
" (C) 2021 Advanced Systems
"

let mapleader=" "

" load plugins
call plug#begin('~/AppData/Local/nvim/plugged')
    " improved syntax support
    Plug 'sheerun/vim-polyglot'
    " file explorer
    Plug 'scrooloose/NERDTree'
    " auto-pairs '(', '[', '{'
    Plug 'jiangmiao/auto-pairs'
call plug#end()

syntax on			" turn on lexical highlighting
filetype on			" enable file type detection
set nocompatible
set encoding=utf-8
set expandtab
set smarttab
set shiftwidth=4	" one tab equals four spaces
set tabstop=4
set lbr				" turn on line breaks
set tw=240			" and set it to 240 chars
set ai				" auto indent
set si				" smart indent
set number			" turn on (absolute) line numbers
set ruler			" show line and column number
set hlsearch		" highlight search results
set magic
set nobackup		" disable backups because we use git
set nowb
set noswapfile
set lazyredraw		" disable redraws during macro execution to improve performance

" format status lines
set statusline=
set statusline+=%1*\ %n\ %*     " buffer number
set statusline+=%5*%{&ff}%*     " file format
set statusline+=%3*%y%*         " file type
set statusline+=%4*\ %<%F%*     " full file path
set statusline+=%2*%m%*         " modified flag
set statusline+=%1*%=%5l%*      " current line no
set statusline+=%2*/%L%*        " total no of lines
set statusline+=%1*%4v\ %*      " virtual column no
set statusline+=%2*0x%04B\ %*   " character under cursor

if has('termguicolors')
    set termguicolors
endif

" enable auto-completion
set wildmode=longest,list,full
" disable comment continuation
autocmd BufNewFile,Bufread * setlocal formatoptions-=cro
" return to last modified line after opening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
" automatically delete all trailing white spaces
autocmd BufWritePre * %s/\s\+$//e


" check spelling
map <leader>o :setlocal spell! spelllang=en_us<CR>


" navigate through split windows
set splitbelow splitright
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" placeholder guide
nnoremap ,, <Esc>/<++><Enter>"_c4l

autocmd FileType tex map ;c :!latexmk -cd "src/document.tex" -synctex=1 -shell-escape
            \ -interaction=nonstopmode -file-line-error -pdf<CR><CR>
autocmd FileType tex map ;p :!mupdf ./build/document.pdf & disown<CR><CR>
autocmd FileType tex map ;d :!latexmk -C -outdir="./src" "./src/document.tex"<CR>
