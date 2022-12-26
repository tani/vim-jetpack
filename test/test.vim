set packpath=
"set verbose=1
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

function s:setup(...)
  call jetpack#begin(g:vimhome)
  for plugin in a:000
    if len(plugin) == 2
      call jetpack#add(plugin[0], plugin[1])
    else
      call jetpack#add(plugin[0])
    endif
  endfor
  call jetpack#end()
  call jetpack#sync()
  call feedkeys("\<CR>", 'n')
endfunction

function Dummy(name)
  return 'file://'.fnamemodify(g:vimhome, ':p:h:h').'/data/'.a:name
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
  call s:setup(
  \ [Dummy('A'), { 'on': 'Test' }],
  \ [Dummy('B'), { 'on': 'Test' }]
  \ )
  call s:assert.isdirectory(s:optdir . '/A')
  call s:assert.isdirectory(s:optdir . '/B')
  call s:assert.not_exists('g:loaded_A')
  call s:assert.not_exists('g:loaded_B')
  silent! Test
  call s:assert.exists('g:loaded_A')
  call s:assert.exists('g:loaded_B')
endfunction

function s:suite.no_option_github()
  call jetpack#begin(g:vimhome)
  call jetpack#add('foo/bar')
  call jetpack#end()
  call s:assert.equals(jetpack#get('bar').url, 'https://github.com/foo/bar')
endfunction

function s:suite.no_option_url()
  call jetpack#begin(g:vimhome)
  call jetpack#add('https://github.com/mbbill/undotree')
  call jetpack#end()
  call s:assert.equals(jetpack#get('undotree').url, 'https://github.com/mbbill/undotree')
endfunction

function s:suite.opt()
  call s:setup([Dummy('C'), { 'opt': 1 }])
  call s:assert.isdirectory(s:optdir . '/C')
  call s:assert.not_exists('g:loaded_C')
  call jetpack#load('C')
  call s:assert.exists('g:loaded_C')
endfunction

function s:suite.do_func()
  call s:setup([Dummy('Q'), { 'do': { -> FunQ() } }])
  call s:assert.isdirectory(s:optdir . '/Q')
  call s:assert.exists('g:loaded_Q')
  call s:assert.exists('g:installed_Q')
endfunction

function s:suite.on_ft()
  call s:setup([Dummy('D'), { 'on_ft': 'c' }])
  call s:assert.isdirectory(s:optdir . '/D')
  call s:assert.not_exists('g:loaded_D')
  let filetype = &filetype
  setf c
  call s:assert.exists('g:loaded_D')
  let &filetype = filetype
endfunction

function s:suite.on_cmd()
  call s:setup([Dummy('E'), { 'on_cmd': 'CmdE' }])
  call s:assert.isdirectory(s:optdir . '/E')
  call s:assert.not_exists('g:loaded_E')
  silent! CmdE
  call s:assert.exists('g:loaded_E')
endfunction

function s:suite.on_map()
  call s:setup([Dummy('F'), { 'on_map': '<Plug>F' }])
  call s:assert.isdirectory(s:optdir . '/F')
  call s:assert.not_exists('g:loaded_F')
  call feedkeys('', 'x')
  call feedkeys("\<Plug>F", 'x')
  call feedkeys('', 'x')
  call s:assert.exists('g:loaded_F')
endfunction

function s:suite.on_source()
  call s:setup(
  \ [Dummy('G'), { 'opt': 1 }],
  \ [Dummy('H'), { 'on_source': 'G' }]
  \ )
  call s:assert.isdirectory(s:optdir . '/G')
  call s:assert.isdirectory(s:optdir . '/H')
  call s:assert.not_exists('g:loaded_G')
  call s:assert.not_exists('g:loaded_H')
  call jetpack#load('G')
  call s:assert.exists('g:loaded_G')
  call s:assert.exists('g:loaded_H')
endfunction

function s:suite.on_post_source()
  call s:setup(
  \ [Dummy('I'), { 'opt': 1 }],
  \ [Dummy('J'), { 'on_post_source': 'I' }]
  \ )
  call s:assert.isdirectory(s:optdir . '/I')
  call s:assert.isdirectory(s:optdir . '/J')
  call s:assert.not_exists('g:loaded_I')
  call s:assert.not_exists('g:loaded_J')
  call jetpack#load('I')
  call s:assert.exists('g:loaded_I')
  call s:assert.exists('g:loaded_J')
endfunction

function s:suite.on_event()
  call s:setup([Dummy('K'), { 'on_event': 'User Test' }])
  call s:assert.isdirectory(s:optdir . '/K')
  call s:assert.not_exists('g:loaded_K')
  doautocmd User Test
  call s:assert.exists('g:loaded_K')
endfunction

function s:suite.rtp()
  call s:setup([Dummy('L'), { 'rtp': 'vim' }])
  call s:assert.isnotdirectory(s:optdir . '/_/vim')
  call s:assert.filereadable(s:optdir . '/_/plugin/L.vim')
endfunction

" function s:suite.issue15()
"   call s:setup(['vim-test/vim-test'])
"   call s:assert.isdirectory(s:optdir . '/_/autoload/test')
" endfunction

function s:suite.names()
  call s:setup([Dummy('M')])
  call s:assert.filereadable(s:optdir . '/_/plugin/M.vim')
  call s:assert.equals(jetpack#names(), ['M'])
endfunction

function s:suite.tap()
  call s:setup([Dummy('N')])
  call s:assert.filereadable(s:optdir . '/_/plugin/N.vim')
  call s:assert.true(jetpack#tap('N'))
  call s:assert.false(jetpack#tap('_'))
endfunction

function s:suite.get()
  call s:setup([Dummy('O')])
  call s:assert.filereadable(s:optdir . '/_/plugin/O.vim')
  let data = jetpack#get('O')
  call s:assert.equals(type(data), type({}))
  call s:assert.false(empty(data), 'data is empty')
endfunction

" function s:suite.change_repo_url()
"   call s:setup(['sveltejs/template'])
"   call s:setup(['readthedocs/template'])
"   call s:assert.match(jetpack#get('template').path, 'readthedocs')
" endfunction

function s:suite.frozen_option()
  call s:assert.skip('')
endfunction

function s:suite.tag_option()
  call s:setup([Dummy('S'), { 'tag': 'v1' }])
  call s:assert.filereadable(s:optdir . '/_/plugin/S.vim')
  call s:assert.equals(g:version_S, 'v1')
endfunction

function s:suite.branch_option()
  call s:setup([Dummy('T'), { 'branch': 'other' }])
  call s:assert.filereadable(s:optdir . '/_/plugin/T.vim')
  call s:assert.equals(g:branch_T, 'other')
endfunction

function s:suite.commit_option()
  let ids = systemlist('git -C '.fnamemodify(g:vimhome, ':p:h:h').'/data/U'.' log -3 --pretty=format:"%h"')
  call s:setup([Dummy('U'), { 'commit': ids[1] }])
  call s:assert.filereadable(s:optdir . '/_/plugin/U.vim')
  call s:assert.equals(g:version_U, 'v0')
endfunction

" function s:suite.issue70()
"   call s:setup(['s1n7ax/nvim-window-picker'], ['p00f/nvim-ts-rainbow'])
"   call s:assert.filereadable(s:optdir . '/_/screenshots')
"   call s:assert.isdirectory(s:optdir. '/nvim-ts-rainbow/screenshots')
" endfunction

function s:suite.local_plugin()
  let install_path = fnamemodify(g:vimhome, ':p:h:h') . '/data/P'
  call s:setup([install_path])
  call s:assert.isdirectory(install_path)
  call s:assert.exists('g:loaded_P')
endfunction

"function s:suite.self_delete()
"  let src_path = expand(s:srcdir . '/github.com/tani/vim-jetpack')
"  let opt_path = expand(s:optdir . '/vim-jetpack')
"  
"  " When jetpack is added, it does not delete itself.
"  call s:setup(['tani/vim-jetpack', { 'opt': 1 }])
"  call s:assert.isdirectory(src_path)
"  call s:assert.isdirectory(opt_path)
"  
"  " When jetpack is not added, it ask me to delete itself.
"  call jetpack#begin(g:vimhome)
"  call jetpack#end()
"  
"  " If you press "no", nothing will happen.
"  augroup SelfDeletePressKey
"    au!
"    au CmdlineEnter * call feedkeys("no\<CR>", "n")
"  augroup END
"  call jetpack#sync()
"  call s:assert.isdirectory(opt_path)
"  
"  " If you press "yes", it will delete the directory
"  augroup SelfDeletePressKey
"    au!
"    autocmd CmdlineEnter * call feedkeys("yes\<CR>", "n")
"  augroup END
"  call jetpack#sync()
"  call s:assert.isnotdirectory(opt_path)
"  
"  " If you have an old jetpack, don't ask.
"  call s:setup(['tani/vim-jetpack', { 'opt': 1 }])
"  call system('git -C ' . src_path . ' fetch --depth 2')
"  call system('git -C ' . src_path . ' reset --hard HEAD~')
"  call jetpack#sync()
"  call s:assert.isdirectory(src_path)
"  call s:assert.isdirectory(opt_path)
"endfunction

if !has('nvim') && !(has('lua') && has('patch-8.2.0775'))
  finish 
endif

lua <<EOL
local packer = require('jetpack.packer')

packer.init({
  package_root = require('jetpack.util').eval('g:vimhome') .. '/pack',
})

_G.packer_setup = function(...)
local plugins = { ... }
packer.startup(function(use)
  for _, plugin in ipairs(plugins) do
    use(plugin)
  end
end)
require('jetpack').sync()
end
EOL

function s:suite.packer_style()
lua<<EOF
  packer_setup({
    vim.fn.Dummy('V'),
  })
EOF
call s:assert.filereadable(s:optdir . '/_/plugin/V.vim')
endfunction

function s:suite.packer_style_setup()
lua<<EOF
  packer_setup({
    vim.fn.Dummy('W'),
    setup = function()
      require('jetpack.util').command[[
        let g:variable_W = 0 
      ]]
    end
  })
EOF
call jetpack#load('W')
call s:assert.exists('g:loaded_W')
call s:assert.exists('g:variable_W')
endfunction

function s:suite.packer_style_config()
lua<<EOF
  packer_setup({
    vim.fn.Dummy('X'),
    config = function()
      require('X').setup{}
    end
  })
EOF
call jetpack#load('X')
call s:assert.exists('g:loaded_X')
call s:assert.exists('g:variable_X')
endfunction

function! s:suite.pkg_requires() abort
lua<<EOF
  packer_setup({
    vim.fn.Dummy('Y'),
    opt = true
  }, {
    vim.fn.Dummy('Z'),
    requires = { 'Y' },
    opt = true
  })
EOF
  call jetpack#load('Z')
  call s:assert.exists('g:loaded_Z')
  call s:assert.exists('g:loaded_Y')
endfunction
