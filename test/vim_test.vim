set packpath=
call execute(printf('source %s/plugin/jetpack.vim', expand('<sfile>:p:h:h')))

function s:fallback(val, default)
  return empty(a:val) ? a:default : a:val
endfunction

let g:jetpack_copy_method = s:fallback(getenv('JETPACK_COPY_METHOD'), 'system')
let g:jetpack_download_method = s:fallback(getenv('JETPACK_DOWNLOAD_METHOD'), 'git')

let s:suite = themis#suite('Jetpack Tests')
let s:assert = themis#helper('assert')
let g:vimhome = substitute(expand('<sfile>:p:h'), '\', '/', 'g')
let s:optdir =  g:vimhome . '/pack/jetpack/opt'
let s:srcdir =  g:vimhome . '/pack/jetpack/src'

call delete(g:vimhome . '/pack', 'rf')

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

function s:assert.loaded(package)
  try
    let loaded = luaeval('package.loaded[_A]', a:package)
    call s:assert.not_equals(loaded, v:null, a:package . ' is not loaded')
  catch /.*/
    " Cannot convert given lua type. So, not v:null (it's loaded).
  endtry
endfunction

function s:assert.notloaded(package)
  try
    let loaded = luaeval('package.loaded[_A]', a:package)
    call s:assert.equals(loaded, v:null, a:package . ' is loaded')
  catch /.*/
    " Cannot convert given lua type. So, not v:null (it's loaded).
    call s:assert.fail(a:package . ' is loaded')
  endtry
endfunction


function s:suite.parse_toml()
  let toml =<<EOF
[[plugins]]
repo = 'tani/jetpack.vim'
opt = true
depends = [
  'Shougo/deoplete.nvim',
  'Shougo/vimproc.vim',
]
hook_add = '''
  let g:jetpack_loaded = 1
'''
[[plugins]]
repo = 'tani/glance-vim'
opt = 1
hook_add = '''let g:glance_loaded = 1'''
[[plugins]]
repo = 'tani/ddc-fuzzy'
hook_add = '''
let g:ddc_fuzzy_loaded = 1'''
EOF
  
  let plugins = jetpack#parse_toml(toml)
  call s:assert.equals(plugins[0].repo, 'tani/jetpack.vim')
  call s:assert.equals(plugins[0].opt, 1)
  call s:assert.equals(plugins[0].depends[0], 'Shougo/deoplete.nvim')
  call s:assert.equals(plugins[0].depends[1], 'Shougo/vimproc.vim')
  call s:assert.match(plugins[0].hook_add, 'let g:jetpack_loaded = 1')
  call s:assert.equals(plugins[1].repo, 'tani/glance-vim')
  call s:assert.equals(plugins[1].opt, 1)
  call s:assert.match(plugins[1].hook_add, 'let g:glance_loaded = 1')
  call s:assert.equals(plugins[2].repo, 'tani/ddc-fuzzy')
  call s:assert.match(plugins[2].hook_add, 'let g:ddc_fuzzy_loaded = 1')
endfunction

function s:suite.multiple_plugins_with_the_same_ondemand_command()
  call jetpack#begin(g:vimhome)
  call jetpack#add('tpope/vim-commentary', { 'on': 'Test' })
  call jetpack#add('tpope/vim-surround', { 'on': 'Test' })
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isdirectory(s:optdir . '/vim-commentary')
  call s:assert.isdirectory(s:optdir . '/vim-surround')
  call s:assert.not_exists('g:loaded_commentary')
  call s:assert.not_exists('g:loaded_surround')
  silent! Test
  call s:assert.exists('g:loaded_commentary')
  call s:assert.exists('g:loaded_surround')
endfunction

function s:suite.no_option_github()
  call jetpack#begin(g:vimhome)
  call jetpack#add('mbbill/undotree')
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isnotdirectory(s:optdir . '/undotree')
  call s:assert.filereadable(s:optdir . '/_/plugin/undotree.vim')
endfunction

function s:suite.no_option_url()
  call jetpack#begin(g:vimhome)
  call jetpack#add('https://github.com/mbbill/undotree')
  call jetpack#end()
  call jetpack#sync()
  call s:setup(['https://github.com/mbbill/undotree'])
  call s:assert.isnotdirectory(s:optdir . '/undotree')
  call s:assert.filereadable(s:optdir . '/_/plugin/undotree.vim')
endfunction

function s:suite.opt_option()
  call jetpack#begin(g:vimhome)
  call jetpack#add('junegunn/goyo.vim', { 'opt': 1 })
  call jetpack#end()
  call jetpack#sync()
  let s:loaded_goyo_vim = 0
  augroup JetpackTest
    autocmd!
    autocmd User JetpackGoyoVimPost let s:loaded_goyo_vim = 1
  augroup END
  call s:assert.isdirectory(s:optdir . '/goyo.vim')
  call s:assert.filereadable(s:optdir . '/goyo.vim/plugin/goyo.vim')
  call s:assert.notfilereadable(s:optdir . '/_/plugin/goyo.vim')
  call s:assert.cmd_not_exists('Goyo')
  call s:assert.false(s:loaded_goyo_vim)
  call jetpack#load('goyo.vim')
  call s:assert.cmd_exists('Goyo')
  call s:assert.true(s:loaded_goyo_vim)
endfunction

function s:suite.do_func_option()
  let bin = 'fzf' . (has('win32') ? '.exe' : '')
  call jetpack#begin(g:vimhome)
  call jetpack#add('junegunn/fzf', { 'do': { -> fzf#install() } })
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isdirectory(s:optdir . '/fzf')
  call s:assert.filereadable(s:optdir . '/fzf/bin/' . bin)
endfunction

function s:suite.do_str_option()
  let cmd = './install'
  if has('win32')
    let cmd = 'powershell -ExecutionPolicy Bypass -file ' . cmd . '.ps1'
  endif
  let bin = 'fzf' . (has('win32') ? '.exe' : '')
  call jetpack#begin(g:vimhome)
  call jetpack#add('junegunn/fzf', { 'do': cmd })
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isdirectory(s:optdir . '/fzf')
  call s:assert.filereadable(s:optdir . '/fzf/bin/' . bin)
endfunction

function s:suite.for_option()
  call jetpack#begin(g:vimhome)
  call jetpack#add('vader', { 'for': 'vader' })
  call jetpack#end()
  call jetpack#sync()
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
  call jetpack#begin(g:vimhome)
  call jetpack#add('tpope/vim-abolish', { 'on': 'Abolish' })
  call jetpack#end()
  call jetpack#sync()
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
  call jetpack#begin(g:vimhome)
  call jetpack#add('vim-skk/eskk.vim', { 'on': '<Plug>(eskk' })
  call jetpack#end()
  call jetpack#sync()
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
  call jetpack#begin(g:vimhome)
  call jetpack#add('tpope/vim-fugitive', { 'on': 'User Test' })
  call jetpack#end()
  call jetpack#sync()
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
  call jetpack#begin(g:vimhome)
  call jetpack#add('vlime/vlime', { 'rtp': 'vim' })
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isnotdirectory(s:optdir . '/vlime')
  call s:assert.isnotdirectory(s:optdir . '/_/vim')
  call s:assert.filereadable(s:optdir . '/_/syntax/vlime_repl.vim')
endfunction

function s:suite.issue15()
  call jetpack#begin(g:vimhome)
  call jetpack#add('vim-test/vim-test')
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isdirectory(s:optdir . '/_/autoload/test')
endfunction

function s:suite.names()
  call jetpack#begin(g:vimhome)
  call jetpack#add('vim-test/vim-test')
  call jetpack#end()
  call jetpack#sync()
  call s:assert.equals(jetpack#names(), ['vim-test'])
  call s:assert.isdirectory(s:optdir . '/_/autoload/test')
endfunction

function s:suite.tap()
  call jetpack#begin(g:vimhome)
  call jetpack#add('vim-test/vim-test')
  call jetpack#end()
  call jetpack#sync()
  call s:assert.true(jetpack#tap('vim-test'))
  call s:assert.false(jetpack#tap('_____'))
endfunction

function s:suite.get()
  call jetpack#begin(g:vimhome)
  call jetpack#add('vim-test/vim-test')
  call jetpack#end()
  call jetpack#sync()
  let data = jetpack#get('vim-test')
  call s:assert.equals(data.url, 'https://github.com/vim-test/vim-test')
  call s:assert.equals(data.opt, 0)
  call s:assert.equals(substitute(data.path, '\', '/', 'g'), s:srcdir .. '/github.com/vim-test/vim-test')
endfunction

function s:suite.change_repo_url()
  call jetpack#begin(g:vimhome)
  call jetpack#add('sveltejs/template')
  call jetpack#add('readthedocs/template')
  call jetpack#end()
  call jetpack#sync()
  call s:assert.match(jetpack#get('template').path, 'readthedocs')
endfunction

function s:suite.frozen_option()
  call s:assert.skip('')
endfunction

function s:suite.tag_option()
  call jetpack#begin(g:vimhome)
  call jetpack#add('uga-rosa/ccc.nvim', { 'tag': 'v1.0.0' })
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isnotdirectory(s:optdir . '/ccc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/ccc.lua')
  let indent = matchstr(readfile(s:optdir . '/_/stylua.toml')[3], '\d\+')
  call s:assert.equals(indent, '4')
endfunction

function s:suite.branch_option()
  call jetpack#begin(g:vimhome)
  call jetpack#add('uga-rosa/ccc.nvim', { 'branch': '0.7.2' })
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isnotdirectory(s:optdir . '/ccc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/ccc.lua')
  let first_line_readme = readfile(s:optdir . '/_/README.md', '', 1)[0]
  call s:assert.compare(first_line_readme, '=~#', 'Since 0.8.0 has been released')
endfunction

function s:suite.commit_option()
  call jetpack#begin(g:vimhome)
  call jetpack#add('uga-rosa/ccc.nvim', { 'commit': 'db80a70' })
  call jetpack#end()
  call jetpack#sync()
  call s:assert.isnotdirectory(s:optdir . '/ccc.nvim')
  call s:assert.filereadable(s:optdir . '/_/plugin/ccc.lua')
  let indent = matchstr(readfile(s:optdir . '/_/stylua.toml')[3], '\d\+')
  call s:assert.equals(indent, '2')
endfunction

function s:suite.issue70()
  call jetpack#begin(g:vimhome)
  call jetpack#add('s1n7ax/nvim-window-picker')
  call jetpack#add('p00f/nvim-ts-rainbow')
  call jetpack#end()
  call jetpack#sync()
  call s:assert.filereadable(s:optdir . '/_/screenshots')
  call s:assert.isdirectory(s:optdir. '/nvim-ts-rainbow/screenshots')
endfunction

function s:suite.local_plugin()
  let install_path = expand(g:vimhome . '/pack/linkformat.vim')
  call system('git clone --depth 1 https://github.com/uga-rosa/linkformat.vim ' . install_path)
  call jetpack#begin(g:vimhome)
  call jetpack#add(install_path)
  call jetpack#end()
  call jetpack#sync()
  call s:assert.equals(jetpack#get('linkformat.vim').path, install_path)
  call s:assert.match(&rtp, '\V'.escape(install_path, '\'))
endfunction

