" When started as "evim", evim.vim will already have done these settings.
if v:progname =~? "evim"
	finish
endif

set nowrap
set lbr                                           " Wrap at characters in "breakat".
set backspace=indent,eol,start                    " allow backspacing over everything in insert mode
set showcmd                                       " display incomplete commands
set incsearch                                     " do incremental searching
set ignorecase smartcase                          " ignore case sensitive searching
set modeline                                      " enable modeline reading (has security implications)
set tabstop=4                                     " Number of spaces that a <Tab> in the file counts for.
set softtabstop=4
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
set noerrorbells visualbell t_vb=                 " Disable visual bell

"set completeopt+=longest                          " insert only the longest common text of the matches.
" (for OmniSharp) don't autoselect first item in omnicomplete, show if only one item (for preview)
"set completeopt=longest,menuone,preview

set wildmode=longest,list,full
set wildmenu
set nolist                                        " No trailing line indicators
set listchars=extends:❯,precedes:❮
set ssop=blank,buffers,folds,help,tabpages,winpos " adjust what state information is saved on :mksession
set spelllang=en_us
set undofile                                      " Enable persistent undo
set undodir=/home/ormaaj/undodir                  " Defines the persistent undo directory
set undolevels=20000                               " Number of undo levels to save
set verbose=0
set laststatus=2                                  " Always show the statusline (good for airline)

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

if has('mouse') && !has('nvim')
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
" colors monokai
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
"nnoremap <F2> :set nonumber!<CR>:set foldcolumn=0<CR>
nnoremap <Space> i<Space><Esc>
nnoremap <Leader>n :NERDTreeToggle<CR>
nnoremap <F8> :TagbarToggle<CR>

" Plugin settings
" ===============

	" csapprox
let g:CSApprox_attr_map = { 'sp' : 'fg' }

	" MiniBufExpl
"nnoremap <Leader>t :MBEToggle<cr>
"let g:miniBufExplMapWindowNavVim = 1
"let g:miniBufExplMapCTabSwitchBufs = 1
"let g:miniBufExplUseSingleClick = 1
"let g:miniBufExplTabWrap = 1

	" 2html.vim
let g:html_use_xhtml = 1 " Output xhtml format when using the :TOhtml command. See :h 2html.vim

	" xmledit / xml.vim
