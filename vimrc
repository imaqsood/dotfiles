runtime macros/matchit.vim
set nocompatible
set number
set rtp+=~/.vim/bundle/Vundle.vim
set clipboard=unnamedplus
set path+=**

set shiftwidth=2
set tabstop=2
set expandtab
set autoindent
set smartindent
set cindent
set re=1
set hidden


call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'idanarye/vim-merginal'
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
Plugin 'scrooloose/nerdtree'
Plugin 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plugin 'junegunn/fzf.vim'
Plugin 'sickill/vim-monokai'
Plugin 'sainnhe/gruvbox-material'
Plugin 'sainnhe/sonokai'
Plugin 'morhetz/gruvbox'
Plugin 'godlygeek/tabular'
"Plugin 'SirVer/ultisnips'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'airblade/vim-gitgutter'
Plugin 'slim-template/vim-slim.git'
Plugin 'chiel92/vim-autoformat'
"Plugin 'davydovanton/vim-html2slim'
Plugin 'jiangmiao/auto-pairs'
Plugin 'tpope/vim-commentary'
Plugin 'vim-ruby/vim-ruby'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-bundler'
Plugin 'tpope/vim-rake'
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-dadbod'
Plugin 'tpope/vim-surround'
Plugin 'dense-analysis/ale'
Plugin 'Yggdroot/indentLine'
Plugin 'kchmck/vim-coffee-script'
Plugin 'autozimu/LanguageClient-neovim'
Plugin 'kana/vim-textobj-user'
Plugin 'nelstrom/vim-textobj-rubyblock'
" Auto-folg files upon open. Disable session-wide with: <leader>nf
Plugin 'bruno-/vim-ruby-fold'
if has('nvim')
  Plugin 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
else
  Plugin 'Shougo/deoplete.nvim'
  Plugin 'roxma/nvim-yarp'
  Plugin 'roxma/vim-hug-neovim-rpc'
endif


call vundle#end()

syntax enable
filetype plugin indent on
" colorscheme monokai
colorscheme gruvbox-material

autocmd BufNewFile,BufRead *.slim set ft=slim
autocmd StdinReadPre * let s:std_in=1
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()
"autocmd VimEnter * if argc() == 0 && !exists('s:std_in') | NERDTree | endif


let ruby_operators        = 1
let ruby_pseudo_operators = 1
let g:airline_theme='google_dark'
let g:airline_powerline_fonts = 1

let g:fzf_buffers_jump = 1

function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val, "lnum": 1 }'))
  copen
  cc
endfunction

let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }
let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'

let g:deoplete#enable_at_startup = 1
let NERDTreeAutoDeleteBuffer = 1
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
let g:ale_set_highlights = 0
let g:ale_linters = {
      \   'ruby': ['standardrb', 'rubocop'],
      \   'python': ['flake8', 'pylint'],
      \   'javascript': ['eslint'],
      \}
let g:ale_fixers = {
      \    'ruby': ['standardrb'],
      \}
let g:ale_fix_on_save = 0
let g:indentLine_char_list = ['|', '¦', '┆', '┊']

function! LinterStatus() abort
  let l:counts = ale#statusline#Count(bufnr(''))

  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors

  return l:counts.total == 0 ? '✨ all good ✨' : printf(
        \   '😞 %dW %dE',
        \   all_non_errors,
        \   all_errors
        \)
endfunction

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ deoplete#mappings#manual_complete()
function! s:check_back_space() abort "{{{
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction"}}}

set hidden

let g:LanguageClient_serverCommands = {
    \ 'ruby': ['~/.rvm/gems/ruby-3.0.0/bin/solargraph', 'stdio'],
    \ }

nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>

highlight ALEWarning ctermbg=DarkMagenta

set statusline=
set statusline+=%m
set statusline+=\ %f
set statusline+=%=
set statusline+=\ %{LinterStatus()}

nnoremap <C-p> :Files!<Cr>
nnoremap <C-f> :Ag!<Space>
nnoremap <C-Space> :Buffers<Cr>
nnoremap <C-c> :Commits!<Cr>
nnoremap <silent> <expr> <Leader><Leader> (expand('%') =~ 'NERD_tree' ? "\<c-w>\<c-w>" : '').":FZF\<cr>"
nnoremap tn :tabnew<Space>
nnoremap tk :tabnext<CR>
nnoremap tj :tabprev<CR>
nnoremap th :tabfirst<CR>
nnoremap tl :tablast<CR>
nnoremap gs :tab G<CR>
nnoremap gb :G blame p<CR>
vnoremap gb :G blame p<CR>
nnoremap <F5> "=strftime("================== %c ==================")<CR>P
inoremap <F5> <C-R>=strftime("================== %c ==================")<CR>

"fold settings
" ------------
" toggle folding with za.
" fold everything with zM
" unfold everything with zR.
" zm and zr can be used too
set foldmethod=syntax   "fold based on syntax (except for haml below)
set foldnestmax=10      "deepest fold is 10 levels
set nofoldenable        "dont fold by default
autocmd BufNewFile,BufRead *.haml setl foldmethod=indent nofoldenable
autocmd! FileType nofile setl foldmethod=indent nofoldenable

" Space to toggle folds.
" nnoremap <Space> za
" vnoremap <Space> za

" Toggles folds being enabled for this vim session
function! FoldToggle()
  if(&foldenable == 1)
    au WinEnter * set nofen
    au WinLeave * set nofen
    au BufEnter * set nofen
    au BufLeave * set nofen
    :set nofen
  else
    au WinEnter * set fen
    au WinLeave * set fen
    au BufEnter * set fen
    au BufLeave * set fen
    :set fen
  endif
endfunc

nnoremap <Leader>nf :call FoldToggle()<CR>
