""""""""""""""""""
" GENERAL SETTINGS
""""""""""""""""""
" Set numbers on the left set number set relativenumber

" Be iMproved
set nocompatible

" Syntax checking etc
syntax on
filetype plugin indent on

" Map w!! to force save (i.e. opened without sudo)
cmap w!! w !sudo tee > /dev/null %

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
Plugin 'scrooloose/syntastic'
Plugin 'ervandew/supertab'
Plugin 'scrooloose/nerdtree'
call vundle#end()

" If vundle was installed, install all other plugins too
if vundle_installed == 0
	echo "Installing Bundles, please ignore key map error messages"
	echo ""
	:PluginInstall
endif

filetype plugin indent on

""""""""""""""""""
" SYNTASTIC SETTINGS
""""""""""""""""""

" Set status line for syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" Syntastic options to check on open and quit.
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

""""""""""""""""""
" NERDTREE SETTINGS
""""""""""""""""""

" Open NERDTree when vim is opened...
autocmd vimenter * NERDTree

" But make the focus the opened file (If there is one)
autocmd vimenter * if argc() != 0 | wincmd l | endif

" Close NERDTree when it is the last open split
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Map Ctrl+n to open NERDTree window
map <C-n> :NERDTreeToggle<CR>

