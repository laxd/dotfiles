""""""""""""""""""
" GENERAL SETTINGS """"""""""""""""""
" Set line number for current line
set number

" Set relative line numbers for all other lines
set relativenumber

" Be iMproved
set nocompatible

" Syntax checking etc
syntax on

" Map w!! to force save (i.e. opened without sudo)
cmap w!! w !sudo tee > /dev/null %

" Save and run tests
map <F5> :w<CR>:make test<CR>

" Remove highlighting with enter
nnoremap <CR> :noh<CR><CR>:<BACKSPACE>

" Allow incremental, highlighted search
set incsearch
set hlsearch

""""""""""""""""""
" SPLITS SETTINGS
""""""""""""""""""

" Allow using ctrl-[hjkl] to travel between splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Open new splits below/to the right of current pane
set splitbelow
set splitright

""""""""""""""""""
" TAB SETTINGS
""""""""""""""""""

set shiftwidth=2
set tabstop=2
set list
set listchars=tab:\|\ 

""""""""""""""""""
" PLUGIN SETTINGS
""""""""""""""""""

" Required for Vundle
filetype off

" First, make sure vundle is installed
let vundle_installed=1
let vundle_readme=expand('~/.vim/bundle/vundle/README.md')
if !filereadable(vundle_readme)
	echo "Installing Vundle.."
	echo ""
	silent !mkdir -p ~/.vim/bundle
	silent !git clone https://github.com/gmarik/vundle ~/.vim/bundle/vundle
	let vundle_installed=0
endif

" Now that we know vundle is installed, continue loading plugins
set rtp+=~/.vim/bundle/vundle/

call vundle#begin()
Plugin 'gmarik/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/nerdcommenter'
Plugin 'ctrlpvim/ctrlp.vim'
Plugin 'SirVer/ultisnips'
Plugin 'honza/vim-snippets.git'
Plugin 'Valloric/YouCompleteMe'
Plugin 'Raimondi/delimitMate'
Plugin 'airblade/vim-rooter'
Plugin 'tfnico/vim-gradle'
Plugin 'rustushki/JavaImp.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'othree/xml.vim'
call vundle#end()

" If vundle was installed, install all other plugins too
if vundle_installed == 0
	echo "Installing Bundles, please ignore key map error messages"
	echo ""
	:PluginInstall
endif

filetype plugin indent on

""""""""""""""""""
" NERDTREE SETTINGS
""""""""""""""""""

" Open NERDTree when vim is opened...
autocmd vimenter * NERDTree

" But make the focus the opened file (If there is one)
autocmd vimenter * if argc() != 0 | wincmd l | endif

" Close NERDTree when it is the last open split
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif 

" Allow us to update NERDTree when we open a new file
map <leader>n :NERDTreeFind<CR>l<CR>

" Map Ctrl+n to open NERDTree window
map <C-n> :NERDTreeToggle<CR>

""""""""""""""""""
" ULTISNIPS SETTINGS
""""""""""""""""""

" Trigger Configuration
let g:UltiSnipsExpandTrigger="<C-SPACE>"
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

""""""""""""""""""
" CTRLP SETTINGS
""""""""""""""""""

let g:ctrlp_map='<leader>t'

" Ignore build/target directories
set wildignore+=*/build/**
set wildignore+=*/target/**

" And don't do any caching
let g:ctrlp_use_caching=0

""""""""""""""""""
" JAVAIMP SETTINGS
""""""""""""""""""

" ONLY to be used with vim-rooter
" (Not working yet...)
" let projectRoot = s:FindRootDirectory()
" Alternative that isn't as good
let projectRoot = getcwd()

let g:JavaImpPaths = 
	\ $HOME . "/.m2/repositories," .
	\ $HOME . "/.gradle/caches/modules-2/files-2.1," .
	\ projectRoot . "/build," .
	\ projectRoot . "/target"
