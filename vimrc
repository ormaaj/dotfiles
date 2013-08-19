" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
	finish
endif

set backspace=indent,eol,start                    " allow backspacing over everything in insert mode
set showcmd                                       " display incomplete commands
set incsearch                                     " do incremental searching
set ignorecase smartcase                          " ignore case sensitive searching
set modeline                                      " enable modeline reading (has security implications)
set tabstop=4                                     " Number of spaces that a <Tab> in the file counts for. 
set softtabstop=1
set shiftwidth=4                                  " Number of spaces to use for each step of (auto)indent. 
set noexpandtab
"set expandtab                                    " In Insert mode: Use the appropriate number of spaces to insert a <Tab>
set number
set numberwidth=3
set nohlsearch                                    " don't highlight the last search
"set autoindent
set smartindent
"set cindent
set ttyfast
set nobackup
set ruler                                         " Make cursor position always visible

"set completeopt+=longest                          " insert only the longest common text of the matches.
" (for OmniSharp) don't autoselect first item in omnicomplete, show if only one item (for preview)
set completeopt=longest,menuone,preview

set wildmode=longest,list,full
set wildmenu
set nolist                                        " No trailing line indicators
set listchars=extends:❯,precedes:❮
set ssop=blank,buffers,folds,help,tabpages,winpos " adjust what state information is saved on :mksession
set hidden                                        " Keeps changes in unsaved buffers when hiding. (You probably want this)
set spelllang=en_us
set undofile                                      " Enable persistent undo
set undodir=/home/smorg/undodir                   " Persistent undo directory
set ul=2000                                       " Undo levels to save
set verbose=0
"set rnu                                          " Numbering relative to the cursor
let g:sh_no_error=1                                " Kill the broken bash error highlighting
"let g:is_bash=1                                   " Use Bash sh highlighting mode globally
"let readline_has_bash=1                           " Use Bash extensions for readline highlighting
let g:is_mzscheme=1
let g:lisp_rainbow=1

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
" colors wombat256mod
" colors camo
" colors desertEx
" colors desert256
" colors candycode
" colors darkspectrum
colors molokai
" colors dante
" colors rdark
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
nnoremap <Leader>t :MBEToggle<cr>
nnoremap <Leader>n :NERDTreeToggle<CR>

" Plugin settings
" ===============

	" csapprox
let g:CSApprox_attr_map = { 'sp' : 'fg' }

	" MiniBufExpl
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplUseSingleClick = 1
let g:miniBufExplTabWrap = 1

	" 2html.vim
let g:html_use_xhtml = 1 " Output xhtml format when using the :TOhtml command. See :h 2html.vim

	" xmledit / xml.vim
let g:xml_use_xhtml = 1  " Auto-close short tags to make valid XML. For xml.vim 
let loaded_xmledit = 1
" let xml_jump_string = "`"

	" haskellmode
let g:haddock_browser="/usr/bin/chromium"

	" Gundo
nnoremap <F5> :GundoToggle<CR>

	" OmniSharp
"This is the default value, setting it isn't actually necessary
let g:OmniSharp_host = "http://localhost:2000"

" Set the type lookup function to use the preview window instead of the status line
let g:OmniSharp_typeLookupInPreview = 1

" Showmatch significantly slows down omnicomplete
" when the first match contains parentheses.
set noshowmatch

" Super tab settings
let g:SuperTabDefaultCompletionType = 'context'
let g:SuperTabContextDefaultCompletionType = "<c-x><c-o>"
let g:SuperTabDefaultCompletionTypeDiscovery = ["&omnifunc:<c-x><c-o>","&completefunc:<c-x><c-n>"]
let g:SuperTabClosePreviewOnPopupClose = 1

nnoremap <F6> :wa!<cr>:OmniSharpBuild<cr>
nnoremap <F12> :OmniSharpGotoDefinition<cr>
nnoremap gd :OmniSharpGotoDefinition<cr>
nnoremap fi :OmniSharpFindImplementations<cr>
nnoremap fu :OmniSharpFindUsages<cr>
nnoremap <leader>ft :OmniSharpTypeLookup<cr>
" I find contextual code actions so useful that I have it mapped to the spacebar
nnoremap <space> :OmniSharpGetCodeActions<cr>

" rename with dialog
nnoremap nm :OmniSharpRename<cr>
nnoremap <F2> :OmniSharpRename<cr>      
" rename without dialog - with cursor on the symbol to rename... ':Rename newname'
command! -nargs=1 Rename :call OmniSharp#RenameTo("<args>")
" Force OmniSharp to reload the solution. Useful when switching branches etc.
nnoremap <leader>rl :OmniSharpReloadSolution<cr>
nnoremap <leader>cf :OmniSharpCodeFormat<cr>
nnoremap <leader>fp :OmniSharpAddToProject<cr>
" (Experimental - uses vim-dispatch plugin) - Start the omnisharp server for the current solution
"nnoremap <leader>ss :OmniSharpStartServer<cr>
"nnoremap <leader>sp :OmniSharpStopServer<cr>

	" Functions
	" =========

python <<EOF
import vim, subprocess
EOF

" nnoremap t :call Tpaste()<CR>
func! Tpaste()
	python <<EOF
vim.current.buffer.append(subprocess.Popen(['/usr/bin/tmux', 'showb'], stdout=subprocess.PIPE).communicate()[0][:-1], vim.current.window.cursor[0])
EOF
endfunc

" vim: set fenc=utf-8 ff=unix ft=vim :
