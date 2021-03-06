set path=./**,lib/**,spec/**,,$GEM_HOME/gems
let g:ruby_path=&path
set cdpath=lib/lims/core,spec

set isk+=?,!

set makeprg=rspec
set errorformat=
    \%-Z\ \ \ \ \ \#\ %f:%l:%.%#,%E\ \ %\\d%\\+)%.%#,%C%m,%Z,
    \%-Z%f:%l:%.%#,%E%\\d%\\+)%.%#,%C%m,%Z,
    \%+W'%.%#'\ FAILED,
    \%+I'%.%#'\ FIXED,
    \%-Cexpected:%.%#,
    \%-C\ \ \ \ \ got:%.%#,
    \%E%.%#:in\ `load':\ %f:%l:%m,
    \%C%f:%l:,
    \%W%f:%l:\ warning:\ %m,
    \%E%f:%l:in\ %*[^:]:\ %m,
    \%E%f:%l:\ %m,
    \%-Z%\tfrom\ %f:%l,
    \%-Z%p^%.%#,
    \%-C%.%#,
    \%-G%.%#


iab tf :focus  => true

nnoremap <silent> <localleader>m :make %<CR>
nnoremap <silent> <localleader>c :make -C %<cr>