let g:xml_use_xhtml = 1  " Auto-close short tags to make valid XML. For xml.vim
let loaded_xmledit = 1
" let xml_jump_string = "`"

	" haskellmode
let g:haddock_browser="/usr/bin/chromium"

	" Gundo
nnoremap <F6> :GundoToggle<CR>

	" Airline
let g:airline_detect_modified=1
let g:airline_detect_paste=1
let g:airline_detect_iminsert=1
let g:airline_inactive_collapse=0
let g:airline_powerline_fonts = 1

let g:airline#extensions#bufferline#enabled = 1
let g:airline#extensions#bufferline#overwrite_variables = 1
let g:airline#extensions#tagbar#enabled = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#tabline#tab_nr_type = 1 " tab number
let g:airline#extensions#tabline#formatter = 'default'
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#buffer_nr_format = '%s: '
let g:airline#extensions#tabline#fnamecollapse = 1

	" OmniSharp
" Automatically start the server.
let g:Omnisharp_start_server = 1

"This is the default value, setting it isn't actually necessary
let g:OmniSharp_host = "http://localhost:2000"

"Set the type lookup function to use the preview window instead of the status line
let g:OmniSharp_typeLookupInPreview = 1

"Timeout in seconds to wait for a response from the server
let g:OmniSharp_timeout = 1

"Showmatch significantly slows down omnicomplete
"when the first match contains parentheses.
set noshowmatch

"Super tab settings - uncomment the next 4 lines
let g:SuperTabDefaultCompletionType = 'context'
let g:SuperTabContextDefaultCompletionType = "<c-x><c-o>"
let g:SuperTabDefaultCompletionTypeDiscovery = ["&omnifunc:<c-x><c-o>","&completefunc:<c-x><c-n>"]
let g:SuperTabClosePreviewOnPopupClose = 1

"don't autoselect first item in omnicomplete, show if only one item (for preview)
"remove preview if you don't want to see any documentation whatsoever.
set completeopt=longest,menuone,preview
" Fetch full documentation during omnicomplete requests.
" There is a performance penalty with this (especially on Mono)
" By default, only Type/Method signatures are fetched. Full documentation can still be fetched when
" you need it with the :OmniSharpDocumentation command.
let g:omnicomplete_fetch_documentation = 1

"Move the preview window (code documentation) to the bottom of the screen, so it doesn't move the code!
"You might also want to look at the echodoc plugin
set splitbelow

" Get Code Issues and syntax errors
let g:syntastic_cs_checkers = ['syntax', 'semantic', 'issues']
" If you are using the omnisharp-roslyn backend, use the following
" let g:syntastic_cs_checkers = ['code_checker']

let g:OmniSharp_CursorHoldSyntaxCheck = 0

augroup omnisharp_commands
    autocmd!

    "Set autocomplete function to OmniSharp (if not using YouCompleteMe completion plugin)
    autocmd FileType cs setlocal omnifunc=OmniSharp#Complete

    " Synchronous build (blocks Vim)
    "autocmd FileType cs nnoremap <F5> :wa!<cr>:OmniSharpBuild<cr>
    " Builds can also run asynchronously with vim-dispatch installed
    autocmd FileType cs nnoremap <leader>b :wa!<cr>:OmniSharpBuildAsync<cr>
    " automatic syntax check on events (TextChanged requires Vim 7.4)
    autocmd BufEnter,TextChanged,InsertLeave *.cs SyntasticCheck

    " Automatically add new cs files to the nearest project on save
    autocmd BufWritePost *.cs call OmniSharp#AddToProject()

    "show type information automatically when the cursor stops moving
    autocmd CursorHold *.cs call OmniSharp#TypeLookupWithoutDocumentation()

    "The following commands are contextual, based on the current cursor position.

    autocmd FileType cs nnoremap gd :OmniSharpGotoDefinition<cr>
    autocmd FileType cs nnoremap <leader>fi :OmniSharpFindImplementations<cr>
    autocmd FileType cs nnoremap <leader>ft :OmniSharpFindType<cr>
    autocmd FileType cs nnoremap <leader>fs :OmniSharpFindSymbol<cr>
    autocmd FileType cs nnoremap <leader>fu :OmniSharpFindUsages<cr>
    "finds members in the current buffer
    autocmd FileType cs nnoremap <leader>fm :OmniSharpFindMembers<cr>
    " cursor can be anywhere on the line containing an issue
    autocmd FileType cs nnoremap <leader>x  :OmniSharpFixIssue<cr>
    autocmd FileType cs nnoremap <leader>fx :OmniSharpFixUsings<cr>
    autocmd FileType cs nnoremap <leader>tt :OmniSharpTypeLookup<cr>
    autocmd FileType cs nnoremap <leader>dc :OmniSharpDocumentation<cr>
    "navigate up by method/property/field
    autocmd FileType cs nnoremap <C-K> :OmniSharpNavigateUp<cr>
    "navigate down by method/property/field
    autocmd FileType cs nnoremap <C-J> :OmniSharpNavigateDown<cr>

augroup END


" this setting controls how long to wait (in ms) before fetching type / symbol information.
set updatetime=500
" Remove 'Press Enter to continue' message when type information is longer than one line.
set cmdheight=2

" Contextual code actions (requires CtrlP or unite.vim)
nnoremap <leader><space> :OmniSharpGetCodeActions<cr>
" Run code actions with text selected in visual mode to extract method
vnoremap <leader><space> :call OmniSharp#GetCodeActions('visual')<cr>

" rename with dialog
nnoremap <leader>nm :OmniSharpRename<cr>
nnoremap <F2> :OmniSharpRename<cr>
" rename without dialog - with cursor on the symbol to rename... ':Rename newname'
command! -nargs=1 Rename :call OmniSharp#RenameTo("<args>")

" Force OmniSharp to reload the solution. Useful when switching branches etc.
nnoremap <leader>rl :OmniSharpReloadSolution<cr>
nnoremap <leader>cf :OmniSharpCodeFormat<cr>
" Load the current .cs file to the nearest project
nnoremap <leader>tp :OmniSharpAddToProject<cr>

" (Experimental - uses vim-dispatch or vimproc plugin) - Start the omnisharp server for the current solution
nnoremap <leader>ss :OmniSharpStartServer<cr>
nnoremap <leader>sp :OmniSharpStopServer<cr>

" Add syntax highlighting for types and interfaces
nnoremap <leader>th :OmniSharpHighlightTypes<cr>
"Don't ask to save when changing buffers (i.e. when jumping to a type definition)
set hidden

    " hasktags support for tagbar
let g:tagbar_type_haskell = {
    \ 'ctagsbin'  : 'hasktags',
    \ 'ctagsargs' : '-x -c -o-',
    \ 'kinds'     : [
        \  'm:modules:0:1',
        \  'd:data: 0:1',
        \  'd_gadt: data gadt:0:1',
        \  't:type names:0:1',
        \  'nt:new types:0:1',
        \  'c:classes:0:1',
        \  'cons:constructors:1:1',
        \  'c_gadt:constructor gadt:1:1',
        \  'c_a:constructor accessors:1:1',
        \  'ft:function types:1:1',
        \  'fi:function implementations:0:1',
        \  'o:others:0:1'
    \ ],
    \ 'sro'        : '.',
    \ 'kind2scope' : {
        \ 'm' : 'module',
        \ 'c' : 'class',
        \ 'd' : 'data',
        \ 't' : 'type'
    \ },
    \ 'scope2kind' : {
        \ 'module' : 'm',
        \ 'class'  : 'c',
        \ 'data'   : 'd',
        \ 'type'   : 't'
    \ }
\ }

" vim: set fenc=utf-8 ff=unix ft=vim :
