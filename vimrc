" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
    finish
endif

set backspace=indent,eol,start                    " allow backspacing over everything in insert mode
set showcmd                                       " display incomplete commands
set incsearch                                     " do incremental searching
set ignorecase smartcase                          " ignore case sensitive searching
set modeline                                      " enable modeline reading (has security implications)
set shiftwidth=4                                  " Number of spaces to use for each step of (auto)indent. 
set tabstop=4                                     " Number of spaces that a <Tab> in the file counts for. 
set softtabstop=4
set expandtab                                     " In Insert mode: Use the appropriate number of spaces to insert a <Tab>
set nohlsearch                                    " don't highlight the last search
set numberwidth=3
set autoindent
set smartindent
set number
set ttyfast
set nobackup
set completeopt+=longest                          " insert only the longest common text of the matches.
set wildmode=longest,list,full
set wildmenu
set ssop=blank,buffers,folds,help,tabpages,winpos " adjust what state information is saved on :mksession
set hidden                                        " Keeps changes in unsaved buffers when hiding. (You probably want this)
set spelllang=en_us
set undofile                                      " Enable persistent undo
set undodir=/home/smorg/undodir                   " Persistent undo directory
set ul=2000                                       " Undo levels to save
"set rnu                                          " Numbering relative to the cursor
let g:sh_no_error=1                                " Kill the broken bash error highlighting
"let g:is_bash=1                                   " Use Bash sh highlighting mode globally
"let readline_has_bash=1                           " Use Bash extensions for readline highlighting

if !exists("g:loaded_pathogen")
    filetype off    
    call pathogen#infect()
    call pathogen#helptags()
endif

filetype plugin indent on

" Switch syntax highlighting on, when the terminal has colors
if &t_Co > 2 || has("gui_running")
    syntax on
endif

if has('mouse')
    set mouse=a
    set ttymouse=xterm2
endif

if has("gui_running")
    set guioptions=aegimt " Kill the toolbar and scrollbars in gvim
    set gfn=Monospace\ 8  " Set the guifont
endif

" Colors
" ======
set background=dark
" let g:CSApprox_konsole = 1
" colors freya
" colors xoria256
" colors wombat256
" colors camo
" colors darkspectrum
" colors desertEx
" colors desert256
colors candycode
" colors inkpot
" colors blacksea
" colors zenburn
" colors solarized

" Misc Vars
" =========
let b:unaryTagsStack = ""

" Keybindings
" ===========
nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>
nnoremap <Space> i<Space><Esc>

" Plugin settings
" ===============
" csapprox
let g:CSApprox_attr_map = { 'sp' : 'fg' }


" 2html.vim
let g:html_use_xhtml = 1 " Output xhtml format when using the :TOhtml command. See :h 2html.vim

" xmledit / xml.vim
let g:xml_use_xhtml = 1  " Auto-close short tags to make valid XML. For xml.vim 
let loaded_xmledit = 1
"    let xml_jump_string = "`"

" haskellmode
let g:haddock_browser="/usr/bin/chromium"

" Gundo
nnoremap <F5> :GundoToggle<CR>

" Functions
" =========

python << EOF
import vim, subprocess
fix = lambda f: (lambda x: x(x))(lambda y: f(lambda z: y(y)(z)))
EOF

nnoremap t :call Tpaste()<CR>
func! Tpaste()
python << EOF
vim.current.buffer.append(subprocess.Popen(['/usr/bin/tmux', 'showb'], stdout=subprocess.PIPE).communicate()[0][:-1], vim.current.window.cursor[0])
EOF
endfunc

" vim: fenc=utf-8 ff=unix ft=vim ts=4 sw=4 sts=4 et
