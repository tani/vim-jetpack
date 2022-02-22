let tests = [
  \ {
  \   'title': '(branch / tag option) Available :CocCommand of coc.nvim',
  \   'prologue': '',
  \   'expected': 'exists(":CocCommand")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(do option) Available an executable of fzf',
  \   'prologue': '',
  \   'expected': 'executable(expand("<sfile>:p:h") . "/pack/jetpack/opt/fzf/bin/fzf")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(do option) fzf should not be merged',
  \   'prologue': '',
  \   'expected': '!executable(expand("<sfile>:p:h") . "/pack/jetpack/opt/_/bin/fzf")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(opt option) fzf.vim should be an opt package',
  \   'prologue': '',
  \   'expected': '!exists(":Files")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(opt option) fzf.vim should exist after packadd',
  \   'prologue': 'packadd fzf.vim',
  \   'expected': 'exists(":Files")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(for option) fzf-preview should not exist',
  \   'prologue': '',
  \   'expected': '!exists(":FzfPreviewGitFilesRpc")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(for option) fzf-preview should exist in lisp',
  \   'prologue': 'setf lisp',
  \   'expected': 'exists(":FzfPreviewGitFilesRpc")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(dir option and do option) skim should be instaled in /pack/skim',
  \   'prologue': '',
  \   'expected': 'has("win64") || has("win32") || executable(expand("<sfile>:p:h") . "/pack/skim/bin/sk")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(dir option and do option) skim should not be merged',
  \   'prologue': '',
  \   'expected': 'has("win64") || has("win32") || !executable(expand("<sfile>:p:h") . "/pack/jetpack/opt/_/bin/sk")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(as option) dracula/vim should be installed as dracula',
  \   'prologue': '',
  \   'expected': 'isdirectory(expand("<sfile>:p:h") . "/pack/jetpack/src/dracula")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(rtp option) vlime/vlime',
  \   'prologue': 'setf lisp',
  \   'expected': 'filereadable(expand("<sfile>:p:h") . "/pack/jetpack/opt/_/addon-info.json")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': 'Issue 15 vim-test',
  \   'prologue': '',
  \   'expected': 'isdirectory(expand("<sfile>:p:h") . "/pack/jetpack/opt/_/autoload/test")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': 'Allow git url',
  \   'prologue': '',
  \   'expected': 'jetpack#tap("ale")',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(autocmd) do autocmd User after loading',
  \   'prologue': 'setf markdown',
  \   'expected': 'g:is_loaded_goyo_user == 1',
  \   'epilogue': ''
  \ },
  \ {
  \   'title': '(commit) checkout a specific commit',
  \   'prologue': '',
  \   'expected': printf('system("git -C %s rev-parse HEAD") =~# "e84eadc7ea1b4d7854840291e5709329432fd159"', expand('<sfile>:p:h') . '/pack/jetpack/src/ddc-fuzzy'),
  \   'epilogue': ''
  \ },
  \ ]
let s:failed = 0

for test in tests
  call execute(test.prologue)
  if eval(test.expected)
    echon "\n[success] " . test.title
  else
    let s:failed = 1
    echon "\n[failed ] " . test.title
  endif
  call execute(test.epilogue)
endfor

if s:failed
  cquit
endif
