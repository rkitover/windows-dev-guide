set encoding=utf8
set langmenu=en_US.UTF-8
let g:is_bash=1
set formatlistpat=^\\s*\\%([-*][\ \\t]\\\|\\d+[\\]:.)}\\t\ ]\\)\\s*
set ruler bg=dark nohlsearch bs=2 noea ai fo+=n undofile modeline belloff=all modeline modelines=5
set fileformats=unix,dos

set mouse=a

" Add vcpkg includes to include search path to get completions for C++.
let g:home = fnamemodify('~', ':p')

if isdirectory(g:home . 'source/repos/vcpkg/installed/x64-windows/include')
  let &path .= ',' . g:home . 'source/repos/vcpkg/installed/x64-windows/include'
endif

if isdirectory(g:home . 'source/repos/vcpkg/installed/x64-windows-static/include')
  let &path .= ',' . g:home . 'source/repos/vcpkg/installed/x64-windows-static/include'
endif

if !has('gui_running') && match($TERM, "screen") == -1
  set termguicolors
  au ColorScheme * hi Normal ctermbg=0
endif

if has('gui_running')
  au ColorScheme * hi Normal guibg=#000000

  if has('win32')
    set guifont=Hack:h11:cANSI
  endif
endif

if has('win32') || has('gui_win32')
  if executable('pwsh')
    set shell=pwsh
  else
    set shell=powershell
  endif

  set shellquote= shellpipe=\| shellredir=> shellxquote=
  set shellcmdflag=-nologo\ -noprofile\ -executionpolicy\ remotesigned\ -noninteractive\ -command
endif

filetype plugin indent on
syntax enable

au BufRead COMMIT_EDITMSG,*.md setlocal spell
au BufRead COMMIT_EDITMSG so $VIMRUNTIME/syntax/gitcommit.vim | set tw=72
au BufRead *.md  setlocal tw=80
au FileType json setlocal ft=jsonc sw=4 et

" Return to last edit position when opening files.
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Fix syntax highlighting on CTRL+L.
noremap  <C-L> <Esc>:syntax sync fromstart<CR>:redraw<CR>
inoremap <C-L> <C-o>:syntax sync fromstart<CR><C-o>:redraw<CR>

" Markdown
let g:markdown_fenced_languages = ['css', 'javascript', 'js=javascript', 'json=javascript', 'jsonc=javascript', 'xml', 'ps1', 'powershell=ps1', 'sh', 'bash=sh', 'autohotkey', 'vim', 'sshconfig', 'dosbatch', 'gitconfig']
