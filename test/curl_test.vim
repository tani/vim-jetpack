set packpath=
call execute(printf('source %s/plugin/jetpack.vim', expand('<sfile>:p:h:h')))

let g:jetpack_copy_method = 'system'
let g:jetpack_download_method = 'curl'

let s:suite = themis#suite('Jetpack Tests')
let s:assert = themis#helper('assert')
let s:vimhome = substitute(expand('<sfile>:p:h'), '\', '/', 'g')
let s:optdir =  s:vimhome . '/pack/jetpack/opt'
let s:srcdir =  s:vimhome . '/pack/jetpack/src'

function s:setup(...) 
  call jetpack#begin(s:vimhome)
  for plugin in a:000
    if len(plugin) == 2
      call jetpack#add(plugin[0], plugin[1])
    else
      call jetpack#add(plugin[0])
    endif
  endfor
  call jetpack#end()
  call jetpack#sync()
endfunction

function s:assert.filereadable(file)
  if !filereadable(a:file)
    call s:assert.fail(a:file . ' is not readable')
  endif
endfunction

function s:assert.notfilereadable(file)
  if filereadable(a:file)
    call s:assert.fail(a:file . ' is readable')
  endif
endfunction

function s:assert.isdirectory(dir)
  if !isdirectory(a:dir)
    call s:assert.fail(a:dir . ' is not a directory')
  endif
endfunction

function s:assert.isnotdirectory(dir)
  if isdirectory(a:dir)
    call s:assert.fail(a:dir . ' is a directory')
  endif
endfunction

function s:suite.no_option_github()
 call s:setup(['mbbill/undotree'])
 call s:assert.isnotdirectory(s:optdir . '/undotree')
 call s:assert.filereadable(s:optdir . '/_/plugin/undotree.vim')
endfunction

function s:suite.no_option_url()
 call s:setup(['https://github.com/mbbill/undotree'])
 call s:assert.isnotdirectory(s:optdir . '/undotree')
 call s:assert.filereadable(s:optdir . '/_/plugin/undotree.vim')
endfunction

function s:suite.opt_option()
 call s:setup(['junegunn/goyo.vim', { 'opt': 1 }]) 
 let s:loaded_goyo_vim = 0
 augroup JetpackTest
   au!
   autocmd User JetpackGoyoVimPost let s:loaded_goyo_vim = 1
 augroup END
 call s:assert.isdirectory(s:optdir . '/goyo.vim')
 call s:assert.filereadable(s:optdir . '/goyo.vim/plugin/goyo.vim')
 call s:assert.notfilereadable(s:optdir . '/_/plugin/goyo.vim')
 call s:assert.cmd_not_exists('Goyo')
 call s:assert.false(s:loaded_goyo_vim)
 packadd goyo.vim
 call s:assert.cmd_exists('Goyo')
 call s:assert.true(s:loaded_goyo_vim)
endfunction

function s:suite.for_option()
 call s:setup(['junegunn/vader.vim', { 'for': 'vader' }]) 
 let s:loaded_vader_vim = 0
 augroup JetpackTest
   au!
   autocmd User JetpackVaderVimPost let s:loaded_vader_vim = 1
 augroup END
 call s:assert.isdirectory(s:optdir . '/vader.vim')
 call s:assert.filereadable(s:optdir . '/vader.vim/plugin/vader.vim')
 call s:assert.notfilereadable(s:optdir . '/_/plugin/vader.vim')
 call s:assert.cmd_not_exists('Vader')
 call s:assert.false(s:loaded_vader_vim)
 let filetype = &filetype
 setf vader
 call s:assert.cmd_exists('Vader')
 call s:assert.true(s:loaded_vader_vim)
 let &filetype = filetype
endfunction

function s:suite.on_option_cmd()
 call s:setup(['tpope/vim-abolish', { 'on': 'Abolish' }]) 
 let s:loaded_abolish_vim = 0
 augroup JetpackTest
   autocmd!
   autocmd User JetpackVimAbolishPost let s:loaded_abolish_vim = 1
 augroup END
 call s:assert.isdirectory(s:optdir . '/vim-abolish')
 call s:assert.filereadable(s:optdir . '/vim-abolish/plugin/abolish.vim')
 call s:assert.notfilereadable(s:optdir . '/_/plugin/abolish.vim')
 call s:assert.cmd_exists('Abolish')
 call s:assert.cmd_not_exists('Subvert')
 call s:assert.false(s:loaded_abolish_vim)
 silent! Abolish
 call s:assert.cmd_exists('Abolish')
 call s:assert.cmd_exists('Subvert')
 call s:assert.true(s:loaded_abolish_vim)
endfunction

function s:suite.on_option_plug()
 call s:setup(['vim-skk/eskk.vim', { 'on': '<Plug>(eskk' }])
 call s:assert.notfilereadable(s:optdir . '/_/plugin/eskk.vim')
 call s:assert.isdirectory(s:optdir . '/eskk.vim')
 call s:assert.filereadable(s:optdir . '/eskk.vim/plugin/eskk.vim')
 let s:loaded_eskk_vim = 0
 augroup JetpackTest
   autocmd!
   autocmd User JetpackEskkVimPost let s:loaded_eskk_vim = 1
 augroup END
 call s:assert.cmd_not_exists('EskkMap')
 call s:assert.false(s:loaded_eskk_vim)
 call feedkeys("i\<Plug>(eskk:toggle)\<Esc>", 'x')
 call feedkeys('', 'x')
 call s:assert.cmd_exists('EskkMap')
 call s:assert.true(s:loaded_eskk_vim)
endfunction

function s:suite.on_option_event()
 call s:setup(['tpope/vim-fugitive', { 'on': 'User Test' }])
 let s:loaded_fugitive = 0
 augroup JetpackTest
   autocmd!
   autocmd User JetpackVimFugitivePost let s:loaded_fugitive = 1
 augroup END
 call s:assert.notfilereadable(s:optdir . '/_/plugin/fugitive.vim')
 call s:assert.isdirectory(s:optdir .  '/vim-fugitive')
 call s:assert.filereadable(s:optdir .  '/vim-fugitive/plugin/fugitive.vim')
 call s:assert.cmd_not_exists('Git')
 call s:assert.false(s:loaded_fugitive)
 doautocmd User Test
 call s:assert.true(s:loaded_fugitive)
 call s:assert.cmd_exists('Git')
endfunction

function s:suite.rtp_option()
 call s:setup(['vlime/vlime', { 'rtp': 'vim' }])
 call s:assert.isnotdirectory(s:optdir . '/vlime')
 call s:assert.isnotdirectory(s:optdir . '/_/vim')
 call s:assert.filereadable(s:optdir . '/_/syntax/vlime_repl.vim')
endfunction

function s:suite.dir_do_option()
 if has('win32')
   call s:assert.skip('')
 endif
 call s:setup(['lotabout/skim', { 'dir': s:vimhome . '/pack/skim', 'do': './install' }])
 call s:assert.isnotdirectory(s:vimhome . '/pack/opt/skim')
 call s:assert.isnotdirectory(s:vimhome . '/pack/src/skim')
 call s:assert.isdirectory(s:vimhome . '/pack/skim')
 call s:assert.filereadable(s:vimhome . '/pack/skim/bin/sk')
endfunction

function s:suite.issue15()
 call s:setup(['vim-test/vim-test'])
 call s:assert.isdirectory(s:optdir . '/_/autoload/test')
endfunction

function s:suite.names()
 call s:setup(['vim-test/vim-test'])
 call s:assert.equals(jetpack#names(), ['vim-test'])
 call s:assert.isdirectory(s:optdir . '/_/autoload/test')
endfunction

function s:suite.tap()
 call s:setup(['vim-test/vim-test'])
 call s:assert.true(jetpack#tap('vim-test'))
 call s:assert.false(jetpack#tap('_____'))
endfunction

function s:suite.get()
 call s:setup(['vim-test/vim-test'])
 let data = jetpack#get('vim-test')
 call s:assert.equals(data.url, 'https://github.com/vim-test/vim-test')
 call s:assert.equals(data.opt, 0)
 call s:assert.equals(substitute(data.path, '\', '/', 'g'), s:srcdir .. '/github.com/vim-test/vim-test')
endfunction

function s:suite.change_repo_url()
 call s:setup(['sveltejs/template'])
 call s:setup(['readthedocs/template'])
 call s:assert.match(jetpack#get('template').path, 'readthedocs')
endfunction

function s:suite.frozen_option()
 call s:assert.skip('')
endfunction

function s:suite.issue70()
  call s:setup(['s1n7ax/nvim-window-picker'], ['p00f/nvim-ts-rainbow'])
  call s:assert.filereadable(s:optdir . '/_/screenshots')
  call s:assert.isdirectory(s:optdir. '/nvim-ts-rainbow/screenshots')
endfunction

