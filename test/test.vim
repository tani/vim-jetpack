execute 'set pp-=' . (has('nvim') ? stdpath('data') . '/site' : expand('~/.vim'))
execute 'set rtp^=' . expand('<sfile>:p:h:h')

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

function s:suite.optimization_2()
  let g:jetpack#optimization = 2
  call s:setup(['junegunn/fzf'], ['junegunn/fzf.vim'])
  call s:assert.isnotdirectory(s:optdir . '/fzf')
  call s:assert.isnotdirectory(s:optdir . '/fzf.vim')
  let g:jetpack#optimization = 1
endfunction

function s:suite.optimization_1()
  let g:jetpack#optimization = 1
  call s:setup(['junegunn/fzf'], ['junegunn/fzf.vim'])
  call s:assert.isdirectory(s:optdir . '/fzf.vim')
  call s:assert.isnotdirectory(s:optdir . '/fzf')
  let g:jetpack#optimization = 1
endfunction

function s:suite.optimization_0()
  let g:jetpack#optimization = 0
  call s:setup(['junegunn/fzf'], ['junegunn/fzf.vim'])
  call s:assert.isdirectory(s:optdir . '/fzf')
  call s:assert.isdirectory(s:optdir . '/fzf.vim')
  let g:jetpack#optimization = 1
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

function s:suite.branch_option()
  call s:setup(['neoclide/coc.nvim', { 'branch': 'release' }])
  let branch = system(printf('git -C "%s" branch', s:srcdir . '/coc.nvim'))
  call s:assert.isnotdirectory(s:optdir . '/coc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/coc.vim')
  call s:assert.match(branch, 'release')
endfunction

function s:suite.tag_option()
  call s:setup(['neoclide/coc.nvim', { 'tag': 'v0.0.80' }])
  let tag = system(printf('git -C "%s" describe --tags --abbrev=0', s:srcdir . '/coc.nvim')) 
  call s:assert.isnotdirectory(s:optdir . '/coc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/coc.vim')
  call s:assert.match(tag, 'v0.0.80')
endfunction

function s:suite.commit_option()
  call s:setup(['neoclide/coc.nvim', { 'commit': 'ce448a6' }])
  let commit = system(printf('git -C "%s" rev-parse HEAD', s:srcdir . '/coc.nvim')) 
  call s:assert.isnotdirectory(s:optdir . '/coc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/coc.vim')
  call s:assert.match(commit, 'ce448a6')
endfunction

function s:suite.opt_option()
  call s:setup(['junegunn/goyo.vim', { 'opt': 1 }]) 
  let s:loaded_goyo_vim = 0
  augroup JetpackTest
    au!
    autocmd User JetpackGoyoVim let s:loaded_goyo_vim = 1
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
    autocmd User JetpackVaderVim let s:loaded_vader_vim = 1
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
    au!
    autocmd User JetpackVimAbolish let s:loaded_abolish_vim = 1
  augroup END
  call s:assert.isdirectory(s:optdir . '/vim-abolish')
  call s:assert.filereadable(s:optdir . '/vim-abolish/plugin/abolish.vim')
  call s:assert.notfilereadable(s:optdir . '/_/plugin/abolish.vim')
  call s:assert.cmd_not_exists('Abolish')
  call s:assert.false(s:loaded_abolish_vim)
  silent! Abolish
  call s:assert.cmd_exists('Abolish')
  call s:assert.true(s:loaded_abolish_vim)
endfunction

function s:suite.on_option_plug()
  call s:setup(['vim-skk/eskk.vim', { 'on': '<Plug>(eskk:toggle)' }])
  call s:assert.notfilereadable(s:optdir . '/_/plugin/eskk.vim')
  call s:assert.isdirectory(s:optdir . '/eskk.vim')
  call s:assert.filereadable(s:optdir . '/eskk.vim/plugin/eskk.vim')
  let s:loaded_eskk_vim = 0
  augroup JetpackTest
    au!
    autocmd User JetpackEskkVim let s:loaded_eskk_vim = 1
  augroup END
  call s:assert.cmd_not_exists('EskkMap')
  call s:assert.false(s:loaded_eskk_vim)
  call feedkeys("i\<Plug>(eskk:toggle)\<Esc>")
  call feedkeys('', 'x')
  call s:assert.cmd_exists('EskkMap')
  call s:assert.true(s:loaded_eskk_vim)
endfunction

function s:suite.rtp_option()
  call s:setup(['vlime/vlime', { 'rtp': 'vim' }])
  call s:assert.isnotdirectory(s:optdir . '/vlime')
  call s:assert.isnotdirectory(s:optdir . '/_/vim')
  call s:assert.filereadable(s:optdir . '/_/syntax/vlime_repl.vim')
endfunction

function s:suite.issue15()
  call s:setup(['vim-test/vim-test'])
  call s:assert.isdirectory(s:optdir . '/_/autoload/test')
endfunction

function s:suite.dir_do_option()
  if has('win32') || has('win64')
    call s:assert.skip('Skim is not for Windows')
  endif
  call s:setup(['lotabout/skim', { 'dir': s:vimhome . '/pack/skim', 'do': './install' }])
  call s:assert.isnotdirectory(s:vimhome . '/pack/opt/skim')
  call s:assert.isnotdirectory(s:vimhome . '/pack/src/skim')
  call s:assert.isdirectory(s:vimhome . '/pack/skim')
  call s:assert.filereadable(s:vimhome . '/pack/skim/bin/sk')
endfunction

function s:suite.frozen_option()
  call s:assert.skip('')
endfunction


